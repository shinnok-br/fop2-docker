#!/usr/bin/perl

$file = "/etc/asterisk/voicemail.conf";

open( CONFIG, "<$file" ) or die("Could not open $file");

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
       if($context =~ /^default/) {
           $context =~ s/^default-//g;
           if($hubo>0) {
               print "no_pickupmark=1\n";
               print "use_pickupchan=1\n";
               print "buttonfile=automatic-buttons.cfg $oldcontext\n\n";
               $hubo=0;
           }
           if($context ne "default") {
              print "[$context]\n";
           }
       }
   }
   if (/=>/) {
       $_ =~ s/\s//g;
       @partes = split(/=>/,$_,2);
       $exten = $partes[0];
       $resto = $partes[1];
       @partes = split(/,/,$resto,2);
       $secret = $partes[0];
       $permisos="";
       if($partes[1]=~m/fop2/) {
           $partes[1] =~ s/(.*)fop2=(.*)/$2/g;
           $permisos = $partes[1];
       };
       $oldcontext=$context;
       if($permisos ne "") {
           print "user=$exten:$secret:$permisos\n";
       }
       $hubo++;
   }

}
close(CONFIG);
print "no_pickupmark=1\n";
print "use_pickupchan=1\n";
print "buttonfile=automatic-buttons.cfg $oldcontext\n\n";
