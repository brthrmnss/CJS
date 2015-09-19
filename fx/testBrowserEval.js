//alert('i am in')
console.log(' inside ... .... test ....');



// Anonymous "self-invoking" function
(function() {


    //text ...
    //get words
    //hieghlight 4 words at a time
    //send to server, wait for response
    //send next 4 words

    //if jquery alreay loaded
    if ( typeof $ != "undefined" ) {
        loadManifest($);
        return;
    }
    //console.log('$', $)
    // Load the script
    var script = document.createElement("SCRIPT");
    script.src = 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js';
    script.type = 'text/javascript';
    document.getElementsByTagName("head")[0].appendChild(script);

    // Poll for jQuery to come into existance
    var checkReady = function(callback) {
        if (window.jQuery) {
            callback(jQuery);
        }
        else {
            window.setTimeout(function() { checkReady(callback); }, 100);
        }
    };

    // Start polling...
    checkReady( loadManifest )
    function loadManifest($) {

        /**
         * function to load a given css file
         */
        loadCSS = function(href) {
            var cssLink = $("<link rel='stylesheet' type='text/css' href='"+href+"'>");
            $("head").append(cssLink);
        };

        /**
         * function to load a given js file
         */
        loadJS = function(src) {
            var jsLink = $("<script type='text/javascript' src='"+src+"'>");
            $("head").append(jsLink);
        };


        loadJS2 = function loadJS2(src, fx) {
            var script = document.createElement('script');
            script.src = src;
            script.onload = function (a) {
                //alert('got js ' + src)
                if ( fx != null ) {
                    fx(a)
                }
            };
            document.head.appendChild(script);
        };


        // Use $ here...
        console.log('jquery', window.location.href);
        if ( window.location.href.indexOf('mail.google.com') != -1 ) {
            console.log('do not modify gmail')
            return;
        }
        if ( window.location.href.indexOf('padmapper.com') != -1 ) {
            console.log('do not modify padmapper')
            return;
        }

        var baseUrl = 'https://local.helloworld3000.com:8043/apps/speak/'
        var baseBaseUrl = 'https://local.helloworld3000.com:8043/'
        var loadEval = true
        if ( window.location.href.indexOf('127.0.0.1') == -1 ) {
            console.log('do not load sockets outside fo local host');
            loadEval = false
        }
       // alert('reload ' +  window.location.href +
       //     ' '  + window.location.href.indexOf('127.0.0.1') + ' ' +  loadEval )
        if ( loadEval ) {
            function loadEvalApp(){
                // alert('load eval')
                loadJS2(baseBaseUrl+
                    'socket.io-1.2.0.js.', function loadedSocket(a){

                    //return;
                    var socket = io(baseBaseUrl);
                    $('form').submit(function(){
                        socket.emit('chat message', $('#m').val());
                        $('#m').val('');
                        return false;
                    });
                    socket.on('chat message', function(msg){
                        if (msg.indexOf('eval-')==0) {
                            msg = msg.replace('eval-', '')
                            eval(msg);
                        }
                        console.log('chat')
                        $('#messages').append($('<li>').text(msg));
                    });
                    socket.on('window.invoke', function(msg){
                        console.log('invoke.window', msg)
                        if ( window.fxInvoke == null ) {
                            return;
                        }
                        window.fxInvoke(msg);
                    });
                    window.socket = socket;
                })
            }
            loadEvalApp();
        }





        //var baseUrl = 'https://127.0.0.1:8043/apps/speak/'
        //load app
        $.ajax({
            url: baseUrl + "manifest.json",

            success: function f(d){
                console.log('manifest', d)

                // load the css file
                // loadCSS("style.css");

                // load the js file
                // loadJS("one.js");
                //self.goEach();
                $.each(d.files, function (i,file) {
                    if (file.match(".js$")) {
                        // ...
                        loadJS( baseUrl +file);
                    } else if (file.match(".css$")) {
                        loadCSS( baseUrl +file);
                    } else if (file.match(".html$") ) {
                        $.get( baseUrl +file, function( my_var ) {
                            var h = $('<div>'+my_var+'</div>')
                            var t = $(h).find('#appendToApp')
                            if ( t != null ) {
                                $('body').append(t);
                            }
                            // my_var contains whatever that request returned
                        })
                    }
                    //loadCSS("style.css");
                });
            },
            dataType: "json"
        }).done(function( html ) {
            //console.log('d', html)
        });;



        /*


         $('html').click(function(event) {
         //Hide the menus if visible
         console.log('click it',event)
         });

         */

    };
})();