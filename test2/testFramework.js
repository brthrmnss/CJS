/**
 * Created by morriste on 2/12/16.
 */
if ( typeof window === 'undefined' ) {
    var window = {}
    window.location = {};
    window.location.hash = ''
    window.location.search = ''
    window.runTest = true //force
    var PromiseHelperV3 = require('./PromiseHelperV3').PromiseHelperV3;
    var sh = require('./shelpers').shelpers;
}
window.tests = {}
var testHelper = {};
function defineLoadParams() {
    testHelper.getParams = function getParamsFromUrl() {
        function getQueryObj() {
// This function is anonymous, is executed immediately and
// the return value is assigned to QueryString!
            var query_string = {};
            var query = window.location.search.substring(1);
            if ( query == '' && window.location.hash.indexOf('?') != 0 ) {
                query = window.location.hash.split('?')[1];
            }
            if ( query == null ) {
                query = '';
            }
            var vars = query.split("&");
            for (var i=0;i<vars.length;i++) {
                var pair = vars[i].split("=");
// If first entry with this name
                if (typeof query_string[pair[0]] === "undefined") {
                    query_string[pair[0]] = decodeURIComponent(pair[1]);
// If second entry with this name
                } else if (typeof query_string[pair[0]] === "string") {
                    var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
                    query_string[pair[0]] = arr;
// If third or later entry with this name
                } else {
                    query_string[pair[0]].push(decodeURIComponent(pair[1]));
                }
            }
            return query_string;
        } ;
        testHelper.params = getQueryObj();
    }
    testHelper.getParams();
}
defineLoadParams();

function defineJQueryHelpers() {
    testHelper.findByContent = function (contnet) {
        return $('body').children()
            .filter(
            function(){
                return $(this).text().toLowerCase() === contnet;
            })
    }
}
defineJQueryHelpers();
var tH = testHelper;
function defineTestTransportFxs() {
    tH.createNewTest = function createNewTest(){
        var work = new PromiseHelperV3();
        window.testInProgress = true;
        var t = work;
        var token = {};
        token.silentToken = true
        work.wait = token.simulate==false;
        work.startChain(token)
        tH.test = t;
        tH.addLogPanel = function addLogPanel() {
            if ( $('#testLogPanel').length == 0 ) {
                $('body').append('<div style="position: fixed; bottom: 10px; right: 10px;display: none; color:red; " id="testLogPanel">asdf  </div>')
            }
        }
        tH.addLogPanel();
        return t;
    }

    tH.addTestStep = function addTestStep(fx_testLink) {
        tH.test.add(fx_testLink);
        tH.test.add(function reportToServer() {
            var delayTime = sh.dv(tH.test.delayTime, 10)
            setTimeout(tH.test.cb, delayTime)
        })
        tH.test.add(function addStandardDelayTime() {
            var delayTime = sh.dv(tH.test.delayTime, 10)
            setTimeout(tH.test.cb, delayTime)
        })
    }
    tH.add = tH.addTestStep;

}
defineTestTransportFxs();

function defineTestMethods() {
    function click(strOrJ) {
        tH.add(function clickAction() {
            var element = tH.findByContent(strOrJ);
//TODO: fail if do not find object?
//Optional ? ... never used too much cognitive load ..
//if need to verify if exists, then verify
            element.css('color', 'red');
            element.click();
            console.log('click', strOrJ, element.length)
            tH.test.cb();
        })
    }
    tH.click = click;
    function clickJ(strOrJ) { //find based on jquery
        tH.add(function clickAction() {
            var element = $(strOrJ);
            element.css('color', 'red');
            element[0].click();
            console.log('click', strOrJ, element.length)
            tH.test.cb();
        })
    }
    clickJ.desc = 'Click button. Get element from jquery stringn'
    tH.clickJ = clickJ;
    function verify(fx) {
        tH.add(function clickAction() {
            if ($.isFunction(fx)) {
                var result = fx();
            }
            else {
                var result = $(fx).length > 0;
            }
            console.log('result',result)
            if ( result != true ){
                tH.fail(['failed to verify', fx])


            }
            tH.test.cb();
        })
    }
    var verifyExists = verify;
    tH.verifyExists = verify;
    tH.verify = verify;

    function log(str) {
        tH.add(function log() {
            console.log('logged',str)
            $('#testLogPanel').show()
            $('#testLogPanel').text(str)
            tH.test.cb();
        })
    }
    tH.log = log;
    function wait(waitTime) {
        tH.add(function waitLink() {
            setTimeout(function resumeTest(){
                tH.test.cb();
            }, waitTime* 1000)
        })
    }
    wait.desc = 'Wait x seconds'
    tH.wait = wait;
    function waitFor(fx, maxTimes, delay, failWhenDone) {
        maxTimes = sh.dv(maxTimes, 10)
        delay = sh.dv(delay, 250)
        failWhenDone = sh.dv(failWhenDone, true)
//debugger
        tH.add(function waitFor_Action() {
//debugger
            var innerT  = new PromiseHelperV3();
            var token = {};
            innerT.silentToken = true
            token.name = 'waitfor-str'
            innerT.wait = token.simulate==false;
            innerT.startChain(token)
            innerT.maxIterations = maxTimes;
            innerT.iteration = 0;

            innerT.addNext(testWaitForCondition)
            innerT.addNext(addWaitForDelay)
            function testWaitForCondition() {
// try {
                var result = fx();
// } catch(e) {
//    console.error(e)
//
//  }
                console.log('waitfor-result',result,
                    innerT.iteration, innerT.maxIterations, fx.name)
                if ( result != true ){
                    if (innerT.iteration > innerT.maxIterations) {
                        debugger;
                        if ( failWhenDone ) {
                            tH.fail(['failed on thing ',
                                innerT.iteration ,
                                innerT.maxIterations])
                            throw new Error(
                                ['failed on thing ',
                                    innerT.iteration ,
                                    innerT.maxIterations].join(' ')
                            )

                        } else {
                            tH.test.cb();
                        }
                    } else {
                        innerT.iteration++
                        innerT.addNext(testWaitForCondition)
                        innerT.addNext(addWaitForDelay)
                        innerT.cb();
                    }
                } else {
                    tH.test.cb();
                }
            }
            function addWaitForDelay () {
                setTimeout(innerT.cb, delay)
            }

        })
    }
    tH.waitFor = waitFor;
    function changeLocation(url) {
        tH.add(function log() {
            console.log('url',url)
            window.location = url;
            tH.test.cb();
        })
    }
    changeLocation.desc = 'change url, can ad test into url'
    tH.changeLocation = changeLocation;
    function runFx(fx) {
        tH.add(function log() {
            fx();
            tH.test.cb();
        })
    }
    runFx.desc = 'run arbitrary method (fx)'
    tH.runFx = runFx;
    tH.run = runFx;
    function runFxAsync(fx) {
        tH.add(function log() {
            fx();
        })
    }
    runFx.desc = 'run arbitrary method (fx), dev must call cb to continue'
    tH.runFxAsync = runFxAsync;
    tH.runAsync = runFxAsync;

    //add description of step for failure
    function addDesc(desc) {
        //fidn previous callback and add this string to it
        tH.log(desc)
    }
    tH.desc=addDesc;

    tH.fail = function failTest(errorArr, asdf) {
        alert('test failed')
        tH.log('Test Failed')
        throw new Error(errorArr.join(' '))

    }



    tH.waitForHide = function waitForHide(jquery) {
        tH.waitFor(function isDialogVisible(){ //waitForHide
            if (
                $(jquery).css("opacity") == "0" ||
                $(jquery).css("display") == "none" ||
                $(jquery).css("visibility") == "hidden"
            ) {
                return true
            }

            return false;//==$(jquery).is(":visible")
        });
    };
    tH.waitForShow = function waitForShow(jquery) {
        tH.waitFor(function isDialogVisible(){ //waitForShow
            console.log('jquery wait for', jquery)
            if ($(jquery).css("opacity") != "0" &&
                $(jquery).css("visibility") != "hidden" ) {
                return true
            }
            return true;//==$(jquery).is(":visible")
        });
    };
    tH.verifyHidden = function waitForShow(jquery) {
        tH.waitFor(function isDialogVisible(){ //waitForHide
            if ($(jquery).css("opacity") == "0") {
                return true
            }
            return false==$(jquery).is(":visible")
        });
    };
    tH.verifyShow = function waitForShow(jquery) {
        tH.verify(function isDialogVisible(){ //waitForHide
            if ($(jquery).css("opacity") != "0") {
                return true
            }
            return true==$(jquery).is(":visible")
        });
    };
    tH.moreThanX = function ensureMoreThanXJqueryElements(jquery, count) {
        tH.verify(function verifySearchResults() { //verify more than 6
            return $(jquery).length > count
        });
    }

    tH.clickOne = function clickOne(jquery, index) {
        tH.run(function clickOne() { //verify more than 6
            index = sh.dv(index, 0);
            var elements = $(jquery);
            if ( index < 0) {
                index = elements.length+ index;
            }
            var element = $(jquery).children()[index];
            // console.log('...function to run' , elements.length, index, element, elements )
            //  console.log('...function to run' , element.text())
            $(jquery).children()[index].click();
        });
    }
}
defineTestMethods();


function defineCompoundMethods() {
    /*tH.waitForHide = function waitForHide(jquery) {
        tH.waitFor(function isDialogVisible(){ //waitForHide
            if ($(jquery).css("opacity") == "0") {
                return true
            }
            return false==$(jquery).is(":visible")
        });
    };*/
    tH.waitForShow = function waitForShow(jquery) {
        tH.waitFor(function isDialogVisible(){ //waitForHide
            if ($(jquery).css("opacity") != "0") {
                return true
            }
            return true==$(jquery).is(":visible")
        });
    };
    tH.verifyHidden = function waitForShow(jquery) {
        tH.waitFor(function isDialogVisible(){ //waitForHide
            if ($(jquery).css("opacity") == "0") {
                return true
            }
            return false==$(jquery).is(":visible")
        });
    };
    tH.verifyShow = function waitForShow(jquery) {
        tH.verify(function isDialogVisible(){ //waitForHide
            if ($(jquery).css("opacity") != "0") {
                return true
            }
            return true==$(jquery).is(":visible")
        });
    };
    tH.moreThanX = function ensureMoreThanXJqueryElements(jquery, count) {
        tH.verify(function verifySearchResults() { //verify more than 6
            return $(jquery).length > count
        });
    }

    tH.clickOne = function clickOneOfElementsInJquery(jquery, index) {
        tH.run(function clickOne() { //verify more than 6
            index = sh.dv(index, 0);
            var elements = $(jquery);
            if ( index < 0) {
                index = elements.length+ index;
            }
            var element = $(jquery).children()[index];
            // console.log('...function to run' , elements.length, index, element, elements )
            //  console.log('...function to run' , element.text())
            $(jquery).children()[index].click();
        });
    }


    tH.set = function setTextField(jquery, text) {
        tH.run(function settext() { //verify more than 6
            //debugger
            $(jquery).val(text)
        });
    }

}
defineCompoundMethods();


function defineContinuitiyMethods() {
    tH.nextTest = function nextTest(testName_, text) {
        var config = {};
        config.testName = testName_
        Cookies.set('nextTest', config);
    }
    //check for next test
    function checkForNextTest() {

        //if cookie, reset to null
        var nextTest = Cookies.getJSON('nextTest');

       // debugger;
        if ( nextTest) {
            window.testInProgress = true;
            //debugger;
           Cookies.set('nextTest', null); //clear cookie
            if ( tH.params.runTest=='true' ){
                console.log('have next test, but runTest is true')
                return;
            }
            function runTestX(testName, testDelay) {
                var testDelay = parseInt(testDelay)
                testDelay= sh.dv(testDelay, 0);
               // debugger;
                if ( testName ){
                    console.info(
                        'Running test', testName, ''
                    )

                    setTimeout(function runTest() {

                        if ( window.testsLoaded != true ) {
                            console.warn('tests not loaded yet')
                            setTimeout(runTest, 200+testDelay)
                            return;
                        }


                        window.tests[testName](tH);
                    }, 200+testDelay)
                } else{
                     runTest();
                }
            }

            runTestX(nextTest.testName)
        }
    }

    checkForNextTest()

}
defineContinuitiyMethods();

if ( typeof $ === 'undefined' ) {
    var jqueryImpersonator = {};
    function JqueryImpersonatorFx() {
        var self  = this;
        self.css = function () {
        }
        self.click = function click() {
        }

        return self;
    };
    JqueryImpersonatorFx.isFunction = function (x){}
    var $ = JqueryImpersonatorFx
}
//http://rr413c1n7.ms.com:10050/test2/test2.html?runTest=true
if ( tH.params.runTest=='true' || window.runTest == true ) {
    var testName = tH.params.testName;
    var testDelay = parseInt(tH.params.testDelay)
    testDelay= sh.dv(testDelay, 0);
    if ( isNaN(testDelay)) {
        testDelay = 0;
    }
    if ( testName ){
        console.info(
            'Running test', testName, '', window.tests, testDelay
        )
        setTimeout(function runTest() {
            window.tests[testName](tH);
        }, 200+testDelay)
    } else{
        runTest();
    }
} else {
    console.log(
        'Skipped All tests....'
    )
}

function runTest() {

    /*.add(self.searchByName)
     .log()
     // .add(self.getFirstQuery)
     //  .add(self.convertMagnetLinkToTorrent)
     .log()
     .add(self.returnMagnetLink)
     .end();*/
    var t = tH.createNewTest();
    tH.test = t;


    /*setTimeout(function lateAlert(){
     alert('...')
     }, 1000)*/
//changeLocation('http://www.yahoo.com') //forward to another url ... and test
    tH.clickJ('#btnTest');
    tH.verifyExists('#btnTest')
    tH.click('test')
    tH.click('test 2', false)
    tH.log('before waitfor')
    tH.waitFor(function(){
        return window.y == 5
    })
    tH.log('after waitfor')
}

function clickTest2() {
    setTimeout(setYValue, 1500)
    function setYValue() {
//return;
        window.y = 5;
        console.log(
            'clicked test 2'
        )
    }
}
//http://rr413c1n7.ms.com:10050/test2/test2.html?runTest=true&testName=testA
function testStackingDemo2() {
// return
    window.tests.testA = function defineTestA(tH) {
        var t = tH.createNewTest();
        tH.click('test 2');
        tH.log('test 2')
        tH.wait(1)
        tH.log('test 2')
        tH.run(function(){
            alert('ran test 2')
        })
    }
}
testStackingDemo2();


