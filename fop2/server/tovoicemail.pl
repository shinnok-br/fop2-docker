#!/usr/bin/perl -w

# Script to Move recordings initiated by FOP2 into the Voicemailbox
# of the user that requested the recording.

# In order for this script to work it must be owned by the same user
# asterisk is running as.
#
# You also have to check the locations of both sox and soxmix and
# the fop2.cfg file
#
# In fop2.cfg you MUST set the monitor filename and configurations to be:
#
# monitor_filename=/var/spool/asterisk/monitor/${ORIG_EXTENSION}_${DEST_EXTENSION}_${MBOX}_${UNIQUEID}
# monitor_format=wav
# monitor_mix=true
# monitor_exec=/usr/local/fop2/tovoicemail.pl
#
# The script must run on the same machine asterisk is installed. Be
# sure the VMAILPATH and DESTFOLDER match your installation. The default
# values should be ok for almost every standard install.

use strict;
use Fcntl;
use File::Copy;
use File::Basename;
use IO::Socket;

# configurable variables
my $VMAILPATH  = "/var/spool/asterisk/voicemail/";
my $DESTFOLDER = "INBOX";
my $FOPCFG     = "/usr/local/fop2/fop2.cfg";
my $SOX        = `which sox`;
my $SOXMIX     = `which soxmix`;

chomp($SOX);
chomp($SOXMIX);

my $plainmix = 0;

if($SOXMIX eq "") { $SOXMIX = "$SOX -m "; $plainmix=1; }

if( $#ARGV < 2 ){
  die("Not enough arguments\n\nUsage: tovoicemail.pl sound-in.wav sound-out.wav sound.wav\n");
}

# command line variables
my $LEFT  = shift(@ARGV);
my $RIGHT = shift(@ARGV);
my $OUT   = shift(@ARGV);

# do not edit below this line
if ( !-f $SOX ) {
    die("No sox found $SOX");
    exit 1;
}

if ( !-f $LEFT ) {
    die("No left sound file found");
    exit 1;
}

if ( !-f $RIGHT ) {
    die("No right sound file found");
    exit 1;
}

system("$SOX $LEFT -c 2 $LEFT-tmp.wav pan -1");
system("$SOX $RIGHT -c 2 $RIGHT-tmp.wav pan 1");

if($plainmix==1) {
    system("$SOXMIX $LEFT-tmp.wav $RIGHT-tmp.wav $OUT");
} else {
    system("$SOXMIX -v 1 $LEFT-tmp.wav -v 1 $RIGHT-tmp.wav -v 1 $OUT");
}

if ( -f $LEFT . "-tmp.wav" ) {
    unlink $LEFT . "-tmp.wav";
}

if ( -f $RIGHT . "-tmp.wav" ) {
    unlink $RIGHT . "-tmp.wav";
}

if ( -f $OUT ) {
    unlink $LEFT;
    unlink $RIGHT;
}

my $fnm      = $OUT;
my $basename = basename($OUT);
my ( $exten, $targetexten, $fullmbox, $uniqueid ) = split( /_/, $basename );

$uniqueid =~ s/\.wav//g;

my $ctx = "default";
my $EOL = "\r\n";

my $user = "admin";
my $pw   = "admin111";
my $host = "localhost";
my $port = "5038";

read_config($FOPCFG);

my $tc = new IO::Socket::INET(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => 30,
    Proto    => 'tcp'
) or die "Could not connect to Host: $host on port $port\n";

if ( $fullmbox =~ m/@/ ) {
    ( $exten, $ctx ) = split( /@/, $fullmbox );
}

sub wavduration {
    sysopen WAV, $fnm, O_RDONLY;
    my $riff;
    sysread WAV, $riff, 12;
    my $fmt;
    sysread WAV, $fmt, 24;
    my $data;
    sysread WAV, $data, 8;
    close WAV;
    my ( $r1, $r2, $r3 ) = unpack "A4VA4", $riff;
    my ( $f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8 ) = unpack "A4VvvVVvv", $fmt;
    my ( $d1, $d2 ) = unpack "A4V", $data;
    my $playlength = int( $d2 / $f6 );
    return $playlength;
}

sub msgcount {
    my ( $context, $mailbox, $folder ) = @_;
    my $path = $VMAILPATH . "/$context/$mailbox/$folder";
    if ( opendir( DIR, $path ) ) {
        my @msgs = grep( /^msg....\.txt$/, readdir(DIR) );
        closedir(DIR);
        return sprintf "%d", $#msgs + 1;
    }
    return 0;
}

sub login {
    my ( $response, $message );
    $tc->send( "Action: Login" . $EOL );
    $tc->send( "Username: $user" . $EOL );
    $tc->send( "Secret: $pw" . $EOL );
    $tc->send( "Events: off" . $EOL );
    $tc->send($EOL);
    while (<$tc>) {
        last if $_ eq $EOL;
        $_ =~ s/$EOL//g;
        ($response) = $_ =~ /^Response: (.*?)$/ if $_ =~ /^Response:/;
        ($message)  = $_ =~ /^Message: (.*?)$/  if $_ =~ /^Message:/;
    }
    return 0 if $response eq 'Success';
    return $message;
}

sub logoff {
    my ( $response, $message );
    $tc->send( "Action: Logoff" . $EOL . $EOL );
    return 1;
}

sub send_userevent {
    my $mailboxnum = shift;
    $tc->send( 'Action: UserEvent' . $EOL );
    $tc->send( 'UserEvent: FOP2RELOADVOICEMAIL' . $EOL );
    $tc->send( "Mailbox: $mailboxnum" . $EOL );
    $tc->send($EOL);
}

sub read_config {
    my $file = shift;
    return unless ( -r $file );
    open( my $fh, "<$file" ) or return;
    while (<$fh>) {
        chomp;
        $_ =~ s/^\s+//g;
        if ( /^#/ || /^;/ || /^$/ ) {
            next;
        }    # Ignores comments and empty lines
        ( undef, $user ) = split( /[,=]/, $_ ) if $_ =~ /manager_user(name)?[,=]/i;
        ( undef, $pw )   = split( /[,=]/, $_ ) if $_ =~ /manager_secret[,=]/i;
        ( undef, $host ) = split( /[,=]/, $_ ) if $_ =~ /manager_host(name)?[,=]/i;
        ( undef, $port ) = split( /[,=]/, $_ ) if $_ =~ /manager_port(num|no)?[,=]/i;
    }
    close($fh);
}

## MAIN **************************************

my $seconds = 0;
my $msgnum = msgcount( $ctx, $exten, $DESTFOLDER );
if ( -e $fnm ) {
    $seconds = wavduration($fnm);
}

my $fulltime = localtime();
my $epoch    = time;
my $msgfmt   = sprintf "%04d", $msgnum;
my $msginfo  = "$VMAILPATH/$ctx/$exten/$DESTFOLDER/msg" . $msgfmt . ".txt";
my $msgwav   = "$VMAILPATH/$ctx/$exten/$DESTFOLDER/msg" . $msgfmt . ".wav";

# To query Asterisk CDR records for the original callerid of the caller.
# You can then use the callerid variable in the msg info file.
#
# my $callerid = `mysql -sN -u root -ppassw0rd asteriskcdrdb -e "select dst from cdr where uniqueid='$uniqueid'"`;
# chomp($callerid);

my $header = ";\n";
$header .= "; Message Information File\n";
$header .= ";\n";
$header .= "[message]\n";
$header .= "origmailbox=$exten\n";
$header .= "exten=fop2-recording\n";
$header .= "context=fop2-recording\n";
$header .= "priority=1\n";
$header .= "callerchan=$targetexten\n";
$header .= "callerid=\"FOP2 Recording\" <$targetexten>\n";
$header .= "origdate=$fulltime\n";
$header .= "origtime=$epoch\n";
$header .= "category=FOP2Recording\n";
$header .= "duration=$seconds";

if ( -e $fnm ) {
    open FILE, ">$msginfo" or die $!;
    print FILE $header;
    close FILE;
    copy( $fnm, $msgwav );
    unlink($fnm);
}

if ( my $error = login() ) {
    print STDERR $error;
    exit 1;
}

send_userevent($fullmbox);
logoff();
