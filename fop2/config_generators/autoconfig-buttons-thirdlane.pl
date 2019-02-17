#!/usr/bin/perl

$mycontext = $ARGV[0];

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
               $hubo=0;
           }
       }
   }
   if (/=>/) {
       $_ =~ s/\s//g;
       @partes = split(/=>/,$_,2);
       $exten = $partes[0];
       $resto = $partes[1];
       @partes = split(/,/,$resto);
       $email = $partes[2];
       if($email ne "") {
          $emails->{$context}{$exten}=$email;
       }
       $hubo++;
   }
}
close(CONFIG);

$hubo=0;


$file = "/etc/asterisk/users.txt";

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
       @partes = split (/-/,$context,2);
       $context= $partes[0];
       $extension = $partes[1];
       if($context eq $mycontext) {
          $dale=1;
       } else {
          $dale=0;
       }
   } else {
       if($dale==1) {
         my ($key,$val) = split(/=/,$_,2);
         $config->{$mycontext}{$extension}{$key}=$val;
       }
   }
}
close(CONFIG);

while ( my ( $uno, $dos ) = each( %{ $config->{$mycontext} } ) ) {
   $label = $dos->{first_name}." ".$dos->{last_name};
   $exten = $dos->{ext};
   $ctx = "from-inside-$mycontext";
   $mbox = $dos->{mailbox};
   $chan = $dos->{phones};
   print "[$chan]\n";
   print "type=extension\n";
   print "extension=$exten\n";
   print "context=$ctx\n";
   print "label=$label\n";
   print "mailbox=$mbox\n";
   if(defined($emails->{$mycontext}{$exten})) {
       print "email=".$emails->{$mycontext}{$exten}."\n";
   }
   print "\n";
}

$file = "/etc/asterisk/queues.conf";

open( CONFIG, "<$file" ) or die("Could not open $file");
$dale=0;
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
       $queuecontext = $_;
       @partes = split (/-/,$queuecontext);
       $context = pop @partes;
       $queue = join('-',@partes);
       if($context eq $mycontext) {
          $dale++;
          print "[QUEUE/$queue-$context]\n";
          print "type=queue\nlabel=$queue\nextension=$dale\ncontext=$context\n\n";
       } 
   } 
}
close(CONFIG);

$file = "/etc/asterisk/meetme.txt";
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
       @partes = split (/-/,$context,2);
       $context= $partes[1];
       $queue = $partes[0];
       if($context eq $mycontext) {
          $dale=1;
       } else {
          $dale=0;
       }
   }  else {
      if($dale==1) {                                                            
         my ($key,$val) = split(/=/,$_,2);                                      
         $config2->{$mycontext}{$queue}{$key}=$val;                             
      }                                                                         
   }                                                                            
}                                                                               
close(CONFIG);                                                                  
while ( my ( $uno, $dos ) = each( %{ $config2->{$mycontext} } ) ) {
   $label = $dos->{description};
   $exten = substr($dos->{conference},5);
   $room = $dos->{conference};
   $ctx = "from-inside-$mycontext";
   print "[CONFERENCE/$room]\n";
   print "type=conference\n";
   print "extension=$exten\n";
   print "context=$ctx\n";
   print "label=$label\n\n";
}

