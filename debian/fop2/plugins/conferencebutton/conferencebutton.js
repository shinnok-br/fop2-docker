plugins['conferencebutton'] = (function() {
    // var private = []; 

    return { 

        loadLang: function(values) {
            var hash = hex_md5(secret+lastkey);
            queuedcommand = "<msg data=\"" + myposition + "|pluginlang|" + language + "~conferencebutton" + "|" + hash + "\" />";
            sendcommand();
        },

        setLang: function() {
            // change language strings
            if ($('#box_asternicTagbox').length > 0) {
                // fop2 pre 2.30
                $('#action_conferencecall').attr('title',lang.conference);
            } else {
                $('#action_conferencecall').attr('data-original-title',lang.conference);
            }
            setTips($('#action_conferencecall'));
        },

        embed: function() {
            // embed elements in page, load style files
            if($('#action_conferencecall').length == 0) {
                var actionbar = $('#custombar');
                but = document.createElement('div');
                $(but).attr({id: 'action_conferencecall', title: 'Conference', 'data-toggle': 'tooltip', 'data-placement': 'bottom'}).addClass('actionbutton myclick');
                img = document.createElement('span');
                $(img).addClass('fop2-conference').addClass('tbutton');
                $(but).append(img);
                actionbar.append(but);
            }
        },

        action_conferencecall: function(target) {
            debug('do conference with '+target);

            if (myposition > 0) {
                var boton = $('#boton' + myposition);
                var number_to_dial;
                // Look for typed number in the dial textbox field
                if ($('#dialtext')[0].value.indexOf(lang.dial) >= 0) {
                    // Placeholder text, we have to remove it
                    var largo = lang.dial.length;
                    number_to_dial = $('#dialtext')[0].value.substr(largo);
                } else {
                    number_to_dial = $('#dialtext')[0].value;
                }
                // If the dialbox is empty, check if we have a target selected
                // and use the target extension number
                if (number_to_dial == "") {
                    if (target > 0) {
                        number_to_dial = botonitos[target]['EXTENSION'];
                    }
                }
                if (number_to_dial == "") {
                    debug("We do not have a target number to dial, exit");
                    return;
                }

                debug(number_to_dial);

                var mycontext = botonitos[myposition]['CONTEXT'];

                if (boton.hasClass('busy')) {
                    var hash = hex_md5(secret+lastkey);
                    queuedcommand = "<msg data=\"" + myposition + "|customconference|" + number_to_dial + "^" + mycontext+ "|" + hash + "\" />";
                    sendcommand();
                } else {
                    // We are not on a call, lets try to barge in
                    boton = $('#boton' + target);
                    if (boton.hasClass('busy')) {
                        number_to_dial = botonitos[myposition]['EXTENSION'];
                        queuedcommand = "<msg data=\"" + target + "|customconference|" + number_to_dial + "^" + mycontext + "|" + hash + "\" />";
                        sendcommand();
                    } else {
                        debug("Nor source or target extensions are busy, conference can be done if someone is on a call only");
                    }
                }
            }
 
        },

        init: function() {
            // initialization function
            this.embed();
            this.loadLang();
        }
    }
}());
