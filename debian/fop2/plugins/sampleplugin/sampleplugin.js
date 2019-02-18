plugins['sampleplugin'] = (function() {

    // Private variables for the plugin

    // This object can be used as a menu item to be added on the context submenu
    // look at the setExtensionMenu method down bellow. The icon can be set/styled
    // in the plugin .css file. The name  will be used as a method to be called
    // when the menu action is selected.

    var menuOption = {
        "sampleAction": { name: 'Sample Sub Menu Action', icon: 'sampleicon' },
    }

    // Retrieving config data from plugin .ini file 
    var sample1 = parseInt(pluginconfig['sampleplugin']['sampleConfig'][''])
    var sample2 = parseInt(pluginconfig['sampleplugin']['sampleConfig']['samplesection'])

    return { 

        loadLang: function(values) {
            // This method is called to load language files into the application when the plugin is loaded
            // The language files are located in the lang subdirectory of the plugin folder
            //
            // queuecommand is a string that can be used to send a command from the client to the server
            // the xml format can be seen below, it requires to be autehnticated by hashing a key as shown
            // you must pass fields separated by pipes in the format <msg data='position|command|data|hash' />
            //
            // Finally the sendcommand function will send the queuedcommand to the server for processing
            var hash = hex_md5(secret+lastkey);
            queuedcommand = "<msg data=\"" + myposition + "|pluginlang|" + language + "~sampleplugin" + "|" + hash + "\" />";
            sendcommand();
        },

        setLang: function() {
            // This method is used to apply a language strings to html elements
            $('#sampleplugin_element').attr('title',lang.samplepluginstring);
        },

        setExtensionMenu: function(items) {
            // This one is called when the context submenu is opened, it is possible then to 
            // add menu items by extending the default object/arry, in this sample we are adding
            // the private menuOption defined on the top of this file.
            jQuery.extend(items,menuOption);
            return items;
        },
        sampleAction: function(target,source) {
            // this method is called when the custom submenu item is selected. Those menu entries
            // send the target and source extension as the button position in the panel.
            // botonitos is an object that has button properties as defined in buttons.cfg, like
            // extension, channel, label, etc. 
            var number_to_dial = botonitos[target]['EXTENSION'];
            queuedcommand = "<msg data=\"" + myposition + "|dial|" + number_to_dial + "|" + hash + "\" />";
            sendcommand();

        },
        callback_getvar: function(nro,texto,slot) {
             // callback_ methods will intercept events received from the server so you can act upon them
             // These are some of the events that you can receive:
             //
             // voicemailcount,lock,unlock,astdbcust,devtype,fromqueue,queuemembers,settext,usersonline,
             // xstatus,presence,ip,state,link,direction,settimer,rename,notionline,notioffline,details,
             // queueentry,waitingcalls,clearentries,getvar,etc
             //
             // a good way to see the events that are received on the client side is to run fop2_server 
             // with debug level 4: /usr/local/fop2/fop2_server -X 8
             //
             // nro is the button index position
             // texto is the main content
             // slot is the (optional) line number
        },
        init: function() {
            // This method is called on the fop2 initilization, and is used to initialize the plugin itself
            // like for adding page elements, or menu items.
            // embed elements in page, load style files

            if($('#action_sampleAction').length == 0) {
                // add button in action toolbar
                var actionbar = $('#custombar');
                but = document.createElement('div');
                $(but).attr({id: 'action_sampleAction', title: 'Sample'}).addClass('actionbutton myclick');
                img = document.createElement('img');
                $(img).attr('src','./images/toolbar/conference.png');
                $(but).append(img);
                actionbar.append(but);
            }

        }
    }
}());
