#!/usr/bin/perl
use File::Copy;
use Getopt::Long;
use Pod::Usage;

my $extensions_file = "/etc/asterisk/extensions_additional.conf";
my $write_file      = "/etc/asterisk/extensions_override_freepbx.conf";
my $help            = 0;
my $man             = 0;
my $force           = 0;
my $write           = 0;
my $print_contexts  = 0;

GetOptions(
    "help|?"        => \$help,
    "man"           => \$man,
    "force"         => \$force,
    "p|print"       => \$print_contexts,
    "f|file=s"      => \$write_file,
    "e|extension=s" => \$extensions_file,
    "w|write"       => \$write
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

if ( !-r $extensions_file ) {
    die("Cannot read $extensions_file. Aborting.\n");
}


#if ( !$force ) {
#    print "Since fop2admin version 1.2.15 there is no need to run this script anymore.\n";
#    print "If you want to run it anyways, be sure to specify the -force command line\n";
#    print "parameter.\n\n";
#    exit;
#}

if ( !$print_contexts && !$write ) {
    pod2usage( -verbose => 2 );
}

@wanted_contexts = ( "app-dnd-on", "app-dnd-off", "app-dnd-toggle", "app-cf-off", "app-cf-on", "app-cf-toggle", "fop2-park", "fop2-dummy", "app-check-classofservce" );
%hash_contexts = map { $_ => 1 } @wanted_contexts;

$cont_diff{'app-dnd-on'}->{'Macro\(user-callerid'} = '; added for fop2
EXTENLINE,n,Set(DB(DND/${AMPUSER})=YES)
EXTENLINE,n,Set(CHAN=${CUT(CHANNEL,-,1)})
EXTENLINE,n,Set(DB(fop2state/${CHAN})=Do not Disturb)
EXTENLINE,n,UserEvent(FOP2ASTDB,Family: fop2state,Channel: ${CHAN},Value: Do not Disturb)
; end fop2 addition';

$cont_diff{'app-dnd-off'}->{'Macro\(user-callerid'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${CUT(CHANNEL,-,1)})
EXTENLINE,n,dbDel(fop2state/${CHAN})
EXTENLINE,n,UserEvent(FOP2ASTDB,Family: fop2state,Channel: ${CHAN},Value: )
; end fop2 addition';

$cont_diff{'app-dnd-toggle'}->{'n\(activate\)'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${CUT(CHANNEL,-,1)})
EXTENLINE,n,Set(DB(fop2state/${CHAN})=Do not Disturb)
EXTENLINE,n,UserEvent(FOP2ASTDB,Family: fop2state,Channel: ${CHAN},Value: Do not Disturb)
; end fop2 addition';

$cont_diff{'app-dnd-toggle'}->{'n\(deactivate\)'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${CUT(CHANNEL,-,1)})
EXTENLINE,n,dbDel(fop2state/${CHAN})
EXTENLINE,n,UserEvent(FOP2ASTDB,Family: fop2state,Channel: ${CHAN},Value: )
; end fop2 addition';

$cont_diff{'app-cf-off'}->{'Del'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${DB(DEVICE/${fromext}/dial)})
EXTENLINE,n,UserEvent(FOP2CUST,Family: astdbcust,Channel: ${CHAN},Value: )
; end fop2 addition';

$cont_diff{'app-cf-on'}->{'Set\(DB'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${DB(DEVICE/${fromext}/dial)})
EXTENLINE,n,UserEvent(FOP2CUST,Family: astdbcust,Channel: ${CHAN},Value: ${toext} )
; end fop2 addition';

$cont_diff{'app-cf-toggle'}->{'Set\(DB'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${DB(DEVICE/${fromext}/dial)})
EXTENLINE,n,UserEvent(FOP2CUST,Family: astdbcust,Channel: ${CHAN},Value: ${toext} )
; end fop2 addition';

$cont_diff{'app-cf-toggle'}->{'Del'} = '; added for fop2
EXTENLINE,n,Set(CHAN=${DB(DEVICE/${fromext}/dial)})
EXTENLINE,n,UserEvent(FOP2CUST,Family: astdbcust,Channel: ${CHAN},Value: )
; end fop2 addition';

$cont_diff{'app-check-classofservce'}->{'Noop\(Starting COS Check\)'} = '; added for fop2
exten => s,n,Set(CHAN=${CUT(CHANNEL,-,1)})
exten => s,n,ExecIf($["${CHAN}"="Local/s@custom"]?Return())
; end fop2 addition';

@final_fop2_file = ();

open( CONFIG, "<$extensions_file" ) or die("Could not open $extensions_file. Aborting...");
while (<CONFIG>) {
    chomp;
    $_ =~ s/^\s+//g;
    $_ =~ s/([^;]*)[;](.*)/$1/g;
    $_ =~ s/\s+$//g;

    if ( /^#/ || /^;/ || /^$/ ) {
        next;
    }    # Ignores comments and empty lines

    if (/^\Q[\E/) {
        s/\[(.*)\]/$1/g;
        $context = $_;
        if ( defined( $hash_contexts{$context} ) ) {
            push @final_fop2_file, "\n[" . $context . "]\n";
        }
    }
    else {
        if ( $context ne "" ) {
            if ( defined( $hash_contexts{$context} ) ) {
                push @final_fop2_file, "$_\n";
                ( $extenline, undef ) = split /,/;

                foreach my $pipi ( keys %cont_diff ) {
                    if ( $context eq $pipi ) {
                        foreach my $pepe ( keys %{ $cont_diff{$pipi} } ) {
                            if ( $_ =~ m|$pepe|i ) {
                                $pepe = $cont_diff{$pipi}->{$pepe};
                                $pepe =~ s/EXTENLINE/$extenline/g;
                                push @final_fop2_file, $pepe . "\n";
                            }
                        }
                    }
                }

            }
        }
    }
}
close(CONFIG);

$AsteriskVersionMajor = `/usr/sbin/asterisk -rx "core show version" | cut -d' ' -f2 | cut -d\\. -f1 `;
chop($AsteriskVersionMajor);

$AsteriskVersionMinor = `/usr/sbin/asterisk -rx "core show version" | cut -d\\. -f2`;
chop($AsteriskVersionMinor);

if ( $AsteriskVersionMajor eq "1") {
    if ( $AsteriskVersionMinor eq "8" ) {
        $delim = ",";
    }
    else {
        $delim = "\\,";
    }
}

if($AsteriskVersionMajor eq "13") {
    $parkline = 'exten => _X.,5,Park(,sc(${RETURN_CONTEXT},${RETURN_EXTENSION},1))';
} else {
    $parkline  = 'exten => _X.,5,Park(,${RETURN_CONTEXT},${RETURN_EXTENSION},1,s)';
}

$extracontext = '
;[fop2-park]
; Old fop2-park for asterisk 1.2 or some older 1.4
;exten => _X.,1,Set(ARRAY(RETURN_EXTENSION,RETURN_CONTEXT)=${CUT(EXTEN,:,1)}DELIM${CUT(EXTEN,:,2)})
;exten => _X.,n,ParkAndAnnounce(PARKED,,Console/dsp,${RETURN_CONTEXT},${RETURN_EXTENSION},1)
;exten => _X.,n,Goto(${RETURN_CONTEXT},${RETURN_EXTENSION},1)
;exten => _X.,n,Hangup

[fop2-park]
exten => _X.,1,Set(ARRAY(RETURN_EXTENSION,RETURN_CONTEXT,PARKBUTTON)=${CUT(EXTEN,:,1)},${CUT(EXTEN,:,2)},${CUT(EXTEN,:,3)})
exten => _X.,2,GotoIf($["${PARKBUTTON}" = "PARK/default"]?5)
exten => _X.,3,GotoIf($["${PARKBUTTON}" = ""]?5)
exten => _X.,4,Set(PARKINGLOT=${PARKBUTTON:5})
PARKLINE

[fop2-dummy]
exten => dummy,1,Answer
exten => dummy,n,Wait(1)
exten => dummy,n,NoCDR()
exten => dummy,n,Hangup

';

$extracontext =~ s/DELIM/$delim/g;
$extracontext =~ s/PARKLINE/$parkline/g;

push @final_fop2_file, $extracontext;

@final_override_file = ();

if ($write) {
    if ( !-w $write_file ) {
        die("File $write_file is not writable. Aborting.\n");
    }
    if ( !-r $extensions_file ) {
        die("File $extensions_file is not readable. Aborting.\n");
    }
    print "Backing up $write_file to $write_file" . ".bak\n";
    copy( $write_file, $write_file . ".bak" ) or die("Could not perform backup!");
    print "Done!\n\n";

    open( CONFIG, "<$write_file" ) or die("Could not open $write_file. Aborting...");
    while (<CONFIG>) {
        if (/^\Q[\E/) {
            $context = $_;
            $context =~ s/\[(.*)\]/$1/g;
            chomp($context);
            if ( defined( $hash_contexts{$context} ) ) {
                $skip = 1;
            }
            else {
                $skip = 0;
            }
        }
        if (/^\Q#include\E/) {
            $skip = 0;
        }
        if ( !$skip ) {
            if ( !m|#include /etc/asterisk/extensions_override_fop2.conf| ) {
                push @final_override_file, $_;
            }
        }
    }
    close(CONFIG);
    push @final_override_file, "#include /etc/asterisk/extensions_override_fop2.conf\n";

    print "Cleaning and updating $write_file ...\n";
    open( CONFIG, ">$write_file" ) or die("Could not open $write_file for writing. Aborting...");
    foreach my $linea (@final_override_file) {
        print CONFIG $linea;
    }
    close(CONFIG);
    print "Done!\n\n";

    $write_file = "/etc/asterisk/extensions_override_fop2.conf";
    print "Creating $write_file ...\n";
    open( CONFIG, ">$write_file" ) or die("Could not open $write_file for writing. Aborting...");
    foreach my $linea (@final_fop2_file) {
        print CONFIG $linea;
    }
    close(CONFIG);
    print "Done!\n\n";
    print "Reloading asterisk dialplan...\n";
    $pepe = `/usr/sbin/asterisk -rx "dialplan reload"`;
    print "Done!\n\n";

    print "Generating FOP2 Manager configuration...\n";
    if( -r "/var/www/html/fop2/admin/update_conf.php") {
        $pepe = `php -f /var/www/html/fop2/admin/update_conf.php 1`;
        print "\n".$pepe."\n";
    }
    print "Finished!\n";
    exit;
}

if ($print_contexts) {
    foreach my $linea (@final_fop2_file) {
        print $linea;
    }
    exit;
}

__END__

=head1 NAME

generate_override_contexts.pl  - generates altered dialplan contexts for a tight integration between FOP2 and Freepbx

=head1 SYNOPSYS

./generate_override_contexts.pl [-print] [-write] [-file override_file] [-man] [-help]

=head1 DESCRIPTION

B<This program> will output modified FreePBX macros for DND and CF 
so they work with FOP2. It will also create the parking context needed
to make parking from FOP2 possible. It can perform a "dry run" when
invoked with the -print option, where it will just print the modified
contexts to standard output, or it can modify your current dialplan files
in asterisk, making a backup  or your original extensions_override_freepbx.conf
file and reloading the asterisk dialplan afterwards.

=head1 OPTIONS

=over 8

=item B<-help>

Print brief usage help and exits.

=item B<-man>

Print the full documentation and exits.

=item B<-print>

Print override contexts to standard output and exits.

=item B<-write>

Cleans your current extensions_override_freepbx.conf file from FOP2
modifications. Adds an #include line at the end and generates a separate
extensions_override_freepbx_fop2.conf file with the proper modifications
to make the DND and Call Forward integration between Fop2 and FreePBX.

=item B<-file>

Lets you specify the full path for your extensions_override_freepbx.conf file


=back

=cut

