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

    function defineBasics() {
        sh.defaultValue = function defaultValue(input, ifNullUse) {
            if (input == null) {
                return ifNullUse
            }
            return input;
        }
        sh.dv = sh.defaultValue;


        function convertArgumentsToArray(_arguments) {
            var args = Array.prototype.slice.call(_arguments, 0);
            return args
        }
        sh.convertArgumentsToArray = convertArgumentsToArray;



        function toJSONString(o, printJSON) {
            printJSON = sh.defaultValue(printJSON, false)
            var json = JSON.stringify(o, "\t", "\t")
            if (printJSON) {
                console.log(json)
            }
            return json;
        }

        sh.toJSONString = toJSONString;


        function callIfDefined(fx) {
            var args = convertArgumentsToArray(arguments)
            args = args.slice(1, args.length)

            if (fx == undefined)
                return args[0];


            // console.debug('args', tojson(args))
            return fx.apply(null, args)
            //return;
        }

        sh.callIfDefined = callIfDefined;


        function q(text, escapeQuote) {
            if (escapeQuote == true) {
                return "\'" + text + "\'"
            }
            return "'" + text + "'"
        }

        sh.q = q;

    }
    defineBasics();

    function defineErrors() {
        sh.errors = {}


        /**
         * Simple log, show prototype (class) and method name
         */
        sh.sLog = function sLog() {
            var args = sh.convertArgumentsToArray(arguments[0])



            var stackTrace = sh.errors.getStackTrace()
            var calls = stackTrace.split("\n");
            var trueCall = calls[4]
            var prototypeName = calls[5]

            function getS(s) {
                if ( s == null ) {
                    return '';
                }
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
    }
    defineErrors();




if (typeof exports === 'undefined') {
    exports = {}
    exports.isNode = false;
    //must be in browser
}
exports.shelpers = helper;

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