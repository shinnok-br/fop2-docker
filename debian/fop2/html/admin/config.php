<?php
// If a known Asterisk configuration GUI/bakcend is found, then
// FOP2 Manager will try to use its database auth system by default.
// If you rather use the built in user manager and level system 
// (recommended), then set this parameter to false.
define('USE_BACKEND_AUTH',true);

// User/Pass to Log into FOP2Manager. If we detect a FreePBX session
// or a fop2 sessions with the "manager" permission, the authentication
// will be asumed as ok.

$ADMINUSER = "fop2admin";
$ADMINPWD  = "fop2admin";

// This database parameters are only needed if you are not using FreePBX, 
// PBX in a Flash, Elastix or Thirdlane 7
// If any of the above systems config files is found, connections details 
// on those config files will be used instead of what you set manually here

$DBHOST="localhost";
$DBUSER="fop2";
$DBPASS="";
$DBNAME="fop2";

// This is the preference sqlite database for FOP2 User and Context Preferences
$SQLITEDB="/usr/local/fop2/fop2settings.db";

// If you use non ASCII chars for labels and you do not see them properly, try
// forcing UTF8 on the MySQL connecton
$FORCE_UTF8=false;

// Plugin Directory. By default the subdirectory plugins of the working FOP2 
// Manager path will be used. If you want to place them in some other location
// uncomment the entry and point to the right path. Be sure that the directory
// owner/permissions allows the web server/php user to write into that directory
//
// $PLUGIN_DIR="/var/www/html/fop2/admin/plugins";

// If you have a PBX that cannot be auto detected, like MiRTA, specify the engine
// here. Otherwise leave this line commented. Available options: mirtapbx, custom
//
// $ENGINE="mirtapbx";

// Branding Settings
$APPNAME          = "FOP2 Manager";
$LOGONAME         = "<span style='font-weight:bold; color:#000;'>FOP2</span> <span style='color:#4EB855'>Manager</span>";
$LOGO             = "images/fop2managerlogo.png";

// General Application Settings
$DEBUG            = 0;
$BUTTONS_PER_PAGE = 150;

// Ombutel Special Config Files
foreach(glob('/etc/fop2/config-webadmin-*.conf') as $conf_file) {
       include_once($conf_file);
}


