# The perl part of a plugin will execute commands on the server side.
# As such, this commands will apply to any user, regardless if the plugin
# is assigned to any user (plugin assignment only affects the client side
# part, or .js files)

# AMI_Event_Handler lets you intercept AMI events and add your own actions/code
# The first parameter is a hash with the key=>value paris as received
#
# The function should return an array with valid AMI cmmands/actions to send
# If you want to see the possible AMI events, you can start fop2_server in debug
# level 1.
#
$AMI_Event_Handler{'sampleplugin'}{'HANGUP'} = sub {
    my $event = shift;
    my @allreturn;

    # Retrieve config data as set in the plugin ini file
    my $var1 = $main::pluginconfig{'sampleplugin'}{'sampleConfig'}{''};
    my $var2 = $main::pluginconfig{'sampleplugin'}{'sampleConfig'}{'samplesection'};

    # This will print out the complete manager event as received
    my @keys =  keys %$event;
    foreach my $key (@keys) {
        print "$key = ".${$event}{$key}."\n";
    }
    print "\n";

    # We can send AMI commands as strings as a reaction to the received AMI event
    $return  = "Action: DBPut\r\n";
    $return .= "Family: SOMETHING\r\n";
    $return .= "Key: TO\r\n";
    $return .= "Val: WRITE\r\n";
    $return .= "\r\n";
    push @allreturn, $return;

    # We return an array containing valid manager Actions
    return @allreturn;
};

# To catch responses from a command sent as a Hash with a special
# formatted ActionID
#
$AMI_Response_Handler{'sampleplugin'}{'myactionresponse'} = sub {

     my $response = shift;
     my $extra    = shift;

     my @allreturn;

     my ($field0, $field1, $field2)   = split/!/, $extra;

     if($response->{Response} eq "Success") {
        # A UserEvent with family and value will be sent to flash clients so we can intercept it in callback_{family} in the plugin js code
        my $valor = { 'Event' => 'UserEvent', 'UserEvent' => 'SomeOtherActionBasedOnResponse', 'Channel' => $field1, 'Family' => "something", 'Value' => $field2 };
        push @allreturn, $valor;

     }

     return @allreturn;
};

# Client_Pre_Command_Handler is called when an action is received from
# a FOP2 Client (from the browser), like changing the presence, initiating
# a transfer, etc. You also can return an AMI command to be sent. 
# The Pre handler will issue your commands BEFORE the standard FOP2
# response. The Post handler will issue the commands AFTER the standard
# FOP2 response.
#
# The first key is the name of the plugin, the second the action received
# from a FOP2 client. You can catch here custom actions defined in the .js
# part of a plugin too.
#
# A good way to see the commands that can be recieved from the client is
# to start fop2_server in debug level 4: /usr/local/fop2/fop2_server -X 4
#
$Client_Pre_Command_Handler{'sampleplugin'}{'ping'} = sub {
    print "pong pong!\n";
    my $pluginconf   = defined($main::pluginconfig{'sampleplugin'}{'sampleconfig'}{'section'})?$main::pluginconfig{'sampleplugin'}{'sampleconfig'}{'section'}:$main::pluginconfig{'sampleplugin'}{'sampleconfig'}{''};
    my @allreturn;

    my $mychannel      = main::get_btn_config( "$contexto", $origen, 'MAINCHANNEL');

    $return  = "Action: DBDel\r\n";
    $return .= "Family: SOMETHING\r\n";
    $return .= "Key: TO\r\n";
    $return .= "\r\n";
    push @allreturn, $return;

    # If we need to get the actual response to our command,
    # then we return a hash instead of a string with a special formaatted ActionID
    # using ! as separator, where the 1st field will be later catched
    # in AMI_Reponse_Handler
    $return = {
        Action    => 'DBPut',
        Family    => 'SOMETHING',
        Key       => 'TO',
        Val       => 'WRITE',
        ActionID  => "myactionresponse!$mychannel!someotherdata"
    };
    push @allreturn, $return;


    push @allreturn, $return;
    return @allreturn;
};

# sampleaction is a custom action sent from the js part of the plugin

$Client_Post_Command_Handler{'sampleplugin'}{'sampleaction'} = sub {
    my @allreturn;
    $return  = "Action: DBDel\r\n";
    $return .= "Family: SOMETHING\r\n";
    $return .= "Key: TO\r\n";
    $return .= "\r\n";
    push @allreturn, $return;
    return @allreturn;
};

