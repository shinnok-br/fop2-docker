$Client_Post_Command_Handler{'conferencebutton'}{'customconference'} = sub { 
    my @allreturn = ();
    my $origen   = shift;
    my $destino  = shift;
    my $contexto = shift;
    my $socket   = shift;
    my $mychannel = main::get_btn_config( "$contexto", $origen, 'MAINCHANNEL');


    my ($extension_to_dial,$origincontext) = split(/\^/,$destino);

    if ( !main::hasPermChannel( $socket, "dial", $mychannel ) && !main::hasPerm( $socket, "all" ) ) {
        # No 'dial' permission, abort action
        print "No permissions for conference\n";
        return @allreturn;
    }

    my @orivariables;
    my $originate_variable = main::get_btn_config( "$contexto", $origen, 'ORIGINATEVARIABLES');
    my $exten              = main::get_btn_config( "$contexto", $origen, 'EXTENSION');
    my $name               = main::get_btn_config( "$contexto", $origen, 'LABEL');
    my $autoanswer         = 0;
    my $autoanswer_header  = '';
    my $callerid           = '';

    if($exten ne $extension_to_dial) {
        # only auto answer on barge

        my $chani          = main::get_btn_channel( "$contexto", $extension_to_dial);
        my $newpos         = main::get_btn_position( "$contexto", $chani);
        $autoanswer        = main::get_btn_config( "$contexto", $newpos, 'AUTOANSWER');
        $autoanswer_header = main::get_btn_config( "$contexto", $newpos, 'AUTOANSWERHEADER');
        $name               = main::get_btn_config( "$contexto", $newpos, 'LABEL');
    }

    $callerid = "CallerID: $name <$exten>";

    if($autoanswer_header !~ m/^__/) {
        $autoanswer_header = "__".$autoanswer_header;
    }

    if ( $autoanswer_header ne "" && $autoanswer == 1) {
        push @orivariables, $autoanswer_header;
    }
    if ( $originate_variable ne "" ) {
        push @orivariables, $originate_variable;
    }

    my $orivariable = join( ',', @orivariables );

    my $return  = "Action: Originate\r\n";
    $return .= "Channel: Local/$extension_to_dial\@$origincontext\r\n";
    $return .= "Application: ChanSpy\r\n";
    $return .= "Data: $mychannel,BEq\r\n";
    if($callerid ne "" ) {
        $return .= "$callerid\r\n";
    }
    if($orivariable ne "" ) {
        $return .= "Variable: $orivariable\r\n";
    }
    $return .= "\r\n";
    push @allreturn, $return;
    return @allreturn;
};

