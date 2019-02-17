<?php
error_reporting(15);
require_once("config.php");
$texto     = $_REQUEST['term'];

if (!function_exists('json_encode')) {
    function json_encode($content) {
        require_once 'JSON.php';
        $json = new Services_JSON;
        return $json->encode($content);
    }
}

$extension = $_SESSION[MYAP]['extension'];
$context   = $_SESSION[MYAP]['context'];

if($context=="general") { $context=""; }

if(isset($_REQUEST['image'])) {
    // We query the image file on phonebook if any
    $res=$db->consulta("SELECT picture FROM visual_phonebook WHERE phone1='%s' OR phone2='%s' LIMIT 1",$_REQUEST['image'],$_REQUEST['image']);
    if($db->num_rows($res)>0) {
        $row=$db->fetch_assoc($res);
        echo $row['picture'];
    }
    exit;
}

if(preg_match("/\.tel$/",$texto)) {
    $results = query_tel($texto);
} else {
    $results = query_phonebook($texto);
}

echo json_encode($results);

function query_phonebook($texto) {
    global $db;
    global $context;
    global $extension;

    $ret = array();

    $results=array();
    $db->consulta("SET NAMES 'UTF8'");
    $res=$db->consulta("SELECT phone1,phone2,CONCAT(firstname,' ',lastname,' (',company,')') AS name FROM visual_phonebook WHERE CONCAT(firstname,' ',lastname,' ',company) LIKE '%%%s%%' AND context='%s' AND (owner='%s' OR (owner<>'%s' AND private='no')) ",$texto,$context,$extension,$extension);
    if($db->num_rows($res)>0) {
        while($row=$db->fetch_assoc($res)) {
            $htmlname = htmlspecialchars($row['name']);
            $htmlname = preg_replace("/\(\)/","",$htmlname);
            $phone1 = preg_replace("/[^0-9]/","", $row['phone1']); 
            $phone2 = preg_replace("/[^0-9]/","", $row['phone2']); 

            if($row['phone1']<>"") {
                $results[] = array('name'=>$htmlname,'value'=>$phone1);
            }
            if($row['phone2']<>"") {
                $results[] = array('name'=>$htmlname,'value'=>$phone2);
            }
        }
    } 
      return $results;
}

function query_tel($domain) {
    return ShowSection(dns_get_record ($domain,DNS_NAPTR));
}

function ShowSection($result) {
    $ret  = Array();
    $tel  = Array();
    $voip = Array();
    $replaceArray = array(array(), array()); 

    for ($i=0; $i<32; $i++)                 {
        $replaceArray[0][] = chr($i);
        $replaceArray[1][] = "";
    }

    for ($i=127; $i<160; $i++) {
        $replaceArray[0][] = chr($i);
        $replaceArray[1][] = "";
    }

    foreach($result as $idx => $record) {

        $record['services'] = str_replace($replaceArray[0], $replaceArray[1], $record['services']); 
        $record['regex'] = str_replace($replaceArray[0], $replaceArray[1], $record['regex']); 
        $papo = preg_split("/!/",$record['regex']);
        if(preg_match("/voice/",$record['services'])) {
           $tel[] = preg_replace("/tel:/","",$papo[2]);
        }  
        if(preg_match("/voip/",$record['services']) || preg_match("/sip/",$record['services'])) {
           $voip[] = preg_replace("/sip:/","SIP/",$papo[2]);
        }  
        if(preg_match("/skype/i",$record['services'])) {
           $voip[] = preg_replace("/skype:/i","SKYPE/",$papo[2]);
        }  
        if(preg_match("/web/",$record['services'])) {
           $web[] = preg_replace("/web:/","",$papo[2]);
        }  
    }

    foreach($tel as $valor) { 
        if($valor<>"") {
            $ret[]= array('name'=>"Voice",'value'=>$valor);
        }
    }
    foreach($voip as $valor) { 
        if($valor<>"") {
            $ret[]= array('name'=>"Voip",'value'=>$valor);
        }
    }
    foreach($web as $valor) { 
        if($valor<>"") {
            $ret[]= array('name'=>"Web",'value'=>$valor);
        }
    }
    return $ret;
}


