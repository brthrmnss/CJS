/**
 * Quick method to make post requests against server asnyc
 * @type {exports}
 */
var shelpers = require('shelpers')
var sh = shelpers.shelpers;
var PromiseHelperV3 = shelpers.PromiseHelperV3;
var express = require('express')
var GenerateData = shelpers.GenerateData;
var  test = {}

var Sequelize = require('sequelize')
var sequelize = null;

var fs = require('fs');


function EasyRemoteTester() {
    var self = this;
    self.data = {};
    self.timeStart = new Date();

    var types = {};
    types.POST = 'POST'
    types.GET = 'GET'
    types.PUT = 'PUT'


    var TestHelper = shelpers.TestHelper;
    var reqPost = TestHelper.reqPost;


    function defineQuickRequests() {
        /**
         * Creates request for short command
         * @param url
         * @param method
         * @param fx
         * @param postData
         * @param doRegPost
         */
        self.quickRequest = function quickRequest(url, method, fx, postData, doRegPost, postJSON) {
            if (method == null) {
                method = types.GET
            }
            var reqoptions = {}
            if ( url.url != null ) {
                reqoptions = url;
                url = url.url;
            }
            if (url == null) {
                throw new Error('url null');
            }
            reqoptions.url = url; //'http://localhost:' + self.settings.port + '/' + url
            if (postData == null) {
                postData = {};
            }
            method = method.toLowerCase();
            if (method == types.POST.toLowerCase() || method == types.PUT.toLowerCase()) {
                if (doRegPost == 'fileupload') {
                    //reqoptions.json = true
                    //reqoptions.body = postData;
                    reqoptions.encoding = null;
                }
                else if (doRegPost || doRegPost == 'form') {
                    reqoptions.form = postData
                } else {
                    //reqoptions.json = true
                    //reqoptions.body = "gg"
                    if (postJSON != false) {
                        reqoptions.json = true;
                    }
                    reqoptions.body = postData
                }
            } else {
                reqoptions.qs = postData
            }

            //aself.settings = sh.dv(self.settings, {});

            if (self.settings.silent != true) {
                console.log('    $', url)
            }
            reqoptions.silent = self.settings.silent;
            reqoptions.urlTimeout = self.settings.urlTimeout;
            reqoptions.method = method
            //do not show body if false
            if ( self.settings.silent === true) {
                if ( self.settings.showBody == null) {
                    self.settings.showBody = sh.dv(self.settings.showBody, false);
                }
            }
            self.settings.showBody = sh.dv(self.settings.showBody, true);
            reqoptions.showBody = self.settings.showBody;
            reqoptions.fx2 = function storeContents(body, resp) {
                self.proc(reqoptions.url, 'results')
                try {
                    body = JSON.parse(body)
                } catch (e) {

                }

                self.lastRequestBody = body;
                self.lastResponse = resp;

                self.assert.failed = function assertLastRequestFailed() {
                    var statusCode = self.lastResponse.statusCode;
                    self.assert(self.lastResponse.statusCode.toString().slice(0,1)=="4",
                        sh.join('request succeed ', statusCode, 'expected to fail, so error'))
                }

                self.assert.fault =  self.assert.failed;

                self.assert.success = function assertLastRequestFailed() {
                    var statusCode = self.lastResponse.statusCode;
                    self.assert(statusCode.toString().slice(0,1)!="4",
                        sh.join('request failed ', statusCode, 'expected to succeed, so error'))
                }
                self.assert.ok = self.assert.success;
                self.assert.reqOk = self.assert.success;

                if (fx) {
                    fx(body, resp)
                }
            };
            reqoptions.name = 'test ' + sh.paren(url)

            reqoptions.request = self.request;
            if ( self.fxNextRequest ) {
                self.fxNextRequest(reqoptions)
                self.fxNextRequest = null; 
            }
            if ( self.nextHeaders ) {
                reqoptions.headers =  self.nextHeaders;
                self.nextHeaders = null; 
            }
            //console.log('testing...')
            console.error('what is request1', reqoptions)
            var req = reqPost(reqoptions);
            if (method == types.POST.toLowerCase()) {
                if (doRegPost == 'fileupload') {
                    // console.log('req', req.form)
                    var form = req.form();
                    form.append('file', fs.createReadStream(postJSON))
                    if ( postData ) {
                        sh.each(postData, function appendToForm(k,v) {
                            //form.append('channel', 'cnn')
                            form.append(k,v)
                        })
                    }

                }
            }
        }
    }
    defineQuickRequests();

    self.create = function create(token) {
        var verbs = {}
        verbs.actions = {}
        verbs.isJSON = 'isJSON'
        verbs.hasXResults = function hasXResults(amt) {


        }
        //has(6).results()
        //create task
        //list tasks
        //show all tasks
        //create task via put
        //create task


        /*

         new Verb().has(6).isJSON
         json.length == 6

         */

        self.settings = token;

        //var token = {}
        if (token == null) {
            token = {};
        }
        var workChain = new PromiseHelperV3();
        token.silentToken = true
        workChain.wait = token.simulate == false;
        workChain.startChain(token);//

        self.workChain= workChain;


        self.createHelpers();
        defineMergeChainWithRemote();
        defineTestVerbHelpers()

        if ( self.settings != null && self.settings.resetRequest == true ) {
            self.request =TestHelper.request(); ;
        }
        return workChain;
    }


    self.clone = function clone(newName) {
        return EasyRemoteTester.create(newName, self.settings);
    }


    function defineUtils2() {
        /**
         * Test helper is a concurrent object that can be used to track
         * expected values of tests.
         */
        self.createHelpers = function createHelpers() {

            var data = {}
            data.expectedRecordLength = 100;//tasks.utils.getLength(); //tasks.records.length;
            data.checkRecordSize = function checkRecordSize() {
                return tasks.lastLength == data.expectedRecordLength
            }
            data.addItem = function addItem() {
                data.expectedRecordLength++;
            }
            data.removeItem = function removeItem() {
                data.expectedRecordLength--;
            }

            data.bodyHasError = function bodyHasError(bodyResponse) {
                if (sh.startsWith(bodyResponse, 'Cannot')) {
                    return true;
                }
                return sh.includes(bodyResponse, 'Error')
            }

            data.isFailure = function isFailure(resp) {
                return resp.statusCode == 404
            }


            data.assert = function assert(eq, msg) {
                /*if ( self.optionalAssertions == true ) {
                 msg = '<<<<Optional>>>>>>'
                 }*/
                var throwError = !self.optionalAssertions;
                var error = sh.errors.jumpError(msg, 5, eq,
                    self.workChain.currentOperation.stack, throwError)
                if ( error ) {
                    self.errorWithReq = true;
                    if ( throwError ) {
                        //give windows machine time to flush stdout
                        setTimeout(function clearStout() {
                            process.exit()
                        }, 50)
                    } else {
                        self.proc('last failure was <<<<<<<optional>>>> so thread not terminating')
                    }
                }
                /*if (eq == false) {
                 throw new Error(msg);
                 }*/
            }


            self.helper = data;
            data.workChain = self.workChain;
            return data;

        }

        /**
         * Method enables you to avoid passing the callback into the
         * test link.
         * Ex:
         * var t = new EasyRemoteTester();
         * function testChain2(token, cb) {
         *       console.log('testChain2');
         *       cb();
         *   }
         becomes:

         var t = new EasyRemoteTester();
         function testChain2() {
                console.log('testChain2');
                t.cb();
            }
         */
        self.cb = function cb_callCurrentCallback() {
            self.workChain.cb();
        }





        self.utils = {}
        self.utils.createTestingUrl = function createTestingUrl(end, port){
            var url = 'http://localhost'
            if  ( self.settings.baseUrl != null   ) {
                url =   self.settings.baseUrl
            }
            if  (   sh.includes(url, '://') == false  ) {
                url = 'http://' + url
            }

            port = sh.dv(port, self.settings.port)
            port = sh.dv( self.settings.portOverride, port )

            if ( port != null ) {
                url += ':' + port;
            }
            if ( ! sh.startsWith(end , '/')){
                url += '/';
            }
            url += end;

            return url;
        }

        self.time = function showTimeLog(msg) {
            sh.time.secsPast = function secsPast(time) {
                var diff = new Date().getTime() - time.getTime()
                var diff = (diff/1000)
                diff = diff.toFixed(0);
                return diff;
            }
            self.proc('elapsed time', sh.time.secsPast(self.timeStart), msg)
        }

        self.lastRequestOK = function lastRequestOK(msg){
            var okCode = 200;
            if (self.lastResponse.statusCode == 201 ) {
                okCode = 201;
            }
            if (self.lastResponse.statusCode == 202 ) {
                okCode = 202;
            }
            self.as2(self.lastResponse.statusCode , okCode, 'the last request failed')
        }
    }
    defineUtils2()


    function defineMergeChainWithRemote(){
        self.add = function add(fx) {
            self.workChain.add(fx);
        }

        self.addS = function addS(fx) {
            self.workChain.addS(fx);
        }
        self.addNext = function addNext(fx, offset) {
            self.workChain.addNext(fx, offset);
        }

        /**
         * Used for adding new functions that spawn tests , without waiting.
         * will move on to next step
         * @param fxSync
         */
        self.addSync = function addSync(fxSync) {
            self.add(function addSync() {
                fxSync()
                self.cb();
            })
        }

        self.xadd = self.addS;
        self.assert = function assert(match, msg) {
            self.helper.assert(match, msg);
        }
        self.as2 = function as2(a,b, msg) {
            var fault = a==b
            if ( b == null ) {
                fault = a;
            }
            self.helper.assert(fault,
                sh.str.join(
                    msg, sh.paren(sh.str.join(a,'!=', b))
                ) );
        }
        self.wait = function wait(seconds, addToChain) {
            seconds = sh.dv(seconds, 3);
            return  self.workChain.utils.wait(seconds, addToChain);
        }
        self.addPause = function addPause(msg, stop) {
            self.add(function addPause() {
                console.log(msg)
                if ( stop == null ) {
                    self.cb();
                }
            })
        }

        /**
         * Add a log callback
         * @param msg
         * @param breakLines
         * @param stop
         */
        self.log = function log(msg, breakLines, stop) {
            breakLines = sh.dv(breakLines, 2)
            self.add(function log() {
                sh.each.times(breakLines, function () {
                    console.log()
                })
                console.log(msg)
                if ( stop == null ) {
                    self.cb();
                }
                sh.each.times(breakLines, function () {
                    console.log()
                })
            })
        }
        self.logNow = function log(msg, breakLines, stop) {
            //breakLines = sh.dv(breakLines, 2)
            // self.add(function log() {
            sh.each.times(breakLines, function () {
                console.log()
            })
            console.log(msg)

            sh.each.times(breakLines, function () {
                console.log()
            })
            // })
        }



        /*self.quickRequest = function quickRequest() {
         sh.forwardArguments(arguments, self.helper.quickRequest)
         //self.helper.quickRequest(match, msg);
         }*/
        //self.quickRequest =  self.helper.quickRequest;

        self.addInner = function add(fx) {
            self.add(function addInnerTest() {

                fx(result)
                function result(body) {
                    console.log('<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>' )
                    self.cb();
                    return;
                }
            });
        }

    }


    function defineTestVerbHelpers() {


        self.testsEnable = function testsEnable() {

            function testEnabled(){
                if ( self.settings.testDisabled == false ) {
                    return; //why: ignore if not disabled, for safety of binding
                }
                self.settings.testDisabled = false
                self.nextBinding = null;
            }

            self.add(  function testEnabled_Cb(t,cb){
                testEnabled();
                cb()
                //self.cb();
            });
            testEnabled()
            return self;
        }
        self.testsDisable = function testDisable() {

            self.add(function testsDisable(t,cb){
                self.settings.testDisabled = true
                var dbg = [cb==self.cb]
                self.nextBinding = {};
                /*self.*/cb();
            });
            self.settings.testDisabled = true
            self.nextBinding = {};
            return self;

        }

        self.postR = function getR(url) {
            return self.getR(url, 'post')
        }

        self.getR = function getR(url, type) {
            if ( self.settings.testDisabled ) {
                return self;
            }
            if ( url == null ) {
                throw new Error('url not defined')
            }
            type = sh.dv(type, 'get')
            //inner data for function call
            var innerDataForFxCall = {}
            //for reuse in chained methods
            self.nextBinding = innerDataForFxCall;
            //innerDataForFxCall.stackTrace = sh.stack.store(-1);
            function nextFunctionToAdd() {
                var req = innerDataForFxCall.req
                req = sh.dv(req, {});
                var reqObj = innerDataForFxCall.reqObj
                reqObj = sh.dv(reqObj, {});
                sh.callIfDefined(innerDataForFxCall.reqFx, req);
                sh.callIfDefined(innerDataForFxCall.fxCreateRequestObject, reqObj);


                if ( innerDataForFxCall.storedAs != null ) {
                    req = sh.dv(req, {});
                    var val = self.data[innerDataForFxCall.storedAs];
                    req[innerDataForFxCall.addAs]=val;
                };

                var post2 = undefined;
                var post3 = undefined;

                //if upload store upload data
                if ( innerDataForFxCall.uploadPath != null ){
                    type = 'post'
                    post2 = 'fileupload'
                    post3 = innerDataForFxCall.uploadPath;
                }

                if ( sh.isFunction(url)) {
                    var fxGeneralUrl = url;
                    url = fxGeneralUrl();
                }
                if ( reqObj ) {
                    //why: dev can set headers
                    reqObj.url = url;
                } else {
                    reqObj = url; //why: set regular url
                }
                reqObj.url = url;

                self.quickRequest(reqObj, type, onResult, req, post2, post3)
                function onResult(body) {

                    /*if ( self.lastResponse.status == 404 ) {

                     }*/
                    var optional = innerDataForFxCall.optional;
                    self.optionalAssertions = optional;
                    if ( optional == true && self.lastResponse == null ) {
                        body = {'error':'error .... response failed ...'}
                    } else {
                        self.assert(self.lastResponse.statusCode != 404,
                            '404 not found');
                    }

                    innerDataForFxCall.conditions = sh.dv(innerDataForFxCall.conditions, []);
                    sh.each(innerDataForFxCall.conditions, function procC(i, cond) {
                        if ( cond.type == 'has') {
                            cond.msg = sh.dv(cond.msg);
                            var val = body[cond.prop];
                            if ( val == null ) {
                                console.log('null', body);
                            }
                            self.assert(val != null,
                                [ ' hasBody failed .... did not have this ' ,
                                    cond.prop , cond.msg ,body].join("\n"));
                        }
                        var parentCond = cond;

                        if ( cond.subs != null) {
                            sh.each(cond.subs, function procC(i, cond) {
                                cond.msg = sh.dv(cond.msg)

                                if (cond.type == 'notEmpty') {
                                    self.assert(val != null && val.length != 0,
                                        'this is empty: (not empty) ' + parentCond.prop + cond.msg);
                                }
                                if ( cond.type == 'includes') {
                                    self.assert(sh.includes(val, cond.findStr),
                                        'did not have this ' + val +  cond.findStr);
                                }
                                if ( cond.type == 'eqVal') {
                                    self.assert(val == cond.eqVal,
                                        ' eqVal not matched ' + val + ' ' +  cond.eqVal);
                                }
                                if ( cond.type == 'includesAsString') {
                                    self.assert(sh.includes(JSON.stringify(val), cond.findStr),
                                        [JSON.stringify(val), cond.findStr,
                                            'did not have this ', sh.qq(val), sh.qq(cond.findStr)]);
                                };
                                if ( cond.type == 'includesAsStringNot') {
                                    self.assert(!sh.includes(JSON.stringify(val), cond.findStr),
                                        'did not have this ' + val +  cond.findStr);
                                }
                            });
                        }

                    });

                    if ( innerDataForFxCall.fxOrStoreKey !=  null  ) {
                        var val = body;
                        if ( innerDataForFxCall.getProp !=  null  ) {
                            val = val[innerDataForFxCall.getProp]
                        }
                        self.data[innerDataForFxCall.fxOrStoreKey] = val
                    }


                    if ( innerDataForFxCall.showBody ) {
                        self.proc('body for', url, body)
                    }

                    if ( innerDataForFxCall.fxEnd ) {
                        sh.callIfDefined(innerDataForFxCall.fxEnd, body)
                    }
                    if ( self.errorWithReq == true && innerDataForFxCall.fxFail ) {
                        sh.callIfDefined(innerDataForFxCall.fxFail, body)
                    } else {
                        sh.callIfDefined(innerDataForFxCall.fxSuccess, body)
                    }
                    self.optionalAssertions = false;
                    self.errorWithReq = false;
                    self.cb();
                };
            };
            self.add(nextFunctionToAdd);
            return self;
        }

        self.with = function with_AddDataToReq(req, fx) {
            self.nextBinding.req = req;
            self.nextBinding.reqFx = fx;
            return self;
        }

        self.addPreFx = function addPreFx_modityRequest( fx) {
            //self.nextBinding.req = req;
            self.nextBinding.fxCreateRequestObject = fx;
            return self;
        }

        //add to next request
        self.addToRequestFromStore = function addToRequest(storedAs, addAs) {
            self.nextBinding.storedAs = storedAs;
            self.nextBinding.addAs = addAs;
            return self;
        }

        self.upload = function upload(filepath) {
            self.nextBinding.uploadPath =filepath;
            return self;
        }

        self.and = function and_restartAtObject(req) {
            return self;
        }
        self.storeHere = function storeHere(fxOrStoreKey, getProp) {
            self.nextBinding.fxOrStoreKey = fxOrStoreKey;
            self.nextBinding.getProp = getProp;
            return self;
        }
        self.storeResponseProp = self.storeHere;



        self.showBody = function showBody() {
            self.nextBinding.showBody = true;
            return self;
        }

        self.makeOptional = function makeReqOptional() {
            self.nextBinding.optional = true;
            return self;
        }

        self.addFx = function addFx(fx) {
            self.nextBinding.fxEnd = fx;
            return self;
        }
        self.fxDone = self.addFx

        self.fxFail = function fxFail(fx) {
            self.nextBinding.fxFail = fx;
            return self;
        }

        self.fxSuccess = function fxSuccess(fx) {
            self.nextBinding.fxSuccess = fx;
            return self;
        }

        /**
         * Timeout to wait before failing this request.
         * May need to add timer to cancel request
         * @param seconds
         */
        self.timeout = function timeout(seconds) {
            self.nextBinding.timeout = timeout*1000
            return self;
        }

        self.why = function whyDidYouCallThis(reason) {
            return self;
        }

        //conditionals
        function defineConditionals(){
            self.bodyHas = function bodyHas(prop, msg) {
                var condition = {};
                condition.type = 'has';
                condition.prop = prop;
                condition.msg = msg
                condition.subs =  [];
                // if ( self.verb_lastConditinal == null ) {
                self.verb_lastConditinal = condition;
                // }
                self.nextBinding.conditions = sh.dv(
                    self.nextBinding.conditions, []);
                self.nextBinding.conditions.push(condition)

                return self;

            };
            self.notEmpty = function notEmpty(msg) {
                var condition = {};
                condition.type = 'notEmpty';
                condition.msg = msg;
                self.verb_lastConditinal.subs = sh.dv(
                    self.verb_lastConditinal.subs, []);
                self.verb_lastConditinal.subs.push(condition);
                return self;
            };

            self.includes = function includes(str, msg) {
                var condition = {};
                condition.type = 'includes';
                condition.findStr = str;
                condition.msg = msg;
                self.verb_lastConditinal.subs = sh.dv(
                    self.verb_lastConditinal.subs, []);
                self.verb_lastConditinal.subs.push(condition);
                return self;
            };
            self.includesAsString = function includesAsString(str, msg) {
                var condition = {};
                condition.type = 'includesAsString';
                condition.findStr = str;
                condition.msg = msg;
                self.verb_lastConditinal.subs = sh.dv(
                    self.verb_lastConditinal.subs, []);
                self.verb_lastConditinal.subs.push(condition);
                return self;
            };
            self.includesAsStr = self.includesAsString;
            self.includesAsStrNot = function includesAsStrNot(str, msg) {
                var condition = {};
                condition.type = 'includesAsStringNot';
                condition.findStr = str;
                condition.msg = msg;
                self.verb_lastConditinal.subs = sh.dv(
                    self.verb_lastConditinal.subs, []);
                self.verb_lastConditinal.subs.push(condition);
                return self;
            };
            self.doesNotHaveAsString = self.includesAsStrNot;

            self.eqVal = function eqVal(val, msg) {
                var condition = {};
                condition.type = 'eqVal';
                condition.eqVal  = val;
                condition.msg = msg;

                self.verb_lastConditinal.subs.push(condition);
                return self;
            };
        }
        defineConditionals();

    }

    /**
     * this examples how to use these methods
     */
    function defineUsages()
    {
        self.exampleCreateLocals = function exampleCreateLocals() {
            var assert = data.assert;
            var quickRequest = data.quickRequest;
        }
    }

    /**
     * Dev deocrates 'test' object. each method is converted into link
     */
    function defineTestUsageMode() {

        self.useTestUsageMode = function useTestUsageMode() {
            self.test = {};
            setTimeout(function convertTestItems() {
                // self.convertTestToChains();
            },0)
        }
        self.makeTest = self.useTestUsageMode;
    }
    defineTestUsageMode();



    function create() {

        function testUtilLinks() {
            self.reset = function reset(token, cb) {
                if (tasks.busy == true) {
                    //asdf.g.ds
                    work.tryLater();
                    return;
                    //setTimeout(self.reset, 500)
                }
                taskApiSettings.model = []
                GenerateData = shelpers.GenerateData;
                var gen = new GenerateData();
                /*taskApiSettings.model = gen.create(100, function (item, id, dp){
                 item.name = id;
                 item.id = id;

                 item.desc = GenerateData.getName();
                 })*/
                tasks.utils.empty(function onTableCleared() {
                    tasks.resetDp(function doneReset() {
                        data.expectedRecordLength = 100;
                        cb();
                    })
                })
                ;
                // assert(data.checkRecordSize(), 'did not reset')
            }

            self.getLength = function getLength(token, cb) {
                tasks.utils.getLength(function onGetLength(length) {
                    data.expectedRecordLength = length;
                    cb();
                })

            }

            self.checkRecordSize = function checkRecordSize(token, cb) {
                tasks.utils.getLength(function onGetLength(length) {
                    data.expectedRecordLength = length;
                    assert(data.checkRecordSize(), 'did not reset')
                    cb();
                })
            }

            /**
             * Checks record size, if fails assert, returns message
             * @param msg
             * @param cb
             */
            self.checkSize = function checkSize(msg, cb) {
                tasks.utils.getLength(function onGetLength(length) {
                    //data.expectedRecordLength = length;
                    assert(data.checkRecordSize(), msg + [tasks.lastLength , data.expectedRecordLength].join(','))
                    cb();
                })
            }


        }

        testUtilLinks();


        function testFauxGetRoutes() {

            work.add(self.reset);
            work.add(self.getLength)
            work.add(self.checkRecordSize);


            self.testGet = function testGet(token, cb) {
                self.quickRequest('api/' + tS.name, 'get', result, {id: "6"})
                function result(body) {
                    //return;
                    // tasks.showId(0, 'lll');
                    assert(body.id == 6, 'did not reset')
                    cb();
                }
            }
            //work.add(self.testGet);


            self.get_create = function get_create(token, cb) {
                self.quickRequest('api/' + tS.name + '/create', 'get', result, {name: "randomTask"})
                data.addItem();
                function result() {
                    self.checkSize('did not add task properly', cb)
                    //cb();
                }
            }
            work.add(self.get_create);


            self.get_update = function get_update(token, cb) {
                var newName = "randomTask_@"
                var idToUpdate = 3;
                self.quickRequest('api/' + tS.name + '/update', 'get', result,
                    {id: idToUpdate, name: newName})
                function result() {
                    tasks.getId(idToUpdate, function onGot(item) {
                        assert(item.dataValues.name == newName, 'did not restfully update task properly')
                        cb();
                    })
                }
            }
            work.add(self.get_update);


            self.get_update = function get_create(token, cb) {
                var newName = "randomTask_@"
                var idToUpdate = 4;
                self.quickRequest('api/' + tS.name + '/update', 'get', result,
                    {id: idToUpdate, name: newName})
                function result() {
                    tasks.getId(idToUpdate, function onGot(item) {
                        assert(item.dataValues.name == newName, 'did not restfully update task properly')
                        cb();
                    })
                }
            }
            work.add(self.get_update);

            self.get_update_wrong = function get_create(token, cb) {
                var newName = "randomTask_@"
                self.quickRequest('api/' + tS.name + '/update', 'get', result, {id: -1, name: newName})
                function result(body) {
                    var ok = sh.includes(body, types.errors.recordDoesNotExist);
                    assert(ok,
                        'let me update an invalid task')
                    cb();
                }
            }
            work.add(self.get_update_wrong);

            self.get_delete = function get_delete(token, cb) {
                var newName = "randomTask_@"
                data.removeItem()
                self.quickRequest('api/' + tS.name + '/delete', 'get', result,
                    {id: 8, name: newName})
                function result(body) {
                    self.checkSize(
                        'did not delete task properly', cb)
                    //cb();
                }
            }
            work.add(self.get_delete);

            self.get_delete_with_id_broken = function get_delete_with_id_broken(token, cb) {
                var newName = "randomTask_@"
                // data.removeItem()
                self.quickRequest('api/' + tS.name + '/delete/' + -1, 'get',
                    result, {id: -1, name: newName})
                function result(body) {
                    var ok = data.bodyHasError(body)
                    assert(ok,
                        'did not delete task properly broken');
                    self.checkSize(
                        'did not delete task properly', cb)
                }
            }
            work.add(self.get_delete_with_id_broken);


            self.get_delete_with_id = function get_delete_with_id(token, cb) {
                data.removeItem();
                self.quickRequest('api/' + tS.name + '/delete/' + 2, 'get', result, {id: -1})
                function result(body) {
                    self.checkSize(
                        'did not delete task properly', cb)
                }
            }
            work.add(self.get_delete_with_id);

        }


        testFauxGetRoutes();


        function testRestRoutes() {

            work.add(self.reset);
            work.add(self.getLength)
            work.add(self.checkRecordSize);


            self.testRestGet = function testRestGet(token, cb) {
                var itemId = 1;
                self.quickRequest('api/' + tS.name + '/' + itemId, 'get', result)
                function result(body) {
                    assert(body.id == itemId, 'did not get item')
                    cb();
                }
            }
            work.add(self.testRestGet);


            self.rest_create = function rest_create(token, cb) {
                // adsf.g.d
                self.quickRequest('api/' + tS.name, 'POST', result, {name: " rand task"})
                data.addItem();
                function result(body) {
                    self.checkSize('did not add task properly', cb);
                    //assert(data.checkRecordSize(), 'did not add task properly')
                    // ();
                }
            }
            work.add(self.rest_create);


            self.rest_create_upsert_fail = function rest_create(token, cb) {
                self.quickRequest('api/' + tS.name, 'POST', result,
                    {name: " rand task2__", upsertQuery: {desc: "<><>"} })
                data.addItem();
                function result(body) {
                    //self.proc('what?...')
                    console.log('what?...');
                    self.checkSize('upsert, did not add task properly', cb);
                }
            }
            work.add(self.rest_create_upsert_fail);


            self.rest_create_upsert_2 = function rest_create(token, cb) {
                self.quickRequest('api/' + tS.name, 'POST', result,
                    {name: " rand task2", upsertQuery: {name: " rand task2"} })
                //data.addItem();
                function result(body) {
                    //self.proc('what?...')
                    console.log('what?...');
                    self.checkSize('upsert, why did you add tag?', cb);
                }
            }
            work.add(self.rest_create_upsert_2);

            //work.add(self.getLength);
            //work.add(self.checkRecordSize);
            //


            self.rest_update = function rest_update(token, cb) {
                var newName = "randomTask_@"
                var idToUpdate = 1
                self.quickRequest('api/' + tS.name + '/' + idToUpdate, 'PUT', result, {id: idToUpdate, name: newName})
                function result() {

                    tasks.getId(idToUpdate, function onGot(item) {
                        assert(item.dataValues.name == newName, 'did not restfully update task properly')
                        cb();
                    })


                }
            }
            work.add(self.rest_update);


            self.rest_update_wrong = function rest_update_wrong(token, cb) {
                var newName = "randomTask_@"
                self.quickRequest('api/' + tS.name + '/' + 9999, 'get', result, {id: 0, name: newName})
                function result() {
                    assert(tasks.getId(0).name == newName, 'did not add task properly')
                    cb();
                }
            }
            //work.add(self.rest_update_wrong);

            self.get_update_wrong = function get_create(token, cb) {
                var newName = "randomTask_@"
                self.quickRequest('api/' + tS.name + '/' + "-1", 'get', result, {id: -1, name: newName})
                function result(body, resp) {
                    assert(data.isFailure(resp), 'Updaded invalid id')
                    // assert(sh.includes(body, types.errors.recordDoesNotExist),
                    //     'let me update an invalid task')
                    cb();
                }
            }
            work.add(self.get_update_wrong);

            self.rest_delete = function rest_delete(token, cb) {
                var newName = "randomTask_@"
                data.removeItem()
                var deleteId = 1;
                self.quickRequest('api/' + tS.name + '/' + deleteId, 'DELETE', result)
                function result(body) {


                    self.checkSize('did not delete task properly', cb)
                    //assert(data.checkRecordSize(),
                    //   'did not delete task properly')
                    //cb();
                }
            }
            work.add(self.rest_delete);

            self.rest_delete_with_id_broken = function get_delete_with_id_broken(token, cb) {
                var newName = "randomTask_@"
                self.quickRequest('api/' + tS.name + '/delete/' + 6, 'DELETE', result)
                function result(body) {
                    assert(data.bodyHasError(body),
                        'did not delete task properly broken');
                    //assert(data.checkrecordsize(),
                    //    'did not delete task properly broken');
                    cb();
                }
            }
            work.add(self.rest_delete_with_id_broken);


            self.rest_delete_with_id = function rest_delete_with_id(token, cb) {
                data.removeItem();
                self.quickRequest('api/' + tS.name + '/delete/' + 2, 'get', result, {id: -1})
                function result(body) {
                    self.checkSize('did not delete task properly', cb)
                }
            }
            work.add(self.rest_delete_with_id);

            self.rest_list = function rest_list(token, cb) {
                self.quickRequest('api/' + tS.name, 'get', result, {id: -1})
                function result(body) {
                    self.checkSize('did not delete task properly', cb)
                }
            }
            work.add(self.rest_list);
        }

        testRestRoutes();

        /*

         self.quickRequest('api/'+tS.name+'/update', 'get', null, {id:0, name:"randomTask_@"})
         self.quickRequest('api/'+tS.name+'/update', 'get', null, {id:-1, name:"randomTask_@"})

         self.quickRequest('api/'+tS.name+'/0', 'get', null, {id:-1, name:"randomTask_@"})
         self.quickRequest('api/'+tS.name+'/delete', 'get', null, {id:-1, name:"randomTask_@"})


         //l crud//
         self.quickRequest('api/tasks', 'get', null, {user_id:"6"})
         self.quickRequest('api/tasks', 'put', null, {name:"randomTask"})
         self.quickRequest('api/'+tS.name+'/1', 'get', null )
         self.quickRequest('api/'+tS.name+'/1', 'get', null, {id:-1, name:"randomTask_@"})
         self.quickRequest('api/'+tS.name+'/1', 'delete', null )

         self.quickRequest('api/'+tS.name+'/search', 'get', null, {id:-1, name:"randomTask", __limit:1})
         self.quickRequest('api/'+tS.name+'/search', 'get', null, {id:1, name:"randomTask", __limit:1, __exact:true})


         self.quickRequest('api/'+tS.name+'/0', 'get', null, {id:-1, name:"randomTask_@"})
         self.quickRequest('api/'+tS.name+'/delete', 'get', null, {id:-1, name:"randomTask_@"})
         */


        function testSearchRoute() {

            work.add(self.reset);
            work.add(self.getLength)
            work.add(self.checkRecordSize);

            function defineTestSearch() {


                self.testQuerySearch = function testQuerySearch(token, cb) {
                    self.quickRequest('api/' + tS.name + '/search', 'get', result,
                        {query://{name:{$like: '%hat'}
                            ["name LIKE ?", "%1%"]
                            //}
                        })
                    //{query:{name:{$like:'%1%'}}} )
                    function result(body) {
                        assert(body.length == 10, 'did not get enough results')
                        cb();
                    }
                }
                work.add(self.testQuerySearch);


                self.testQuerySearch_limit = function testQuerySearch(token, cb) {
                    //self.quickRequest('api/'+tS.name+'/search', 'get', result, {query:{name:1}, limit:10} )
                    self.quickRequest('api/' + tS.name + '/search', 'get', result,
                        {query://{name:{$like: '%hat'}
                            ["name LIKE ?", "%1"]
                            //}
                        })
                    function result(body) {
                        assert(body.length == 10, 'did not get enough results')
                        cb();
                    }
                }
                work.add(self.testQuerySearch_limit);


                self.testQuerySearch_limit_1 = function testQuerySearch(token, cb) {
                    self.quickRequest('api/' + tS.name + '/search', 'get', result,
                        {query: {name: 11}, limit: 10})
                    function result(body) {
                        assert(body.length == 1, 'did not get enough results')
                        cb();
                    }
                }
                work.add(self.testQuerySearch_limit_1);


                self.changeDescOnItem = function changeDescOnItem(token, cb) {
                    tasks.getId(11, function onGot(item) {
                        token.item = item;
                        token.newDesc = "Find Desc"


                        tasks.utils.updateItem({desc: "Find Desc"}, item, function onSaved(o) {
                            cb();
                        });


                    })
                }
                work.add(self.changeDescOnItem);

                //return

                self.testQuerySearch_limit_piecemeal = function testQuerySearch(token, cb) {
                    // tasks.getId(11).desc = 'Find Desc'
                    self.quickRequest('api/' + tS.name + '/search', 'get', result,
                        {name: "10", desc: token.newDesc})
                    function result(body) {
                        assert(body.length == 1, 'did not get enough results')
                        cb();
                    }
                }
                work.add(self.testQuerySearch_limit_piecemeal);

                self.testQuerySearch_limit_piecemealb = function testQuerySearch(token, cb) {
                    // tasks.getId(11).desc = 'Find Desc';
                    self.quickRequest('api/' + tS.name + '/search', 'get', result,
                        {name: "11", desc: tasks.getId(11).desc.slice(0, 6)})
                    function result(body) {
                        assert(body.length == 1, 'search doesn\'t work on wild cards');
                        cb();
                    }
                }
                //  work.add(self.testQuerySearch_limit_piecemealb);

                self.testQuerySearch_limit_piecemealb_findNone = function testQuerySearch(token, cb) {
                    // tasks.getId(11).desc = 'Find Desc';
                    self.quickRequest('api/' + tS.name + '/search', 'get', result,
                        {name: "11", desc: 'llll'})
                    function result(body) {
                        assert(body.length == 0, 'search return more than 0 results for bad query');
                        cb();
                    }
                }
                work.add(self.testQuerySearch_limit_piecemealb_findNone);

            }

            defineTestSearch()


            //crud

            /* setTimeout(function () {
             tasks.showId(0, 'lll');
             }, 500)*/

        }


        testSearchRoute();


        function testUserId() {
            work.add(self.reset);
            work.add(self.getLength)
            work.add(self.checkRecordSize);


            self.setupUserIdTesting = function setupUserIdTesting(token, cb) {
                tS.fxGetUserId = function getUserId(req) {
                    return 4;
                }

                cb();

            }
            work.add(self.setupUserIdTesting);

            self.testUpdateToUserId = function testUpdateToUserId(token, cb) {

                var idToUpdate = 1

                tasks.getId(idToUpdate, function onGot(item) {

                    tasks.utils.updateItem({user_id: 4}, item, cb2)

                    function cb2(o) {
                        cb();
                    }

                    //assert(item.dataValues.name == newName, 'did not restfully update task properly')
                    //cb();
                })


            }
            work.add(self.testUpdateToUserId);


            self.testRestGet = function testRestGet(token, cb) {
                var itemId = 1;
                self.quickRequest('api/' + tS.name + '/' + itemId, 'get', result)
                function result(body) {
                    assert(body.id == itemId, 'did not get item')
                    cb();
                }
            }
            work.add(self.testRestGet);

            self.testRestGet_BadUserId = function testRestGet(token, cb) {
                var itemId = 1 + 1;
                self.quickRequest('api/' + tS.name + '/' + itemId, 'get', result)
                function result(body) {
                    assert(body == '', 'return item from get you should not have')
                    cb();
                }
            }
            work.add(self.testRestGet_BadUserId);


            self.rest_create = function rest_create(token, cb) {
                // adsf.g.d
                self.quickRequest('api/' + tS.name, 'POST', result, {name: " rand task"})
                data.addItem();
                function result(body) {
                    self.checkSize('did not add task properly', cb);
                    //assert(data.checkRecordSize(), 'did not add task properly')
                    // ();

                    //list and get last id?
                }
            }
            work.add(self.rest_create);


            self.rest_update = function rest_update(token, cb) {
                var newName = "randomTask_@"
                var idToUpdate = 1
                self.quickRequest('api/' + tS.name + '/' + idToUpdate, 'PUT', result, {id: idToUpdate, name: newName})
                function result() {

                    tasks.getId(idToUpdate, function onGot(item) {
                        assert(item.dataValues.name == newName, 'did not restfully update task properly')
                        cb();
                    })


                }
            }
            work.add(self.rest_update);


            self.rest_update_wrong = function rest_update_wrong(token, cb) {
                var newName = "randomTask_@"
                var idToUpdate = 8
                self.quickRequest('api/' + tS.name + '/' + idToUpdate, 'get', result, {id: 0, name: newName})
                function result() {
                    tasks.settings.userId = null;
                    tasks.getId(idToUpdate, function onGot(item) {
                        assert(item.dataValues.name != newName, 'did not restfully update task properly')
                        cb();
                    })
                }
            }
            work.add(self.rest_update_wrong);

            self.get_update_wrong = function get_create(token, cb) {
                var newName = "randomTask_@"
                self.quickRequest('api/' + tS.name + '/' + "-1", 'get', result, {id: -1, name: newName})
                function result(body, resp) {
                    assert(data.isFailure(resp), 'Updaded invalid id')
                    // assert(sh.includes(body, types.errors.recordDoesNotExist),
                    //     'let me update an invalid task')
                    cb();
                }
            }
            work.add(self.get_update_wrong);

            self.rest_delete = function rest_delete(token, cb) {
                var newName = "randomTask_@"
                data.removeItem()
                var deleteId = 1;
                self.quickRequest('api/' + tS.name + '/' + deleteId, 'DELETE', result)
                function result(body) {


                    self.checkSize('__did not delete task properly', cb)
                    //assert(data.checkRecordSize(),
                    //   'did not delete task properly')
                    //cb();
                }
            }
            work.add(self.rest_delete);

            self.rest_delete_with_id_broken = function get_delete_with_id_broken(token, cb) {
                var newName = "randomTask_@"
                self.quickRequest('api/' + tS.name + '/delete/' + 6, 'DELETE', result)
                function result(body) {
                    assert(data.bodyHasError(body),
                        'did not delete task properly broken');
                    //assert(data.checkrecordsize(),
                    //    'did not delete task properly broken');
                    cb();
                }
            }
            work.add(self.rest_delete_with_id_broken);


            self.rest_delete_with_id = function rest_delete_with_id(token, cb) {
                //data.removeItem();
                self.quickRequest('api/' + tS.name + '/delete/' + 2, 'get', result, {id: -1})
                function result(body) {
                    self.checkSize('did not delete task properly', cb)
                }
            }
            work.add(self.rest_delete_with_id);

            self.rest_list = function rest_list(token, cb) {
                self.quickRequest('api/' + tS.name, 'get', result, {id: -1})
                function result(body) {
                    self.checkSize('did not delete task properly', cb)
                }
            }
            work.add(self.rest_list);
        }

        testUserId();
    }


    self.proc = function proc() {
        sh.sLog(arguments)
    }
}

/**
 * Recommended usage until API matures
 * @param settings
 */
EasyRemoteTester.create = function create(name, settings) {
    var t = new EasyRemoteTester();
    if ( settings == null ){
        settings = {}
    }
    if ( settings != null ) {
        if ( settings.name == null && name != null ) {
            settings.name = name;
        }
    }
    var work = t.create(settings)
    //var tH = t.createHelpers();
    return t;
}

exports.EasyRemoteTester = EasyRemoteTester;

/**
 * Use to convert test work-links into chain
 *
 * @constructor
 */
function TestQueue() {

    var p = TestQueue.prototype;
    p = this;
    var self = this;

    p.initTestQueue = function initTestQueue(settings) {
        var t = EasyRemoteTester.create('test get confi API',settings);
        self.t = t;
        return t;
    }

    /**
     * Add work to chain
     * @param callback
     */
    p.add = function add(callback) {
        self.t.add(function filesStored() {
            sh.logLine(2);
            //log name of function
            callback(function finished(){
                sh.logLine(2)
                t.cb();

            })
        })
    }

    p.proc = function debugLogger() {
        if ( self.silent == true) {
            return
        }
        sh.sLog(arguments)
    }




}


exports.TestQueue = TestQueue;

if ( module.parent == null ) {



    var t = new EasyRemoteTester();
    var work = t.create();
    var tH = t.createHelpers();
    var assert = tH.assert; var quickRequest = tH.quickRequest;

    function testChain(token, cb) {
        console.log('testChain');
        cb();
    }
    work.add(testChain);

    function testChain_addTime() {
        console.log('add time');
        times++;
        work.addNext(testChain_AddNext);
        t.cb();
    }

    var times = 0;
    function testChain_AddNext(token, cb) {
        console.log('testChain2')
        if ( times > 3) {
            t.cb();
        } else {
            t.addNext(t.wait(1,false),0);
            t.addNext(testChain_addTime,1);
            t.cb();
        }
    }
    work.add(testChain_AddNext);


    function testYahoo(token, cb) {
        console.log('test yahoo')
        cb()
        t.quickRequest('http://www.yahoo.com',  null, function result(d){
            function result(body) {
                //var ok = tH.bodyHasError(body)
                assert(body!=null,
                    'did not delete task properly broken');
                // self.checkSize(
                //    'did not delete task properly', cb)
                cb()
            }
        })
    }
    work.add(testYahoo)


    //testRestHelper();
    //setTimeout(testRestHelper, 5000); //wait for db to create records

}

