/**
 * Created by user2 on 3/12/16.
 */

var loadScript = function loadScript() {

    jQuery.getScript("/path/to/myscript.js")
        .done(function () {
            /* yay, all good, do something */
        })
        .fail(function () {
            /* boo, fall back to something else */
        });
}

//loadScript();

var scripts2 = [
    'shelpers-mini.js', 'PromiseHelperV3.js',
    'testFramework.js',
    'tests.js',

]
var loadScript2 = function loadScript2(_scripts2) {
    if ( scripts2.length == 0 ) {
        console.log('finished');
        return;
    }
    var url = _scripts2.shift();
    if ( window.preamble == null ) {
        window.preamble = 'test2/'
    }
    url = window.preamble + url;
    jQuery.getScript(url)
        .done(function () {
        })
        .always(function doneLoadingFile () {
            loadScript2(_scripts2);
        })
        .fail(function (a,b,c,d) {
            console.error('failed to load', url, a==null,b,c,d)
            console.error(c.stack)
        });
}


if ( window.location.href.indexOf('runTest=true') !=-1 )
    loadScript2(scripts2);

var cookie =  Cookies.getJSON('nextTest')
if ( cookie ) {
    loadScript2(scripts2);
}
