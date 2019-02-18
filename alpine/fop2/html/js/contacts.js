$(function () {

    $('#csvupload').change(function(e){
        $in=$(this);
        var valor = $in.val();
        rest = valor.replace("C:\\fakepath\\","");
        $('#csvfilename').html(rest);
    });

    $('.image-editor').cropit({'rejectSmallImage':false});

    $('.select-image-btn').click(function() {
        $('.cropit-image-input').click();
    });

    $('form').submit(function() {
        var imageData = $('.image-editor').cropit('export');
        $('.hidden-image-data').val(imageData);
    });

    $('[data-toggle="tooltip"]').tooltip();
   
    $('#addnewbutton').on('click', function(event) {
        event.preventDefault();
        $('#addnew').submit();
    });

    $('#buttondelete').on('click', function(event) {
        event.preventDefault();
        areyousurestring = $('#areyousure').html();
        yesstring = $('#yesstring').html();
        nostring  = $('#nostring').html();
        deleteid  = $(this).attr('data-recordid');
        alertify.set({
             labels: {
                 ok: yesstring,
                 cancel: nostring
             }
        });
        alertify.confirm(areyousurestring, function(e) {
            if (e) {
                $('#formdeleteid').val(deleteid);
                $('#formdelete').submit();
            }
        });


    });

    $('#buttonclose').on('click', function(event) {
        event.preventDefault();
        parent.hideContacts();
    });

    $('#buttonimport').on('click', function(event) {
        event.preventDefault();
        $('#uploadcontainer').modal();
    });

    $('#buttonexport').on('click', function(event) {
        event.preventDefault();
        $('#formexport').submit();
    });



    $(document).on('keyup', function(e) {
        var tag = e.target.tagName.toLowerCase();
        var tagid = e.target.id;

        if ( e.which === 27) {
            if(tag=='input' && tagid=='contact-list-search') {
                $('#contact-list-search').val('');
                $('#contact-list-search').focus();
            } else if(tag=='body') {
                parent.hideContacts();
            }
            console.log(tag);
        }
    });
 
    $('.glyphicon-earphone').on('click', function(el) {
        var number = $(this).attr('data-original-title');
        parent.dial(number);
    });


    $("#contact-list-search").livesearch({
        searchCallback: searchFunction
    });


    $('#records').jscroll({
        nextSelector : "a.first",    
        contentSelector : "li.chat",
        debug: true,
        callback: function() { $('[data-toggle="tooltip"]').tooltip(); },
        loadingHtml: '<i class="fa fa-spinner fa-spin"></i>'
    });

     function searchFunction(searchTerm) {
          var url=window.location.href;
          var lastChar = url.substr(url.length - 1);          
          if(lastChar=='#') {
              url=url.substr(0,-1);
          }
          myurl = insertParam(url,'search',searchTerm);
          myurl = myurl.replace(/&?action=([^&]$|[^&]*)/i, "");
          myurl = myurl.replace(/&?id=([^&]$|[^&]*)/i, "");
          var pane = $('#records');
          pane.load(myurl+' #contact-list', function() { 
            $('#records').removeData('jscroll');
            $('#records').jscroll({
                nextSelector : "a.first",
                contentSelector : "li.chat",
                debug: true,
                callback: function() { $('[data-toggle="tooltip"]').tooltip(); },
                loadingHtml: '<i class="fa fa-spinner fa-spin"></i>'
            });
          });
    }

    function insertParam(mystring, key, value) {
        console.log("insert param "+mystring);
        if(mystring === false) { return; }
        if(typeof mystring == 'undefined') { return; }
        key = encodeURI(key); value = encodeURI(value);

        if(mystring.indexOf('?')>0) {
           part = mystring.split('?');
           kvp = part[1].split('&');
        } else {
           kvp = [];
           part = [ mystring, '' ];
        }

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

        var pepe = part[0] + '?' + kvp.join('&');
        return pepe; 
    }

    parent.setLangContacts();
});

