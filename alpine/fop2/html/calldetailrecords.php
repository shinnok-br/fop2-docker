<?php
header("Content-Type: text/html; charset=utf-8");
require_once("config.php");

$context   = $_SESSION[MYAP]['context'];
$extension = $_SESSION[MYAP]['extension'];

$permit    = $_SESSION[MYAP]['permit'];
$admin     = isset($_SESSION[MYAP]['admin'])?$_SESSION[MYAP]['admin']:0;
$permisos  = preg_split("/,/",$permit);

if(in_array("callhistory",$permisos) || in_array("all",$permisos)) {
    $allowed='yes';
} else {
    $allowed='no';
}

$datefield = 'calldate';

// MiRTA PBX uses a different CDR schema where the date field
// is named start. If you use MiRTA uncomment the following line:
//
// $datefield = 'start';

?>
<!DOCTYPE html>
<html>
<head>
<?php
if(isset($page_title)) { 
    echo "    <title>$page_title></title>\n"; 
} else {
    echo "    <title>".TITLE."</title>\n"; 
}

if($allowed=="no") {
    echo "<meta http-equiv=\"refresh\" content=\"5\" >\n";
}

?>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
    <meta http-equiv="imagetoolbar" content="false"/>
    <meta name="MSSmartTagsPreventParsing" content="true"/>
    <meta name="description" content=""/>
    <meta name="keywords" content=""/>
    <link rel="stylesheet" type="text/css" href="css/jconf.css" />
    <link rel="stylesheet" type="text/css" href="css/chosen.css" />
    <link rel="stylesheet" type="text/css" href="css/jquery.noty.css" />
    <link href="css/bootstrap.min.css" media="screen" rel="stylesheet" type="text/css">
    <link rel="stylesheet" type="text/css" href="css/bootstrap.datepicker.css" />
    <link rel="stylesheet" type="text/css" href="css/dbgrid.css" />
    <link rel="stylesheet" type="text/css" href="css/flags.css" />
    <link rel="stylesheet" type="text/css" href="css/animate.css" />
    <link href="css/bootstrap-select.css" media="screen" rel="stylesheet" type="text/css">
    <script src="js/jquery-1.11.3.min.js" type="text/javascript"></script>
    <script src="js/moment-with-locales.js"></script>
    <script type="text/javascript" src="js/jquery.plugin.js"></script>
    <script type="text/javascript" src="js/jquery.noty.js"></script>
    <script type="text/javascript" src="js/chosen.jquery.min.js"></script>
    <script type="text/javascript" src="js/jquery.jconf.js"></script>
    <script src="js/bootstrap.min.js" type="text/javascript"></script>
    <script src="js/bootstrap-switch.min.js" type="text/javascript"></script>
    <script src="js/bootstrap-dropdown-on-hover.js " type="text/javascript"></script>
    <script type="text/javascript" src="js/bootstrap.datepicker.js"></script>
    <script type="text/javascript" src="js/jquery.datetimeentry.js"></script>
    <script type="text/javascript" src="js/jquery.tools.form.min.js"></script>
    <script type="text/javascript" src="js/jquery.colresizable.min.js"></script>
    <script type="text/javascript" src="js/jquery.browser.js"></script>
    <script type="text/javascript" src="js/jquery.autoheight.js"></script>
    <script src="js/bootstrap-select.js" type="text/javascript"></script>
<?php
if(isset($extrahead)) {
    foreach($extrahead as $bloque) {
        echo "$bloque";
    }
}
?>
<script>

jQuery(document).ready(function($) {

    jQuery.ajaxSetup({async: false});
    $.getScript("js/presence.js", function() {
        var ret = jQuery.getScript("js/lang_"+language+".js");
        if(ret==1) {
            jQuery.getScript("js/lang_en.js");
        }
        $('.clicktodial').attr('data-original-title',lang.dial);
    });
    jQuery.ajaxSetup({async: true});
});


function debug(message) {
    if(window.console !== undefined) {
        console.log(message);
    }
};

function setFilterDir(elem) {
    valor = elem.options[elem.selectedIndex].value;
    insertParam('filterdir',valor);
}

function setFilterDispo(elem) {
    valor = elem.options[elem.selectedIndex].value;
    insertParam('filterdispo',valor);
}


function insertParam(key, value)
{
    key = escape(key); value = escape(value);

    var kvp = document.location.search.substr(1).split('&');

    var i=kvp.length; var x; while(i--) 
    {
        x = kvp[i].split('=');

        if (x[0]==key)
        {
                x[1] = value;
                kvp[i] = x.join('=');
                break;
        }
    }

    if(i<0) {kvp[kvp.length] = [key,value].join('=');}

    //this will reload the page, it's likely better to store this until finished
    document.location.search = kvp.join('&'); 
}

function playVmail(hash,file,iconid) {

    var url  = 'setvar.php';
    var pars = 'sesvar=vfile&value='+file;
    var url2 = "download.php?file="+hash+"!"+file;

    if($(''+iconid).hasClassName('pauseicon')) {
        window.TinyWav.Pause(url2,iconid);
    } else {
        $(''+iconid).addClassName('waiticon');

        var pepe = new Ajax.Request(url, {
          method: 'post',
          postBody:pars,
          onSuccess: function(transp) {
              debug("success "+url2);
              if($(''+iconid).hasClassName('playicon')) {
                  $(''+iconid).removeClassName('waiticon');
                  debug("success play");
                  window.TinyWav.Play(url2,iconid);
              }
          }
        });
    }
}

function downloadVmail(hash,file) {

    var url   = 'setvar.php';
    var pars1 = 'sesvar=vfile&value='+file;
    var pars2 = hash+"!"+file;
    var areq = new Ajax.Request(url, {
      method: 'post',
      postBody:pars1,
      onSuccess: function(transp) {
          downloadFile("download.php",pars2);
      }
    });
}

function downloadFile(url,pars) {
    $('#dloadfrm').attr('action',url);
    $('#file').val(pars); 
    $('#dloadfrm').submit();
}

</script>

</head>
<body style='overflow-x: hidden;'>
<div class='xcontainer-fluid'>
<?php

if($allowed <> "yes") {
    
    if(!isset($_SESSION[MYAP]['retries'])) {
        $_SESSION[MYAP]['retries']=1;
    } else {
        $_SESSION[MYAP]['retries']++;
    }

   echo "<div class='container-fluid text-center'><br/>";

   if($_SESSION[MYAP]['retries']>10) {
       echo "<h3 class='animated tada'>You do not have permissions to access this resource</h3>";
       echo "<br/><br/><btn class='btn btn-default' onclick='javascript:window.location.reload();'>Refresh</button>";
   } else {
       echo "<h3>Please wait...</h3>";
   }
   echo "</div>";
   die();
}

if($context=="") { 
    $addcontext="";
} else {
    $addcontext="${context}_";
}

// Sanitize Input
$addcontext = preg_replace("/\.[\.]+/", "", $addcontext);
$addcontext = preg_replace("/^[\/]+/", "", $addcontext);
$addcontext = preg_replace("/^[A-Za-z][:\|][\/]?/", "", $addcontext);

$extension = preg_replace("/'/", "",  $extension );
$extension = preg_replace("/\"/", "", $extension );
$extension = preg_replace("/;/", "",  $extension );

$transinbound = trans('inbound');
$transoutbound = trans('outbound');

$grid =  new dbgrid($db);
$grid->set_table($CDRDBTABLE);
$grid->set_pk('uniqueid');
$grid->add_structure('number', 'text',null,'');
$grid->salt("dldli3ksa");
$grid->set_fields("$datefield,IF(dst='".$extension."' OR dstchannel LIKE 'SIP/$extension-________' OR dstchannel LIKE 'PJSIP/$extension-________','$transinbound','$transoutbound') as direction,IF(dst='".$extension."' OR dstchannel LIKE 'SIP/$extension-________' OR dstchannel LIKE 'PJSIP/$extension-________',src,dst) as number,duration,billsec,disposition,uniqueid,clid");
$grid->hide_field('uniqueid');
$grid->hide_field('clid');
//$grid->no_edit_field('uniqueid');
$grid->no_edit_field('number');
$grid->set_per_page(8);


$condstring="";

$mifilt = $_REQUEST['filterdir'];

if($mifilt=="") {
    $condstring ="(src='$extension' OR channel LIKE 'SIP/$extension-________' OR channel LIKE 'PJSIP/$extension-________' OR dst='$extension' OR dstchannel LIKE 'SIP/$extension-________' OR dstchannel LIKE 'PJSIP/$extension-________' ) ";
} else if($mifilt=="inbound") {
    $condstring ="(dst='$extension' OR dstchannel LIKE 'SIP/$extension-________' OR dstchannel LIKE 'PJSIP/$extension-________') ";
} else {
    $condstring="(src='$extension' OR channel LIKE 'SIP/$extension-________' OR channel LIKE 'PJSIP/$extension-________')";
}

$customboton="<form class='form-inline'><div class='form-group'>
             <select class='form-control selectpicker' name='filterby' onchange='setFilterDir(this)'>";
$customboton.="<option value='' "; if($mifilt=='') { $customboton.= 'selected'; }; $customboton.= ">".trans('All')."</option>\n";
$customboton.="<option value='inbound' "; if($mifilt=='inbound'){ $customboton.= 'selected';}; $customboton.= ">".trans('inbound')."</option>\n";
$customboton.="<option value='outbound' ";if($mifilt=='outbound'){ $customboton.= 'selected';}; $customboton.= ">".trans('outbound')."</option>\n";
$customboton.="</select></div>\n";

$grid->add_custom_toolbar($customboton);

$mifilt = $_REQUEST['filterdispo'];

if($mifilt<>"") {
    if($condstring<>"") { $condstring .= " AND "; }
    $condstring .="(disposition='".strtoupper($mifilt)."') ";
} 

// Uncomment this if you want to make the cdr reports tenant aware in Thirdlane or similar setups
// The userfield might need to be changed to the proper field
//
// if($condstring<>"") { $condstring .= " AND "; }
// $condstring .= "(userfield='$context') ";


$customboton="<div class='form-group'>
             <select class='form-control selectpicker' name='filterbydispo' onchange='setFilterDispo(this)'>";
$customboton.="<option value='' "; if($mifilt=='') { $customboton.= 'selected'; }; $customboton.= ">".trans('All')."</option>\n";
$customboton.="<option value='answered' "; if($mifilt=='answered'){ $customboton.= 'selected';}; $customboton.= ">".trans('Answered')."</option>\n";
$customboton.="<option value='no answer' ";if($mifilt=='no answer'){ $customboton.= 'selected';}; $customboton.= ">".trans('No answer')."</option>\n";
$customboton.="<option value='busy' ";if($mifilt=='busy'){ $customboton.= 'selected';}; $customboton.= ">".trans('Busy')."</option>\n";
$customboton.="<option value='failed' ";if($mifilt=='failed'){ $customboton.= 'selected';}; $customboton.= ">".trans('Failed')."</option>\n";
$customboton.="</select></div></form>\n";
$grid->add_custom_toolbar($customboton);


$grid->set_condition($condstring);

$fieldname = Array();
$fieldname[]=trans('Date');
$fieldname[]=trans('Direction');
$fieldname[]=trans('Number');
$fieldname[]=trans('Duration');
$fieldname[]=trans('Billsec');
$fieldname[]=trans('Disposition');
$fieldname[]=trans('Uniqueid');
$fieldname[]=trans('Clid');
$fieldname[]=trans('src');
$fieldname[]=trans('dst');
$fieldname[]=trans('dcontext');
$fieldname[]=trans('channel');
$fieldname[]=trans('dstchannel');
$fieldname[]=trans('lastapp');
$fieldname[]=trans('lastdata');
$fieldname[]=trans('amaflags');
$fieldname[]=trans('accountcode');
$fieldname[]=trans('userfield');
$fieldname[]=trans('did');
$fieldname[]=trans('recordingfile');
$fieldname[]=trans('cnum');
$fieldname[]=trans('cnam');
$fieldname[]=trans('outbound_cnum');
$fieldname[]=trans('outbound_cnam');
$fieldname[]=trans('dst_cnam');
$grid->set_display_name( array($datefield,'direction','number','duration','billsec','disposition', 'uniqueid', 'clid', 'src', 'dst', 'dcontext', 'channel', 'dstchannel', 'lastapp', 'lastdata', 'amaflags', 'accountcode', 'userfield', 'did', 'recordingfile', 'cnum', 'cnam', 'outbound_cnum', 'outbound_cnam', 'dst_cnam'), $fieldname);

$grid->set_nocheckbox(true);
$grid->allow_view(true);
$grid->allow_edit(false);
$grid->allow_delete(false);
$grid->allow_add(false);
$grid->allow_export(false);
$grid->allow_import(false);
$grid->allow_search(true);
$grid->set_orderby("$datefield");
$grid->set_orderdirection("DESC");
$grid->set_search_fields(array('src','dst',$datefield,'clid','uniqueid'));

$grid->add_display_filter('disposition','dispoColor');
//$grid->add_display_filter('filename','downloadfile');

/*
$grid->set_input_parent_style("uniqueid","style='width:48%; float:left;'");
$grid->set_input_parent_style("datetime","style='width:48%; float:right; margin-right:10px;'");
$grid->set_input_parent_style("ownerextension","style='clear:both;width:48%; float:left;'");
$grid->set_input_style("ownerextension","style='text-indent:120px;'");
$grid->set_input_style("targetextension","style='text-indent:120px;'");
$grid->set_input_parent_style("targetextension","style='width:48%; float:right; margin-right:10px;'");
*/
//$grid->add_validation_type('email','email');

$grid->add_display_filter('number','clickdial');

$grid->show_grid();

function dispoColor($dispo,$datos) {

   $clid = htmlentities($datos['clid']);

   $color=array();
   $color['ANSWERED']="<span class='label label-success' title='$clid'>".trans($dispo)."</span>";
   $color['NO ANSWER']="<span class='label label-danger' title='$clid'>".trans($dispo)."</span>";
   $color['FAILED']="<span class='label label-danger' title='$clid'>".trans($dispo)."</span>";
   $color['BUSY']="<span class='label label-warning' title='$clid'>".trans($dispo)."</span>";
   if(isset($color[$dispo])) {
      return $color[$dispo];
   } else {
      return $dispo;
   }
}

function downloadfile($filename) {
   $hash=md5($_SESSION[MYAP]['key']);
   return "<div id='$filename' class='playicon' title='Play' onclick='playVmail(\"$hash\",\"$filename\",\"$filename\")'><img src='images/pixel.gif' width=16 height=16 alt='pixel' border='0' /></div><div onclick='javascript:downloadVmail(\"$hash\",\"$filename\");' class='downloadicon' title='Download' id='downloadvm_$filename'><img src='images/pixel.gif' width=16 height=16 alt='pixel' border='0' /></div>";
}

function clickdial($number,$datos) {

   global $transoutbound;

   $numberstrip = preg_replace("/[^0-9#\*]/","",$number);
   $clid = htmlentities($datos['clid']);

   if($datos['direction']==$transoutbound) {
      $toprint = $number;
   } else {
      $toprint = $clid;
   }

   if(strlen($numberstrip)>0) {
       return "<div style='height:1.5em;'><a data-toggle='tooltip' class='clicktodial' data-original-title='click to dial' href='javascript:void();' onclick='parent.dial(\"$numberstrip\"); return false;'>$toprint</a></div>";
   } else {
       return $number;
   }
}


?>
</div>
<form id='dloadfrm' method='post'><input type=hidden id='file' name='file'/></form>
</body>
</html>
