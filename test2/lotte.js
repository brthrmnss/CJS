//alert('lotte')



//http://10.211.55.4:33310/api/search:c?166af0ef8327c82375d4ac2432cd913a 404 (N
//http://10.211.55.4:33310/api/search:all?sessionid=53947c4e435ad7429bfe9ec972df0ea4&session_id=53947c4e435ad7429bfe9ec972df0ea4&boo=yay


function hideShow(idToHide) {
    if ( $('#'+idToHide).hasClass('hide') ) {
        $('#'+idToHide).removeClass('hide')
    }  else {
        $('#'+idToHide).addClass('hide')
    }
}

var dict = {};


//var sh = require('shelpers').shelpers;
//var shelpers = require('shelpers');

function TestThing() {
    var p = TestThing.prototype;
    p = this;
    var self = this;
    self.count = 0;

    p.method1 = function method1(url, appCode) {
    }

    p.getUserInfo = function getUserInfo(fx) {
        self.utils.makeCall(self.utils.makeUrl('getUserInfo'), fx)
        self.fxSummary = function (data) {
            var result = 'booty';
            result = [data.username , 'is a', data.level, 'user'].join(' ')
            return result
        }
        self.fxTest = function (data) {
            var result = data;
            result = data.username == self.username
            result = result.toString();
            return result
        }
        self.why = 'verify getUserInfo works'
    }

    p.search = function search(fx) {
        //var url = 'http://10.211.55.4:33310/api/search:c'
        self.utils.makeCall(self.utils.makeUrl('api/search:c'+'?'+
            'session_id=' +
            self.sessions.session_id
            ,'33310'), fx)

        self.fxSummary = function (data) {
            var result = 'booty';
            result = [data.media.length, 'items'].join(' ')
            return result
        }
        self.why = 'can search?'
    }

    p.makePayment = function makePayment(fx) {
        //var url = 'http://10.211.55.4:33310/api/search:c'
        var obj = {};
        obj.username = 'admin';
        obj.product = '1';
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);
        self.utils.makeCall(self.utils.makeUrl('paymentCreate'+'?'+
            param
            ,'8888'), fx)
        self.why = 'create test payment'
    }

    p.testPayment = function testPayment(fx) {
        var obj = {};
        obj.username = 'admin';
        obj.product = '1';
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);
        self.utils.makeCall(self.utils.makeUrl('statusOK_'+'?'+
            param
            ,'8888'), fx)
        self.why = 'verify bitpay and electrum are working'
    }

    p.getUserCount = function getUserCount(fx) {
        var obj = {};
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);
        self.utils.makeCall(self.utils.makeUrl('countUsers'/*+'?'+
             param*/
        ), fx)
        self.makeCallShowAll = true;
    }

    p.getCPU = function getCPU(fx) {
        var obj = {};
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);
        self.utils.makeCall(self.utils.makeUrl('getCPU'/*+'?'+
             param*/
        ), fx)
        //self.makeCallShowAll = true;
    }


    p.getTest = function getTest(fx) {
        var obj = {};
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);

        self.makeCallNoRun = true

        self.utils.makeCall(self.utils.makeUrl('index.html?runTest=true&testName=rHome#results=yyy+...+'/*+'?'+
             param*/
        ), fx);
        //localhost:63342/Code/code-yeti/test2/test2.html?runTest=true&testName=testA

    }

    p.getTest2 = function getTest2(fx) {
        var obj = {};
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);

        self.makeCallNoRun = true

        self.utils.makeCall(self.utils.makeUrl('index.html?runTest=true&testName=rLoginExpiredUser#results=yyy+...+'/*+'?'+
             param*/
        ), fx);
        //localhost:63342/Code/code-yeti/test2/test2.html?runTest=true&testName=testA
        self.why = 'verify expired accounts';
    }

    p.getTest3 = function getTest3(fx) {
        var obj = {};
        obj.session_id = self.sessions.session_id;
        var param = $.param(obj);
        self.makeCallNoRun = true
        self.utils.makeCall(
            self.utils.makeUrl('index.html?runTest=true&testName=rLoginExpiredUser#results=yyy+...+'
        ), fx);
        self.why = 'hit all pages';
    }




    p.login = function login(user, password, fx) {
        var data = {}
        data.loginUsername = 'admin'
        data.loginPassword = 'password'
        self.sessions = {};
        $.ajax({
            type: "POST",
            url: url,
            data: data,
            success: success,
            error: errorX,
            dataType: 'json',
            crossDomain: true,
            xhrFields: {
                withCredentials: true
            }
        });

        function success(e) {
            console.log('e', e)
            self.sessions.session_id = e.key;
            self.sessions.sessionid = e.key;
            sh.callIfDefined(fx)
        }

        function errorX(e) {
            console.error('e', e)
        }
    }

    p.run = function method1(url, appCode) {
        var work = new PromiseHelperV3();
        var t = work;
        var token = {};
        token.silentToken = true
        work.wait = token.simulate==false;
        work.startChain(token)
        work.add(function () {
            console.log('password')
            self.login('s', 'p', function () {
                console.log('....ppp')
                t.cb();
            })

        })
        self.work = work;
        self.workChain = work;
        self.utils.addToChain(work)

        self.utils.doNotRun = function doNotRun() {
            work.add(function () {
                self.makeCallNoRun = true
                console.info('do not run', '...')
                t.cb();
            })

        }
        work.addA(self.getUserInfo)
        work.addA(self.search)
        work.addA(self.testPayment)
        work.addA(self.makePayment)
        work.addA(self.getUserCount);
        self.utils.doNotRun()
        // work.addA(self.makePayment)
        work.addA(self.getUserCount);
        work.addA(self.getCPU);
        work.addA(self.getTest)
        work.addA(self.getTest2)
        work.addA(self.getTest3);

        work.add(function x2() {
            console.log('....last call')
        })
    }

    function defineUtils() {
        p.utils = {}
        p.utils.makeCall = function makeCall(url, fxOk, type) {
            // var url = 'http://10.211.55.4:33031/getUserInfo'
            type = sh.dv(type, 'GET')
            console.info('url', url)
            if ( self.makeCallNoRun) {
                console.info('makeCallNoRun', url, self.makeCallNoRun)
                self.makeCallNoRun = false;
                self.makeCallUrl = url;
                self.makeCallResult = null;
                sh.callIfDefined(fxOk);
                return;
            }

            $.ajax({
                type: type,
                url: url,
                /* headers:{
                 session_id: self.sessions.session_id,
                 },*/
                beforeSend: function (request)
                {
                    //  sdf.g
                    // request.setRequestHeader("Authority", 'ggg');
                },
                //data: data,
                success: success,
                error: errorX,
                dataType: 'json',
                crossDomain: true,
                xhrFields: {
                    withCredentials: true
                }
            });

            function success(e) {
                console.info('url', url, 'ok', e)
                self.makeCallUrl = url;
                self.makeCallResult = e;
                self.makeCallSummary = null;
                // debugger;
                sh.callIfDefined(fxOk);
            }

            function errorX(e) {
                console.error('e', e)

                self.makeCallUrl = url;
                self.makeCallResult = e;
                self.makeCallFailed = true;
                self.makeCallSummary = 'error' + e
                // debugger;
                sh.callIfDefined(fxOk);
            }
        }
        p.utils.makeUrl = function makeUrl(url, port) {
            self.port = '33031'
            if ( port  == null ) {
                port = ':' + self.port;
            }else {
                port = ':' + port;
            };

            //var url = 'http://10.211.55.4:33031/getUserInfo'
            var fullUrl = 'http://'+self.ip + port + '/' + url;
            self.url = fullUrl;
            return fullUrl;
        }

        p.utils.addToChain = function addToChain(work) {
            /**
             * Auto adds fx as chain-link
             * @param fx
             * @param args__
             */
            work.addA = function addAMethod(fx, args__) {
                work.add(autoAddedChain)
                var dictKey = self.ip+'_'+fx.name
                dict[dictKey] = autoAddedChain;
                var args = sh.convertArgumentsToArray(arguments);
                function autoAddedChain(rerun) {
                    //console.log('password')
                    args.shift();
                    var fxCallback = args.pop();

                    args.push(function autoGemCallback(data){

                        sh.callIfDefined(fxCallback, data)
                        console.log('....end of auto defined ', fx.name)

                        var divContainer = $('<div />');
                        divContainer.css('padding-left')
                        $('#testOutput').append(divContainer);


                        var divUrl = $('<div />');
                        var divJSON = $('<pre  />');
                        var btnHide = $('<button/>')

                        self.count++;
                        var count = self.count+'. '
                        var a = $('<a />');
                        a.attr('href', self.makeCallUrl);
                        a.html(self.makeCallUrl)
                        a.css('width', '50%');
                        divUrl.html(count  ); //divUrl.html(count     );
                        divUrl.append(a);
                        //divSpan.html(sh.toJSONString(self.makeCallResult));
                        divJSON.append('<br/>');
                        divJSON.html(JSON.stringify(self.makeCallResult, undefined, 2));

                        var idResultsDiv = 'results_'+self.count

                        divUrl.append(' ');

                        btnHide.html('hide');


                        btnHide.attr('onclick', 'hideShow('+sh.q(idResultsDiv)+')')
                        btnHide.addClass('btn btn-default')
                        divUrl.append(btnHide);


                        var btnHide = $('<button/>')
                        btnHide.html('replay');
                        btnHide.attr('onclick', 'hideShow('+sh.q(dictKey)+')')
                        btnHide.addClass('btn btn-primary')
                        divUrl.append(btnHide);

                        // debugger;
                        //$('#testOutput').append('<br/>');
                        // $('#testOutput').append('<br/>');


                        divContainer.append(divUrl)

                        if ( self.why ) {
                            var divWhy = $('<div  />');
                            divWhy.html(self.why)
                            divContainer.append(divWhy)
                            self.why = null;
                        }
                        divContainer.append('<br/>');
                        divJSON.attr('id', idResultsDiv);
                        if ( self.makeCallShowAll != true ) {
                            divJSON.addClass('hide');
                        }
                        self.makeCallShowAll = false;

                        divContainer.append(divJSON)

                        if ( self.makeCallFailed != true ) {
                            if (self.fxSummary) {
                                var divSummary = $('<pre  />');

                                try {
                                    divSummary.html(self.fxSummary(self.makeCallResult))
                                } catch ( e ) {
                                    divSummary.html(e);
                                    //hide by default
                                    //divJSON.addClass('hide');
                                }

                                divContainer.append(divSummary)

                            }
                            if (self.fxTest) {
                                var divTest = $('<pre  />');
                                divTest.html(self.fxTest(self.makeCallResult))
                                divContainer.append(divTest)

                            }
                            ;
                        } else {
                            var divTest = $('<pre  />');
                            divTest.html( (self.makeCallResult))
                            divContainer.append(divTest)
                            divTest.addClass('btn-danger')
                            //btn btn-danger
                        }

                        self.fxSummary = null;
                        self.fxTest = null;
                        self.makeCallFailed = false;
                        work.cb();
                    })
                    // sh.callIfDefined(fx, args)
                    args.unshift(fx); //add to front
                    sh.callIfDefined.apply(null, args)
                    /* self.login('s', 'p', function () {

                     })*/
                }

            }
        }
    }
    defineUtils()

    p.proc = function debugLogger() {
        if ( self.silent == true) {
            return
        }
        sh.sLog(arguments)
    }


}

/*
 exports.TestThing = TestThing;

 if (module.parent == null) {

 }
 */

var t = new TestThing();
t.ip = '10.211.55.4'
t.ip = window.location.hostname;
t.username = 'admin'
var url = 'http://'+t.ip+':33031/api/login'
t.run();


function testTest() {
    var data = {}
    data.loginUsername = 'admin'
    data.loginPassword = 'password'
    var sessions = {};
    $.ajax({
        type: "POST",
        url: url,
        data: data,
        success: success,
        error: errorX,
        dataType: 'json',
        crossDomain: true,
        xhrFields: {
            withCredentials: true
        }
    });

    function success(e) {
        console.log('e', e)
        sessions.session_id = e.key;
        sessions.sessionid = e.key;
        asdf()
        doSearch()
    }

    function errorX(e) {
        console.error('e', e)
    }


    function asdf() {
        var url = 'http://'+t.ip+':33031/getUserInfo'
        $.ajax({
            type: "GET",
            url: url,
            //data: data,
            success: success,
            error: errorX,
            dataType: 'json',
            crossDomain: true,
            xhrFields: {
                withCredentials: true
            }
        });

        function success(e) {
            console.log('ok', e)
        }

        function errorX(e) {
            console.error('e', e)
        }
    }

    function doSearch() {
        // curl 'http://10.211.55.4:33310/api/search:c?session_id=50409b30796ef15b3f3d5a42408c2147&boo=yay' -H 'Accept: */*' -H 'Referer: http://10.211.55.4:33031/' -H 'Origin: http://10.211.55.4:33031' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.87 Safari/537.36' --compressed
        var url = 'http://'+t.ip+':33310/api/search:c'
        $.ajax({
            type: "GET",
            url: url,
            data: sessions,
            success: success,
            error: errorX,
            dataType: 'json',
            crossDomain: true,
            xhrFields: {
                withCredentials: true
            }
        });

        function success(e) {
            console.log('e', e)
        }

        function errorX(e) {
            console.error('e', e)
        }
    }
}