<?php
header("Content-Type: text/html; charset=utf-8");
require_once("config.php");

$requestaction = isset($_REQUEST['action'])?$_REQUEST['action']:'list';

$ris = $db->consulta("SET NAMES utf8");

// Session Variables
$context   = isset($_SESSION[MYAP]['context'])?$_SESSION[MYAP]['context']:'';
$extension = isset($_SESSION[MYAP]['extension'])?$_SESSION[MYAP]['extension']:-1;
$admin     = isset($_SESSION[MYAP]['admin'])?$_SESSION[MYAP]['admin']:0;
$allowed   = isset($_SESSION[MYAP]['phonebook'])?$_SESSION[MYAP]['phonebook']:'no';


if(isset($_SESSION[MYAP]['permit'])) {
    $permits = preg_split("/,/",$_SESSION[MYAP]['permit']);
    if($allowed=='no' && in_array('phonebook',$permits)) {
       $allowed='yes';
    }
}


$addcontext=$context;
if($context<>'') {
    $addcontext=$context."_";
}
// Sanitize Input
$addcontext = preg_replace("/\.[\.]+/", "", $addcontext);
$addcontext = preg_replace("/^[\/]+/", "", $addcontext);
$addcontext = preg_replace("/^[A-Za-z][:\|][\/]?/", "", $addcontext);

$userdirectory = './uploads/'.$addcontext;

$notallowed = '';
if($extension == -1 || $allowed<>'yes') {

    if(!isset($_SESSION[MYAP]['retries'])) {
        $_SESSION[MYAP]['retries']=1;
    } else {
        $_SESSION[MYAP]['retries']++;
    }

    // If no session extension is set, kick the user out
    if($_SESSION[MYAP]['retries']>10) {
        $notallowed = "<br><br><div class='container-fluid text-center'><br/><h3 class='animated tada'>You do not have permissions to access this resource</h3></div>";
$notallowed.= "extension $extension allowed $allowed<br>";
$notallowed.=print_r($_SESSION[MYAP]);
    } else {
        $notallowed = "<br><br><div class='container-fluid text-center'><br/><h3>Please wait...</h3></div>";
    }
}

// Create visual phonebook table if it does not exist
$res = $db->consulta("desc visual_phonebook");
if(!$res) {
    $querycreate = "CREATE TABLE `visual_phonebook` (
      `id` int(11) not null auto_increment,
      `firstname` varchar(50) default null,
      `lastname` varchar(50) default null,
      `company` varchar(100) default null,
      `phone1` varchar(50) default null,
      `phone2` varchar(50) default null,
      `owner` varchar(50) default '',
      `private` enum('yes','no') default 'no',
      `picture` varchar(100) default null,
      `email` varchar(150) default '',
      `address` varchar(150) default '',
      `context` varchar(150) default '',
      primary key  (`id`),
      key `search` (`firstname`,`lastname`,`company`)
    ) engine=myisam default charset=utf8";
    $ris = $db->consulta($querycreate);
    if(!$ris) {
        echo "<h1><br/>could not connect/create the phonebook table.<br/><br/>please verify your mysql credentials in config.php.</h1>";
        die();
    }
}

// Update tables for older versions
$alldbfields   = array();
$alldbfields['visual_phonebook']['email']= "alter table `visual_phonebook` add `email` varchar(150) default '' after phone2";
$alldbfields['visual_phonebook']['address']= "alter table `visual_phonebook` add `address` varchar(150) default '' after email";

foreach($alldbfields as $table => $rest) {

    $res = $db->consulta("desc $table");

    if($res) {

        // table exists, check if we need to add /update_fields to it
        $existdbfield = array();
        while($row = $db->fetch_assoc($res)) {
            $campo = $row['Field'];
            $existdbfield[$campo]=1;
        }

        foreach($rest as $campo=>$query) {
            if(!isset($existdbfield[$campo])) {
                $db->consulta($query);
                $updated_field[$table][$campo]=1;
            }
        }
    }
}

function process_csv($file) {
    global $db, $extension, $userdirectory;

    $validfields  = array();
    $validfields[]='firstname';
    $validfields[]='lastname';
    $validfields[]='phone1';
    $validfields[]='phone2';
    $validfields[]='company';
    $validfields[]='picture';
    $validfields[]='private';
    $validfields[]='owner';
    $validfields[]='context';

    $db->consulta("SET NAMES utf8");
    $fp=fopen($file,"r");
    $cont=0;
    $cuantascolumnas=0;
    $invalidlines=0;

    while(($datos = fgetcsv($fp,'',",")) !== FALSE) {
        if($cont==0) {
            $columnas = $datos;
            $cuantascolumnas = count($columnas);
            $valid = 0;
            foreach($validfields as $field) {
                if(in_array($field,$columnas)) {
                    $valid++;
                }
            }
            if($valid==0) {
                $return[] = array('kind'=>'warning','message'=>trans('No valid fields to import!'));
                break;
            }

        } else {
            $cuantascolumnashay = count($datos);
            if($cuantascolumnashay<=1) { continue; } // skip linea en blanco
            if($cuantascolumnashay==$cuantascolumnas) {
                $update = array();
                $campos  = "(`".implode($columnas,"`,`")."`)";
                $valores = "(";
                $valarray=array();
                foreach($datos as $idx=>$val) {
                    $val = htmlentities($val);
                    $valarray[]="'".$val."'";
                }
                $valores .= implode(",",$valarray).")";
                $query = "REPLACE INTO visual_phonebook $campos VALUES $valores";
                $db->consulta($query);
            } else {
                $invalidlines++;
            }
        }
        $cont++;
    }
    fclose($fp);
    unlink($file);
    if($invalidlines>0) {
        $return[] = array('kind'=>'success','message'=>trans('%d lines ignored',$invalidlines));
    }
    if($cont>0) {
        $cont--; // supress header
        $return[] = array('kind'=>'success','message'=>trans('%d records imported',$cont));
    }

    return $return;
           
}

// Shows edit / insert form

function edit_form($row) {
    global $extension, $userdirectory;

    if(count($row)==0) {
        $action    = 'insert';
        $firstname = '';
        $lastname  = '';
        $company   = '';
        $phone1    = '';
        $phone2    = '';
        $picture   = '';
        $address   = '';
        $email     = '';
        $id        = '';
        $private   = '';
        $owner     = $extension;

    } else {
        $firstname = $row['firstname'];
        $lastname  = $row['lastname'];
        $company   = $row['company'];
        $phone1    = $row['phone1'];
        $phone2    = $row['phone2'];
        $picture   = $row['picture'];
        $address   = $row['address'];
        $email     = $row['email'];
        $owner     = $row['owner'];
        $private   = $row['private'];
        $id        = $row['id'];
        $action    = 'save';
    }

?>
<div class="row" style='margin-left:3px; margin-right:3px;'>
<form method='post' enctype='multipart/form-data'>
  <input type=hidden name='action' value='<?php echo $action;?>'>
  <input type=hidden name='id' value='<?php echo $id;?>'>

  <div class="image-editor" style='margin-bottom:10px'>
    <input type="file" class="cropit-image-input">
    <div class="cropit-image-preview" style="background-image: url(<?php echo "${userdirectory}${picture}";?>);"  ></div>
  
    <div class="row" style='padding-top:10px; padding-left:15px;'> 
    <div class="col-xs-6 select-image-btn btn btn-primary btn-sm"><?php echo trans('New Image');?></div>
    <div class="col-xs-6"> 

    <div class="slider-wrapper"><span class="icon icon-image small-image"></span><input type="range" class="cropit-image-zoom-input" min="0" max="1" step="0.01"><span class="icon icon-image large-image"></span></div>

    </div>
    </div>

    <input type="hidden" name="image-data" class="hidden-image-data" />
  </div>

  <div class="form-group">
    <label for="firstname"><?php echo trans('First Name');?></label>
    <input type="text" class="form-control" name="firstname" id="firstname" placeholder="<?php echo trans('First Name');?>" value='<?php echo $firstname;?>'>
  </div>
  <div class="form-group">
    <label for="lastname"><?php echo trans('Last Name');?></label>
    <input type="text" class="form-control" name="lastname" id="lastname" placeholder="<?php echo trans('Last Name');?>" value='<?php echo $lastname;?>'>
  </div>
  <div class="form-group">
    <label for="company"><?php echo trans('Company');?></label>
    <input type="text" class="form-control" name="company" id="company" placeholder="<?php echo trans('Company');?>" value='<?php echo $company;?>'>
  </div>
  <div class="form-group">
    <label for="address"><?php echo trans('Address');?></label>
    <input type="text" class="form-control" name="address" id="address" placeholder="<?php echo trans('Address');?>" value='<?php echo $address;?>'>
  </div>
  <div class="form-group">
    <label for="phone1"><?php echo trans('Phone 1');?></label>
    <input type="text" class="form-control" name="phone1" id="phone1" placeholder="<?php echo trans('Phone 1');?>" value='<?php echo $phone1;?>'>
  </div>
  <div class="form-group">
    <label for="phone2"><?php echo trans('Phone 2');?></label>
    <input type="text" class="form-control" name="phone2" id="phone2" placeholder="<?php echo trans('Phone 2');?>" value='<?php echo $phone2;?>'>
  </div>
  <div class="form-group">
    <label for="email"><?php echo trans('Email');?></label>
    <input type="text" class="form-control" name="email" id="email" placeholder="<?php echo trans('Email');?>" value='<?php echo $email;?>'>
  </div>
<?php
if($owner==$extension) {
    $checked='';
    if($private=='yes') { $checked=' checked '; }

?>
  <div class="checkbox">
    <label>
      <input type="checkbox" name="private[]" id="private" <?php echo $checked;?>> <?php echo trans('Private');?>
    </label>
  </div>
<?php
}
?>
<?php
if($id<>'') {
?>
  <a id='buttondelete' data-recordid='<?php echo $id;?>' class="btn btn-danger btn-sm"><?php echo trans('Delete');?></a>
<?php
}
?>
  <a href="contacts.php" class="btn btn-warning btn-sm"><?php echo trans('Cancel');?></a>
  <button type="submit" class="btn btn-primary btn-sm"><?php echo trans('Save');?></button>
</form>
</div>
<?php
}  // end function edit_form
?>
<!DOCTYPE html>
<html>
<head>
    <meta content="text/html; charset=utf-8" http-equiv="content-type">
    <meta content="yes" name="apple-mobile-web-app-capable">
    <meta content="YES" name="apple-touch-fullscreen">
    <meta content="width=device-width, minimum-scale = 0.1, maximum-scale = 1.0, user-scalable=yes" name="viewport">

    <title>Contacts</title>

    <link href="css/bootstrap.min.css" media="screen" rel="stylesheet" type="text/css">
    <link href="css/jquery-ui.css" media="screen" rel="stylesheet" type="text/css">
    <link href="css/alertify.core.css" media="screen" rel="stylesheet" type="text/css">
    <link href="css/alertify.bootstrap3.css" media="screen" rel="stylesheet" type="text/css">
    <link href="css/contacts.css" media="screen" rel="stylesheet" type="text/css">
    <link href="css/animate.css" media="screen" rel="stylesheet" type="text/css">
    <link href="css/font-awesome.min.css" media="screen" rel="stylesheet" type="text/css">
    <script src="js/lodash.min.js" type="text/javascript"></script>
    <script src="js/jquery-1.11.3.min.js" type="text/javascript"></script>
    <script src="js/jquery-ui.min.js" type="text/javascript"></script>
    <script src="js/jquery.ui.touch-punch.min.js" type="text/javascript"></script>
    <script src="js/bootstrap.min.js" type="text/javascript"></script>
    <script src="js/jquery.cropit.js" type="text/javascript"></script>
    <script src="js/bootstrap-dropdown-on-hover.js" type="text/javascript"></script>
    <script src="js/alertify.min.js" type="text/javascript"></script>
    <script src="js/jquery.jscroll.min.js" type="text/javascript"></script>
    <script src="js/jquery.livesearch.js" type="text/javascript"></script>
    <script src="js/contacts.js" type="text/javascript"></script>
<?php
    if($allowed=='no' or $extension=="-1") {
        echo "<meta http-equiv=\"refresh\" content=\"5\" >\n";
    }
?>
</head>
<body>

<div class='container' style='border-left:3px solid #ddd; padding-left:0px; padding-top:25px; width: 250px;'>

<?php
if($notallowed<>'') {

    echo $notallowed;
    echo "</div>";
    echo "</body></html>";
    die();
}

if($requestaction=='edit') {

    $res = $db->consulta("select * from visual_phonebook where id='%s'",$_REQUEST['id']);
    $row = $db->fetch_assoc($res);

    edit_form($row);

} else if ($requestaction=='export') {
    $mensaje=array();
    $query = "SELECT id,firstname,lastname,company,address,email,phone1,phone2,picture FROM visual_phonebook WHERE context='%s' AND (owner='%s' OR (owner<>'%s' AND private='no')) ORDER BY CONCAT(firstname,' ',lastname)";
    $res = $db->consulta($query,array($context,$extension,$extension));
    if($db->num_rows($res)==0) {
        $mensaje[] = array('kind'=>'warning','message'=>trans('There are no records to export'));
    }
    if(count($mensaje)>0) {
        print_messages($mensaje);
        exit;
    }
    @ob_end_clean();
    $delimiter = ",";
    $filename = "visual_phonebook.csv";
    header('Content-Type: text/csv');
    header("Content-Disposition: attachment; filename=$filename");
    $cont=1;
    while ($row = $db->fetch_assoc($res)) {
        if($cont==1) {
            $columnas = Array();
            foreach($row as $columna=>$valor) {
                $columnas[] = $columna;
            }
            $header = implode($delimiter,$columnas);
            echo "$header\n";
        }
        $milinea = Array();
        foreach($row as $columna=>$valor) {
            $milinea[] = $valor;
        }
        $linea = implode($delimiter,$milinea);
        echo "$linea\n";
        $cont++;
    }
 
    exit;
} else if ($requestaction=='import') {

    $arrFile = $_FILES['csvupload'];
    $file    = $arrFile['tmp_name'];

    if ($arrFile['size']>0 && !empty($file)) {
        if (is_uploaded_file($file)) {
        if (copy ($file, $userdirectory."contactsimportCSV.csv")) {
            $name_upload="contactsimportCSV.csv";
        }else{
            $error[]=array('kind'=>'warning','mesage'=>trans('Could not copy uploaded file'));
        }
        }else{
            $error[]=array('kind'=>'warning','message'=>trans('Could not upload file'));
        }
    }else{
        $error[]=array('kind'=>'warning','message'=>trans('Could not upload file'));
    }

    if($name_upload == "") {
        $error[]=array('kind'=>'warning','message'=>trans('Empty file?'));
    } 
    if(count($error)>0) { print_messages($error); } else {
        // procesa csv
        $mensaje = process_csv($userdirectory."contactsimportCSV.csv");
        print_messages($mensaje);
    }

    print_contacts();
   
} else if ($requestaction=='delete') {

    $id = $_REQUEST['id'];
    $result = $db->select("picture","visual_phonebook","","id=$id");
    $imagen = $result[0]['picture'];
    if(is_file("${userdirectory}${imagen}")) {
        unlink("${userdirectory}${imagen}");
    }
    $db->consulta("DELETE FROM visual_phonebook WHERE id=%s",$id);
    print_contacts();

} else if ($requestaction=='new') {
    // Mostrar formulario para insertar
    edit_form(array());

} else if ($requestaction=='save' || $requestaction=='insert') {

    $firstname = $_REQUEST['firstname'];
    $lastname  = $_REQUEST['lastname'];
    $company   = $_REQUEST['company'];
    $phone1    = $_REQUEST['phone1'];
    $phone2    = $_REQUEST['phone2'];
    $picture   = $_REQUEST['picture'];
    $address   = $_REQUEST['address'];
    $email     = $_REQUEST['email'];
    $id        = $_REQUEST['id'];
    $private   = $_REQUEST['private'][0];
    $privvalue = ($private=='on')?'yes':'no';

    if($requestaction=='save') {
        $db->consulta('UPDATE visual_phonebook SET firstname="%s",lastname="%s",company="%s",phone1="%s",phone2="%s",address="%s",email="%s",private="%s" WHERE id=%s',array($firstname,$lastname,$company,$phone1,$phone2,$address,$email,$privvalue,$id));
    } else {
        $res = $db->consulta('INSERT INTO visual_phonebook (firstname,lastname,company,phone1,phone2,address,email,owner,private,context) VALUES ("%s","%s","%s","%s","%s","%s","%s","%s","%s","%s")',array($firstname,$lastname,$company,$phone1,$phone2,$address,$email,$extension,$privvalue,$context));
        $id = $db->insert_id($res);
        $res = $db->consulta('UPDATE visual_phonebook SET picture="%s" WHERE id=%s',array($id."-picture.png",$id));
    }

    // save record/image
    if($_REQUEST['image-data']<>'') {

        list($nada,$image_data) = preg_split("/,/",$_REQUEST['image-data']);
        $decoded_image = base64_decode($image_data);
        $fp=fopen($userdirectory.$id."-picture.png","w");
        fputs($fp,$decoded_image);
        fclose($fp);

        if($requestaction=='save') {
            // update picture field only if image is set, otherwise keep the one on dB for backwards compatibility
            $db->consulta('UPDATE visual_phonebook SET picture="%s" WHERE id=%s', array("$id-picture.png",$id));
        }


    } else {
        $picture = '';
    }

    print_contacts();


} else {
    // Si no hay accion, mostramos lista
    print_contacts();

}

function print_messages($errors) {
    foreach($errors as $error) {
    echo "<div class='alert alert-".$error['kind']." alert-dismissible' role='alert'>
  <button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button>
  <strong>".$error['message']."</strong></div>";
    }
}

function print_contacts() {
    global $db, $extension, $admin, $userdirectory, $context;


    if(isset($_GET['search'])) {
       $search = $_GET['search'];
       $search = preg_replace("/\"/","",$search);
       $search = preg_replace("/;/","",$search);
       if($search<>"") {
           $condition = " (CONCAT(firstname,' ',lastname) LIKE \"%$search%\" OR company LIKE \"%$search%\" OR phone1 LIKE \"%$search%\" OR phone2 LIKE \"%$search%\" OR email LIKE \"%$search%\")";
       } else {
           $condition="(1=1)";
       }

    } else {
        $condition="(1=1)";
        $search="";
    }


    $res = $db->consulta("SELECT count(*) AS count FROM visual_phonebook WHERE context='$context' AND (owner='$extension' OR (owner<>'$extension' AND private='no')) AND $condition");
    $row = $db->fetch_assoc($res);
    $rec_count = $row['count'];

    if(isset($_GET['initial'])) {
        $previousinitial= base64_decode($_GET['initial']);
    } else {
        $previousinitial='1';
    }
 
    $rec_limit = 10;
    if( isset($_GET{'page'} ) ) {
        $page = $_GET{'page'} + 1;
        $offset = $rec_limit * $page ;
    } else {
        $page = 0;
        $offset = 0;
    }
    $left_rec = $rec_count - (($page-1) * $rec_limit);
    $tot_page = ceil($rec_count / $rec_limit);

    echo "
    <div class='row'>
        <div class='col-xs-12 col-sm-12'>
            <div class='panel panel-default'>

                <div class='panel-heading c-list'>
                    <span class='title' style='padding:5px; font-size:1.5em;' id='contactstitle'>Contacts</span>
                    <ul class='pull-right c-controls'>
                        <li>
                           <form id='addnew'><input type=hidden name='action' value='new'> </form>
                           <a id='addnewbutton' style='cursor:pointer;' data-toggle='tooltip' data-placement='bottom' title='".trans('Add Record')."'><i class='fa fa-plus' style='font-size:1.5em;'></i></a>
                        </li>
                        <li class='dropdown' style='margin-right:10px;'>
                        <a href='#' class='dropdown-toggle' data-toggle='dropdown' role='button' aria-haspopup='true' aria-expanded='false'>
                        <i class='fa fa-bars' style='font-size:1.5em;'></i>
                        </a>
                        <ul class='dropdown-menu dropdown-menu-right animated flipInX'>
                            <li role='presentation'><a class='pointer' role='menuitem' id='buttonimport'><span class='fa fa-upload'></span> <span class='importtitle'>".trans('Import')."</span></a></li>
                            <li role='presentation'><a class='pointer' role='menuitem' id='buttonexport'><span class='fa fa-download'></span> <span class='exporttitle'>".trans('Export')."</span></a></li>
                            <li role='presentation'><a class='pointer' role='menuitem' id='buttonclose'><span class='fa fa-arrow-right'></span> <span class='closetitle'>Close</span></a></li>
                        </ul>
                        </li>
                    </ul>
                </div>
                
                <div class='row'>
                    <div class='col-xs-12'>
                        <div class='input-group c-search'>
                            <input type='text' class='form-control' id='contact-list-search'>
                            <span class='input-group-btn'>
                                <button class='btn btn-default' type='button'><span class='fa fa-search text-muted'></span></button>
                            </span>
                        </div>
                    </div>
                </div>
            </div>

    ";

   echo "<div id='records'>";
   echo "<ul class='list-group' id='contact-list' style='margin:0;'> ";

    $query = "SELECT id,picture,concat(firstname,' ',lastname) AS name,company,phone1,phone2,email,address,owner FROM visual_phonebook WHERE context='$context' AND (owner='$extension' OR (owner<>'$extension' AND private='no')) AND $condition ORDER BY CONCAT(firstname,' ',lastname) ";
    $query .= " limit $offset,$rec_limit"; 
    $res = $db->consulta($query);

    while($row = $db->fetch_assoc($res)) {
        
        if(is_callable('mb_substr')) {
            $initial = mb_substr($row['name'],0,1,'UTF-8');
        } else {
            $initial = substr($row['name'],0,1);
        }
        if(strtolower($initial) <> strtolower($previousinitial)) {
            echo "<li class='list-group-item chat'><h2 class='initial'>".strtoupper($initial)."</h2></li>";
        }

        // echo ro-itemw

        echo "<li class='list-group-item chat' style='padding:5px 1px 5px 1px;' id='contact".$row['id']."'><div class='col-xs-4 col-sm-3 nopad'>\n";

        $previousinitial = $initial;
        if(is_file($userdirectory.$row['picture'])) {
            echo "<img src='$userdirectory".$row['picture']."' class='lazy img-responsive img-circle avatar'>";
        } else {
            echo "<div class='avatar icon-user-default'>&nbsp;</div>";
        }

        echo "      </div>
                        <div class='col-xs-8 col-sm-9 nopad' style='padding-left:10px;'>
                            <span class='name nopadding searchit'>".$row['name']."</span><br/>
                            <span class='company searchit'>".$row['company']."</span><br/>
                        </div>
                        <div class='col-xs-12 col-sm-12 text-right'>";
        if($row['address']<>'') {
            echo "<span class='fa fa-map-marker text-muted c-info' data-toggle='tooltip' title='".$row['address']."'></span>";
        }
        if($row['phone1']<>'') {
            $numberstrip = preg_replace("/[^0-9]/","",$row['phone1']);
            echo "<a href='#' onclick='parent.dial(\"$numberstrip\")'><span class='fa fa-phone text-muted c-info' data-toggle='tooltip' title='".$row['phone1']."'></span></a>";
        }
        if($row['phone2']<>'') {
            $numberstrip = preg_replace("/[^0-9]/","",$row['phone2']);
            echo "<a href='#' onclick='parent.dial(\"$numberstrip\")'><span class='fa fa-phone text-muted c-info' data-toggle='tooltip' title='".$row['phone2']."'></span></a>";
        }
        if($row['email']<>'') {
            echo "<a href='mailto:".$row['email']."'><span class='fa fa-envelope-o text-muted c-info' data-toggle='tooltip' title='".$row['email']."'></span></a>";
        }
        echo "
                        </div>
                        <div class='editlink'><a href='?action=edit&id=".$row['id']."' class='label label-default'>".trans('Edit Record')."</a></div>
                        <div class='clearfix'></div>
                    </li> ";
    }

    if($page<>$tot_page) {
        echo "<li class='chat' style='display:none;'><a class='first' href=\"contacts.php?initial=".base64_encode($initial)."&page=$page&search=$search\">Next $rec_limit Records</a></li>"; 
    } 
    echo "</ul>";
    echo "</div></div></div>";
 

}
?>

        <div id='uploadcontainer' class="modal fade" role="dialog">
            <div class="modal-dialog modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                        <div class='content'><span class='fa fa-list-alt pull-left' style='padding: 7px 5px; font-size:1.5em;'></span><h3 class='modal-title uploadtitle'>Upload File</h3></div>
                    </div>
                    <div class="modal-body">
                    <form method='post' enctype='multipart/form-data' id='formimport' name='formimport'><div id='uploadbutton' class='btn btn-default'><input type="file" id="csvupload" name="csvupload">Browse</div> <span id='csvfilename'></span><input type='hidden' name='action' value='import'><input type='submit' class='btn btn-primary'></input></form>
                    </div>
                </div>
            </div>
        </div>

<form class='hidden' id='formdelete'><input type=hidden name='action' value='delete'><input type=hidden name='id' id='formdeleteid' value=''></form>
<form class='hidden' id='formexport'><input type=hidden name='action' value='export'></form>

<span class='hidden' id='areyousure'>Are you sure?</span>
<span class='hidden' id='yesstring'>Yes</span>
<span class='hidden' id='nostring'>No</span>
</body>
</html>
