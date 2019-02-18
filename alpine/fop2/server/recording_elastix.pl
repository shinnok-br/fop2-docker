#!/usr/bin/perl -w

# Script to make recordings initiated in fop2 available in the Elastix
# Monitoring Tool.

# In order for this script to work it must be owned by the same user
# asterisk is running as.
#
# You also have to check the locations of both sox and soxmix and
# the fop2.cfg file
#
# In fop2.cfg you MUST set the monitor filename and configurations to be:
#
# monitor_filename=/var/spool/asterisk/monitor/${ORIG_EXTENSION}_${DEST_EXTENSION}_%h%i%s_${UNIQUEID}
# monitor_format=wav
# monitor_mix=true
# monitor_exec=/usr/local/fop2/recording_elastix.pl
#
# The script must run on the same machine asterisk is installed. Be
# sure the DESTFOLDER exists and it is owned by the asterisk user. 
#

use strict;
use Fcntl;
use File::Copy;
use File::Basename;
use File::Path qw(mkpath);
use DBI;

# database connection
my $MYSQLUSER   = "fop2";
my $MYSQLPASS   = "";
my $MYSQLDBNAME = "asteriskcdrdb";
my $MYSQLTABLE  = "cdr";
my $MYSQLHOST   = "localhost";

# configurable variables
my $DESTFOLDER = "/var/spool/asterisk/monitor/";
my $SOX        = `which sox`;
my $SOXMIX     = `which soxmix`;

sub parse_amportal_conf {
    my $filename = shift;
    my %ampconf = (
            AMPDBENGINE => "mysql",
            AMPDBNAME => "asterisk",
            AMPENGINE => "asterisk",
    );
    open(AMPCONF, $filename) or die "Cannot open $filename ($!)";
    while (<AMPCONF>) {
        if ($_ =~ /^\s*([a-zA-Z0-9_]+)\s*=\s*(.*)\s*([;#].*)?/) {
            $ampconf{$1} = $2;
        }
    }
    close(AMPCONF);
    return \%ampconf;
}

if(-f "/etc/amportal.conf") {
    my $ampconf = parse_amportal_conf( "/etc/amportal.conf" );
    $MYSQLUSER   = $ampconf->{"AMPDBUSER"};
    $MYSQLPASS   = $ampconf->{"AMPDBPASS"};
    $MYSQLHOST   = $ampconf->{"AMPDBHOST"};
} elsif(-f "/etc/freepbx/freepbx.conf") {
    my $ampconf = parse_amportal_conf( "/etc/freepbx/freepbx.conf" );
    $MYSQLUSER   = $ampconf->{"AMPDBUSER"};
    $MYSQLPASS   = $ampconf->{"AMPDBPASS"};
    $MYSQLHOST   = $ampconf->{"AMPDBHOST"};
}

chomp($SOX);
chomp($SOXMIX);

my $plainmix = 0;

if($SOXMIX eq "") { $SOXMIX = "$SOX -m "; $plainmix=1; }

my $dbh;

# Remove trailing slash
$DESTFOLDER =~ s|/\z||;

if( $#ARGV < 2 ){
    die("Not enough arguments\n\nUsage: recording_elastix.pl sound-in.wav sound-out.wav sound.wav\n");
}

sub connect_db() {
    my $return = 0;
    my %attr   = (
        PrintError => 0,
        RaiseError => 0,
    );

    my $dsn = "DBI:mysql:database=$MYSQLDBNAME;host=$MYSQLHOST";
    $dbh->disconnect if $dbh;
    $dbh = DBI->connect( $dsn, $MYSQLUSER, $MYSQLPASS, \%attr ) or $return = 1;
    return $return;
}

# command line variables
my $LEFT  = shift(@ARGV);
my $RIGHT = shift(@ARGV);
my $OUT   = shift(@ARGV);
my $UNI   = shift(@ARGV);

if(!defined($UNI)) {
    $UNI="none";
}

# do not edit below this line
if ( !-f $SOX ) {
    die("No sox found $SOX");
    exit 1;
}

my $SOXVERSION =  `$SOX -h 2>&1  | head -n 1 | cut -d\. -f1 | awk '{print \$3}' | sed 's/[A-Za-z]//g'`;

if ( !-f $SOXMIX ) {
    print "No soxmix found\n";
    die("No soxmix found");
    exit 1;
}

if ( !-f $LEFT ) {
    print "No left found\n";
    die("No left sound file found");
    exit 1;
}

if ( !-f $RIGHT ) {
    print "No right found\n";
    die("No right sound file found");
    exit 1;
}

if($SOXVERSION>12) {
    # New SOX
    system("$SOX $LEFT -c 2 $LEFT-tmp.wav remix 1 0");
    system("$SOX $RIGHT -c 2 $RIGHT-tmp.wav remix 0 1");
} else {
    # Old SOX 
    system("$SOX $LEFT -c 2 $LEFT-tmp.wav pan -1");
    system("$SOX $RIGHT -c 2 $RIGHT-tmp.wav pan 1");
}

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
my ( $exten, $targetexten, $fullmbox, $uniqueid, $context ) = split( /_/, $basename );

if(!defined($context)) {
    $context="";
}

$uniqueid =~ s/\.wav//g;
$context  =~ s/\.wav//g;

sub wavduration {
    sysopen WAV, $fnm, O_RDONLY;
    my $riff;
    sysread WAV, $riff, 12;
    my $fmt;
    sysread WAV, $fmt, 24;
    my $data;
    sysread WAV, $data, 8;
    my ( $r1, $r2, $r3 ) = unpack "A4VA4", $riff;
    my ( $f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8 ) = unpack "A4VvvVVvv", $fmt;
    my ( $d1, $d2 ) = unpack "A4V", $data;
    my $playlength = int( $d2 / $f6 );
    return $playlength;
}


## MAIN **************************************

if ( -e $fnm ) {
    my $seconds = wavduration($fnm);
    my $whorecorded  = $exten;
    my $whomrecorded = $targetexten;
    my $duration     = $seconds;

    if($seconds > 4) {
        &connect_db();
        if($UNI ne "none") { $uniqueid = $UNI; }
        my $query = "UPDATE cdr SET userfield='audio:$fnm' WHERE uniqueid='$uniqueid'";
        $dbh->do($query);
        $dbh->disconnect if $dbh;
    } 
}
