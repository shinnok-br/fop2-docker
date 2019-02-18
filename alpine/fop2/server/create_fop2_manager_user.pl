#!/usr/bin/perl
use File::Copy;
use Getopt::Long;
use Pod::Usage;

my $help              = 0;
my $user              = 'fop2';
my $manager_conf_file = "";
my $fop2_conf_file    = "/usr/local/fop2/fop2.cfg";
my $manager_file      = "";
my $fop2_file         = "";

GetOptions(
    "help|?"                    => \$help,
    "u|user=s"                  => \$user,
    "mcf|managerconfigfile=s"   => \$manager_conf_file,
    "fff|fop2configfile=s"      => \$fop2_conf_file
) or pod2usage(2);

pod2usage(1) if $help;


my $do=0;

if ( $manager_conf_file eq "" ) {
    if ( -f "/etc/asterisk/manager.conf") {
        $manager_file = "/etc/asterisk/manager.conf";
        $do=1;
    }
    if ( -f "/etc/asterisk/manager_custom.conf") {
        $manager_file = "/etc/asterisk/manager_custom.conf";
        $do=1;
    }
    if ( -f "/etc/xivo/common.conf" ) {
        $manager_file = "/etc/asterisk/manager.d/fop2.conf";
    }
} else {
    if ( -f $manager_conf_file) {
        $do=1;
    }
    $manager_file = $manager_conf_file;
}

if($do==0) {
    print "Cannot find a valid manager configuration file ($manager_file) to add the user. Aborting...\n";
    exit 1;
}

$do=0;
if ( $fop2_conf_file eq "" ) {
    if ( -f "/etc/asterisk/fop2/fop2.cfg") {
        $fop2_file = "/etc/asterisk/fop2/fop2.cfg";
        $do=1;
    }
    if ( -f "/usr/local/fop2/fop2.cfg") {
        $fop2_file = "/usr/local/fop2/fop2.cfg";
        $do=1;
    }
} else {
    if ( -f $fop2_conf_file) {
        $do=1;
    }
    $fop2_file = $fop2_conf_file;
}


if($do==0) {
    print "Cannot find a valid FOP2 configuration file ($fop2_file) to set the user/secret. Aborting...\n";
    exit 1;
}

$password = random_string(20);

if(check_if_manager_user_exists($user)) {
    $password = extract_password_for_manager_user($manager_file,$user);
    update_fop2_config_file($fop2_file,$user,$password);
} else {
    append_user_to_manager_conf_file($manager_file,$user,$password);
    update_fop2_config_file($fop2_file,$user,$password);
}

sub extract_password_for_manager_user() {
    $manager_file = shift;
    $user = shift;
    $clave = '';
    open( CONFIG, "<$manager_file" ) or die("Could not open $manager_file. Aborting...");
    my $douser   = 0;
    while (<CONFIG>) {
        $linea = $_;
        $linea =~ s/^\s+|\s+$//g;
        $linea =~ s/\s//g;
        if($linea =~ m/^\[$user\]/) {
            $douser=1;
        }
        if($douser==1) {
             if($linea =~ m/^secret/) { 
                 $douser=0;
                 @partes = split(/=/,$linea);
                 $clave = $partes[1];
             }
        }
    }
    return $clave;
}

sub check_if_manager_user_exists() {
    $user = shift;
    $manager_users = `/usr/sbin/asterisk -rx "manager show users"`;
    @lineas = split(/\n/,$manager_users);
    foreach my $linea (@lineas) {
        if($linea eq $user) {
            print ("User '$user' already exists in Asterisk Manager configuration\n");
            return 1;
        }
    }
    return 0;
}


sub append_user_to_manager_conf_file() {
    $manager_file = shift;
    $user         = shift;
    $password     = shift;
    $manager_user = "
[#{USER}]
secret=#{SECRET}
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read=all
write=all
writetimeout=1000
eventfilter=!Event: RTCP*
eventfilter=!Event: VarSet
eventfilter=!Event: Cdr
eventfilter=!Event: AGIExec
eventfilter=!Event: ExtensionStatus
eventfilter=!Event: ChannelUpdate
eventfilter=!Event: ChallengeSent
eventfilter=!Event: SuccessfulAuth
eventfilter=!Event: HangupRequest
eventfilter=!Event: SoftHangupRequest
eventfilter=!Event: MusicOnHold
eventfilter=!Event: LocalBridge 
";

    $manager_user =~ s/#{SECRET}/$password/g;
    $manager_user =~ s/#{USER}/$user/g;

    if( ! -f $manager_file ) {
        my $lfh;
        open($lfh, '>', $manager_file) or
            die "Unable to open file $manager_file : $!";
        close($lfh) or die "Unable to close file : $manager_file $!";
    } else {
# Backup manager config file
        print "Backing up $manager_file to $manager_file" . ".bak\n";
        copy( $manager_file, $manager_file . ".bak" ) or die("Could not perform backup!");
        print "Done!\n\n";
    }

# Append fop2 manager user at the end of manager configuration file
    print "Appending $user configuration at the end of $manager_file...\n";
    open(my $fh, '>>', $manager_file) or die "Could not open file '$manager_file' $!";
    print $fh $manager_user;
    close $fh;
    print "Done!\n\n";
}

sub update_fop2_config_file() {

    $fop2_file = shift;
    $user      = shift;
    $password  = shift;

# Backup fop2 config file
    print "Backing up $fop2_file to $fop2_file" . ".bak\n";
    copy( $fop2_file, $fop2_file . ".bak" ) or die("Could not perform backup!");
    print "Done!\n\n";

# Read fop2.cfg file line by line and replace manager_user and manager_secret, only first appeareance
    my @final_fop2_file;
    open( CONFIG, "<$fop2_file" ) or die("Could not open $fop2_file. Aborting...");
    my $douser   = 0;
    my $dosecret = 0;
    while (<CONFIG>) {
        $linea = $_;
        $linea =~ s/^\s+|\s+$//g;
        $linea =~ s/\s//g;
        if($linea =~ m/^manager_user=/) {
            if($douser==0) {
                $douser=1;
                push @final_fop2_file, "manager_user=$user\n";
            }
        } elsif ($linea =~ m/^manager_secret=/) {
            if($dosecret==0) {
                $dosecret=1;
                push @final_fop2_file, "manager_secret=$password\n";
            }
        } else {
            push @final_fop2_file, $_;
        }
    }
    close(CONFIG);

    print "Writing updated $fop2_file...\n";
    open( CONFIG, ">$fop2_file" ) or die("Could not open $fop2_file for writing. Aborting...");
    foreach my $linea (@final_fop2_file) {
        print CONFIG $linea;
    }
    close(CONFIG);
}


print "Done!\n\n";

print "Reloading Asterisk Manager configuration...\n";
$pepe = `/usr/sbin/asterisk -rx "manager reload"`;
print "Done!\n\n";

print "Restarting FOP2...\n";
if(-f "/etc/rc.d/init.d/fop2") {
    $pepe = `/etc/rc.d/init.d/fop2 restart`;
} elsif (-f "/etc/init.d/fop2") {
    $pepe = `/etc/init.d/fop2 stop`;
    $pepe = `/etc/init.d/fop2 start`;
}
print "Done!\n\n";

sub random_string() {
    my $length = shift;
    my @chars = ("A".."Z", "a".."z");
    my $string;
    $string .= $chars[rand @chars] for 1..$length;
    return $string;
}
