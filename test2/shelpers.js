/**
 * Helpers methods
 */

(function () {

    var isNode = true

    if (typeof exports === 'undefined' || exports.isNode == false) {
        isNode = false
    }

    if ( isNode ) {
        var path = require('path')
    } else {
        require = function () {
            return {};
        }
    }

    function trim1(str) {
        return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    }


    var helper = {}
    var sh = helper;

    var str = {}
    sh.str = str;
    sh.fs = {};
    sh.errors = {}
    str.createName = function createName(count ) {
        var strs = "Sudie, Carroll, Basil, Mayola, Regina, Horacio, Tiera, Randolph, Andres, Tammi, Cathey, Serafina, Grace, Ellan, Micha, Martina, Loren, Barton, Kirk, Regan"
        strs = sh.splitStrIntoArray(strs);
        var val = '';
        for ( var i =0; i < count; i++) {
            var name = sh.array.getRandomItem(strs)
            val +=   name
            if ( count != i -1 ) {
                val += ' '
            }
        }
        return val
    }

    /**
     * Example usage:

     pad(10, 4);      // 0010
     pad(9, 4);       // 0009
     pad(123, 4);     // 0123

     pad(10, 4, '-'); // --10
     * @param n
     * @param width
     * @param z
     * @returns {*}
     */
    str.pad = function pad(n, width, z) {
        z = z || '0';
        n = n + '';
        return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
    }

    /*
     String.prototype.splice = function( idx, rem, s ) {
     return (this.slice(0,idx) + s + this.slice(idx + Math.abs(rem)));
     };
     */
    function splice(str, idx, rem, s) {
        return (str.slice(0, idx) + s + str.slice(idx + Math.abs(rem)));
    };

    String.prototype.replaceBetween = function (start, end, what) {
        return this.substring(0, start) + what + this.substring(end);
    };

    function includes(url, subStr) {
        return url.indexOf(subStr) != -1
    }

    function includes(url, subStr, lowerCase) {

        if (url == null) {
            return false
        }
        if ( lowerCase == true) {
            if ( sh.isArray(url )){
                var urlR = [];
                sh.each(url, function lowerCaseAll(k,v){
                    urlR.push(v.toLowerCase())
                })
                url = urlR;
            } else {
                url = url.toString();
                url = url.toLowerCase()
            }
            if (subStr != null) {
                subStr = subStr.toString().toLowerCase()
            }
        }
        return url.indexOf(subStr) != -1
    }

    function removeFromArray(array, value, clone ) {
        var index = array.indexOf(value)
        if ( index == 0 )
            return array;

        array.splice(index, 1);
        return array;
    }

    function endsWith (str, suffix) {

        return str.indexOf(suffix, str.length - suffix.length) !== -1;
    }

    function startsWith (str, subStr) {
        if (str == null) {
            return;
        }
        return str.indexOf(subStr) == 0 ;
    }

    /**
     * Readible verion of replace
     * @param url
     * @param subStr
     * @returns {boolean}
     */
    function replace(str, find, replaceWith) {
        function escapeRegExp(string) {
            return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
        }
        // So in order to make the replaceAll function above safer, it could be modified to the following if you also include escapeRegExp:

        // function replaceAll(string, find, replace) {
        return str.replace(new RegExp(escapeRegExp(find), 'g'), replaceWith);
        //  }

        // String.prototype.replaceAll = function (find, replace) {
        //var str = this;
        find = new RegExp(find.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'g')
        return str.replace( find
            , replaceWith);

        // return str.replace(new RegExp(subStr, 'g'), replaceWith);
        // };
        // str = str.replace(subStr, replaceWith)
        // return str

    }

    /**
     * String.prototype.insert = function (index, string) {
  if (index > 0)
    return this.substring(0, index) + string + this.substring(index, this.length);
  else
    return string + this;
};
     * @param str
     * @param subStr
     * @returns {boolean}
     */
    function insert(str, index, addIn) {
        if (index > 0)
            return str.substring(0, index) + addIn + str.substring(index, str.length);
        else
            return string + str;
    }

    /**
     * Case insnsitive
     * @param url
     * @param subStr
     * @returns {*}
     */
    function includes2(url, subStr) {
        if (url == null) {
            return false
        }
        return includes(url.toLowerCase(), subStr.toLowerCase())
    }


    function remove_win_newlines(txt) {
        txt = txt.replace(/\r?\n|\r/g, '\n')
        return txt
    }

    function stripBadFiles(file, replaceWith) {
        //var file = file.replace(/\//g, '_')
        //file = file.replace(/\\/g, '_')
        var replaceWith = sh.defaultValue(replaceWith, '')
        file = file.replace(/[^\w\s]/gi, '') /*\.*/
        return file
    }
    function replaceBackslash(str) {
        var replaced = str.replace(/\\/gi, "/");
        return replaced
    }




    function stripSpecialChars(file) {
        file = file.replace(/[^\w]/gi, '_')
        return file
    }

    /**
     * This script can run a series of tests
     * @param items
     * @constructor
     */

    function GoThroughEach(items) {
        var async = require('async')
        var self = this;
        var p = GoThroughEach.prototype;

        p.setIndex = function setIndex(newIndex) {
            self.currentIndex = newIndex;
        }


        self.items = items

        self.items = items


        self.config = {};

        self.go = function go(arr, fxItemCallback, fxComplete, timeDelay_, autoStart) {
            self.complete = false;
            if (arr instanceof Array) {
                self.items = arr;
                self.fxComplete = fxComplete
                self.fxItemCallback = fxItemCallback;
            } else {
                var config = arr; //user sent in obj
                self.items = config.items;
                if (config.fxDone == null) {
                    throw 'supply fxDone'
                }
                self.fxComplete = config.fxDone;
                self.fxItemCallback = config.fxItem;
                ;
                self.config = config;
                autoStart = self.autoStart;///// = config;
            }
            self.currentIndex = -1
            self.timeDelay = timeDelay_
            if (self.timeDelay > 0) {
                /*if ( timer != null )
                 timer.removeEventListener(TimerEvent.TIMER, this.nextTimerComplete )
                 timer = new Timer(timeDelay,1 )
                 timer.addEventListener(TimerEvent.TIMER, this.nextTimerComplete )*/
            }
            if (autoStart != false) {
                // self.nextItem(null, true);
                self.start()
            }


        }

        self.start = function start() {
            var limit = sh.defaultValue(self.config.concurrency, 1)
            async.forEachLimit(self.items, limit, function (item, callback) {
                //db.delete('messages', messageId, callback);
                //fx(callbackPlay)
                self.fxItemCallback(item, callback)
            }, function (err) {
                if (err) console.error(err)
                self.fxComplete();

            });
        }

        //remove this method .... use async callback only
        self.XnextItem = function nextItem(e, timed, internallySet) {
            /*if ( self.currentIndex != -1 && ( self.currentIndex != self.items.length ) ||  PauseFirstAndLast )
             {
             if ( self.items.length != 0 )
             {
             if ( timeDelay != 0 && timed == false  )
             {
             this.timer.reset();
             this.timer.start();
             return;
             }
             }
             }*/
            if (self.config.concurrent != null && internallySet != true) {
                self.handleConcurrency()
                return;
            }
            if (this.complete == true)
                return;
            self.currentIndex++
            if (self.currentIndex >= self.items.length) {
                self.end();
                return;
            }
            var currentItem = self.items[self.currentIndex]
            self.fxItemCallback(currentItem, self.nextItem);
            //self.execution.waitingFor.add()
        }


        self.handleConcurrency = function handleConcurrency() {
            //how many ouconing requests

        }

        /*self.start = function start() {
         self.currentIndex=-1;
         self.running = false;
         self.complete = false;
         self.nextItem()
         }*/
        self.next = function next() {
            self.nextItem()
        }

        self.end = function end(callEndFxCallback) {
            //if ( this.timer != null ) 	this.timer.stop() ;
            self.complete = true;  //call complete first so we do not interfere wtih starting again ...
            //self.items = [] ; //

            var fxFinal = self.fxComplete
            //self.fxComplete = null

            //call final fx last to prevent anything that has restarted the loop and reused
            //this instance from losign variables ...
            if (callEndFxCallback != false) {
                if (fxFinal != null)
                    fxFinal();
            }
        }

        self.last = function last() {
            index = self.items.length - 1
            return self.items[index];
        }

        self.reset = function reset(sendEndFx) {
            self.currentIndex = 0;
            self.running = false;
            self.complete = false;
            if (sendEndFx == true) {
                sh.callIfDefined(fxComplete)
            }
        }


    }

    function testGoThroughEach() {
        function fxItem(item, callback) {
            console.log(item, sh.getTime())
            sh.waitXSecs(1, callback)
            //n.next()
        }

        function fxDone() {
            console.log('done')
        }

        var arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        var n = new GoThroughEach(arr)
        // n.go(arr,fxItem, fxDone)
        n.go({items: arr,
                fxItem: fxItem,
                fxDone: fxDone,
                concurrency: 2

            }

        )

    }


    function dictMakeByName(arr, prop) {
        prop = sh.defaultValue(prop, 'prop')
        var dict ={}
        sh.each(arr, function iter(i,item){
            var key = item[prop]
            dict[key] = item;
        })

        return dict
    }

    function DictArray() {
        var self = this;
        var p = DictArray.prototype;


        self.add = function add(key, val) {
            var arr = this[key]
            if (arr == null) {
                arr = []
            }
            arr.push(val)
            this[key] = arr;
        }


    }

    function testDictArray() {
        var arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        var n = new DictArray()
        n.add('aa', 1)
        n.add('aa', 2)
        n.add('aa', 56)
        n.add('cc', 1)
        if (n.aa.length != 3) throw 'bad'
    }

    eachPropConst = {}
    eachPropConst.any = '__any__'
    function eachProp(dict, str, fxCallback, fxCallbackAll ) {
        var props = str.split('.')
        var lastLayer =  dict ; //start off with dict
        var currentLayer = []
        var allLayers = {}
        var layerIndex = 1;
        sh.each(props, function onProps(i, prop ) {
            currentLayer = []
            sh.each(lastLayer, function s (i, o){
                var addItem = o;
                if ( prop == eachPropConst.any) {
                    //lastLayer.push(o)
                } else {
                    addItem=(o[prop])
                }

                if ( addItem == null ) {
                    return;
                }
                currentLayer.push(addItem)
                sh.callIfDefined(fxCallbackAll, addItem)
            })
            allLayers[layerIndex]=lastLayer;
            layerIndex++
            lastLayer = currentLayer;
        })

        if (fxCallback != null ) {
            sh.each(lastLayer, function onVal(i, val) {
                fxCallback(val);
            })
        }

        return allLayers;
    }

    function testEachProp() {

        var obj = {}
        var layer2 = {}
        layer2['aaa']=8
        layer2['bbb']=9
        obj['asdf'] = layer2
        obj['asdf2'] = layer2

        eachProp(obj, '__any__.bbb', function processNum(o){
            console.log('s', o)
        });


        var obj = {}
        var layer2 = {}
        var layer3 = {}

        obj['asdf'] = layer2
        obj['asdf2'] = layer2
        layer2['aaa']=layer3
        layer2['bbb']=layer3
        layer3['aaa']=8
        layer3['bbb']=9
        eachProp(obj, '__any__.bbb.aaa', function processNum(o){
            console.log('s2', o)
        });
        eachProp(obj, '__any__.bbbd.aaa', function processNum(o){
            throw 'how did this happen?' // can't call this ...
        });
        eachProp(obj, '__any__.bbb', function processNum(o){
            console.log('s3', o)
        });
    }


    function callIfDefined(fx) {
        var args = convertArgumentsToArray(arguments)
        args = args.slice(1, args.length)

        if (fx == undefined)
            return args[0];


        // console.debug('args', tojson(args))
        return fx.apply(null, args)
        //return;
    }



    function forwardArgsTo(fx, args) {
        if (fx == undefined)
            return;
        if ( args != null && args.length == null ) {
            var args = convertArgumentsToArray(args)
        }
        return fx.apply(null, args)
    }
    sh.forwardArgsTo = forwardArgsTo;



    function convertArgumentsToArray(_arguments) {
        var args = Array.prototype.slice.call(_arguments, 0);
        return args
    }

    /**
     * Intelligent split string into parts
     * @param _arguments
     */
    function splitStrIntoArray(str, splitOnChar, allowNull) {
        allowNull = defaultValue(allowNull, true)
        splitOnChar = defaultValue(splitOnChar, null)
        if (str == null) {
            if (allowNull) {
                return []
            } else {
                throw new Error('str not valid', str)
            }
        }
        var output = null
        //ignore if split
        if (str instanceof Array) {
            return str;
        }
        //allow user to seopcify char to split
        if (splitOnChar != null) {
            if (str.indexOf(splitOnChar) != -1) {
                output = str.split(splitOnChar)
            } else {
                output = []
            }
        }
        else {
            //otherwsie fallback on common options
            if (str.indexOf(', ') != -1) {
                output = str.split(', ')
            } else if (str.indexOf(',') != -1) {
                output = str.split(',')
            } else if (str.indexOf(' ') != -1) {
                output = str.split(' ')
            } else {
                output = [str] //just one
            }
        }
        return output
    }

    function convertArrayPropsToObject(arrayOfProps) {
        var output = {}
        if ( arrayOfProps == null ) { arrayOfProps = []}
        sh.each(arrayOfProps, function (k,v) {
            output[v]="";
        })
        return output
    }

    sh.convertArrayPropsToObject = convertArrayPropsToObject;

    function removeSubString(substring, url) {
        if (url.slice(0, substring.length) === substring)
            url = url.substr(substring.length);
        return url;
    }


    function q(text, escapeQuote) {
        if (escapeQuote == true) {
            return "\'" + text + "\'"
        }
        return "'" + text + "'"
    }

    function removeFromBegAndEndOfStr(text, removeStr) {
        if ( sh.startsWith(text, removeStr) &&
            sh.endsWith(text, removeStr)) {

            text = text.replace(removeStr, '')
            text = text.slice(0,text.length-removeStr.length)
        }
//    if ( sh.endsWith(text, removeStr)) {
//        text = text.slice(0,text.length-removeStr.length)
//    }
        return text;
    }

    function unquote(text) {
        return removeFromBegAndEndOfStr(text, '"')
    }


    function qq(text) {
        return "\"" + text + "\""
    }
    function paren(text) {
        return "(" + text + ")"
    }

    function bracket(text) {
        return "[" + text + "]"
    }

    function join() {
        var args = sh.convertArgumentsToArray(arguments)

        return args.join(' ');
    }
    sh.str.join = join;

    var br = '<br />'
    var brn = '<br />\n'
    var newline = '\n'
    function strip(text) {
        return text.replace(/^\s+|\s+$/g, '');
    }
//console.log('d')


    function log() {
        var args = convertArgumentsToArray(arguments)
        var fx = console.log;
        fx.apply(console, args)
        //console.log()
    }
    /**
     * Labeled log line
     */
    function lLog(label, logArguments) {
        var args = convertArgumentsToArray(logArguments)
        args.unshift(label)
        var fx = console.log;
        fx.apply(null, args)
        //console.log()
    }


    /**
     * Simple log, show prototype (class) and method name
     */
    function sLog() {
        var args = convertArgumentsToArray(arguments[0])



        var stackTrace = sh.errors.getStackTrace()
        var calls = stackTrace.split("\n");
        var trueCall = calls[4]
        var prototypeName = calls[5]

        function getS(s) {
            s = s.split("at ")[1];
            return s
        }

        trueCall = getS(trueCall);
        prototypeName = getS(prototypeName);

        function stripPrototype(s) {
            //FlexMXMLtoStyleExplorerConvertor.convertFile (C:\Users\user1\Dropbox\projects\crypto\proxy\css\convertMXMLSkinToExplorer.js:40:44)
            s = s.split(".")[0];
            return s
        }

        //LineProcHelper.getLineWith (C:\Users\user1\Dropbox\projects\crypto\proxy\css\convertMXMLSkinToExplorer.js:29:30)
        function getLinePrototype(s) {
            var methodCall = s.split(" (")[0] //LineProcHelper.getLineWith
            var prototype = methodCall.split(".")[0];
            var method = methodCall.split(".")[1];
            var line = "(" + s.split(" (")[1]; //(c:\)
            return {prototype: prototype, method: method, line: line}
        }

        var lists = getLinePrototype(trueCall)
        var prototype = lists.prototype;
        var method = lists.method;
        var line = lists.line;

        prototypeName = stripPrototype(prototypeName);
        //console.log(stackTrace + 'llllllllll')
        /*console.log(trueCall)
         console.log(prototypeName)*/

        //console.log(stackTrace)
        // args.unshift(label)
        args.unshift(lists.method);
        args.unshift(lists.prototype);
        args.unshift('>>>*> ');
        args.push(lists.line);
        var str = "\t" + args.join(" ") + "\n"
        str = args.join(" ")
        console.log(str)
        //var fx = console.log;
        //fx.apply(null, args)
        //console.log()
        return str;
    }

    sh.errors.jumpError = function jumpError(msg, lines, ifFalse , postAdd, throwError) {
        if (ifFalse != null) {
            if (ifFalse != false) {
                return;
            }

        }

        //user may not secify lines, but condition


        var stackTrace = sh.errors.getStackTrace()

        var calls = stackTrace.split("\n");

        //console.log(calls.join("\n"))


        lines = sh.dv(lines, 3);
        if (lines < 0) {
            lines *= -1
        }


        var old = calls.slice(1 + 2, lines)
        var newCalls = calls.slice(lines);

        newCalls.unshift('Error: ' + msg);


        if (postAdd != null)
            newCalls = newCalls.concat('', 'from', postAdd)

        newCalls = newCalls.concat('', 'via', old)


        var e = new Error(msg)
        e.stack = newCalls.join("\n")
        // e.stack = 'ooo'
        //e.message = 'dfsdf'
        if (throwError != false) {

            throw(e);
        }
        else {
            console.error(e.stack)
        }



        return true;

    }

    sh.errors.storeError = function jumpError( lines ) {

        var stackTrace = sh.errors.getStackTrace()

        var calls = stackTrace.split("\n");

        //console.log(calls.join("\n"))


        lines = sh.dv(lines, 3);
        if ( lines < 0 ) { lines *= -1 }


        var newCalls = calls.slice(lines);

        //newCalls.unshift('Error: ' + msg);

        //var e =new Error(msg)
        //e.stack = newCalls.join("\n")
        // e.stack = 'ooo'
        //e.message = 'dfsdf'
        //throw(e);
        return newCalls;

    }




    function getStackTrace() {
        var err = new Error();

        return err.stack;
    }
    sh.errors.getStackTrace = getStackTrace



    String.prototype.empty = function () {
        return (!this || 0 === this.length);
    }

    String.prototype.strip = function () {
        return this.replace(/^\s+|\s+$/g, '');
    }

    function getNodeArguments(str) {
        /**
         * Use optimistm
         * @type {Array}
         */
        var args = process.argv.splice(2);
        return args;
    }

    sh.progArg = function getProcessArgumentAtIndex(index) {
        var args = sh.getNodeArguments()
        return args[index];
    }


    function makeRelative(url) {
        //http://stackoverflow.com/questions/10687099/how-to-test-if-a-url-string-is-absolute-or-relative
        var urlRemoved = url;
        if (url.indexOf('://') != -1) {
            urlRemoved = url.replace(/^(?:\/\/|[^\/]+)*\//, "")
            urlRemoved = '/' + urlRemoved
        }
        return urlRemoved
    }



    function removeProtocol(url) {
        if (url.indexOf(sh.http) == 0) {
            url = url.replace(sh.http, '')
        }
        if (url.indexOf(sh.https) == 0) {
            url = url.replace(sh.https, '')
        }


        return url
    }

    function isAbsUrl(url) {
        if (url.indexOf(sh.http) == 0) {
            return true
        }
        if (url.indexOf(sh.https) == 0) {
            return true
        }
        return false
    }


    function getSubDomain(url) {
        //var url = sh.urls.removeProtocol(url)
        var add = null
        if (url.indexOf(sh.http) == 0) {
            url = url.replace(sh.http, '')
            add = sh.http;
        }
        if (url.indexOf(sh.https) == 0) {
            url = url.replace(sh.https, '')
            add = sh.https;
        }
        var domain = url;
        if (sh.includes(url, '/')) {
            domain = url.split('/')[0] + '/'
        } else {
            domain = url;
        }
        if (add != null) {
            domain = add + domain
        }
        return domain
    }
    function breakStringIntoLinesSafe(str) {
        var split = [];
        str = str.replace(/(\r\n|\n|\r)/gm, "\n");
        split = str.split("\n")
        return split;
    }

    function getLinesFromFile(file, throwErrorIfFileFound) {
        var fs = require("fs")
        if ( throwErrorIfFileFound == false ) {
            console.log('sh.getLinesFromFile', 'file not found')
            if ( sh.fileExists(file) == false  ){
                return [];
            }
        }
        var contents = fs.readFileSync(file).toString()

        contents = contents.replace(/(\r\n|\n|\r)/gm, "\n");
        var lines = breakStringIntoLinesSafe(contents);
        return lines;
    }

    function capitalize(string)
    {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }


    function readFile(file, nullValue, binary ) {
        if ( nullValue != null && sh.fileExists(file)==false) {
            if ( nullValue == true ) { //legacy, remove as soon as possible
                return ''
            }
            return nullValue
        }
        var fs = require("fs")
        var encoding =  'utf-8';
        if ( binary == true  ) { encoding = 'binary'};
        try {
            var contents = fs.readFileSync(file, encoding)//.toString()
        } catch ( e ) {
            console.log('cannot find', __dirname , file, require('path').resolve(__dirname+'/'+file))
            throw e
        }
        return contents;
    }


    function copyFile2(from, to, async, fxCallback, binary) {
        if ( async == true ) {


        }
        var contents = sh.readFile(from, null, binary);
        sh.writeFile(to, contents,false,binary);
    }


    /**
     * Expects newline to be used as seperator
     * returns array with each line as a speerate index
     * @param file
     */
    function readFileLinesAsArray(file, content) {
        if (content == null) {
            var contents = sh.readFile(file);
        } else {
            var contents = content //allow user to specify contnet, nto file
        }
        contents = sh.remove_win_newlines(contents)
        var testList = contents.split("\n")
        return testList;
    }

    /**
     * Combines all arguments into lines and concat new newline
     * @returns {string|*}
     */
    function combineLines() {
        var lines = sh.convertArgumentsToArray(arguments)
        //remove null lines
        return lines.join(sh.n)
    }


    /**
     * Turns comma seperated string into array
     * @param val
     * @returns {Array}
     */
    function convertStringToArray( val ) {
        var nullValIsArray = true
        if ( val == null ) {
            if ( nullValIsArray ) {
                return []
            }
        }
        var split = val.split(',')
        var split = split.map(function(val){
            return sh.strip(val)
        });
        return split;
    }

    /**
     * Creates a path from arugments
     * @returns {string|*}
     */
    function makePath ( ) {
        var args = sh.convertArgumentsToArray(arguments)
        return args.join('/')
    }

    function getFilesInDirectory(dir, recurse, sortByTime, showNames,
                                 filter, filterIncludes, appendDirOnFileNames ) {
        var fs = require("fs")
        var files = fs.readdirSync(dir);
        var filesWithDir = [];
        for (var i in files) {
            try {
                if (!files.hasOwnProperty(i)) continue;
                var name = dir + '/' + files[i];
                //filesWithDir.push(name);
                if (fs.statSync(name).isDirectory()) {
                    if (recurse == true)
                        getFiles(name); //will not work
                } else {
                    if ( showNames ) {
                        console.log(name)
                    }
                }
            } catch (e) {
            }
        }



        if ( filter != null ) {
            files =  files.filter( filter);
        }

        if ( filterIncludes != null ) {
            var matches = []
            sh.each(files, function processEach(i,fileName){
                if ( sh.includes(fileName, filterIncludes)){
                    matches.push(fileName);
                }
            })
            files =  matches;
        }

        if ( sortByTime ) {
            var y = files.sort(function (a, b) {
                return fs.statSync(dir + a).mtime.getTime() -
                    fs.statSync(dir + b).mtime.getTime();
            });
        }


        var sep = '/';
        if ( sh.endsWith(dir, '/')) {
            sep = ''
        }
        if ( appendDirOnFileNames == true  ) {
            files = files.map(function (fileName) {
                return dir+sep+fileName});

        }


        return files;
    }

    sh.fs.getFilesInDirectory = getFilesInDirectory;
//simplifies invokation
    sh.fs.getFilesInDirectory2 = function getFilesIndirectory_Path(dir) {
        return sh.fs.getFilesInDirectory(dir, false, false, false, null, null, true);
        recurse, sortByTime, showNames,
            filter, filterIncludes, appendDirOnFileNames
    };

    sh.fs.writeJSONFile = function writeJSONFile(file, json) {
        if ( file == null ) { return; }

        sh.writeFile(file, sh.toJSONString(json));
    }

    sh.fs.readJSONFile = function readJSONFile(file, defaultVal, ifSwallowParsingErrors, okIfNotFound ) {
        if ( defaultVal != undefined ) {
            defaultVal = sh.dv(defaultVal, {});
        }
        ifSwallowParsingErrors = sh.dv(ifSwallowParsingErrors, false);
        okIfNotFound = sh.dv(okIfNotFound, false);

        if ( file == null ) { if ( okIfNotFound == true ) {
            return defaultVal;
        }};
        if ( sh.fileExists(file)==false) {
            if ( okIfNotFound == true ) {
                return defaultVal;
            }
        };
        try {
            var json = JSON.parse(sh.readFile(file))
        } catch (e ) {
            //never ignore parsing errors, it is too difficult to debug
            if ( ifSwallowParsingErrors != true ) {
                throw new Error('cannot parse config file ' + file)
            }
            console.log('parsing error with loading json', 'readJSONFile', file);
            json = defaultVal
        }
        return json;
    }


    /**
     * Same as readJSONFile, but will not throw errors if file not found
     * Usage: for config files
     * @param file
     * @param defaultVal
     * @param ifSwallowErrors
     * @returns {*}
     */
    sh.fs.readJSONFileOpt = function readJSONFileOpt(file, defaultVal, ifSwallowErrors ) {
        ifSwallowErrors = sh.dv(ifSwallowErrors, false); //throw parsing error
        defaultVal = sh.dv(defaultVal, {});
        var json = sh.fs.readJSONFile(file, defaultVal, ifSwallowErrors, true)
        return json;
    }

    sh.fs.mergeJSONFileIntoObject = function mergeJSONFileIntoObject(file, options) {
        var fromObject  = JSON.parse(sh.readFile(file));
        sh.mergeObjects(fromObject, options, true )
        sh.each(fromObject, function copyProp(i,v) {
            sh.mergeObjects(v, options[i], true);
        })
        return options;
    }

//Write temp file
    sh.fs.writeTemp = function writeTemp(config) {
        var contents = config.contents;
        if ( config.json ) {
            contents = sh.toJSONString(config.json)
        }
        var fileName = config.fileName;
        if(fileName==null) {fileName = getTimeStamp()

            if ( config.json ) {
                fileName += '.json';
            }
        }
        var dirTemp = 'temp/'
        var dir = ''
        if ( config.addTemp == false )
            dirTemp = '';
        if ( config.dir) {
            dir = config.dir+'/'+dirTemp
            fileName = dir +fileName;
        };
        if ( dir != '' )
            sh.makePathIfDoesNotExist(dir);
        writeFile(fileName, contents)

        return fileName;
    }



    sh.writeJSONFile = sh.fs.writeJSONFile;
    sh.readJSONFile = sh.fs.readJSONFile;
    sh.mergeJSONFileIntoObject = sh.fs.mergeJSONFileIntoObject;

    sh.fs.resolve = function resolvePath(pathToResolve) {
        var path = require('path')
        return path.resolve(pathToResolve);
    }

    function defineFS() {

        var fs = require('fs')
        sh.fs.parseBytesOutput = function parseSize_HumanReadable_CmdLineOutput_To_Gigabytes (cmdInput) {
            var cmdOutput = -1;

            if ( sh.includes(cmdInput, "\t")) {
                cmdInput = cmdInput.split("\t")[0];
            };
            if ( sh.includes(cmdInput, "\n")) { //remove trailing \n
                cmdInput = cmdInput.split("\n")[0];
            };

            var parsedVal = cmdInput.slice(0, -1);
            parsedVal = parseInt(parsedVal);

            if (sh.endsWith(cmdInput, 'K')) {
                cmdOutput = cmdInput.slice(0, -1)
                cmdOutput = parseInt(cmdOutput);
                cmdOutput = cmdOutput * 1000;
            }
            else if ( sh.endsWith(cmdInput, 'M')) {
                cmdOutput = cmdInput.slice(0, -1)
                cmdOutput = parseInt(cmdOutput);
                cmdOutput = cmdOutput / 1000;
            }
            else if ( sh.endsWith(cmdInput, 'G')) {
                cmdOutput = parsedVal;
            }
            else if (sh.endsWith(cmdInput, 'T')) {
                cmdOutput = cmdInput.slice(0, -1);
                cmdOutput = parseInt(cmdOutput);
                cmdOutput = cmdOutput * 1000;
            }
            else { //assume bytes
                cmdOutput = parsedVal/ 1000/1000/1000; //kilo, mega, giga
            }
            //cmdOutput = parseInt(cmdOutput);
            return cmdOutput;
        };


        sh.fs.getFileSizeInBytes =  function getFilesizeInBytes(filename) {
            var stats = fs.statSync(filename)
            var fileSizeInBytes = stats["size"]
            return fileSizeInBytes
        };

        sh.fs.getSizeOfDir =  function getSizeOfDir(filename) {
            var stats = fs.statSync(filename)
            var fileSizeInBytes = stats["size"]
            return fileSizeInBytes
        };

        sh.fs.getSizeOfDir2 = function getSizeOfDir(dirToCheck, fxDone) {
            var child_process = require('child_process');
            var cmd = "du -hsb "+dirToCheck;
            child_process.exec(cmd, function (err, stdout, stderr) {
                var output = stdout;
                //asdf.g
                //return
                function parseResultOfHumanReadable(cmdOutput) {
                    var output = cmdOutput;
                    var result = 0;
                    var result = sh.fs.parseBytesOutput(cmdOutput);

                    console.log('getSizeOfDir',cmd, result);
                    return result;
                };

                var result = parseResultOfHumanReadable(output)
                fxDone(result);
            });
        };

        sh.fs.isDirBiggerThanXGBs = function isDirBiggerThanXGBs(dir, gb, fxCallback) {
            var size = sh.fs.getSizeOfDir(dir)
            var sizeO= size/ 1000 / 1000 / 1000
            console.log('size', size, sizeO)
            sh.fs.getSizeOfDir2(dir, function gotSize(size) {

                var sizeO= size/ 1000 / 1000 / 1000
                console.log('size', size, sizeO)

                if ( size > gb ) {
                    fxCallback(true)
                } else  {
                    fxCallback(false)
                }
            })


        }

        sh.fs.checkSpace = function checkSpace(dirToCheck, fxDone, min_gb) {
            var child_process = require('child_process');
            var gb = "df -h /tmp | tail -1 | tr -s ' ' | cut -d' ' -f4"
            var cmdToCheckSpace = "df -h "+dirToCheck+" | tail -1 | tr -s ' ' | cut -d' ' -f4"
            //df -k /tmp | tail -1 | tr -s ' ' | cut -d' ' -f5
            child_process.exec(cmdToCheckSpace, function (err, stdout, stderr) {
                var output = stdout;
                var freeGb = sh.fs.parseBytesOutput(stdout);
                console.log('cmdToCheckSpace',cmdToCheckSpace, freeGb);
                if (min_gb != null &&
                    min_gb > freeGb) {
                    //asdf.g
                    console.log('sh.fs', 'not enough free space available', min_gb ,'>',
                        freeGb, output, sh.qq(dirToCheck));
                    fxDone(false, freeGb);
                    return;
                };

                fxDone(true, freeGb);
            });
        };

        sh.fs.findPathWithFreeSpace =  function findPathWithFreeSpace(dirs, minSpace, fxResult) {
            var stats = fs.statSync(filename)
            var fileSizeInBytes = stats["size"]
            //return fileSizeInBytes
            sh.async(dirs,
                function checkDirforSpace(dirToCheck, fxIterationdone) {



                    var dirToCheck2 = self.utils.fixInitPathIfRelative(dirToCheck);
                    var dirExisting = dirToCheck2 + '/' + searchForDir;

                    /* if ( self.settings.testCopyDirs &&
                     self.settings.testCopyDirs_createRandomFile != false) {
                     var fileTestFile = dirExisting + '/newFile'+Math.random()+'.txt'
                     console.log('touc', dirExisting)
                     //creates a file in location, if doesn't existing
                     sh.fs.touch = function touchFile(file, contents) {
                     var base = sh.getPath(file);
                     sh.fs.mkdirp(base);
                     sh.writeFile(file, contents);
                     }

                     if ( Math.random() > 0.6 ) { //40% of iterations, write file
                     sh.fs.touch(fileTestFile, 'test');
                     //console.error(fileTestFile)
                     // asdf.g
                     }

                     //  asdf.g
                     }*/


                    //store the status
                    var dirStatus = {};
                    dirsStatus[dirExisting] = dirStatus;
                    dirStatus.dir = dirExisting;

                    checkDirforSpace(dirToCheck2);

                    //check free space & get size of directory
                    function checkDirforSpace(dirToCheck) {
                        self.checkSpace(dirToCheck, function onCheckedDir(ok, freeSpace) {
                            //dictDirOk[dirToCheck] = ok;
                            /*if ( dirsOK ) {
                             dirsOk.push(dirToCheck);
                             } else {
                             dirsFullsNotOk.push(dirToCheck);
                             };*/
                            dirStatus.freeSpace = freeSpace;
                            dirStatus.empty = ! ok;
                            dirStatus.hasFreeSpace = ok;
                            dirStatus.dir = dirToCheck;
                            //get size of directory
                            self.getSizeOfDir(dirToCheck, function onGotSize(sizeOfDir) {
                                dirStatus.dirSize = sizeOfDir;
                                checkIfDirExists();
                            }, true);

                        })
                    }
                    //check if exists
                    function checkIfDirExists() {
                        var dirExists = sh.fileExists(dirExisting);
                        dirStatus.dirExists = dirExists;

                        if ( self.settings.testPreExisting && asdf.g ){
                            //create drive
                            //add file iwth ame ..
                        }

                        // if ( dirExists ) {
                        //dirPreExisting=dirExisting;
                        // dataHelper.dirsPreExisting.push(dirPreExisting);
                        // };

                        fxIterationdone();
                    }

                } ,
                function allDirsChecked() {
                    //have status of all dirs
                    fxResult(result)
                }
            );


        };
    };
    defineFS();

    sh.fs.limitSizeOfDirToXFiles = function limitSizeOfDirToXFiles(dir, maxFiles) {
        var files= sh.getFilesInDirectory(dir, false, true)

        maxFiles = sh.dv(maxFiles)
        //sort alphabetically: Modfied time cannot be trusted, as uploads may come in any order ...
        //must rely on timestamp in filename
        files = files.sort(function (a, b) {
            return a.toLowerCase().localeCompare(b.toLowerCase());
        });

        //self.proc('files', files);
        // self.proc('files.max', self.settings.max_files_per_channel,files.length)

        if ( files.length > maxFiles ) {
            //get the last (x) files in the list
            var indexOfFirstFileToKeep = files.length - (maxFiles-1);
            //Delete everything upto indexOfFirstFileToKeep
            var deleteFiles = files.slice(0,indexOfFirstFileToKeep);
            //Delete everything after indexOfFirstFilesToKeep
            //var deleteFiles = files.slice(indexOfFirstFileToKeep);
            console.log('deleting files before index', indexOfFirstFileToKeep)
            console.log('deleting list:', deleteFiles.length, deleteFiles)
            //asdf.g
            sh.each(deleteFiles, function deleteFile(i,fileToDelete) {
                sh.deleteFile(dir+fileToDelete, true, true);
                console.log('deleting', fileToDelete)
            })

        };
    }


    sh.sortBy = function sortBy(records, field, isData ) {
        //if ( sortByTime ) {
        var moment = require('moment')
        records.sort(function (a, b) {
            a = a[field];
            if ( sh.isString(a)  ) {
                a = new Date(a)
            }
            b = b[field];
            if ( sh.isString(b)  ) {
                b = new Date(b);
            }
            return    b - a;
        });
        // }

        return records;
    }

    function clearDir(dirPath, removeDir) {
        //use node-fs
        var fs = require("fs")
        //var files = fs.readdirSync(dir);

        try { var files = fs.readdirSync(dirPath); }
        catch(e) { return; }
        if (files.length > 0)
            for (var i = 0; i < files.length; i++) {
                var filePath = dirPath + '/' + files[i];
                if (fs.statSync(filePath).isFile())
                    fs.unlinkSync(filePath);
                else
                    clearDir(filePath, true);
            }
        if ( removeDir )
            fs.rmdirSync(dirPath);


    }

    sh.fs.clearDir = clearDir;
    function rmrf(dirPath) {
        clearDir(dirPath, true)
    }

    sh.fs.clearDir = clearDir;
    function isDirectory(dir) {
        var fs = require("fs")
        if (fs.statSync(dir).isDirectory()) {
            return true
        }
        return false;
    }



    /**
     * Opens all files in array sync
     * @param filesToOpen
     * @returns {Array}
     */
    function openFiles(filesToOpen, prepend) {
        var filesOpened = []
        prepend = sh.defaultValue(prepend, '')
        var fs = require("fs")
        for (var i in filesToOpen) {
            var file = filesToOpen[i];
            try {
                file = fs.readFileSync(prepend + file)
            } catch ( e) {}
            filesOpened.push(file)
        }

        return filesOpened;
    }


    function getFileName(filePath) {
        var path = require('path')
        return path.basename(filePath)
    }
    function getPath(filePath) {
        var path = require('path')
        return path.dirname(filePath)
    }


    function makePathIfDoesNotExist(dir) {
        var fs = require("fs")
        var mkdirp = require('mkdirp')
        console.log('dir', dir)
        mkdirp.sync(dir)

        return;
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, 0766, function (err) {
                if (err) {
                    console.log(err);
                    response.send("ERROR! Can't make the directory! \n");    // echo the result back
                }
            });
        }
    }

    function fileExists(dir) {
        var fs = require("fs")
        return fs.existsSync(dir)
    }
    function checkFileMTime(dir, waitTimeSecs) {
        var fs = require("fs")
        if ( sh.fileExists( dir ) == false  ) {
            return false
        }
        var status = fs.statSync(dir)
        var date = new Date();
        if ( date.getTime() - status.mtime.getTime()  > waitTimeSecs ) {
            return true;
        }
        return false
    }

    function deleteFile(file, okIfNotFound, async) {
        if ( okIfNotFound == true ) {
            if ( sh.fileExists(file) == false ) {
                console.log('sh.deleteFile', 'cannot find file to delete', file)
                return false;
            }
        }
        var fs = require("fs")
        if ( async === true ) {
            fs.unlink(file, function unlinked(err){
                //console.log('')
            });
            return;
        }
        //console.log('xDelete', file)
        //setTimeout(function xDelete() {
        fs.unlinkSync(file)
        //}, 500);
        // return fs.unlinkSync(file)
    }


    sh.fs.removeDir = function removeDir(dir) {
        var fs = require('fs-extra');

        fs.removeSync(dir);
    }
    sh.fs.removeDir2 = function removeDir(dir) {
        var fs = require('fs-extra');
        asdf.g
        fs.removeSync(dir);
    }
    sh.fs.deleteDir = sh.fs.removeDir;

    sh.fs.mkdirp = makePathIfDoesNotExist;

    sh.fs.copyDir = function copyDir(dirFrom, dirTo) {
        var fs = require('fs-extra'); //
        fs.copySync(dirFrom, dirTo);
    }
    sh.copyDir = sh.fs.copyDir;

    sh.fileExt = function fileExt(filePath, matchExt) {
        var ext = filePath.split('.').slice(-1)[0];
        if ( ext == matchExt ) {
            return true;
        }
        return false;
    }


    sh.fs.move = function move(from, to) {
        var fs = require("fs")
        if ( fs.statSync(from).isFile() &&
            ! fs.statSync(to).isFile()  ) {
            to = to + '/' + sh.getFileName(from);
        }
        sh.fs.copyDir(from, to)
        sh.fs.deleteDir(from);
    }
    sh.fs.changeDir = function changeDir(from, to) {
        var filename = sh.getFileName(from)
        var output = to + '/' + filename;
        return output
    };

    function dirname(fileName) {
        var path = require("path")
        return path.dirname(fileName);
    }
    function writeFile(fileName, content, surpressErrors, binary) {
        var fs = require("fs")
        //var contents = fs.readFileSync(file, 'utf-8')//.toString()

        var exists = fs.existsSync(fileName )
        if (exists) {
            //writeFile(++i);
        } else {
            // fs.writeFile(fileName);
        }

        var encoding = 'utf8';
        if ( binary == true ) {
            encoding = 'binary'
        }

        if (surpressErrors == true) {
            try {
                fs.writeFileSync(fileName, content, encoding);
            } catch (e) {
                console.error(e)

            }
        } else {
            fs.writeFileSync(fileName, content, encoding);
        }

    }


    function copyFile(source, target, cb) {

        var copySettings = source;
        if ( copySettings.hasOwnProperty('file') ) {
            source = copySettings.file
            if ( copySettings.hasOwnProperty('toDir')) {
                var nameOfFileAfterMove = path.basename(source)
                target = copySettings.toDir+ '/' + nameOfFileAfterMove;
            }
            cb = copySettings.callback;
        }
        if ( copySettings.hasOwnProperty('source') ) {
            source = copySettings.source
            target = copySettings.target
            cb = copySettings.callback;
        }

        var fs = require('fs')
        var cbCalled = false;

        var rd = fs.createReadStream(source);
        rd.on("error", function(err) {
            done(err);
        });
        var wr = fs.createWriteStream(target);
        wr.on("error", function(err) {
            done(err);
        });
        wr.on("close", function(ex) {
            done();
        });
        rd.pipe(wr);

        function done(err) {
            if (!cbCalled) {
                if ( cb != null ) {
                    cb(err);
                }
                cbCalled = true;
            }
        }
    }

    function getUserHome() {
        return process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];
    }

    function writeFile2(fileName, content, settings) {
        //first argument can be an object
        if ( fileName.hasOwnProperty('name')) {
            settings = fileName;
        }

        settings.dir //where to store files
        settings.timestamp_dir //
        settings.quantizeTime //how many minutes to quantize directory name
        settings.fxCallback //called when done writing file async
        //settings.output_filename_preamble =
        //sh.defaultValue(settings.output_filename_preamble, '')
        //will be prepended to front of file_name
        fileName = sh.defaultValue(settings.fileName, fileName) //overrides first param

        //store strings
        if ( settings.content != null ) {
            content = settings.content;
        }
        if ( settings.contents != null ) {
            content = settings.contents;
        }
        //convert json
        if ( settings.obj != null ) {
            content = sh.toJSONString(settings.obj)
        }
        if ( settings.json != null ) {
            content = sh.toJSONString(settings.json)
        }

        if ( settings.name != null ) {
            fileName =  settings.name
        }

        var fs = require("fs")
        var mkdirp = require("mkdirp")
        //var contents = fs.readFileSync(file, 'utf-8')//.toString()
        if (settings.timestamp) {
            path.extname('index.html')
            //fileName += getTimeStamp()
            fileName = path.basename(fileName, path.extname(fileName)) + '.' + getTimeStamp() + path.extname(fileName)
        }

        if (settings.dir_home ) {

            settings.dir = sh.defaultValue(settings.dir, '')
            settings.dir = path.join(sh.getUserHome(), settings.dir)
        }

        if (settings.timestamp_dir) {
            function quantize(offset, minutesQuantize) {
                minutesQuantize = sh.defaultValue(minutesQuantize, 5)
                var quantizeMilliseconds = 1000 * 60 * 5
                offset = sh.defaultValue(offset, 0)
                var timeInMs = new Date().getTime()
                timeInMs += offset
                var x = timeInMs / quantizeMilliseconds
                var y = Math.floor(x)
                return y
            }

            function convertQuantizedTimeToDirName(minutesQuantize) {
                minutesQuantize = sh.defaultValue(minutesQuantize, 5) //default ot 5 min range
                var timestampDir = getTimeStamp(quantize(0, minutesQuantize) * 60 * minutesQuantize * 1000)
                return timestampDir;
            }

            var q = 1000 * 60
            var test = [quantize(q * 2), quantize(q * 5), quantize(q * 10), quantize(q * 11), quantize(11110)]
            var test2 = [getTimeStamp(quantize(q * 2) * 60 * 5 * 1000) ]
            var timestampDir = convertQuantizedTimeToDirName(settings.quantizeMinutes)
            //add timestamped dir onto original settings.dir
            //what happens if settings dir is null?
            settings.dir = sh.defaultValue(settings.dir, '')
            settings.dir = path.join(settings.dir, timestampDir)
            mkdirp.sync(settings.dir)
            fileName = path.join(settings.dir, fileName) //if filename WAS abs, this would not work

        } else {

            settings.dir
            if (settings.dir) {
                if ( sh.includes( settings.dir, '?') || sh.includes( settings.dir, '&') ) {
                    console.error( 'special chars in settings.dir');
                }
                mkdirp.sync(settings.dir)
                fileName = path.join(settings.dir, fileName) //if filename WAS abs, this would not work
            }



        }


        //dev wants to get the dir that will be written to ...
        //used when timestamp_dir, when hardcoded dir is set
        if ( settings.getDir ) {
            return path.dirname(fileName);
        }

        // console.log('writeFile2', fileName)
        // fs.exists(fileName, function (exists) {
        //     if (exists) {
        //writeFile(++i);
        //     } else {
        // fs.writeFile(fileName);
        //    }

        try {
            if ( settings.doNotMakeDirectory != true ) {
                var dir = sh.dirname(fileName)
                mkdirp.sync(dir)
            }
            if ( settings.binary != true ) {
                fs.writeFileSync(fileName, content, "utf8");
            } else {
                fs.writeFileSync(fileName, content,'binary' );
                /*var content=content.toString("binary");
                 fs.writeFileSync(fileName, content, 'binary', function(err){
                 if (err) throw err
                 console.log('File saved.')
                 })*/
            }
            //fs.writeFileSync(fileName, content, "utf8");
            sh.callIfDefined(settings.fxCallback)
            fs.exists(fileName, function (exists) {
                var path = require('path')
                if ( settings.showLocation ) {
                    console.log('file?', exists, path.resolve(fileName))
                }
            })
        } catch (e) {
            if (settings.surpressErrors != true) {
                throw e
            }
        }
        // });

        var output = {}
        output.filename = fileName;
        return output
    }


    function writeFile2Test() {
        writeFile2('a.txt', 'content', {dir: 'inner', timestamp_dir: true});
        writeFile2('a2.txt', 'content', {dir: 'inner', timestamp_dir: true});
        writeFile2('a2.txt', 'content', { timestamp_dir: true});
        return;
        writeFile2('a.txt', 'content', {dir: 'inner', timestamp: true});
        writeFile2('ab.txt', 'content', {dir: 'inner/asdf', timestamp: true});
        writeFile2('ab.txt', 'content', {timestamp: true});
    }

    function writeFileToTrash(fileName, content, surpressErrors) {
        var fs = require("fs")
        //var contents = fs.readFileSync(file, 'utf-8')//.toString()

        fileName = 'c:/trash/' + fileName
        fs.exists(fileName, function (exists) {
            if (exists) {
                //writeFile(++i);
            } else {
                // fs.writeFile(fileName);
            }

            try {
                fs.writeFileSync(fileName, content, "utf8");
            } catch (e) {
                if (surpressErrors != true) {
                    throw e
                }
            }
        });


    }


    function getContentBetween(content, starter, ender) {
        if (content.indexOf(starter) == -1) {
            return content
        }
        var result = content.split(starter)[1]
        if (result.indexOf(ender) == -1) {
            return result
        }
        var result = result.split(ender)[0]

        return starter+result+ender

    }


    function getArrayContentBetween(content, starter, ender) {
        var indexOfStarter = content.indexOf(starter)
        if (indexOfStarter == -1) {
            return content
        }
        var content = content.slice(indexOfStarter+starter.length)

        var indexOfEnder = content.indexOf(ender)
        if (indexOfEnder == -1) {
            return content
        }


        var result = content.slice(0, indexOfEnder)

        return result

    }

    /**
     * Return a concated array of assumed aray at prop
     */
    function arrayCondenseArrayByProp(objArray, arrayProp) {

        var list = [];
        for (var i = 0; i < objArray.length; i++) {
            var obj = objArray[i];
            var innerArray = obj[arrayProp]
            if (innerArray == null) {
                continue;
            }
            /*for (var y = 0; i < innerArray.length; y++) {
             var innerObj = innerArray[y];
             innerObj
             }*/
            list = list.concat(innerArray)
        }


        return list;
    }


    function throwErrorIfPropNull (obj, prop, msg ) {
        if ( obj[prop] == null ) {
            throw new Error(msg);
        }
    }
    sh.throwErrorIfPropNull  =throwErrorIfPropNull;

    sh.errors.throwErrorIfPropNull

    function requiredParam(param, warning) {
        if (param == null) {
            throw new Error(['Required Param:', error, warning].join(" "))
        }
    }
    function requiredParamOneOf(warning /* ... params*/) {
        var args = convertArgumentsToArray(arguments)
        args = args.slice(1)
        if (args.length == 0) {
            throw requiredParamOneOf + ' no args sent ' + warning
        }

        for (var i = 0; i < args.length; i++) {
            var param = args[i];
            if (param != null) {
                return
            }
        }

        if (param == null) {
            throw new Error(['Required one of params to be set:', warning].join(" "))
        }
    }

    /**
     * Returns true if line begins with a # of !
     */
    function isCommentLine(line) {
        var firstChar = sh.strip(line).charAt(0)
        if (firstChar == '#' || firstChar == '!')
            return true

        return false
    }
    function defaultValue(input, ifNullUse) {
        if (input == null) {
            return ifNullUse
        }
        return input;
    }

    /**
     * Merge two objects together
     * Utility: Default settings object, is being overriden
     * by optional settings object
     * @param mergeThisObject - override settings
     * @param intoThisObject - base settings
     * @returns {*}
     */
    function mergeObjects(mergeThisObject, intoThisObject, onlyIfIntoPropIsNotNull, ignoreNested) {
        onlyIfIntoPropIsNotNull = sh.dv(onlyIfIntoPropIsNotNull, false);
        ignoreNested = sh.dv(ignoreNested, false) //do regular replace
        if (mergeThisObject == null) {
            return intoThisObject
        }
        if (intoThisObject == null) {
            return intoThisObject
        }

        sh.each(mergeThisObject, function( prop, val ) {
            var isNull = intoThisObject[prop] == null ;
            if ( onlyIfIntoPropIsNotNull == true   ) {
                if ( intoThisObject[prop] != null ) {
                    return;
                }
            }
            //ignoreNestedWhenNotNull
            if ( ignoreNested && sh.isObject(val) && isNull ==false ) {
                return;
            }
            intoThisObject[prop] = val;
        })

        return intoThisObject;
    }

    sh.mergeObjectsForce = function (mergeThisObject, intoThisObject, onlyIfIntoPropIsNotNull, ignoreNested) {
        onlyIfIntoPropIsNotNull = sh.dv(onlyIfIntoPropIsNotNull, false);
        ignoreNested = false
        return sh.mergeObjects(mergeThisObject, intoThisObject, onlyIfIntoPropIsNotNull, ignoreNested);
    }

    function defaults(from, to ) {
        sh.mergeObjects(from, to, true)
    }
    sh.defaults = defaults;



//Used to merge two config objects together ..
    function mergeObjects2_configMerge(mergeThisObject, intoThisObject, onlyIfIntoPropIsNotNull) {
        if (mergeThisObject == null) {
            return intoThisObject
        }
        if (intoThisObject == null) {
            return intoThisObject
        }

        sh.each(mergeThisObject, function (prop, val) {
            var currentVal = intoThisObject[prop]
            if (onlyIfIntoPropIsNotNull == true) {
                if (currentVal != null) {
                    return;
                }
            }
            if (sh.isObject(val) && currentVal != null) {
                sh.mergeObjects2(val, currentVal)
                return
            }
            if (currentVal != null && val == null) {
                return;
            }
            intoThisObject[prop] = val;
        })

        return intoThisObject;
    }

    sh.mergeObjects2 = mergeObjects2_configMerge;


    /**
     * MAke itemOrArray an array if it not already one
     * @param itemOrArray
     * @returns {*}
     */
    function forceArray(itemOrArray) {
        var array = itemOrArray;
        if (!(itemOrArray instanceof Array)) {
            array = [itemOrArray];
        }
        if (itemOrArray == null) {
            array = []
        }
        return array
    }


    function arrayFilterByProp(items, prop, val, doLikeSearch) {
        var filteredItems = []
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            var propVal = item[prop];
            if ( doLikeSearch != true ) {
                if (item[prop] == val) {
                    filteredItems.push(item)
                }
            } else {
                if (sh.includes(propVal.toLowerCase(), val.toLowerCase())) {
                    filteredItems.push(item)
                }
            }
        }

        return filteredItems
    }
    function arrayCollectProp(items, prop) {
        var filteredItems = []
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            filteredItems.push(item[prop])
        }
        return filteredItems
    }

    function arrayCallMethodOnItem(items, method) {
        var filteredItems = []
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            filteredItems.push(item[method]())
        }
        return filteredItems
    }
    sh.arrayCallMethodOnItem = arrayCallMethodOnItem;


    function isArray(itemOrArray) {
        return (itemOrArray instanceof Array)
    }

    function isString(objectOrString) {
        //return (objectOrString instanceof String)
        return typeof objectOrString == 'string'
    }

    function isNumber(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }
    sh.isNumber = isNumber;

    function isObject(obj) {
        if ( sh.isFunction(obj)) {
            return false;
        }
        if ( obj == null ) {
            return false;
        }
        return typeof obj == 'object'
    }


    function isFunction(functionToCheck) {
        var getType = {};
        return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
    }

    function clone2(item) {
        var CircularJSON = require('circular-json')
        item = CircularJSON.stringify(item)
        item = CircularJSON.parse(item)
        return item
    }

    function clone(item) {
        item = JSON.stringify(item)
        item = JSON.parse(item)
        return item
    }


    function copyProps(from, to) {
        sh.each(from, function(k,v){
            to[k]=v;
        })
    }
    sh.copyProps = copyProps;

    /**
     * Remove your props
     * @param item
     * @param props
     */
    function removeProps(item, props) {
        sh.each(props, function (ia, prop) {
            delete item[prop]
        })
    }

    function assert(val, val2, error) {
        if (val != val2) {
            throw new Error([val, '!=', val2, error].join(', '))
        }
    }


    function forLoop() {
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
        }
    }

//copied from jquery
    /**
     * sh.each(items, function( itemIndex, item ) {
    })

     * @param object
     * @param callback
     * @param args
     * @returns {*}
     */
    function each(object, callback, args) {

        var name, i = 0, length = object.length;

        if (args) {
            if (length === undefined) {
                for (name in object)
                    if (callback.apply(object[ name ], args) === false)
                        break;
            } else
                for (; i < length;)
                    if (callback.apply(object[ i++ ], args) === false)
                        break;

            // A special, fast, case for the most common use of each
        } else {
            if (length === undefined) {
                for (name in object)
                    if (callback.call(object[ name ], name, object[ name ]) === false)
                        break;
            } else
                for (var value = object[0];
                     i < length && callback.call(value, i, value) !== false; value = object[++i]) {
                }
        }

        return object;
    }


    each.print = function print (items, prop, save, display) {

        var lines = [];

        sh.each(items, function printItem(k,v){
            var prePend = (k+1)+'.';
            if ( sh.isString(k)) { // dictionary
                prePend = (k)+':';
            }
            var val = v;
            if ( prop != null ) {
                val =  v[prop];
            }

            if ( display != false ) {
                console.log(prePend, val);
            }
            lines.push(prePend + ' ' + val)
        })

        return lines
    }

    each.find = function find (items, lookFor) {
        var found = false;
        sh.each(items, function printItem(k,v){
            if ( v == lookFor) {
                found = true
                return false;
            }
        })
        return found;
    }


    each.printJSON = function print (items, label) {
        if ( label != null ) {
            console.log('\n', label+':')
        }
        sh.each(items, function printItem(k,v){
            console.log('\t', (k+1)+'.', sh.toJSONString(v) );
        })
    }

    each.times = function times(number, fx, startAt0) {
        var numbers = [];
        var number = parseInt(number);
        var numStart = 1;
        if ( startAt0 == true ) { //by default 10 times give syou 0-1, here we use 1- 10
            numStart = 0;
        }
        for ( var i = 0; i < number; i++) {
            var num =i;
            num += numStart
            numbers.push(num);
        }

        if ( fx != null ) {
            sh.each(numbers, fx)
        }
        else {
            return numbers;
        }
    }

    each.createDict = function createDict(items, prop) {
        prop = sh.dv(prop, 'id');
        var dict = {};
        sh.each(items, function addToDict(i, obj) {
            var key = obj[prop];
            if ( sh.isArray(prop) ) {

            }
            if ( sh.isFunction(prop) ) {
                key = prop(obj)
            }
            dict[key] = obj;
        });

        return dict;
    }


    each.prop = function prop(items, prop) {
        prop = sh.dv(prop, 'id');
        var returnArray = [];
        sh.each(items, function addToDict(i, obj) {
            var key = obj[prop];
            if ( sh.isArray(prop) ) {

            }
            var val = obj[prop];
            if ( sh.isFunction(prop) ) {
                val = prop(obj)
            }
            //dict[key] = obj;
            returnArray.push(val);
        });
        return returnArray;
    }

    each.prepend = function prependToArray(items, str) {
        var output = [];
        sh.each(items, function procItem(i, item) {
            output.push(str + item)
        })
        return output;
    }

//AKA Lines helper
    each.lines = function (items, config) {
        config = sh.dv(config, {})


        if ( sh.isObject( items )) {
            config = items;
        };
        if ( config.str != null ) {
            items = config.str.split('\n');
        };


        if ( sh.isString(items)) {
            items = items.split('\n');
        }

        var lines = [];
        lines = sh.dv(config.addTo, []);


        sh.each(items, function processLine(i, line) {

            if ( line == null ) {
                return;
            }
            if ( line.trim() == '' && config.skipEmpty != false  ) {
                return;
            }

            if ( config.ignore != null ) {
                var ignoreFault = false;
                sh.each(config.ignore, function testIgnoreLineFilter(x, ignore) {
                    if (sh.includes(line, ignore)) {
                        return false;
                    }
                });
                if (ignoreFault) {
                    return;
                }
                ;
            }


            if ( config.ignoreComments ) {
                var commentStartingChars = ["'", '//', '#']
                if ( sh.isArray(config.ignoreComments) ) {
                    commentStartingChars = config.ignoreComments
                }
                var ignoreFault = false;
                sh.each(commentStartingChars, function testIgnoreLineFilter(x, ignore) {
                    if ( sh.startsWith(line, ignore)) {
                        return false;
                    }
                });
                if ( ignoreFault ) {
                    return;
                };
            }

            if ( config.fxProc != null ) {
                config.line = line;
                config.includes = function includes(val){
                    return config.line.indexOf(val)!=-1;
                };

                config.remove = function remove(val){
                    config.line = config.line.replace(val, '');
                    return config;
                };

                line = sh.callIfDefined(config.fxProc, line)
                if ( line == null )
                    return;
                if ( line == false )
                    return false; //stop processing
            }


            if ( config.appendToLine != null ) {
                line += config.appendToLine
            }

            lines.push(line)

        })

        return lines;
    }

    /**
     * Fluid api for arrays
     * @param items
     * @constructor
     */
    function EachHelper(items) {
        var self = this;
        var p = self;
        self.items = items;
        self.prop = function prop( prop) {
            prop = sh.dv(prop, 'id');
            var returnArray = [];
            sh.each(self.items, function addToDict(i, obj) {
                var key = obj[prop];
                if ( sh.isArray(prop) ) {

                }
                var val = obj[prop];
                if ( sh.isFunction(prop) ) {
                    val = prop(obj)
                }
                //dict[key] = obj;
                returnArray.push(val);
            });
            self.items = returnArray;
            return self;
        }

        self.prepend = function prependToArray( str) {
            var output = [];
            sh.each(self.items, function procItem(i, item) {
                output.push(str + item)
            })
            self.items = output;
            return self;
        }
    }

    function eachHelper(items) {

        return new EachHelper(items)
    }

    function getTimeStamp(timeOverride) {
        var str = "";

        var currentTime = new Date()
        if (timeOverride != null) {
            currentTime.setTime(timeOverride);
        }
        var hours = currentTime.getHours()
        var minutes = currentTime.getMinutes()
        var seconds = currentTime.getSeconds()

        if (minutes < 10) {
            minutes = "0" + minutes
        }
        if (seconds < 10) {
            seconds = "0" + seconds
        }
        str += hours + "_" + minutes + "_" + seconds// + " ";
        //(time.getMonth() + 1)+'-'+time.getDate()+'-'+time.getFullYear()+' '+(time.getHours()+1)+'-'+time.getMinutes()+'-'+time.getSeconds().toString();
        str = (currentTime.getMonth() + 1) + '-' + currentTime.getDate() + '-' + currentTime.getFullYear() + '_' + str;

        /* if(hours > 11){
         str += "PM"
         } else {
         str += "AM"
         }*/
        return str;
    }


    /**
     * Utility, compare this time to the last time, Date}
     */
    function timeElapsed(lastDate) {
        var currentTime = new Date()
        var time = currentTime.getTime() - lastDate.getTime()
        return time / 1000;
    }

    /**
     * Utility, unity looks cleaner
     * @returns {Date}
     */
    function getTime() {
        return new Date()
    }

    function caseInsensitiveComparison(str1, str2, otherValidCombinations) {
        if (str1 == str2)
            return true

        if (str1 == null) {
            return false
        }

        if (str2 == null) {
            return false;
        }

        if (str1.toLowercase() == str2.toLowercase()) {
            return true
        }

        if (otherValidCombinations != null) {
            sh.each(otherValidCombinations, function (itemIndex, item) {
                if (str1.toLowercase() == item.toLowercase()) {
                    return true
                }
            })
        }
        return false;
    }

    /**
     * Utility: Pass a function to show arguments
     */
    function traceResult() {
        console.log(arguments.join(", "))
    }

    function traceResultNamed(name) {
        return function traceResult_Named() {
            var args = convertArgumentsToArray(arguments);
            console.log(name, args.join(", "))
        }
    }

    function waitXSecs(secs, callback, name) {
        setTimeout(function traceResult_Named() {
                if (name != null) {
                    console.log('waitXSecs', 'secs', name)
                }
                callIfDefined(callback)
            }, secs * 1000
        )
    }

    function wait1Sec(callback, name) {
        waitXSecs(1, callback, name)
    }




    function logLater(secs, content, name) {
        if (secs == null) {
            secs = .5
        }
        setTimeout(function traceResult_Named() {
                //if ( name != null ) {
                console.log()
                console.log(name, ':')
                console.log(content)
                // }
                // callIfDefined(callback)
            }, secs * 1000
        )
    }


    function sortArrayByField(array, field) {
        function compare(a, b) {
            if (a[field] < b[field])
                return -1;
            if (a[field] > b[field])
                return 1;
            return 0;
        }

        if (array == null) {
            return array;
        }
        array.sort(compare);
        return array
    }


    function error() {
        setTimeout(function () {
            console.error.apply(this, arguments)
        }, 500)
    }



    function urlLink(potetialUrl) {

        if (potetialUrl.indexOf('http') == 0) {
            return true
        }


        return false
    }

    function toJSON(o, printJSON) {
        printJSON = defaultValue(printJSON, false)
        var json = JSON.stringify(o)
        if (printJSON) {
            console.log(json)
        }
        return json;
    }

    function safeProp(obj, val ) {
        if (  obj != null ) {
            return val
        }
        return ''
    }

    function isNull(val) {
        if ( val == null ) {
            return true
        }

        return false;
    }

    function toJSONString(o, printJSON) {
        printJSON = defaultValue(printJSON, false)
        var json = JSON.stringify(o, "\t", "\t")
        if (printJSON) {
            console.log(json)
        }
        return json;
    }
    function toJSONStrX(o, pretty) {


        // var jsonHtmlTable = ConvertJsonToTable(objectArray, 'jsonTable', null, 'Download');

        function syntaxHighlight(json) {
            if (pretty) {
                /*json = json.replace(/\{\n/gi, '')
                 json = json.replace(/\}\n/gi, '')
                 json = json.replace(/\[\n/gi, '')
                 json = json.replace(/\]\n/gi, '')

                 json = json.replace(/\},\n/gi, '\n')
                 json = json.replace(/\],\n/gi, '\n')*/
            } else {
                json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            }
            return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
                var cls = 'number';
                if (/^"/.test(match)) {
                    if (/:$/.test(match)) {
                        cls = 'key';
                    } else {
                        cls = 'string';
                    }
                } else if (/true|false/.test(match)) {
                    cls = 'boolean';
                } else if (/null/.test(match)) {
                    cls = 'null';
                }
                return '<span class="' + cls + '">' + match + '</span>';
            });
        }

        // var obj = {a:1, 'b':'foo', c:[false,'false',null, 'null', {d:{e:1.3e5,f:'1.3e5'}}]};
        var str = JSON.stringify(o, undefined, 4);

        //output(str);
        var x = syntaxHighlight(str);

        return x;
    }

    var styles = '<style>' + 'pre {outline: 1px solid #ccc; padding: 5px; margin: 5px; }' +
        '.string { color: green; }' +
        '.number { color: darkorange; }' +
        '.boolean { color: blue; }' +
        '.null { color: magenta; }' +
        '.key { color: red; }' +
        '</style>'


//http://stackoverflow.com/questions/4810841/how-can-i-pretty-print-json-using-javascript
    function toHTMLStr(o) {
        var tab = RegExp("\\t", "g");
        var newline = RegExp("\\n", "g");
        o = o.replace(tab, '&nbsp;&nbsp;&nbsp;&nbsp;')
        //var tab = RegExp("\\t", "g");
        o = o.replace(newline, '<br />')
        var tab = RegExp("\",", "g");
        o = o.replace(newline, '",<br />')


        return o;
    }


    function makeLink(title, url, desc) {
        var s = '<a href="' + url + '" title="' + desc + '">' + title + '</a>'
        return s;
    }

    function wrapInHTMLTag(str, tag) {
        var s = '<'+tag+'>' + str + '</'+tag+'>'
        return s;
    }



    /**
     * Join with new line
     * @param array
     * @returns {*|join|string|String|join}
     */
    function joinn(arr) {
        var args = convertArgumentsToArray(arguments)
        if (args.length > 1) {
            arr = args;
        }
        else {

        }

        return arr.join("\n")
    }


    function EasyTimer() {
        this.start = function start() {
            this.startTime = new Date();
            newTimer
            this.running = true
        }

        this.stop = function stop() {
            this.duration = sh.timeElapsed(this.startTime).toFixed(2)
            this.running = false;
        }


        this.remaining = function remaining(percentDone) {
            this.duration = sh.timeElapsed(this.startTime).toFixed(2)
            var remainingPercentage = 1-percentDone;
            var percRatio = remainingPercentage/percentDone
            var secsRemaining = this.duration*percRatio
            var minsRemaining = secsRemaining / 60
            return minsRemaining.toFixed(2)
        }

        this.secs = function secs(format) {
            if (this.running) {
                this.stop()
            }

            var output = this.duration
            //this.duration = sh.timeElapsed(this.startTime).toFixed(2)
            if (format != false) {
                output = ' ' + sh.paren(this.duration)
            }
            return output;
        }


    }

    function newTimer() {
        var t = new EasyTimer()
        t.start()
        return t;
    }
//line.replace(/'/g, "\\'");

    function isWin() {
        return process.platform === 'win32'
    }
    function isMac() {
        console.log('platform', process.platform)
        return process.platform === 'mac'
    }

//http://stackoverflow.com/questions/16261635/javascript-split-string-by-space-but-ignore-space-in-quotes-notice-not-to-spli
//q: javascript split string by space, but ignore space in quotes (notice not to split by the colon too)
    function splitStringOnQuotes(s) {
        //s = 'Time:"Last 7 Days" Time:"Last 30 Days"'
        output = s.match(/(?:[^\s"]+|"[^"]*")+/g)
        return output;
    }

//http://stackoverflow.com/a/2970667
    function toCamelCase(str) {
        return str.replace(/(?:^\w|[A-Z]|\b\w|\s+)/g, function(match, index) {
            if (+match === 0) return ""; // or if (/\s+/.test(match)) for white spaces
            return index == 0 ? match.toLowerCase() : match.toUpperCase();
        });
    }


    function toUpperCaseFirstChar (str) {
        return str.substr( 0, 1 ).toUpperCase() + str.substr( 1 );
    }

    function toLowerCaseFirstChar (str) {
        return str.substr( 0, 1 ).toLowerCase() + str.substr( 1 );
    }

    function unwrap(str, onlyIfFirstCharIs ){
        if ( onlyIfFirstCharIs != null ) {
            if ( str.slice(0,1) != onlyIfFirstCharIs ) {
                return str;
            }
        }
        str = str.trim(str)
        str = str.slice(1,-1)
        return str
    }


    function isWrapped(edges, str) {
        str = str.trim()
        var closer =  edges.slice(1)// ')'
        var opener = edges.slice(0,1)// '('
        if ( str.slice(0,1)!= opener) {
            return false
        }
        if ( str.slice(str.length-1)!= closer) {
            return false
        }
        return true;
    }

    function defineFS2() {

        var file = sh.fs;
        sh.file = file;
        sh.files = file;

        /**
         * Appends ext to the filename
         * @param filename
         * @param ext
         * @returns {*}
         */
        sh.file.addExtensionIfMissiong = function addExtensionIfMissiong(filename, ext) {
            if (sh.includes(filename, ext)) {
                return filename;
            }
            //add '.' if needed
            if (false == sh.includes(ext, '.')) {
                ext = '.' + ext;
            }
            return filename + ext;
        }

        /**
         * Appends ext to the filename
         * @param filename
         * @param ext
         * @returns {*}
         */
        sh.file.prependDirIfDefined = function prependDirIfDefined(file, prePend) {
            if (prePend == null) {
                return file;
            }
            if (false == sh.includes(prePend, '/')) {
                prePend = prePend + '/'
            }
            file = prePend + file;
            return file;
        }

        /**
         * Should add before extension?
         * @param name
         * @param append
         * @returns {*}
         */
        sh.file.addToFilename = function addToFilename(name, append) {
            return name + append;
        }

        /**
         *
         * @param name
         * @param append
         * @returns {*}
         */
        sh.file.backup = function backup(fileNameToBackup, dir, maxNumFiles) {

            var newName = fileNameToBackup
            /*if ( append ) {
             newName += '_'+append;
             }*/
            if (sh.fileExists(fileNameToBackup) == false) {
                return;
            }
            var contents = sh.readFile(fileNameToBackup);
            var writeFileSettings = {};
            writeFileSettings.dir = 'backups';
            if (dir != null) {
                writeFileSettings.dir = dir;
            }
            writeFileSettings.contents = contents
            writeFileSettings.maxNumFiles = maxNumFiles;
            writeFileSettings.name = newName;
            writeFileSettings.timestamp = true;
            sh.writeFile2(writeFileSettings);

            sh.file.clipDir('backups', 10)

        }

        /**
         * Where from before?
         * count files
         * sort by modified time
         * delete
         * RouteHelper
         * @param dir
         * @param maxNumFiles
         */
        sh.file.clipDir = function clipDirFileCount(dir, maxNumFiles) {

        }
    }
    defineFS2();


//iterate over string
    /*
     $.each(myJsonObj, function(key,val){
     // do something with key and val
     });
     You can always write a function to recursively descend into the object:

     function traverse(jsonObj) {
     if( typeof jsonObj == "object" ) {
     $.each(jsonObj, function(k,v) {
     // k is either an array index or object key
     traverse(v);
     });
     }
     else {
     // jsonOb is a number or string
     }
     }
     */

    function defineArrays() {


        var array = {}
        sh.array = array;
        array.getRandomItem = function getRandomItem(arry) {
            var item = arry[Math.floor(Math.random()*arry.length)];
            return item;
        }

        array.removeNulls = function removeNulls(arry, strict) {
            var y = []
            sh.each(arry, function(k, v){
                if (v == null ) {
                    return
                }
                if ( strict == true && v == 'undefined') {
                    return;
                }
                y.push(v)
            })
            return y;
        }

    }
    defineArrays();

    function defineCallingCommands() {
        sh.run = function runCommand(cmd, opts) {

            console.log('running', cmd)
            var child_process = require('child_process');
            var ipAdd = child_process.execSync(cmd, opts)

        }

        sh.runAsync = function runCommandAsync(cmd, fx, opts) {
            console.log('running', cmd)
            var child_process = require('child_process');
            var ipAdd = child_process.exec(cmd, opts, fx)
        }

        sh.runAsync2 = function runCommandAsync_Spawn(cmd, args, fxDone, opts) {
            console.log('running', cmd)

            // (function() {
            var childProcess = require("child_process");
            var oldSpawn = childProcess.spawn;

            function mySpawn() {
                console.log('spawn called');
                console.log(arguments);
                var result = oldSpawn.apply(this, arguments);
                return result;
            }

            childProcess.spawn = mySpawn;
            //  })();


            var spawn = childProcess.spawn;
            var proc = spawn(cmd, args, opts);


            proc.on('error', function (err) {

                console.error('err', err.stack)
                throw err
            })


            proc.on("exit", function (exitCode) {
                console.log('process exited with code ' + exitCode);
                sh.callIfDefined(fxDone)
            })

            proc.stdout.on("data", function (chunk) {
                console.log('received chunk ' + chunk);
            })

            proc.stdout.on("end", function () {
                console.log("finished collecting data chunks from stdout");
            })


        }


        /**
         *
         * Can run command in a subprocess
         * @constructor
         */
        function CommandRunner() {
            var preamble = '\t\tCRunner'
            //store to log file
            var self = this;
            self.launchCmd = function launchCmd(cmd, args, settings) {
                //console.log(preamble, 'launchCmd')
                self.log = {}
                self.log.startTime = sh.getTimeStamp()
                self.log.cmd = cmd
                self.log.args = args;
                self.log.output = ''
                self.log.error = ''

                self.spawn(cmd, args, settings)
            }

            /**
             * Tokenized interface
             * @param cmd
             * @param args
             * @param settings
             */
            self.execute = function execute(settings) {
                if (self.silent) {
                    console.log(preamble, ',launchCmd', settings.cmd)
                }
                var cmd = settings.cmd
                var args = settings.args;

                self.silent = settings.silent;
                self.settings = settings;
                //make this more user friendly. split cmd if has whitespace
                if (sh.includes(cmd, ' ')) {
                    var _args = cmd.split(' ');
                    _args = sh.splitStringOnQuotes(cmd)
                    cmd = _args[0]
                    args = _args.slice(1)
                }

                self.log = {}
                self.log.startTime = sh.getTimeStamp()

                self.log.cmd = cmd
                self.log.args = args;

                self.log.output = ''
                self.log.error = ''

                self.spawn(cmd, args, settings)
            }


            self.spawn = function spawn(cmd, args, settings) {
                var callback = settings.fxCallback //called when cmd exits

                if (settings.noWait) {
                    sh.callIfDefined(callback)
                }

                settings.origCmd = cmd;
                var prependToLog = sh.defaultValue(settings.prependToLog, '') //show source
                //if cmd is a javascript file, append node on the beginning
                if (cmd.indexOf('node') != 0 && sh.endsWith(cmd, '.js')) {
                    args.unshift(cmd)
                    cmd = 'node';
                    //if ( process.platform != 'win32' )
                    // cmd = 'nodejs'
                }
                self.callback = callback;
                self.settings = settings;

                var terminalRef = null;

                function appendToLog(logLine, error) {
                    try {
                        if (settings != null && settings.logger != null) {
                            settings.logger.push(logLine)
                        }
                        self.log.output += logLine //+ sh.n
                        if (error) {
                            self.log.error += logLine
                        }

                    } catch (e) {
                        console.error('issue with debug');
                        terminalRef.kill('SIGINT');
                        terminal.stdout.removeAllListeners('data');
                        terminal.stderr.removeAllListeners('data');
                        self.endOfCmd()
                    }
                }

                if (args == null) {
                    args = {}
                }
                args.maxBuffer = Infinity;
                if (self.silent != true) {
                    console.log(preamble, 'spawn', cmd, args.join(", "))
                    console.log(preamble, '', cmd, args.join(" "))
                }
                var terminal = require('child_process').spawn(cmd, args);
                terminalRef = terminal;
                terminal.stdout.on('data', function onChildProc(data) {
                    // console.log('stdout: ' + data);
                    var logLine = prependToLog + ' stdout (cr): ' + data
                    if (self.silent != true) {
                        process.stdout.write(logLine);
                    }

                    appendToLog(logLine)

                    if (settings.fxEcho != null) {
                        settings.fxEcho(data.toString(), self.write);
                    }
                    //
                    if (settings.promptText != null && sh.includes(data.toString(), settings.promptText)) {
                        console.log('\t\t\t\t', 'lll', settings.fxCmds.length)
                        //
                        var fxCmds = settings.fxCmds
                        if (fxCmds != null) {
                            if (fxCmds.length > 0) {
                                self.write(fxCmds.pop()) //send most recent command
                                return;
                            }
                        }


                    }


                    if (settings.fxInput != null) {
                        settings.fxInput(self.write, data.toString());
                    }

                });
                terminal.stderr.on('data', function (data) {
                    var logLine = prependToLog + 'data: ' + data.toString()
                    if (data.hasOwnProperty('message') && data.message != null) {
                        logLine += ' ' + data.message
                    }
                    if (settings.fxEcho != null) {
                        settings.fxEcho(data.toString(), self.write);
                    }
                    if (self.silent != true) {
                        process.stdout.write(logLine);
                        console.error(logLine)
                    }
                    appendToLog(logLine, true)

                    if (settings.fxData != null) {
                        settings.fxData(logLine)
                    }
                    //console.log('stderr: ' + data);
                    //console.error(prependToLog+'child process error', error);
                    //+ sh.n

                });
                terminal.on('exit', function (code) {

                    var logLine = prependToLog + 'child process exited with code ' + code + '\n'
                    if (self.silent) {

                    } else {
                        process.stdout.write(logLine);
                    }

                    if (self.hasError) {
                        console.error(settings.logger.join("\n"))
                    }
                    appendToLog(logLine)
                    self.endOfCmd()

                });
                //error that terminated the child process
                terminal.on('error', function (error) {
                    self.hasError = true
                    var logLine = prependToLog + 'fatal stderr: ' + 'child process error ' +
                        error + ' ' + error.stack
                    //process.error.write(logLine);
                    if (self.silent != true) {
                        console.error(logLine)
                        appendToLog(logLine, true)
                    }

                    console.error(preamble, 'ERROR', 'spawn', cmd, args.join(", "))
                    console.error(logLine)

                    if (settings.fxEcho != null) {
                        settings.fxEcho(error.toString(), self.write);
                    }
                    var logLine = prependToLog + 'fatal stderr: ' + 'child process error ' + error.message
                    //process.error.write(logLine);
                    if (self.silent != true) {
                        console.error(logLine)
                    }
                    appendToLog(logLine, true)
                    self.endOfCmd()
                });


                self.terminal = terminal;
                self.write = function write() {
                    var args = sh.convertArgumentsToArray(arguments)
                    //args.push("\n")
                    terminal.stdin.write(args.join('') + "\n")
                    //console.log('... write', args)
                }
                self.write2 = function write() {
                    var args = sh.convertArgumentsToArray(arguments)
                    args.push("\n")
                    terminal.stdin.write(args.join(' '))
                    //console.log('... write', args)
                }

                function sendStdIn() {
                    console.log('Sending stdin to terminal');
                    //terminal.stdin.write('pwd')
                    write('dir')
                    // remove prev stdout listener
                    //out.removeAllListeners('data');
                    write('exit')
                    // new stdout listener
                    /*out.on('data', function (data) {
                     console.log('stdout: ' + data);
                     });*/
                    //writeT('safd')
                    write('cd')
                    // write('dir')
                    //terminal.stdin.write('dir\n')
                    //terminal.stdin.write('echo "Hello $USER. Your machine runs since:"\n');
                    // terminal.stdin.write('uptime\n');
                    // console.log('Ending terminal session');
                    //terminal.stdin.end();
                }

                if (settings.enableInput) {
                    console.log('input is enabled')
                    var sys = require("sys");

                    var stdin = process.openStdin();

                    stdin.addListener("data", function (d) {
                        // note:  d is an object, and when converted to a string it will
                        // end with a linefeed.  so we (rather crudely) account for that
                        // with toString() and then substring()
                        //console.log("you entered: [" +   d.toString().substring(0, d.length-1) + "]");
                        var input = d.toString().substring(0, d.length - 1)
                        //console.log('entered', input)
                        // self.write(d)
                        terminal.stdin.write(d)
                    });
                }

            }


            self.endOfCmd = function endOfCmd() {
                self.logOutputToFile();
                //console.log('....', 'endOfCmd',self.callback!=null,
                //    self.settings.fxCallback!=null)
                if (self.callback != null) {
                    self.callback()
                    return; //do not call fxCallback too
                }
                ;
                if (self.settings.fxCallback != null) {
                    self.settings.fxCallback();
                }

                if (self.settings.fxCallback == null) {
                    console.log('warning, no fxCallback defined')
                }
            }

            self.logOutputToFile = function logOutputToFile() {
                if (self.settings.storeOutputToFile != true) {
                    return
                }
                //var content = JSON.stringify(self.log);
                var logOutputToFileSettings = self.settings.logSettings;
                //settings.dir = 'job'
                //sh.writeFile2(self.settings.origCmd+'.output.txt',
                //    content, logOutputToFileSettings)
                var content = settings.logger.join();
                var logFileName = self.settings.origCmd + '.output.txt'
                sh.writeFile2(logFileName,
                    content, logOutputToFileSettings)
                //sh.writeFile2(self.output_filename_preamble + self.log.cmd+'output.json', content, logOutputToFileSettings)
            }
        }

        /**
         * Bulk save the contents of many log runners
         * @param contents
         * @param fileSettings
         */
        CommandRunner.log = function (contents, fileSettings) {
            var content = contents;
            if (contents instanceof Array) {
                var content = contents.join();
            }
            sh.writeFile2('',
                content, fileSettings)
            //sh.writeFile2(self.output_filename_preamble + self.log.cmd+'output.json', content, logOutputToFileSettings)

        }

        function testCallingCommands() {
            //
            //

            var json = {}
            json.cmd = 'asdfasdf'
            json.args = ['bad cmnd']
            var fxCallbackTestComplete = function fxCallbackTestComplete() {
                console.log('done')
                // cmd.logOutput();
            }
            var cmd = new CommandRunner();
            // cmd.launchCmd(json.cmd, json.args, fxCallbackTestComplete)
            cmd.logOutput = true


            var json = {}
            json.cmd = 'node emailTest.js'
            json.args = [4, 5, 6]
            json.cmd = 'node'// emailTest.js'
            json.args = ['emailTest.js', 4, 5, 6]
            var fxCallbackTestComplete = function fxCallbackTestComplete() {
                console.log('done')
            }
            var cmd = new CommandRunner();
            cmd.launchCmd(json.cmd, json.args, fxCallbackTestComplete)
            cmd.logOutput = true
        }


        sh.async = function async(items, fxAction, fxDone, concurrency) {
            var async = require('async');

            //var imdbs = [];
            if (sh.isString(items)) {
                items = sh.splitStrIntoArray(items)
            }

            if (items.length == 0) {
                sh.callIfDefined(fxDone);
            }
            concurrency = sh.dv(concurrency, 1);
            async.forEachLimit(items, concurrency, function processEachTest(item, fxInteration) {
                //console.log('look at', item)
                fxAction(item, fxInteration);
            }, function allTestFinished(err) {
                if (err) {
                    console.log(err)
                }
                ;
                sh.callIfDefined(fxDone);
            });

        }

    }

    defineCallingCommands();


    function defineTime() {

        sh.time = {}
        sh.time.diff = function diff(a, b, ms ) {
            if ( b == null ) {
                b = new Date();
            }
            var diff = b.getTime() - a.getTime()
            if ( diff > ms ) { //+ ms <  ) {
                return true
            }
            return false;
        };
        sh.time.diff2 = function diff(a, secs ) {
            var  b = new Date();
            var diff = b.getTime() - a.getTime()
            if ( diff > secs * 1000 ) { //+ ms <  ) {
                return true
            }
            return false;
        };

        sh.time.diffLessThanSecs = function diffLessThanSecs(a, secs ) {
            var  b = new Date();
            var diff = b.getTime() - a.getTime()
            if ( diff < secs * 1000 ) { //+ ms <  ) {
                return true
            }
            return false;
        }

        sh.time.secs = function howManySecodsHavePastSince(a, b, ms ) {
            if ( b == null ) {
                b = new Date();
            }
            var diff = b.getTime() - a.getTime()
            diff = diff/1000;
            return diff;
        };

    }
    defineTime();


    if (typeof exports === 'undefined') {
        exports = {}
        exports.isNode = false;
        //must be in browser
    }
    exports.shelpers = helper;
    helper.includes = includes;
    helper.removeFromArray = removeFromArray;
    helper.replace = replace;
    helper.includes2 = includes2;
    helper.endsWith = endsWith;
    helper.startsWith = startsWith;
    helper.log = log;
    helper.callIfDefined = callIfDefined;
    helper.remove_win_newlines = remove_win_newlines;
    helper.stripBadFiles = stripBadFiles;
    helper.replaceBackslash = replaceBackslash
    helper.stripSpecialChars = stripSpecialChars;
    helper.convertArgumentsToArray = convertArgumentsToArray;
    helper.splitStrIntoArray = splitStrIntoArray;
    helper.convertStringToArray = convertStringToArray;
    helper.strip = strip;
    helper.removeSubString = removeSubString
    helper.combineLines = combineLines;


    helper.lLog = lLog;
    helper.sLog = sLog;
    helper.requiredParam = requiredParam;
    helper.requiredParamOneOf = requiredParamOneOf;
    helper.readFile = readFile;
    helper.copyFile2 = copyFile2;
    helper.readFileLinesAsArray = readFileLinesAsArray;
    helper.writeFile = writeFile;
    helper.writeFile2 = writeFile2;
    helper.writeFileToTrash = writeFileToTrash;
    helper.fileExists = fileExists;
    helper.checkFileMTime = checkFileMTime;
    helper.dirname = dirname;
    helper.deleteFile = deleteFile;

    helper.copyFile = copyFile;
    helper.getLinesFromFile = getLinesFromFile;
    helper.getFilesInDirectory = getFilesInDirectory;
    helper.isDirectory = isDirectory;
    helper.openFiles = openFiles;
    helper.getFileName = getFileName;
    helper.getPath = getPath;
    helper.makePathIfDoesNotExist = makePathIfDoesNotExist;
    helper.mkdirp = makePathIfDoesNotExist;
    helper.fs.clearDir = clearDir;
    helper.fs.rmrf = rmrf;
    helper.getUserHome = getUserHome;
    helper.makePath = makePath;

//array
    helper.forceArray = forceArray;
    helper.isArray = isArray;
    helper.isString = isString;
    helper.isObject = isObject;
    helper.isFunction = isFunction;
    helper.arrayFilterByProp = arrayFilterByProp;
    helper.arrayCollectProp = arrayCollectProp;
    helper.clone = clone
    helper.clone2 = clone2;
    helper.arrayCondenseArrayByProp = arrayCondenseArrayByProp;
    helper.joinn = joinn

    helper.error = error

    helper.urlLink = urlLink

    helper.assert = assert

    helper.traceResult = traceResult;
    helper.traceResultNamed = traceResultNamed;

    helper.waitXSecs = waitXSecs;
    helper.wait1Sec = wait1Sec;
    helper.logLater = logLater;


    helper.defaultValue = defaultValue;
    helper.dv = defaultValue;
    helper.mergeObjects = mergeObjects;

    helper.sortArrayByField = sortArrayByField;
    helper.each = each;

    helper.eachHelper = eachHelper;

    helper.timeElapsed = timeElapsed
    helper.getTimeStamp = getTimeStamp
    helper.getTime = getTime;

    helper.paren = paren;
    helper.quote = q;
    helper.unquote = unquote;
    helper.q = q;
    helper.qq = qq;

    helper.bracket = bracket;
    helper.br = br;
    helper.brn = brn;
    helper.newline = newline;
    helper.n = newline;
    helper.tab = "\t";
    helper.toJSON = toJSON;
    helper.toJSONString = toJSONString;
    helper.safeProp = safeProp;

    helper.capitalize = capitalize
    helper.toHTMLStr = toHTMLStr
    helper.toJSONStrX = toJSONStrX
    helper.toHTMLJSON = {}
    helper.toHTMLJSON.styles = styles;

    helper.getArrayContentBetween =
        helper.isCommentLine = isCommentLine;
    helper.getContentBetween = getContentBetween;

    helper.getNodeArguments = getNodeArguments;

    helper.tests = {}
    helper.GoThroughEach = GoThroughEach;
    helper.tests.testGoThroughEach = testGoThroughEach;

    helper.dictMakeByName = dictMakeByName;
    helper.DictArray = DictArray;
    helper.tests.testDictArray = testDictArray;
    helper.tests.writeFile2Test = writeFile2Test

    helper.removeProps = removeProps;
    if ( helper.str == null ) {
        helper.str = {}
    }
    helper.str.https = 'https://'
    helper.str.http = 'http://'
    helper.https = 'https://'
    helper.http = 'http://'
    helper.html = {};
    helper.html.makeLink = makeLink;
    helper.html.wrapInHTMLTag = wrapInHTMLTag;

    helper.urls = {}
    helper.urls.makeRelative = makeRelative
    helper.urls.removeProtocol = removeProtocol;
    helper.urls.getSubDomain = getSubDomain;
    helper.urls.isAbsUrl = isAbsUrl;
//Strings
    helper.caseInsensitiveComparison = caseInsensitiveComparison;
    helper.cICompare = caseInsensitiveComparison;
    helper.insert = insert;

    helper.newTimer = newTimer;
    helper.EasyTimer = EasyTimer;
    helper.CommandRunner = CommandRunner;

    helper.splitStringOnQuotes = splitStringOnQuotes
    helper.toCamelCase = toCamelCase;

    helper.toLowerCaseFirstChar = toLowerCaseFirstChar;
    helper.toUpperCaseFirstChar = toUpperCaseFirstChar
    helper.unwrap = unwrap;
    helper.unWrap = unwrap
    helper.isWrapped = isWrapped
    helper.eachProp = eachProp


    helper.isWin = isWin;
    helper.isMac = isMac;
    helper.isNull = isNull;

    function defineIterationHelpers() {

    }
    defineIterationHelpers();


//used by browser/node.js agnostic scripts
//todo: add more robust solution
    helper.isNode = true
    helper.isBrowser = false
    if (typeof require !== 'undefined') {}
    else {
        helper.isBrowser = true
        helper.isNode = false
    }


    var shelpers = sh;
    window.sh = sh;
    /*
     for (var i=0;i<cars.length;i++)
     {
     document.write(cars[i] + "<br>");
     }
     */

    if ( isNode ) {
        if (module.parent == null) {
            function runTests(){
                testEachProp()
                return;
                //helper.tests.testDictArray()
                //helper.tests.writeFile2Test();
            }

            runTests();
        }
    }

})();