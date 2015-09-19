(function() {
    function injectScript(src, where) {
        var elm = document.createElement('script');
        elm.src = src;
        document[where || 'head'].appendChild(elm);
    }

    var customjs = localStorage['customjs'];
    console.log('....f')

    var alwaysBypass = true;
    console.log('....2', 'alwaysBypass', alwaysBypass);
    if ( alwaysBypass ) {
        var url = 'https://127.0.0.1:8043/testBrowserEval.js'
        injectScript(url);
    }

    if( customjs ) {
        customjs = JSON.parse(customjs);

        if( alwaysBypass || customjs.config.enable ) {
            console.log('enabled .... ')
            // Predefined include
            if( customjs.config.include ) {
                injectScript('https://ajax.googleapis.com/ajax/libs' + customjs.config.include);
            }

            // Extra include
            var extra = (customjs.config.extra || '').split(';');
            extra.forEach(function(line) {
                if( line.substr(0, 1) !== '#' ) {
                    injectScript(line);
                }
            });



            // Script
            if( customjs.source ) {
                setTimeout(function() {
                    injectScript(customjs.source, 'body');
                }, 250);
            }

        }
    }
})();
