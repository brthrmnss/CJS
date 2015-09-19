/**
 * Created by user on 8/2/15.
 */

/**
 * This is a mini server, that allows users to
 * append to notes
 *
 * Expects everest to be running.
 */


var sh = require('shelpers').shelpers;
var shelpers = require('shelpers');

var express = require('express');
var config = global.config;



/**
 * Created by user on 7/30/15.
 */
var sh = require('shelpers').shelpers;
var shelpers = require('shelpers');
var EasyRemoteTester = shelpers.EasyRemoteTester;

var port = 4444

function EvernoteHelperware() {
    var p = EvernoteHelperware.prototype;
    p = this;
    var self = this;

    /**
     * Setup middleware and routes
     * @param url
     * @param appCode
     */
    p.start = function start(url, appCode) {


        var custom = true
        var expressHttpsHelper = require('./../../nodejs-ssl-example-master/expressHttpsHelper.js')
        expressHttpsHelper = expressHttpsHelper.expressHttpsHelper;
        var express = require("express");
        var app = express();

        function setupApp() {
            var bodyParser = require('body-parser');
            app.use(bodyParser());



            //Add middleware for cross domains
            app.use(function(req, res, next) {
                res.header("Access-Control-Allow-Origin", "*");
                res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
                next();
            });

            //app.post('/append_named', self.appendNoteNamed);
            app.get('/say', self.say)
            self.setupSession();

        //    if ( custom == false )
         //       app.listen(port)

            return app;
        }

        if ( custom ) {
            expressHttpsHelper(port,port+1, setupApp)
        } else {

        }




    }

    self.setupSession = function setupSession() {
        setTimeout(function x() {
            self.test();
        }, 50)
    }

    function defineRoutes() {

        self.say = function sayRoute(req, res ) {
            var query = req.query;
            var text = req.query.text;
            var rate = req.query.rate;
            var voice = req.query.voice;
            var json = {}
            json.status = 'ok'

            self.speak(function result(body) {
                res.json(json);
            }, text , rate, voice);
        }


        p.speak = function (fx, text, rate, voice) {
            var child_process = require('child_process');
            var gb = "say "
            voice = sh.dv(voice, 'Ryan')
            gb += ' '+'-v ' + voice +' ';
            gb += ' '+sh.qq(text) +' ';
            if ( rate != null ) {
                gb += ' ' + '-r ' + rate + ' ';
            }

            if ( sh.isWin() ) {
                //windows
                gb = 'cscript "C:\Program Files\Jampal\ptts.vbs" -r +10';
            }

            //gb += ' '+sh.qq(text) +' ';
            //gb += ' '+'-r' + rate +' ';
            //df -k /tmp | tail -1 | tr -s ' ' | cut -d' ' -f5
            child_process.exec(gb, function (err, stdout, stderr) {
                /*var output = stdout;
                 if (sh.includes(output, 'G')) {
                 output = output.slice(0, -1)
                 }
                 ;
                 var freeGb = parseInt(output);
                 if (self.settings.min_gb != null &&
                 self.settings.min_gb > freeGb) {
                 console.log('not enough free space available')
                 fx(false)
                 return;
                 }*/

                fx(true);
                //self.t.cb();
                // 'stdout' here is a string containing the things printed by 'df'
                console.log('done speaking', text )//, 'free space')
            });
        }

    }
    defineRoutes();

    p.test = function test() {
        var baseUrl = 'http://127.0.0.1:4445'
        var t = EasyRemoteTester.create('Test say basics',{showBody:false});
        var data = {};
        t.settings.baseUrl = baseUrl
        var urls = {};
        urls.notes = {};
        urls.say = t.utils.createTestingUrl('say')

        var t2 = t.clone('test a few voices notes');
        t2.getR(urls.say).with({text:'test'}).bodyHas('status').notEmpty()
        t2.getR(urls.say).with({text:'test', rate:20}).bodyHas('status').notEmpty()
        t2.getR(urls.say).with({text:'test', rate:350}).bodyHas('status').notEmpty()
        t2.getR(urls.say).with({text:'voice', voice:'Heather'}).bodyHas('status').notEmpty()
        return;

    }


    p.proc = function debugLogger() {
        if ( self.silent == true) {
            return
        }
        sh.sLog(arguments)
    }


}

exports.EvernoteHelperware = EvernoteHelperware;

if (module.parent == null) {
    var e = new EvernoteHelperware()
    e.start();
};



