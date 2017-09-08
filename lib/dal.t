Index: mptransfer/DAL/SQLListRestHelperServer/SQLLiteRestHelper.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/SQLListRestHelperServer/SQLLiteRestHelper.js	(revision )
+++ mptransfer/DAL/SQLListRestHelperServer/SQLLiteRestHelper.js	(revision )
@@ -0,0 +1,38 @@
+/**
+ * Created by morriste on 7/22/16.
+ */
+
+
+var Sequelize = require('sequelize')//.sequelize
+//var sqlite    = require('sequelize-sqlite').sqlite
+
+var sequelize = new Sequelize(
+    'database', 'username', '', {
+    dialect: 'sqlite',
+   // storage: 'file:data.db'
+    storage: 'data/data.db'
+})
+
+var Record = sequelize.define('Record', {
+    name: Sequelize.STRING,
+    quantity: Sequelize.INTEGER
+})
+
+var sync = sequelize.sync()
+sync
+    .done(function(a,b,c){
+        console.log('synced')
+
+
+        var rec = Record.build({ name: "sunny", quantity: 3 });
+        rec.save()
+            .error(function(err) {
+// error callback
+                alert('somethings wrong')
+            })
+        .done(function() {
+// success callback
+            console.log('inserted')
+        });
+    })
+
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.bak.b4.split2
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.bak.b4.split2	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.bak.b4.split2	(revision )
@@ -0,0 +1,1724 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+var querystring= require('querystring');
+var DalDbHelpers= require('./supporting/DalDbHelpers').DalDbHelpers; //why: database lib defined here
+var DalDashboardHelpers= require('./supporting/DalDashboardHelpers').DalDashboardHelpers; //why: database lib defined here
+var DalServerTestHelpers= require('./supporting/DalServerTestHelpers').DalServerTestHelpers; //why: database lib defined here
+var DalSyncRoutesHelpers= require('./supporting/DalSyncRoutesHelpers').DalSyncRoutesHelpers; //why: database lib defined here
+var DalBasicRoutesHelpers= require('./supporting/DalBasicRoutesHelpers').DalBasicRoutesHelpers; //why: database lib defined here
+
+
+function SQLSharingServer() {
+    var p = SQLSharingServer.prototype;
+    p = this;
+    var self = this;
+
+    p.init = function init(config) {
+        self.settings = {};     //store settings and values
+        self.data = {};
+        if (config) {
+            self.settings = config;
+        } else
+        {
+            var cluster_settings = rh.loadRServerConfig(true);
+        }
+        //self.settings.port = 3001;
+
+        self.settings.updateLimit = sh.dv(self.settings.updateLimit, 99+901);
+        self.server_config = rh.loadRServerConfig(true);  //load server config
+        self.settings.enableAutoSync = sh.dv(self.settings.enableAutoSync,true);
+
+        self.debug = {};
+        //self.debug.tableCascades = true; //show table info this stop
+        self.debug.jsonBugs = false;
+        self.handleTables();
+
+
+        if ( self.debug.tableCascades )
+            return;
+       // return;
+        self.app = express();   //create express server
+
+        //self.setupSecurity()
+
+        self.createRoutes();    //decorate express server
+        self.createSharingRoutes();
+
+        self.createDashboardRoutes();
+        self.createDashboardResources();
+
+        self.identify();
+
+        self.startServer()
+
+        self.connectToDb();
+        self.setupAutoSync();
+    }
+
+    p.handleTables = function handleTables() {
+        //return;
+        if ( self.settings.cluster_config.table ) {
+            self.settings.cluster_config.tables = self.settings.cluster_config.table;
+        }
+        if ( self.settings.cluster_config.tables == null )
+            return;
+
+        if ( self.settings.subServer) {
+            //asdf.g
+            return;
+        }
+
+        self.data.tableServers = [];
+        //return
+        var tables = sh.clone(self.settings.cluster_config.tables);
+        var mainTable = tables.pop();
+        self.settings.tableName = mainTable;
+        self.settings.topServer = true;
+
+
+
+        //in non-test mode, all are the same
+        var bconfig = self.utils.cloneSettings();
+        //sh.clone(self.settings);
+
+        /*
+         tables are tricky
+         in test mode, we are running app ports on same machine, so we
+         offset the port numbers  by the number of tables
+         tables, people, cars
+         a1,b3,c5
+
+         a1 a_car_2,
+         b3 b_car_4,
+         c5 c_car_6,
+
+         in prod mode, we offset each table by 1, so car is on port 1, people is on port 2
+         tables, people, cars
+         a1,b1,c1
+
+         a1 a_car_2,
+         b1 b_car_2,
+         c1 b_car_2,
+
+         have to update sub configuration
+         */
+        var tablePortOffset = 0;
+        sh.each(tables, function addServerForTable(k,tableName) {
+            //return
+
+            //var config = sh.clone(bconfig);
+            var config = self.utils.cloneSettings();
+           // var config = self.utils.detectCircularProblemsWith(self.settings)
+            var cloneablePeers = []; //clone peers so port increments do not conflict
+            sh.each(config.peerConfig.peers, function copyPeer(k,v) {
+                var p = {};
+                sh.mergeObjects2(v, p)
+                delete p.peers //remove recurse peers property
+                cloneablePeers.push(p)
+            })
+            config.peerConfig.peers = sh.clone(cloneablePeers)
+            if ( config.peerConfig == null ) {
+                var breakpoint =  {};
+            }
+            delete config.topServer;
+            var peerCount = config.peerConfig.peers.length; //why: offset in test mode by this many ports
+            var originalIp = config.ip
+            tablePortOffset += 1
+
+            config.port = null;
+            config.ip = self.utils.incrementPort(config.ip, tablePortOffset);
+            config.peerConfig.ip = self.utils.incrementPort(config.peerConfig.ip, tablePortOffset);
+            self.proc("\t\t", 'peer', config.name,tableName, config.ip)
+            var additionalOffset = 0;
+            //setup matching ip/port for peers
+            sh.each(config.peerConfig.peers, function setupMatchingPortForPeers(k,peer) {
+                if (tables.length==1) {
+                    //tablePortOffset -= 1
+                   // additionalOffset = -1
+                    //why: do not offset by 1 ... not sure why
+                }
+                peer.ip = self.utils.incrementPort(peer.ip, tablePortOffset+additionalOffset);
+                self.proc("\t\t\t", 'peer',tableName, peer.name, peer.ip)
+            });
+
+            if ( self.debug.tableCascades ) {
+                return;
+            }
+            config.subServer = true;
+            config.topServerIp = self.settings.ip;
+            config.tables = null;
+            config.table = null;
+            config.tableName = tableName;
+            var service = new SQLSharingServer();
+            if ( self.runOnce )
+                return
+            /* setTimeout(function makeServerLaterToTestInitError(_config) {
+
+             console.error('run later', _config.ip)
+
+             service.init(_config);
+             }, 2000, config)*/
+
+            setTimeout(function makeServerLaterToTestInitError(_config) {
+
+                console.error('run later', _config.ip)
+
+                //self.data.tableServers
+                service.init(_config);
+                service.data.tableServers = self.data.tableServers;
+            }, 500, config)
+
+            // self.runOnce = true
+            //service.init(config);
+            // var peerObj = service;
+            //c
+            self.data.tableServers.push(service);
+        });
+
+        // process.exit();
+        return;
+    }
+
+    p.setupSecurity = function setupSecuirty() {
+        if ( self.settings.password == null ) {
+            return;
+        }
+        //TODO: finish ... but will break everything
+        self.app.use(function block(req, res, next) {
+            var password = ''
+            if ( req.params)
+                password = sh.dv(req.params.password, password)
+            if ( req.query)
+                password = sh.dv(req.query.password, password)
+            if ( req.body)
+                password = sh.dv(req.body.password, password)
+
+            if ( password != self.settings.password ) {
+                console.error('blocked attemptX')
+                res.status(410)
+                res.send({"status":"high bandwidth"})
+                return;
+            }
+            res.header("Access-Control-Allow-Origin", "*");
+            res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
+            next();
+        });
+    }
+
+    DalDashboardHelpers(self)
+
+    p.createRoutes = function createRoutes() {
+        self.app.post('/upload', function (req, res) {});
+    }
+
+    p.startServer = function startServer() {
+        self.proc('startServer', self.settings.name, self.settings.port, self.settings.tableName )
+        if ( self.settings.port == null){
+            throw new Error('no port this will not launch ' +  self.settings.name)
+        }
+        self.app.listen(self.settings.port);
+        self.proc('started server on', self.settings.name, self.settings.port);
+    }
+
+    function defineAutoSync() {
+        p.setupAutoSync = function setupAutoSync(setTimeTo) {
+            if ( setTimeTo ) {
+                self.settings.syncTime = setTimeTo;
+            }
+            if ( setTimeTo === false ) {
+                self.settings.syncTime = 0;
+            }
+
+            if ( self.settings.syncTime > 0  && self.settings.enableAutoSync ) {
+                clearInterval(self.data.autoSyncInt)
+                self.data.autoSyncInt = setInterval(
+                    self.autoSync,
+                    self.settings.syncTime*1000 )
+
+            }
+            else
+            {
+                return;
+            }
+        }
+
+        p.autoSync = function autoSync() {
+            var incremental = true;
+            var  config = {};
+            config.skipPeer =  req.query.fromPeer;
+            self.pull( function syncComplete(result) {
+                //res.send('ok');
+                self.proc('auto synced...')
+            }, incremental, config );
+        }
+    }
+    defineAutoSync()
+
+    function defineRoutes() {
+        self.showCluster = function showCluster(req, res) {
+            res.send(self.settings);
+        };
+        self.showTable  = function showCluster(req, res) {
+            res.send('ok');
+        };
+
+
+        self.verifySync = function verifySync(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            self.pull2( function syncComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                res.send(result);
+            } );
+
+        };
+
+        self.syncIn = function syncIn(req, res) {
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            };
+            var incremental = false;
+            if ( req.originalUrl.indexOf('getTableDataIncre') != -1 ) {
+                incremental = true;
+            };
+
+            var synchronousMode = req.query.sync == "true";
+            var  config = {};
+            config.skipPeer =  req.query.fromPeer;
+            self.pull( function syncComplete(result) {
+                if ( synchronousMode == false ) {
+                    if ( sh.isFunction(res)){
+                        res(result);
+                        return;
+                    }
+                    res.send('ok');
+                }
+            }, incremental, config );
+
+            if ( synchronousMode ) {
+                res.send('ok');
+            }
+        };
+
+        self.syncReverse = function syncReverse(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var  config = {};
+            fromPeer = req.query.fromPeer;
+            config.skipPeer =  fromPeer;
+            if ( fromPeer == null ) {
+                throw new Error('need peer')
+            };
+            self.utils.forEachPeer(fxEachPeer, fxComplete);
+
+            function fxEachPeer(ip, fxDone) {
+                var config = {showBody:false};
+                /*if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                 fxDone()
+                 return;
+                 }*/
+                self.log('revsync', req.query.fromPeer);
+                self.utils.updateTestConfig(config)
+                config.baseUrl = ip;
+                var t = EasyRemoteTester.create('Sync Peer', config);
+                var urls = {};
+                urls.syncIn = t.utils.createTestingUrl('syncIn');
+                var reqData = {};
+                reqData.data =  0
+                t.getR(urls.syncIn).why('get syncronize the other side')
+                    .with(reqData).storeResponseProp('count', 'count')
+                // t.addSync(fxDone)
+                t.add(function(){
+                    fxDone()
+                    t.cb();
+                })
+                //fxDone();
+            }
+            function fxComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                if ( sh.isFunction(res)){
+                    res(result);
+                    return;
+                }
+                res.send(result);
+            }
+        };
+
+
+        /**
+         * Delete all deleted records
+         * Forces a sync with all peers to ensure errors are not propogated
+         * @param req
+         * @param res
+         */
+        self.purgeDeletedRecords = function purgeDeletedRecords(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var fromPeer = self.utils.getPeerForRequest(req);
+
+            var fromPeerChain = req.query.fromPeerChain;
+            fromPeerChain = sh.dv(fromPeerChain, fromPeer+(self.settings.name));
+
+            var config = {showBody:false};
+            self.utils.updateTestConfig(config);
+            //config.baseUrl = ip;
+            var t = EasyRemoteTester.create('Delete Purged Records', config);
+            var urls = {};
+
+            var secondStep = false;
+            if ( req.query.secondStep == 'true') {
+                secondStep = true
+            }
+
+            var reqData = {};
+            reqData.data =  0
+
+            if ( secondStep != true ) { //if this is first innovacation (not subsequent invocaiton on peers)
+                /*t.getR(urls.syncIn).why('get syncronize the other side')
+                 .with(reqData).storeResponseProp('count', 'count')
+                 // t.addSync(fxDone)
+                 t.add(function(){
+                 fxDone()
+                 t.cb();
+                 })*/
+
+                t.add(function step1_syncIn_allPeers(){
+                    self.syncIn(req, t.cb)
+                });
+                t.add(function step2_syncOut_allPeers(){
+                    self.syncReverse(req, t.cb)
+                });
+                t.add(function step3_purgeDeleteRecords_onAllPeers(){
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        var config = {showBody:false};
+                        config.baseUrl = ip;
+                        self.utils.updateTestConfig(config)
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep =  true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerIp = self.settings.ip;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone()
+                            return;
+                        }
+                        urls.purgeDeletedRecords = t2.utils.createTestingUrl('purgeDeletedRecords');
+                        urls.purgeDeletedRecords += self.utils.url.appendUrl(self.utils.url.from(ip))
+                        t2.getR(urls.purgeDeletedRecords).why('...')
+                            .with(reqData)
+                        t2.add(function(){
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+
+
+
+                    // self.syncReverse(req, t.cb)
+                });
+
+
+            } else {
+                //sync from all other peers ... ?
+                //skip the peer that started this sync ? ...
+
+                /*t.add(function step1_syncIn_allPeers(){
+                 self.syncIn(req, t.cb, req.query.fromPeer)
+                 });
+                 t.add(function step2_syncOut_allPeers(){
+                 self.syncReverse(req, t.cb,  req.query.fromPeer)
+                 });*/
+                t.add(function step1_updateAll_OtherPeers() {
+                    var skipPeer = req.query.fromPeer;
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone()
+                            return;
+                        };
+
+                        var config = {showBody: false};
+                        self.utils.updateTestConfig(config);
+                        config.baseUrl = ip;
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep = true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        reqData.xPath = sh.dv(reqData.xPath, '')
+                        reqData.xPath += '_'+reqData.fromPeer
+
+                        urls.syncIn = t2.utils.createTestingUrl('syncIn');
+                        urls.syncReverse = t2.utils.createTestingUrl('syncReverse');
+                        urls.purgeDeletedRecords = t2.utils.createTestingUrl('purgeDeletedRecords');
+                        urls.purgeDeletedRecords += self.utils.url.appendUrl(self.utils.url.from(ip))
+                        t2.getR(urls.syncIn).why('...')
+                            .with(reqData)
+                        t2.getR(urls.syncReverse).why('...')
+                            .with(reqData)
+                        t2.getR(urls.purgeDeletedRecords).why('...')
+                            .with(reqData)
+                        t2.add(function () {
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+                });
+            }
+
+            t.add(function step4_purgeRecordsLocally(){
+                self.dbHelper2.purgeDeletedRecords( recordsDeleted);
+
+                function recordsDeleted() {
+                    var result = {}
+                    result.ok = true;
+                    res.send(result)
+                }
+            });
+
+        }
+
+        /**
+         * Do an action on all nodes in cluster.
+         * @param req
+         * @param res
+         */
+        self.atomicAction = function atomicAction(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var fromPeer = self.utils.getPeerForRequest(req);
+            if ( fromPeer == '?' ){
+                fromPeer = self.settings.name;
+            }
+            //if fromPeer not in list .... drop request ...
+            var fromPeerChain = req.query.fromPeerChain;
+            fromPeerChain = sh.dv(fromPeerChain, fromPeer+(self.settings.name));
+
+            var config = {showBody:false};
+            config.silent = true
+            self.utils.updateTestConfig(config);
+            //config.baseUrl = ip;f
+            var tOuter = EasyRemoteTester.create('Commit atomic action', config);
+            var urls = {};
+
+            var secondStep = false;
+            if ( req.query.secondStep == 'true') {
+                secondStep = true
+            }
+            var allowRepeating = true;
+
+            var reqData = {};
+            reqData.data =  0
+            var records = req.query.records;
+            var actionType = req.query.type;
+            var level =  reqData.level
+            if ( level == null ) {
+                level = 0
+            }
+            if ( actionType == 'update' ) {
+                if ( records == null || records.length == 0 ) {
+                    var result = {}
+                    result.status = false
+                    result.msg = 'no records sent ... cannot update'
+                    res.status(410)
+                    res.send(result)
+                    return
+
+                }
+            }
+
+
+            if ( actionType == null ) {
+                throw new Error('need action type')
+            }
+
+
+            var nestedResults = {};
+            //if ( secondStep != true || allowRepeating ) { //if this is first innovacation (not subsequent invocaiton on peers)
+
+            /*t.add(function step1_syncIn_allPeers(){
+             self.syncIn(req, t.cb)
+             });
+             t.add(function step2_syncOut_allPeers(){
+             self.syncReverse(req, t.cb)
+             });*/
+            tOuter.add(function sendActionToAllPeers(){
+                self.utils.forEachPeer(fxEachPeer, fxComplete);
+                function fxEachPeer(ip, fxDone) {
+                    if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                        fxDone();   return;   }
+                    var config = {showBody:false};
+                    config.baseUrl = ip;
+                    config.silent = true
+                    self.utils.updateTestConfig(config)
+                    var t2 = EasyRemoteTester.create('Commit atomic on peers', config);
+                    var reqData = {};
+                    reqData.secondStep =  true; //prevent repeat of process
+                    reqData.level = level;
+                    reqData.records = req.query.records;
+                    reqData.type = req.query.type;
+                    reqData.fromPeer = self.settings.name;
+                    reqData.fromPeerIp = self.settings.ip;
+                    reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+
+                    console.error('step 1', req.level, reqData.fromPeer, ip)
+                    urls.atomicAction = t2.utils.createTestingUrl('atomicAction');
+                    urls.atomicAction += self.utils.url.appendUrl(
+                        self.utils.url.from(ip),
+                        {type:actionType})
+                    t2.getR(urls.atomicAction).why('...')
+                        .with(reqData)
+                        .fxDone(function onReqDone(data) {
+                            if ( actionType == 'count') {
+                                nestedResults[data.name]=data;
+                            }
+                            return data;
+                        })
+                    t2.add(function(){
+                        fxDone()
+                        t2.cb();
+                    })
+                }
+                function fxComplete(ok) {
+
+                    tOuter.cb();
+                }
+            });
+
+
+            // } else {
+
+
+            //
+            if (actionType == 'sync' && false ) { //this just takes longer,
+                //not gaurnateed to work
+                tOuter.add(function step1_updateAll_OtherPeers() {
+
+
+                    var skipPeer = req.query.fromPeer;
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone(); return; };
+
+                        var config = {showBody: false};
+                        config.silent = true
+                        self.utils.updateTestConfig(config);
+                        config.baseUrl = ip;
+                        console.error('step 2', req.level,self.settings.name, ip)
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep = true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        reqData.xPath = sh.dv(reqData.xPath, '')
+                        reqData.xPath += '_'+reqData.fromPeer
+                        reqData.records = req.query.records;
+                        reqData.type = req.query.type;
+                        urls.atomicAction = t2.utils.createTestingUrl('atomicAction');
+                        urls.atomicAction += self.utils.url.appendUrl(
+                            self.utils.url.from(ip),
+                            {type:actionType})
+                        t2.getR(urls.atomicAction).why('...')
+                            .with(reqData)
+                        t2.add(function () {
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+                        tOuter.cb();
+                    }
+                });
+            }
+            //}
+
+            tOuter.add(function step4_purgeRecordsLocally(){
+
+                var logOutInput = false;
+                if ( logOutInput) {   console.error('done', req.query.type, self.settings.name) }
+                if ( req.query.type == 'update') {
+                    self.dbHelper2.upsert(records, function upserted() {
+                        console.error('done2', req.query.type, self.settings.name)
+                        //  t.cb();
+                        var result = {}
+                        result.ok = true;
+                        self.proc('return', self.settings.name)
+                        res.send(result)
+                    });
+                } else if ( req.query.type == 'sync') {
+                    var incremental = true;
+                    var  config = {};
+                    config.skipPeer =  req.query.fromPeer;
+                    self.pull( function syncComplete(result) {
+                        res.send('ok');
+                    }, incremental, config );
+                } else if ( req.query.type == 'count') {
+
+                    var incremental = true;
+                    var  config = {};
+                    config.skipPeer =  req.query.fromPeer;
+                    //todo-reuse real count
+
+                    sh.isEmptyObject = function isEmptyObject(obj) {
+                        return !Object.keys(obj).length;
+                    }
+
+                    self.dbHelper2.getDBVersion(function onNext(version) {
+                        self.dbHelper2.countAll(function gotAllRecords(count){
+                            self.count = count;
+                            var result = {
+                                name:self.settings.name,
+                                v:self.version,
+                                count:count}
+                            if ( ! sh.isEmptyObject(nestedResults)) {
+                                result.nestedResults = nestedResults
+                            }
+                            res.send(result);
+                        }, {});
+                    },{})
+
+                }
+                else if (req.query.type == 'delete') {
+
+                    var ids = [records[0].id_timestamp];
+
+                    self.Table.findAll({where:{id_timestamp:ids}})
+                        .then(function onX(objs) {
+                            if ( logOutInput) {      console.error('done2', req.query.type, self.settings.name) }
+                            //throw new Error('new type specified')
+                            self.Table.destroy({where:{id_timestamp:{$in:ids}}})
+                                .then(
+                                function upserted() {
+                                    //  t.cb();
+                                    var result = {}
+                                    if ( logOutInput) {
+                                        console.error('done3', req.query.type, self.settings.name)
+                                    }
+                                    result.ok = true;
+                                    res.send(result)
+                                })
+                                .error(function() {
+                                    asdf.g
+                                });
+                        }).error(function() {
+                            //  asdf.g
+                        })
+
+                } else {
+                    throw new Error('... throw it ex ...')
+                }
+                //self.dbHelper2.purgeDeletedRecords( recordsDeleted);
+
+                /* function recordsDeleted() {
+                 var result = {}
+                 result.ok = true;
+                 res.send(result)
+                 }*/
+            });
+        }
+
+        self.getCount = function getCount(req, res) {
+            //count records in db with my source
+            /*
+             q: do get all records? only records with me as source ..
+             // only records that are NOT related to user on other side
+             */
+            var dateSet = new Date()
+            var dateInt = parseInt(req.query.global_updated_at)
+            var dateSet = new Date(dateInt);
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                //throw new Error('why are you couunting things ? 8/3/2016') //Answer -- during a sync don't want to go backwards
+                query.where = {global_updated_at:{$gt:dateSet}};
+                query.order = ['global_updated_at',  'DESC']
+            }
+
+            self.proc('who is request from', req.query.peerName);
+
+            self.dbHelper2.getDBVersion(function onNext() {
+                self.dbHelper2.countAll(function gotAllRecords(count){
+                    self.count = count;
+                    var result = {
+                        count:count,
+                        v:self.version,
+                        name:self.settings.name
+                    }
+                    console.error('776-what is count', result, query)
+                    res.send(result);
+                    if ( req.query.global_updated_at != null ) {
+                        var dbg = dateSet ;
+                        return;
+                    }
+                }, query);
+            },{})
+
+
+        };
+
+        self.getSize = function getSize(cb) {
+            self.dbHelper2.count(function gotAllRecords(count){
+                self.count = count;
+                self.size = count;
+                sh.callIfDefined(cb)
+            })
+        }
+
+        self.getRecords = function getRecords(req, res) {
+            res.statusCode = 404
+            res.send('not found')
+            return; //Blocked for performance reasons
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(dateInt);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            query.order = ['global_updated_at',  'DESC']
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                res.send(recs);
+            } )
+        };
+        self.getNextPage = function getRecords(req, res) {
+            var query = {}
+            query.where  = {};
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(req.query.global_updated_at);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            if ( self.data.breakpoint_catchPageRequests ) {
+                console.error('at breakpoint_catchPageRequests')
+            }
+            query.order = ['global_updated_at',  'DESC']
+            query.limit = self.settings.updateLimit;
+            if ( req.query.offset != null ) {
+                query.offset = req.query.offset;
+            }
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                if ( self.data.breakpoint_catchPageRequests ) {
+                    console.error('at breakpoint_catchPageRequests')
+                }
+                //Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aAs` AS `aA` WHERE `aA`.`global_updated_at` > '2016-08-02 18:29:30.000 +00:00' ORDER BY `global_updated_at`, `DESC` LIMIT 1000;
+                //2016-08-02T18:29:30.976Z
+                res.send(recs);
+            } )
+        };
+
+        p.createSharingRoutes = function createSharingRoutes() {
+            self.app.get('/showCluster', self.showCluster );
+            self.app.get('/showTable/:tableName', self.showTable );
+            self.app.get('/getTableData/:tableName', self.syncIn);
+
+            self.app.get('/verifySync', self.verifySync);
+            self.app.get('/getTableData', self.syncIn);
+
+            self.app.get('/getTableDataIncremental', self.syncIn);
+            self.app.get('/count', self.getCount );
+            self.app.get('/getRecords', self.getRecords );
+            self.app.get('/getNextPage', self.getNextPage );
+            self.app.get('/verifySync', self.verifySync );
+
+            self.app.get('/syncReverse', self.syncReverse );
+            self.app.get('/syncIn', self.syncIn);
+
+            self.app.get('/purgeDeletedRecords', self.purgeDeletedRecords);
+            self.app.get('/atomicAction', self.atomicAction);
+            //self.app.get('/syncRecords', self.syncRecords );
+        };
+    }
+    defineRoutes();
+
+    function defineSyncRoutines() {
+        self.sync = {};
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull = function pullFromPeers(cb, incremental) {
+
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function syncPeer(peerIp, fxDoneSync) {
+                    self.proc('syninc peer', peerIp );
+                    self.sync.syncPeer( peerIp, function syncedPeer() {
+                        fxDoneSync()
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records synced');
+                    sh.callIfDefined(cb)
+                })
+            return;
+            /*
+             async
+             syncpeer
+             get count after udapted time, or null
+             offset by 100
+             get count afater last updated time
+             next
+             res.send('ok');
+             */
+        };
+
+
+
+        /**
+         * Get count ,
+         * offset by 1000
+         * very count is same
+         * @param ip
+         * @param cb
+         */
+        self.sync.syncPeer = function syncPeer(ip, cb, incremental) {
+            var config          = {showBody:false};
+            config.baseUrl      = ip;
+            self.utils.updateTestConfig(config)
+            var t               = EasyRemoteTester.create('Sync Peer', config);
+
+            var urls            = {};
+
+            urls.getCount       = t.utils.createTestingUrl('count');
+            urls.getRecords     = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage    = t.utils.createTestingUrl('getNextPage');
+            /*
+             urls.getCount += self.utils.url.appendUrl(self.utils.url.from(ip))
+             urls.getRecords   += self.utils.url.appendUrl(self.utils.url.from(ip))
+             urls.getNextPage    += self.utils.url.appendUrl(self.utils.url.from(ip))
+             */
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName    = self.settings.peerName;
+            if (incremental) {
+                if (self.dictPeerSyncTime[ip] != null) {
+                    reqData.global_updated_at = self.dictPeerSyncTime[ip]
+                }
+                reqData.incremental = true;
+            }
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+
+            t.add(function getRecordCount(){
+                var y = t.data.count;
+                t.cb();
+            });
+
+            t.recordsAll = [];
+            t.recordUpdateCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+            t.offset = 0;
+
+            /* t.add(function syncRecourds(){
+             t.quickRequest( urls.getRecords,
+             'get', result, reqData);
+             function result(body) {
+             t.assert(body.length!=null, 'no page');
+             t.records = body;
+             t.recordsAll = t.recordsAll.concat(body);
+             t.cb();
+             };
+             });
+
+             t.add(function filterNewRecordsForPeerSrc(){
+             t.cb();
+             })
+             t.add(function upsertRecords(){
+             self.dbHelper2.upsert(t.records, function upserted(){
+             t.cb();
+             })
+             })
+
+             */
+
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'__'+peerName
+            function getUrlDebugTag(t) {
+                var urlTag = '?a'+'='+actorsStr+'&'+
+                    'of='+t.offset
+                return urlTag
+            }
+
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+                        //reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+
+                        t.addNext(function upsertRecords(){
+                            self.dbHelper2.upsert(body, function upserted(resultsUpsert){
+                                t.lastRecord_global_updated_at = self.utils.latestDate(t.lastRecord_global_updated_at, resultsUpsert.last_global_at)
+                                t.cb();
+                            });
+                        });
+                        //do query for records ... if can't find them, then delete them?
+                        //search for 'deleted' record updates, if my versions aren't newer than
+                        //deleted versions, then delete thtme
+                        t.addNext(function deleteExtraRecords(){
+                            //self.dbHelper2.upsert(t.records, function upserted(){
+                            t.cb();
+                            //});
+                        });
+
+                        /*t.addNext(function verifyRecords(){
+                         var query = {};
+                         var dateFirst = new Date(body[0].global_updated_at);
+                         if ( body.length > 1 ) {
+                         var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                         } else {
+                         dateLast = dateFirst
+                         }
+                         query.where = {
+                         global_updated_at: {$gte:dateFirst},
+                         $and: {
+                         global_updated_at: {$lte:dateLast}
+                         }
+                         };
+                         query.order = ['global_updated_at',  'DESC'];
+                         self.dbHelper2.search(query, function gotAllRecords(recs){
+                         var yquery = query;
+                         var match = self.dbHelper2.compareTables(recs, body);
+                         if ( match != true ) {
+                         t.matches.push(t.iterations)
+                         self.proc('match issue on', t.iterations, recs.length, body.length)
+                         }
+                         t.cb();
+                         } )
+                         })*/
+                        t.addNext(getRecordsUntilFinished)
+                    }
+
+                    t.recordUpdateCount += body.length;
+                    t.iterations  += 1
+                    if (t.firstPage == null ) t.firstPage = body; //store first record for update global_update_at
+                    //no must store last one
+
+                    //t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function countRecords(){
+                self.dbHelper2.count(  function upserted(count){
+                    self.size = count;
+                    t.cb();
+                })
+            })
+            t.add(function verifySync(){
+                self.lastUpdateSize = t.recordUpdateCount;
+                //self.lastRecords = t.recordsAll;
+                // var bugOldDate = [t.firstPage[0].global_updated_at,t.lastRecord_global_updated_at];
+                //if ( self.lastUpdateSize > 0 )
+                //    self.dictPeerSyncTime[ip] = t.firstPage[0].global_updated_at;
+                if (t.lastRecord_global_updated_at )
+                    self.dictPeerSyncTime[ip] = t.lastRecord_global_updated_at
+
+                sh.callIfDefined(cb)
+            })
+
+        }
+
+
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull2 = function verifyFromPeers(cb, incremental) {
+            var resultsPeers = {};
+            var result = true;
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function verifySyncPeer(peerIp, fxDoneSync) {
+                    self.proc('verifying peer', peerIp );
+                    self.sync.verifySyncPeer( peerIp, function syncedPeer(ok) {
+                        resultsPeers[peerIp] = ok
+                        if ( ok == false ) {
+                            result = false;
+                        }
+                        fxDoneSync(ok )
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records verified');
+                    sh.callIfDefined(cb, result, resultsPeers)
+                })
+            return;
+        };
+
+
+
+        /**
+         * Ask for each peer record, starting from the bottom
+         * @param ip
+         * @param cb
+         */
+        self.sync.verifySyncPeer = function verifyPeer(ip, cb, incremental) {
+            var config = {showBody:false};
+            config.baseUrl = ip;
+            self.utils.updateTestConfig(config);
+            var t = EasyRemoteTester.create('Sync Peer', config);
+            var urls = {};
+
+
+            urls.getCount = t.utils.createTestingUrl('count');
+            urls.getRecords = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage = t.utils.createTestingUrl('getNextPage');
+
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName = self.settings.peerName;
+            reqData.fromPeer = self.settings.peerName;
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+
+            t.add(function getRecordCount(){
+                var recordCount = t.data.count;
+                t.cb();
+            });
+
+            t.recordsAll = [];
+            t.recordCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+            t.offset = 0;
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'__'+peerName
+            function getUrlDebugTag(t) {
+                var urlTag = '?a'+'='+actorsStr+'&'+
+                    'of='+t.offset
+                return urlTag
+            }
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+                        // reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.addNext(function verifyRecords(){
+                            var query = {};
+                            var dateFirst = new Date(body[0].global_updated_at);
+                            if ( body.length > 1 ) {
+                                var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                            } else {
+                                dateLast = dateFirst
+                            }
+                            query.where = {
+                                global_updated_at: {$gte:dateFirst},
+                                $and: {
+                                    global_updated_at: {$lte:dateLast}
+                                }
+                            };
+                            query.order = ['global_updated_at',  'DESC'];
+                            self.dbHelper2.search(query, function gotAllRecords(recs){
+                                var yquery = query;
+                                var match = self.dbHelper2.compareTables(recs, body);
+                                if ( match != true ) {
+                                    t.matches.push(t.iterations)
+                                    self.proc('match issue on', self.settings.name, peerName, t.iterations, recs.length, body.length)
+                                }
+                                t.cb();
+                            } )
+                        })
+                        t.addNext(getRecordsUntilFinished)
+                    }
+                    t.recordCount += body.length;
+                    t.iterations  += 1
+                    t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function filterNewRecordsForPeerSrc(){
+                t.ok = t.matches.length == 0;
+                t.cb();
+            })
+            t.add(function deleteAllRecordsForPeerName(){
+                t.cb();
+            })
+            /* t.add(function countRecords(){
+             self.dbHelper2.count(  function upserted(count){
+             self.size = count;
+             t.cb();
+             })
+             })*/
+            t.add(function verifySync(){
+                self.proc('verifying', self.settings.name, self.count, ip, t.recordCount)
+                //    self.lastUpdateSize = t.recordsAll.length;
+                //  if ( t.recordsAll.length > 0 )
+                //        self.dictPeerSyncTime[ip] = t.recordsAll[0].global_updated_at;
+                sh.callIfDefined(cb, t.ok)
+            })
+
+        }
+    }
+    defineSyncRoutines();
+
+    /**
+     * why: identify current machine in config file to find peers
+     */
+    p.identify = function identify() {
+        var peers = self.settings.cluster_config.peers;
+        if ( self.settings.cluster_config == null )
+            throw new Error ( ' need cluster config ')
+
+
+        if ( self.settings.port != null &&
+            sh.includes(self.settings.ip, self.settings.port) == false ) {
+            self.settings.ip = null; //clear ip address if does not include port
+        };
+
+        if ( self.settings.port == null && self.settings.ip  ) {
+            //why: get port from ip address
+            var portIpAndPort = self.settings.ip;
+            if ( portIpAndPort.indexOf(':') != -1 ) {
+                var ip = portIpAndPort.split(':')[0];
+                var port = portIpAndPort.split(':')[1];
+                if ( sh.isNumber(port) == false ){
+                    throw new Error(['bad port ', ip, port].join(' '))
+                }
+                self.settings.ip = ip;
+                if ( ip.split('.').length !=4 && ip != 'localhost'){
+                    throw new Error(['invalid ip ', ip, port].join(' '))
+                }
+                self.settings.port = port;
+            };
+        };
+
+        var initIp = self.settings.ip;
+        self.settings.ip = sh.dv(self.settings.ip, '127.0.0.1:'+self.settings.port); //if no ip address defined
+        if ( self.settings.ip.indexOf(':')== -1 ) {
+            self.settings.ip = self.settings.ip+':'+self.settings.port;
+        }
+
+        if ( initIp == null ) {
+            var myIp = self.server_config.ip;
+            //find who i am from peer
+            self.proc('searching for ip', myIp)
+            sh.each(peers, function findMatchingPeer(i, ipSection){
+                var peerName = null;
+                var peerIp = null;
+
+                peerName = i;
+                peerIp = ipSection;
+
+                if ( sh.isObject(ipSection)) {
+                    sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                        peerName = name;
+                        peerIp = ip;
+                    })
+                }
+
+                if ( self.settings.peerName != null ) {
+                    if (self.settings.peerName == peerName) {
+                        foundPeerEntryForSelf = true;
+                        self.settings.name = peerName;
+                        return;
+                    }
+                } else {
+                    if (self.settings.ip == peerIp) {
+                        foundPeerEntryForSelf = true;
+                        self.settings.name = peerName;
+                        return;
+                    }
+                }
+                var peerIpOnly = peerIp;
+                if ( peerIp.indexOf(':') != -1 ) {
+                    peerIpOnly = peerIp.split(':')[0];
+                };
+                if ( peerIpOnly == myIp ) {
+                    self.proc('found your thing...')
+                    self.settings.ip = peerIpOnly
+                    if ( peerIp.indexOf(':') != -1 ) {
+                        var port = peerIp.split(':')[1];
+                        self.settings.port = port;
+                    }
+                    self.settings.name = peerName;
+                    self.settings.cluster_config.tables
+                    var y = [];
+                    return;
+                } else {
+                    // self.proc('otherwise',peerIpOnly);
+                }
+            });
+            self.server_config
+        }
+
+        self.proc('ip address', self.settings.ip);
+
+        self.settings.dictPeersToIp = {};
+        self.settings.dictIptoPeers = {};
+        self.settings.peers = [];
+
+        var foundPeerEntryForSelf = false;
+
+        console.log(self.settings.name, 'self peers', peers);
+        sh.each(peers, function findMatchingPeer(i, ipSection){
+            var peerName = null;
+            var peerIp = null;
+            sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                peerName = name;
+                peerIp = ip;
+            })
+            if ( sh.isString(ipSection) && sh.isString(i) ) { //peer and ip address method
+                if ( ipSection.indexOf(':') ) {
+                    peerName = i;
+                    peerIp = ipSection;
+                    if ( peerIp.indexOf(':') != -1 ) {
+                        peerIp = peerIp.split(':')[0];
+                    };
+                }
+            }
+            if ( self.settings.peerName != null ) {
+                if (self.settings.peerName == peerName) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+                /*
+                 var peerConfig = ipSection;
+                 if (self.settings.peerName == peerConfig.name ) {
+                 foundPeerEntryForSelf = true;
+                 self.settings.name = peerName;
+                 return;
+                 }
+                 */
+            }
+            else {
+                if (self.settings.ip == peerIp) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+            }
+            if ( ipSection.name ){
+                var peerConfig = ipSection;
+                var peerName = peerConfig.name;
+                var peerIp = peerConfig.ip;
+            }
+            self.proc('error no matched config',peerName, peerIp, self.settings.ip); //.error('....', );
+            self.settings.peers.push(peerIp);
+            self.settings.dictPeersToIp[peerName]=peerIp;
+            self.settings.dictIptoPeers[peerIp]=peerName;
+        });
+
+        if ( self.settings.peerConfig ) { //why: let cluster loader set config and send no peers
+            //bypass searchc
+            foundPeerEntryForSelf = true;
+            self.settings.name = self.settings.peerConfig.name;
+        }
+
+
+        self.proc(self.settings.peerName, 'foundPeerEntryForSelf', foundPeerEntryForSelf, self.settings.peers.length,  self.settings.peers);
+
+        if ( foundPeerEntryForSelf == false ) {
+            throw new Error('did not find self in config')
+        }
+
+        if (  self.settings.peers.length == 0 ) {
+            throw new Error('init: not enough peers ' + self.settings.name, peers)
+        }
+    }
+
+    function defineDatabase() {
+
+        p.connectToDb = function connectToDb() {
+            if ( self.settings.dbConfigOverride) {
+                var Sequelize = require('sequelize')//.sequelize
+                if ( self.settings.tableName == null || self.settings.tableName == '' ) {
+                    asdf.g
+                }
+                var sequelize = new Sequelize('database', 'username', '', {
+                    dialect: 'sqlite',
+                    storage: 'db/'+[self.settings.name,self.settings.tableName].join('_')+'.db',
+                    logging:self.settings.dbLogging
+                })
+                self.sequelize = sequelize;
+                self.createTableDefinition();
+            } else {
+                var sequelize = rh.getSequelize(null, null, true);
+                self.sequelize = sequelize;
+                self.createTableDefinition();
+            }
+
+
+        }
+
+        /**
+         * Creates table object
+         */
+        p.createTableDefinition = function createTableDefinition() {
+            var tableSettings = {};
+            if (self.settings.force == true) {
+                tableSettings.force = true
+                tableSettings.sync = true;
+            }
+            tableSettings.name = self.settings.tableName
+            if ( self.settings.tableName == null ) {
+                throw new Error('need a table name')
+            }
+            //tableSettings.name = sh.dv(sttgs.name, tableSettings.name);
+            tableSettings.createFields = {
+                name: "", desc: "", user_id: 0,
+                imdb_id: "", content_id: 0,
+                progress: 0
+            };
+
+
+            self.settings.fields = tableSettings.createFields;
+
+            var requiredFields = {
+                source_node: "", id_timestamp: "",
+                updated_by_source:"",
+                global_updated_at: new Date(), //make another field that must be changed
+                version: 0, deleted: true
+            }
+            sh.mergeObjects(requiredFields, tableSettings.createFields);
+            tableSettings.sequelize = self.sequelize;
+            SequelizeHelper.defineTable(tableSettings, tableCreated);
+
+            function tableCreated(table) {
+                console.log('table ready')
+                //if ( sttgs.storeTable != false ) {
+                self.Table = table;
+
+                setTimeout(function () {
+                    sh.callIfDefined(self.settings.fxDone);
+                }, 100)
+
+            }
+        }
+
+        DalDbHelpers(self)
+    }
+    defineDatabase();
+
+    function defineUtils() {
+        if ( self.utils == null ) self.utils = {};
+
+        self.utils.cloneSettings = function cloneSettings() {
+            var y = self.settings;
+            var clonedSettings = {};
+            sh.each(y, function dupeX(k,v) {
+                //what
+                try {
+                    var c = sh.clone(v);
+                    clonedSettings[k] = c;
+                } catch ( e ) {
+                    if ( self.debug.jsonBugs )
+                        console.error('problem json copy with', k)
+
+
+                    clonedSettings[k] = v; //ugh ...
+                }
+
+            })
+
+
+            // function recursivee
+            return clonedSettings;
+        }
+
+        self.utils.detectCircularProblemsWith =
+            function detectCircularProblemsWith(obj, dictPrev, path) {
+                if ( dictPrev == null ) {
+                    dictPrev = {};
+                    dictPrev.arr = [];
+                    path = ''
+                }
+                //why will detect circular references in json object (stringify)
+                var clonedSettings = {};
+                sh.each(obj, function dupeX(k,v) {
+                    try {
+                        dictPrev[v] = k;
+                        dictPrev.arr.push(v)
+                        var c = sh.clone(v);
+                        clonedSettings[k] = c;
+
+                    } catch ( e ) {
+                        path += '.'+k
+                        if ( self.debug.jsonBugs )
+                            console.error('problem json copy with', k, v, path)
+                        dictPrev[v] = k;
+                        dictPrev.arr.push(v)
+                        if ( sh.isObject( v )) {
+                            var prev = dictPrev[v];
+                            var hasItem = dictPrev.arr.indexOf(v)
+
+                            if ( prev != null || hasItem != -1  ) {
+                                if ( dictPrev.culprintFound ) {
+                                    console.log('---> is culprit ', path, k, prev)
+                                    return;
+                                }
+                                console.log('this is culprit ', path, k, prev)
+                                // return;
+                                dictPrev.culprintFound = true;
+                            }
+
+                            sh.each(v, function dupeX(k1,innerV) {
+                                console.log('  ... |> ', k1)
+                                var pathRecursive = path +'.'+k1;
+                                dictPrev[innerV] = k1;
+                                dictPrev.arr.push(innerV)
+                                self.utils.detectCircularProblemsWith(innerV, dictPrev,pathRecursive)
+
+                            })
+
+                        }
+
+                        //clonedSettings[k] = v; //ugh ...
+                    }
+                })
+                // function recursivee
+                return clonedSettings;
+            }
+
+
+
+        self.utils.latestDate = function compareTwoDates_returnMostRecent(a,b) {
+            if ( a == null )
+                return b;
+            if (a.getTime() > b.getTime() ) {
+                return a;
+            }
+            return b;
+        }
+
+        self.utils.incrementPort = function incrementPort(ip, offset) {
+            var obj = self.utils.getPortAndIp(ip);
+
+
+            var newIp =  obj.ip + ':' + (obj.port+offset);
+            return newIp;
+        }
+
+        self.utils.getPortAndIp = function getPortAndIp (ip) {
+            var obj = {}
+            var portIpAndPort = ip;
+            if ( portIpAndPort.indexOf(':') != -1 ) {
+                var ip = portIpAndPort.split(':')[0];
+                var port = portIpAndPort.split(':')[1];
+                if ( sh.isNumber(port) == false ){
+                    throw new Error(['bad port ', ip, port].join(' '))
+                }
+
+                if ( ip.split('.').length !=4 && ip != 'localhost'){
+                    throw new Error(['invalid ip ', ip, port].join(' '))
+                }
+
+                obj.port = parseInt(port)
+                obj.ip = ip; //parseInt(ip)
+            };
+            return obj;
+        }
+
+        self.utils.forEachPeer = function fEP(fxPeer, fxDone) {
+
+            sh.async(self.settings.peers,
+                fxPeer, function allDone() {
+                    sh.callIfDefined(fxDone);
+                })
+            return;
+        }
+
+        self.utils.getPeerForRequest = function getPeerForRequest(req) {
+            var fromPeer = req.query.fromPeer;
+            if ( fromPeer == null ) {
+                throw new Error('need peer')
+            };
+            return fromPeer;
+        }
+
+
+        self.utils.peerHelper = {};
+        self.utils.peerHelper.getPeerNameFromIp = function getPeerNameFromIp(ip) {
+            var peerName = self.settings.dictIptoPeers[ip];
+            if ( peerName == null ) {
+                throw new Error('what no peer for ' + ip);
+            }
+            return peerName;
+        }
+
+        /**
+         *
+         * Return true if peer matches
+         * @param ip
+         * @returns {boolean}
+         */
+        self.utils.peerHelper.skipPeer = function skipPeer(ipOrNameOrDict, ip) {
+            if ( ipOrNameOrDict == '?') {
+                return false;
+            }
+            var peerName = null
+            var peerIp = null;
+            var peerName = self.settings.dictIptoPeers[ipOrNameOrDict];
+            if ( peerName == null ) {
+                peerName = ipOrNameOrDict;
+                peerIp = self.settings.dictPeersToIp[peerName];
+                if ( peerName == null ) {
+                    throw new Error('bad ip....'  + ipOrNameOrDict)
+                }
+            } else {
+                peerIp = ipOrNameOrDict;
+            }
+
+            if ( peerIp == ip ) {
+                return true; //skip this one it matches
+            }
+
+            return false;
+        }
+
+        /**
+         * Update config to limit debugging information
+         * @param config
+         * @returns {*}
+         */
+        self.utils.updateTestConfig = function updateTestConfig(config) {
+            config = sh.dv(config, {});
+            config.silent = true;
+            self.settings.cluster_config.urlTimeout = sh.dv(self.settings.cluster_config.urlTimeout, 3000);
+            config.urlTimeout = self.settings.cluster_config.urlTimeout;
+            return config;
+        }
+
+    }
+    defineUtils();
+
+    function defineLog() {
+        self.log = function log() {
+            if ( self.listLog == null ) {
+                self.listLog = []
+            }
+            var args = sh.convertArgumentsToArray(arguments)
+            var str = args.join(' ')
+            str = self.listLog.length + '. ' + str;
+            self.listLog.push(str)
+        }
+    }
+    defineLog();
+
+    function defineUrl() {
+        //  var actorsStr = self.settings.name+'__'+peerName
+        function getUrlDebugTag(t) {
+            var urlTag = '?a'+'='+actorsStr+'&'+
+                'of='+t.offset
+            return urlTag
+        }
+
+        self.utils.url = {};
+        self.utils.url.appendUrl = function appendUrl() { //take array of objects adn add to url
+            var url = '?';
+            var queryObject = {};
+            var args = sh.convertArgumentsToArray(arguments)
+            sh.each(args, function processB(i, hsh){
+                sh.each(hsh, function processBx(k, v){
+                    queryObject[k] = v;
+                })
+            })
+            url +=  querystring.stringify(queryObject)
+            return url;
+        }
+        self.utils.url.from = function appendUrl(ip) { //take array of objects adn add to url
+            return self.utils.peerHelper.getPeerNameFromIp(ip)
+
+        }
+    }
+    defineUrl();
+
+    DalServerTestHelpers(self)
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.SQLSharingServer = SQLSharingServer;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+
+
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_augment.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_augment.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_augment.js	(revision )
@@ -0,0 +1,696 @@
+/**
+ * Created by user on 1/13/16.
+ */
+/**
+ * Created by user on 1/3/16.
+ */
+    /*
+    TODO:
+    Test that records are delete?
+    //how to do delete, have a delte colunm to sync dleet eitems
+     */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+var SQLSharingServer = require('./sql_sharing_server').SQLSharingServer;
+
+if (module.parent == null) {
+
+    var configOverride = {};
+    configOverride.mysql = {
+        "ip" : "127.0.0.1",
+        "databasename" : "yetidb",
+        //"user" : "yetidbuser",
+        //"pass" : "aSDDD545y^",
+        "port" : "3306"
+    };
+
+    rh.configOverride = configOverride;
+
+    //load confnig frome file
+    //peer has gone down ... peer comes back
+    //real loading
+    //multipe tables
+
+    //define tables to sync and time
+    //create 'atomic' modes for create/update and elete
+    var cluster_config = {
+        peers:[
+            {a:"127.0.0.1:12001"},
+            {b:"127.0.0.1:12002"}
+        ]
+    };
+
+    var topology = {};
+    var allPeers = [];
+    var config = {};
+    config.cluster_config = cluster_config;
+    config.port = 12001;
+    config.peerName = 'a';
+    config.tableName = 'aA';
+    config.fxDone = testInstances
+    config.dbConfigOverride=true
+    config.dbLogging=false
+    config.password = 'dirty'
+    var service = new SQLSharingServer();
+    service.init(config);
+    var a = service;
+    allPeers.push(service)
+    topology.a = a;
+
+    var config = sh.clone(config);
+    config.port = 12002;
+    config.peerName = 'b';
+    config.tableName = 'bA';
+    var service = new SQLSharingServer();
+    service.init(config);
+    var b = service;
+    allPeers.push(service)
+    topology.b = b;
+
+
+
+    function augmentNetworkConfiguration() {
+        if ( topology.augmentNetworkConfiguration) {
+            return;
+        }
+        topology.augmentNetworkConfiguration = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {c:"127.0.0.1:12003"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12003;
+        config.peerName = 'c';
+        config.tableName = 'cA';
+
+        var service = new SQLSharingServer();
+        service.init(config);
+        var c = service;
+        allPeers.push(service)
+        topology.c = c;
+        //c.linkTo({b:b});
+        b.linkTo({c:c})
+
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12004;
+        config.peerName = 'd';
+        config.tableName = 'dA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var d = service;
+        allPeers.push(service)
+        topology.d = d;
+        //d.linkTo({c:c});
+        b.linkTo({d:d})
+
+
+    }
+
+
+    function augmentNetworkConfiguration2() {
+        if ( topology.augmentNetworkConfiguration2) {
+            return;
+        }
+        topology.augmentNetworkConfiguration2 = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {e:"127.0.0.1:12005"}
+        ]
+        config.port = 12005;
+        config.peerName = 'e';
+        config.tableName = 'eA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var e = service;
+        allPeers.push(service)
+        topology.d.linkTo({e:e})
+
+
+    }
+
+
+    function testInstances() {
+        //make chain
+        var sh = require('shelpers').shelpers;
+        var shelpers = require('shelpers');
+        var EasyRemoteTester = shelpers.EasyRemoteTester;
+        var t = EasyRemoteTester.create('Test Channel Server basics',
+            {
+                showBody:false,
+                silent:true
+            });
+
+        //t.add(clearAllData())
+        clearAllData()
+        t.add(function clearRecordsFrom_A(){
+            a.test.destroyAllRecords(true, t.cb);
+        })
+
+        t.add(function clearRecordsFrom_B(){
+            b.test.destroyAllRecords(true, t.cb);
+        })
+        ResuableSection_verifySync()
+        t.add(function create100Records_A(){
+            a.test.createTestData(t.cb)
+        })
+
+        t.add(function aPing(){
+            //  b.test.destroyAllRecords(true, t.cb);
+            // b.ping();
+            t.cb();
+        })
+        t.add(function bPing(){
+            //  b.test.destroyAllRecords(true, t.cb);
+            t.cb();
+        })
+
+        t.add(function bPullARecords(){
+
+            b.pull(t.cb);
+        })
+
+        function ResuableSection_verifySync(msg, size) { //verifies size of both peers
+            if ( msg == null ) {
+                msg = ''
+            }
+            msg = ' ' + msg;
+            t.add(function getASize(){
+                a.getSize(t.cb);
+            })
+            t.add(function getBSize(){
+                b.getSize(t.cb);
+            })
+            t.add(function testSize(){
+                if ( size ) {
+                    t.assert(b.size == size, 'sync did not work (sizes different) a' + [a.size, size] + msg)
+                    t.assert(a.size == size, 'sync did not work (sizes different) b' + [b.size, size] + msg)
+                }
+                t.assert(b.size== a.size, 'sync did not work (sizes different)' + [b.size, a.size] + msg)
+                t.cb();
+            })
+        }
+
+        ResuableSection_verifySync('A and b should be same size', 100);
+
+        function ResuableSection_addRecord() {
+            t.add(function addNewRecord() {
+                a.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+            });
+        };
+        ResuableSection_addRecord();
+
+        var baseUrl = 'http://127.0.0.1:'+ b.settings.port;
+        var urls = {};
+
+        //do partial sync
+        //sync from http request methods
+        //batched sync
+        //remove batch tester
+        //cluster config if no config sent
+
+        function defineHTTPTestMethods() {
+            //var t = EasyRemoteTester.create('Test Channel Server basics',{showBody:false});
+            t.settings.baseUrl = baseUrl;
+            urls.getTableData = t.utils.createTestingUrl('getTableData');
+            urls.syncIn = t.utils.createTestingUrl('syncIn');
+
+            ResuableSection_addRecord();
+
+            t.getR(urls.getTableData).with({sync:false})
+                // .bodyHas('status').notEmpty()
+                .fxDone(function syncComplete(result) {
+                    return;
+                });
+
+            ResuableSection_verifySync();
+        }
+        defineHTTPTestMethods();
+
+
+        function define_TestIncrementalUpdate () {
+            urls.getTableData = t.utils.createTestingUrl('getTableDataIncremental');
+
+            t.getR(urls.getTableData).with({sync:false}) //get all records
+                .fxDone(function syncComplete(result) {
+                    return;
+                })
+            t.workChain.utils.wait(1);
+            ResuableSection_verifySync('All records are synced')
+            ResuableSection_addRecord(); //this record is new, will be ONLY record
+                //sent in next update.
+
+            t.addFx(function startBreakpoints() {
+                //this is not async ... very dangerous
+                topology.b.data.breakpoint = true;
+                topology.a.data.breakpoint_catchPageRequests = true;
+            })
+
+
+            t.getR(urls.getTableData).with({sync:false})
+                .fxDone(function syncComplete(result) {
+                    console.log('>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<')
+                    t.assert(b.lastUpdateSize==1, 'updated wrong # of records updated after pull ' + b.lastUpdateSize)
+
+                    return;
+                })
+
+
+            t.addFx(function removeBreakpoints() {
+                topology.b.data.breakpoint = false;
+                topology.a.data.breakpoint_catchPageRequests = false;
+
+            })
+
+
+            ResuableSection_verifySync()
+        }
+        define_TestIncrementalUpdate();
+
+
+
+        function define_TestDataIntegrity() {
+            urls.verifySync = t.utils.createTestingUrl('verifySync');
+            t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    t.assert(result.ok==true, 'data not integral ' + result.ok)
+                    return;
+                });
+        }
+        define_TestDataIntegrity();
+
+
+        function define_syncReverse() {
+            ResuableSection_addRecord();
+
+            t.add(function addNewRecord() {
+                b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+            });
+            t.add(function addNewRecord() {
+                b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+            });
+
+            urls.syncReverse = t.utils.createTestingUrl('syncReverse');
+
+
+            t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'?'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+            t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+            ResuableSection_verifySync()
+        };
+        define_syncReverse();
+        ;
+
+        /**
+         * Records need to be  marked as 'deleted'
+         * otherwise deletion doesn't count
+         * @param client
+         */
+        function forgetRandomRecordFrom(client) {
+            if ( client == null ) { client = b }
+            t.add(function forgetRandomRecord() {
+                client.test.forgetRandomRecord(t.cb);
+            });
+        }
+
+        function deleteRandomRecordFrom(client) {
+            if ( client == null ) { client = b }
+            t.add(function deleteRandomRecord() {
+                b.test.deleteRandomRecord(t.cb);
+            });
+        }
+
+        function syncIn() {
+
+            t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+        }
+        function syncOut() {
+            t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'a'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+        }
+        function syncBothDirections() {
+            syncIn()
+            syncOut()
+        }
+        function breakTest() {
+            t.addFx(function() {
+                asdf.g
+            })
+        }
+        function purgeDeletedRecords() {
+            urls.purgeDeletedRecords = t.utils.createTestingUrl('purgeDeletedRecords');
+            t.getR(urls.purgeDeletedRecords).with({fromPeer:'?'})
+                .fxDone(function purgeDeletedRecords_Complete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+
+                    return;
+                })
+        }
+
+
+        /**
+         * Deletes all data from all nodes
+         */
+        function clearAllData() {
+            t.workChain.utils.wait(1);
+            t.add(function () {
+                sh.async(allPeers,
+                    function(peer, fxDone) {
+                        // asdf.g
+                        peer.test.destroyAllRecords(true,  recordsDestroyed)
+                        function recordsDestroyed() {
+                            fxDone();
+                        }
+                    },
+                    function dleeteAll() {
+                        t.cb()
+                    } );
+            });
+            t.add(function () {
+                sh.async(allPeers,
+                    function(peer, fxDone) {
+                        // asdf.g
+                        peer.test.createTestData(  recordsCreated)
+                        function recordsCreated() {
+                            fxDone();
+                        }
+                    },
+                    function dleeteAll() {
+                        t.cb()
+                    } );
+            });
+        }
+
+        function inSyncAll() {
+            t.workChain.utils.wait(1);
+            t.add(function () {
+                sh.async(allPeers,
+                    function(peer, fxDone) {
+                        var t2 = EasyRemoteTester.create('TestInSync',
+                            {  showBody:false,  silent:true });
+                        var baseUrl = 'http://'+ peer.ip; //127.0.0.1:'+ b.settings.port;
+                        var urls = {};
+                        t2.settings.baseUrl = baseUrl;
+                        urls.verifySync = t.utils.createTestingUrl('verifySync');
+                        t2.getR(urls.verifySync).with(
+                            {sync:false,peer:'a'}
+                        )
+                            .fxDone(function syncComplete(result) {
+                                t2.assert(result.ok==true, 'data not inSync ' + result.ok);
+                                return;
+                            });
+                    },
+                    function dleeteAll() {
+                        t.cb()
+                    } );
+            });
+        }
+
+
+
+        function define_TestDataIntegrity2() {
+            forgetRandomRecordFrom();
+            t.workChain.utils.wait(1);
+            forgetRandomRecordFrom();
+            forgetRandomRecordFrom();
+            notInSync();
+            syncBothDirections()
+        }
+        define_TestDataIntegrity2();
+
+        function notInSync() {
+            t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    t.assert(result.ok==false, 'data is not supposed to be in sync ' + result.ok);
+                    return;
+                });
+        }
+        function inSync() {
+            t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                    return;
+                });
+        }
+        function defineBlockSlowTests() {
+            function define_ResiliancyTest() {
+                forgetRandomRecordFrom();
+                forgetRandomRecordFrom(a);
+                forgetRandomRecordFrom(a);
+                forgetRandomRecordFrom();
+                notInSync();
+                //notInSync();
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+            }
+            define_ResiliancyTest();
+
+            function define_ResiliancyTest_IllegallyChangedRecords() {
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                notInSync()
+                //resolve
+                syncBothDirections()
+
+                notInSync()//did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                syncBothDirections()
+                inSync();
+            };
+            define_ResiliancyTest_IllegallyChangedRecords();
+
+            function define_multipleNodes() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration()
+                    t.cb()
+                });
+                clearAllData();
+
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecord_skipUpdateTime() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                notInSync()
+                syncBothDirections()
+                notInSync(); //did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                syncBothDirections();
+                inSync();
+            };
+            define_multipleNodes();
+        }
+
+        defineBlockSlowTests()
+
+
+        function defineSlowTests2() {
+            function define_TestDeletes() {
+                syncBothDirections()
+                ResuableSection_verifySync()
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(topology.c);
+
+                purgeDeletedRecords();
+
+                inSync();
+
+            };
+            define_TestDeletes()
+
+            function define_TestDeletes2() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration2()
+                    t.cb()
+                });
+                clearAllData();
+
+                syncBothDirections()
+                ResuableSection_verifySync()
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(topology.c);
+                deleteRandomRecordFrom(topology.e);
+
+                //syncBothDirections();
+                purgeDeletedRecords();
+                /*t.add(function getRecord() {
+                 b.test.getRandomRecord(function (rec) {
+                 randomRec = rec;
+                 t.cb()
+                 });
+                 });
+                 t.add(function updateRecords() {
+                 randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+                 });*/
+                //  notInSync()
+                // syncBothDirections()
+                inSync();
+
+            };
+            define_TestDeletes2()
+        }
+        defineSlowTests2()
+
+
+
+        function define_TestHubAndSpoke() {
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration()
+                t.cb()
+            });
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration2()
+                t.cb()
+            });
+            clearAllData();
+
+
+            function addTimer(reason) {
+                t.add(function defineNewNodes() {
+                    if (t.timer  != null ) {
+                        var diff = sh.time.secs(t.timer)
+                        console.log('>');console.log('>');console.log('>');
+                        console.log(t.timerReason, 'time', diff);
+                        console.log('>');console.log('>');console.log('>');
+                    } else {
+
+                    }
+                    t.timerReason = reason;
+                    t.timer = new Date();
+                    t.workChain.utils.wait(1);
+                    t.cb()
+                });
+
+            }
+
+            addTimer('sync both dirs')
+            syncBothDirections()
+            addTimer('local sync')
+            ResuableSection_verifySync()
+            addTimer('deletes')
+            deleteRandomRecordFrom(b);
+            deleteRandomRecordFrom(b);
+            deleteRandomRecordFrom(topology.c);
+            deleteRandomRecordFrom(topology.e);
+
+            addTimer('purge all deletes')
+            //syncBothDirections();
+            purgeDeletedRecords();
+            /*t.add(function getRecord() {
+             b.test.getRandomRecord(function (rec) {
+             randomRec = rec;
+             t.cb()
+             });
+             });
+             t.add(function updateRecords() {
+             randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+             });*/
+            //  notInSync()
+            // syncBothDirections()
+            addTimer('insync')
+            inSync();
+            inSyncAll();
+            //TODO: Test sync on N
+            //check in sync on furthes node
+            addTimer('insyncover')
+
+        };
+        define_TestHubAndSpoke()
+
+       // breakTest()
+
+        //TODO: Add index to updated at
+
+        //test from UI
+        //let UI log in
+        //task page saeerch server
+
+        //account server
+        //TODO: To getLastPage for records
+
+        //TODO: replace getRecords, with getLastPage
+        //TODO: do delete, so mark record as deleted, store in cache,
+        //3x sends, until remove record from database ...
+
+        /*
+         when save to delete? after all synced
+         mark as deleted,
+         ask all peers to sync
+         then delete from database if we delete deleted nodes
+
+         do full sync
+         if deleteMissing -- will remove all records my peers do not have
+         ... risky b/c incomplete database might mess  up things
+         ... only delete records thata re marked as deleted
+         */
+
+        /*
+         TODO:
+         test loading config from settings object with proper cluster config
+         test auto syncing after 3 secs
+         build proper hub and spoke network ....
+         add E node that is linked to d (1 hop away)
+         */
+        /**
+         * store global record count
+         * Mark random record as deleted,
+         * sync
+         * remove deleted networks
+         * sync
+         * ensure record is gone
+         */
+
+        //Revisions
+    }
+}
+
+
+
Index: mptransfer/DAL/server_config.json
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/server_config.json	(revision )
+++ mptransfer/DAL/server_config.json	(revision )
@@ -0,0 +1,74 @@
+{
+  "frontend": {
+    "site_title":"bougie uploads",
+    "feedback_email":"local@test.com",
+    "login_port":33031,
+    "tracker_ip": "0",
+    "welcome":"..."
+  },
+  "scripts": [
+    "node_scripts/bitcoinorder_server2/invoice_service.js",
+    "`node_scripts/bitcoinorder_server/order_watcher/invoice_watcher.js",
+    "node_scripts/credentials_server/user_server.js",
+    "node_scripts/file_server/file_server.js",
+    "`node_scripts/reedem_server/redeem_server.js",
+    "node_scripts/search_server/search_server2.js",
+    "`node_scripts/invite_server/invite_server.js",
+    "node_scripts/registration_server/registration_server.js",
+    "node_scripts/bitcoin_wallet/electrum_wallet_manager.js"
+  ],
+  "global":{
+    "dir_login_consumer_sessions":"XhomeX/ritv/sessions_login_consumer_api",
+    "title":"BougieUpload.cr",
+    "feedback_email":"yyy@hotmail.com"
+  },
+  "downloads":{
+    "dir_downloads":"/media/incoming"
+  },
+  "mysql":{
+    "ip" : "127.0.0.1",
+    "databasename" : "yetidb",
+    "user" : "yetidbuser",
+    "pass" : "aSDDD545y^",
+    "port" : "3306"
+  },
+  "files":{
+    "port":33037,
+    "default_server":"http://127.0.0.1:33037/api/get_content/",
+    "default_server2":"*",
+    "url_verify":"http://127.0.0.1:33037/api/verify/",
+    "url_test":"http://127.0.0.1:33037/api/test/",
+    "full_path":"true",
+    "testMode_2Servers":true
+  },
+  "search":{
+    "port":33310,
+    "show_search_results":true,
+    "login":true
+  },
+  "bitcoinAPI":{
+  },
+  "electrum":{
+    "dir":"",
+    "__dir":"stores wallet in dir of electrum folder",
+    "___use_electrum_client":false
+  },
+  "loginAPI":{
+    "port":33031,
+    "dir_sessions":"XhomeX/ritv/dir_sessions",
+    "warning":"this is the main port for the whole server"
+  },
+  "debug_startup":false,
+  "email":{
+    "xservice":"mailbox.org",
+    "username":"rmanager@mailbox.org",
+    "password":"Runningman6",
+    "port":"587",
+    "send_emails_after_registration":true,
+    "enable_forgot_password":true,
+    "require_activation":true
+  },
+  "registration_server":{
+    "port":18001
+  }
+}
Index: mptransfer/DAL/sql_sharing_server/supporting/DalServerTestHelpers.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DalServerTestHelpers.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DalServerTestHelpers.js	(revision )
@@ -0,0 +1,236 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+
+function DalServerTestHelpers(_self) {
+    var p = DalServerTestHelpers.prototype;
+    p = this;
+    var self = this;
+    if ( _self ) {
+        self = _self;
+        p = _self
+    }
+
+    /**
+     * why: identify current machine in config file to find peers
+     */
+
+    function defineDatabase() {
+
+        function defineTestUtils() {
+            //why: utils for testing.
+            p.linkTo = function linkTo(peerToAdd, reset ) {
+                var reset = sh.dv(reset, false);
+                if ( reset ) {
+                    self.settings.cluster_config.peers = []
+                }
+
+
+                var foundSelf = false;
+
+
+                var peersToAdd = sh.forceArray(peerToAdd);
+                sh.each(peersToAdd, function (k, peer)  {
+
+
+                    sh.each(peer, function (peerName, ipAddOrPeer)  {
+                        var peer = ipAddOrPeer;
+                        if ( sh.isNumber(ipAddOrPeer) ) {
+                            // return;
+                            //peer =
+                        }
+                        else if ( peer.settings != null ) {
+                            var peer = ipAddOrPeer.settings.ip;
+                        }
+
+                        if ( ipAddOrPeer == self.settings.ip) {
+                            foundSelf = true;
+                        }
+                        //peersToAdd[k] = peer;
+                        //self.settings.cluster_config.peers[peerName] = peer;
+                        var newPeer = {}
+                        newPeer[peerName] = peer;
+                        self.settings.cluster_config.peers.push(newPeer);
+                    })
+                })
+
+                if ( foundSelf == false) {
+                    //self.settings.cluster_config.peers[self.settings.name] = self.settings.ip;
+                    var myPeer = {}
+                    myPeer[self.settings.name] = self.settings.ip;
+                    self.settings.cluster_config.peers.push(myPeer);
+                }
+                self.identify();
+            }
+
+
+        }
+        defineTestUtils();
+
+
+        function defineTest() {
+            self.test = {};
+            self.test.createTestData = function createTestData(cb, deleteFirst) {
+                GenerateData = shelpers.GenerateData;
+                var gen = new GenerateData();
+                var model = gen.create(100, function (item, id, dp) {
+                    item.name = id;
+                    // item.id = id;
+                    item.source_node = self.settings.peerName;
+                    item.desc = GenerateData.getName();
+                    item.global_updated_at = new Date();
+                    item.id_timestamp = (new Date()).toString() + '_' + Math.random();
+                });
+
+                var results = model;
+
+
+                if ( deleteFirst != false ) {
+                    self.test.destroyAllRecords(true, createTestData);
+                } else {
+                    createTestData();
+                }
+
+                function createTestData() {
+                    self.Table.bulkCreate(results).then(
+                        function (results) {
+                            // Notice: There are no arguments here, as of right now you'll have to...
+                            if (cb != null) cb(results);
+                            return;
+                        }).catch(function (err) {
+                            console.log(err)
+                            // exit();
+                            setTimeout(function () {
+                                throw err;
+                            }, 5);
+                        });
+                }
+
+            }
+            self.test.destroyAllRecords = function (confirmed, fx) {
+                if (confirmed != true) {
+                    return false;
+                }
+
+                var queryDelete = {}
+                if ( self.data.isSQLlite ) {
+
+                }
+               // queryDelete = {id:{$ne: -1}}
+                self.Table.destroy({where: queryDelete}).then(function () {
+                    self.proc('all records destroyed')
+                    self.count = 0;
+
+                    self.dbHelper2.getDBVersionAndCount(fxUpdatedCount)
+
+                    function fxUpdatedCount(v, count) {
+                        self.proc('size', v, count)
+                        if ( count != 0 ) {
+                            throw new Error('could not delete')
+                        }
+                        sh.callIfDefined(fx);
+                    }
+
+
+                })
+
+            }
+
+
+            self.test.forgetRandomRecord = function (fx) {
+                /*Array.prototype.randsplice = function(){
+                 var ri = Math.floor(Math.random() * this.length);
+                 var rs = this.splice(ri, 1);
+                 return rs;
+                 }
+                 var obj = self.lastRecords.randsplice();
+
+                 if ( obj.length ==1 ) {
+                 obj = obj[0];
+                 }*/
+                //this will pull the other side records
+
+
+
+                self.test.getRandomRecord(function onGotRecord(rec) {
+                    self.dbHelper2.deleteRecord(rec.id, fx);
+                })
+
+                /*self.dbHelper2.count(function gotAllRecords(count){
+                 self.count = count;
+                 self.size = count;
+                 sh.callIfDefined(cb)
+                 })*/
+
+            };
+
+            self.test.deleteRandomRecord = function (fx) {
+                self.test.getRandomRecord(function onGotRecord(rec) {
+                    rec.deleted = true;
+                    rec.updated_by_source = self.name;
+                    //self.dbHelper2.deleteRecord(rec.id, fx); //this line will break the test
+                    self.dbHelper2.updateRecord(rec, fx)
+
+                })
+            };
+
+            self.test.getRandomRecord = function (fx) {
+
+                var query = {};
+                query.where  = {};
+
+                self.dbHelper2.countAll(function gotCount(count){
+                    self.count = count;
+                    //offset by count?
+                    query.order = ['global_updated_at',  'DESC']
+                    query.limit = 1;
+                    query.offset = parseInt(count*Math.random());
+                    self.dbHelper2.search(query, function gorRandomRecord(recs){
+                        var obj = recs[0];
+                        sh.callIfDefined(fx, obj)
+                    } , false);
+                }, query);
+
+
+            }
+
+            self.test.saveRecord = function saveRecord(obj, fx) {
+                obj.save().then(function gotAllRecords(recs){
+                        sh.callIfDefined(fx, obj)
+                    }
+                )
+
+            }
+
+
+
+
+
+        }
+        defineTest()
+
+    }
+    defineDatabase();
+
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.DalServerTestHelpers = DalServerTestHelpers;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+}
\ No newline at end of file
Index: mptransfer/DAL/readme
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/readme	(revision )
+++ mptransfer/DAL/readme	(revision )
@@ -0,0 +1,186 @@
+This is server
+Arch is micro-service based
+Each subfolder contains a service
+main-server.js - handles login, and registration
+http://localhost:33031/
+
+
+/usr/sbin/node file_server.js
+10.211.55.4 ip address
+Sun, 03 Jan 2016 19:48:36 GMT body-parser deprecated bodyParser: use individual json/urlencoded middlewares at ../credentials_server/api/CredentialConsumerAPI.js:25:17
+Sun, 03 Jan 2016 19:48:36 GMT body-parser deprecated undefined extended: provide extended option at ../credentials_server/node_modules/body-parser/index.js:85:29
+starting LoginAPIConsumerService ./sessions_test
+LoginConsumerAPI Server Started on 33037
+http://localhost:33037
+contents <Buffer 27 75 73 65 20 73 74 72 69 63 74 27 3b 0a 0a 76 61 72 20 75 72 6c 20 3d 20 72 65 71 75 69 72 65 28 27 75 72 6c 27 29 0a 20 20 2c 20 50 61 74 68 20 3d ... >
+resolved /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/sequelize/lib/sequelize.js false
+making model file
+undefined { get: [Function: get],
+  put: [Function: put],
+  post: [Function: post],
+  delete: [Function: delete_] } '/api/file'
+10.211.55.4
+ ip address free space
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER NOT NULL auto_increment , `name` VARCHAR(65), `creatorip` VARCHAR(15), `creator` VARCHAR(65), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER NOT NULL auto_increment , `name` VARCHAR(65), `creatorip` VARCHAR(15), `creator` VARCHAR(65), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER NOT NULL auto_increment , `invite_code` VARCHAR(65), `level` ENUM('free user', 'invited', 'neophite', 'paid user', 'admin'), `email` VARCHAR(65), `forumname` VARCHAR(65), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(15), `creator` VARCHAR(65), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER NOT NULL auto_increment , `invite_code` VARCHAR(65), `level` ENUM('free user', 'invited', 'neophite', 'paid user', 'admin'), `email` VARCHAR(65), `forumname` VARCHAR(65), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(15), `creator` VARCHAR(65), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(65), `password` VARCHAR(65), `email` VARCHAR(65), `level` ENUM('free user', 'invited', 'neophite', 'paid user', 'admin'), `status` ENUM('active', 'pending', 'disabled', 'suspended'), `lastloginip` VARCHAR(15), `lastlogindate` DATETIME, `paidExpiryDate` DATETIME, `lastPayment` VARCHAR(65), `identifier` VARCHAR(15), `datecreated` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(65), `password` VARCHAR(65), `email` VARCHAR(65), `level` ENUM('free user', 'invited', 'neophite', 'paid user', 'admin'), `status` ENUM('active', 'pending', 'disabled', 'suspended'), `lastloginip` VARCHAR(15), `lastlogindate` DATETIME, `paidExpiryDate` DATETIME, `lastPayment` VARCHAR(65), `identifier` VARCHAR(15), `datecreated` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): CREATE TABLE IF NOT EXISTS `file` (`id` INTEGER(10) NOT NULL auto_increment , `originalFilename` VARCHAR(255), `userId` VARCHAR(255), PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `file` (`id` INTEGER(10) NOT NULL auto_increment , `originalFilename` VARCHAR(255), `userId` VARCHAR(255), PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `file`
+Executing (default): SHOW INDEX FROM `file`
+Connection has been established successfully.
+Executing (default): SELECT count(*) AS `count` FROM `file` AS `file`;
+Executing (default): INSERT INTO `file` (`id`,`originalFilename`,`userId`) VALUES (NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL),(NULL,NULL,NULL);
+starting...
+starting/ { port: 33037,
+  default_server: 'http://10.211.55.4:33037/api/get_content/',
+  default_server2: '*',
+  url_verify: 'http://10.211.55.4:33037/api/verify/',
+  url_test: 'http://10.211.55.4:33037/api/test/',
+  full_path: 'true',
+  fxDone: undefined,
+  name: 'test Real Content Provider API',
+  silentToken: true }
+quit true false
+    $ http://localhost:33037/api/find_content
+checking if user is logged in /api/find_content?originalFilename=randomTask
+LoginAPIConsumerService key undefined { cookie:
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true } } undefined
+
+ consumer not logged in
+>>>*>  Request _callback test (http://localhost:33037/api/find_content) (doSearchWithNoLogin (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:179:27)) http://localhost:33037/api/find_content [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/find_content) {"msg":"user not logged in","success":false} (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: {"msg":"user not logged in","success":false}
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/find_content results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+{ msg: 'user not logged in', success: false }
+404 for  test (http://localhost:33037/api/find_content) {"msg":"user not logged in","success":false}
+    $ http://localhost:33031/api/login
+>>>*>  Request _callback test (http://localhost:33031/api/login) (testLoginWithNewUser (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:465:19)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'no user found', success: false }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+    $ http://localhost:33031/api/login
+>>>*>  Request _callback test (http://localhost:33031/api/login) (testLoginWithNewUser (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:447:19)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success',
+  success: true,
+  key: '848504eabd531fef886366523fa069ce',
+  user_id: 155 }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+login { msg: 'success',
+  success: true,
+  key: '848504eabd531fef886366523fa069ce',
+  user_id: 155 }
+    $ http://localhost:33037/api/verify?key=848504eabd531fef886366523fa069ce
+checking if user is logged in /api/verify?key=848504eabd531fef886366523fa069ce
+
+ /api/verify sent session key 848504eabd531fef886366523fa069ce
+isUserLoggedInAtMainCreateLocalSession { msg: 'success',
+  success: true,
+  key: '848504eabd531fef886366523fa069ce',
+  username: 'mark',
+  user_id: 155 }
+setting path on session to  sessions_test {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"key":"848504eabd531fef886366523fa069ce"}
+filehostingDDDD 10.211.55.4:33037
+headers undefined [ 'filehostingX=848504eabd531fef886366523fa069ce',
+  'filehosting=848504eabd531fef886366523fa069ce; Max-Age=900000; Domain=127.0.0.1:33037; HttpOnly',
+  'filehostingG=848504eabd531fef886366523fa069ce; Max-Age=900000; Domain=10.211.55.4:33037; HttpOnly',
+  'filehostingDDD=848504eabd531fef886366523fa069ce; Max-Age=900000; Domain=10.211.55.4:33037; HttpOnly',
+  'filehostingDDD=848504eabd531fef886366523fa069ce; Max-Age=900000; Domain=10.211.55.4:33037; HttpOnly' ]
+>>>*>  Request _callback test (http://localhost:33037/api/verify?key=848504eabd531fef886366523fa069ce) (tryVerify_LoginUserToRemoveAPI (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:499:19)) http://localhost:33037/api/verify?key=848504eabd531fef886366523fa069ce [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/verify?key=848504eabd531fef886366523fa069ce) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success', success: true }
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/verify?key=848504eabd531fef886366523fa069ce results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+    $ http://localhost:33037/api/find_content
+checking if user is logged in /api/find_content?originalFilename=randomTask
+LoginAPIConsumerService key 848504eabd531fef886366523fa069ce { cookie:
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: '848504eabd531fef886366523fa069ce',
+  __lastAccess: 1451850517873 } undefined
+>>>*>  find_content  getContent [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:90:18)
+success|ok() is deprecated and will be removed in 2.1, please use promise-style instead.
+Executing (default): SELECT `id`, `originalFilename`, `userId` FROM `file` AS `file` WHERE `file`.`originalFilename` = 'randomTask' LIMIT 10;
+>>>*>  Request _callback test (http://localhost:33037/api/find_content) (doSearchAfterLogin (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:194:23)) http://localhost:33037/api/find_content [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/find_content) [] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: []
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/find_content results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+    $ http://localhost:33037/api/file/create
+checking if user is logged in /api/file/create?originalFilename=jack.mp4
+LoginAPIConsumerService key 848504eabd531fef886366523fa069ce { cookie:
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: '848504eabd531fef886366523fa069ce',
+  __lastAccess: 1451850517873 } undefined
+Executing (default): INSERT INTO `file` (`id`,`originalFilename`) VALUES (DEFAULT,'jack.mp4');
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/RestHelperSQL js:758:30 We have a persisted instance now (undefined
+>>>*>  Request _callback test (http://localhost:33037/api/file/create) (createMovie_to_search (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:216:23)) http://localhost:33037/api/file/create [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/file/create) 101 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: 101
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/file/create results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+body 101
+    $ http://localhost:33037/api/find_content
+checking if user is logged in /api/find_content?originalFilename%5Blike%5D=%25mp4%25
+LoginAPIConsumerService key 848504eabd531fef886366523fa069ce { cookie:
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: '848504eabd531fef886366523fa069ce',
+  __lastAccess: 1451850517873 } undefined
+>>>*>  find_content  getContent [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:90:18)
+Executing (default): SELECT `id`, `originalFilename`, `userId` FROM `file` AS `file` WHERE `file`.`originalFilename` LIKE '%mp4%' LIMIT 10;
+Using .values has been deprecated. Please use .get() instead
+>>>*>  Request _callback test (http://localhost:33037/api/find_content) (doSearchWithLikeInName_VerifySearchWorks (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:235:23)) http://localhost:33037/api/find_content [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/find_content) [{"id":101,"originalFilename":"jack.mp4","userId":null}] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: [{"id":101,"originalFilename":"jack.mp4","userId":null}]
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/find_content results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+body [ { id: 101, originalFilename: 'jack.mp4', userId: null } ]
+    $ http://localhost:33037/api/file/delete/101
+checking if user is logged in /api/file/delete/101
+LoginAPIConsumerService key 848504eabd531fef886366523fa069ce { cookie:
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: '848504eabd531fef886366523fa069ce',
+  __lastAccess: 1451850517873 } undefined
+Executing (default): SELECT `id`, `originalFilename`, `userId` FROM `file` AS `file` WHERE `file`.`id` = '101';
+Executing (default): DELETE FROM `file` WHERE `id` = 101 LIMIT 1
+destroyed
+>>>*>  Request _callback test (http://localhost:33037/api/file/delete/101) (createMovie_to_search_delete (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:251:23)) http://localhost:33037/api/file/delete/101 [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/file/delete/101)  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents:
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/file/delete/101 results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+body
+    $ http://localhost:33037/api/get_content
+checking if user is logged in /api/get_content?test=true
+LoginAPIConsumerService key 848504eabd531fef886366523fa069ce { cookie:
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: '848504eabd531fef886366523fa069ce',
+  __lastAccess: 1451850517873 } undefined
+>>>*>  Request _callback test (http://localhost:33037/api/get_content) (reqMovie (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/file_server/file_server.js:268:23)) http://localhost:33037/api/get_content [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33037/api/get_content) test ok (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: test ok
+>>>*>  Object storeContents [as fx2] http://localhost:33037/api/get_content results (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:80:22)
+body test ok
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete test Real Content Provider API (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:53:30)
Index: mptransfer/DAL/scratch
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/scratch	(revision )
+++ mptransfer/DAL/scratch	(revision )
@@ -0,0 +1,570 @@
+/usr/sbin/node user_server.js
+10.211.55.4 ip address
+resolved /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/sequelize/lib/sequelize.js false
+DEPRECATION WARNING: The logging-option should be either a function or false. Default: console.log
+starting...
+starting/ { loginAPI: 
+   { port: 33031,
+     dir_sessions: '/home/user/ritv/dir_sessions',
+     warning: 'this is the main port for the whole server',
+     dirSesstions: '/home/user/sessions_login_api',
+     publicRoutes: 
+      [ 'favicon.ico',
+        'output.html',
+        'output/sparrow',
+        '/output/scripts',
+        '/output/',
+        '/proxy?' ],
+     fxPreLoginRoutes: [Function: fxPreLoginRoutes],
+     debugMiddleware: false,
+     fxGenericPreUserAuthBounceRouteHandler: [Function: fxGenericPreUserAuthBounceRouteHandler],
+     fxUserNotLoggedInResultSize: 3917,
+     fxGenericRouteHandler: [Function: fxGenericRouteHandler],
+     server: undefined,
+     dirSessions: '/home/user/trash/vidserv/login_api_sessions' },
+  loginAPIConsumer: 
+   { dirSesstions: '/home/user/ritv/sessions_login_consumer_api',
+     portProducer: 33031,
+     port: 37331,
+     dirSessions: '/home/user/trash/vidserv/test_login_consumer_api_sessions',
+     baseUrl: null },
+  sequelize: 
+   { options: 
+      { dialect: 'mysql',
+        dialectModulePath: null,
+        host: '127.0.0.1',
+        protocol: 'tcp',
+        define: [Object],
+        query: {},
+        sync: {},
+        timezone: '+00:00',
+        logging: [Function],
+        omitNull: false,
+        native: false,
+        replication: false,
+        ssl: undefined,
+        pool: {},
+        quoteIdentifiers: true,
+        hooks: {},
+        port: '12889' },
+     config: 
+      { database: 'yetidb',
+        username: 'yetidbuser',
+        password: 'aSDDD545y^',
+        host: '127.0.0.1',
+        port: '12889',
+        pool: [Object],
+        protocol: 'tcp',
+        native: false,
+        ssl: undefined,
+        replication: false,
+        dialectModulePath: null,
+        keepDefaultTimezone: undefined,
+        dialectOptions: undefined },
+     dialect: 
+      { sequelize: [Circular],
+        connectionManager: [Object],
+        QueryGenerator: [Object] },
+     models: {},
+     daoFactoryManager: { daos: [], sequelize: [Circular] },
+     modelManager: { daos: [], sequelize: [Circular] },
+     connectionManager: 
+      { sequelize: [Circular],
+        config: [Object],
+        dialect: [Object],
+        onProcessExit: [Function],
+        lib: [Object],
+        pool: [Object] },
+     importCache: {},
+     test: 
+      { '$trackRunningQueries': false,
+        '$runningQueries': 0,
+        trackRunningQueries: [Function],
+        verifyNoRunningQueries: [Function] },
+     Sequelize: 
+      { [Function]
+        options: [Object],
+        Utils: [Object],
+        Promise: [Object],
+        QueryTypes: [Object],
+        Validator: [Object],
+        Model: [Object],
+        ABSTRACT: [Function],
+        STRING: [Object],
+        CHAR: [Object],
+        TEXT: [Object],
+        NUMBER: [Object],
+        INTEGER: [Object],
+        BIGINT: [Object],
+        FLOAT: [Object],
+        TIME: [Object],
+        DATE: [Object],
+        DATEONLY: [Object],
+        BOOLEAN: [Object],
+        NOW: [Object],
+        BLOB: [Object],
+        DECIMAL: [Object],
+        UUID: [Object],
+        UUIDV1: [Object],
+        UUIDV4: [Object],
+        HSTORE: [Object],
+        JSON: [Object],
+        JSONB: [Object],
+        VIRTUAL: [Object],
+        ARRAY: [Object],
+        NONE: [Object],
+        ENUM: [Object],
+        RANGE: [Object],
+        Transaction: [Object],
+        Instance: [Function],
+        replaceHookAliases: [Function],
+        runHooks: [Function],
+        hook: [Function],
+        addHook: [Function],
+        hasHook: [Function],
+        hasHooks: [Function],
+        Error: [Object],
+        ValidationError: [Object],
+        ValidationErrorItem: [Function],
+        DatabaseError: [Object],
+        TimeoutError: [Object],
+        UniqueConstraintError: [Object],
+        ExclusionConstraintError: [Object],
+        ForeignKeyConstraintError: [Object],
+        ConnectionError: [Object],
+        ConnectionRefusedError: [Object],
+        AccessDeniedError: [Object],
+        HostNotFoundError: [Object],
+        HostNotReachableError: [Object],
+        InvalidConnectionError: [Object],
+        ConnectionTimedOutError: [Object],
+        fn: [Function],
+        col: [Function],
+        cast: [Function],
+        asIs: [Function],
+        literal: [Function],
+        and: [Function],
+        or: [Function],
+        json: [Function],
+        condition: [Function],
+        where: [Function] } },
+  setupRoutes: [Function: setupGenericRoutes],
+  fxDone: [Function: loginServerRunning],
+  forceDB: false,
+  port: 33031,
+  name: 'test login server',
+  silentToken: true }
+testChain
+testChain
+creating tables
+starting...
+starting/ { fxDone: [Function: tablesSycnedOrCreated],
+  name: 'recipe to sync table',
+  silentToken: true }
+Executing (default): SELECT 1+1 AS result
+Syced successfully.
+Executing (default): CREATE TABLE IF NOT EXISTS `sessions` (`id` VARCHAR(255) NOT NULL , `data` TEXT NOT NULL, `updated_on` DATETIME, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `sessions`
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `users`
+Connection has been established successfully.
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete recipe to sync table (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/PromiseHelperV3.js:45:30)
+Mon, 15 Feb 2016 06:03:13 GMT body-parser deprecated bodyParser: use individual json/urlencoded middlewares at example/ExampleCredentialsAPIProducerService.js:86:17
+Mon, 15 Feb 2016 06:03:14 GMT body-parser deprecated undefined extended: provide extended option at node_modules/body-parser/index.js:85:29
+fxPreLoginRoutes
+Credential Server Started on 33031
+Credential Server Started on http://localhost:33031
+setup routes
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): CREATE TABLE IF NOT EXISTS `sessions` (`id` VARCHAR(255) NOT NULL , `data` TEXT NOT NULL, `updated_on` DATETIME, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `sessions`
+    $
+testing...
+login check 2 true /api/login
+-- someone is logging in
+topMiddleware_BlockUsersWithoutSessions logged in... /api/login
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'mark' AND `users`.`password` = '0932217b636fcb32fc83c2e9355a3bf5' LIMIT 1;
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"}}
+>>>*>  Request _callback test (http://localhost:33031/api/login) (login_withBadUsername (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:227:15)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'no user found', success: false }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'mark' LIMIT 1;
+Executing (default): DELETE FROM `users` WHERE `id` = 268 LIMIT 1
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'mark2' LIMIT 1;
+Executing (default): DELETE FROM `users` WHERE `id` = 269 LIMIT 1
+Executing (default): INSERT INTO `users` (`id`,`username`,`password`,`status`,`firstname`,`lastname`,`lastPayment`,`paidExpiryDate`,`paymentTracker`,`passwordResetHash`,`identifier`,`apikey`) VALUES (DEFAULT,'mark','0fd78fd8db9f2455ccf8fdcc642ce04c','active','','',NULL,NULL,'','','','');
+We have a persisted instance now
+Executing (default): INSERT INTO `users` (`id`,`username`,`password`,`status`,`firstname`,`lastname`,`lastPayment`,`paidExpiryDate`,`paymentTracker`,`passwordResetHash`,`identifier`,`apikey`) VALUES (DEFAULT,'mark2','0fd78fd8db9f2455ccf8fdcc642ce04c','active','','',NULL,NULL,'','','','');
+We have a persisted instance now
+    $
+testing...
+login check 2 false /api/test?key=undefined
+topMiddleware_BlockUsersWithoutSessions not logged in
+404 for  test (http://localhost:33031/api/test?key=undefined) { msg: 'user not logged in', success: false }
+bodoy { msg: 'user not logged in', success: false }
+3917 'what is this....'
+>>>*>  Request _callback test (http://localhost:33031/api/test?key=undefined) (tryToMakeRequestAgainstServer_ExpectFailure (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:727:19)) http://localhost:33031/api/test?key=undefined [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/test?key=undefined) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'user not logged in', success: false }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/test?key=undefined received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+    $
+testing...
+-- someone is logging in
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'mark' AND `users`.`password` = '0fd78fd8db9f2455ccf8fdcc642ce04c' LIMIT 1;
+login check 2 true /api/login
+topMiddleware_BlockUsersWithoutSessions logged in... /api/login
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196187,"key":"5bd4e624520f7b7791d49fc97704752d","username":"mark","user_id":271}
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196339,"key":"5bd4e624520f7b7791d49fc97704752d","username":"mark","user_id":271}
+Executing (3960316d-6f8d-4905-ab93-d6b527fcf370): START TRANSACTION;
+Executing (3960316d-6f8d-4905-ab93-d6b527fcf370): SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
+Executing (3960316d-6f8d-4905-ab93-d6b527fcf370): SET autocommit = 1;
+Executing (3960316d-6f8d-4905-ab93-d6b527fcf370): SELECT `id`, `data`, `updated_on` FROM `sessions` AS `sessions` WHERE `sessions`.`id` = '5bd4e624520f7b7791d49fc97704752d' AND `sessions`.`data` = '{\"username\":\"mark\",\"user_id\":271}';
+save complete null
+Executing (default): UPDATE `users` SET `lastlogindate`='2016-02-15 06:03:16',`lastloginip`='::ffff:127.0.0.1' WHERE `id` = 271
+Executing (3960316d-6f8d-4905-ab93-d6b527fcf370): INSERT INTO `sessions` (`id`,`data`,`updated_on`) VALUES ('5bd4e624520f7b7791d49fc97704752d','{\"username\":\"mark\",\"user_id\":271}','2016-02-15 06:03:16');
+>>>*>  Request _callback test (http://localhost:33031/api/login) (testLoginWithNewUser (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:272:15)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success',
+  success: true,
+  key: '5bd4e624520f7b7791d49fc97704752d',
+  user_id: 271 }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+Executing (3960316d-6f8d-4905-ab93-d6b527fcf370): COMMIT;
+    $
+testing...
+login check 2 true /api/test?key=5bd4e624520f7b7791d49fc97704752d
+topMiddleware_BlockUsersWithoutSessions logged in... /api/test?key=5bd4e624520f7b7791d49fc97704752d
+---test route
+---expires 0
+>>>*>  Request _callback test (http://localhost:33031/api/test?key=5bd4e624520f7b7791d49fc97704752d) (tryToMakeRequestAgainstServer (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:717:19)) http://localhost:33031/api/test?key=5bd4e624520f7b7791d49fc97704752d [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/test?key=5bd4e624520f7b7791d49fc97704752d) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { success: true, test: 'test route' }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/test?key=5bd4e624520f7b7791d49fc97704752d received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'markExpired' LIMIT 1;
+Executing (default): DELETE FROM `users` WHERE `id` = 270 LIMIT 1
+Executing (default): INSERT INTO `users` (`id`,`username`,`password`,`level`,`status`,`firstname`,`lastname`,`lastPayment`,`paidExpiryDate`,`paymentTracker`,`passwordResetHash`,`identifier`,`apikey`) VALUES (DEFAULT,'markExpired','0fd78fd8db9f2455ccf8fdcc642ce04c','NEOPHITE','active','','',NULL,'2016-02-12 06:03:13','','','','');
+We have a persisted instance now
+logging in with markExpired randomTask2
+    $
+testing...
+-- someone is logging in
+login check 2 true /api/login
+topMiddleware_BlockUsersWithoutSessions logged in... /api/login
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'markExpired' AND `users`.`password` = '0fd78fd8db9f2455ccf8fdcc642ce04c' LIMIT 1;
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196341,"key":"a03a2f7a74dc4892ae59786ba6ca3ec0","username":"markExpired","user_id":273}
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196563,"key":"a03a2f7a74dc4892ae59786ba6ca3ec0","username":"markExpired","user_id":273,"accountExpired":true}
+Executing (a18dad74-052d-4f98-b9e2-1a952db05d47): START TRANSACTION;
+Executing (default): UPDATE `users` SET `lastlogindate`='2016-02-15 06:03:16',`lastloginip`='::ffff:127.0.0.1' WHERE `id` = 273
+Executing (a18dad74-052d-4f98-b9e2-1a952db05d47): SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
+save complete null
+>>>*>  Request _callback test (http://localhost:33031/api/login) (login_withBadUsername (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:155:23)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success',
+  success: true,
+  key: 'a03a2f7a74dc4892ae59786ba6ca3ec0',
+  user_id: 273,
+  accountExpired: true }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+Executing (a18dad74-052d-4f98-b9e2-1a952db05d47): SET autocommit = 1;
+logging in with { msg: 'success',
+  success: true,
+  key: 'a03a2f7a74dc4892ae59786ba6ca3ec0',
+  user_id: 273,
+  accountExpired: true }
+    $
+testing...
+Executing (a18dad74-052d-4f98-b9e2-1a952db05d47): SELECT `id`, `data`, `updated_on` FROM `sessions` AS `sessions` WHERE `sessions`.`id` = 'a03a2f7a74dc4892ae59786ba6ca3ec0' AND `sessions`.`data` = '{\"username\":\"markExpired\",\"user_id\":273,\"account_expired\":true}';
+Executing (a18dad74-052d-4f98-b9e2-1a952db05d47): INSERT INTO `sessions` (`id`,`data`,`updated_on`) VALUES ('a03a2f7a74dc4892ae59786ba6ca3ec0','{\"username\":\"markExpired\",\"user_id\":273,\"account_expired\":true}','2016-02-15 06:03:16');
+Executing (a18dad74-052d-4f98-b9e2-1a952db05d47): COMMIT;
+login check 2 true /api/logout
+topMiddleware_BlockUsersWithoutSessions logged in... /api/logout
+>>>*>  Request _callback test (http://localhost:33031/api/logout) (testLoginAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:172:23)) http://localhost:33031/api/logout [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+404 for  test (http://localhost:33031/api/logout) Cannot POST /api/logout
+
+>>>*>  Request _callback 	 test (http://localhost:33031/api/logout) Cannot POST /api/logout
+ (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: Cannot POST /api/logout
+
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/logout received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+    $
+testing...
+login check 2 true /api/logout
+topMiddleware_BlockUsersWithoutSessions logged in... /api/logout
+>>>*>  Request _callback test (http://localhost:33031/api/logout) (testLoginAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:180:23)) http://localhost:33031/api/logout [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/logout) Cannot POST /api/logout
+ (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: Cannot POST /api/logout
+
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/logout received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+404 for  test (http://localhost:33031/api/logout) Cannot POST /api/logout
+
+body 'Cannot POST /api/logout
+'
+    $
+testing...
+logging in with mark randomTask2
+login check 2 true /api/login
+-- someone is logging in
+topMiddleware_BlockUsersWithoutSessions logged in... /api/login
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'mark' AND `users`.`password` = '0fd78fd8db9f2455ccf8fdcc642ce04c' LIMIT 1;
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196573,"key":"b69c66a2cfa3715db3661fdd0d9627bc","username":"mark","user_id":271,"accountExpired":true}
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196836,"key":"b69c66a2cfa3715db3661fdd0d9627bc","username":"mark","user_id":271,"accountExpired":true}
+Executing (01e2ad7e-c818-41c3-afee-cc24149e761e): START TRANSACTION;
+Executing (default): UPDATE `users` SET `lastlogindate`='2016-02-15 06:03:16' WHERE `id` = 271
+Executing (01e2ad7e-c818-41c3-afee-cc24149e761e): SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
+Executing (01e2ad7e-c818-41c3-afee-cc24149e761e): SET autocommit = 1;
+save complete null
+Executing (01e2ad7e-c818-41c3-afee-cc24149e761e): SELECT `id`, `data`, `updated_on` FROM `sessions` AS `sessions` WHERE `sessions`.`id` = 'b69c66a2cfa3715db3661fdd0d9627bc' AND `sessions`.`data` = '{\"username\":\"mark\",\"user_id\":271,\"account_expired\":true}';
+>>>*>  Request _callback test (http://localhost:33031/api/login) (login_withBadUsername (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:155:23)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success',
+  success: true,
+  key: 'b69c66a2cfa3715db3661fdd0d9627bc',
+  user_id: 271 }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+logging in with { msg: 'success',
+  success: true,
+  key: 'b69c66a2cfa3715db3661fdd0d9627bc',
+  user_id: 271 }
+Executing (01e2ad7e-c818-41c3-afee-cc24149e761e): INSERT INTO `sessions` (`id`,`data`,`updated_on`) VALUES ('b69c66a2cfa3715db3661fdd0d9627bc','{\"username\":\"mark\",\"user_id\":271,\"account_expired\":true}','2016-02-15 06:03:16');
+Executing (01e2ad7e-c818-41c3-afee-cc24149e761e): COMMIT;
+Mon, 15 Feb 2016 06:03:16 GMT body-parser deprecated bodyParser: use individual json/urlencoded middlewares at api/CredentialConsumerAPI.js:25:17
+starting LoginAPIConsumerService /home/user/trash/vidserv/test_login_consumer_api_sessions
+LoginConsumerAPI Server Started on 37331
+http://localhost:37331
+    $
+testing...
+checking if user is logged in /api/test?username=mark&password=randomTask
+LoginAPIConsumerService key undefined { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true } } undefined { username: 'mark', password: 'randomTask' }
+
+ consumer not logged in
+>>>*>  Request _callback test (http://localhost:37331/api/test) (makeRequestToConsumerAPI_WithoutLoggingIn (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:358:19)) http://localhost:37331/api/test [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:37331/api/test) {"msg":"user not logged in","success":false} (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: {"msg":"user not logged in","success":false}
+>>>*>  Object storeContents [as fx2] http://localhost:37331/api/test received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+404 for  test (http://localhost:37331/api/test) {"msg":"user not logged in","success":false}
+    $
+testing...
+checking if user is logged in /api/logout
+LoginAPIConsumerService key undefined { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true } } undefined {}
+
+ consumer not logged in
+404 for  test (http://localhost:37331/api/logout) { msg: 'user not logged in', success: false }
+>>>*>  Request _callback test (http://localhost:37331/api/logout) (testLateAddedRoute (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:328:27)) http://localhost:37331/api/logout [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:37331/api/logout) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'user not logged in', success: false }
+>>>*>  Object storeContents [as fx2] http://localhost:37331/api/logout received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+    $
+testing...
+login check 2 true /api/logout
+topMiddleware_BlockUsersWithoutSessions logged in... /api/logout
+404 for  test (http://localhost:33031/api/logout) Cannot POST /api/logout
+
+>>>*>  Request _callback test (http://localhost:33031/api/logout) (testLoginAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:172:23)) http://localhost:33031/api/logout [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/logout) Cannot POST /api/logout
+ (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: Cannot POST /api/logout
+
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/logout received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+    $
+testing...
+login check 2 true /api/logout
+topMiddleware_BlockUsersWithoutSessions logged in... /api/logout
+404 for  test (http://localhost:33031/api/logout) Cannot POST /api/logout
+
+body 'Cannot POST /api/logout
+'
+>>>*>  Request _callback test (http://localhost:33031/api/logout) (testLoginAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:180:23)) http://localhost:33031/api/logout [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/logout) Cannot POST /api/logout
+ (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: Cannot POST /api/logout
+
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/logout received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+logging in with mark randomTask2
+    $
+testing...
+-- someone is logging in
+Executing (default): SELECT `id`, `username`, `password`, `level`, `email`, `lastlogindate`, `lastloginip`, `status`, `title`, `firstname`, `lastname`, `createdip`, `lastPayment`, `paidExpiryDate`, `paymentTracker`, `passwordResetHash`, `identifier`, `apikey` FROM `users` AS `users` WHERE `users`.`username` = 'mark' AND `users`.`password` = '0fd78fd8db9f2455ccf8fdcc642ce04c' LIMIT 1;
+login check 2 true /api/login
+topMiddleware_BlockUsersWithoutSessions logged in... /api/login
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516196837,"key":"e18ec0aa4260edef16a4aae843194e64","username":"mark","user_id":271,"accountExpired":true}
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"__lastAccess":1455516198021,"key":"e18ec0aa4260edef16a4aae843194e64","username":"mark","user_id":271,"accountExpired":true}
+Executing (0c399c1f-1726-4895-8fca-9d3597fc2259): START TRANSACTION;
+Executing (default): UPDATE `users` SET `lastlogindate`='2016-02-15 06:03:18' WHERE `id` = 271
+Executing (0c399c1f-1726-4895-8fca-9d3597fc2259): SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
+Executing (0c399c1f-1726-4895-8fca-9d3597fc2259): SET autocommit = 1;
+save complete null
+Executing (0c399c1f-1726-4895-8fca-9d3597fc2259): SELECT `id`, `data`, `updated_on` FROM `sessions` AS `sessions` WHERE `sessions`.`id` = 'e18ec0aa4260edef16a4aae843194e64' AND `sessions`.`data` = '{\"username\":\"mark\",\"user_id\":271,\"account_expired\":true}';
+Executing (0c399c1f-1726-4895-8fca-9d3597fc2259): INSERT INTO `sessions` (`id`,`data`,`updated_on`) VALUES ('e18ec0aa4260edef16a4aae843194e64','{\"username\":\"mark\",\"user_id\":271,\"account_expired\":true}','2016-02-15 06:03:18');
+>>>*>  Request _callback test (http://localhost:33031/api/login) (login_withBadUsername (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:155:23)) http://localhost:33031/api/login [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:33031/api/login) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success',
+  success: true,
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  user_id: 271 }
+>>>*>  Object storeContents [as fx2] http://localhost:33031/api/login received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+Executing (0c399c1f-1726-4895-8fca-9d3597fc2259): COMMIT;
+logging in with { msg: 'success',
+  success: true,
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  user_id: 271 }
+    $
+testing...
+checking if user is logged in /test2
+LoginAPIConsumerService key undefined { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true } } undefined {}
+
+ consumer not logged in
+404 for  test (http://localhost:37331/test2) {"msg":"user not logged in","success":false}
+>>>*>  Request _callback test (http://localhost:37331/test2) (testLateAddedRoute_EnsuresConsumerHelperGuardsPreExistingRoutes (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:372:19)) http://localhost:37331/test2 [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:37331/test2) {"msg":"user not logged in","success":false} (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: {"msg":"user not logged in","success":false}
+>>>*>  Object storeContents [as fx2] http://localhost:37331/test2 received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+    $
+testing...
+isUser { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true } } undefined
+checking if user is logged in /api/verify?key=e18ec0aa4260edef16a4aae843194e64
+
+ /api/verify sent session key e18ec0aa4260edef16a4aae843194e64
+Producer: api verify /api/verify?key=e18ec0aa4260edef16a4aae843194e64 e18ec0aa4260edef16a4aae843194e64
+login check 2 true /api/verify?key=e18ec0aa4260edef16a4aae843194e64
+topMiddleware_BlockUsersWithoutSessions logged in... /api/verify?key=e18ec0aa4260edef16a4aae843194e64
+Executing (default): SELECT `id`, `data`, `updated_on` FROM `sessions` AS `sessions` WHERE `sessions`.`id` = 'e18ec0aa4260edef16a4aae843194e64';
+setting path on session to  /home/user/trash/vidserv/login_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"}}
+isUserLoggedInAtMainCreateLocalSession result { msg: 'success',
+  success: true,
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  username: 'mark',
+  user_id: 271,
+  account_expired: true }
+{ cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  account_expired: true } '...' '7'
+setting path on session to  /home/user/trash/vidserv/test_login_consumer_api_sessions {"cookie":{"originalMaxAge":null,"expires":null,"httpOnly":true,"path":"/"},"key":"e18ec0aa4260edef16a4aae843194e64","account_expired":true}
+>>>>>>>>>>>>>>>>account is expired .......
+headers undefined undefined
+>>>*>  Request _callback test (http://localhost:37331/api/verify?key=e18ec0aa4260edef16a4aae843194e64) (tryVerify_LoginUserToRemoveAPI (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:381:19)) http://localhost:37331/api/verify?key=e18ec0aa4260edef16a4aae843194e64 [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:37331/api/verify?key=e18ec0aa4260edef16a4aae843194e64) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'success', success: true }
+>>>*>  Object storeContents [as fx2] http://localhost:37331/api/verify?key=e18ec0aa4260edef16a4aae843194e64 received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+what is body { msg: 'success', success: true }
+    $
+testing...
+checking if user is logged in /api/test
+LoginAPIConsumerService key e18ec0aa4260edef16a4aae843194e64 { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  account_expired: true,
+  __lastAccess: 1455516198081 } undefined {}
+isUser { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  account_expired: true,
+  __lastAccess: 1455516198081 } true
+>>>*>  Request _callback test (http://localhost:37331/api/test) (tryRouteAFterVerify (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:390:19)) http://localhost:37331/api/test [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:37331/api/test) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'account expired', success: false }
+>>>*>  Object storeContents [as fx2] http://localhost:37331/api/test received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+404 for  test (http://localhost:37331/api/test) { msg: 'account expired', success: false }
+    $
+testing...
+checking if user is logged in /test2
+LoginAPIConsumerService key e18ec0aa4260edef16a4aae843194e64 { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  account_expired: true,
+  __lastAccess: 1455516198081 } undefined {}
+>>>*>  Request _callback test (http://localhost:37331/test2) (testLateAddedRoute (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:401:19)) http://localhost:37331/test2 [object Object]  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:178:17)
+>>>*>  Request _callback 	 test (http://localhost:37331/test2) [object Object] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:213:21)
+	body contents: { msg: 'account expired', success: false }
+isUser { cookie: 
+   { path: '/',
+     _expires: null,
+     originalMaxAge: null,
+     httpOnly: true },
+  key: 'e18ec0aa4260edef16a4aae843194e64',
+  account_expired: true,
+  __lastAccess: 1455516198081 } true
+404 for  test (http://localhost:37331/test2) { msg: 'account expired', success: false }
+>>>*>  Object storeContents [as fx2] http://localhost:37331/test2 received result ok... (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:71:22)
+    ^E
+/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/shelpers.js:716
+    throw(e);
+          ^
+Error: user was able to communicate without trying
+    at result (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:404:23)
+    at Object.storeContents [as fx2] (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:83:21)
+    at Request._callback (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/TestHelper.js:237:42)
+    at Request.self.callback (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/request/request.js:368:22)
+    at Request.emit (events.js:110:17)
+    at Request.<anonymous> (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/request/request.js:1219:14)
+    at Request.emit (events.js:129:20)
+    at IncomingMessage.<anonymous> (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/request/request.js:1167:12)
+    at IncomingMessage.emit (events.js:129:20)
+    at _stream_readable.js:908:16
+    at process._tickCallback (node.js:355:11)
+
+from
+    at CredentialServerQuickStartHelper.runFunctionalTestCredentialServers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:567:9)
+    at CredentialServerQuickStartHelper.setupCredentialProducerAndConsumer (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:121:14)
+    at CredentialServerQuickStartHelper.testCredentialsServer (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/CredentialServerQuickStartHelper.js:76:14)
+    at UserServer.defineCredentialServer_Settings (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/user_server.js:348:18)
+    at UserServer.createCredentialServer (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/user_server.js:90:14)
+    at UserServer.createSessionsDirs (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/user_server.js:80:14)
+    at UserServer.loadSettings (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/user_server.js:40:14)
+    at UserServer.init (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/user_server.js:31:14)
+    at Object.<anonymous> (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/user_server.js:367:7)
+    at Module._compile (module.js:460:26)
+    at Object.Module._extensions..js (module.js:478:10)
+
+via
+    at Object.assert (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:175:39)
+    at EasyRemoteTester.assert (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/credentials_server/node_modules/shelpers/lib/EasyRemoteTester.js:262:25)
+
+Process finished with exit code 1
Index: mptransfer/DAL/sql_sharing_server/tests/sqllite_tests.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/tests/sqllite_tests.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/tests/sqllite_tests.js	(revision )
@@ -0,0 +1,37 @@
+/**
+ * Created by morriste on 7/22/16.
+ */
+
+
+var Sequelize = require('sequelize')//.sequelize
+//var sqlite    = require('sequelize-sqlite').sqlite
+
+var sequelize = new Sequelize('database', 'username', '', {
+    dialect: 'sqlite',
+   // storage: 'file:data.db'
+    storage: 'data.db'
+})
+
+var Record = sequelize.define('Record', {
+    name: Sequelize.STRING,
+    quantity: Sequelize.INTEGER
+})
+
+var sync = sequelize.sync()
+sync
+    .done(function(a,b,c){
+        console.log('synced')
+
+
+        var rec = Record.build({ name: "sunny", quantity: 3 });
+        rec.save()
+            .error(function(err) {
+// error callback
+                alert('somethings wrong')
+            })
+        .done(function() {
+// success callback
+            console.log('inserted')
+        });
+    })
+
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_bulk_config.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_bulk_config.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_bulk_config.js	(revision )
@@ -0,0 +1,962 @@
+/**
+ * Created by user on 1/13/16.
+ */
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+var SQLSharingServer = require('./sql_sharing_server').SQLSharingServer;
+
+if (module.parent == null) {
+
+    var config = {}
+    config.cluster_config = 'tests/'+'test_cluster_config.json'
+    var server_config = rh.loadRServerConfig(true, config);
+    var cluster_config  = server_config.cluster_config;
+
+    var allPeers = [];
+    var topology = {};
+    //override for wind evelopment
+    rh.configOverride = {};
+    rh.configOverride.mysql = {};
+    rh.configOverride.mysql.port = '3306'
+    rh.configOverride.mysql.user = 'root'
+    rh.configOverride.mysql.pass = 'password'
+
+
+    function testGrabbingCurrentPeer() {
+        //startup service with nothing.
+        //see what happens
+
+        // sh.each(peer, function processPeer(peerName, ip) {
+        var config = {};
+        config.cluster_config = cluster_config;
+
+        // var peers = dictPeerToLinksToPeers[peerName];
+        // var me = {}
+        // me[peerName] = ip;
+        //    peers.push(me)
+        // config.cluster_config.peers = peers;
+        config.cluster_config.peers.a = server_config.ip+':' + 16001
+        // config.port = port;
+        //  config.peerName = peerName;
+        //  config.tableName = peerName+'Table';
+        config.fxDone = fxFinishedInitPeer
+        var service = new SQLSharingServer();
+        var peerName = 'a';
+        config.peerName = peerName
+        config.tableName = config.cluster_config.tables[0]
+        service.init(config);
+        var a = service;
+        allPeers.push(service);
+        topology[peerName] = a;
+    }
+    testGrabbingCurrentPeer();
+    return;
+
+    //load confnig frome file
+    //peer has gone down ... peer comes back
+    //real loading
+    //multipe tables
+
+    //define tables to sync and time
+    //create 'atomic' modes for create/update and elete
+
+    //TODO:
+    /*
+     Drop the ip address
+     fi ip address is not 127.0.0.1,
+     make 'tabeles'
+     specify refresh time
+     make fulls ync -
+     */
+    var topology = {};
+    var allPeers = [];
+    /**
+     * Create network from config file
+     */
+    function defineTopology() {
+        var dictPeersToIp = {};
+        var dictPeerToLinksToPeers = {};
+        sh.each(server_config.cluster_config.peers, function onPeer(peerName,peer) {
+            //  sh.each(peer, function processPeer(peerName, ip) {
+            dictPeersToIp[peerName] = peer;
+            dictPeerToLinksToPeers[peerName] = [];
+            //  });
+        })
+
+        /*
+         config.cluster_config.peers = [
+         {d:"127.0.0.1:12004"},
+         {e:"127.0.0.1:12005"}
+         ]
+         create an object where the name of the peer, and the ip address
+         do for each way
+         */
+        sh.each(server_config.cluster_config.links, function onPeer(fromPeerName,linksTo) {
+            var fromPeer = dictPeerToLinksToPeers[fromPeerName];
+            //   sh.each(peer, function processPeer(peerName, linksTo) {
+            fromPeer.linkedToPeer = sh.dv( fromPeer.linkedToPeer, {})
+            sh.each(linksTo, function processPeerLinkedTo(i, toPeerName) {
+                var toPeer = dictPeersToIp[toPeerName];
+                var toPeerConfig = {};
+                var exists = fromPeer.linkedToPeer[toPeerName]
+                if ( exists == null ) {
+                    toPeerConfig[toPeerName] = toPeer;
+                    fromPeer.push(toPeerConfig);
+                    fromPeer.linkedToPeer[toPeerName] = toPeerConfig;
+                }
+
+                function linkToPeer_to_fromPeer() {
+                    var dbg= [fromPeerName, toPeerName]
+                    var fromPeerConfig_rev = {};
+                    var fromPeer = dictPeerToLinksToPeers[toPeerName]; //siwtch
+                    fromPeer.linkedToPeer = sh.dv( fromPeer.linkedToPeer, {})
+                    var exists = fromPeer.linkedToPeer[fromPeerName]
+                    var fromPeerIp =  dictPeersToIp[fromPeerName]
+                    if ( exists == null ) {
+                        fromPeerConfig_rev[fromPeerName] = fromPeerIp;
+                        fromPeer.push(fromPeerConfig_rev);
+                        fromPeer.linkedToPeer[fromPeerName] = fromPeerConfig_rev;
+                    }
+                    //link toPeer to fromPeer
+                }
+                linkToPeer_to_fromPeer();
+            });
+            //   });
+        })
+        sh.each(server_config.cluster_config.links, function onPeer(fromPeerName,linksTo) {
+            var fromPeer = dictPeerToLinksToPeers[fromPeerName];
+            //   sh.each(peer, function processPeer(peerName, linksTo) {
+            fromPeer.linkedToPeer = sh.dv( fromPeer.linkedToPeer, {})
+            sh.each(linksTo, function processPeerLinkedTo(i, toPeerName) {
+                var toPeer = dictPeersToIp[toPeerName];
+                var toPeerConfig = {};
+                var exists = fromPeer.linkedToPeer[toPeerName]
+                if ( exists == null ) {
+                    toPeerConfig[toPeerName] = toPeer;
+                    fromPeer.push(toPeerConfig);
+                    fromPeer.linkedToPeer[toPeerName] = toPeerConfig;
+                }
+
+                function linkToPeer_to_fromPeer() {
+                    var dbg= [fromPeerName, toPeerName]
+                    var fromPeerConfig_rev = {};
+                    var fromPeer = dictPeerToLinksToPeers[toPeerName]; //siwtch
+                    fromPeer.linkedToPeer = sh.dv( fromPeer.linkedToPeer, {})
+                    var exists = fromPeer.linkedToPeer[fromPeerName]
+                    var fromPeerIp =  dictPeersToIp[fromPeerName]
+                    if ( exists == null ) {
+                        fromPeerConfig_rev[fromPeerName] = fromPeerIp;
+                        fromPeer.push(fromPeerConfig_rev);
+                        fromPeer.linkedToPeer[fromPeerName] = fromPeerConfig_rev;
+                    }
+                    //link toPeer to fromPeer
+                }
+                linkToPeer_to_fromPeer();
+            });
+            //   });
+        })
+
+
+        sh.each(server_config.cluster_config.peers, function onPeer(peerName,ip) {
+            //var ip = null;
+            if ( ip.indexOf(':') !=-1 ) {
+                var port = ip.split(':')[1];
+                ip = ip.split(':')[0];
+
+            }
+
+            // sh.each(peer, function processPeer(peerName, ip) {
+            var config = {};
+            config.cluster_config = cluster_config;
+            var peers = dictPeerToLinksToPeers[peerName];
+            var me = {}
+            me[peerName] = ip;
+            peers.push(me)
+            config.cluster_config.peers = peers;
+
+            config.port = port;
+            config.peerName = peerName;
+            config.tableName = peerName+'Table';
+            config.fxDone = fxFinishedInitPeer
+            var service = new SQLSharingServer();
+            service.init(config);
+            var a = service;
+            allPeers.push(service);
+            topology[peerName] = a;
+            //     });
+        })
+
+    }
+    defineTopology();
+
+
+    var i = 0
+    function fxFinishedInitPeer () {
+        i++
+        if ( i == allPeers.length ) {
+            testInstances()
+        }
+
+    }
+    return;
+    //testInstances();
+
+    // setTimeout(testInstances, 500);
+
+
+    /*
+     var config = sh.clone(config);
+     config.port = 12002;
+     config.peerName = 'b';
+     config.tableName = 'bA';
+     var service = new SQLSharingServer();
+     service.init(config);
+     var b = service;
+     allPeers.push(service)
+     */
+    function __augmentNetworkConfiguration() {
+        if ( topology.augmentNetworkConfiguration) {
+            return;
+        }
+        topology.augmentNetworkConfiguration = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {c:"127.0.0.1:12003"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12003;
+        config.peerName = 'c';
+        config.tableName = 'cA';
+
+        var service = new SQLSharingServer();
+        service.init(config);
+        var c = service;
+        allPeers.push(service)
+        topology.c = c;
+        //c.linkTo({b:b});
+        b.linkTo({c:c})
+
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12004;
+        config.peerName = 'd';
+        config.tableName = 'dA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var d = service;
+        allPeers.push(service)
+        topology.d = d;
+        //d.linkTo({c:c});
+        b.linkTo({d:d})
+
+
+    }
+    function __augmentNetworkConfiguration2() {
+        if ( topology.augmentNetworkConfiguration2) {
+            return;
+        }
+        topology.augmentNetworkConfiguration2 = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {e:"127.0.0.1:12005"}
+        ]
+        config.port = 12005;
+        config.peerName = 'e';
+        config.tableName = 'eA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var e = service;
+        allPeers.push(service)
+        topology.d.linkTo({e:e})
+    }
+
+
+    function testInstances() {
+        //make chain
+        var sh = require('shelpers').shelpers;
+        var shelpers = require('shelpers');
+        var EasyRemoteTester = shelpers.EasyRemoteTester;
+        var t = EasyRemoteTester.create('Test Channel Server basics',
+            {
+                showBody:false,
+                silent:true
+            });
+
+
+
+        var b = topology.b;
+        var baseUrl = 'http://127.0.0.1:'+ b.settings.port;
+        var urls = {};
+
+        var helper = {};
+
+        function defineHelperMethod() {
+            /**
+             * Deletes all data from all nodes
+             */
+            helper.clearAllData = function clearAllData(addData) {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function (peer, fxDone) {
+                            // asdf.g
+                            peer.test.destroyAllRecords(true, recordsDestroyed)
+                            function recordsDestroyed() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        });
+                });
+                if ( addData) {
+                    helper.addData();
+                }
+            }
+            helper.addData = function addData() {
+                t.add(function () {
+                    sh.async(allPeers,
+                        function (peer, fxDone) {
+                            // asdf.g
+                            peer.test.createTestData(recordsCreated)
+                            function recordsCreated() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        });
+                });
+            }
+
+
+
+
+            helper.getCountsOfAll = function getCountsOfAll(msg) {
+                t.workChain.utils.wait(1);
+                dictCounts = {};
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            var t2 = EasyRemoteTester.create('TestInSync',
+                                {  showBody:false,  silent:true });
+                            var baseUrl = 'http://'+ peer.settings.ip; //127.0.0.1:'+ b.settings.port;
+                            var urls = {};
+                            t2.settings.baseUrl = baseUrl;
+                            urls.getCount = t2.utils.createTestingUrl('count');
+                            t2.getR(urls.getCount).with(
+                                //   {sync:false,peer:'a'}
+                            )
+                                .fxDone(function syncComplete(result) {
+
+                                    dictCounts[peer.settings.name] = result;
+                                    fxDone()
+                                    return;
+                                });
+                        },
+                        function goCounts() {
+                            console.log('---------->counts', msg, dictCounts)
+                            t.cb()
+                        } );
+                });
+            }
+
+
+
+            helper.clearDataFromNode = function clearDataFromNode(service) {
+                service = sh.dv(service, topology.a)
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    service.test.destroyAllRecords(true, t.cb);
+                });
+            }
+
+            helper.toggleBlocking = function toggleBlocking(service) {
+                service = sh.dv(service, topology.c)
+                service.settings.block = !service.settings.block
+                console.log('blocking is ', service.settings.block , 'for', service.settings.name)
+
+            }
+
+            helper.pingNode = function clearDataFromNode(service) {
+                service = sh.dv(service, topology.a)
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    service.test.destroyAllRecords(true, t.cb);
+                });
+            }
+
+            helper.pingNode = function clearDataFromNode(service) {
+                service = sh.dv(service, topology.a)
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    service.test.destroyAllRecords(true, t.cb);
+                });
+            }
+
+
+            helper.verifyLocally = function verifyLocally(service) {
+                service = sh.dv(service, topology.a)
+                t.add(function getASize() {
+                    service.getSize(t.cb);
+                })
+                t.add(function getBSize() {
+                    b.getSize(t.cb);
+                })
+                t.add(function testSize() {
+                    t.assert(b.size == service.size, 'sync did ntow ork' + [b.size, service.size])
+                    t.cb();
+                })
+            }
+
+
+            helper.addRecord = function addRecord(service) {
+                service = sh.dv(service, topology.a)
+                t.add(function addNewRecord() {
+                    service.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+                });
+            }
+
+
+            helper.verifyRecourCount = function verifyRecourCount (countExpect, service) {
+                service = sh.dv(service, topology.a)
+                t.add(function verifyCounts() {
+                    service.dbHelper2.countAll(function gotAllRecords(count) {
+                        t.assert(countExpect== count, 'not the right amount of records '
+                            + count +' == '+ countExpect);
+                        t.cb()
+                    })
+                });
+            }
+
+
+
+            helper.verifySync = function verifySync () {
+                urls.verifySync = t.utils.createTestingUrl('verifySync');
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not integral ' + result.ok)
+                        return;
+                    });
+            }
+
+            /**
+             * Records need to be  marked as 'deleted'
+             * otherwise deletion doesn't count
+             * @param client
+             */
+            helper.forgetRandomRecordFrom =  function forgetRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function forgetRandomRecord() {
+                    client.test.forgetRandomRecord(t.cb);
+                });
+            }
+
+            helper.deleteRandomRecordFrom =  function deleteRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function deleteRandomRecord() {
+                    b.test.deleteRandomRecord(t.cb);
+                });
+            }
+
+            helper.syncIn = function syncIn() {
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            helper.syncOut = function syncOut() {
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            helper.syncBothDirections = function syncBothDirections() {
+                helper.syncIn()
+                helper.syncOut()
+            }
+
+            helper.notInSync = function notInSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==false, 'data is not supposed to be in sync ' + result.ok);
+                        return;
+                    });
+            }
+            helper.inSync = function inSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                        return;
+                    });
+            }
+
+            helper.purgeDeletedRecords = function purgeDeletedRecords() {
+                urls.purgeDeletedRecords = t.utils.createTestingUrl('purgeDeletedRecords');
+                t.getR(urls.purgeDeletedRecords).with({fromPeer:'?'})
+                    .fxDone(function purgeDeletedRecords_Complete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+
+                        return;
+                    })
+            }
+
+
+            helper.inSyncAll = function inSyncAll() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            var t2 = EasyRemoteTester.create('TestInSync',
+                                {  showBody:false,  silent:true });
+                            var baseUrl = 'http://'+ peer.ip; //127.0.0.1:'+ b.settings.port;
+                            var urls = {};
+                            t2.settings.baseUrl = baseUrl;
+                            urls.verifySync = t2.utils.createTestingUrl('verifySync');
+                            t2.getR(urls.verifySync).with(
+                                {sync:false,peer:'a'}
+                            )
+                                .fxDone(function syncComplete(result) {
+                                    t2.assert(result.ok==true, 'data not inSync ' + result.ok);
+                                    fxDone();
+                                    return;
+                                });
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+            }
+
+
+
+
+
+
+            helper.addTimer = function addTimer(reason) {
+                t.add(function defineNewNodes() {
+                    if (t.timer  != null ) {
+                        var diff = sh.time.secs(t.timer)
+                        console.log('>');console.log('>');console.log('>');
+                        console.log(t.timerReason, 'time', diff);
+                        console.log('>');console.log('>');console.log('>');
+                    } else {
+
+                    }
+                    t.timerReason = reason;
+                    t.timer = new Date();
+                    t.workChain.utils.wait(1);
+                    t.cb()
+                });
+            }
+
+
+        }
+        defineHelperMethod();
+
+        //t.add(clearAllData())
+        helper.clearAllData()
+
+
+
+
+        t.add(function bPullARecords(){
+            b.pull(t.cb);
+        })
+
+
+        helper.addRecord()
+
+
+
+        //do partial sync
+        //sync from http request methods
+        //batched sync
+        //remove batch tester
+        //cluster config if no config sent
+
+        function defineHTTPTestMethods() {
+            //var t = EasyRemoteTester.create('Test Channel Server basics',{showBody:false});
+            t.settings.baseUrl = baseUrl;
+            urls.getTableData = t.utils.createTestingUrl('getTableData');
+            urls.syncIn = t.utils.createTestingUrl('syncIn');
+            urls.atomicAction = t.utils.createTestingUrl('atomicAction');
+
+
+        }
+        defineHTTPTestMethods();
+
+
+        function atomicSyncTest() {
+            helper.toggleBlocking();
+            helper.clearAllData();
+            helper.getCountsOfAll('counts on start');
+            /*
+             helper.addRecord();
+
+             t.getR(urls.getTableData).with({sync:false})
+             // .bodyHas('status').notEmpty()
+             .fxDone(function syncComplete(result) {
+             return;
+             });
+
+             helper.verifySync();*/
+            //  return;
+
+            helper.verifySync();
+
+            var records =[];
+            var rec=  topology.b.dbHelper2.updateRecordForDb({name:'yyy2'})
+            records = [rec];
+
+            t.getR(urls.atomicAction).with({records:records,
+                type:'update',
+                fromPeer:'?'})
+            // .bodyHas('status').notEmpty()
+                .fxDone(function syncComplete(result) {
+                    return;
+                });
+
+
+            var rec2=  topology.b.dbHelper2.updateRecordForDb({name:'yyy2'})
+            var records2 = [rec2];
+
+            t.getR(urls.atomicAction).with({records:records2,
+                type:'update',
+                fromPeer:'?'})
+            // .bodyHas('status').notEmpty()
+                .fxDone(function syncComplete(result) {
+                    return;
+                });
+
+            t.getR(urls.atomicAction).with({records:records,
+                type:'delete',
+                fromPeer:'?'})
+            // .bodyHas('status').notEmpty()
+                .fxDone(function syncComplete(result) {
+                    return;
+                });
+
+            t.workChain.utils.wait(1);
+            helper.verifyRecourCount(1);
+            helper.getCountsOfAll();
+            helper.verifySync();
+        }
+        atomicSyncTest()
+
+
+
+        function oldTest() {
+
+
+            function define_TestIncrementalUpdate () {
+                urls.getTableData = t.utils.createTestingUrl('getTableDataIncremental');
+
+                t.getR(urls.getTableData).with({sync:false}) //get all records
+                    .fxDone(function syncComplete(result) {
+                        return;
+                    })
+                t.workChain.utils.wait(1);
+                //ResuableSection_verifySync()
+                helper.addRecord();
+
+                t.getR(urls.getTableData).with({sync:false})
+                    .fxDone(function syncComplete(result) {
+                        console.log('>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<')
+                        t.assert(b.lastUpdateSize==1, 'updated wrong # of records ' + b.lastUpdateSize)
+                        return;
+                    })
+
+                helper.verifySync();
+            }
+            define_TestIncrementalUpdate();
+
+
+
+            function define_TestDataIntegrity() {
+                urls.verifySync = t.utils.createTestingUrl('verifySync');
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not integral ' + result.ok)
+                        return;
+                    });
+            }
+            define_TestDataIntegrity();
+
+
+            function define_syncReverse() {
+                helper.addRecord();
+
+                t.add(function addNewRecord() {
+                    b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+                });
+                t.add(function addNewRecord() {
+                    b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+                });
+
+                urls.syncReverse = t.utils.createTestingUrl('syncReverse');
+
+
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'?'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+                helper.verifySync()
+            };
+            define_syncReverse();
+            ;
+
+
+
+
+            function define_TestDataIntegrity2() {
+                helper.forgetRandomRecordFrom();
+                t.workChain.utils.wait(1);
+                helper.forgetRandomRecordFrom();
+                helper.forgetRandomRecordFrom();
+                helper.notInSync();
+                helper.syncBothDirections()
+            }
+            define_TestDataIntegrity2();
+
+            function defineBlockSlowTests() {
+                function define_ResiliancyTest() {
+                    helper.forgetRandomRecordFrom();
+
+                    helper.forgetRandomRecordFrom(topology.a);
+                    helper.forgetRandomRecordFrom(topology.a);
+                    helper.forgetRandomRecordFrom();
+                    helper.notInSync();
+                    //notInSync();
+                    helper.syncBothDirections()
+                    helper.verifySync()
+                    helper.inSync();
+
+                }
+
+                define_ResiliancyTest();
+
+                function define_ResiliancyTest_IllegallyChangedRecords() {
+                    helper.syncBothDirections();
+                    helper.verifySync();
+                    helper.inSync();
+                    t.add(function getRecord() {
+                        b.test.getRandomRecord(function (rec) {
+                            randomRec = rec;
+                            t.cb()
+                        });
+                    });
+                    t.add(function updateRecords() {
+                        randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                    });
+                    helper.notInSync();
+                    //resolve
+                    helper.syncBothDirections();
+
+                    helper.notInSync()//did not upldate global date
+                    t.add(function updateRecords() {
+                        randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                    });
+                    helper.syncBothDirections();
+                    helper.inSync();
+                };
+                define_ResiliancyTest_IllegallyChangedRecords();
+
+                function define_multipleNodes() {
+                    /*t.add(function defineNewNodes() {
+                     augmentNetworkConfiguration()
+                     t.cb()
+                     });*/
+                    helper.clearAllData();
+
+                    helper.syncBothDirections()
+                    helper.verifySync()
+                    helper.inSync();
+                    t.add(function getRecord() {
+                        b.test.getRandomRecord(function (rec) {
+                            randomRec = rec;
+                            t.cb()
+                        });
+                    });
+                    t.add(function updateRecord_skipUpdateTime() {
+                        randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                    });
+                    helper.notInSync()
+                    helper.syncBothDirections()
+                    helper.notInSync(); //did not upldate global date
+                    t.add(function updateRecords() {
+                        randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                    });
+                    helper.syncBothDirections();
+                    helper.inSync();
+                };
+                define_multipleNodes();
+            }
+            defineBlockSlowTests()
+
+            function defineSlowTests2() {
+                function define_TestDeletes() {
+                    helper.syncBothDirections()
+                    helper.verifySync()
+                    helper.deleteRandomRecordFrom(b);
+                    helper.deleteRandomRecordFrom(b);
+                    helper.deleteRandomRecordFrom(topology.c);
+
+                    helper.purgeDeletedRecords();
+
+                    helper.inSync();
+
+                };
+                define_TestDeletes()
+
+                function define_TestDeletes2() {
+                    t.add(function defineNewNodes() {
+                        augmentNetworkConfiguration2()
+                        t.cb()
+                    });
+                    helper.clearAllData();
+
+                    helper.syncBothDirections()
+                    helper.verifySync()
+                    helper.deleteRandomRecordFrom(b);
+                    helper.deleteRandomRecordFrom(b);
+                    helper.deleteRandomRecordFrom(topology.c);
+                    helper.deleteRandomRecordFrom(topology.e);
+
+                    //syncBothDirections();
+                    helper.purgeDeletedRecords();
+                    /*t.add(function getRecord() {
+                     b.test.getRandomRecord(function (rec) {
+                     randomRec = rec;
+                     t.cb()
+                     });
+                     });
+                     t.add(function updateRecords() {
+                     randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+                     });*/
+                    //  notInSync()
+                    // syncBothDirections()
+                    helper.inSync();
+
+                };
+                define_TestDeletes2()
+            }
+            defineSlowTests2()
+
+
+
+            function define_TestHubAndSpoke() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration()
+                    t.cb()
+                });
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration2()
+                    t.cb()
+                });
+                helper.clearAllData();
+
+                helper.addTimer('sync both dirs')
+                helper.syncBothDirections()
+                helper.addTimer('local sync')
+                helper.verifySync()
+                helper.addTimer('deletes')
+                helper.deleteRandomRecordFrom(b);
+                helper.deleteRandomRecordFrom(b);
+                helper.deleteRandomRecordFrom(topology.c);
+                helper.deleteRandomRecordFrom(topology.e);
+
+                helper.addTimer('purge all deletes')
+                //syncBothDirections();
+                helper.purgeDeletedRecords();
+                /*t.add(function getRecord() {
+                 b.test.getRandomRecord(function (rec) {
+                 randomRec = rec;
+                 t.cb()
+                 });
+                 });
+                 t.add(function updateRecords() {
+                 randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+                 });*/
+                //  notInSync()
+                // syncBothDirections()
+                helper.addTimer('insync')
+                helper.inSync();
+                helper.inSyncAll();
+                //TODO: Test sync on N
+                //check in sync on furthes node
+                helper.addTimer('insyncover')
+
+            };
+            define_TestHubAndSpoke()
+        }
+
+
+        //TODO: Add index to updated at
+
+        //test from UI
+        //let UI log in
+        //task page saeerch server
+
+        //account server
+        //TODO: To getLastPage for records
+
+        //TODO: replace getRecords, with getLastPage
+        //TODO: do delete, so mark record as deleted, store in cache,
+        //3x sends, until remove record from database ...
+
+        /*
+         when save to delete? after all synced
+         mark as deleted,
+         ask all peers to sync
+         then delete from database if we delete deleted nodes
+
+         do full sync
+         if deleteMissing -- will remove all records my peers do not have
+         ... risky b/c incomplete database might mess  up things
+         ... only delete records thata re marked as deleted
+         */
+
+        /*
+         TODO:
+         test loading config from settings object with proper cluster config
+         test auto syncing after 3 secs
+         build proper hub and spoke network ....
+         add E node that is linked to d (1 hop away)
+         */
+        /**
+         * store global record count
+         * Mark random record as deleted,
+         * sync
+         * remove deleted networks
+         * sync
+         * ensure record is gone
+         */
+
+        //Revisions
+    }
+}
+
+
+
Index: mptransfer/DAL/SQLListRestHelperServer/RestHelperSQLLite.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/SQLListRestHelperServer/RestHelperSQLLite.js	(revision )
+++ mptransfer/DAL/SQLListRestHelperServer/RestHelperSQLLite.js	(revision )
@@ -0,0 +1,481 @@
+/**
+ * Designed to test all ritv functions
+ * @type {*}
+ */
+
+var shelpers = require('shelpers');
+var sh = shelpers.shelpers;
+var SettingsHelper = require('shelpers').SettingsHelper;
+
+var ExpressServerHelper = shelpers.ExpressServerHelper
+var RestHelperSQLTest = require('shelpers').RestHelperSQLTest;
+var Sequelize = RestHelperSQLTest.Sequelize;
+
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+
+function RestHelperJSONFileBasedServer() {
+    var p = RestHelperJSONFileBasedServer.prototype;
+    p = this;
+    var self = this;
+
+    self.init = function init(config){
+        var defaultSettings = {
+            port: 10005,
+            dir: 'requests/',
+            //dirHtml: 'ritv_public_html/', //
+            dirHtml: '../quick/', //
+            mysql:{
+                database:'fileserver',
+                user:"root",
+                password:'password',
+                port:3306
+            },
+            wildcards:false,
+            enableAnonymouse:true,
+            noProxy:true,
+            // force:false,
+            fxDone:self.fxServerStarted
+        }
+        var settings = {};
+        sh.mergeObjects(config, settings)
+        sh.mergeObjects(defaultSettings, settings)
+
+        self.settings = settings;
+        self.settings.noSQL = true;
+
+        self.init2()
+    }
+
+
+    p.init2 = function init2(settings) {
+        var express = require('express');
+        var app = express();
+        self.settings2 = sh.clone(self.settings);
+        self.app = app;
+
+        var bodyParser = require('body-parser');
+        var session = require('express-session');
+        var cookieParser= require('cookie-parser');
+        //var FileStore = require('session-file-store')(session);
+
+        //self.define_YeomanRoutes(app);
+
+        function allowCrossDomainMiddlware (req, res, next) {
+            res.header('Access-Control-Allow-Origin', '*');
+            res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
+            res.header('Access-Control-Allow-Headers', 'Content-Type');
+            next();
+        }
+        app.use(allowCrossDomainMiddlware)
+        app.use(bodyParser());
+        app.use(cookieParser());
+        /* app.use(session({ store: new FileStore(
+         {path: 'anon_sessions' }),
+         secret: 'spaceyok', resave: false, saveUninitialized: true }));
+         */
+        self.setupDataStores()
+
+
+        app.listen(self.settings.port)
+        self.proc('start on port', self.settings.port)
+
+        self.fxServerStarted();
+    }
+
+    p.setupDataStores = function setupDataStores() {
+
+        self.t  = EasyRemoteTester.create('test everything');
+        self.t.wait(2);
+
+        //self.define_PromptsJSON();
+        self.define_PromptsSQLite();
+
+        //self.define_Prompts_Log(s.server);
+
+        return;
+
+    }
+
+    p.fxServerStarted = function fxServerStarted() {
+        self.runTests();
+    }
+
+
+    p.define_PromptsJSON = function defineBreadcrumbRestHelper() {
+        //server = self.cQS.credentialsServer.api;
+        self.promptsJSON = RestHelperSQLTest.createHelper('promptjson',
+            self.app,
+            {
+                name:'promptjson',
+                file:'G:/Dropbox/projects/crypto/ritv/distillerv3/tools/santizename/output/missing imdb info.json',
+                fileUseAltFileForSafety:true,
+                fields:
+                {name: "", desc: "", user_id: 0, imdb_id: "", minutes: 0,
+                    one_per_day:true, data:"" , data_json:"text"},
+                fxUserId:self.utils.getUserIdFromSession,
+                noSQL:self.settings.noSQL,
+
+                //fxGetUserId:LoginAPIConsumerService.pullSessionIDFromRequest,
+                //fxStart:testBreadCrumbsUserId
+                //port:self.settings.port,
+            }
+        );
+
+    }
+
+    p.define_PromptsSQLite = function define_PromptsSQLite(server) {
+        //server = self.cQS.credentialsServer.api;
+        self.promptsql = RestHelperSQLTest.createHelper('promptsql',
+            self.app,
+            {
+                name:'promptsql',
+                fields:
+                {name: "", desc: "", user_id: 0, color: "", comments: "",
+                    data:"", progress:0, data_json:"text"},
+                fxUserId:self.utils.getUserIdFromSession,
+                noSQL:self.settings.noSQL,
+                sqLite:true,
+                //fxGetUserId:LoginAPIConsumerService.pullSessionIDFromRequest,
+                //fxStart:testBreadCrumbsUserId
+                //port:self.settings.port,
+            }
+        );
+
+
+
+
+    }
+
+    function defineTestHelpers() {
+        self.startupTests = [];
+        self.addToTest = function addToTests(item, name) {
+            self.startupTests.push({name:name, fx:item})
+        }
+        self.runTests = function runTests(item, name) {
+
+            sh.each(self.startupTests, function runTest(k,v){
+                sh.logLine = function logLine(times) {
+                    sh.times(times, function(){console.log();});
+                }
+                sh.times = function times(count, fx) {
+                    for (var i = 0; i < count; i++) {
+                        fx(i);
+                    }
+                }
+                sh.logLine(3)
+                self.proc('running test', v.name)
+                sh.logLine(3)
+                v.fx();
+            })
+
+            self.runRemoteUrlTest();
+            // self.startupTests.push({name:name, item:item})
+        }
+
+        self.createTestingUrl = function createTestingUrl(end){
+            var url = 'http://localhost:' + self.settings.port ;//+ '/' + end;
+            if ( ! sh.startsWith(end , '/')){
+                url += '/';
+            }
+            url += end;
+
+            return url;
+        }
+
+        p.runRemoteUrlTest = function runRemoteUrlTest() {
+            // return;
+            var config = {showBody:false};
+            var ip = '127.0.0.1:'+self.settings.port;
+            config.baseUrl = ip;
+            //self.utils.updateTestConfig(config);
+            var t = EasyRemoteTester.create('Sync Peer', config);
+            var urls = {};
+
+            urls.getCount = t.utils.createTestingUrl('api/prompt/count');
+            urls.getRecords = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage = t.utils.createTestingUrl('getNextPage');
+
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+
+            /*
+             t.getR(urls.getCount).why('get getCount')
+             // .with(reqData).storeResponseProp('count', 'count')
+             //self.dalLog("\t\t\t", 'onGotNextPage-search-start-a', actorsStr , JSON.stringify(query) )
+
+             t.add(function getRecordCount(){
+             // var recordCount = t.data.count;
+             t.cb();
+             });
+             */
+
+            self.promptsql.defineTestUtils(t);
+
+            return;
+
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+                        // reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.addNext(function verifyRecords(){
+                            var query = {};
+                            var dateFirst = new Date(body[0].global_updated_at);
+                            if ( body.length > 1 ) {
+                                var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                            } else {
+                                dateLast = dateFirst
+                            }
+                            query.where = {
+                                global_updated_at: {$gte:dateFirst},
+                                $and: {
+                                    global_updated_at: {$lte:dateLast}
+                                }
+                            };
+                            query.order = ['global_updated_at',  'DESC'];
+                            self.dbHelper2.search(query, function gotAllRecords(recs){
+                                var yquery = query;
+                                var match = self.dbHelper2.compareTables(recs, body);
+                                if ( match != true ) {
+                                    t.matches.push(t.iterations)
+                                    self.proc('match issue on', self.settings.name, peerName, t.iterations, recs.length, body.length)
+                                }
+                                t.cb();
+                            } )
+                        })
+                        t.addNext(getRecordsUntilFinished)
+                    }
+                    t.recordCount += body.length;
+                    t.iterations  += 1
+                    t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function filterNewRecordsForPeerSrc(){
+                t.ok = t.matches.length == 0;
+                t.cb();
+            })
+            t.add(function deleteAllRecordsForPeerName(){
+                t.cb();
+            })
+            /* t.add(function countRecords(){
+             self.dbHelper2.count(  function upserted(count){
+             self.size = count;
+             t.cb();
+             })
+             })*/
+            t.add(function verifySync(){
+                self.proc('verifying', self.settings.name, self.count, ip, t.recordCount)
+                //    self.lastUpdateSize = t.recordsAll.length;
+                //  if ( t.recordsAll.length > 0 )
+                //        self.dictPeerSyncTime[ip] = t.recordsAll[0].global_updated_at;
+                sh.callIfDefined(cb, t.ok)
+            })
+
+
+        }
+    }
+    defineTestHelpers();
+
+
+    function defineUtils() {
+        self.utils = {}
+        self.utils.generateFakeContentForContentAPI = function generateFakeContentForContentAPI() {
+            var GenerateData = shelpers.GenerateData;
+            var gen = new GenerateData();
+
+            var input = ['Game of Thrones', '4x12', 'The Blacklist',
+                'Empire', "Grey's Anatomy", '6x20',
+                "Schindler's List", 'Raging Bull', 'the Godfather', ''];
+
+            function addSrc(obj) {
+                obj.src = ''
+                var content = 'content/';
+                /*sh.str.ifStr(obj.series, 'series/')+
+                 sh.str.ifStr(obj.series && obj.name != null, obj.name+'/')+
+                 sh.str.ifStr(obj.series && obj.name != null, obj.name+'/')+
+                 '.mp4'*/
+                if (obj.series == true) {
+                    content += 'series/';
+                    if (obj.series_name != null) {
+                        content += obj.series_name //+ ' - '
+                    }
+                    if (obj.name != null) {
+                        content += ' - ' + obj.name //+ ' - '
+                    }
+                    content += ' ' + obj.season + 'x' + obj.episode;
+                }
+                else {
+                    //if ( obj.name != null ) {
+                    content += obj.name// + ' - '
+
+                    if ( obj.name == 'Raging Bull') {
+                        obj.year = 1980
+                        obj.imdb_id = 'tt0081398'
+                    }
+                    if ( obj.name == 'the Godfather') {
+                        obj.year = 1972
+                        obj.imdb_id = 'tt0068646'
+                    }
+
+
+                    //}
+                    //content += obj.season + ' x ' + obj.episode;
+                }
+
+                content += '.mp4';
+                obj.src = content;
+
+            }
+
+            function isNumber(n) {
+                return !isNaN(parseFloat(n)) && isFinite(n);
+            }
+
+
+            function makeArray(input) {
+                var output = []
+                var prev = {}
+                for (var i = 0; i < input.length; i++) {
+                    var item = input[i]
+
+                    var next = input[i + 1];
+
+                    var firstNumber = false
+
+                    if (next != null) {
+                        firstNumber = next.slice(0, 1)
+                    }
+
+
+                    if (isNumber(firstNumber)) {
+                        i++;
+
+
+                        output.pop();
+
+
+                        var s = next.split('x')[0];
+                        var e = next.split('x')[1];
+                        s = parseInt(s)
+                        e = parseInt(e)
+                        for (var sea = 1; sea < s; sea++) {
+
+                            for (var epi = 1; epi < e; epi++) {
+                                var obj = sh.clone(prev);
+                                obj.season = sea;
+                                obj.episode = epi;
+                                obj.series = true;
+                                obj.series_name = item;
+
+                                addSrc(obj);
+
+                                obj.desc = item + ' ' +
+                                    obj.season + 'x' + obj.episode;
+                                output.push(obj);
+                            }
+
+                        }
+
+
+                        continue;
+                    }
+
+                    var obj = {}
+                    obj.name = item;
+                    obj.desc = item;
+                    addSrc(obj);
+                    output.push(obj);
+                    prev = obj;
+
+                }
+                return output
+            }
+
+
+            var output = makeArray(input)
+            var model = gen.create(output, function (item, id, dp) {
+                //item.name = id;
+                // item.id = id;
+                //item.desc = GenerateData.getName();
+
+                item.imdb_id= sh.dv(item.imdb_id,'tt'+(id+100));
+            });
+
+            return model;
+        }
+
+        self.convertQueryParamToQuery = function (req) {
+            //TODO: move this code somewhere else
+            var query = req.query;//JSON.parse(req.query);
+
+            if ( req.query.pquery != null ) {
+                query =JSON.parse( req.query.pquery )
+            }
+
+            var andLimits = [];
+            andLimits.push({ src: {like:"%"+query.name+"%"} })
+            if (query.season_name) {
+                andLimits.push({ src: {like: "%" + query.season_name + "%"} })
+            }
+            if (query.episode) {
+                andLimits.push({ episode:query.episode });
+            }
+            if (query.season) {
+                andLimits.push({ season:query.season });
+            }
+
+            if (query.year && false == true ) {
+                andLimits.push({ year:  query.year  })
+            }
+            var arr =  Sequelize.and.apply(this, andLimits)
+
+            var query_ = {where:query}
+            query_.limit = 10;
+            req.query = query_;
+        }
+
+        self.utils.getUserIdFromSession = function getUserIdFromSession(req){
+            if ( self.login == false ) {
+                return 2;
+                //return null;
+            }
+            return req.session.user_id;
+        }
+        self.utils.getUserIdFromSession = null;
+    }
+    defineUtils();
+
+    /**
+     * Receive log commands in special format
+     */
+    p.proc = function proc() {
+        sh.sLog(arguments)
+    }
+
+}
+
+
+
+
+
+
+var s = new RestHelperJSONFileBasedServer()
+s.init();
+
Index: mptransfer/DAL/.gitignore
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/.gitignore	(revision )
+++ mptransfer/DAL/.gitignore	(revision )
@@ -0,0 +1,6 @@
+server_config_override_file_deploy.json
+server_config_override_file_local.json
+server_config_internal.json
+search_server/sessions_test/*.json
+utils/database/database_export.sql
+node_scripts/search_server/sessions_test/*.json
Index: mptransfer/DAL/SQLListRestHelperServer/RestHelperSQLLite.js.bak
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/SQLListRestHelperServer/RestHelperSQLLite.js.bak	(revision )
+++ mptransfer/DAL/SQLListRestHelperServer/RestHelperSQLLite.js.bak	(revision )
@@ -0,0 +1,361 @@
+/**
+ * Designed to test all ritv functions
+ * @type {*}
+ */
+
+var shelpers = require('shelpers');
+var sh = shelpers.shelpers;
+var SettingsHelper = require('shelpers').SettingsHelper;
+
+var ExpressServerHelper = shelpers.ExpressServerHelper
+var RestHelperSQLTest = require('shelpers').RestHelperSQLTest;
+var Sequelize = RestHelperSQLTest.Sequelize;
+
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+
+
+function RestHelperJSONFileBasedServer() {
+    var p = RestHelperJSONFileBasedServer.prototype;
+    p = this;
+    var self = this;
+
+    self.init = function init(config){
+        var defaultSettings = {
+            port: 10002,
+            dir: 'requests/',
+            //dirHtml: 'ritv_public_html/', //
+            dirHtml: '../quick/', //
+            mysql:{
+                database:'fileserver',
+                user:"root",
+                password:'password',
+                port:3306
+            },
+            wildcards:false,
+            enableAnonymouse:true,
+            noProxy:true,
+            // force:false,
+            fxDone:self.fxServerStarted
+        }
+        var settings = {};
+        sh.mergeObjects(config, settings)
+        sh.mergeObjects(defaultSettings, settings)
+
+        self.settings = settings;
+        self.settings.noSQL = true;
+
+        self.init2()
+    }
+
+
+    p.init2 = function init2(settings) {
+        var express = require('express');
+        var app = express();
+        self.settings2 = sh.clone(self.settings);
+        self.app = app;
+
+        var bodyParser = require('body-parser');
+        var session = require('express-session');
+        var cookieParser= require('cookie-parser');
+        var FileStore = require('session-file-store')(session);
+
+        //self.define_YeomanRoutes(app);
+
+        function allowCrossDomainMiddlware (req, res, next) {
+            res.header('Access-Control-Allow-Origin', '*');
+            res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
+            res.header('Access-Control-Allow-Headers', 'Content-Type');
+            next();
+        }
+        app.use(allowCrossDomainMiddlware)
+        app.use(bodyParser());
+        app.use(cookieParser());
+        app.use(session({ store: new FileStore(
+            {path: 'anon_sessions' }),
+            secret: 'spaceyok', resave: false, saveUninitialized: true }));
+
+        self.setupDataStores()
+
+
+        app.listen(self.settings.port)
+        self.proc('start on port', self.settings.port)
+    }
+
+    p.setupDataStores = function setupDataStores() {
+
+        self.t  = EasyRemoteTester.create('test everything');
+        self.t.wait(2);
+
+        self.define_Prompts();
+       // self.define_Prompts_Log(s.server);
+
+        return;
+
+    }
+
+    p.fxServerStarted = function fxServerStarted() {
+        self.runTests();
+    }
+
+
+    p.define_Prompts = function defineBreadcrumbRestHelper() {
+        //server = self.cQS.credentialsServer.api;
+        self.prompts = RestHelperSQLTest.createHelper('prompt',
+            self.app,
+            {
+                name:'dls',
+                file:'G:/Dropbox/projects/crypto/ritv/distillerv3/tools/santizename/output/missing imdb info.json',
+                fileUseAltFileForSafety:true,
+                fields:
+                {name: "", desc: "", user_id: 0, imdb_id: "", minutes: 0,
+                    one_per_day:true, data:"" , data_json:"text"},
+                fxUserId:self.utils.getUserIdFromSession,
+                noSQL:self.settings.noSQL,
+                //fxGetUserId:LoginAPIConsumerService.pullSessionIDFromRequest,
+                //fxStart:testBreadCrumbsUserId
+                //port:self.settings.port,
+            }
+        );
+    }
+
+    p.define_Prompts_Log = function define_Prompts_RestHelper(server) {
+        //server = self.cQS.credentialsServer.api;
+        self.promptsLog = RestHelperSQLTest.createHelper('promptlog',
+            server,
+            {
+                name:'promptlog',
+                fields:
+                {name: "", desc: "", user_id: 0, color: "", comments: "",
+                    data:"", progress:0, data_json:"text"},
+                fxUserId:self.utils.getUserIdFromSession,
+                noSQL:self.settings.noSQL,
+                //fxGetUserId:LoginAPIConsumerService.pullSessionIDFromRequest,
+                //fxStart:testBreadCrumbsUserId
+                //port:self.settings.port,
+            }
+        );
+
+    }
+
+    function defineTestHelpers() {
+        self.startupTests = [];
+        self.addToTest = function addToTests(item, name) {
+            self.startupTests.push({name:name, fx:item})
+        }
+        self.runTests = function runTests(item, name) {
+
+            sh.each(self.startupTests, function runTest(k,v){
+                sh.logLine = function logLine(times) {
+                    sh.times(times, function(){console.log();});
+                }
+                sh.times = function times(count, fx) {
+                    for (var i = 0; i < count; i++) {
+                        fx(i);
+                    }
+                }
+                sh.logLine(3)
+                self.proc('running test', v.name)
+                sh.logLine(3)
+                v.fx();
+            })
+            // self.startupTests.push({name:name, item:item})
+        }
+
+        self.createTestingUrl = function createTestingUrl(end){
+            var url = 'http://localhost:' + self.settings.port ;//+ '/' + end;
+            if ( ! sh.startsWith(end , '/')){
+                url += '/';
+            }
+            url += end;
+
+            return url;
+        }
+    }
+    defineTestHelpers();
+
+
+    function defineUtils() {
+        self.utils = {}
+        self.utils.generateFakeContentForContentAPI = function generateFakeContentForContentAPI() {
+            var GenerateData = shelpers.GenerateData;
+            var gen = new GenerateData();
+
+            var input = ['Game of Thrones', '4x12', 'The Blacklist',
+                'Empire', "Grey's Anatomy", '6x20',
+                "Schindler's List", 'Raging Bull', 'the Godfather', ''];
+
+            function addSrc(obj) {
+                obj.src = ''
+                var content = 'content/';
+                /*sh.str.ifStr(obj.series, 'series/')+
+                 sh.str.ifStr(obj.series && obj.name != null, obj.name+'/')+
+                 sh.str.ifStr(obj.series && obj.name != null, obj.name+'/')+
+                 '.mp4'*/
+                if (obj.series == true) {
+                    content += 'series/';
+                    if (obj.series_name != null) {
+                        content += obj.series_name //+ ' - '
+                    }
+                    if (obj.name != null) {
+                        content += ' - ' + obj.name //+ ' - '
+                    }
+                    content += ' ' + obj.season + 'x' + obj.episode;
+                }
+                else {
+                    //if ( obj.name != null ) {
+                    content += obj.name// + ' - '
+
+                    if ( obj.name == 'Raging Bull') {
+                        obj.year = 1980
+                        obj.imdb_id = 'tt0081398'
+                    }
+                    if ( obj.name == 'the Godfather') {
+                        obj.year = 1972
+                        obj.imdb_id = 'tt0068646'
+                    }
+
+
+                    //}
+                    //content += obj.season + ' x ' + obj.episode;
+                }
+
+                content += '.mp4';
+                obj.src = content;
+
+            }
+
+            function isNumber(n) {
+                return !isNaN(parseFloat(n)) && isFinite(n);
+            }
+
+
+            function makeArray(input) {
+                var output = []
+                var prev = {}
+                for (var i = 0; i < input.length; i++) {
+                    var item = input[i]
+
+                    var next = input[i + 1];
+
+                    var firstNumber = false
+
+                    if (next != null) {
+                        firstNumber = next.slice(0, 1)
+                    }
+
+
+                    if (isNumber(firstNumber)) {
+                        i++;
+
+
+                        output.pop();
+
+
+                        var s = next.split('x')[0];
+                        var e = next.split('x')[1];
+                        s = parseInt(s)
+                        e = parseInt(e)
+                        for (var sea = 1; sea < s; sea++) {
+
+                            for (var epi = 1; epi < e; epi++) {
+                                var obj = sh.clone(prev);
+                                obj.season = sea;
+                                obj.episode = epi;
+                                obj.series = true;
+                                obj.series_name = item;
+
+                                addSrc(obj);
+
+                                obj.desc = item + ' ' +
+                                    obj.season + 'x' + obj.episode;
+                                output.push(obj);
+                            }
+
+                        }
+
+
+                        continue;
+                    }
+
+                    var obj = {}
+                    obj.name = item;
+                    obj.desc = item;
+                    addSrc(obj);
+                    output.push(obj);
+                    prev = obj;
+
+                }
+                return output
+            }
+
+
+            var output = makeArray(input)
+            var model = gen.create(output, function (item, id, dp) {
+                //item.name = id;
+                // item.id = id;
+                //item.desc = GenerateData.getName();
+
+                item.imdb_id= sh.dv(item.imdb_id,'tt'+(id+100));
+            });
+
+            return model;
+        }
+
+        self.convertQueryParamToQuery = function (req) {
+            //TODO: move this code somewhere else
+            var query = req.query;//JSON.parse(req.query);
+
+            if ( req.query.pquery != null ) {
+                query =JSON.parse( req.query.pquery )
+            }
+
+            var andLimits = [];
+            andLimits.push({ src: {like:"%"+query.name+"%"} })
+            if (query.season_name) {
+                andLimits.push({ src: {like: "%" + query.season_name + "%"} })
+            }
+            if (query.episode) {
+                andLimits.push({ episode:query.episode });
+            }
+            if (query.season) {
+                andLimits.push({ season:query.season });
+            }
+
+            if (query.year && false == true ) {
+                andLimits.push({ year:  query.year  })
+            }
+            var arr =  Sequelize.and.apply(this, andLimits)
+
+            var query_ = {where:query}
+            query_.limit = 10;
+            req.query = query_;
+        }
+
+        self.utils.getUserIdFromSession = function getUserIdFromSession(req){
+            if ( self.login == false ) {
+                return 2;
+                //return null;
+            }
+            return req.session.user_id;
+        }
+    }
+    defineUtils();
+
+    /**
+     * Receive log commands in special format
+     */
+    p.proc = function proc() {
+        sh.sLog(arguments)
+    }
+
+}
+
+
+
+
+
+
+var s = new RestHelperJSONFileBasedServer()
+s.init();
+
Index: mptransfer/DAL/sql_sharing_server/supporting/public_html/dashboard_dal.html
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/public_html/dashboard_dal.html	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/public_html/dashboard_dal.html	(revision )
@@ -0,0 +1,59 @@
+
+
+<!DOCTYPE html>
+<html>
+<head>
+    <title></title>
+
+    <script src="jquery-2.0.2.js.ignore_scan"></script>
+    <script src="bootstrap.min.3.js.ignore_scan"></script>
+    <link rel="stylesheet" type="text/css" href="bootstrap-theme.min.css.ignore_scan" />
+    <link rel="stylesheet" type="text/css" href="bootstrap.min.css.ignore_scan" />
+    <script src="db.js"></script>
+
+    <style>
+        .hide {
+            display: none;
+        }
+    </style>
+</head>
+<body>
+
+<div id="txtTitle" ></div>
+
+<div>
+    All Nodes
+    call get nodes on all my nodes as an atomic action
+    get peers call on 1 person.
+    make request to server, put response in textarea
+
+
+</div>
+
+<div>
+    List and delete
+    make request, load json in list using quick list component json from site.
+    delete button will callf unction in new window and trigger reload
+</div>
+
+<div>
+    Sync All
+    make request, put repsonse in div
+</div>
+
+<div>
+    DB Size
+    DB Stats
+    Synced?
+</div>
+
+<div>
+    Run Query
+</div>
+
+<div>
+    Disable  / Enable
+</div>
+
+</body>
+</html>
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/supporting/DalBasicRoutesHelpers.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DalBasicRoutesHelpers.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DalBasicRoutesHelpers.js	(revision )
@@ -0,0 +1,724 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+var querystring= require('querystring');
+
+function DalBasicRoutesHelpers(_self) {
+    var p = DalBasicRoutesHelpers.prototype;
+    p = this;
+    var self = this;
+    if ( _self ){  self = _self; p = self }
+
+    function defineRoutes() {
+        self.showCluster = function showCluster(req, res) {
+            res.send(self.settings);
+        };
+        self.showTable  = function showCluster(req, res) {
+            res.send('ok');
+        };
+
+
+        self.verifySync = function verifySync(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            self.pull2( function syncComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                res.send(result);
+            } );
+
+        };
+
+        self.syncIn = function syncIn_pullAction(req, res) {
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                //throw new Error('... blocked ....')
+                return ;
+            };
+            var incremental = false;
+            if ( req.originalUrl.indexOf('getTableDataIncre') != -1 ) {
+                incremental = true;
+            };
+
+            var synchronousMode = req.query.sync == "true";
+            var  config = {};
+            config.skipPeer =  req.query.fromPeer;
+            self.pullRecordsFromPeers( function syncComplete(result) {
+                if ( synchronousMode == false ) {
+                    if ( sh.isFunction(res)){
+                        res(result);
+                        return;
+                    }
+                    res.send('ok');
+                }
+            }, incremental, config );
+
+            if ( synchronousMode ) {
+                res.send('ok');
+            }
+        };
+
+        self.syncReverse = function syncReverse(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                asdf.g
+                return ;
+            }
+            var  itConfig = {};
+            var fromPeer = req.query.fromPeer;
+            itConfig.skipPeer =  fromPeer; //why: don't try to sync bakc to pper yet
+             if ( req.query.oneshot == 'true' ){
+                itConfig.onlySyncPeer = itConfig.skipPeer;
+                itConfig.skipPeer= null;
+            }
+            if ( fromPeer == null ) {
+                throw new Error('need peer')
+            };
+
+           // self.proc('syncReverse', self.settings.name, )
+            self.utils.forEachPeer(fxEachPeer, fxComplete);
+
+            function fxEachPeer(ip, fxDone) {
+                var config = {showBody:false};
+                /*if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                 fxDone()
+                 return;
+                 }*/
+
+                var peerName = self.utils.peerHelper.getPeerNameFromIp(ip);
+
+                if ( itConfig.skipPeer && peerName == itConfig.skipPeer ) {
+                  //asdf.g
+                    /*fxDone();
+                    return;*/
+                }
+
+                if ( itConfig.onlySyncPeer && peerName != itConfig.onlySyncPeer ) {
+                    /*fxDone();
+                    return;*/ //TODO: 8/25/2016: This is not good to have
+                }
+
+                self.dalLogX('revsync', peerName, req.query.fromPeer);
+                self.utils.updateTestConfig(config)
+                config.baseUrl = ip;
+                var t = EasyRemoteTester.create('Sync Peer', config);
+                var urls = {};
+                urls.syncIn = t.utils.createTestingUrl('syncIn');
+                var reqData = {};
+                reqData.data =  0
+                t.getR(urls.syncIn).why('get syncronize the other side')
+                    .with(reqData).storeResponseProp('count', 'count')
+                // t.addSync(fxDone)
+                t.add(function onFinishedWithSyncIn(){
+                    self.proc('you ready...')
+                    fxDone()
+                    t.cb();
+                })
+                //fxDone();
+            }
+            function fxComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                if ( sh.isFunction(res)){
+                    res(result);
+                    return;
+                }
+                res.send(result);
+            }
+        };
+
+
+        /**
+         * Delete all deleted records
+         * Forces a sync with all peers to ensure errors are not propogated
+         * @param req
+         * @param res
+         */
+        self.purgeDeletedRecords = function purgeDeletedRecords(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var fromPeer = self.utils.getPeerForRequest(req);
+
+            var fromPeerChain = req.query.fromPeerChain;
+            fromPeerChain = sh.dv(fromPeerChain, fromPeer+(self.settings.name));
+
+            var config = {showBody:false};
+            self.utils.updateTestConfig(config);
+            //config.baseUrl = ip;
+            var t = EasyRemoteTester.create('Delete Purged Records', config);
+            var urls = {};
+
+            var secondStep = false;
+            if ( req.query.secondStep == 'true') {
+                secondStep = true
+            }
+
+            var reqData = {};
+            reqData.data =  0
+
+            if ( secondStep != true ) { //if this is first innovacation (not subsequent invocaiton on peers)
+                /*t.getR(urls.syncIn).why('get syncronize the other side')
+                 .with(reqData).storeResponseProp('count', 'count')
+                 // t.addSync(fxDone)
+                 t.add(function(){
+                 fxDone()
+                 t.cb();
+                 })*/
+
+                t.add(function step1_syncIn_allPeers(){
+                    self.syncIn(req, t.cb)
+                });
+                t.add(function step2_syncOut_allPeers(){
+                    self.syncReverse(req, t.cb)
+                });
+                t.add(function step3_purgeDeleteRecords_onAllPeers(){
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        var config = {showBody:false};
+                        config.baseUrl = ip;
+                        self.utils.updateTestConfig(config)
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep =  true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerIp = self.settings.ip;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone()
+                            return;
+                        }
+                        urls.purgeDeletedRecords = t2.utils.createTestingUrl('purgeDeletedRecords');
+                        urls.purgeDeletedRecords += self.utils.url.appendUrl(self.utils.url.from(ip))
+                        t2.getR(urls.purgeDeletedRecords).why('...')
+                            .with(reqData)
+                        t2.add(function(){
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+
+
+
+                    // self.syncReverse(req, t.cb)
+                });
+
+
+            } else {
+                //sync from all other peers ... ?
+                //skip the peer that started this sync ? ...
+
+                /*t.add(function step1_syncIn_allPeers(){
+                 self.syncIn(req, t.cb, req.query.fromPeer)
+                 });
+                 t.add(function step2_syncOut_allPeers(){
+                 self.syncReverse(req, t.cb,  req.query.fromPeer)
+                 });*/
+                t.add(function step1_updateAll_OtherPeers() {
+                    var skipPeer = req.query.fromPeer;
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone()
+                            return;
+                        };
+
+                        var config = {showBody: false};
+                        self.utils.updateTestConfig(config);
+                        config.baseUrl = ip;
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep = true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        reqData.xPath = sh.dv(reqData.xPath, '')
+                        reqData.xPath += '_'+reqData.fromPeer
+
+                        urls.syncIn = t2.utils.createTestingUrl('syncIn');
+                        urls.syncReverse = t2.utils.createTestingUrl('syncReverse');
+                        urls.purgeDeletedRecords = t2.utils.createTestingUrl('purgeDeletedRecords');
+                        urls.purgeDeletedRecords += self.utils.url.appendUrl(self.utils.url.from(ip))
+                        t2.getR(urls.syncIn).why('...')
+                            .with(reqData)
+                        t2.getR(urls.syncReverse).why('...')
+                            .with(reqData)
+                        t2.getR(urls.purgeDeletedRecords).why('...')
+                            .with(reqData)
+                        t2.add(function () {
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+                });
+            }
+
+            t.add(function step4_purgeRecordsLocally(){
+                self.dbHelper2.purgeDeletedRecords( recordsDeleted);
+
+                function recordsDeleted() {
+                    var result = {}
+                    result.ok = true;
+                    res.send(result)
+                }
+            });
+
+        }
+
+        /**
+         * Do an action on all nodes in cluster.
+         * @param req
+         * @param res
+         */
+        self.atomicAction = function atomicAction(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var fromPeer = self.utils.getPeerForRequest(req);
+            if ( fromPeer == '?' ){
+                fromPeer = self.settings.name;
+              //  asdf.g
+                self.dalLogReset()
+                var initialRequest = true;
+            }
+            //if fromPeer not in list .... drop request ...
+            var fromPeerChain = req.query.fromPeerChain;
+            fromPeerChain = sh.dv(fromPeerChain, fromPeer+'-->'+(self.settings.name));
+
+            var config = {showBody:false};
+            config.silent = true
+            self.utils.updateTestConfig(config);
+            //config.baseUrl = ip;f
+            var tOuter = EasyRemoteTester.create('Commit atomic action', config);
+            var urls = {};
+
+            var secondStep = false;
+            if ( req.query.secondStep == 'true') {
+                secondStep = true
+            }
+            var allowRepeating = true;
+
+            var reqData = {};
+            reqData.data =  0
+            var records = req.query.records;
+            var actionType = req.query.type;
+            var level =  reqData.level
+
+
+
+            self.dalLog("atomicAction",  self.settings.name, actionType, level, fromPeer, fromPeerChain     )
+
+            if ( level == null ) {
+                level = 0
+            }
+            if ( actionType == 'update' ) {
+                if ( records == null || records.length == 0 ) {
+                    var result = {}
+                    result.status = false
+                    result.msg = 'no records sent ... cannot update'
+                    res.status(410)
+                    res.send(result)
+                    return
+
+                }
+            }
+
+
+            if ( actionType == null ) {
+                throw new Error('need action type')
+            }
+
+
+            var nestedResults = {};
+            //if ( secondStep != true || allowRepeating ) { //if this is first innovacation (not subsequent invocaiton on peers)
+
+            /*t.add(function step1_syncIn_allPeers(){
+             self.syncIn(req, t.cb)
+             });
+             t.add(function step2_syncOut_allPeers(){
+             self.syncReverse(req, t.cb)
+             });*/
+            tOuter.add(function sendActionToAllPeers(){
+                self.utils.forEachPeer(fxEachPeer, fxComplete);
+                function fxEachPeer(ip, fxDone) {
+                    if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                        fxDone();   return;   }
+                    var config = {showBody:false};
+                    config.baseUrl = ip;
+                    config.silent = true
+                    self.utils.updateTestConfig(config)
+                    var t2 = EasyRemoteTester.create('Commit atomic on peers', config);
+                    var reqData = {};
+                    reqData.secondStep =  true; //prevent repeat of process
+                    reqData.level = level;
+                    reqData.records = req.query.records;
+                    reqData.type = req.query.type;
+                    reqData.fromPeer = self.settings.name;
+                    reqData.fromPeerIp = self.settings.ip;
+                    reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+
+                    console.error('step 1', req.level, reqData.fromPeer, ip)
+                    urls.atomicAction = t2.utils.createTestingUrl('atomicAction');
+                    urls.atomicAction += self.utils.url.appendUrl(
+                        self.utils.url.from(ip),
+                        {type:actionType})
+                    t2.getR(urls.atomicAction).why('...')
+                        .with(reqData)
+                        .fxDone(function onReqDone(data) {
+                            if ( actionType == 'count') {
+                                nestedResults[data.name]=data;
+                            }
+                            return data;
+                        })
+                    t2.add(function(){
+                        fxDone()
+                        t2.cb();
+                    })
+                }
+                function fxComplete(ok) {
+
+                    tOuter.cb();
+                }
+            });
+
+
+            // } else {
+
+
+            //
+            if (actionType == 'sync' && false ) { //this just takes longer,
+                //not gaurnateed to work
+                tOuter.add(function step1_updateAll_OtherPeers() {
+
+
+                    var skipPeer = req.query.fromPeer;
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone(); return; };
+
+                        var config = {showBody: false};
+                        config.silent = true
+                        self.utils.updateTestConfig(config);
+                        config.baseUrl = ip;
+                        console.error('step 2', req.level,self.settings.name, ip)
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep = true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        reqData.xPath = sh.dv(reqData.xPath, '')
+                        reqData.xPath += '_'+reqData.fromPeer
+                        reqData.records = req.query.records;
+                        reqData.type = req.query.type;
+                        urls.atomicAction = t2.utils.createTestingUrl('atomicAction');
+                        urls.atomicAction += self.utils.url.appendUrl(
+                            self.utils.url.from(ip),
+                            {type:actionType})
+                        t2.getR(urls.atomicAction).why('...')
+                            .with(reqData)
+                        t2.add(function () {
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+                        tOuter.cb();
+                    }
+                });
+            }
+            //}
+
+            tOuter.add(function step4_purgeRecordsLocally(){
+
+                var logOutInput = false;
+                if ( logOutInput) {   console.error('done', req.query.type, self.settings.name) }
+                if ( req.query.type == 'update') {
+                    self.dbHelper2.upsert(records, function upserted() {
+                        console.error('done2', req.query.type, self.settings.name)
+                        //  t.cb();
+                        var result = {}
+                        result.ok = true;
+                        self.proc('return', self.settings.name)
+                        res.send(result)
+                    });
+                } else if ( req.query.type == 'sync') {
+                    var incremental = true;
+                    var  config = {};
+                    config.skipPeer =  req.query.fromPeer;
+                    self.pullRecordsFromPeers( function syncComplete(result) {
+                        res.send('ok');
+                        tOuter.cb()
+                    }, incremental, config );
+                } else if ( req.query.type == 'count') {
+
+                    var incremental = true;
+                    var  config = {};
+                    config.skipPeer =  req.query.fromPeer;
+                    //todo-reuse real count
+
+                    sh.isEmptyObject = function isEmptyObject(obj) {
+                        return !Object.keys(obj).length;
+                    }
+
+                    self.dbHelper2.getDBVersion(function onNext(version) {
+                        self.dbHelper2.countAll(function gotAllRecords(count){
+                            self.count = count;
+                            var result = {
+                                name:self.settings.name,
+                                v:self.version,
+                                count:count}
+                            if ( ! sh.isEmptyObject(nestedResults)) {
+                                result.nestedResults = nestedResults
+                            }
+                            res.send(result);
+                            tOuter.cb()
+                        }, {});
+                    },{})
+
+                }
+                else if (req.query.type == 'delete') {
+
+                    var ids = [records[0].id_timestamp];
+
+                    self.Table.findAll({where:{id_timestamp:ids}})
+                        .then(function onX(objs) {
+                            if ( logOutInput) {      console.error('done2', req.query.type, self.settings.name) }
+                            //throw new Error('new type specified')
+                            self.Table.destroy({where:{id_timestamp:{$in:ids}}})
+                                .then(
+                                function upserted() {
+                                    //  t.cb();
+                                    var result = {}
+                                    if ( logOutInput) {
+                                        console.error('done3', req.query.type, self.settings.name)
+                                    }
+                                    result.ok = true;
+                                    res.send(result)
+                                    tOuter.cb()
+                                })
+                                .error(function() {
+                                    asdf.g
+                                });
+                        }).error(function() {
+                            //  asdf.g
+                        })
+
+                } else {
+                    throw new Error('... throw it ex ...')
+                }
+                //self.dbHelper2.purgeDeletedRecords( recordsDeleted);
+
+                /* function recordsDeleted() {
+                 var result = {}
+                 result.ok = true;
+                 res.send(result)
+                 }*/
+            });
+
+
+            tOuter.add(function debug() {
+               // asdf.g
+                if ( initialRequest ) {
+                    self.dalLogDump();
+                }
+            })
+        }
+
+        self.getCount = function getCount(req, res) {
+
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+
+            //count records in db with my source
+            /*
+             q: do get all records? only records with me as source ..
+             // only records that are NOT related to user on other side
+             */
+
+
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                if ( isNaN(dateInt)) {
+                    var dateSet =  new Date(req.query.global_updated_at);
+                } else {
+                    var dateSet = new Date(dateInt);
+                }
+
+                if ( isNaN( dateSet.getTime() ) ) {
+                    throw new Error('dateSet GetTime is bad ' +
+                        req.query.global_updated_at)
+                }
+
+                //throw new Error('why are you couunting things ? 8/3/2016') //Answer -- during a sync don't want to go backwards
+                query.where = {global_updated_at:{$gt:dateSet}};
+                query.order = ['global_updated_at',  'DESC']
+            }
+
+            self.proc('who is request from', req.query.peerName);
+
+            self.dbHelper2.getDBVersion(function onNext(version) {
+                self.dbHelper2.countAll(function gotAllRecords(count){
+                    self.count = count;
+                    var result = {
+                        count:count,
+                        v:self.version,
+                        name:self.settings.name
+                    }
+                    console.error('776-what is count',
+                        req.query.peerName,
+                        self.settings.name, result, query)
+                    res.send(result);
+                    if ( req.query.global_updated_at != null ) {
+                        var dbg = dateSet ;
+                        return;
+                    }
+                }, query);
+            },{})
+
+
+        };
+
+        self.getSize = function getSize(cb) {
+            self.dbHelper2.count(function gotAllRecords(count){
+                self.count = count;
+                self.size = count;
+                sh.callIfDefined(cb)
+            })
+        }
+
+        self.getRecords = function getRecords(req, res) {
+            res.statusCode = 404
+            res.send('not found')
+            return; //Blocked for performance reasons
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(dateInt);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            query.order = ['global_updated_at',  'DESC']
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                res.send(recs);
+            } )
+        };
+        self.getNextPage = function getRecords(req, res) {
+
+            //self.dalLog("\t\t\t", 'onGotNextPage-search-start-a', actorsStr , JSON.stringify(query) )
+
+            var query = {}
+            query.where  = {};
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(req.query.global_updated_at);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            if ( self.data.breakpoint_catchPageRequests ) {
+                console.error('at breakpoint_catchPageRequests')
+            }
+
+            query.order = ['global_updated_at',  'DESC']
+            query.limit = self.settings.updateLimit;
+            if ( req.query.offset != null ) {
+                query.offset = req.query.offset;
+            }
+
+
+
+
+            var actorsStr = self.settings.name+'-?->'+req.query.peerName
+            //self.dalLog("\t\t\t", 'onGotNextPage-getNextPage', actorsStr , JSON.stringify(query) )
+            if ( actorsStr == 'd-?->b') {
+                var y = {};
+            }
+
+            if ( actorsStr == 'b-?->d') {
+                var y = {};
+            }
+
+            //self.dalLog("\t\t\t", 'onGotNextPage-search-start', actorsStr , JSON.stringify(query) )
+
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                if ( self.data.breakpoint_catchPageRequests ) {
+                    console.error('at breakpoint_catchPageRequests')
+                }
+                //Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aAs` AS `aA` WHERE `aA`.`global_updated_at` > '2016-08-02 18:29:30.000 +00:00' ORDER BY `global_updated_at`, `DESC` LIMIT 1000;
+                //2016-08-02T18:29:30.976Z
+                //zself.dalLog("\t\t\t", 'onGotNextPage-search-result', actorsStr , JSON.stringify(query), recs.length, self.settings.name)
+                //recs.yyy = 'yud'+actorsStr
+                res.send(recs);
+            } )
+        };
+
+        p.createSharingRoutes = function createSharingRoutes() {
+            self.app.get('/showCluster', self.showCluster );
+            self.app.get('/showTable/:tableName', self.showTable );
+            self.app.get('/getTableData/:tableName', self.syncIn);
+
+            self.app.get('/getTableData', self.syncIn);
+
+            self.app.get('/getTableDataIncremental', self.syncIn);
+            self.app.get('/count', self.getCount );
+            self.app.get('/getRecords', self.getRecords );
+            self.app.get('/getNextPage', self.getNextPage );
+
+            self.app.get('/verifySync', self.verifySync );
+
+            self.app.get('/syncReverse', self.syncReverse );
+            self.app.get('/syncIn', self.syncIn);
+            self.app.get('/pull', self.syncIn);
+
+            self.app.get('/purgeDeletedRecords', self.purgeDeletedRecords);
+            self.app.get('/atomicAction', self.atomicAction);
+            //self.app.get('/syncRecords', self.syncRecords );
+        };
+    }
+    defineRoutes();
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.DalBasicRoutesHelpers = DalBasicRoutesHelpers;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+}
\ No newline at end of file
Index: mptransfer/DAL/cluster_config.json
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/cluster_config.json	(revision )
+++ mptransfer/DAL/cluster_config.json	(revision )
@@ -0,0 +1,20 @@
+{
+    "peers":{
+        "a":"127.0.0.1"
+    },
+    "links": {
+        "a":["b", "c"],
+        "b":[],
+        "e":["d"],
+        "d":"b",
+        "f":"e"
+    },
+    "table":["cars", "people"],
+    "password":"wishing on 3 wells for downstairs",
+    "name" : "test splurge",
+    "overrides":{
+        "a":{},
+        "b":null
+    }
+
+}
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server.js	(revision )
@@ -0,0 +1,790 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+var querystring= require('querystring');
+var DalDbHelpers= require('./supporting/DalDbHelpers').DalDbHelpers; //why: database lib defined here
+var DalDashboardHelpers= require('./supporting/DalDashboardHelpers').DalDashboardHelpers; //why: database lib defined here
+var DalServerTestHelpers= require('./supporting/DalServerTestHelpers').DalServerTestHelpers; //why: database lib defined here
+var DalSyncRoutesHelpers= require('./supporting/DalSyncRoutesHelpers').DalSyncRoutesHelpers; //why: database lib defined here
+var DalBasicRoutesHelpers= require('./supporting/DalBasicRoutesHelpers').DalBasicRoutesHelpers; //why: database lib defined here
+
+
+function SQLSharingServer() {
+    var p = SQLSharingServer.prototype;
+    p = this;
+    var self = this;
+
+    p.init = function init(config) {
+        self.settings = {};     //store settings and values
+        self.data = {};
+        if (config) {
+            self.settings = config;
+        } else
+        {
+            var cluster_settings = rh.loadRServerConfig(true);
+        }
+        //self.settings.port = 3001;
+
+        self.settings.updateLimit = sh.dv(self.settings.updateLimit, 99+901);
+        self.server_config = rh.loadRServerConfig(true);  //load server config
+        self.settings.enableAutoSync = sh.dv(self.settings.enableAutoSync,true);
+
+        self.debug = {};
+        //self.debug.tableCascades = true; //show table info this stop
+        self.debug.jsonBugs = false;
+        self.handleTables();
+
+
+        if ( self.debug.tableCascades )
+            return;
+        // return;
+        self.app = express();   //create express server
+
+        //self.setupSecurity()
+        self.createBlockingRoutes()
+
+        self.createRoutes();    //decorate express server
+        self.createSharingRoutes();
+
+        self.createDashboardRoutes();
+        self.createDashboardResources();
+
+        self.identify();
+
+        self.startServer()
+
+        self.connectToDb();
+        self.setupAutoSync();
+    }
+
+    p.handleTables = function handleTables() {
+        //return;
+        if ( self.settings.cluster_config.table ) {
+            self.settings.cluster_config.tables = self.settings.cluster_config.table;
+        }
+        if ( self.settings.cluster_config.tables == null )
+            return;
+
+        if ( self.settings.subServer) {
+            //asdf.g
+            return;
+        }
+
+        self.data.tableServers = [];
+        //return
+        var tables = sh.clone(self.settings.cluster_config.tables);
+        var mainTable = tables.pop();
+        self.settings.tableName = mainTable;
+        self.settings.topServer = true;
+
+
+
+        //in non-test mode, all are the same
+        var bconfig = self.utils.cloneSettings();
+        //sh.clone(self.settings);
+
+        /*
+         tables are tricky
+         in test mode, we are running app ports on same machine, so we
+         offset the port numbers  by the number of tables
+         tables, people, cars
+         a1,b3,c5
+
+         a1 a_car_2,
+         b3 b_car_4,
+         c5 c_car_6,
+
+         in prod mode, we offset each table by 1, so car is on port 1, people is on port 2
+         tables, people, cars
+         a1,b1,c1
+
+         a1 a_car_2,
+         b1 b_car_2,
+         c1 b_car_2,
+
+         have to update sub configuration
+         */
+        var tablePortOffset = 0;
+        sh.each(tables, function addServerForTable(k,tableName) {
+            //return
+
+            //var config = sh.clone(bconfig);
+            var config = self.utils.cloneSettings();
+            // var config = self.utils.detectCircularProblemsWith(self.settings)
+            var cloneablePeers = []; //clone peers so port increments do not conflict
+            sh.each(config.peerConfig.peers, function copyPeer(k,v) {
+                var p = {};
+                sh.mergeObjects2(v, p)
+                delete p.peers //remove recurse peers property
+                cloneablePeers.push(p)
+            })
+            config.peerConfig.peers = sh.clone(cloneablePeers)
+            if ( config.peerConfig == null ) {
+                var breakpoint =  {};
+            }
+            delete config.topServer;
+            var peerCount = config.peerConfig.peers.length; //why: offset in test mode by this many ports
+            var originalIp = config.ip
+            tablePortOffset += 1
+
+            config.port = null;
+            config.ip = self.utils.incrementPort(config.ip, tablePortOffset);
+            config.peerConfig.ip = self.utils.incrementPort(config.peerConfig.ip, tablePortOffset);
+            self.proc("\t\t", 'peer', config.name,tableName, config.ip)
+            var additionalOffset = 0;
+            //setup matching ip/port for peers
+            sh.each(config.peerConfig.peers, function setupMatchingPortForPeers(k,peer) {
+                if (tables.length==1) {
+                    //tablePortOffset -= 1
+                    // additionalOffset = -1
+                    //why: do not offset by 1 ... not sure why
+                }
+                peer.ip = self.utils.incrementPort(peer.ip, tablePortOffset+additionalOffset);
+                self.proc("\t\t\t", 'peer',tableName, peer.name, peer.ip)
+            });
+
+            if ( self.debug.tableCascades ) {
+                return;
+            }
+            config.subServer = true;
+            config.topServerIp = self.settings.ip;
+            config.tables = null;
+            config.table = null;
+            config.tableName = tableName;
+
+           // config.peers = sh.clone(config.peers)
+            var service = new SQLSharingServer();
+            if ( self.runOnce )
+                return
+            /* setTimeout(function makeServerLaterToTestInitError(_config) {
+
+             console.error('run later', _config.ip)
+
+             service.init(_config);
+             }, 2000, config)*/
+
+            setTimeout(function makeServerLaterToTestInitError(_config) {
+
+                console.error('run later', _config.ip)
+
+                //self.data.tableServers
+                service.init(_config);
+                service.data.tableServers = self.data.tableServers;
+            }, 500, config)
+
+            // self.runOnce = true
+            //service.init(config);
+            // var peerObj = service;
+            //c
+            self.data.tableServers.push(service);
+        });
+
+
+        // process.exit();
+        return;
+    }
+
+    p.setupSecurity = function setupSecuirty() {
+        if ( self.settings.password == null ) {
+            return;
+        }
+        //TODO: finish ... but will break everything
+        self.app.use(function block(req, res, next) {
+            var password = ''
+            if ( req.params)
+                password = sh.dv(req.params.password, password)
+            if ( req.query)
+                password = sh.dv(req.query.password, password)
+            if ( req.body)
+                password = sh.dv(req.body.password, password)
+
+            if ( password != self.settings.password ) {
+                console.error('blocked attemptX')
+                res.status(410)
+                res.send({"status":"high bandwidth"})
+                return;
+            }
+            res.header("Access-Control-Allow-Origin", "*");
+            res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
+
+            next();
+        });
+    }
+
+    DalDashboardHelpers(self)
+
+    p.createRoutes = function createRoutes() {
+        self.app.post('/upload', function (req, res) {});
+    }
+
+    p.createBlockingRoutes = function createBlockingRoutes() {
+        //return;
+        self.app.use(function block(req, res, next) {
+            if ( self.settings.block ) {
+                self.proc('what is this', self.settings.name, 'what is this...?')
+                //asdf.g
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            next();
+        });
+    }
+    p.startServer = function startServer() {
+        self.proc('startServer', self.settings.name, self.settings.port, self.settings.tableName )
+        if ( self.settings.port == null){
+            throw new Error('no port this will not launch ' +  self.settings.name)
+        }
+        self.app.listen(self.settings.port);
+        self.proc('started server on', self.settings.name, self.settings.port);
+    }
+
+    DalSyncRoutesHelpers(self)
+    DalBasicRoutesHelpers(self)
+
+
+    /**
+     * why: identify current machine in config file to find peers
+     */
+    p.identify = function identify() {
+        var peers = self.settings.cluster_config.peers;
+        if ( self.settings.cluster_config == null )
+            throw new Error ( ' need cluster config ')
+
+
+        if ( self.settings.port != null &&
+            sh.includes(self.settings.ip, self.settings.port) == false ) {
+            self.settings.ip = null; //clear ip address if does not include port
+        };
+
+        if ( self.settings.port == null && self.settings.ip  ) {
+            //why: get port from ip address
+            var portIpAndPort = self.settings.ip;
+            if ( portIpAndPort.indexOf(':') != -1 ) {
+                var ip = portIpAndPort.split(':')[0];
+                var port = portIpAndPort.split(':')[1];
+                if ( sh.isNumber(port) == false ){
+                    throw new Error(['bad port ', ip, port].join(' '))
+                }
+                self.settings.ip = ip;
+                if ( ip.split('.').length !=4 && ip != 'localhost'){
+                    throw new Error(['invalid ip ', ip, port].join(' '))
+                }
+                self.settings.port = port;
+            };
+        };
+
+        var initIp = self.settings.ip;
+        self.settings.ip = sh.dv(self.settings.ip, '127.0.0.1:'+self.settings.port); //if no ip address defined
+        if ( self.settings.ip.indexOf(':')== -1 ) {
+            self.settings.ip = self.settings.ip+':'+self.settings.port;
+        }
+
+        if ( initIp == null ) {
+            var myIp = self.server_config.ip;
+            //find who i am from peer
+            self.proc('searching for ip', myIp)
+            sh.each(peers, function findMatchingPeer(i, ipSection){
+                var peerName = null;
+                var peerIp = null;
+
+                peerName = i;
+                peerIp = ipSection;
+
+                if ( sh.isObject(ipSection)) {
+                    sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                        peerName = name;
+                        peerIp = ip;
+                    })
+                }
+
+                if ( self.settings.peerName != null ) {
+                    if (self.settings.peerName == peerName) {
+                        foundPeerEntryForSelf = true;
+                        self.settings.name = peerName;
+                        return;
+                    }
+                } else {
+                    if (self.settings.ip == peerIp) {
+                        foundPeerEntryForSelf = true;
+                        self.settings.name = peerName;
+                        return;
+                    }
+                }
+                var peerIpOnly = peerIp;
+                if ( peerIp.indexOf(':') != -1 ) {
+                    peerIpOnly = peerIp.split(':')[0];
+                };
+                if ( peerIpOnly == myIp ) {
+                    self.proc('found your thing...')
+                    self.settings.ip = peerIpOnly
+                    if ( peerIp.indexOf(':') != -1 ) {
+                        var port = peerIp.split(':')[1];
+                        self.settings.port = port;
+                    }
+                    self.settings.name = peerName;
+                    self.settings.cluster_config.tables
+                    var y = [];
+                    return;
+                } else {
+                    // self.proc('otherwise',peerIpOnly);
+                }
+            });
+            self.server_config
+        }
+
+        self.proc('ip address', self.settings.ip);
+
+        self.settings.dictPeersToIp = {};
+        self.settings.dictIptoPeers = {};
+        self.settings.peers = [];
+
+        var foundPeerEntryForSelf = false;
+
+        console.log(self.settings.name, 'self peers', peers);
+        sh.each(peers, function findMatchingPeer(i, ipSection){
+            var peerName = null;
+            var peerIp = null;
+            sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                peerName = name;
+                peerIp = ip;
+            })
+            if ( sh.isString(ipSection) && sh.isString(i) ) { //peer and ip address method
+                if ( ipSection.indexOf(':') ) {
+                    peerName = i;
+                    peerIp = ipSection;
+                    if ( peerIp.indexOf(':') != -1 ) {
+                        peerIp = peerIp.split(':')[0];
+                    };
+                }
+            }
+            if ( self.settings.peerName != null ) {
+                if (self.settings.peerName == peerName) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+                /*
+                 var peerConfig = ipSection;
+                 if (self.settings.peerName == peerConfig.name ) {
+                 foundPeerEntryForSelf = true;
+                 self.settings.name = peerName;
+                 return;
+                 }
+                 */
+            }
+            else {
+                if (self.settings.ip == peerIp) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+            }
+            if ( ipSection.name ){
+                var peerConfig = ipSection;
+                var peerName = peerConfig.name;
+                var peerIp = peerConfig.ip;
+            }
+            self.proc('error no matched config',peerName, peerIp, self.settings.ip); //.error('....', );
+            self.settings.peers.push(peerIp);
+            self.settings.dictPeersToIp[peerName]=peerIp;
+            self.settings.dictIptoPeers[peerIp]=peerName;
+        });
+
+        if ( self.settings.peerConfig ) { //why: let cluster loader set config and send no peers
+            //bypass searchc
+            foundPeerEntryForSelf = true;
+            self.settings.name = self.settings.peerConfig.name;
+        }
+
+
+        self.proc(self.settings.peerName, 'foundPeerEntryForSelf', foundPeerEntryForSelf, self.settings.peers.length,  self.settings.peers);
+
+        if ( foundPeerEntryForSelf == false ) {
+            throw new Error('did not find self in config')
+        }
+
+        if (  self.settings.peers.length == 0 ) {
+            throw new Error('init: not enough peers ' + self.settings.name, peers)
+        }
+    }
+
+    function defineDatabase() {
+
+        p.connectToDb = function connectToDb() {
+            if ( self.settings.dbConfigOverride) {
+                var Sequelize = require('sequelize')//.sequelize
+                if ( self.settings.tableName == null || self.settings.tableName == '' ) {
+                    asdf.g
+                }
+                var sequelize = new Sequelize('database', 'username', '', {
+                    dialect: 'sqlite',
+                    storage: 'db/'+[self.settings.name,self.settings.tableName].join('_')+'.db',
+                    logging:self.settings.dbLogging
+                })
+                self.sequelize = sequelize;
+                self.createTableDefinition();
+            } else {
+                var sequelize = rh.getSequelize(null, null, true);
+                self.sequelize = sequelize;
+                self.createTableDefinition();
+            }
+
+
+        }
+
+        /**
+         * Creates table object
+         */
+        p.createTableDefinition = function createTableDefinition() {
+            var tableSettings = {};
+            if (self.settings.force == true) {
+                tableSettings.force = true
+                tableSettings.sync = true;
+            }
+            tableSettings.name = self.settings.tableName
+            if ( self.settings.tableName == null ) {
+                throw new Error('need a table name')
+            }
+            //tableSettings.name = sh.dv(sttgs.name, tableSettings.name);
+            tableSettings.createFields = {
+                name: "", desc: "", user_id: 0,
+                imdb_id: "", content_id: 0,
+                progress: 0
+            };
+
+
+            self.settings.fields = tableSettings.createFields;
+
+            var requiredFields = {
+                source_node: "", id_timestamp: "",
+                updated_by_source:"",
+                global_updated_at: new Date(), //make another field that must be changed
+                version: 0, deleted: true
+            }
+            sh.mergeObjects(requiredFields, tableSettings.createFields);
+            tableSettings.sequelize = self.sequelize;
+            SequelizeHelper.defineTable(tableSettings, tableCreated);
+
+            function tableCreated(table) {
+                self.proc(self.settings.name, 'table ready')
+                //if ( sttgs.storeTable != false ) {
+                self.Table = table;
+
+
+                self.dbHelper2.getDBVersion()
+
+                setTimeout(function () {
+                    sh.callIfDefined(self.settings.fxDone);
+                }, 100)
+
+            }
+        }
+
+        DalDbHelpers(self)
+    }
+    defineDatabase();
+
+    function defineUtils() {
+        if ( self.utils == null ) self.utils = {};
+
+        self.utils.cloneSettings = function cloneSettings() {
+            var y = self.settings;
+            var clonedSettings = {};
+            sh.each(y, function dupeX(k,v) {
+                //what
+                try {
+                    var c = sh.clone(v);
+                    clonedSettings[k] = c;
+                } catch ( e ) {
+                    if ( self.debug.jsonBugs )
+                        console.error('problem json copy with', k)
+
+
+                    clonedSettings[k] = v; //ugh ...
+                }
+
+            })
+
+
+            // function recursivee
+            return clonedSettings;
+        }
+
+        self.utils.detectCircularProblemsWith =
+            function detectCircularProblemsWith(obj, dictPrev, path) {
+                if ( dictPrev == null ) {
+                    dictPrev = {};
+                    dictPrev.arr = [];
+                    path = ''
+                }
+                //why will detect circular references in json object (stringify)
+                var clonedSettings = {};
+                sh.each(obj, function dupeX(k,v) {
+                    try {
+                        dictPrev[v] = k;
+                        dictPrev.arr.push(v)
+                        var c = sh.clone(v);
+                        clonedSettings[k] = c;
+
+                    } catch ( e ) {
+                        path += '.'+k
+                        if ( self.debug.jsonBugs )
+                            console.error('problem json copy with', k, v, path)
+                        dictPrev[v] = k;
+                        dictPrev.arr.push(v)
+                        if ( sh.isObject( v )) {
+                            var prev = dictPrev[v];
+                            var hasItem = dictPrev.arr.indexOf(v)
+
+                            if ( prev != null || hasItem != -1  ) {
+                                if ( dictPrev.culprintFound ) {
+                                    console.log('---> is culprit ', path, k, prev)
+                                    return;
+                                }
+                                console.log('this is culprit ', path, k, prev)
+                                // return;
+                                dictPrev.culprintFound = true;
+                            }
+
+                            sh.each(v, function dupeX(k1,innerV) {
+                                console.log('  ... |> ', k1)
+                                var pathRecursive = path +'.'+k1;
+                                dictPrev[innerV] = k1;
+                                dictPrev.arr.push(innerV)
+                                self.utils.detectCircularProblemsWith(innerV, dictPrev,pathRecursive)
+
+                            })
+
+                        }
+
+                        //clonedSettings[k] = v; //ugh ...
+                    }
+                })
+                // function recursivee
+                return clonedSettings;
+            }
+
+
+
+        self.utils.latestDate = function compareTwoDates_returnMostRecent(a,b) {
+            if ( a == null )
+                return b;
+            if (a.getTime() > b.getTime() ) {
+                return a;
+            }
+            return b;
+        }
+
+        self.utils.incrementPort = function incrementPort(ip, offset) {
+            var obj = self.utils.getPortAndIp(ip);
+
+
+            var newIp =  obj.ip + ':' + (obj.port+offset);
+            return newIp;
+        }
+
+        self.utils.getPortAndIp = function getPortAndIp (ip) {
+            var obj = {}
+            var portIpAndPort = ip;
+            if ( portIpAndPort.indexOf(':') != -1 ) {
+                var ip = portIpAndPort.split(':')[0];
+                var port = portIpAndPort.split(':')[1];
+                if ( sh.isNumber(port) == false ){
+                    throw new Error(['bad port ', ip, port].join(' '))
+                }
+
+                if ( ip.split('.').length !=4 && ip != 'localhost'){
+                    throw new Error(['invalid ip ', ip, port].join(' '))
+                }
+
+                obj.port = parseInt(port)
+                obj.ip = ip; //parseInt(ip)
+            };
+            return obj;
+        }
+
+        self.utils.forEachPeer = function fEP(fxPeer, fxDone) {
+
+            sh.async(self.settings.peers,
+                fxPeer, function allDone() {
+                    sh.callIfDefined(fxDone);
+                })
+            return;
+        }
+
+        self.utils.getPeerForRequest = function getPeerForRequest(req) {
+            var fromPeer = req.query.fromPeer;
+            if ( fromPeer == null ) {
+                throw new Error('need peer')
+            };
+            return fromPeer;
+        }
+
+
+        self.utils.peerHelper = {};
+        self.utils.peerHelper.getPeerNameFromIp = function getPeerNameFromIp(ip) {
+            var peerName = self.settings.dictIptoPeers[ip];
+            if ( peerName == null ) {
+                throw new Error('what no peer for ' + ip);
+            }
+            return peerName;
+        }
+
+        /**
+         *
+         * Return true if peer matches
+         * @param ip
+         * @returns {boolean}
+         */
+        self.utils.peerHelper.skipPeer = function skipPeer(ipOrNameOrDict, ip) {
+            if ( ipOrNameOrDict == '?') {
+                return false;
+            }
+            var peerName = null
+            var peerIp = null;
+            var peerName = self.settings.dictIptoPeers[ipOrNameOrDict];
+            if ( peerName == null ) {
+                peerName = ipOrNameOrDict;
+                peerIp = self.settings.dictPeersToIp[peerName];
+                if ( peerName == null ) {
+                    throw new Error('bad ip....'  + ipOrNameOrDict)
+                }
+            } else {
+                peerIp = ipOrNameOrDict;
+            }
+
+            if ( peerIp == ip ) {
+                return true; //skip this one it matches
+            }
+
+            return false;
+        }
+
+        /**
+         * Update config to limit debugging information
+         * @param config
+         * @returns {*}
+         */
+        self.utils.updateTestConfig = function updateTestConfig(config) {
+            config = sh.dv(config, {});
+            config.silent = true;
+            self.settings.cluster_config.urlTimeout = sh.dv(self.settings.cluster_config.urlTimeout, 3000);
+            config.urlTimeout = self.settings.cluster_config.urlTimeout;
+            return config;
+        }
+
+    }
+    defineUtils();
+
+    function defineLog() {
+        self.dalLogX = function log() {
+            if ( self.listLog == null ) {
+                self.listLog = []
+            }
+            var args = sh.convertArgumentsToArray(arguments)
+            var str = args.join(' ')
+            str = self.listLog.length + '. ' + str;
+            self.listLog.push(str)
+        }
+
+        self.dalLog = function log() {
+            if ( self.listLog == null ) {
+                self.listLog = []
+            }
+            var args = sh.convertArgumentsToArray(arguments)
+            var str = args.join(' ')
+            str = self.listLog.length + '. ' + str;
+            var file = sh.sLog('');
+            var split = file.split('\\')
+            file = split[0] + split.slice(-1)[0] //limit display length
+            console.error(args)
+            str += ' '+file
+            self.listLog.push(str)
+            if ( self.logGlobal ) {
+                self.logGlobal.push(str)
+            }
+        }
+
+        self.dalLogReset = function dalLogReset() {
+            self.listLog= [];
+            console.log("\n\n\n\n\n\n\n-reset-\n\n\n\n\n\n")
+            if ( self.logGlobal ) {
+                self.logGlobal.length = 0 ;
+            }
+
+        }
+
+        self.dalLogDump = function dalLogDump() {
+            // console.log('>>>', self.listLog)
+            console.log('>>>>>' )//, self.logGlobal)
+            sh.each(self.listLog, function (k,v) {
+                console.log(v)
+            })
+            //  console.log(self.logGlobal)
+            if ( self.logGlobal ) {
+                console.log('>>>>>' )//, self.logGlobal)
+                sh.each(self.logGlobal, function (k,v) {
+                    console.log(v)
+                })
+                //  console.log(self.logGlobal)
+            }
+        }
+    }
+    defineLog();
+
+    function defineUrl() {
+        //  var actorsStr = self.settings.name+'__'+peerName
+        function getUrlDebugTag(t) {
+            var urlTag = '?a'+'='+actorsStr+'&'+
+                'of='+t.offset
+            return urlTag
+        }
+
+        self.utils.url = {};
+        self.utils.url.appendUrl = function appendUrl() { //take array of objects adn add to url
+            var url = '?';
+            var queryObject = {};
+            var args = sh.convertArgumentsToArray(arguments)
+            sh.each(args, function processB(i, hsh){
+                sh.each(hsh, function processBx(k, v){
+                    queryObject[k] = v;
+                })
+            })
+            url +=  querystring.stringify(queryObject)
+            return url;
+        }
+        self.utils.url.from = function appendUrl(ip) { //take array of objects adn add to url
+            return self.utils.peerHelper.getPeerNameFromIp(ip)
+
+        }
+    }
+    defineUrl();
+
+    DalServerTestHelpers(self)
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.SQLSharingServer = SQLSharingServer;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+
+
+}
\ No newline at end of file
Index: mptransfer/DAL/debug_config_override.txt
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/debug_config_override.txt	(revision )
+++ mptransfer/DAL/debug_config_override.txt	(revision )
@@ -0,0 +1,4 @@
+{
+"comment":"if a value is set in this file, we use use the override set",
+"file":""
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/supporting/DalDashboardHelpers.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DalDashboardHelpers.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DalDashboardHelpers.js	(revision )
@@ -0,0 +1,338 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var querystring= require('querystring');
+
+function DalDashboardHelpers(_self) {
+    var p = DalDashboardHelpers.prototype;
+    p = this;
+    var self = this;
+    if ( _self ) {
+        self = _self;
+        p = self;
+    }
+
+
+    /**
+     * why: identify current machine in config file to find peers
+     */
+
+    function defineDBMethods() {
+
+
+        p.createDashboardResources = function createDashboardResources() {
+            if ( self.settings.enableDashboard != false ) {
+                //q: should offset dir? no
+                var dirPub = __dirname+'/../../node_modules/shelpers/lib/public_html/'
+                self.app.use(express.static(__dirname+'/public_html'));
+                self.app.use(express.static(dirPub));
+                console.info('createDashboardResources', '127.0.0.1:12011/dashboard_dal.html')
+                if ( ! sh.fileExists(dirPub) ) {
+                    throw new Error(dirPub)
+                }
+
+                if ( ! sh.fileExists(dirPub+'/'+'jquery-2.0.2.js.ignore_scan') ) {
+                    throw new Error(dirPub)
+                }
+            }
+        }
+
+        p.createDashboardRoutes = function createDashboardRoutes() {
+            self.getConfig = function getConfig (req, res) {
+                var peers = self.settings.peers;
+                var cfg = self.utils.cloneSettings();
+                cfg.cluster_config.peers = peers;
+                cfg.peers = peers;
+                var x =self.utils.detectCircularProblemsWith(self.settings)
+                var tables = {};
+                if ( true || self.settings.subServer != true ) {
+                    if ( self.data.tableServers == null ) {
+                        self.data.tableServers = [];
+                    }
+                    sh.each(self.data.tableServers, function (k,tableServer) {
+                        tables[tableServer.settings.tableName] = tableServer.settings
+                        //why: random check to ensure this i fucntioning
+                        if ( tableServer.settings.subServer != true ) {
+                            throw new Error('not a sub server ... not good ')
+                        }
+                    });
+                } else {
+
+                }
+                x.tableServers = tables ;
+                var x =self.utils.detectCircularProblemsWith(x)
+                var str = sh.toJSONString(x);
+                res.send(str);
+                return;
+                self.settings.peers = [];
+                self.settings.cluster_config.peers = [];
+                var str = sh.toJSONString(self.settings)
+                self.settings.cluster_config.peers = peers;
+                self.settings.peers = peers;
+                res.send(str)
+            }
+
+            self.app.get('/getConfig',  self.getConfig );
+
+            self.getPeers = function getPeers (req, res) {
+                var peers = self.settings.peers;
+                var cfg = self.utils.cloneSettings();
+                cfg.cluster_config.peers = peers;
+                cfg.peers = peers;
+                var x =self.utils.detectCircularProblemsWith(self.settings)
+                var tables = {};
+                x.tableServers = tables ;
+                var x =self.utils.detectCircularProblemsWith(x)
+                var x = {}
+                x.peers = self.dictIptoPeers;
+                x.name = self.settings.name;
+                x.ip = self.ip;
+                x.peers2 = self.settings.peers;
+                var str = sh.toJSONString(x);
+                res.send(str);
+                return;
+
+            }
+            self.app.get('/getPeers',  self.getPeers );
+
+            self.listRecords = function listRecords(req, res) {
+                var query = {}
+                query.limit = 4
+                self.dbHelper2.search(query, function gotAllRecords(recs){
+                    // var str = sh.toJSONString(recs)
+                    // res.send(str)
+                    res.send(recs);
+                } )
+
+            }
+
+            self.app.get('/listRecords',  self.listRecords );
+            //function (req, res) {});
+
+            self.dbUpdateSettings = function dbUpdateSettings(req, res) {
+
+                var query = req.query;
+
+
+                var updateX = false;
+                var skipProps = [];
+                skipProps = ['password', 'tableName', 'ip', 'port']
+                sh.each(query, function copyToSettingsObject(k,v) {
+                    if ( sh.includes(skipProps, k)) {
+                        return;
+                    }
+                    self.proc('updated', k, v)
+                    self.settings[k] = v;
+                    if ( v == 'syncTime') {
+                        updateX = true
+                    }
+                })
+
+
+                if ( updateX ) {
+                    self.setupAutoSync();
+                }
+
+
+                res.send({sttatus:'ok'})
+
+            }
+
+            self.app.get('/dbUpdateSettings',  self.dbUpdateSettings );
+
+
+            self.addRecords = function addRecord(req, res) {
+                var item = {name: "test new" + self.settings.name + ' '}
+                if (  req.query != null ) {
+                    item = req.query
+                }
+                self.dbHelper2.addNewRecord(item, saveRecord);
+                function saveRecord(recs){
+                    res.send(recs);
+                };
+
+            }
+
+            self.app.get('/addRecord',  self.addRecords );
+
+
+            self.app.get('/countRecords', self.getCount );
+
+
+
+            self.getPeersInfo = function getPeersInfo(req, res) {
+                var item = {name: "test new" + self.settings.name + ' '}
+                if (  req.query != null ) {
+                    item = req.query
+                }
+
+                res.send({});
+                return;
+
+
+                self.dbHelper2.addNewRecord(item, saveRecord);
+                function saveRecord(recs){
+                    res.send(recs);
+                };
+
+            }
+
+            self.app.get('/getPeersInfo',  self.getPeersInfo );
+
+
+            self.isClusterSynced = function isClusterSynced(req, res) {
+                //why: will call count action
+                req.query = {};
+                req.query.type = 'count'
+                req.query.fromPeer = '?'
+                var fxOldSend  = res.send;
+                res.send = function onResult(data) {
+
+                    var synced = true;
+
+
+                    var homeVersion = null
+                    function process(obj, x,y) {
+
+                        var vvv = new Date(obj.v).getTime();
+                        if ( homeVersion == null ) {
+                            homeVersion = vvv;
+                            vvv = 0
+                        }
+                        else {
+                            vvv =   vvv - homeVersion;
+                            if ( vvv != 0 ){
+                                synced = false;
+                                data.synced = synced
+                                obj.synced = false;
+                            }
+                            vvv =  (vvv / 1000).toFixed()
+                            if ( Math.abs(vvv) < 60 ) {
+                                vvv += 's'
+                            }else {
+                                vvv = (vvv / 60).toFixed()
+                                if (  Math.abs(vvv) < 60 ) {
+                                    vvv += 'm'
+                                } else {
+                                    vvv = (vvv / 60).toFixed()
+                                    if (  Math.abs(vvv) < 60 ) {
+                                        vvv += 'h'
+                                    } else {
+                                        vvv =  (vvv / 24).toFixed()
+                                        if (  Math.abs(vvv) < 60 ) {
+                                            vvv += 'd'
+                                        }
+                                    }
+                                }
+
+                            }
+
+                        }
+
+                        if ( obj.nestedResults == null ) return;
+                        sh.each(obj.nestedResults, function procNested(k,nestedObj) {
+                            process(nestedObj, x+1, k+y+1)
+                        })
+                    }
+                    process(data, 1,1)
+
+
+                    data.synced = synced;
+                    fxOldSend.apply(res, [data])
+                    //req.apply()
+                }
+                self.atomicAction(req, res)
+            }
+            self.app.get('/isClusterSynced',  self.isClusterSynced );
+
+
+            self.deleteRecord = function deleteRecord(req, res) {
+                //why: will call count action
+                //delete record the 'wrong' way ... simple removing a record will require a full sync
+                //TODO: Add incremental sync
+                var id = 0;
+                if (req.params.id != null ) {
+                    id = req.params.id
+                }
+                self.dbHelper2.deleteRecord(id, function () {
+                    res.status(410)
+                    res.send({status:"gone"})
+                })
+            }
+            self.app.get('/deleteRecord/:id',  self.deleteRecord );
+
+            self.purgeRecord = function purgeRecord(req, res) {
+                //why: remove record appropriately
+                var id = 0;
+                if (req.params.id != null ) {
+                    id = req.params.id
+                }
+                self.dbHelper2.getById(id, function (record) {
+                    if ( record == null) {
+
+                        res.status(404)
+                        res.send({status:"not found"})
+                        return
+                    }
+                    var attrs = record.dataValues
+                    attrs.deleted = true;
+                    self.dbHelper2.updateRecord(record,onRecordDeletedProperly )
+                    function onRecordDeletedProperly(oo) {
+                        res.status(410)
+                        res.send({status:"deleted"})
+                    };
+                });
+
+            }
+            self.app.get('/purgeRecord/:id',  self.purgeRecord );
+
+
+            self.addPeer = function addPeer (req, res) {
+
+                var peerName = req.query.peerName;
+                var peerIp = req.query.peerIp;
+
+                var newPeerConfigObj = {};
+                newPeerConfigObj[peerName]=peerIp;
+                self.settings.cluster_config.peers.push(newPeerConfigObj);
+                //
+                //var peers = self.settings.peers;
+                self.identify();
+                var result = {}
+                result.ok = true
+                res.send(result);
+                return;
+            }
+            self.app.get('/addPeer',  self.addPeer );
+        }
+
+
+
+
+
+    }
+    defineDBMethods();
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.DalDashboardHelpers = DalDashboardHelpers;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+}
\ No newline at end of file
Index: mptransfer/DAL/1
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/1	(revision )
+++ mptransfer/DAL/1	(revision )
@@ -0,0 +1,2 @@
+http://auutwvpt2zktxwng.onion.link/
+https://search.disconnect.me/searchTerms/serp?search=89b4cac1-b5ed-480c-b459-97c7a39337f4
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/supporting/DBConfigHelpers.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DBConfigHelpers.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DBConfigHelpers.js	(revision )
@@ -0,0 +1,3 @@
+/**
+ * Created by user2 on 5/3/16.
+ */
Index: mptransfer/DAL/sql_sharing_server/supporting/DalClusterConfigLoader.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DalClusterConfigLoader.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DalClusterConfigLoader.js	(revision )
@@ -0,0 +1,232 @@
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+
+var SQLSharingServer = require('./../sql_sharing_server').SQLSharingServer;
+
+
+function DalClusterConfigLoader() {
+    var p = DalClusterConfigLoader.prototype;
+    p = this;
+    var self = this;
+    p.init = function init(config) {
+        self.settings = sh.dv(config, {});
+        self.settings.file = sh.dv(self.settings.file, __dirname+'/'+'../'+'../'+ 'cluster_config.json')
+        self.config = sh.readJSONFile(self.settings.file)
+        self.cluster_config = self.config;
+        sh.toJSONString(self.config,self.config.displayConfigOnInit)
+
+        self.makePeers();
+        self.processPeers();
+        self.peersConfig_modify()
+        self.makePeersObjects();
+    }
+
+    p.makePeers = function makePeers() {
+
+        function defineTopologyUtils() {
+            var tU  ={};
+            var dictPeers = {};
+            self.topUtils = tU;
+            self.topUtils.topology = dictPeers
+
+            self.topUtils.makePeer = function makePeer(peerName) {
+                var peer = dictPeers[peerName];
+                if ( peer == null ) {
+                    peer =  {};
+                    peer.name = peerName;
+                    peer.linksTo = [];
+                    peer.links = [];
+                    dictPeers[peerName] = peer;
+                }
+                return peer;
+            }
+            self.topUtils.createLink = function createLink(fromPeer, toPeerName) {
+                var fromPeerName = fromPeer;
+                if ( fromPeer.name )
+                    fromPeerName = fromPeer.name;
+                var peer = dictPeers[fromPeerName];
+                var peer = self.topUtils.makePeer(fromPeerName) //forgiving
+                var toPeer = self.topUtils.makePeer(toPeerName)
+                if ( peer.linksTo.indexOf(toPeerName) == -1 ) {
+                    self.proc(fromPeerName,'-->', toPeerName)
+                    peer.linksTo.push(toPeerName);
+                }
+
+                //why: create full list of peers in/out
+                if ( peer.links.indexOf(toPeerName) == -1 ) {
+                    peer.links.push(toPeerName);
+
+                    if ( toPeer.links.indexOf(fromPeerName) == -1 ) {
+                        toPeer.links.push(fromPeerName);
+                    }
+                }
+
+
+            }
+            self.topUtils.getPeers = function getPeers(peersByName) {
+                var peerConfigs = [];;
+                sh.each(peersByName, function onPeer(idx,peerName) {
+                    var peer = self.topUtils.makePeer(peerName);
+                    peerConfigs.push(peer)
+                });
+                return peerConfigs;
+            }
+        }
+        defineTopologyUtils();
+
+        sh.each(self.cluster_config.links, function onPeer(fromPeerName,linksTo) {
+            var peer = self.topUtils.makePeer(fromPeerName);
+            sh.each(linksTo, function onPeer(idx,linksToPeerNamed) {
+                var peer = self.topUtils.makePeer(fromPeerName);
+                self.topUtils.createLink(peer, linksToPeerNamed);
+            });
+            return;
+        })
+
+        console.log('')
+        sh.toJSONString(self.topUtils.topology, true)
+    }
+    p.processPeers = function processPeers() {
+        //why: show warning messages..
+        //warn about empty peers.
+        //warn about loops
+        //no ips, will use test mode
+        //test mode, will use test mode
+        if ( self.settings.testMode ) {
+            console.warning('use test mode')
+        }
+
+        sh.each(self.topUtils.topology, function onPeer(fromPeerName,peerConfig) {
+            if ( peerConfig.ip  == null ) {
+                console.warn('use test mode b/c', fromPeerName, peerConfig, 'had no ip address')
+                self.settings.testMode = true;
+                return false;
+            }
+        })
+
+    }
+    p.peersConfig_modify = function peersConfig_modify() {
+        //why: finalize ocnfig warning messages..
+
+        var port = 12010
+        sh.each(self.topUtils.topology, function onPeer(fromPeerName,peerConfig) {
+            if ( self.settings.testMode ) {
+                peerConfig.ip  = '127.0.0.1';
+
+                peerConfig.ip +=':'+port;
+                //peerConfig.port = port;
+                port += self.config.table.length;
+                port += 1;
+
+                self.proc('peerIp', fromPeerName, peerConfig.ip );
+            }
+        })
+
+    }
+    p.makePeersObjects = function makePeersObjects() {
+        //why: create live instances
+
+        var topology = {};
+        var allPeers = [];
+        var baseConfig = {};
+        //baseConfig.cluster_config = self.topUtils.topology;
+        //baseConfig.port = 12001;
+        baseConfig.peerName = 'a';
+        baseConfig.tableName = 'aA';
+        baseConfig.fxDone = self.finishedMakingPeers
+        baseConfig.dbConfigOverride = true
+        baseConfig.dbLogging =false
+        baseConfig.testMode = self.settings.testMode;
+        //baseConfig.dbLogging=true
+
+        var logGlobal = [];
+        //if no ips
+        sh.each(self.topUtils.topology,
+            function createLivePeerObject(fromPeerName,peerConfig) {
+                var config = sh.clone(baseConfig);
+                peerConfig = sh.clone(peerConfig)
+                sh.mergeObjectsForce(peerConfig, config)
+                config.cluster_config = {};
+                //peerConfig.peers = peerConfig.peers;
+                peerConfig.peers = self.topUtils.getPeers(peerConfig.links);
+                config.peerConfig = peerConfig;
+                config.cluster_config = peerConfig;
+                config.cluster_config = self.cluster_config;
+                config.cluster_config.peers = peerConfig.peers; //ugh ...
+                var service = new SQLSharingServer();
+                service.init(config);
+                var peerObj = service;
+                peerObj.logGlobal = logGlobal; //why: test syncing tests
+                allPeers.push(service);
+                topology[fromPeerName] = peerObj;
+
+                self.proc('serv', service.settings.name, service.settings.ip)
+            })
+
+
+        function debugVerifyToplogyIsLinked() {
+            var topEntries = {}
+            var subEntries = {};
+            sh.each(allPeers,
+                function showPeerPeers(k,peer) {
+
+                    self.proc(peer.settings.name, peer.settings.ip )
+                    console.log('', peer.settings.dictPeersToIp, peer.settings.peers)
+                    sh.each(peer.settings.dictPeersToIp, function (name,ip) {
+                        var lastIp = topEntries[name]
+                        if ( lastIp && lastIp != ip ) {
+                            throw new Error(
+                                ['having bug with', name, ip, 'on',  peer.settings.name].join(' '))
+                        }
+                        topEntries[name] = ip;
+                    })
+                    var tab = "\t\t"
+                    sh.each(peer.data.tableServers, function (k,sub) {
+                        if ( sub.settings == null ) {
+                            return;
+                        }
+                        //self.proc(tab, sub.settings.name, sub.settings.ip )
+                        console.error(tab, sub.settings.name, sub.settings.ip )
+                        console.error(tab, '', sub.settings.dictPeersToIp, sub.settings.peers)
+                        sh.each(peer.settings.dictPeersToIp, function (name,ip) {
+                            var lastIp = topEntries[name]
+                            if ( lastIp && lastIp != ip ) {
+                                throw new Error([
+                                    'having bug sub with', name, ip, 'on',  sub.settings.name].join(' '))
+                            }
+                            topEntries[name] = ip;
+                        })
+                    })
+
+                })
+           // process.exit();
+        }
+
+
+        setTimeout(debugVerifyToplogyIsLinked, 0)
+        setTimeout(debugVerifyToplogyIsLinked, 2000)
+
+        return;
+    }
+
+    p.method = function method(config) {
+    }
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        sh.sLog(arguments);
+    };
+}
+
+exports.DalClusterConfigLoader = DalClusterConfigLoader;
+
+if (module.parent == null) {
+    var instance = new DalClusterConfigLoader();
+    var config = {};
+    instance.init(config)
+}
+
+
+
Index: mptransfer/DAL/sql_sharing_server/supporting/public_html/db2.js.x
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/public_html/db2.js.x	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/public_html/db2.js.x	(revision )
@@ -0,0 +1,110 @@
+/**
+ * Created by morriste on 8/3/16.
+ */
+
+
+var utils = {};
+utils.getIntoDiv = function ( url , toDiv, name, fx) {
+    $.ajax({
+        url: url,
+    })
+        .fail(function( data , t, e) {
+            console.error(e)
+        })
+        .done(function( data ) {
+            if ( console && console.log ) {
+                console.log( "Sample of data:", data.slice( 0, 100 ) );
+            }
+
+            var dataPP = data.replace(/\n/gi, "<br />")
+            dataPP = dataPP.replace(/\t/gi, "&emsp; "+"&nbsp;"+"&nbsp;"+"&nbsp;")
+            $('#'+toDiv).html(dataPP)
+            if ( fx ) fx(data)
+
+
+        });
+}
+
+utils.addBtn = function ( url , toDiv, name) {
+    if ( name == null )
+        name = url;
+    var btn = $('<button></button>');
+    btn.html(name);
+    btn.click(onClickAutoGen)
+    function onClickAutoGen(){
+        utils.getIntoDiv(url, toDiv, '',
+            function createJumpLinks(data){
+                var json = JSON.parse(data);
+
+                var containerJumpLinks = $('<div></div>')
+
+                $.each(json.dictPeersToIp, function (peerName,ip) {
+                    var btn = $('<button></button>');
+                    btn.html(peerName);
+                    btn.click(function onClick(){
+                        var url = ip+'/dashboard_dal.html'
+                        utils.redirectTo(url, toDiv, '')
+
+                    })
+                    containerJumpLinks.append(btn);
+                })
+
+                containerJumpLinks.append($("<br />"));
+
+                $('#'+toDiv).prepend(containerJumpLinks)
+
+        })
+    }
+    $('#'+toDiv+'_cfg').append(btn);
+
+    var btn = $('<button></button>');
+    btn.html('~');
+    var showXHide = true;
+    btn.click(function onClick(){
+        showXHide = ! showXHide;
+        if ( showXHide ) {
+            $('#'+toDiv).removeClass('hide')
+        } else {
+            $('#'+toDiv).addClass('hide')
+        }
+    })
+    $('#'+toDiv+'_cfg').append(btn);
+
+    var ret = {};
+    ret.fx = onClickAutoGen;
+    return ret
+}
+utils.addDBAction = function ( txt, createDiv ) {
+    var div = $('<div></div>');
+    div.attr('id', createDiv+'_cfg');
+
+    $('body').append(div)
+    var div = $('<div></div>');
+    div.css("height", '200px')
+    div.css("overflow", 'auto')
+    div.attr('id', createDiv);
+    $('body').append(div);
+
+
+   /* var div = $('<div>------</div>');
+    $('body').append(div);*/
+}
+
+
+$( document ).ready(init)
+
+function init() {
+    utils.addDBAction('get config', 'config')
+    var result = utils.addBtn('/getConfig', 'config')
+    result.fx();
+
+    //utils.addInfo('get config')
+
+   // utils.br();
+
+    utils.addDBAction('get config', 'listRecords')
+    utils.addBtn('/getConfig', 'listRecords')
+
+    utils.addDBAction('get config', 'node_enable')
+    utils.addBtn('/getConfig', 'node_enable')
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/supporting/DalDbHelpers.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DalDbHelpers.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DalDbHelpers.js	(revision )
@@ -0,0 +1,559 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+var querystring= require('querystring');
+
+function DalDbHelpers(_self) {
+    var p = DalDbHelpers.prototype;
+    p = this;
+    var self = this;
+    if ( _self ) self = _self;
+
+    /**
+     * why: identify current machine in config file to find peers
+     */
+
+    function defineDatabase() {
+
+        function defineDbHelpers() {
+            var dbHelper = {};
+            self.dbHelper2 = dbHelper;
+            dbHelper.count = function (fx, table) {
+                table = sh.dv(table, self.Table);
+                //console.error('count', table.name, name)
+                table.count({where: {}}).then(function onResults(count) {
+                    self.count = count;
+                    //self.proc('count', count);
+                    sh.callIfDefined(fx, count);
+                })
+            }
+
+            dbHelper.utils = {};
+            dbHelper.utils.queryfy = function queryfy(query) {
+                query = sh.dv(query, {});
+                var fullQuery = {};
+                if ( query.where != null ) {
+                    fullQuery = query;
+                }else {
+                    fullQuery.query = query;
+                }
+                return fullQuery;
+            }
+
+            dbHelper.countAll = function (fx, query) {
+                var fullQuery = dbHelper.utils.queryfy(query)
+                self.Table.count(fullQuery).then(function onResults(count) {
+                    self.count = count;
+                    //self.proc('count', count)
+                    sh.callIfDefined(fx, count)
+                    //  self.version = objs.updated_at.getTime();
+                })
+            }
+
+            dbHelper.getDBVersion = function (fx, query) {
+                var fullQuery = dbHelper.utils.queryfy(query)
+                fullQuery.limit = 1;
+                fullQuery = {
+                    limit: 1,
+                    //     offset: index,
+                    where: {},
+                    order: 'global_updated_at DESC'
+                }
+                self.Table.findAll(fullQuery).then(function onResults(recs) {
+
+                    if ( recs.length == 0 ) {
+                        self.version = 0;
+                    } else {
+                        self.version = recs[0].global_updated_at
+                    }
+                    //self.proc('count', count)
+                    sh.callIfDefined(fx, self.version)
+                    //  self.version = objs.updated_at.getTime();
+                })
+            }
+
+            dbHelper.getDBVersionAndCount = function getDBVersionAndCount(fx, query){
+
+                query = sh.dv(query, {})
+                var queryIsEmpty = false;
+                if ( JSON.stringify(query)=='{}') {
+                    queryIsEmpty = true
+                }
+                var results = {};
+                dbHelper.getDBVersion(onGotDBVersion, query )
+
+                function onGotDBVersion(version) {
+                    results.version = version;
+                    if ( queryIsEmpty ) {
+                        self.version = version; //why: update global version
+                    }
+                    dbHelper.countAll(onGotCount, query);
+                }
+
+                function onGotCount(count){
+                    if ( queryIsEmpty ) {
+                        self.count = count; //why: update global version
+                    }
+                    fx(results.version, count);
+                }
+            }
+
+            dbHelper.getUntilDone = function (query, limit, fx, fxDone, count) {
+                var index = 0;
+                if (count == null) {
+                    dbHelper.countAll(function (initCount) {
+                        count = initCount;
+                        nextQuery();
+                    }, query)
+                    return;
+                }
+                ;
+
+                function nextQuery(initCount) {
+                    self.proc(index, count, (index / count).toFixed(2));
+                    if (index >= count) {
+                        if (index == 0 && count == 0) {
+                            sh.callIfDefined(fx, [], true);
+                        }
+                        sh.callIfDefined(fxDone);
+                        //sh.callIfDefined(fx, [], true);
+                        return;
+                    }
+                    ;
+
+                    self.Table.findAll(
+                        {
+                            limit: limit,
+                            offset: index,
+                            where: query,
+                            order: 'global_updated_at ASC'
+                        }
+                    ).then(function onResults(objs) {
+                            var records = [];
+                            var ids = [];
+                            sh.each(objs, function col(i, obj) {
+                                records.push(obj.dataValues);
+                                ids.push(obj.dataValues.id);
+                            });
+                            self.proc('sending', records.length, ids)
+                            index += limit;
+
+                            var lastPage = false;
+                            if (index >= count) {
+                                lastPage = true
+                            }
+                            // var lastPage = records.length < limit;
+                            //lastPage = index >= count;
+                            // self.proc('...', lastPage, index, count)
+                            sh.callIfDefined(fx, records, lastPage);
+                            sh.callIfDefined(nextQuery)
+                        }
+                    ).catch(function (err) {
+                            console.error(err, err.stack);
+                            throw(err);
+                        })
+                }
+
+                nextQuery();
+
+
+            }
+
+
+            dbHelper.getAll = function getAll(fx) {
+                dbHelper.search({}, fx);
+            }
+            dbHelper.search = function search(query, fx, convert) {
+                convert = sh.dv(convert, true)
+                //table = sh.dv(table, self.Table);
+                var fullQuery = dbHelper.utils.queryfy(query)
+                self.Table.findAll(
+                        fullQuery
+                    ).then(function onResults(objs) {
+                        if (convert) {
+                            var records = [];
+                            var ids = [];
+                            sh.each(objs, function col(i, obj) {
+                                records.push(obj.dataValues);
+                                ids.push(obj.dataValues.id);
+                            });
+                        } else {
+                            records = objs;
+                        }
+                        sh.callIfDefined(fx, records)
+                    }
+                ).catch(function (err) {
+                        console.error(err, err.stack);
+                        //fx(err)
+
+                        throw(err);
+                        process.exit()
+                    })
+            }
+
+
+            self.dbHelper2.upsert = function upsert(records, fx) {
+                records = sh.forceArray(records);
+
+                var dict = {};
+                var dictOfExistingItems = dict;
+                var queryInner = {};
+                var statements = [];
+
+                var newRecords = [];
+                var results = {}
+
+                var resultsUpsert = results;
+                results.newRecords = newRecords;
+                var ids = [];
+                sh.each(records, function putInDict(i, record) {
+                        ids.push(record.id)
+                    }
+                )
+                if ( self.settings.debugUpsert )
+                    self.proc(self.name, ':', 'upsert', records.length, ids)
+                if (records.length == 0) {
+                    sh.callIfDefined(fx);
+                    return;
+                }
+
+                sh.each(records, function putInDict(i, record) {
+                    if (record.id_timestamp == null || record.source_node == null) {
+                        throw new Error('bad record ....');
+                    }
+                    if (sh.isString(record.id_timestamp)) { //NO: this is id ..
+                        //record.id_timestamp = new Date(record.id_timestamp);
+                    }
+                    if (sh.isString(record.global_updated_at)) {
+                        record.global_updated_at = new Date(record.global_updated_at);
+                    }
+
+                    resultsUpsert.last_global_at = self.utils.latestDate( resultsUpsert.last_global_at, record.global_updated_at);
+
+                    var dictKey = record.id_timestamp + record.source_node
+                    if (dict[dictKey] != null) {
+                        self.proc('duplicate keys', dictKey)
+                        throw new Error('duplicate key error on unique timestamps' + dictKey)
+                        return;
+                    }
+                    dict[dictKey] = record;
+                    /*statements.push(SequelizeHelper.Sequlize.AND(
+
+
+                     ))*/
+
+                    statements.push({
+                        id_timestamp: record.id_timestamp,
+                        source_node: record.source_node
+                    });
+                })
+
+                if (statements.length > 0) {
+                    queryInner = SequelizeHelper.Sequelize.or(statements)
+                    queryInner = SequelizeHelper.Sequelize.or.apply(this, statements)
+
+                    //find all matching records
+                    var query = {where: queryInner};
+
+                    self.Table.findAll(query).then(function (results) {
+                        self.proc('found existing records');
+                        sh.each(results, function (i, eRecord) {
+                            var eRecordId = eRecord.id_timestamp + eRecord.source_node;
+                            var newerRecord = dictOfExistingItems[eRecordId];
+                            if (newerRecord == null) {
+                                self.proc('warning', 'look for record did not have in database')
+                                //newRecords.push()
+                                return;
+                            }
+
+                            //do a comparison
+                            var dateOldRecord = parseInt(eRecord.dataValues.global_updated_at.getTime());
+                            var dateNewRecord = parseInt(newerRecord.global_updated_at.getTime());
+                            var newer = dateNewRecord > dateOldRecord;
+                            var sameDate = eRecord.dataValues.global_updated_at.toString() == newerRecord.global_updated_at.toString()
+                            if ( self.settings.showWarnings ) {
+                                self.proc('compare',
+                                    eRecord.name,
+                                    newerRecord,
+                                    newer,
+                                    eRecord.dataValues.global_updated_at, newerRecord.global_updated_at);
+                            }
+                            if ( newer == false ) {
+                                if ( self.settings.showWarnings )
+                                    self.proc('warning', 'rec\'v object that is older', eRecord.dataValues)
+                            }
+                            else if (sameDate) {
+                                if ( self.settings.showWarnings )
+                                    self.proc('warning', 'rec\'v object that is already up to date', eRecord.dataValues)
+                            } else {
+                                console.error('newerRecord', newerRecord)
+                                eRecord.updateAttributes(newerRecord);
+                            }
+                            //handled item
+                            dictOfExistingItems[eRecordId] = null;
+                        });
+                        createNewRecords();
+                    });
+                } else {
+                    createNewRecords();
+                }
+
+                //update them all
+
+                //add the rest
+                function createNewRecords() {
+                    var _dictOfExistingItems = dictOfExistingItems;
+                    //mixin un copied records
+                    sh.each(dictOfExistingItems, function addToNewRecords(i, eRecord) {
+                        if (eRecord == null) {
+                            //already updated
+                            return;
+                        }
+                        //console.error('creating new instance of id on', eRecord.id)
+                        eRecord.id = null;
+                        newRecords.push(eRecord);
+                    });
+
+                    if (newRecords.length > 0) {
+                        self.Table.bulkCreate(newRecords).then(function (objs) {
+
+                            self.proc('all records created', objs.length);
+                            //sh.each(objs, function (i, eRecord) {
+                            // var match = dict[eRecord.id_timestamp.toString() + eRecord.source]
+                            // eRecord.updateAttributes(match)
+                            // })
+                            sh.callIfDefined(fx, results);
+
+                        }).catch(function (err) {
+                            console.error(err, err.stack)
+                            throw  err
+                        })
+                    } else {
+                        self.proc('no records to create')
+                        sh.callIfDefined(fx, results)
+                    }
+
+
+                    /* sh.callIfDefined(fx)*/
+
+                }
+
+            }
+
+
+            self.dbHelper2.updateRecordForDb = function updateRecordForDb(record) {
+                var item = record;
+                item.source_node = self.settings.peerName;
+                //item.desc = GenerateData.getName();
+                item.global_updated_at = new Date();
+                item.id_timestamp = (new Date()).toString() + '_' + Math.random() + '_' + Math.random();
+                return item;
+            };
+
+            self.dbHelper2.addNewRecord = function addNewRecord(record, fx, saveNo) {
+                var item = record;
+                item.source_node = self.settings.peerName;
+                //item.desc = GenerateData.getName();
+                item.global_updated_at = new Date();
+                item.id_timestamp = (new Date()).toString() + '_' + Math.random() + '_' + Math.random();
+
+
+                var newRecords = [item];
+                self.Table.bulkCreate(newRecords).then(function (objs) {
+                    self.proc('all records created', objs.length);
+                    sh.callIfDefined(fx);
+                }).catch(function (err) {
+                    console.error(err, err.stack);
+                    throw  err
+                });
+
+            }
+
+
+            self.dbHelper2.compareTables = function compareTables(a, b) {
+                // console.log(nameA,data.count1,
+                //     nameB, data.count2, data.count1 == data.count2 );
+
+                var getId = function getId(obj){
+                    return obj.source_node + '_' + obj.id_timestamp//.getTime();
+                }
+
+                var dictTable1 = sh.each.createDict(
+                    a, getId);
+                var dictTable2 = sh.each.createDict(
+                    b, getId);
+
+                function compareObjs(a, b) {
+                    var badProp = false;
+                    if ( b == null ) {
+                        self.proc('b is null' )
+                        return false;
+                    }
+                    sh.each(self.settings.fields, function (prop, defVal) {
+                        if (['global_updated_at'].indexOf(prop)!= -1 ){
+                            return;
+                        }
+                        var valA = a[prop];
+                        var valB = b[prop];
+                        if ( valA != valB ) {
+                            badProp = true;
+                            self.proc('mismatched prop', prop, valA, valB)
+                            return false; //break out of loop
+                        }
+                    });
+                    if ( badProp ) {
+                        return false;
+                    }
+                    return true
+                }
+
+                var result = {};
+                result.notInA = []
+                result.notInB = [];
+                result.brokenItems = [];
+                function compareDictAtoDictB(dict1, dict2) {
+                    var diff = [];
+                    var foundIds = [];
+                    sh.each(dict1, function (id, objA) {
+                        var objB= dict2[id];
+                        if ( objB == null ) {
+                            // console.log('b does not have', id, objA)
+                            result.notInB.push(objA)
+                            // return;
+                        } else { //why: b/c if A has extra record ... it is ok...
+                            if (!compareObjs(objA, objB)) {
+                                result.brokenItems.push([objA, objB])
+                                //return;
+                            }
+                        }
+                        foundIds.push(id);
+                    });
+
+                    sh.each(dict2, function (id, objB) {
+                        if ( foundIds.indexOf(id) != -1 ) {
+                            return
+                        };
+                        /*if ( ! compareObjs(objA, objB)) {
+                         result.brokenItems.push(objA)
+                         return;
+                         }*/
+                        //console.log('a does not have', id, objB)
+                        result.notInA.push(objB)
+                    });
+                };
+
+                compareDictAtoDictB(dictTable1, dictTable2);
+
+                if ( result.notInA.length > 0 ) {
+                    //there were items in a did not find
+                    return false;
+                };
+                if ( result.brokenItems.length > 0 ) {
+                    self.proc('items did not match', result.brokenItems)
+                    return false;
+                };
+                return true;
+                return false;
+            }
+
+
+            self.dbHelper2.deleteRecord = function deleteRecord(id, cb) {
+                if ( sh.isNumber( id ) == false ) {
+                    /* self.Table.destroy(
+                     )*/
+                    // self.Table.destroy(id)
+                    id.destroy()
+                        .then(function() {
+                            sh.callIfDefined(cb);
+                        })
+                } else {
+                    self.Table.destroy({where:{id:id}})
+                        .then(function() {
+                            console.log('fff')
+                            sh.callIfDefined(cb);
+                        })
+                }
+
+            };
+
+            self.dbHelper2.getById = function getRecordById(id, cb) {
+
+                if ( sh.isNumber( id ) == false ) {
+                    id = id.dataValues.id
+                }
+
+                if ( sh.isNumber( id ) == false ) {
+                    // asdf.g
+                    cb(null)
+                    return;
+                }
+                self.Table.findAll({where:{id:id}})
+                    .then(function(objs) {
+                        //console.log('fff')
+                        sh.callIfDefined(cb, objs[0]);
+                    })
+
+            };
+
+
+            self.dbHelper2.updateRecord = function updateRecord(record, cb, attrs2) {
+                var attrs = record.dataValues;
+                if ( attrs2 ) { //why: updating dataVBalues previous did nto work
+                    sh.each(attrs2, function(k,v){
+                        attrs[k] = v;
+                    } )
+                }
+                // attrs.deleted = true;
+                attrs.updated_by_source = self.settings.name;
+                attrs.global_updated_at = new Date();
+
+                var arr = [];
+                sh.each(attrs, function(k,v){
+                    arr.push(k)
+                } )
+                //attrs.name = '777'
+                record.updateAttributes(attrs, arr).then( cb  );
+            };
+
+
+            self.dbHelper2.purgeDeletedRecords = function purgeDeletedRecords(cb) {
+                self.Table.destroy({where:{deleted:true}})
+                    .then(function onRecordsDestroyed(x) {
+                        console.log('deleted records', x)
+                        sh.callIfDefined(cb);
+                    })
+            }
+        }
+        defineDbHelpers();
+
+
+    }
+    defineDatabase();
+
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.DalDbHelpers = DalDbHelpers;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+
+
+}
\ No newline at end of file
Index: mptransfer/DAL/utils/clear_user_sessions.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/utils/clear_user_sessions.js	(revision )
+++ mptransfer/DAL/utils/clear_user_sessions.js	(revision )
@@ -0,0 +1,31 @@
+/**
+ * Utility Script clears all sessions in db
+ */
+var shelpers = require('shelpers');
+var sh = shelpers.shelpers;
+var rh = require('rhelpers');
+
+
+var dirSessions = sh.getUserHome()+'/'+"sessions_login_api"
+
+
+var cluster_settings  = require( '../' + 'cluster_config.json' );
+if ( cluster_settings.sessions != null ) {
+    dirSessions= cluster_settings.sessions.dirSessions;
+
+}
+
+var server_config = rh.loadRServerConfig(true);
+
+dirSessions= server_config.loginAPI.dir_sessions;
+sh.fs.rmrf(dirSessions);
+//sh.fs.rmrf('/home/user/ritv/dir_sessions');
+
+dirSessions= server_config.global.dir_login_consumer_sessions;
+sh.fs.rmrf(dirSessions);
+
+//CrednetialServerquickStart
+var dirSessions = sh.getUserHome() + '/' + 'trash/vidserv/'+'login_api_sessions';
+sh.fs.rmrf(dirSessions);
+var dirSessions = sh.getUserHome()+'/trash/vidserv/'+'test_login_consumer_api_sessions';
+sh.fs.rmrf(dirSessions);
Index: mptransfer/DAL/sql_sharing_server/supporting/DalSyncRoutesHelpers.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/DalSyncRoutesHelpers.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/DalSyncRoutesHelpers.js	(revision )
@@ -0,0 +1,545 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+var querystring= require('querystring');
+
+function DalSyncRoutesHelpers(_self) {
+    var p = DalSyncRoutesHelpers.prototype;
+    p = this;
+    var self = this;
+    if ( _self ){ self = _self; p = self }
+
+
+    function defineAutoSync() {
+        p.setupAutoSync = function setupAutoSync(setTimeTo) {
+            if ( setTimeTo ) {
+                self.settings.syncTime = setTimeTo;
+            }
+            if ( setTimeTo === false ) {
+                self.settings.syncTime = 0;
+            }
+
+            if ( self.settings.syncTime > 0  && self.settings.enableAutoSync ) {
+                clearInterval(self.data.autoSyncInt)
+                self.data.autoSyncInt = setInterval(
+                    self.autoSync,
+                    self.settings.syncTime*1000 )
+
+            }
+            else
+            {
+                return;
+            }
+        }
+
+        p.autoSync = function autoSync() {
+            var incremental = true;
+            var  config = {};
+            config.skipPeer =  req.query.fromPeer;
+            self.pull( function syncComplete(result) {
+                //res.send('ok');
+                self.proc('auto synced...')
+            }, incremental, config );
+        }
+    }
+    defineAutoSync()
+
+    function defineSyncRoutines() {
+        self.sync = {};
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pullRecordsFromPeers = function pullRecordsFromPeers(cb, incremental) {
+
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+            //self.dalLog("^^^", 'pullRecordsFromPeers', self.settings.name     )
+
+            /*
+             TODO: filter based on params
+             var  itConfig = {};
+             var fromPeer = req.query.fromPeer;
+             itConfig.skipPeer =  fromPeer; //why: don't try to sync bakc to pper yet
+             if ( req.query.oneshot == 'true' ){
+             itConfig.onlySyncPeer = itConfig.skipPeer;
+             itConfig.skipPeer= null;
+             }
+             if ( fromPeer == null ) {
+             throw new Error('need peer')
+             };
+             */
+
+            self.pulling = true;
+
+            sh.async(self.settings.peers,
+                function syncPeer(peerIp, fxDoneSync) {
+                    self.sync.syncPeer( peerIp, function syncedPeer() {
+                        fxDoneSync()
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records synced');
+                    sh.callIfDefined(cb)
+                })
+            return;
+            /*
+             async
+             syncpeer
+             get count after udapted time, or null
+             offset by 100
+             get count afater last updated time
+             next
+             res.send('ok');
+             */
+        };
+        self.pull = self.pullRecordsFromPeers
+
+
+        /**
+         * Get count ,
+         * offset by 1000
+         * very count is same
+         * @param ip
+         * @param cb
+         */
+        self.sync.syncPeer = function syncPeer(ip, cb, incremental) {
+            var config          = {showBody:false};
+            config.baseUrl      = ip;
+            self.utils.updateTestConfig(config)
+            var t               = EasyRemoteTester.create('Sync Peer', config);
+
+            var urls            = {};
+
+            urls.getCount       = t.utils.createTestingUrl('count');
+            urls.getRecords     = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage    = t.utils.createTestingUrl('getNextPage');
+            urls.syncReverse    = t.utils.createTestingUrl('syncReverse');
+            urls.pull    = t.utils.createTestingUrl('pull');
+
+            /*
+             urls.getCount += self.utils.url.appendUrl(self.utils.url.from(ip))
+             urls.getRecords   += self.utils.url.appendUrl(self.utils.url.from(ip))
+             urls.getNextPage    += self.utils.url.appendUrl(self.utils.url.from(ip))
+             */
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName    = self.settings.peerName;
+            if (incremental) {
+                if (self.dictPeerSyncTime[ip] != null) {
+                    reqData.global_updated_at = self.dictPeerSyncTime[ip]
+                }
+                reqData.incremental = true;
+            }
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'-->'+peerName
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'-->'+peerName
+
+
+            function getUrlDebugTag(t) {
+                var urlTag = '?a'+'='+actorsStr+'&'+
+                    'of='+t.offset
+                return urlTag
+            }
+
+            self.proc('syncing peer', actorsStr );
+            self.dalLog('syncing peer', actorsStr )
+
+            t.recordsAll = [];
+            t.recordUpdateCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+            t.offset = 0;
+
+            // self.log
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData)
+                //.storeResponseProp('count', 'count')
+                //.storeResponseProp('version', 'v')
+                .fxDone(function onGotCount(data, res, error){
+                    if ( error ) {
+                        debugger;
+                        self.proc('error...', 'aborting',  error);
+                        cb();
+                        return false;
+                    }
+                    t.data.count = data.count;
+                    t.data.version = data.v;
+                    return;
+                });
+
+
+           /* t.add(function getRecordCount(){
+                var y = t.data.count;
+                t.cb();
+            });*/
+
+
+
+            /* t.add(function syncRecourds(){
+             t.quickRequest( urls.getRecords,
+             'get', result, reqData);
+             function result(body) {
+             t.assert(body.length!=null, 'no page');
+             t.records = body;
+             t.recordsAll = t.recordsAll.concat(body);
+             t.cb();
+             };
+             });
+
+             t.add(function filterNewRecordsForPeerSrc(){
+             t.cb();
+             })
+             t.add(function upsertRecords(){
+             self.dbHelper2.upsert(t.records, function upserted(){
+             t.cb();
+             })
+             })
+
+             */
+
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                self.dalLog("\t\t", 'onGotNextPageX-pre-attempt', actorsStr ,
+                    t.offset, urls.getNextPage+getUrlDebugTag(t) )
+
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                if ( actorsStr == 'd-->b') {
+                    var y = {};
+                    debugger;
+                }
+                function onGotNextPage(body, resp, error) {
+                    if ( body == null ) {
+                        debugger
+                    }
+                    if ( error ) {
+                        self.proc('error...', 'aborting',  error);
+                        cb();
+                        return;
+                    }
+                    self.dalLog("\t\t", 'onGotNextPageX-attempt', self.settings.name, actorsStr , t.offset, body.length)
+                    if ( actorsStr == 'd-->b') {
+                        var y = {};
+                        debugger;
+                    }
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+                        //reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+
+                        t.addNext(function upsertRecords(){
+                            self.dbHelper2.upsert(body, function upserted(resultsUpsert){
+                                t.lastRecord_global_updated_at = self.utils.latestDate(t.lastRecord_global_updated_at, resultsUpsert.last_global_at)
+                                t.cb();
+                            });
+                        });
+                        //do query for records ... if can't find them, then delete them?
+                        //search for 'deleted' record updates, if my versions aren't newer than
+                        //deleted versions, then delete thtme
+                        t.addNext(function deleteExtraRecords(){
+                            //self.dbHelper2.upsert(t.records, function upserted(){
+                            t.cb();
+                            //});
+                        });
+
+                        /*t.addNext(function verifyRecords(){
+                         var query = {};
+                         var dateFirst = new Date(body[0].global_updated_at);
+                         if ( body.length > 1 ) {
+                         var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                         } else {
+                         dateLast = dateFirst
+                         }
+                         query.where = {
+                         global_updated_at: {$gte:dateFirst},
+                         $and: {
+                         global_updated_at: {$lte:dateLast}
+                         }
+                         };
+                         query.order = ['global_updated_at',  'DESC'];
+                         self.dbHelper2.search(query, function gotAllRecords(recs){
+                         var yquery = query;
+                         var match = self.dbHelper2.compareTables(recs, body);
+                         if ( match != true ) {
+                         t.matches.push(t.iterations)
+                         self.proc('match issue on', t.iterations, recs.length, body.length)
+                         }
+                         t.cb();
+                         } )
+                         })*/
+                        t.addNext(getRecordsUntilFinished)
+                    }
+
+                    t.recordUpdateCount += body.length;
+                    t.iterations  += 1
+                    if (t.firstPage == null ) t.firstPage = body; //store first record for update global_update_at
+                    //no must store last one
+
+                    //t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function countRecords(){
+
+                self.dbHelper2.count(  function upserted(count){
+                    self.size = count;
+                    t.cb();
+                })
+            })
+
+            t.add(function getVersion(){
+                self.dbHelper2.getDBVersion(  function upserted(count){
+                    //self.size = count;
+                    t.cb();
+                });
+            })
+            t.add(function verifySync(){
+                self.lastUpdateSize = t.recordUpdateCount;
+
+
+                //self.lastRecords = t.recordsAll;
+                // var bugOldDate = [t.firstPage[0].global_updated_at,t.lastRecord_global_updated_at];
+                //if ( self.lastUpdateSize > 0 )
+                //    self.dictPeerSyncTime[ip] = t.firstPage[0].global_updated_at;
+                if (t.lastRecord_global_updated_at )
+                    self.dictPeerSyncTime[ip] = t.lastRecord_global_updated_at
+
+                var v = new Date(self.version)
+                var v2 = new Date(t.data.version )
+                var versionDiff = v.getTime() - v2.getTime()
+
+                if ( versionDiff > 0 ) {
+                    self.dalLog("\t",'syncing peer', actorsStr, versionDiff )
+                }
+                if ( v.getTime() != v2.getTime() ) {
+                    var y = {};
+                    // console.clear()
+                    console.log('\033c')
+                    console.log('\033[2J');
+                    console.log('\n\n\n\n\n\n\n');
+                    process.stdout.write("\u001b[2J\u001b[0;0H");
+                    //why: version do not match, so sync again (size was likely 0)
+                    console.error('z4', actorsStr, v.getTime(), 'vs.',v2.getTime() )
+                    self.proc('z4', actorsStr, v.getTime(), 'vs.',v2.getTime(),
+                        'ask other end to get my records', 'SYNC means pull' )
+
+                    //cb
+                    //return;
+                    reqData.fromPeer = self.settings.name;
+                    reqData.fromPeerIp = self.settings.ip;
+                    reqData.oneshot = true;
+                    t.quickRequest( urls.pull+getUrlDebugTag(t),
+                        'get', onRevSync, reqData);
+                    function onRevSync(data) {
+                        //should exist if failed ...
+                        self.proc('finished update pull', actorsStr, v.getTime(), 'vs.',v2.getTime(),
+                            'ask other end to get my records',data, 'pulled' )
+                        sh.callIfDefined(cb)
+                    }
+                    return;
+                }
+
+
+                //self.dalLog("\t",'-syncing peer', actorsStr, versionDiff )
+
+                sh.callIfDefined(cb)
+            })
+
+        }
+
+
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull2 = function verifyFromPeers(cb, incremental) {
+            var resultsPeers = {};
+            var result = true;
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function verifySyncPeer(peerIp, fxDoneSync) {
+                    self.proc('verifying peer', peerIp );
+                    self.sync.verifySyncPeer( peerIp, function syncedPeer(ok) {
+                        resultsPeers[peerIp] = ok
+                        if ( ok == false ) {
+                            result = false;
+                        }
+                        fxDoneSync(ok )
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records verified');
+                    sh.callIfDefined(cb, result, resultsPeers)
+                })
+            return;
+        };
+
+        /**
+         * Ask for each peer record, starting from the bottom
+         * @param ip
+         * @param cb
+         */
+        self.sync.verifySyncPeer = function verifyPeer(ip, cb, incremental) {
+            var config = {showBody:false};
+            config.baseUrl = ip;
+            self.utils.updateTestConfig(config);
+            var t = EasyRemoteTester.create('Sync Peer', config);
+            var urls = {};
+
+
+            urls.getCount = t.utils.createTestingUrl('count');
+            urls.getRecords = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage = t.utils.createTestingUrl('getNextPage');
+
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName = self.settings.peerName;
+            reqData.fromPeer = self.settings.peerName;
+
+            t.recordsAll = [];
+            t.recordCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+            t.offset = 0;
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'__'+peerName
+            function getUrlDebugTag(t) {
+                var urlTag = '?a'+'='+actorsStr+'&'+
+                    'of='+t.offset
+                return urlTag
+            }
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+            //self.dalLog("\t\t\t", 'onGotNextPage-search-start-a', actorsStr , JSON.stringify(query) )
+
+            t.add(function getRecordCount(){
+                var recordCount = t.data.count;
+                t.cb();
+            });
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+                        // reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.addNext(function verifyRecords(){
+                            var query = {};
+                            var dateFirst = new Date(body[0].global_updated_at);
+                            if ( body.length > 1 ) {
+                                var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                            } else {
+                                dateLast = dateFirst
+                            }
+                            query.where = {
+                                global_updated_at: {$gte:dateFirst},
+                                $and: {
+                                    global_updated_at: {$lte:dateLast}
+                                }
+                            };
+                            query.order = ['global_updated_at',  'DESC'];
+                            self.dbHelper2.search(query, function gotAllRecords(recs){
+                                var yquery = query;
+                                var match = self.dbHelper2.compareTables(recs, body);
+                                if ( match != true ) {
+                                    t.matches.push(t.iterations)
+                                    self.proc('match issue on', self.settings.name, peerName, t.iterations, recs.length, body.length)
+                                }
+                                t.cb();
+                            } )
+                        })
+                        t.addNext(getRecordsUntilFinished)
+                    }
+                    t.recordCount += body.length;
+                    t.iterations  += 1
+                    t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function filterNewRecordsForPeerSrc(){
+                t.ok = t.matches.length == 0;
+                t.cb();
+            })
+            t.add(function deleteAllRecordsForPeerName(){
+                t.cb();
+            })
+            /* t.add(function countRecords(){
+             self.dbHelper2.count(  function upserted(count){
+             self.size = count;
+             t.cb();
+             })
+             })*/
+            t.add(function verifySync(){
+                self.proc('verifying', self.settings.name, self.count, ip, t.recordCount)
+                //    self.lastUpdateSize = t.recordsAll.length;
+                //  if ( t.recordsAll.length > 0 )
+                //        self.dictPeerSyncTime[ip] = t.recordsAll[0].global_updated_at;
+                sh.callIfDefined(cb, t.ok)
+            })
+
+        }
+    }
+    defineSyncRoutines();
+
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.DalSyncRoutesHelpers = DalSyncRoutesHelpers;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.perfect.bak
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.perfect.bak	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.perfect.bak	(revision )
@@ -0,0 +1,1788 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+var querystring= require('querystring');
+
+function SQLSharingServer() {
+    var p = SQLSharingServer.prototype;
+    p = this;
+    var self = this;
+
+    p.init = function init(config) {
+        self.settings = {};     //store settings and values
+        self.data = {};
+        if (config) {
+            self.settings = config;
+        } else
+        {
+            var cluster_settings = rh.loadRServerConfig(true);
+        }
+        //self.settings.port = 3001;
+
+        self.settings.updateLimit = sh.dv(self.settings.updateLimit, 99+901);
+        self.server_config = rh.loadRServerConfig(true);  //load server config
+
+
+        self.app = express();   //create express server
+        self.createRoutes();    //decorate express server
+        self.createSharingRoutes();
+
+        self.app.listen(self.settings.port);
+        self.proc('started server on', self.settings.port);
+
+        self.identify();
+        self.connectToDb();
+        self.setupAutoSyncing();
+    }
+
+    p.createRoutes = function createRoutes() {
+        self.app.post('/upload', function (req, res) {});
+    }
+
+    function defineAutosyncing() {
+        p.setupAutoSyncing = function setupAutoSyncing() {
+            if ( self.settings.syncTime > 0 ) {
+                self.int = setInterval(self.autoSync, self.settings.syncTime*1000)
+            }
+            else
+            {
+                return;
+            }
+        }
+
+        p.autoSync = function autoSync() {
+            var incremental = true;
+            var  config = {};
+            config.skipPeer =  req.query.fromPeer;
+            self.pull( function syncComplete(result) {
+                //res.send('ok');
+                self.proc('auto synced...')
+            }, incremental, config );
+        }
+    }
+    defineAutosyncing()
+
+    function defineRoutes() {
+        self.showCluster = function showCluster(req, res) {
+            res.send(self.settings);
+        };
+        self.showTable  = function showCluster(req, res) {
+            res.send('ok');
+        };
+
+
+        self.verifySync = function verifySync(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            self.pull2( function syncComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                res.send(result);
+            } );
+
+        };
+
+        self.syncIn = function syncIn(req, res) {
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            };
+            var incremental = false;
+            if ( req.originalUrl.indexOf('getTableDataIncre') != -1 ) {
+                incremental = true;
+            };
+
+            var synchronousMode = req.query.sync == "true";
+            var  config = {};
+            config.skipPeer =  req.query.fromPeer;
+            self.pull( function syncComplete(result) {
+                if ( synchronousMode == false ) {
+                    if ( sh.isFunction(res)){
+                        res(result);
+                        return;
+                    }
+                    res.send('ok');
+                }
+            }, incremental, config );
+
+            if ( synchronousMode ) {
+                res.send('ok');
+            }
+        };
+
+        self.syncReverse = function syncReverse(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var  config = {};
+            fromPeer = req.query.fromPeer;
+            config.skipPeer =  fromPeer;
+            if ( fromPeer == null ) {
+                throw new Error('need peer')
+            };
+            self.utils.forEachPeer(fxEachPeer, fxComplete);
+
+            function fxEachPeer(ip, fxDone) {
+                var config = {showBody:false};
+                /*if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                 fxDone()
+                 return;
+                 }*/
+                self.log('revsync', req.query.fromPeer);
+                self.utils.updateTestConfig(config)
+                config.baseUrl = ip;
+                var t = EasyRemoteTester.create('Sync Peer', config);
+                var urls = {};
+                urls.syncIn = t.utils.createTestingUrl('syncIn');
+                var reqData = {};
+                reqData.data =  0
+                t.getR(urls.syncIn).why('get syncronize the other side')
+                    .with(reqData).storeResponseProp('count', 'count')
+                // t.addSync(fxDone)
+                t.add(function(){
+                    fxDone()
+                    t.cb();
+                })
+                //fxDone();
+            }
+            function fxComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                if ( sh.isFunction(res)){
+                    res(result);
+                    return;
+                }
+                res.send(result);
+            }
+        };
+
+
+        /**
+         * Delete all deleted records
+         * Forces a sync with all peers to ensure errors are not propogated
+         * @param req
+         * @param res
+         */
+        self.purgeDeletedRecords = function purgeDeletedRecords(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var fromPeer = self.utils.getPeerForRequest(req);
+
+            var fromPeerChain = req.query.fromPeerChain;
+            fromPeerChain = sh.dv(fromPeerChain, fromPeer+(self.settings.name));
+
+            var config = {showBody:false};
+            self.utils.updateTestConfig(config);
+            //config.baseUrl = ip;
+            var t = EasyRemoteTester.create('Delete Purged Records', config);
+            var urls = {};
+
+            var secondStep = false;
+            if ( req.query.secondStep == 'true') {
+                secondStep = true
+            }
+
+            var reqData = {};
+            reqData.data =  0
+
+            if ( secondStep != true ) { //if this is first innovacation (not subsequent invocaiton on peers)
+                /*t.getR(urls.syncIn).why('get syncronize the other side')
+                 .with(reqData).storeResponseProp('count', 'count')
+                 // t.addSync(fxDone)
+                 t.add(function(){
+                 fxDone()
+                 t.cb();
+                 })*/
+
+                t.add(function step1_syncIn_allPeers(){
+                    self.syncIn(req, t.cb)
+                });
+                t.add(function step2_syncOut_allPeers(){
+                    self.syncReverse(req, t.cb)
+                });
+                t.add(function step3_purgeDeleteRecords_onAllPeers(){
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        var config = {showBody:false};
+                        config.baseUrl = ip;
+                        self.utils.updateTestConfig(config)
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep =  true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerIp = self.settings.ip;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone()
+                            return;
+                        }
+                        urls.purgeDeletedRecords = t2.utils.createTestingUrl('purgeDeletedRecords');
+                        urls.purgeDeletedRecords += self.utils.url.appendUrl(self.utils.url.from(ip))
+                        t2.getR(urls.purgeDeletedRecords).why('...')
+                            .with(reqData)
+                        t2.add(function(){
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+
+
+
+                    // self.syncReverse(req, t.cb)
+                });
+
+
+            } else {
+                //sync from all other peers ... ?
+                //skip the peer that started this sync ? ...
+
+                /*t.add(function step1_syncIn_allPeers(){
+                 self.syncIn(req, t.cb, req.query.fromPeer)
+                 });
+                 t.add(function step2_syncOut_allPeers(){
+                 self.syncReverse(req, t.cb,  req.query.fromPeer)
+                 });*/
+                t.add(function step1_updateAll_OtherPeers() {
+                    var skipPeer = req.query.fromPeer;
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone()
+                            return;
+                        };
+
+                        var config = {showBody: false};
+                        self.utils.updateTestConfig(config);
+                        config.baseUrl = ip;
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep = true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        reqData.xPath = sh.dv(reqData.xPath, '')
+                        reqData.xPath += '_'+reqData.fromPeer
+
+                        urls.syncIn = t2.utils.createTestingUrl('syncIn');
+                        urls.syncReverse = t2.utils.createTestingUrl('syncReverse');
+                        urls.purgeDeletedRecords = t2.utils.createTestingUrl('purgeDeletedRecords');
+                        urls.purgeDeletedRecords += self.utils.url.appendUrl(self.utils.url.from(ip))
+                        t2.getR(urls.syncIn).why('...')
+                            .with(reqData)
+                        t2.getR(urls.syncReverse).why('...')
+                            .with(reqData)
+                        t2.getR(urls.purgeDeletedRecords).why('...')
+                            .with(reqData)
+                        t2.add(function () {
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+                });
+            }
+
+            t.add(function step4_purgeRecordsLocally(){
+                self.dbHelper2.purgeDeletedRecords( recordsDeleted);
+
+                function recordsDeleted() {
+                    var result = {}
+                    result.ok = true;
+                    res.send(result)
+                }
+            });
+
+        }
+
+        /**
+         * Do an action on all nodes in cluster.
+         * @param req
+         * @param res
+         */
+        self.atomicAction = function atomicAction(req, res) {
+            if ( self.settings.block ) {
+                self.proc(self.settings.name, 'block')
+                return ;
+            }
+            var fromPeer = self.utils.getPeerForRequest(req);
+
+            var fromPeerChain = req.query.fromPeerChain;
+            fromPeerChain = sh.dv(fromPeerChain, fromPeer+(self.settings.name));
+
+            var config = {showBody:false};
+            self.utils.updateTestConfig(config);
+            //config.baseUrl = ip;f
+            var t = EasyRemoteTester.create('Commit atomic', config);
+            var urls = {};
+
+            var secondStep = false;
+            if ( req.query.secondStep == 'true') {
+                secondStep = true
+            }
+
+            var reqData = {};
+            reqData.data =  0
+            var records = req.query.records;
+            var actionType = req.query.type;
+            var records = req.query.records;
+
+            if ( actionType == null ) {
+                throw new Error('need action type')
+            }
+
+
+            if ( secondStep != true ) { //if this is first innovacation (not subsequent invocaiton on peers)
+
+                /*t.add(function step1_syncIn_allPeers(){
+                 self.syncIn(req, t.cb)
+                 });
+                 t.add(function step2_syncOut_allPeers(){
+                 self.syncReverse(req, t.cb)
+                 });*/
+                t.add(function step3_purgeDeleteRecords_onAllPeers(){
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone();   return;   }
+                        var config = {showBody:false};
+                        config.baseUrl = ip;
+                        self.utils.updateTestConfig(config)
+                        var t2 = EasyRemoteTester.create('Commit atomic on peers', config);
+                        var reqData = {};
+                        reqData.secondStep =  true; //prevent repeat of process
+                        reqData.records = req.query.records;
+                        reqData.type = req.query.type;
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerIp = self.settings.ip;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+
+                        urls.atomicAction = t2.utils.createTestingUrl('atomicAction');
+                        urls.atomicAction += self.utils.url.appendUrl(
+                            self.utils.url.from(ip),
+                            {type:actionType})
+                        t2.getR(urls.atomicAction).why('...')
+                            .with(reqData)
+                        t2.add(function(){
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+
+                        t.cb();
+                    }
+                });
+
+
+            } else {
+
+                t.add(function step1_updateAll_OtherPeers() {
+                    var skipPeer = req.query.fromPeer;
+                    self.utils.forEachPeer(fxEachPeer, fxComplete);
+                    function fxEachPeer(ip, fxDone) {
+                        if ( self.utils.peerHelper.skipPeer(fromPeer, ip)) {
+                            fxDone(); return; };
+
+                        var config = {showBody: false};
+                        self.utils.updateTestConfig(config);
+                        config.baseUrl = ip;
+                        var t2 = EasyRemoteTester.create('Purge records on peers', config);
+                        var reqData = {};
+                        reqData.secondStep = true; //prevent repeat of process
+                        reqData.fromPeer = self.settings.name;
+                        reqData.fromPeerChain = fromPeerChain + '__' + self.settings.name
+                        reqData.xPath = sh.dv(reqData.xPath, '')
+                        reqData.xPath += '_'+reqData.fromPeer
+                        reqData.records = req.query.records;
+                        reqData.type = req.query.type;
+                        urls.atomicAction = t2.utils.createTestingUrl('atomicAction');
+                        urls.atomicAction += self.utils.url.appendUrl(
+                            self.utils.url.from(ip),
+                            {type:actionType})
+                        t2.getR(urls.atomicAction).why('...')
+                            .with(reqData)
+                        t2.add(function () {
+                            fxDone()
+                            t2.cb();
+                        })
+                    }
+                    function fxComplete(ok) {
+                        t.cb();
+                    }
+                });
+            }
+
+            t.add(function step4_purgeRecordsLocally(){
+
+                var logOutInput = false;
+                if ( logOutInput) {   console.error('done', req.query.type, self.settings.name) }
+                if ( req.query.type == 'update') {
+                    self.dbHelper2.upsert(records, function upserted() {
+                        console.error('done2', req.query.type, self.settings.name)
+                        //  t.cb();
+                        var result = {}
+                        result.ok = true;
+                        self.proc('return', self.settings.name)
+                        res.send(result)
+                    });
+                } else if ( req.query.type == 'sync') {
+                    var incremental = true;
+                    var  config = {};
+                    config.skipPeer =  req.query.fromPeer;
+                    self.pull( function syncComplete(result) {
+                        res.send('ok');
+                    }, incremental, config );
+                }
+                else if (req.query.type == 'delete') {
+
+                    var ids = [records[0].id_timestamp];
+
+                    self.Table.findAll({where:{id_timestamp:ids}})
+                        .then(function onX(objs) {
+                            if ( logOutInput) {      console.error('done2', req.query.type, self.settings.name) }
+                            //throw new Error('new type specified')
+                            self.Table.destroy({where:{id_timestamp:{$in:ids}}})
+                                .then(
+                                function upserted() {
+                                    //  t.cb();
+                                    var result = {}
+                                    if ( logOutInput) {
+                                        console.error('done3', req.query.type, self.settings.name)
+                                    }
+                                    result.ok = true;
+                                    res.send(result)
+                                })
+                                .error(function() {
+                                    asdf.g
+                                });
+                        }).error(function() {
+                            //  asdf.g
+                        })
+
+                } else {
+                    throw new Error('... throw it ex ...')
+                }
+                //self.dbHelper2.purgeDeletedRecords( recordsDeleted);
+
+                /* function recordsDeleted() {
+                 var result = {}
+                 result.ok = true;
+                 res.send(result)
+                 }*/
+            });
+        }
+
+        self.getCount = function getCount(req, res) {
+            //count records in db with my source
+            /*
+             q: do get all records? only records with me as source ..
+             // only records that are NOT related to user on other side
+             */
+            var dateSet = new Date()
+            var dateInt = parseInt(req.query.global_updated_at)
+            var dateSet = new Date(dateInt);
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                query.where = {global_updated_at:{$gt:dateSet}};
+                query.order = ['global_updated_at',  'DESC']
+            }
+
+            self.proc('who is request from', req.query.peerName);
+            self.dbHelper2.countAll(function gotAllRecords(count){
+                self.count = count;
+                res.send({count:count});
+                if ( req.query.global_updated_at != null ) {
+                    var dbg = dateSet ;
+                    return;
+                }
+            }, query);
+        };
+
+        self.getSize = function getSize(cb) {
+            self.dbHelper2.count(function gotAllRecords(count){
+                self.count = count;
+                self.size = count;
+                sh.callIfDefined(cb)
+            })
+        }
+
+        self.getRecords = function getRecords(req, res) {
+            res.statusCode = 404
+            res.send('not found')
+            return; //Blocked for performance reasons
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(dateInt);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            query.order = ['global_updated_at',  'DESC']
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                res.send(recs);
+            } )
+        };
+        self.getNextPage = function getRecords(req, res) {
+            var query = {}
+            query.where  = {};
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(req.query.global_updated_at);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            if ( self.data.breakpoint_catchPageRequests ) {
+                console.error('at breakpoint_catchPageRequests')
+            }
+            query.order = ['global_updated_at',  'DESC']
+            query.limit = self.settings.updateLimit;
+            if ( req.query.offset != null ) {
+                query.offset = req.query.offset;
+            }
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                if ( self.data.breakpoint_catchPageRequests ) {
+                    console.error('at breakpoint_catchPageRequests')
+                }
+                //Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aAs` AS `aA` WHERE `aA`.`global_updated_at` > '2016-08-02 18:29:30.000 +00:00' ORDER BY `global_updated_at`, `DESC` LIMIT 1000;
+                //2016-08-02T18:29:30.976Z
+                res.send(recs);
+            } )
+        };
+
+        p.createSharingRoutes = function createSharingRoutes() {
+            self.app.get('/showCluster', self.showCluster );
+            self.app.get('/showTable/:tableName', self.showTable );
+            self.app.get('/getTableData/:tableName', self.syncIn);
+
+            self.app.get('/verifySync', self.verifySync);
+            self.app.get('/getTableData', self.syncIn);
+
+            self.app.get('/getTableDataIncremental', self.syncIn);
+            self.app.get('/count', self.getCount );
+            self.app.get('/getRecords', self.getRecords );
+            self.app.get('/getNextPage', self.getNextPage );
+            self.app.get('/verifySync', self.verifySync );
+
+            self.app.get('/syncReverse', self.syncReverse );
+            self.app.get('/syncIn', self.syncIn);
+
+            self.app.get('/purgeDeletedRecords', self.purgeDeletedRecords);
+            self.app.get('/atomicAction', self.atomicAction);
+            //self.app.get('/syncRecords', self.syncRecords );
+        };
+    }
+    defineRoutes();
+
+    function defineSyncRoutines() {
+        self.sync = {};
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull = function pullFromPeers(cb, incremental) {
+
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function syncPeer(peerIp, fxDoneSync) {
+                    self.proc('syninc peer', peerIp );
+                    self.sync.syncPeer( peerIp, function syncedPeer() {
+                        fxDoneSync()
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records synced');
+                    sh.callIfDefined(cb)
+                })
+            return;
+            /*
+             async
+             syncpeer
+             get count after udapted time, or null
+             offset by 100
+             get count afater last updated time
+             next
+             res.send('ok');
+             */
+        };
+
+
+
+        /**
+         * Get count ,
+         * offset by 1000
+         * very count is same
+         * @param ip
+         * @param cb
+         */
+        self.sync.syncPeer = function syncPeer(ip, cb, incremental) {
+            var config          = {showBody:false};
+            config.baseUrl      = ip;
+            self.utils.updateTestConfig(config)
+            var t               = EasyRemoteTester.create('Sync Peer', config);
+
+            var urls            = {};
+
+            urls.getCount       = t.utils.createTestingUrl('count');
+            urls.getRecords     = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage    = t.utils.createTestingUrl('getNextPage');
+            /*
+             urls.getCount += self.utils.url.appendUrl(self.utils.url.from(ip))
+             urls.getRecords   += self.utils.url.appendUrl(self.utils.url.from(ip))
+             urls.getNextPage    += self.utils.url.appendUrl(self.utils.url.from(ip))
+             */
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName    = self.settings.peerName;
+            if (incremental) {
+                if (self.dictPeerSyncTime[ip] != null) {
+                    reqData.global_updated_at = self.dictPeerSyncTime[ip]
+                }
+                reqData.incremental = true;
+            }
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+
+            t.add(function getRecordCount(){
+                var y = t.data.count;
+                t.cb();
+            });
+
+            t.recordsAll = [];
+            t.recordUpdateCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+            t.offset = 0;
+
+            /* t.add(function syncRecourds(){
+             t.quickRequest( urls.getRecords,
+             'get', result, reqData);
+             function result(body) {
+             t.assert(body.length!=null, 'no page');
+             t.records = body;
+             t.recordsAll = t.recordsAll.concat(body);
+             t.cb();
+             };
+             });
+
+             t.add(function filterNewRecordsForPeerSrc(){
+             t.cb();
+             })
+             t.add(function upsertRecords(){
+             self.dbHelper2.upsert(t.records, function upserted(){
+             t.cb();
+             })
+             })
+
+             */
+
+            if ( self.data.breakpoint ) {
+                console.error('at breakpoint')
+            }
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'__'+peerName
+            function getUrlDebugTag(t) {
+                var urlTag = '?a'+'='+actorsStr+'&'+
+                    'of='+t.offset
+                return urlTag
+            }
+
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+                        //reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+
+                        t.addNext(function upsertRecords(){
+                            self.dbHelper2.upsert(body, function upserted(resultsUpsert){
+                                t.lastRecord_global_updated_at = self.utils.latestDate(t.lastRecord_global_updated_at, resultsUpsert.last_global_at)
+                                t.cb();
+                            });
+                        });
+                        //do query for records ... if can't find them, then delete them?
+                        //search for 'deleted' record updates, if my versions aren't newer than
+                        //deleted versions, then delete thtme
+                        t.addNext(function deleteExtraRecords(){
+                            //self.dbHelper2.upsert(t.records, function upserted(){
+                            t.cb();
+                            //});
+                        });
+
+                        /*t.addNext(function verifyRecords(){
+                         var query = {};
+                         var dateFirst = new Date(body[0].global_updated_at);
+                         if ( body.length > 1 ) {
+                         var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                         } else {
+                         dateLast = dateFirst
+                         }
+                         query.where = {
+                         global_updated_at: {$gte:dateFirst},
+                         $and: {
+                         global_updated_at: {$lte:dateLast}
+                         }
+                         };
+                         query.order = ['global_updated_at',  'DESC'];
+                         self.dbHelper2.search(query, function gotAllRecords(recs){
+                         var yquery = query;
+                         var match = self.dbHelper2.compareTables(recs, body);
+                         if ( match != true ) {
+                         t.matches.push(t.iterations)
+                         self.proc('match issue on', t.iterations, recs.length, body.length)
+                         }
+                         t.cb();
+                         } )
+                         })*/
+                        t.addNext(getRecordsUntilFinished)
+                    }
+
+                    t.recordUpdateCount += body.length;
+                    t.iterations  += 1
+                    if (t.firstPage == null ) t.firstPage = body; //store first record for update global_update_at
+                    //no must store last one
+
+                    //t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function countRecords(){
+                self.dbHelper2.count(  function upserted(count){
+                    self.size = count;
+                    t.cb();
+                })
+            })
+            t.add(function verifySync(){
+                self.lastUpdateSize = t.recordUpdateCount;
+                //self.lastRecords = t.recordsAll;
+                var bugOldDate = [t.firstPage[0].global_updated_at,t.lastRecord_global_updated_at];
+                if ( self.lastUpdateSize > 0 )
+                    self.dictPeerSyncTime[ip] = t.firstPage[0].global_updated_at;
+                if (t.lastRecord_global_updated_at )
+                    self.dictPeerSyncTime[ip] = t.lastRecord_global_updated_at
+
+                sh.callIfDefined(cb)
+            })
+
+        }
+
+
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull2 = function verifyFromPeers(cb, incremental) {
+            var resultsPeers = {};
+            var result = true;
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function verifySyncPeer(peerIp, fxDoneSync) {
+                    self.proc('verifying peer', peerIp );
+                    self.sync.verifySyncPeer( peerIp, function syncedPeer(ok) {
+                        resultsPeers[peerIp] = ok
+                        if ( ok == false ) {
+                            result = false;
+                        }
+                        fxDoneSync(ok )
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records verified');
+                    sh.callIfDefined(cb, result, resultsPeers)
+                })
+            return;
+        };
+
+
+
+        /**
+         * Ask for each peer record, starting from the bottom
+         * @param ip
+         * @param cb
+         */
+        self.sync.verifySyncPeer = function verifyPeer(ip, cb, incremental) {
+            var config = {showBody:false};
+            config.baseUrl = ip;
+            self.utils.updateTestConfig(config);
+            var t = EasyRemoteTester.create('Sync Peer', config);
+            var urls = {};
+
+
+            urls.getCount = t.utils.createTestingUrl('count');
+            urls.getRecords = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage = t.utils.createTestingUrl('getNextPage');
+
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName = self.settings.peerName;
+            reqData.fromPeer = self.settings.peerName;
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+
+            t.add(function getRecordCount(){
+                var recordCount = t.data.count;
+                t.cb();
+            });
+
+            t.recordsAll = [];
+            t.recordCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+            t.offset = 0;
+
+            var peerName = self.utils.peerHelper.getPeerNameFromIp(ip)
+            var actorsStr = self.settings.name+'__'+peerName
+            function getUrlDebugTag(t) {
+                var urlTag = '?a'+'='+actorsStr+'&'+
+                    'of='+t.offset
+                return urlTag
+            }
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+                t.quickRequest( urls.getNextPage+getUrlDebugTag(t),
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+
+                        t.offset += body.length;
+                        reqData.offset = t.offset;
+                        // reqData.global_updated_at = body[0].global_updated_at;
+
+                        t.addNext(function verifyRecords(){
+                            var query = {};
+                            var dateFirst = new Date(body[0].global_updated_at);
+                            if ( body.length > 1 ) {
+                                var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                            } else {
+                                dateLast = dateFirst
+                            }
+                            query.where = {
+                                global_updated_at: {$gte:dateFirst},
+                                $and: {
+                                    global_updated_at: {$lte:dateLast}
+                                }
+                            };
+                            query.order = ['global_updated_at',  'DESC'];
+                            self.dbHelper2.search(query, function gotAllRecords(recs){
+                                var yquery = query;
+                                var match = self.dbHelper2.compareTables(recs, body);
+                                if ( match != true ) {
+                                    t.matches.push(t.iterations)
+                                    self.proc('match issue on', self.settings.name, peerName, t.iterations, recs.length, body.length)
+                                }
+                                t.cb();
+                            } )
+                        })
+                        t.addNext(getRecordsUntilFinished)
+                    }
+                    t.recordCount += body.length;
+                    t.iterations  += 1
+                    t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function filterNewRecordsForPeerSrc(){
+                t.ok = t.matches.length == 0;
+                t.cb();
+            })
+            t.add(function deleteAllRecordsForPeerName(){
+                t.cb();
+            })
+            /* t.add(function countRecords(){
+             self.dbHelper2.count(  function upserted(count){
+             self.size = count;
+             t.cb();
+             })
+             })*/
+            t.add(function verifySync(){
+                self.proc('verifying', self.settings.name, self.count, ip, t.recordCount)
+                //    self.lastUpdateSize = t.recordsAll.length;
+                //  if ( t.recordsAll.length > 0 )
+                //        self.dictPeerSyncTime[ip] = t.recordsAll[0].global_updated_at;
+                sh.callIfDefined(cb, t.ok)
+            })
+
+        }
+    }
+    defineSyncRoutines();
+
+    /**
+     * why: identify current machine in config file to find peers
+     */
+    p.identify = function identify() {
+        var peers = self.settings.cluster_config.peers;
+        if ( self.settings.cluster_config == null )
+            throw new Error ( ' need cluster config ')
+
+
+        if ( self.settings.port != null &&
+            sh.includes(self.settings.ip, self.settings.port) == false ) {
+            self.settings.ip = null; //clear ip address if does not include port
+        };
+
+        var initIp = self.settings.ip;
+        self.settings.ip = sh.dv(self.settings.ip, '127.0.0.1:'+self.settings.port); //if no ip address defined
+        if ( self.settings.ip.indexOf(':')== -1 ) {
+            self.settings.ip = self.settings.ip+':'+self.settings.port;
+        }
+
+        if ( initIp == null ) {
+            var myIp = self.server_config.ip;
+            //find who i am from peer
+            self.proc('searching for ip', myIp)
+            sh.each(peers, function findMatchingPeer(i, ipSection){
+                var peerName = null;
+                var peerIp = null;
+
+                peerName = i;
+                peerIp = ipSection;
+
+                if ( sh.isObject(ipSection)) {
+                    sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                        peerName = name;
+                        peerIp = ip;
+                    })
+                }
+
+                if ( self.settings.peerName != null ) {
+                    if (self.settings.peerName == peerName) {
+                        foundPeerEntryForSelf = true;
+                        self.settings.name = peerName;
+                        return;
+                    }
+                } else {
+                    if (self.settings.ip == peerIp) {
+                        foundPeerEntryForSelf = true;
+                        self.settings.name = peerName;
+                        return;
+                    }
+                }
+                var peerIpOnly = peerIp;
+                if ( peerIp.indexOf(':') != -1 ) {
+                    peerIpOnly = peerIp.split(':')[0];
+                };
+                if ( peerIpOnly == myIp ) {
+                    self.proc('found your thing...')
+                    self.settings.ip = peerIpOnly
+                    if ( peerIp.indexOf(':') != -1 ) {
+                        var port = peerIp.split(':')[1];
+                        self.settings.port = port;
+                    }
+                    self.settings.name = peerName;
+                    self.settings.cluster_config.tables
+                    var y = [];
+                    return;
+                } else {
+                    // self.proc('otherwise',peerIpOnly);
+                }
+            });
+            self.server_config
+        }
+
+        self.proc('ip address', self.settings.ip);
+
+        self.settings.dictPeersToIp = {};
+        self.settings.dictIptoPeers = {};
+        self.settings.peers = [];
+
+        var foundPeerEntryForSelf = false;
+
+        console.log(self.settings.name, 'self peers', peers);
+        sh.each(peers, function findMatchingPeer(i, ipSection){
+            var peerName = null;
+            var peerIp = null;
+            sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                peerName = name;
+                peerIp = ip;
+            })
+            if ( sh.isString(ipSection) && sh.isString(i) ) { //peer and ip address method
+                if ( ipSection.indexOf(':') ) {
+                    peerName = i;
+                    peerIp = ipSection;
+                    if ( peerIp.indexOf(':') != -1 ) {
+                        peerIp = peerIp.split(':')[0];
+                    };
+                }
+            }
+            if ( self.settings.peerName != null ) {
+                if (self.settings.peerName == peerName) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+            } else {
+                if (self.settings.ip == peerIp) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+            }
+            self.proc('error no matched config',peerName, peerIp, self.settings.ip); //.error('....', );
+            self.settings.peers.push(peerIp);
+            self.settings.dictPeersToIp[peerName]=peerIp;
+            self.settings.dictIptoPeers[peerIp]=peerName;
+        });
+        self.proc(self.settings.peerName, 'foundPeerEntryForSelf', foundPeerEntryForSelf, self.settings.peers.length,  self.settings.peers);
+
+        if ( foundPeerEntryForSelf == false ) {
+            throw new Error('did not find self in config')
+        }
+
+        if (  self.settings.peers.length == 0 ) {
+            throw new Error('init: not enough peers')
+        }
+    }
+
+    function defineDatabase() {
+
+        p.connectToDb = function connectToDb() {
+            if ( self.settings.dbConfigOverride) {
+                var Sequelize = require('sequelize')//.sequelize
+                var sequelize = new Sequelize('database', 'username', '', {
+                    dialect: 'sqlite',
+                    storage: ''+self.settings.name+'.db',
+                    logging:self.settings.dbLogging
+                })
+                self.sequelize = sequelize;
+                self.createTableDefinition();
+            } else {
+                var sequelize = rh.getSequelize(null, null, true);
+                self.sequelize = sequelize;
+                self.createTableDefinition();
+            }
+
+
+        }
+
+        /**
+         * Creates table object
+         */
+        p.createTableDefinition = function createTableDefinition() {
+            var tableSettings = {};
+            if (self.settings.force == true) {
+                tableSettings.force = true
+                tableSettings.sync = true;
+            }
+            tableSettings.name = self.settings.tableName
+            if ( self.settings.tableName == null ) {
+                throw new Error('need a table name')
+            }
+            //tableSettings.name = sh.dv(sttgs.name, tableSettings.name);
+            tableSettings.createFields = {
+                name: "", desc: "", user_id: 0,
+                imdb_id: "", content_id: 0,
+                progress: 0
+            };
+
+
+            self.settings.fields = tableSettings.createFields;
+
+            var requiredFields = {
+                source_node: "", id_timestamp: "",
+                updated_by_source:"",
+                global_updated_at: new Date(), //make another field that must be changed
+                version: 0, deleted: true
+            }
+            sh.mergeObjects(requiredFields, tableSettings.createFields);
+            tableSettings.sequelize = self.sequelize;
+            SequelizeHelper.defineTable(tableSettings, tableCreated);
+
+            function tableCreated(table) {
+                console.log('table ready')
+                //if ( sttgs.storeTable != false ) {
+                self.Table = table;
+
+                setTimeout(function () {
+                    sh.callIfDefined(self.settings.fxDone);
+                }, 100)
+
+            }
+        }
+
+
+        function defineDbHelpers() {
+            var dbHelper = {};
+            self.dbHelper2 = dbHelper;
+            dbHelper.count = function (fx, table) {
+                table = sh.dv(table, self.Table);
+                //console.error('count', table.name, name)
+                table.count({where: {}}).then(function onResults(count) {
+                    self.count = count;
+                    //self.proc('count', count);
+                    sh.callIfDefined(fx, count);
+                })
+            }
+
+            dbHelper.utils = {};
+            dbHelper.utils.queryfy = function queryfy(query) {
+                query = sh.dv(query, {});
+                var fullQuery = {};
+                if ( query.where != null ) {
+                    fullQuery = query;
+                }else {
+                    fullQuery.query = query;
+                }
+                return fullQuery;
+            }
+
+            dbHelper.countAll = function (fx, query) {
+                var fullQuery = dbHelper.utils.queryfy(query)
+                self.Table.count(fullQuery).then(function onResults(count) {
+                    self.count = count;
+                    //self.proc('count', count)
+                    sh.callIfDefined(fx, count)
+                    //  self.version = objs.updated_at.getTime();
+                })
+            }
+
+            dbHelper.getUntilDone = function (query, limit, fx, fxDone, count) {
+                var index = 0;
+                if (count == null) {
+                    dbHelper.countAll(function (initCount) {
+                        count = initCount;
+                        nextQuery();
+                    }, query)
+                    return;
+                }
+                ;
+
+                function nextQuery(initCount) {
+                    self.proc(index, count, (index / count).toFixed(2));
+                    if (index >= count) {
+                        if (index == 0 && count == 0) {
+                            sh.callIfDefined(fx, [], true);
+                        }
+                        sh.callIfDefined(fxDone);
+                        //sh.callIfDefined(fx, [], true);
+                        return;
+                    }
+                    ;
+
+                    self.Table.findAll(
+                        {
+                            limit: limit,
+                            offset: index,
+                            where: query,
+                            order: 'global_updated_at ASC'
+                        }
+                    ).then(function onResults(objs) {
+                            var records = [];
+                            var ids = [];
+                            sh.each(objs, function col(i, obj) {
+                                records.push(obj.dataValues);
+                                ids.push(obj.dataValues.id);
+                            });
+                            self.proc('sending', records.length, ids)
+                            index += limit;
+
+                            var lastPage = false;
+                            if (index >= count) {
+                                lastPage = true
+                            }
+                            // var lastPage = records.length < limit;
+                            //lastPage = index >= count;
+                            // self.proc('...', lastPage, index, count)
+                            sh.callIfDefined(fx, records, lastPage);
+                            sh.callIfDefined(nextQuery)
+                        }
+                    ).catch(function (err) {
+                            console.error(err, err.stack);
+                            throw(err);
+                        })
+                }
+
+                nextQuery();
+
+
+            }
+
+
+            dbHelper.getAll = function getAll(fx) {
+                dbHelper.search({}, fx);
+            }
+            dbHelper.search = function search(query, fx, convert) {
+                convert = sh.dv(convert, true)
+                //table = sh.dv(table, self.Table);
+                var fullQuery = dbHelper.utils.queryfy(query)
+                self.Table.findAll(
+                        fullQuery
+                    ).then(function onResults(objs) {
+                        if (convert) {
+                            var records = [];
+                            var ids = [];
+                            sh.each(objs, function col(i, obj) {
+                                records.push(obj.dataValues);
+                                ids.push(obj.dataValues.id);
+                            });
+                        } else {
+                            records = objs;
+                        }
+                        sh.callIfDefined(fx, records)
+                    }
+                ).catch(function (err) {
+                        console.error(err, err.stack);
+                        //fx(err)
+
+                        throw(err);
+                        process.exit()
+                    })
+            }
+
+
+            self.dbHelper2.upsert = function upsert(records, fx) {
+                records = sh.forceArray(records);
+
+                var dict = {};
+                var dictOfExistingItems = dict;
+                var queryInner = {};
+                var statements = [];
+
+                var newRecords = [];
+                var results = {}
+
+                var resultsUpsert = results;
+                results.newRecords = newRecords;
+                var ids = [];
+                sh.each(records, function putInDict(i, record) {
+                        ids.push(record.id)
+                    }
+                )
+                if ( self.settings.debugUpsert )
+                    self.proc(self.name, ':', 'upsert', records.length, ids)
+                if (records.length == 0) {
+                    sh.callIfDefined(fx);
+                    return;
+                }
+
+                sh.each(records, function putInDict(i, record) {
+                    if (record.id_timestamp == null || record.source_node == null) {
+                        throw new Error('bad record ....');
+                    }
+                    if (sh.isString(record.id_timestamp)) { //NO: this is id ..
+                        //record.id_timestamp = new Date(record.id_timestamp);
+                    }
+                    if (sh.isString(record.global_updated_at)) {
+                        record.global_updated_at = new Date(record.global_updated_at);
+                    }
+
+                    resultsUpsert.last_global_at = self.utils.latestDate( resultsUpsert.last_global_at, record.global_updated_at);
+
+                    var dictKey = record.id_timestamp + record.source_node
+                    if (dict[dictKey] != null) {
+                        self.proc('duplicate keys', dictKey)
+                        throw new Error('duplicate key error on unique timestamps' + dictKey)
+                        return;
+                    }
+                    dict[dictKey] = record;
+                    /*statements.push(SequelizeHelper.Sequlize.AND(
+
+
+                     ))*/
+
+                    statements.push({
+                        id_timestamp: record.id_timestamp,
+                        source_node: record.source_node
+                    });
+                })
+
+                if (statements.length > 0) {
+                    queryInner = SequelizeHelper.Sequelize.or(statements)
+                    queryInner = SequelizeHelper.Sequelize.or.apply(this, statements)
+
+                    //find all matching records
+                    var query = {where: queryInner};
+
+                    self.Table.findAll(query).then(function (results) {
+                        self.proc('found existing records');
+                        sh.each(results, function (i, eRecord) {
+                            var eRecordId = eRecord.id_timestamp + eRecord.source_node;
+                            var newerRecord = dictOfExistingItems[eRecordId];
+                            if (newerRecord == null) {
+                                self.proc('warning', 'look for record did not have in database')
+                                //newRecords.push()
+                                return;
+                            }
+
+                            //do a comparison
+                            var dateOldRecord = parseInt(eRecord.dataValues.global_updated_at.getTime());
+                            var dateNewRecord = parseInt(newerRecord.global_updated_at.getTime());
+                            var newer = dateNewRecord > dateOldRecord;
+                            var sameDate = eRecord.dataValues.global_updated_at.toString() == newerRecord.global_updated_at.toString()
+                            if ( self.settings.showWarnings ) {
+                                self.proc('compare',
+                                    eRecord.name,
+                                    newerRecord,
+                                    newer,
+                                    eRecord.dataValues.global_updated_at, newerRecord.global_updated_at);
+                            }
+                            if ( newer == false ) {
+                                if ( self.settings.showWarnings )
+                                    self.proc('warning', 'rec\'v object that is older', eRecord.dataValues)
+                            }
+                            else if (sameDate) {
+                                if ( self.settings.showWarnings )
+                                    self.proc('warning', 'rec\'v object that is already up to date', eRecord.dataValues)
+                            } else {
+                                console.error('newerRecord', newerRecord)
+                                eRecord.updateAttributes(newerRecord);
+                            }
+                            //handled item
+                            dictOfExistingItems[eRecordId] = null;
+                        });
+                        createNewRecords();
+                    });
+                } else {
+                    createNewRecords();
+                }
+
+                //update them all
+
+                //add the rest
+                function createNewRecords() {
+                    var _dictOfExistingItems = dictOfExistingItems;
+                    //mixin un copied records
+                    sh.each(dictOfExistingItems, function addToNewRecords(i, eRecord) {
+                        if (eRecord == null) {
+                            //already updated
+                            return;
+                        }
+                        //console.error('creating new instance of id on', eRecord.id)
+                        eRecord.id = null;
+                        newRecords.push(eRecord);
+                    });
+
+                    if (newRecords.length > 0) {
+                        self.Table.bulkCreate(newRecords).then(function (objs) {
+
+                            self.proc('all records created', objs.length);
+                            //sh.each(objs, function (i, eRecord) {
+                            // var match = dict[eRecord.id_timestamp.toString() + eRecord.source]
+                            // eRecord.updateAttributes(match)
+                            // })
+                            sh.callIfDefined(fx, results);
+
+                        }).catch(function (err) {
+                            console.error(err, err.stack)
+                            throw  err
+                        })
+                    } else {
+                        self.proc('no records to create')
+                        sh.callIfDefined(fx, results)
+                    }
+
+
+                    /* sh.callIfDefined(fx)*/
+
+                }
+
+            }
+
+
+            self.dbHelper2.updateRecordForDb = function updateRecordForDb(record) {
+                var item = record;
+                item.source_node = self.settings.peerName;
+                //item.desc = GenerateData.getName();
+                item.global_updated_at = new Date();
+                item.id_timestamp = (new Date()).toString() + '_' + Math.random() + '_' + Math.random();
+                return item;
+            };
+
+            self.dbHelper2.addNewRecord = function addNewRecord(record, fx, saveNo) {
+                var item = record;
+                item.source_node = self.settings.peerName;
+                //item.desc = GenerateData.getName();
+                item.global_updated_at = new Date();
+                item.id_timestamp = (new Date()).toString() + '_' + Math.random() + '_' + Math.random();
+
+
+                var newRecords = [item];
+                self.Table.bulkCreate(newRecords).then(function (objs) {
+                    self.proc('all records created', objs.length);
+                    sh.callIfDefined(fx);
+                }).catch(function (err) {
+                    console.error(err, err.stack);
+                    throw  err
+                });
+
+            }
+
+
+            self.dbHelper2.compareTables = function compareTables(a, b) {
+                // console.log(nameA,data.count1,
+                //     nameB, data.count2, data.count1 == data.count2 );
+
+                var getId = function getId(obj){
+                    return obj.source_node + '_' + obj.id_timestamp//.getTime();
+                }
+
+                var dictTable1 = sh.each.createDict(
+                    a, getId);
+                var dictTable2 = sh.each.createDict(
+                    b, getId);
+
+                function compareObjs(a, b) {
+                    var badProp = false;
+                    if ( b == null ) {
+                        self.proc('b is null' )
+                        return false;
+                    }
+                    sh.each(self.settings.fields, function (prop, defVal) {
+                        if (['global_updated_at'].indexOf(prop)!= -1 ){
+                            return;
+                        }
+                        var valA = a[prop];
+                        var valB = b[prop];
+                        if ( valA != valB ) {
+                            badProp = true;
+                            self.proc('mismatched prop', prop, valA, valB)
+                            return false; //break out of loop
+                        }
+                    });
+                    if ( badProp ) {
+                        return false;
+                    }
+                    return true
+                }
+
+                var result = {};
+                result.notInA = []
+                result.notInB = [];
+                result.brokenItems = [];
+                function compareDictAtoDictB(dict1, dict2) {
+                    var diff = [];
+                    var foundIds = [];
+                    sh.each(dict1, function (id, objA) {
+                        var objB= dict2[id];
+                        if ( objB == null ) {
+                            // console.log('b does not have', id, objA)
+                            result.notInB.push(objA)
+                            // return;
+                        } else { //why: b/c if A has extra record ... it is ok...
+                            if (!compareObjs(objA, objB)) {
+                                result.brokenItems.push([objA, objB])
+                                //return;
+                            }
+                        }
+                        foundIds.push(id);
+                    });
+
+                    sh.each(dict2, function (id, objB) {
+                        if ( foundIds.indexOf(id) != -1 ) {
+                            return
+                        };
+                        /*if ( ! compareObjs(objA, objB)) {
+                         result.brokenItems.push(objA)
+                         return;
+                         }*/
+                        //console.log('a does not have', id, objB)
+                        result.notInA.push(objB)
+                    });
+                };
+
+                compareDictAtoDictB(dictTable1, dictTable2);
+
+                if ( result.notInA.length > 0 ) {
+                    //there were items in a did not find
+                    return false;
+                };
+                if ( result.brokenItems.length > 0 ) {
+                    self.proc('items did not match', result.brokenItems)
+                    return false;
+                };
+                return true;
+                return false;
+            }
+
+
+            self.dbHelper2.deleteRecord = function deleteRecord(id, cb) {
+                if ( sh.isNumber( id ) == false ) {
+                    /* self.Table.destroy(
+                     )*/
+                    // self.Table.destroy(id)
+                    id.destroy()
+                        .then(function() {
+                            sh.callIfDefined(cb);
+                        })
+                } else {
+                    self.Table.destroy({where:{id:id}})
+                        .then(function() {
+                            console.log('fff')
+                            sh.callIfDefined(cb);
+                        })
+                }
+
+            };
+
+
+
+            self.dbHelper2.updateRecord = function updateRecord(record, cb) {
+                var attrs = record.dataValues;
+                // attrs.deleted = true;
+                attrs.updated_by_source = self.settings.name;
+                attrs.global_updated_at = new Date();
+                record.updateAttributes(attrs).then( cb  );
+            };
+
+
+            self.dbHelper2.purgeDeletedRecords = function purgeDeletedRecords(cb) {
+                self.Table.destroy({where:{deleted:true}})
+                    .then(function onRecordsDestroyed(x) {
+                        console.log('deleted records', x)
+                        sh.callIfDefined(cb);
+                    })
+            }
+        }
+        defineDbHelpers();
+
+
+    }
+    defineDatabase();
+
+    function defineUtils() {
+        if ( self.utils == null ) self.utils = {};
+
+        self.utils.latestDate = function compareTwoDates_returnMostRecent(a,b) {
+            if ( a == null )
+                return b;
+            if (a.getTime() > b.getTime() ) {
+                return a;
+            }
+            return b;
+        }
+        self.utils.forEachPeer = function fEP(fxPeer, fxDone) {
+
+            sh.async(self.settings.peers,
+                fxPeer, function allDone() {
+                    sh.callIfDefined(fxDone);
+                })
+            return;
+        }
+
+        self.utils.getPeerForRequest = function getPeerForRequest(req) {
+            var fromPeer = req.query.fromPeer;
+            if ( fromPeer == null ) {
+                throw new Error('need peer')
+            };
+            return fromPeer;
+        }
+
+
+        self.utils.peerHelper = {};
+        self.utils.peerHelper.getPeerNameFromIp = function getPeerNameFromIp(ip) {
+            var peerName = self.settings.dictIptoPeers[ip];
+            if ( peerName == null ) {
+                throw new Error('what no peer for ' + ip);
+            }
+            return peerName;
+        }
+
+        /**
+         *
+         * Return true if peer matches
+         * @param ip
+         * @returns {boolean}
+         */
+        self.utils.peerHelper.skipPeer = function skipPeer(ipOrNameOrDict, ip) {
+            if ( ipOrNameOrDict == '?') {
+                return false;
+            }
+            var peerName = null
+            var peerIp = null;
+            var peerName = self.settings.dictIptoPeers[ipOrNameOrDict];
+            if ( peerName == null ) {
+                peerName = ipOrNameOrDict;
+                peerIp = self.settings.dictPeersToIp[peerName];
+                if ( peerName == null ) {
+                    throw new Error('bad ip....'  + ipOrNameOrDict)
+                }
+            } else {
+                peerIp = ipOrNameOrDict;
+            }
+
+            if ( peerIp == ip ) {
+                return true; //skip this one it matches
+            }
+
+            return false;
+        }
+
+        /**
+         * Update config to limit debugging information
+         * @param config
+         * @returns {*}
+         */
+        self.utils.updateTestConfig = function updateTestConfig(config) {
+            config = sh.dv(config, {});
+            config.silent = true;
+            self.settings.cluster_config.urlTimeout = sh.dv(self.settings.cluster_config.urlTimeout, 3000);
+            config.urlTimeout = self.settings.cluster_config.urlTimeout;
+            return config;
+        }
+
+    }
+    defineUtils();
+
+    function defineLog() {
+        self.log = function log() {
+            if ( self.listLog == null ) {
+                self.listLog = []
+            }
+            var args = sh.convertArgumentsToArray(arguments)
+            var str = args.join(' ')
+            str = self.listLog.length + '. ' + str;
+            self.listLog.push(str)
+        }
+    }
+    defineLog();
+
+    function defineUrl() {
+
+        //  var actorsStr = self.settings.name+'__'+peerName
+        function getUrlDebugTag(t) {
+            var urlTag = '?a'+'='+actorsStr+'&'+
+                'of='+t.offset
+            return urlTag
+        }
+
+        self.utils.url = {};
+        self.utils.url.appendUrl = function appendUrl() { //take array of objects adn add to url
+            var url = '?';
+            var queryObject = {};
+            var args = sh.convertArgumentsToArray(arguments)
+            sh.each(args, function processB(i, hsh){
+                sh.each(hsh, function processBx(k, v){
+                    queryObject[k] = v;
+                })
+            })
+            url +=  querystring.stringify(queryObject)
+            return url;
+        }
+        self.utils.url.from = function appendUrl(ip) { //take array of objects adn add to url
+            return self.utils.peerHelper.getPeerNameFromIp(ip)
+
+        }
+    }
+    defineUrl();
+
+    function defineTestUtils() {
+        //why: utils for testing.
+        p.linkTo = function linkTo(peerToAdd, reset ) {
+            var reset = sh.dv(reset, false);
+            if ( reset ) {
+                self.settings.cluster_config.peers = []
+            }
+
+
+            var foundSelf = false;
+
+
+            var peersToAdd = sh.forceArray(peerToAdd);
+            sh.each(peersToAdd, function (k, peer)  {
+
+
+                sh.each(peer, function (peerName, ipAddOrPeer)  {
+                    var peer = ipAddOrPeer;
+                    if ( sh.isNumber(ipAddOrPeer) ) {
+                        // return;
+                        //peer =
+                    }
+                    else if ( peer.settings != null ) {
+                        var peer = ipAddOrPeer.settings.ip;
+                    }
+
+                    if ( ipAddOrPeer == self.settings.ip) {
+                        foundSelf = true;
+                    }
+                    //peersToAdd[k] = peer;
+                    //self.settings.cluster_config.peers[peerName] = peer;
+                    var newPeer = {}
+                    newPeer[peerName] = peer;
+                    self.settings.cluster_config.peers.push(newPeer);
+                })
+            })
+
+            if ( foundSelf == false) {
+                //self.settings.cluster_config.peers[self.settings.name] = self.settings.ip;
+                var myPeer = {}
+                myPeer[self.settings.name] = self.settings.ip;
+                self.settings.cluster_config.peers.push(myPeer);
+            }
+            self.identify();
+        }
+
+    }
+    defineTestUtils();
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        var args = sh.convertArgumentsToArray(arguments)
+        args.unshift(self.settings.name)
+        sh.sLog(args);
+    }
+}
+
+exports.SQLSharingServer = SQLSharingServer;
+
+if (module.parent == null) {
+    var service = new SQLSharingServer()
+    service.init()
+    return;
+
+
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/supporting/log.txt
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/log.txt	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/log.txt	(revision )
@@ -0,0 +1,1 @@
+
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests.js.fix
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests.js.fix	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests.js.fix	(revision )
@@ -0,0 +1,837 @@
+/**
+ * Created by user on 1/13/16.
+ */
+/**
+ * Created by user on 1/3/16.
+ */
+/*
+ TODO:
+ Test that records are delete?
+ //how to do delete, have a delte colunm to sync dleet eitems
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+var SQLSharingServer = require('./sql_sharing_server').SQLSharingServer;
+
+if (module.parent == null) {
+
+    var configOverride = {};
+    configOverride.mysql = {
+        "ip" : "127.0.0.1",
+        "databasename" : "yetidb",
+        //"user" : "yetidbuser",
+        //"pass" : "aSDDD545y^",
+        "port" : "3306"
+    };
+
+    rh.configOverride = configOverride;
+
+    //load confnig frome file
+    //peer has gone down ... peer comes back
+    //real loading
+    //multipe tables
+
+    //define tables to sync and time
+    //create 'atomic' modes for create/update and elete
+    var cluster_config = {
+        peers:[
+            {a:"127.0.0.1:12001"},
+            {b:"127.0.0.1:12002"}
+        ]
+    };
+
+    var topology = {};
+    var allPeers = [];
+    var config = {};
+    config.cluster_config = cluster_config;
+    config.port = 12001;
+    config.peerName = 'a';
+    config.tableName = 'aA';
+    config.fxDone = testInstances
+    config.dbConfigOverride=true
+    config.dbLogging=false
+    //config.dbLogging=true //issue with queries ... when get >1000 items in db on sqllite
+    config.password = 'dirty'
+    var service = new SQLSharingServer();
+    service.init(config);
+    var a = service;
+    allPeers.push(service)
+    topology.a = a;
+
+    var config = sh.clone(config);
+    config.port = 12002;
+    config.peerName = 'b';
+    config.tableName = 'bA';
+    var service = new SQLSharingServer();
+    service.init(config);
+    var b = service;
+    allPeers.push(service)
+    topology.b = b;
+
+    var peerCount = 2;
+    var peerStartingIp = 12001
+    var _config = config;
+    function createNewPeer(name) {
+        var config = sh.clone(_config);
+
+
+
+        config.port = peerStartingIp+peerCount;
+        peerCount++;
+
+        var newPeerConfigObj = {};
+        newPeerConfigObj[name] = '127.0.0.1'+':'+config.port;
+        config.cluster_config.peers.push(newPeerConfigObj);
+
+        config.peerName = name;
+        config.tableName = config.peerName+'_ATest';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var b = service;
+        allPeers.push(service)
+        topology[name] = b;
+
+        return service;
+    }
+
+
+
+    function augmentNetworkConfiguration() {
+        if ( topology.augmentNetworkConfiguration) {
+            return;
+        }
+        topology.augmentNetworkConfiguration = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {c:"127.0.0.1:12003"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12003;
+        config.peerName = 'c';
+        config.tableName = 'cA';
+
+        var service = new SQLSharingServer();
+        service.init(config);
+        var c = service;
+        allPeers.push(service)
+        topology.c = c;
+        //c.linkTo({b:b});
+        b.linkTo({c:c})
+
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12004;
+        config.peerName = 'd';
+        config.tableName = 'dA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var d = service;
+        allPeers.push(service)
+        topology.d = d;
+        //d.linkTo({c:c});
+        b.linkTo({d:d})
+
+
+    }
+
+
+    function augmentNetworkConfiguration2() {
+        if ( topology.augmentNetworkConfiguration2) {
+            return;
+        }
+        topology.augmentNetworkConfiguration2 = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {e:"127.0.0.1:12005"}
+        ]
+        config.port = 12005;
+        config.peerName = 'e';
+        config.tableName = 'eA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var e = service;
+        allPeers.push(service)
+        topology.d.linkTo({e:e})
+
+
+    }
+
+
+    function testInstances() {
+        //make chain
+        var sh = require('shelpers').shelpers;
+        var shelpers = require('shelpers');
+        var EasyRemoteTester = shelpers.EasyRemoteTester;
+        var t = EasyRemoteTester.create('Test Channel Server basics',
+            {
+                showBody:false,
+                silent:true
+            });
+
+        var testC = {};
+        testC.speedUp = true;
+        testC.stopSlowTests = true
+
+        //t.add(clearAllData())
+        clearAllData()
+        t.add(function clearRecordsFrom_A(){
+            a.test.destroyAllRecords(true, t.cb);
+        })
+
+
+
+        if ( 'defineBlock' == 'defineBlock') {
+            function ResuableSection_verifySync(msg, size) { //verifies size of both peers
+                if ( msg == null ) {
+                    msg = ''
+                }
+                msg = ' ' + msg;
+                t.add(function getASize(){
+                    a.getSize(t.cb);
+                })
+                t.add(function getBSize(){
+                    b.getSize(t.cb);
+                })
+                t.add(function testSize(){
+                    if ( size ) {
+                        t.assert(b.size == size, 'sync did not work (sizes different) a' + [a.size, size] + msg)
+                        t.assert(a.size == size, 'sync did not work (sizes different) b' + [b.size, size] + msg)
+                    }
+                    t.assert(b.size== a.size, 'sync did not work (sizes different)' + [b.size, a.size] + msg)
+                    t.cb();
+                })
+            }
+
+            function ResuableSection_addRecord() {
+                t.add(function addNewRecord() {
+                    a.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+                });
+            };
+
+            var baseUrl = 'http://127.0.0.1:'+ b.settings.port;
+            var urls = {};
+
+            //do partial sync
+            //sync from http request methods
+            //batched sync
+            //remove batch tester
+            //cluster config if no config sent
+
+            function defineHTTPTestMethods() {
+                //var t = EasyRemoteTester.create('Test Channel Server basics',{showBody:false});
+                t.settings.baseUrl = baseUrl;
+                urls.getTableData = t.utils.createTestingUrl('getTableData');
+                urls.syncIn = t.utils.createTestingUrl('syncIn');
+                urls.syncInB = t.utils.createTestingUrl('syncReverse');
+                urls.syncReverseB = t.utils.createTestingUrl('syncReverse');
+
+                ResuableSection_addRecord();
+
+                t.getR(urls.getTableData).with({sync:false})
+                    // .bodyHas('status').notEmpty()
+                    .fxDone(function syncComplete(result) {
+                        return;
+                    });
+
+                ResuableSection_verifySync();
+            }
+
+            function define_TestIncrementalUpdate () {
+                urls.getTableData = t.utils.createTestingUrl('getTableDataIncremental');
+
+                t.getR(urls.getTableData).with({sync:false}) //get all records
+                    .fxDone(function syncComplete(result) {
+                        return;
+                    })
+                t.workChain.utils.wait(1);
+                ResuableSection_verifySync('All records are synced')
+                ResuableSection_addRecord(); //this record is new, will be ONLY record
+                //sent in next update.
+
+                t.addFx(function startBreakpoints() {
+                    //this is not async ... very dangerous
+                    topology.b.data.breakpoint = true;
+                    topology.a.data.breakpoint_catchPageRequests = true;
+                })
+
+
+                t.getR(urls.getTableData).with({sync:false})
+                    .fxDone(function syncComplete(result) {
+                        console.log('>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<')
+                        t.assert(b.lastUpdateSize==1, 'updated wrong # of records updated after pull ' + b.lastUpdateSize)
+
+                        return;
+                    })
+
+
+                t.addFx(function removeBreakpoints() {
+                    topology.b.data.breakpoint = false;
+                    topology.a.data.breakpoint_catchPageRequests = false;
+
+                })
+
+
+                ResuableSection_verifySync()
+            }
+
+
+            urls.verifySync = t.utils.createTestingUrl('verifySync');
+            urls.syncReverse = t.utils.createTestingUrl('syncReverse');
+
+            function define_syncReverse() {
+                ResuableSection_addRecord();
+
+                t.add(function addNewRecord() {
+                    b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+                });
+                t.add(function addNewRecord() {
+                    b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+                });
+
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'?'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+                ResuableSection_verifySync()
+            };
+
+
+            function define_TestDataIntegrity() {
+
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not integral ' + result.ok)
+                        return;
+                    });
+            }
+
+
+
+            /**
+             * Records need to be  marked as 'deleted'
+             * otherwise deletion doesn't count
+             * @param client
+             */
+            function forgetRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function forgetRandomRecord() {
+                    client.test.forgetRandomRecord(t.cb);
+                });
+            }
+
+            function deleteRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function deleteRandomRecord() {
+                    b.test.deleteRandomRecord(t.cb);
+                });
+            }
+
+            function syncIn() {
+
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            function syncOut() {
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            function syncBothDirections() {
+                syncIn()
+                syncOut()
+            }
+            function breakTest() {
+                t.addFx(function() {
+                    asdf.g
+                })
+            }
+            function purgeDeletedRecords() {
+                urls.purgeDeletedRecords = t.utils.createTestingUrl('purgeDeletedRecords');
+                t.getR(urls.purgeDeletedRecords).with({fromPeer:'?'})
+                    .fxDone(function purgeDeletedRecords_Complete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+
+                        return;
+                    })
+            }
+
+
+            /**
+             * Deletes all data from all nodes
+             */
+            function clearAllData() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            // asdf.g
+                            peer.test.destroyAllRecords(true,  recordsDestroyed)
+                            function recordsDestroyed() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            // asdf.g
+                            peer.test.createTestData(  recordsCreated)
+                            function recordsCreated() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+            }
+
+            function inSyncAll() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            var t2 = EasyRemoteTester.create('TestInSync',
+                                {  showBody:false,  silent:true });
+                            var baseUrl = 'http://'+ peer.ip; //127.0.0.1:'+ b.settings.port;
+                            var urls = {};
+                            t2.settings.baseUrl = baseUrl;
+                            urls.verifySync = t.utils.createTestingUrl('verifySync');
+                            t2.getR(urls.verifySync).with(
+                                {sync:false,peer:'a'}
+                            )
+                                .fxDone(function syncComplete(result) {
+                                    t2.assert(result.ok==true, 'data not inSync ' + result.ok);
+                                    return;
+                                });
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+            }
+
+
+
+            function define_TestDataIntegrity2() {
+                forgetRandomRecordFrom();
+                t.workChain.utils.wait(1);
+                forgetRandomRecordFrom();
+                forgetRandomRecordFrom();
+                notInSync();
+                syncBothDirections()
+            }
+
+            function notInSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==false, 'data is not supposed to be in sync ' + result.ok);
+                        return;
+                    });
+            }
+            function inSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                        return;
+                    });
+            }
+        }
+
+        if ( true == true ) { //skip stuff
+            
+            t.add(function clearRecordsFrom_B(){
+                b.test.destroyAllRecords(true, t.cb);
+            })
+            ResuableSection_verifySync()
+            t.add(function create100Records_A(){
+                a.test.createTestData(t.cb)
+            })
+
+            t.add(function aPing(){
+                //  b.test.destroyAllRecords(true, t.cb);
+                // b.ping();
+                t.cb();
+            })
+            t.add(function bPing(){
+                //  b.test.destroyAllRecords(true, t.cb);
+                t.cb();
+            })
+
+            t.add(function bPullARecords(){
+
+                b.pull(t.cb);
+            })
+
+
+            ResuableSection_verifySync('A and b should be same size', 100);
+            ResuableSection_addRecord();
+
+            defineHTTPTestMethods();
+            define_TestIncrementalUpdate();
+
+            //if ( testC.speedUp != true )
+            define_TestDataIntegrity();
+
+
+            if ( testC.speedUp != true ) {
+                define_syncReverse();
+            }
+
+
+            if ( testC.speedUp != true ) {
+                define_TestDataIntegrity2();
+            }
+
+        }
+        testC.disableServer = function disableServer(name) {
+            t.add(function disableServer(){
+                var server = topology[name]
+                if ( server == null ) {
+                    throw new Error('what is this? '+name)
+                }
+                server.settings.block = true;
+                t.cb();
+            })
+        }
+        testC.syncMachineB = function syncMachine(name) {
+            //sync A to newPeer
+            t.getR(urls.syncReverseB).with({fromPeer:'b'}/*{peer:'a', fromPeer:'newPeerC'}*/)
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+            t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+
+            //verify two peers are synced
+            t.getR(urls.verifySync).with({sync:true,peer:'newPeerC'})
+                .fxDone(function syncComplete(result) {
+                    t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                    return;
+                });
+
+        }
+
+
+        function define_TestDelayedAddPeer() {
+            t.add(function clearRecordsFrom_B(){
+                var peer = createNewPeer('newPeerC');
+
+                t.data.newPeerC = peer;
+                t.cb();
+            })
+            urls.addPeer = t.utils.createTestingUrl('addPeer');
+            t.getR(urls.addPeer)
+                //.fxBefore
+                .with({peerIp:'127.0.0.1:12003'
+                    /*topology['newPeerC'].ip*/, //ugh use the before method
+                    peerName:'newPeerC'})
+                .fxDone(function syncComplete(result) {
+                    //debugger;
+                    b.settings.breakpoint = true;
+                    t.assert(result.ok==true, 'couldnot add peer ' + result.ok);
+                    return;
+                });
+            testC.syncMachineB('b')
+
+            //testUtils.checkSize
+            t.add(function getASize(){
+                t.data.newPeerC.getSize(t.cb);
+            })
+            t.add(function getBSize(){
+                b.getSize(t.cb);
+            })
+            t.add(function testSize(){
+                var size = 106;
+                size= null;
+                var msg = '///...\\\\'
+                if ( size ) {
+                    t.assert(b.size == size, 'sync did not work (sizes different) b' + [b.size, size] + msg)
+                    t.assert( t.data.newPeerC.size == size, 'sync did not work (sizes different) x' + [ t.data.newPeerC.size, size] + msg)
+                }
+                t.assert(b.size ==  t.data.newPeerC.size, 'sync did not work (sizes different)' + [b.size,  t.data.newPeerC.size] + msg)
+                t.cb();
+            })
+
+
+            //block add one and retry
+            ResuableSection_addRecord();
+            testC.disableServer('newPeerC')
+            testC.syncMachineB('b')
+
+        }
+        define_TestDelayedAddPeer()
+
+        ////////
+        if ( testC.stopSlowTests) {
+            return
+        }
+        //////////
+
+
+        function defineBlockSlowTests() {
+            function define_ResiliancyTest() {
+                forgetRandomRecordFrom();
+                forgetRandomRecordFrom(a);
+                forgetRandomRecordFrom(a);
+                forgetRandomRecordFrom();
+                notInSync();
+                //notInSync();
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+            }
+            define_ResiliancyTest();
+
+            function define_ResiliancyTest_IllegallyChangedRecords() {
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                notInSync()
+                //resolve
+                syncBothDirections()
+
+                notInSync()//did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                syncBothDirections()
+                inSync();
+            };
+            define_ResiliancyTest_IllegallyChangedRecords();
+
+            function define_multipleNodes() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration()
+                    t.cb()
+                });
+                clearAllData();
+
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecord_skipUpdateTime() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                notInSync()
+                syncBothDirections()
+                notInSync(); //did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                syncBothDirections();
+                inSync();
+            };
+            define_multipleNodes();
+        }
+        defineBlockSlowTests()
+
+
+        function defineSlowTests2() {
+            function define_TestDeletes() {
+                syncBothDirections()
+                ResuableSection_verifySync()
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(topology.c);
+
+                purgeDeletedRecords();
+
+                inSync();
+
+            };
+            define_TestDeletes()
+
+            function define_TestDeletes2() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration2()
+                    t.cb()
+                });
+                clearAllData();
+
+                syncBothDirections()
+                ResuableSection_verifySync()
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(topology.c);
+                deleteRandomRecordFrom(topology.e);
+
+                //syncBothDirections();
+                purgeDeletedRecords();
+                /*t.add(function getRecord() {
+                 b.test.getRandomRecord(function (rec) {
+                 randomRec = rec;
+                 t.cb()
+                 });
+                 });
+                 t.add(function updateRecords() {
+                 randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+                 });*/
+                //  notInSync()
+                // syncBothDirections()
+                inSync();
+
+            };
+            define_TestDeletes2()
+        }
+        defineSlowTests2()
+
+
+
+        function define_TestHubAndSpoke() {
+            asdf.g.dsdf.d
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration()
+                t.cb()
+            });
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration2()
+                t.cb()
+            });
+            clearAllData();
+
+
+            function addTimer(reason) {
+                t.add(function defineNewNodes() {
+                    if (t.timer  != null ) {
+                        var diff = sh.time.secs(t.timer)
+                        console.log('>');console.log('>');console.log('>');
+                        console.log(t.timerReason, 'time', diff);
+                        console.log('>');console.log('>');console.log('>');
+                    } else {
+
+                    }
+                    t.timerReason = reason;
+                    t.timer = new Date();
+                    t.workChain.utils.wait(1);
+                    t.cb()
+                });
+
+            }
+
+            addTimer('sync both dirs')
+            syncBothDirections()
+            addTimer('local sync')
+            ResuableSection_verifySync()
+            addTimer('deletes')
+            deleteRandomRecordFrom(b);
+            deleteRandomRecordFrom(b);
+            deleteRandomRecordFrom(topology.c);
+            deleteRandomRecordFrom(topology.e);
+
+            addTimer('purge all deletes')
+            //syncBothDirections();
+            purgeDeletedRecords();
+            /*t.add(function getRecord() {
+             b.test.getRandomRecord(function (rec) {
+             randomRec = rec;
+             t.cb()
+             });
+             });
+             t.add(function updateRecords() {
+             randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+             });*/
+            //  notInSync()
+            // syncBothDirections()
+            addTimer('insync')
+            inSync();
+            inSyncAll();
+            //TODO: Test sync on N
+            //check in sync on furthes node
+            addTimer('insyncover')
+
+        };
+        define_TestHubAndSpoke()
+
+        // breakTest()
+
+        //TODO: Add index to updated at
+
+        //test from UI
+        //let UI log in
+        //task page saeerch server
+
+        //account server
+        //TODO: To getLastPage for records
+
+        //TODO: replace getRecords, with getLastPage
+        //TODO: do delete, so mark record as deleted, store in cache,
+        //3x sends, until remove record from database ...
+
+        /*
+         when save to delete? after all synced
+         mark as deleted,
+         ask all peers to sync
+         then delete from database if we delete deleted nodes
+
+         do full sync
+         if deleteMissing -- will remove all records my peers do not have
+         ... risky b/c incomplete database might mess  up things
+         ... only delete records thata re marked as deleted
+         */
+
+        /*
+         TODO:
+         test loading config from settings object with proper cluster config
+         test auto syncing after 3 secs
+         build proper hub and spoke network ....
+         add E node that is linked to d (1 hop away)
+         */
+        /**
+         * store global record count
+         * Mark random record as deleted,
+         * sync
+         * remove deleted networks
+         * sync
+         * ensure record is gone
+         */
+
+        //Revisions
+    }
+}
+
+
+
Index: mptransfer/DAL/sql_sharing_server/supporting/public_html/db.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/supporting/public_html/db.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/supporting/public_html/db.js	(revision )
@@ -0,0 +1,636 @@
+/**
+ * Created by morriste on 8/3/16.
+ */
+
+
+$.isString = function isString(x) {
+    return toString.call(x) === "[object String]"
+}
+
+var utils = {};
+utils.getIntoDiv = function ( url , toDiv, name, fx, data) {
+    $.ajax({
+        url: url,
+        data: data,
+    })
+        .fail(function( data , t, e) {
+            console.error(e)
+        })
+        .done(function( data ) {
+            if ( console && console.log ) {
+                var dataStr = data;
+                if ( !$.isString(data)) {
+                    dataStr = JSON.stringify(data);//.toString()
+                }
+                console.log( "Sample of data:", dataStr.slice( 0, 100 ) );
+            }
+
+            if ( fx ) fx(data)
+
+
+        });
+}
+
+utils.addBtn = function addBtn ( cfg ) { //url , toDiv, name) {
+    if ( cfg.name == null )
+        cfg.name = cfg.url;
+    var divCfg =   $('#'+cfg.toDiv+'_cfg')
+    var div =   $('#'+cfg.toDiv )
+    var btn = $('<button></button>');
+    btn.html(cfg.name);
+    btn.click(onClickAutoGen)
+    function onClickAutoGen(){
+        utils.getIntoDiv(cfg.url, cfg.toDiv, '',
+            function postClickAction(data){
+
+                try {
+                    if ($.isString(data)) {
+                        var dataPP = data.replace(/\n/gi, "<br />")
+                        dataPP = dataPP.replace(/\t/gi, "&emsp; "+"&nbsp;"+"&nbsp;"+"&nbsp;")
+                        div.html(dataPP)
+                    }
+                    else {
+                        var dataPP = JSON.stringify(data, '<br />', '&emsp;');
+                        dataPP = dataPP.replace(/\t/gi, "&emsp; "+"&nbsp;"+"&nbsp;"+"&nbsp;")
+
+                        var pre = $('<pre></pre>')
+                        pre.html(dataPP)
+                        //debugger
+                        div.html(pre)
+                    }
+
+                } catch ( e ) {}
+
+                if ( cfg.fx ) {
+                    var cfg2 = {
+                        url: cfg.url,
+                        div: div,
+                        data:data
+                    };
+                    cfg.fx(cfg2)
+                }
+                return;
+            }, cfg.data)
+    }
+    divCfg.append(btn);
+
+    var btn = $('<button></button>');
+    btn.html('~');
+    var showXHide = true;
+    btn.click(function onClick(){
+        showXHide = ! showXHide;
+        if ( showXHide ) {
+            div.removeClass('hide')
+        } else {
+            div.addClass('hide')
+        }
+    })
+    divCfg.append(btn);
+
+    var ret = {};
+    ret.fx = onClickAutoGen;
+    return ret
+}
+utils.addDBAction = function ( txt, createDiv ) {
+    var div = $('<div></div>');
+    div.attr('id', createDiv+'_cfg');
+
+    $('body').append(div)
+    var div = $('<div></div>');
+    div.css("max-height", '200px')
+    div.css("overflow", 'auto')
+    div.attr('id', createDiv);
+    $('body').append(div);
+
+
+    /* var div = $('<div>------</div>');
+     $('body').append(div);*/
+}
+
+utils.redirectTo = function redirectTo(url ) {
+    console.log('....', url)
+    window.location = url;
+}
+
+$( document ).ready(init)
+
+function init() {
+    utils.addDBAction('get config', 'config')
+    var getConfigBtnObj = utils.addBtn(
+        {
+            url:'/getConfig',
+            toDiv:'config',
+
+            fx:createJumpLinks
+        }
+    )
+    getConfigBtnObj.fx();
+
+
+
+
+
+    function createJumpLinks(cfg){
+
+        var json = JSON.parse(cfg.data);
+
+        var containerJumpLinks = $('<div></div>')
+
+        utils.dictPeersToIp = json.dictPeersToIp;
+        $.each(json.dictPeersToIp, function (peerName,ip) {
+            var btn = $('<button></button>');
+            btn.html(peerName);
+            btn.click(function onClick(){
+                var url = ip+'/dashboard_dal.html'
+                if ( url.indexOf('http://')==-1)
+                    url = 'http://'+url
+                utils.redirectTo(url )
+
+            })
+            containerJumpLinks.append(btn);
+        })
+
+        containerJumpLinks.append($("<br />"));
+
+        cfg.div.prepend(containerJumpLinks)
+
+
+        utils.newDiv = function newDeiv() {
+            return  $('<div></div>');
+        }
+        utils.appendToDiv = function  appendToDiv(div, txt){
+            var newDiv = ($('<span></span>'));
+            newDiv.html(txt)
+            div.append(newDiv)
+        }
+
+        utils.addBtn = function  appendToDiv(div, txt, url){
+            var btn = ($('<button></button>'));
+            btn.html(txt)
+            div.append(btn)
+            btn.click(function onClick(){
+                if ($.isFunction(url)) {
+                    return url();
+                }
+                // var url = ip+'/dashboard_dal.html'
+                if ( url.indexOf('http://')==-1)
+                    url = 'http://'+url
+                utils.redirectTo(url )
+            })
+        }
+
+        utils.addBr = function addBrToDiv(addToDiv) {
+            var ui = $('<br />')
+            if ( addToDiv == null ) {
+                addToDiv = utils.div
+            }
+            addToDiv.append(ui)
+        }
+
+        utils.add = function add(ui, addToDiv){
+            if ( addToDiv == null ) {
+                addToDiv = utils.div
+            }
+            addToDiv.append(ui)
+        }
+        utils.form = {};
+        utils.form.createTicker = function createTicker(cfg ) {//name, val, min, max) {
+            var ui = $('<input type="number" />')
+            ui.val(cfg.val)
+            ui.attr('id', cfg.id);
+            ui.css({width:'30px'})
+            return ui;
+        }
+
+        utils.url = function url(cfg) {
+            if ( cfg.url.indexOf('http://')==-1) {
+                cfg.url = 'http://'+cfg.url
+            }
+
+            function getDataFromUrl() {
+                var data = {};
+                data = cfg.data;
+                if ($.isFunction(cfg.data) ) {
+                    data = cfg.data();
+                }
+                //debugger;
+                $.ajax({
+                    url: cfg.url,
+                    data: data,
+                })
+                    .fail(function( data , t, e) {
+                        console.error(e)
+                    })
+                    .done(function( data ) {
+                        if ( cfg.fx ) cfg.fx(data)
+                    });
+            }
+            return getDataFromUrl;
+        }
+        utils.urls = {};
+        utils.urls.getValueJSON = function getValueJSON(cfg, storeAs) {
+            function getJSON() {
+
+                if ($.isString(cfg)) {
+                    cfg = {storeAs:storeAs, jqueryVal:cfg}
+                }
+
+                var json = {};
+                json[cfg.storeAs] = cfg.prop
+                if ( cfg.fx ) {
+                    json[cfg.storeAs] = cfg.fx()
+                }
+                if ( cfg.jqueryVal ) {
+                    var ui = $(cfg.jqueryVal);
+                    json[cfg.storeAs]  =  ui.val();
+                }
+
+                return json;
+
+            }
+
+
+            return getJSON;
+        }
+
+
+        utils.convertJSONBoolean = function convertJSONBoolean(val) {
+            if ( val == 'true' ) {
+                val  = true;
+            }
+            if ( val == 'false' )
+                val = false;
+
+            return val;
+        }
+
+        function createUpDownPath() {
+            var containerJumpUpDown  = $('<div></div>')
+            if ( json.subServer ) {
+                utils.appendToDiv(containerJumpUpDown, 'subServer')
+                utils.addBtn(containerJumpUpDown, 'p',
+                    json.topServerIp+'/dashboard_dal.html')
+            }
+
+            if ( json.topServer ) {
+                utils.appendToDiv(containerJumpUpDown, 'topServer');
+                $.each(json.tableServers, function(k,v){
+                    utils.addBtn(containerJumpUpDown, v.tableName,
+                        v.ip+'/dashboard_dal.html')
+                });
+            }
+            containerJumpUpDown.append($("<br />"));
+            cfg.div.prepend(containerJumpUpDown)
+            containerJumpUpDown.append($("<br />"));
+        }
+        createUpDownPath();
+
+        function createSyncPath() {
+            var containerJumpUpDown  = utils.newDiv()
+            utils.div = containerJumpUpDown;
+
+            /*utils.appendToDiv(containerJumpUpDown, json.enableAutoSync);
+
+            utils.addBtn(containerJumpUpDown, 'toggle-autoSync',
+                utils.url(
+                    {
+                        url:json.ip+'/dbUpdateSettings',
+                        data:utils.urls.getValueJSON(
+                            {
+                                fx: function toggleSync() {
+                                    var x = json.enableAutoSync;
+                                    x = utils.convertJSONBoolean(x)
+                                    return ! x
+                                },
+                                storeAs: 'enableAutoSync'
+                            }
+                        ),
+                        fx:getConfigBtnObj.fx,
+                    }
+                )
+            )*/
+
+
+            utils.appendToDiv(containerJumpUpDown, json.enableSync);
+            utils.addBtn(containerJumpUpDown, 'toggle-enableSync',
+                utils.url(
+                    {
+                        url:json.ip+'/dbUpdateSettings',
+                        data:utils.urls.getValueJSON(
+                            {
+                                fx: function toggleSync() {
+                                    var x = json.enableSync;
+                                    x = utils.convertJSONBoolean(x)
+                                    return ! x
+                                },
+                                storeAs: 'enableSync'
+                            }
+                        ),
+                        fx:getConfigBtnObj.fx,
+                    }
+                )
+            )
+
+            utils.addBr();
+            //utils.form.addTicker(containerJumpUpDown,  json.syncTime);
+            var t = utils.form.createTicker({id:"numUpdateTime", val:json.syncTime});
+            utils.add(t)
+            utils.addBtn(containerJumpUpDown, 'update',
+                utils.url(
+                    {
+                        url:json.ip+'/dbUpdateSettings',
+                        data:utils.urls.getValueJSON('#numUpdateTime', 'syncTime')
+                    }
+                )
+            );
+            // $.each(json.tableServers, function(k,v){
+            // utils.addBtn(containerJumpUpDown, v.tableName,
+            //    v.ip+'/dashboard_dal.html', {syncTime:0} )
+            // });
+            utils.appendToDiv(containerJumpUpDown,  json.syncTime)
+            utils.addBr();
+            utils.addBr();
+            cfg.div.prepend(containerJumpUpDown)
+            utils.addBr();
+        }
+        createSyncPath();
+
+
+
+        $('#txtTitle').html([json.name,json.tableName,'db'].join(' '));
+
+
+    }
+
+
+
+    function createPeerBtns(cfg) {
+        //debugger;
+        // var json = JSON.parse(cfg.data);
+
+        var containerJumpLinks = $('<div></div>')
+        var tableTop = $('<table></table>');
+        //debugger;
+
+        var homeVersion = null;
+
+        function process(obj, x,y) {
+
+            var vvv = new Date(obj.v).getTime();
+            if ( homeVersion == null ) {
+                homeVersion = vvv;
+                vvv = 0
+            }
+            else {
+                vvv =   vvv - homeVersion;
+                vvv =  (vvv / 1000).toFixed()
+                if ( Math.abs(vvv) < 60 ) {
+                    vvv += 's'
+                }else {
+                    vvv = (vvv / 60).toFixed()
+                    if (  Math.abs(vvv) < 60 ) {
+                        vvv += 'm'
+                    } else {
+                        vvv = (vvv / 60).toFixed()
+                        if (  Math.abs(vvv) < 60 ) {
+                            vvv += 'h'
+                        } else {
+                            vvv =  (vvv / 24).toFixed()
+                            if (  Math.abs(vvv) < 60 ) {
+                                vvv += 'd'
+                            }
+                        }
+                    }
+
+                }
+
+            }
+
+            //debugger;
+            var btn = $('<button></button>');
+            btn.html([/*x,y,*/obj.name,vvv,'(',obj.count,')'].join(' '))
+            containerJumpLinks.append(btn);
+
+            var tr = $('<tr></tr>');
+            for ( var i = 0; i < x; i++ ) {
+                var td = $('<td></td>');
+                // td.append(btn.clone())
+                tr.append(td);
+            }
+            var td = $('<td></td>');
+            //td.html([x,y,obj.name])
+            td.append(btn.clone())
+            tr.append(td);
+            tableTop.append(tr)
+
+
+            if ( obj.nestedResults == null ) return;
+            $.each(obj.nestedResults, function procNested(k,nestedObj) {
+                process(nestedObj, x+1, k+y+1)
+            })
+        }
+        process(cfg.data, 1,1)
+
+        cfg.div.prepend(containerJumpLinks)
+
+        cfg.div.prepend(tableTop)
+
+        return;
+        utils.dictPeersToIp = dictPeersToIp;
+        $.each(json.dictPeersToIp, function (peerName,ip) {
+            var btn = $('<button></button>');
+            btn.html(peerName);
+            btn.click(function onClick(){
+                var url = ip+'/dashboard_dal.html'
+                if ( url.indexOf('http://')==-1)
+                    url = 'http://'+url
+                utils.redirectTo(url )
+
+            })
+            containerJumpLinks.append(btn);
+        })
+
+        containerJumpLinks.append($("<br />"));
+
+        cfg.div.prepend(containerJumpLinks)
+
+        $('#txtTitle').html(json.name + ' ' + 'db');
+    }
+
+//utils.addInfo('get config')
+
+// utils.br();
+
+
+    utils.addDBAction('get config', 'listRecords')
+    var result = utils.addBtn(
+        {
+            url:'/listRecords',
+            toDiv:'listRecords',
+            fx:function updateColor(cfg) {
+                function TableUtils() {
+                    var self = this;
+                    var p = self;
+                    p.addCell = function addCell(btn) {
+                        var td = $('<td></td>');
+                        td.append(btn )
+                        self.td = td;
+                        self.tr.append(td);
+                    }
+                    p.addRow = function addRow(btn) {
+                        var tr = $('<tr></tr>');
+                        self.tr = tr;
+                        self.tbl.append(tr)
+                    }
+                    p.createTable = function c() {
+                        var tbl = $('<table></table>')
+                        self.tbl = tbl
+                        return self.tbl
+                    }
+
+                    p.makeLink = function makeLink(title, url, desc, target) {
+                        var a = $('<a></a>')
+                        a.attr('href', url)
+                        a.attr('title', desc)
+                        a.html(title)
+                        if ( target === true )
+                            a.attr('target', '_blank')
+                        return a;
+                    }
+                }
+                var tableUtils = new TableUtils()
+                var tbl = tableUtils.createTable()
+
+
+                $.each(cfg.data, function addButton(k,v){
+                    var btn = $('<btn></btn>')
+                    //debugger
+                    btn.html([v.id, v.name].join(' '))
+                    tableUtils.addRow()
+                    tableUtils.addCell(btn)
+                    var id = '/'+ v.id
+                    var link = tableUtils.makeLink('x', '/deleteRecord'+id, 'remove link', true)
+                    tableUtils.addCell(link)
+                    var link = tableUtils.makeLink('--', '/purgeRecord'+id, 'remove link', true)
+                    tableUtils.addCell(link)
+
+                })
+                //debugger
+                cfg.div.prepend(tbl)
+            }
+        }
+    )
+
+
+
+
+    utils.addDBAction('Add Record', 'addRecord')
+    var result = utils.addBtn(
+        {
+            url:'/addRecord',
+            toDiv:'addRecord',
+
+            // fx:createJumpLinks
+        }
+    )
+
+
+    utils.addDBAction('Full Sync', 'fullSync')
+    var result = utils.addBtn(
+        {
+            data:{
+                type:'sync',
+                fromPeer:'?'
+            },
+            url:'/atomicAction',
+            toDiv:'fullSync',
+            name:'Full Sync'
+            // fx:createJumpLinks
+        }
+    )
+
+
+//atomicAction
+    utils.addDBAction('Get Peers', 'getPeersInfo')
+    var result = utils.addBtn(
+        {
+            why: 'See all peers and count and version of peers',
+            url:'/atomicAction',
+            toDiv:'getPeersInfo',
+            name:'Count Cluster',
+            data:{
+                type:'count',
+                fromPeer:'?'
+            },
+            // fx:createJumpLinks
+        }
+    )
+
+    utils.addDBAction('Count', 'countRecords')
+    var result = utils.addBtn(
+        {
+            url:'/countRecords',
+            toDiv:'countRecords',
+            // fx:createJumpLinks
+        }
+    )
+
+    utils.addDBAction('Get Peers', 'getAllPeers')
+    var result = utils.addBtn(
+        {
+            why: 'Get all peers, and create btns for all peers',
+            url:'/atomicAction',
+            toDiv:'getAllPeers',
+            name:'Get All Cluster',
+            data:{
+                type:'count',
+                fromPeer:'?'
+            },
+            fx:createPeerBtns
+        }
+    )
+
+
+    utils.addDBAction('Delete Purged', 'deletePurged')
+    var result = utils.addBtn(
+        {
+            why: 'Remove purged',
+            url:'/purgeDeletedRecords',
+            toDiv:'deletePurged',
+            name:'Remove all purged records',
+            data:{
+                type:'count',
+                fromPeer:'?'
+            },
+        }
+    )
+
+
+
+
+    utils.addDBAction('isSynced', 'isSynced')
+    var result = utils.addBtn(
+        {
+            why: 'Get all peers, and create btns for all peers',
+            url:'/isClusterSynced',
+            toDiv:'isSynced',
+            name:'isSynced?',
+            data:{
+                type:'count',
+                fromPeer:'?'
+            },
+            fx:function markColor(cfg) {
+                //debugger
+                if ( cfg.data.synced )
+                    cfg.div.css('background-color', 'green' )
+                else
+                    cfg.div.css('background-color', 'red' )
+            }
+            // fx:createPeerBtns
+        }
+    )
+
+
+    utils.addDBAction('get config', 'node_enable')
+    utils.addBtn('/getConfig', 'node_enable')
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.bak.before.incremental
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.bak.before.incremental	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server.js.bak.before.incremental	(revision )
@@ -0,0 +1,1144 @@
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+sh.isNumber =  function isNumeric(n) {
+    return !isNaN(parseFloat(n)) && isFinite(n);
+}
+
+function SQLSharingServer() {
+    var p = SQLSharingServer.prototype;
+    p = this;
+    var self = this;
+    p.init = function init(config) {
+        self.settings = {};     //store settings and values
+        if (config) {
+            self.settings = config;
+        } else
+        {
+            var cluster_settings = rh.loadRServerConfig(true);
+        }
+        //self.settings.port = 3001;
+
+        self.server_config = rh.loadRServerConfig(true);  //load server config
+
+        self.app = express();   //create express server
+        self.createRoutes();    //decorate express server
+        self.createSharingRoutes();
+
+        self.app.listen(self.settings.port);
+        self.proc('started server on', self.settings.port);
+
+        self.identify();
+        self.connectToDb();
+    }
+
+    p.linkTo = function linkTo(peerToAdd, reset ) {
+        var reset = sh.dv(reset, false);
+        if ( reset ) {
+            self.settings.cluster_config.peers = []
+        }
+
+
+        var foundSelf = false;
+
+
+        var peersToAdd = sh.forceArray(peerToAdd);
+        sh.each(peersToAdd, function (k, peer)  {
+
+
+            sh.each(peer, function (peerName, ipAddOrPeer)  {
+                var peer = ipAddOrPeer;
+                if ( sh.isNumber(ipAddOrPeer) ) {
+                    // return;
+                    //peer =
+                }
+                else if ( peer.settings != null ) {
+                    var peer = ipAddOrPeer.settings.ip;
+                }
+
+                if ( ipAddOrPeer == self.settings.ip) {
+                    foundSelf = true;
+                }
+                //peersToAdd[k] = peer;
+                //self.settings.cluster_config.peers[peerName] = peer;
+                var newPeer = {}
+                newPeer[peerName] = peer;
+                self.settings.cluster_config.peers.push(newPeer);
+            })
+        })
+
+        if ( foundSelf == false) {
+            //self.settings.cluster_config.peers[self.settings.name] = self.settings.ip;
+            var myPeer = {}
+            myPeer[self.settings.name] = self.settings.ip;
+            self.settings.cluster_config.peers.push(myPeer);
+        }
+        self.identify();
+    }
+
+    p.createRoutes = function createRoutes() {
+        self.app.post('/upload', function (req, res) {});
+    }
+
+    function defineRoutes() {
+        self.showCluster = function showCluster(req, res) {
+            res.send(self.settings);
+        };
+        self.showTable  = function showCluster(req, res) {
+            res.send('ok');
+        };
+        self.getTableData = function getTableData(req, res) {
+
+            var incremental = false;
+            if ( req.originalUrl.indexOf('getTableDataIncre') != -1 ) {
+                incremental = true;
+            };
+
+            var syncResult =  req.query.sync == "true";
+            self.pull( function syncComplete() {
+                if ( syncResult == false ) {
+                    res.send('ok');
+                }
+            }, incremental );
+
+            if ( syncResult ) {
+                res.send('ok');
+            }
+        };
+
+        self.verifySync = function verifySync(req, res) {
+            self.pull2( function syncComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                res.send(result);
+            } );
+
+        };
+
+
+        self.reverseSync = function reverseSync(req, res) {
+            if ( self.utils == null ) self.utils = {};
+            self.utils.forEachPeer = function fEP(fxPeer, fxDone) {
+                sh.async(self.settings.peers,
+                    fxPeer, function allDone() {
+                        sh.callIfDefined(fxDone);
+                    })
+                return;
+            }
+
+            self.utils.forEachPeer(fxEachPeer, fxComplete);
+            /* self.pull2( function syncComplete(ok) {
+             var result = {};
+             result.ok = ok;
+             res.send(result);
+             } );*/
+            function fxEachPeer(ip, fxDone) {
+                var config = {showBody:false};
+                config.baseUrl = ip;
+                var t = EasyRemoteTester.create('Sync Peer', config);
+                var urls = {};
+                urls.sync = t.utils.createTestingUrl('sync');
+                var reqData = {};
+                reqData.data =  0
+                t.getR(urls.sync).why('get syncronize the other side')
+                    .with(reqData).storeResponseProp('count', 'count')
+                // t.addSync(fxDone)
+                t.add(function(){
+                    fxDone()
+                    t.cb();
+                })
+                //fxDone();
+            }
+            function fxComplete(ok) {
+                var result = {};
+                result.ok = ok;
+                res.send(result);
+            }
+        };
+
+
+
+        self.getCount = function getCount(req, res) {
+            //count records in db with my source
+            /*
+             q: do get all records? only records with me as source ..
+             // only records that are NOT related to user on other side
+             */
+
+            var dateSet = new Date()
+            var dateInt = parseInt(req.query.global_updated_at)
+            var dateSet = new Date(dateInt);
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                query.where = {global_updated_at:{$gt:dateSet}};
+                query.order = ['global_updated_at',  'DESC']
+            }
+
+            self.proc('who is request from', req.query.peerName);
+            self.dbHelper2.countAll(function gotAllRecords(count){
+                self.count = count;
+                res.send({count:count});
+                if ( req.query.global_updated_at != null ) {
+                    var dbg = dateSet ;
+                    return;
+                }
+            }, query);
+        };
+
+        self.getSize = function getSize(cb) {
+            self.dbHelper2.count(function gotAllRecords(count){
+                self.count = count;
+                self.size = count;
+                sh.callIfDefined(cb)
+            })
+        }
+
+        self.getRecords = function getRecords(req, res) {
+            var query = {}
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(dateInt);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            query.order = ['global_updated_at',  'DESC']
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                res.send(recs);
+            } )
+        };
+        self.getNextPage = function getRecords(req, res) {
+            var query = {}
+            query.where  = {};
+            if ( req.query.global_updated_at != null ) {
+                var dateSet = new Date()
+                var dateInt = parseInt(req.query.global_updated_at)
+                var dateSet = new Date(req.query.global_updated_at);
+                query.where = {global_updated_at:{$gt:dateSet}};
+            }
+            query.order = ['global_updated_at',  'DESC']
+            query.limit = 100;
+            self.dbHelper2.search(query, function gotAllRecords(recs){
+                self.recs = recs;
+                res.send(recs);
+            } )
+        };
+
+        /*self.syncRecords = function syncRecords(req, res) {
+         self.dbHelper2.getAll(function gotAllRecords(recs){
+         self.recs = recs;
+         res.send(recs);
+         })
+         };*/
+
+        p.createSharingRoutes = function createSharingRoutes() {
+            self.app.get('/showCluster', self.showCluster );
+            self.app.get('/showTable/:tableName', self.showTable );
+            self.app.get('/getTableData/:tableName', self.getTableData);
+
+            self.app.get('/verifySync', self.verifySync);
+            self.app.get('/getTableData', self.getTableData);
+            self.app.get('/getTableDataIncremental', self.getTableData);
+            self.app.get('/count', self.getCount );
+            self.app.get('/getRecords', self.getRecords );
+            self.app.get('/getNextPage', self.getNextPage );
+            self.app.get('/verifySync', self.verifySync );
+
+            self.app.get('/reverseSync', self.reverseSync );
+            self.app.get('/sync', self.getTableData);
+            //self.app.get('/syncRecords', self.syncRecords );
+        };
+    }
+    defineRoutes();
+
+    function defineSyncRoutines() {
+        self.sync = {};
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull = function pullFromPeers(cb, incremental) {
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function syncPeer(peerIp, fxDoneSync) {
+                    self.proc('syninc peer', peerIp );
+                    self.sync.syncPeer( peerIp, function syncedPeer() {
+                        fxDoneSync()
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records synced');
+                    sh.callIfDefined(cb)
+                })
+            return;
+            /*
+             async
+             syncpeer
+             get count after udapted time, or null
+             offset by 100
+             get count afater last updated time
+             next
+             res.send('ok');
+             */
+        };
+
+
+
+        /**
+         * Get count ,
+         * offset by 1000
+         * very count is same
+         * @param ip
+         * @param cb
+         */
+        self.sync.syncPeer = function syncPeer(ip, cb, incremental) {
+            var config = {showBody:false};
+            config.baseUrl = ip;
+
+            var t = EasyRemoteTester.create('Sync Peer', config);
+            var urls = {};
+            urls.register = t.utils.createTestingUrl('register');
+
+            urls.getCount = t.utils.createTestingUrl('count');
+            urls.getRecords = t.utils.createTestingUrl('getRecords');
+
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName = self.settings.peerName;
+            if (incremental) {
+                if (self.dictPeerSyncTime[ip] == null) {
+                    self.dictPeerSyncTime[ip] = new Date();
+                }
+                reqData.global_updated_at = self.dictPeerSyncTime[ip].getTime();
+                reqData.incremental = true;
+            }
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+
+            t.add(function getRecordCount(){
+                var y = t.data.count;
+                t.cb();
+            });
+
+            t.recordsAll = [];
+
+            t.add(function syncRecourds(){
+                t.quickRequest( urls.getRecords,
+                    'get', result, reqData);
+                function result(body) {
+                    t.assert(body.length!=null, 'no page');
+                    t.records = body;
+                    t.recordsAll = t.recordsAll.concat(body);
+                    t.cb();
+                };
+            });
+            t.add(function filterNewRecordsForPeerSrc(){
+                t.cb();
+            })
+            t.add(function deleteAllRecordsForPeerName(){
+                self.dbHelper2.upsert(t.records, function upserted(){
+                    t.cb();
+                })
+            })
+            t.add(function countRecords(){
+                self.dbHelper2.count(  function upserted(count){
+                    self.size = count;
+                    t.cb();
+                })
+            })
+            t.add(function verifySync(){
+                self.lastUpdateSize = t.recordsAll.length;
+                self.lastRecords = t.recordsAll;
+                if ( t.recordsAll.length > 0 )
+                    self.dictPeerSyncTime[ip] = t.recordsAll[0].global_updated_at;
+                sh.callIfDefined(cb)
+            })
+
+        }
+
+
+
+
+        /**
+         * Ping all peers, in async, pull from each peer
+         * @param cb
+         */
+        self.pull2 = function verifyFromPeers(cb, incremental) {
+            var resultsPeers = {};
+            var result = true;
+            self.pulling = true;
+            sh.async(self.settings.peers,
+                function verifySyncPeer(peerIp, fxDoneSync) {
+                    self.proc('verifying peer', peerIp );
+                    self.sync.verifySyncPeer( peerIp, function syncedPeer(ok) {
+                        resultsPeers[peerIp] = ok
+                        if ( ok == false ) {
+                            result = false;
+                        }
+                        fxDoneSync(ok )
+                    }, incremental);
+                }, function allDone() {
+                    self.proc('all records verified');
+                    sh.callIfDefined(cb, result, resultsPeers)
+                })
+            return;
+        };
+
+
+
+        /**
+         * Ask for each peer record, starting from the bottom
+         * @param ip
+         * @param cb
+         */
+        self.sync.verifySyncPeer = function syncPeer(ip, cb, incremental) {
+            var config = {showBody:false};
+            config.baseUrl = ip;
+
+            var t = EasyRemoteTester.create('Sync Peer', config);
+            var urls = {};
+
+            urls.getCount = t.utils.createTestingUrl('count');
+            urls.getRecords = t.utils.createTestingUrl('getRecords');
+            urls.getNextPage = t.utils.createTestingUrl('getNextPage');
+
+            if ( self.dictPeerSyncTime == null )
+                self.dictPeerSyncTime = {};
+
+            var reqData = {};
+            reqData.peerName = self.settings.peerName;
+
+            t.getR(urls.getCount).why('get getCount')
+                .with(reqData).storeResponseProp('count', 'count')
+
+            t.add(function getRecordCount(){
+                var recordCount = t.data.count;
+                t.cb();
+            });
+
+            t.recordsAll = [];
+            t.recordCount = 0 ;
+            t.iterations = 0
+            t.matches = [];
+
+            t.add(getRecordsUntilFinished);
+            function getRecordsUntilFinished(){
+
+                t.quickRequest( urls.getNextPage,
+                    'get', onGotNextPage, reqData);
+                function onGotNextPage(body) {
+                    t.assert(body.length!=null, 'no page');
+                    if ( body.length != 0 ) {
+                        reqData.global_updated_at = body[0].global_updated_at;
+
+
+                        t.addNext(function verifyRecords(){
+                            var query = {};
+                            var dateFirst = new Date(body[0].global_updated_at);
+                            if ( body.length > 1 ) {
+                                var dateLast = new Date(body.slice(-1)[0].global_updated_at);
+                            } else {
+                                dateLast = dateFirst
+                            }
+                            query.where = {
+                                global_updated_at: {$gte:dateFirst},
+                                $and: {
+                                    global_updated_at: {$lte:dateLast}
+                                }
+                            };
+                            query.order = ['global_updated_at',  'DESC'];
+                            self.dbHelper2.search(query, function gotAllRecords(recs){
+                                var yquery = query;
+                                var match = self.dbHelper2.compareTables(recs, body);
+                                if ( match != true ) {
+                                    t.matches.push(t.iterations)
+                                    self.proc('match issue on', t.iterations, recs.length, body.length)
+                                }
+                                t.cb();
+                            } )
+                        })
+                        t.addNext(getRecordsUntilFinished)
+                    }
+                    t.recordCount += body.length;
+                    t.iterations  += 1
+                    t.recordsAll = t.recordsAll.concat(body); //not sure about this
+                    t.cb();
+                };
+
+                //var recordCount = t.data.count;
+                //t.cb();
+            }
+
+
+            t.add(function filterNewRecordsForPeerSrc(){
+                t.ok = t.matches.length == 0;
+                t.cb();
+            })
+            t.add(function deleteAllRecordsForPeerName(){
+                t.cb();
+            })
+            /* t.add(function countRecords(){
+             self.dbHelper2.count(  function upserted(count){
+             self.size = count;
+             t.cb();
+             })
+             })*/
+            t.add(function verifySync(){
+                //    self.lastUpdateSize = t.recordsAll.length;
+                //  if ( t.recordsAll.length > 0 )
+                //        self.dictPeerSyncTime[ip] = t.recordsAll[0].global_updated_at;
+                sh.callIfDefined(cb, t.ok)
+            })
+
+        }
+    }
+    defineSyncRoutines();
+
+
+    p.identify = function identify() {
+        if ( self.settings.cluster_config == null )
+            throw new Error ( ' need cluster config ')
+
+
+        if ( self.settings.port != null &&
+            sh.includes(self.settings.ip, self.settings.port) == false ) {
+            self.settings.ip = null; //clear ip address if does not include port
+        };
+
+        self.settings.ip = sh.dv(self.settings.ip, '127.0.0.1:'+self.settings.port); //if no ip address defined
+        if ( self.settings.ip.indexOf(':')== -1 ) {
+            self.settings.ip = self.settings.ip+':'+self.settings.port;
+        }
+        self.proc('ip address', self.settings.ip);
+
+        self.settings.peers = [];
+        var foundPeerEntryForSelf = false;
+        sh.each(self.settings.cluster_config.peers, function findMatchingPeer(i, ipSection){
+            var peerName = null;
+            var peerIp = null;
+            sh.each(ipSection, function getIpAddressAndName(name, ip) {
+                peerName = name;
+                peerIp = ip;
+            })
+            if ( self.settings.peerName != null ) {
+                if (self.settings.peerName == peerName) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+            } else {
+                if (self.settings.ip == peerIp) {
+                    foundPeerEntryForSelf = true;
+                    self.settings.name = peerName;
+                    return;
+                }
+            }
+            console.error('....');
+            self.settings.peers.push(peerIp);
+        });
+        self.proc(self.settings.peerName, 'foundPeerEntryForSelf', foundPeerEntryForSelf, self.settings.peers.length,  self.settings.peers);
+        if ( foundPeerEntryForSelf == false ) {
+            throw new Error('did not find self in config')
+        }
+        if (  self.settings.peers.length == 0 ) {
+            throw new Error('init: not enough peers')
+        }
+    }
+
+
+    function defineDatabase() {
+        function defineDbHelpers() {
+            var dbHelper = {};
+            self.dbHelper2 = dbHelper;
+            dbHelper.count = function (fx, table) {
+                table = sh.dv(table, self.Table);
+                //console.error('count', table.name, name)
+                table.count({where: {}}).then(function onResults(count) {
+                    self.count = count;
+                    self.proc('count', count);
+                    sh.callIfDefined(fx, count);
+                })
+            }
+
+            dbHelper.utils = {};
+            dbHelper.utils.queryfy = function queryfy(query) {
+                query = sh.dv(query, {});
+                var fullQuery = {};
+                if ( query.where != null ) {
+                    fullQuery = query;
+                }else {
+                    fullQuery.query = query;
+                }
+                return fullQuery;
+            }
+
+            dbHelper.countAll = function (fx, query) {
+                var fullQuery = dbHelper.utils.queryfy(query)
+                self.Table.count(fullQuery).then(function onResults(count) {
+                    self.count = count;
+                    self.proc('count', count)
+                    sh.callIfDefined(fx, count)
+                    //  self.version = objs.updated_at.getTime();
+                })
+            }
+
+            dbHelper.getUntilDone = function (query, limit, fx, fxDone, count) {
+                var index = 0;
+                if (count == null) {
+                    dbHelper.countAll(function (initCount) {
+                        count = initCount;
+                        nextQuery();
+                    }, query)
+                    return;
+                }
+                ;
+
+                function nextQuery(initCount) {
+                    self.proc(index, count, (index / count).toFixed(2));
+                    if (index >= count) {
+                        if (index == 0 && count == 0) {
+                            sh.callIfDefined(fx, [], true);
+                        }
+                        sh.callIfDefined(fxDone);
+                        //sh.callIfDefined(fx, [], true);
+                        return;
+                    }
+                    ;
+
+                    self.Table.findAll(
+                        {
+                            limit: limit,
+                            offset: index,
+                            where: query,
+                            order: 'global_updated_at ASC'
+                        }
+                    ).then(function onResults(objs) {
+                            var records = [];
+                            var ids = [];
+                            sh.each(objs, function col(i, obj) {
+                                records.push(obj.dataValues);
+                                ids.push(obj.dataValues.id);
+                            });
+                            self.proc('sending', records.length, ids)
+                            index += limit;
+
+                            var lastPage = false;
+                            if (index >= count) {
+                                lastPage = true
+                            }
+                            // var lastPage = records.length < limit;
+                            //lastPage = index >= count;
+                            // self.proc('...', lastPage, index, count)
+                            sh.callIfDefined(fx, records, lastPage);
+                            sh.callIfDefined(nextQuery)
+                        }
+                    ).catch(function (err) {
+                            console.error(err, err.stack);
+                            throw(err);
+                        })
+                }
+
+                nextQuery();
+
+
+            }
+
+
+            dbHelper.getAll = function getAll(fx) {
+                dbHelper.search({}, fx);
+            }
+            dbHelper.search = function search(query, fx, convert) {
+                convert = sh.dv(convert, true)
+                //table = sh.dv(table, self.Table);
+                var fullQuery = dbHelper.utils.queryfy(query)
+                self.Table.findAll(
+                    fullQuery
+                ).then(function onResults(objs) {
+                        if (convert) {
+                            var records = [];
+                            var ids = [];
+                            sh.each(objs, function col(i, obj) {
+                                records.push(obj.dataValues);
+                                ids.push(obj.dataValues.id);
+                            });
+                        } else {
+                            records = objs;
+                        }
+                        sh.callIfDefined(fx, records)
+                    }
+                ).catch(function (err) {
+                        console.error(err, err.stack);
+                        fx(err)
+                        throw(err);
+                    })
+            }
+
+
+            self.dbHelper2.upsert = function upsert(records, fx) {
+                records = sh.forceArray(records);
+                var dict = {};
+                var dictOfExistingItems = dict;
+                var queryInner = {};
+                var statements = [];
+
+                var newRecords = [];
+                var ids = [];
+                sh.each(records, function putInDict(i, record) {
+                        ids.push(record.id)
+                    }
+                )
+                self.proc(self.name, ':', 'upsert', records.length, ids)
+                if (records.length == 0) {
+                    sh.callIfDefined(fx);
+                    return;
+                }
+
+                sh.each(records, function putInDict(i, record) {
+                    if (record.id_timestamp == null || record.source_node == null) {
+                        throw new Error('bad record ....');
+                    }
+                    if (sh.isString(record.id_timestamp)) { //NO: this is id ..
+                        //record.id_timestamp = new Date(record.id_timestamp);
+                    }
+                    if (sh.isString(record.global_updated_at)) {
+                        record.global_updated_at = new Date(record.global_updated_at);
+                    }
+
+                    var dictKey = record.id_timestamp + record.source_node
+                    if (dict[dictKey] != null) {
+                        self.proc('duplicate keys', dictKey)
+                        throw new Error('duplicate key error on unique timestamps' + dictKey)
+                        return;
+                    }
+                    dict[dictKey] = record;
+                    /*statements.push(SequelizeHelper.Sequlize.AND(
+
+
+                     ))*/
+
+                    statements.push({
+                        id_timestamp: record.id_timestamp,
+                        source_node: record.source_node
+                    });
+                })
+
+                if (statements.length > 0) {
+                    queryInner = SequelizeHelper.Sequelize.or(statements)
+                    queryInner = SequelizeHelper.Sequelize.or.apply(this, statements)
+
+                    //find all matching records
+                    var query = {where: queryInner};
+
+                    self.Table.findAll(query).then(function (results) {
+                        self.proc('found existing records');
+                        sh.each(results, function (i, eRecord) {
+                            var eRecordId = eRecord.id_timestamp + eRecord.source_node;
+                            var newerRecord = dictOfExistingItems[eRecordId];
+                            if (newerRecord == null) {
+                                self.proc('warning', 'look for record did not have in database')
+                                //newRecords.push()
+                                return;
+                            }
+
+                            //do a comparison
+                            var dateOldRecord = parseInt(eRecord.dataValues.global_updated_at.getTime());
+                            var dateNewRecord = parseInt(newerRecord.global_updated_at.getTime());
+                            var newer = dateNewRecord > dateOldRecord;
+                            var sameDate = eRecord.dataValues.global_updated_at.toString() == newerRecord.global_updated_at.toString()
+                            if ( self.settings.showWarnings ) {
+                                self.proc('compare',
+                                    eRecord.name,
+                                    newerRecord,
+                                    newer,
+                                    eRecord.dataValues.global_updated_at, newerRecord.global_updated_at);
+                            }
+                            if ( newer == false ) {
+                                if ( self.settings.showWarnings )
+                                    self.proc('warning', 'rec\'v object that is older', eRecord.dataValues)
+                            }
+                            else if (sameDate) {
+                                if ( self.settings.showWarnings )
+                                    self.proc('warning', 'rec\'v object that is already up to date', eRecord.dataValues)
+                            } else {
+                                console.error('newerRecord', newerRecord)
+                                eRecord.updateAttributes(newerRecord);
+                            }
+                            //handled item
+                            dictOfExistingItems[eRecordId] = null;
+                        });
+                        createNewRecords();
+                    });
+                } else {
+                    createNewRecords();
+                }
+
+                //update them all
+
+                //add the rest
+                function createNewRecords() {
+                    var _dictOfExistingItems = dictOfExistingItems;
+                    //mixin un copied records
+                    sh.each(dictOfExistingItems, function addToNewRecords(i, eRecord) {
+                        if (eRecord == null) {
+                            //already updated
+                            return;
+                        }
+                        console.error('removing id on', eRecord.id)
+                        eRecord.id = null;
+                        newRecords.push(eRecord);
+                    });
+
+                    if (newRecords.length > 0) {
+                        self.Table.bulkCreate(newRecords).then(function (objs) {
+
+                            self.proc('all records created', objs.length);
+                            //sh.each(objs, function (i, eRecord) {
+                            // var match = dict[eRecord.id_timestamp.toString() + eRecord.source]
+                            // eRecord.updateAttributes(match)
+                            // })
+                            sh.callIfDefined(fx);
+
+                        }).catch(function (err) {
+                            console.error(err, err.stack)
+                            throw  err
+                        })
+                    } else {
+                        self.proc('no records to create')
+                        sh.callIfDefined(fx)
+                    }
+
+
+                    /* sh.callIfDefined(fx)*/
+
+                }
+
+            }
+
+
+            self.dbHelper2.addNewRecord = function addNewRecord(record, fx) {
+                var item = record;
+                item.source_node = self.settings.peerName;
+                //item.desc = GenerateData.getName();
+                item.global_updated_at = new Date();
+                item.id_timestamp = (new Date()).toString() + '_' + Math.random() + '_' + Math.random();
+
+
+                var newRecords = [item];
+                self.Table.bulkCreate(newRecords).then(function (objs) {
+                    self.proc('all records created', objs.length);
+                    sh.callIfDefined(fx);
+                }).catch(function (err) {
+                    console.error(err, err.stack);
+                    throw  err
+                });
+
+            }
+
+
+            self.dbHelper2.compareTables = function compareTables(a, b) {
+                // console.log(nameA,data.count1,
+                //     nameB, data.count2, data.count1 == data.count2 );
+
+                var getId = function getId(obj){
+                    return obj.source_node + '_' + obj.id_timestamp//.getTime();
+                }
+
+                var dictTable1 = sh.each.createDict(
+                    a, getId);
+                var dictTable2 = sh.each.createDict(
+                    b, getId);
+
+                function compareObjs(a, b) {
+                    var badProp = false;
+                    if ( b == null ) {
+                        self.proc('b is null' )
+                        return false;
+                    }
+                    sh.each(self.settings.fields, function (prop, defVal) {
+                        if (['global_updated_at'].indexOf(prop)!= -1 ){
+                            return;
+                        }
+                        var valA = a[prop];
+                        var valB = b[prop];
+                        if ( valA != valB ) {
+                            badProp = true;
+                            self.proc('mismatched prop', prop, valA, valB)
+                            return false; //break out of loop
+                        }
+                    });
+                    if ( badProp ) {
+                        return false;
+                    }
+                    return true
+                }
+
+                var result = {};
+                result.notInA = []
+                result.notInB = [];
+                result.brokenItems = [];
+                function compareDictAtoDictB(dict1, dict2) {
+                    var diff = [];
+                    var foundIds = [];
+                    sh.each(dict1, function (id, objA) {
+                        var objB= dict2[id];
+                        if ( objB == null ) {
+                            // console.log('b does not have', id, objA)
+                            result.notInB.push(objA)
+                            // return;
+                        } else { //why: b/c if A has extra record ... it is ok...
+                            if (!compareObjs(objA, objB)) {
+                                result.brokenItems.push([objA, objB])
+                                //return;
+                            }
+                        }
+                        foundIds.push(id);
+                    });
+
+                    sh.each(dict2, function (id, objB) {
+                        if ( foundIds.indexOf(id) != -1 ) {
+                            return
+                        };
+                        /*if ( ! compareObjs(objA, objB)) {
+                         result.brokenItems.push(objA)
+                         return;
+                         }*/
+                        //console.log('a does not have', id, objB)
+                        result.notInA.push(objB)
+                    });
+                };
+
+                compareDictAtoDictB(dictTable1, dictTable2);
+
+                if ( result.notInA.length > 0 ) {
+                    //there were items in a did not find
+                    return false;
+                };
+                if ( result.brokenItems.length > 0 ) {
+                    self.proc('items did not match', result.brokenItems)
+                    return false;
+                };
+                return true;
+                return false;
+            }
+
+
+            self.dbHelper2.deleteRecord = function deleteRecord(id, cb) {
+                console.log('....d')
+
+
+                if ( sh.isNumber( id ) == false ) {
+                    /* self.Table.destroy(
+
+                     )*/
+                    console.log('...d.d')
+                    // self.Table.destroy(id)
+                    id.destroy()
+                        .then(function() {
+                            sh.callIfDefined(cb);
+                        })
+                } else {
+                    console.log('....d')
+                    self.Table.destroy({where:{id:id}})
+                        .then(function() {
+                            console.log('fff')
+                            sh.callIfDefined(cb);
+                        })
+                }
+
+            };
+        }
+
+        defineDbHelpers();
+
+        p.connectToDb = function connectToDb() {
+            var sequelize = rh.getSequelize(null, null, false);
+            self.sequelize = sequelize;
+            self.createTableDefinition();
+        }
+
+        /**
+         * Creates table object
+         */
+        p.createTableDefinition = function createTableDefinition() {
+            var tableSettings = {};
+            if (self.settings.force == true) {
+                tableSettings.force = true
+                tableSettings.sync = true;
+            }
+            tableSettings.name = self.settings.tableName
+            //tableSettings.name = sh.dv(sttgs.name, tableSettings.name);
+            tableSettings.createFields = {
+                name: "", desc: "", user_id: 0,
+                imdb_id: "", content_id: 0,
+                progress: 0
+            };
+
+
+            self.settings.fields = tableSettings.createFields;
+
+            var requiredFields = {
+                source_node: "", id_timestamp: "",
+                global_updated_at: new Date(), //make another field that must be changed
+                version: 0, deleted: true
+            }
+            sh.mergeObjects(requiredFields, tableSettings.createFields);
+            tableSettings.sequelize = self.sequelize;
+            SequelizeHelper.defineTable(tableSettings, tableCreated);
+
+            function tableCreated(table) {
+                console.log('table ready')
+                //if ( sttgs.storeTable != false ) {
+                self.Table = table;
+                //  self.setVersion();
+                //  }
+                //  sh.callIfDefined(fx);
+                //   sh.callIfDefined(sttgs.fx, table)
+                /* if (self.settings.testMode) {
+                 self.test.createTestData();
+                 };*/
+                setTimeout(function () {
+                    sh.callIfDefined(self.settings.fxDone);
+                }, 100)
+
+
+            }
+        }
+
+        function defineTest() {
+            self.test = {};
+            self.test.createTestData = function createTestData(cb) {
+                GenerateData = shelpers.GenerateData;
+                var gen = new GenerateData();
+                var model = gen.create(100, function (item, id, dp) {
+                    item.name = id;
+                    // item.id = id;
+                    item.source_node = self.settings.peerName;
+                    item.desc = GenerateData.getName();
+                    item.global_updated_at = new Date();
+                    item.id_timestamp = (new Date()).toString() + '_' + Math.random();
+                });
+
+                var results = model;
+
+                self.Table.bulkCreate(results).then(
+                    function (results) {
+                        // Notice: There are no arguments here, as of right now you'll have to...
+                        if (cb != null) cb(results);
+                        return;
+                    }).catch(function (err) {
+                        console.log(err)
+                        // exit();
+                        setTimeout(function () {
+                            throw err;
+                        }, 5);
+                    });
+            }
+            self.test.destroyAllRecords = function (confirmed, fx) {
+                if (confirmed != true) {
+                    return false;
+                }
+
+                self.Table.destroy({where: {}}).then(function () {
+                    sh.callIfDefined(fx);
+                    self.proc('all records destroyed')
+                })
+
+            }
+
+
+            self.test.deleteRandomRecord = function (fx) {
+                /*Array.prototype.randsplice = function(){
+                 var ri = Math.floor(Math.random() * this.length);
+                 var rs = this.splice(ri, 1);
+                 return rs;
+                 }
+                 var obj = self.lastRecords.randsplice();
+
+                 if ( obj.length ==1 ) {
+                 obj = obj[0];
+                 }*/
+                //this will pull the other side records
+
+
+
+                self.test.getRandomRecord(function onGotRecord(rec) {
+                    self.dbHelper2.deleteRecord(rec.id, fx);
+                })
+
+
+                /*self.dbHelper2.count(function gotAllRecords(count){
+                 self.count = count;
+                 self.size = count;
+                 sh.callIfDefined(cb)
+                 })*/
+
+            };
+
+            self.test.getRandomRecord = function (fx) {
+
+                var query = {};
+                query.where  = {};
+
+                self.dbHelper2.countAll(function gotCount(count){
+                    self.count = count;
+                    //offset by count?
+                    query.order = ['global_updated_at',  'DESC']
+                    query.limit = 1;
+                    query.offset = parseInt(count*Math.random());
+                    self.dbHelper2.search(query, function gotAllRecords(recs){
+                        var obj = recs[0];
+                        sh.callIfDefined(fx, obj)
+                    } , false);
+                }, query);
+
+
+            }
+
+            self.test.saveRecord = function saveRecord(obj, fx) {
+                obj.save().then(function gotAllRecords(recs){
+                        sh.callIfDefined(fx, obj)
+                    }
+                )
+
+            }
+
+
+
+
+
+        }
+
+        defineTest();
+
+    }
+
+    defineDatabase();
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return;
+        }
+        sh.sLog(arguments);
+    }
+}
+
+exports.SQLSharingServer = SQLSharingServer;
+
+if (module.parent == null) {
+
+    return;
+
+
+}
\ No newline at end of file
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests.js	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests.js	(revision )
@@ -0,0 +1,936 @@
+/**
+ * Created by user on 1/13/16.
+ */
+/**
+ * Created by user on 1/3/16.
+ */
+/*
+ TODO:
+ Test that records are delete?
+ //how to do delete, have a delte colunm to sync dleet eitems
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+var SQLSharingServer = require('./sql_sharing_server').SQLSharingServer;
+
+if (module.parent == null) {
+
+    var configOverride = {};
+    configOverride.mysql = {
+        "ip" : "127.0.0.1",
+        "databasename" : "yetidb",
+        //"user" : "yetidbuser",
+        //"pass" : "aSDDD545y^",
+        "port" : "3306"
+    };
+
+    rh.configOverride = configOverride;
+
+    //load confnig frome file
+    //peer has gone down ... peer comes back
+    //real loading
+    //multipe tables
+
+    //define tables to sync and time
+    //create 'atomic' modes for create/update and elete
+    var cluster_config = {
+        peers:[
+            {a:"127.0.0.1:12001"},
+            {b:"127.0.0.1:12002"}
+        ]
+    };
+
+    var topology = {};
+    var allPeers = [];
+    var config = {};
+    config.cluster_config = cluster_config;
+    config.port = 12001;
+    config.peerName = 'a';
+    config.tableName = 'aA';
+    config.fxDone = testInstances
+    config.dbConfigOverride=true
+    config.dbLogging=false
+    //config.dbLogging=true //issue with queries ... when get >1000 items in db on sqllite
+    config.password = 'dirty'
+    var service = new SQLSharingServer();
+    service.init(config);
+    var a = service;
+    allPeers.push(service)
+    topology.a = a;
+
+    var config = sh.clone(config);
+    config.port = 12002;
+    config.peerName = 'b';
+    config.tableName = 'bA';
+    var service = new SQLSharingServer();
+    service.init(config);
+    var b = service;
+    allPeers.push(service)
+    topology.b = b;
+
+    var peerCount = 2;
+    var peerStartingIp = 12001
+    var _config = config;
+    function createNewPeer(name) {
+        var config = sh.clone(_config);
+
+
+
+        config.port = peerStartingIp+peerCount;
+        peerCount++;
+
+        var newPeerConfigObj = {};
+        newPeerConfigObj[name] = '127.0.0.1'+':'+config.port;
+        config.cluster_config.peers.push(newPeerConfigObj);
+
+        config.peerName = name;
+        config.tableName = config.peerName+'_ATest';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var b = service;
+        allPeers.push(service)
+        topology[name] = b;
+
+        return service;
+    }
+
+
+
+    function augmentNetworkConfiguration() {
+        if ( topology.augmentNetworkConfiguration) {
+            return;
+        }
+        topology.augmentNetworkConfiguration = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {c:"127.0.0.1:12003"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12003;
+        config.peerName = 'c';
+        config.tableName = 'cA';
+
+        var service = new SQLSharingServer();
+        service.init(config);
+        var c = service;
+        allPeers.push(service)
+        topology.c = c;
+        //c.linkTo({b:b});
+        b.linkTo({c:c})
+
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12004;
+        config.peerName = 'd';
+        config.tableName = 'dA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var d = service;
+        allPeers.push(service)
+        topology.d = d;
+        //d.linkTo({c:c});
+        b.linkTo({d:d})
+
+
+    }
+
+
+    function augmentNetworkConfiguration2() {
+        if ( topology.augmentNetworkConfiguration2) {
+            return;
+        }
+        topology.augmentNetworkConfiguration2 = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {e:"127.0.0.1:12005"}
+        ]
+        config.port = 12005;
+        config.peerName = 'e';
+        config.tableName = 'eA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var e = service;
+        allPeers.push(service)
+        topology.d.linkTo({e:e})
+
+
+    }
+
+
+    function testInstances() {
+        //make chain
+        var sh = require('shelpers').shelpers;
+        var shelpers = require('shelpers');
+        var EasyRemoteTester = shelpers.EasyRemoteTester;
+        var t = EasyRemoteTester.create('Test Channel Server basics',
+            {
+                showBody:false,
+                silent:true
+            });
+
+        var testC = {};
+        testC.speedUp = true;
+        testC.stopSlowTests = true
+
+        //t.add(clearAllData())
+        clearAllData()
+        t.add(function clearRecordsFrom_A(){
+            a.test.destroyAllRecords(true, t.cb);
+        })
+
+
+
+        if ( 'defineBlock' == 'defineBlock') {
+            function ResuableSection_verifySync(msg, size) { //verifies size of both peers
+                if ( msg == null ) {
+                    msg = ''
+                }
+                msg = ' ' + msg;
+                t.add(function getASize(){
+                    a.getSize(t.cb);
+                })
+                t.add(function getBSize(){
+                    b.getSize(t.cb);
+                })
+                t.add(function testSize(){
+                    if ( size ) {
+                        t.assert(b.size == size, 'sync did not work (sizes different) a' + [a.size, size] + msg)
+                        t.assert(a.size == size, 'sync did not work (sizes different) b' + [b.size, size] + msg)
+                    }
+                    t.assert(b.size== a.size, 'sync did not work (sizes different)' + [b.size, a.size] + msg)
+                    t.cb();
+                })
+            }
+
+            function ResuableSection_addRecord() {
+                t.add(function addNewRecord() {
+                    a.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+                });
+            };
+
+            var baseUrl = 'http://127.0.0.1:'+ b.settings.port;
+            var urls = {};
+
+            t.settings.baseUrl = baseUrl;
+            urls.getTableData = t.utils.createTestingUrl('getTableData');
+            urls.syncIn = t.utils.createTestingUrl('syncIn');
+            urls.syncInB = t.utils.createTestingUrl('syncReverse');
+            urls.syncReverseB = t.utils.createTestingUrl('syncReverse');
+
+            //do partial sync
+            //sync from http request methods
+            //batched sync
+            //remove batch tester
+            //cluster config if no config sent
+
+            function defineHTTPTestMethods() {
+                //var t = EasyRemoteTester.create('Test Channel Server basics',{showBody:false});
+
+                ResuableSection_addRecord();
+
+                t.getR(urls.getTableData).with({sync:false})
+                    // .bodyHas('status').notEmpty()
+                    .fxDone(function syncComplete(result) {
+                        return;
+                    });
+
+                ResuableSection_verifySync();
+            }
+
+            function define_TestIncrementalUpdate () {
+                urls.getTableData = t.utils.createTestingUrl('getTableDataIncremental');
+
+                t.getR(urls.getTableData).with({sync:false}) //get all records
+                    .fxDone(function syncComplete(result) {
+                        return;
+                    })
+                t.workChain.utils.wait(1);
+                ResuableSection_verifySync('All records are synced')
+                ResuableSection_addRecord(); //this record is new, will be ONLY record
+                //sent in next update.
+
+                t.addFx(function startBreakpoints() {
+                    //this is not async ... very dangerous
+                    topology.b.data.breakpoint = true;
+                    topology.a.data.breakpoint_catchPageRequests = true;
+                })
+
+
+                t.getR(urls.getTableData).with({sync:false})
+                    .fxDone(function syncComplete(result) {
+                        console.log('>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<')
+                        t.assert(b.lastUpdateSize==1, 'updated wrong # of records updated after pull ' + b.lastUpdateSize)
+
+                        return;
+                    })
+
+
+                t.addFx(function removeBreakpoints() {
+                    topology.b.data.breakpoint = false;
+                    topology.a.data.breakpoint_catchPageRequests = false;
+
+                })
+
+
+                ResuableSection_verifySync()
+            }
+
+            var baseUrlA = 'http://127.0.0.1:'+ a.settings.port;
+            t.settings.baseUrl = baseUrlA;
+            urls.getTableData = t.utils.createTestingUrl('getTableData');
+            urls.verifySync = t.utils.createTestingUrl('verifySync');
+            urls.syncReverse = t.utils.createTestingUrl('syncReverse');
+            urls.verifySyncA = t.utils.createTestingUrl('verifySync');
+
+            function define_syncReverse() {
+                ResuableSection_addRecord();
+
+                t.add(function addNewRecord() {
+                    b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+                });
+                t.add(function addNewRecord() {
+                    b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+                });
+
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'?'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+                ResuableSection_verifySync()
+            };
+
+
+            function define_TestDataIntegrity() {
+
+                t.getR(urls.verifySyncA).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not integral ' + result.ok)
+                        return;
+                    });
+            }
+
+
+
+            /**
+             * Records need to be  marked as 'deleted'
+             * otherwise deletion doesn't count
+             * @param client
+             */
+            function forgetRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function forgetRandomRecord() {
+                    client.test.forgetRandomRecord(t.cb);
+                });
+            }
+
+            function deleteRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function deleteRandomRecord() {
+                    b.test.deleteRandomRecord(t.cb);
+                });
+            }
+
+            function syncIn() {
+
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            function syncOut() {
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            function syncBothDirections() {
+                syncIn()
+                syncOut()
+            }
+            function breakTest() {
+                t.addFx(function() {
+                    asdf.g
+                })
+            }
+            function purgeDeletedRecords() {
+                urls.purgeDeletedRecords = t.utils.createTestingUrl('purgeDeletedRecords');
+                t.getR(urls.purgeDeletedRecords).with({fromPeer:'?'})
+                    .fxDone(function purgeDeletedRecords_Complete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+
+                        return;
+                    })
+            }
+
+
+            /**
+             * Deletes all data from all nodes
+             */
+            function clearAllData() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            // asdf.g
+                            peer.test.destroyAllRecords(true,  recordsDestroyed)
+                            function recordsDestroyed() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            // asdf.g
+                            peer.test.createTestData(  recordsCreated)
+                            function recordsCreated() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+            }
+
+            function inSyncAll() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            var t2 = EasyRemoteTester.create('TestInSync',
+                                {  showBody:false,  silent:true });
+                            var baseUrl = 'http://'+ peer.ip; //127.0.0.1:'+ b.settings.port;
+                            var urls = {};
+                            t2.settings.baseUrl = baseUrl;
+                            urls.verifySync = t.utils.createTestingUrl('verifySync');
+                            t2.getR(urls.verifySync).with(
+                                {sync:false,peer:'a'}
+                            )
+                                .fxDone(function syncComplete(result) {
+                                    t2.assert(result.ok==true, 'data not inSync ' + result.ok);
+                                    return;
+                                });
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+            }
+
+
+
+            function define_TestDataIntegrity2() {
+                forgetRandomRecordFrom();
+                t.workChain.utils.wait(1);
+                forgetRandomRecordFrom();
+                forgetRandomRecordFrom();
+                notInSync();
+                syncBothDirections()
+            }
+
+            function notInSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==false, 'data is not supposed to be in sync ' + result.ok);
+                        return;
+                    });
+            }
+            function inSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                        return;
+                    });
+            }
+        }
+
+        if ( true == false ) { //skip stuff
+
+            t.add(function clearRecordsFrom_B(){
+                b.test.destroyAllRecords(true, t.cb);
+            })
+            ResuableSection_verifySync()
+            t.add(function create100Records_A(){
+                a.test.createTestData(t.cb)
+            })
+
+            t.add(function aPing(){
+                //  b.test.destroyAllRecords(true, t.cb);
+                // b.ping();
+                t.cb();
+            })
+            t.add(function bPing(){
+                //  b.test.destroyAllRecords(true, t.cb);
+                t.cb();
+            })
+
+            t.add(function bPullARecords(){
+
+                b.pull(t.cb);
+            })
+
+
+            ResuableSection_verifySync('A and b should be same size', 100);
+            ResuableSection_addRecord();
+
+            defineHTTPTestMethods();
+            define_TestIncrementalUpdate();
+
+            //if ( testC.speedUp != true )
+            define_TestDataIntegrity();
+
+
+            if ( testC.speedUp != true ) {
+                define_syncReverse();
+            }
+
+
+            if ( testC.speedUp != true ) {
+                define_TestDataIntegrity2();
+            }
+
+        }
+        testC.disableServer = function disableServer(name) {
+            t.add(function disableServer(){
+                var server = topology[name]
+                if ( server == null ) {
+                    throw new Error('what is this? '+name)
+                }
+                server.settings.block = true;
+                t.cb();
+            })
+        };
+
+        testC.enableServer = function enableServer(name) {
+            t.add(function enableServer(){
+                var server = topology[name]
+                if ( server == null ) {
+                    throw new Error('what is this? '+name)
+                }
+                server.settings.block = false;
+                t.cb();
+            })
+        };
+
+
+        testC.syncMachineB = function syncMachine(name) {
+            //sync A to newPeer
+            t.getR(urls.syncReverseB).with({fromPeer:'b'}/*{peer:'a', fromPeer:'newPeerC'}*/)
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+            t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+
+            //verify two peers are synced
+            t.getR(urls.verifySync).with({sync:true,peer:'newPeerC'})
+                .fxDone(function syncComplete(result) {
+                    t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                    return;
+                });
+
+        }
+
+        testC.data = {}
+        testC.data.clearRecords = function clearRecords(nodeName) {
+            t.add(function clearRecordsFrom_NodeNamed(){
+                var node = topology[nodeName]
+                if ( node == null ) {
+                    t.cb();
+                    return;
+                }
+                node.test.destroyAllRecords(true, t.cb);
+            })
+        }
+
+        testC.data.create100Records = function create100Records(nodeName) {
+            t.add(function clear100RecordsOn_NodeNamed(){
+                var node = topology[nodeName]
+                node.test.createTestData(t.cb);
+            })
+        }
+
+        testC.data.addNewRecordToA = function addNewRecordToA(recordData) {
+            t.add(function addNewRecord() {
+                a.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+            });
+        }
+
+        testC.data.addNewRecordToB = function addNewRecordToA(recordData) {
+            t.add(function addNewRecord() {
+                b.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+            });
+        }
+
+
+
+
+
+        testC.peers = {}
+        testC.peers.addPeer = function addPeerNamed(nodeName, configPeer) {
+            t.add(function addNewPeer(){
+                var peer = createNewPeer(nodeName);
+                t.data[nodeName] = peer;
+                t.cb();
+            })
+            urls.addPeer = t.utils.createTestingUrl('addPeer');
+            t.getR(urls.addPeer)
+                //.fxBefore
+                .with({peerIp:'127.0.0.1:12003'
+                    /*topology['newPeerC'].ip*/, //ugh use the before method
+                    peerName:nodeName})
+                .fxDone(function syncComplete(result) {
+                    //debugger;
+                    b.settings.breakpoint = true;
+                    t.assert(result.ok==true, 'couldnot add peer ' + result.ok);
+                    return;
+                });
+            return nodeName;
+        }
+
+
+        testC.sync = {}
+        testC.sync.areTwoNodesInSync = function areTwoNodesInSync(nodeNameA, nodeNameB, size, msg, inverse) {
+            //testUtils.checkSize
+            t.add(function getASize(){
+                var nodeA= topology[nodeNameA]
+                nodeA.getSize(t.cb);
+                t.data.xnodeA = nodeA;
+            })
+            t.add(function getBSize(){
+                var nodeB = topology[nodeNameB]
+                nodeB.getSize(t.cb);
+                t.data.xnodeB = nodeB;
+            })
+            t.add(function testSize(){
+                msg = sh.dv(msg, '');
+                if ( size ) {
+                    t.assert(t.data.xnodeA.size == size, 'sync did not work (sizes different) b' + [t.data.anodeb, size] + msg)
+                    t.assert( t.data.xnodeB.size == size, 'sync did not work (sizes different) x' + [ t.data.anodea.size, size] + msg)
+                }
+                if ( inverse ) {
+                    t.assert(t.data.xnodeA.size != t.data.xnodeB.size,
+                        '(sizes are same)' +
+                            [t.data.xnodeB.size,  t.data.xnodeA.size] + msg)
+                    t.cb();
+                    return;
+                }
+                t.assert(t.data.xnodeA.size == t.data.xnodeB.size,
+                    'sync did not work (sizes different)' +
+                        [t.data.xnodeB.size,  t.data.xnodeA.size] + msg)
+                t.cb();
+            })
+        }
+
+        testC.sync.areTwoNodesNotInSync = function areTwoNodesNotInSync(a,b,size,msg){
+            testC.sync.areTwoNodesInSync(a,b,size, msg, true)
+        }
+
+        function define_TestDelayedAddPeer() {
+
+
+            testC.data.clearRecords('a')
+            testC.data.clearRecords('b')
+
+
+            testC.data.create100Records('b')
+            testC.peers.addPeer('newPeerC')
+            testC.data.clearRecords('newPeerC')
+
+            testC.syncMachineB('b')
+
+            testC.sync.areTwoNodesInSync('b', 'newPeerC' )
+
+
+
+            //block add one and retry
+            testC.data.addNewRecordToB();
+            testC.sync.areTwoNodesNotInSync('b', 'newPeerC' )
+            testC.disableServer('newPeerC')
+            testC.syncMachineB('b')
+            //verify sync failed
+            testC.sync.areTwoNodesNotInSync('b', 'newPeerC' )
+            //re-enable newPeerC
+            testC.enableServer('newPeerC')
+            //try sync again
+            testC.syncMachineB('b')
+            testC.sync.areTwoNodesInSync('b', 'newPeerC' )
+
+
+            //ensure the record if saved while offline is resolved later ...
+            //new peers person record needs to update, adn is resolved when logged in
+            //auot syncing ... 
+        }
+        define_TestDelayedAddPeer()
+
+        ////////
+        if ( testC.stopSlowTests) {
+            return
+        }
+        //////////
+
+
+        function defineBlockSlowTests() {
+            function define_ResiliancyTest() {
+                forgetRandomRecordFrom();
+                forgetRandomRecordFrom(a);
+                forgetRandomRecordFrom(a);
+                forgetRandomRecordFrom();
+                notInSync();
+                //notInSync();
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+            }
+            define_ResiliancyTest();
+
+            function define_ResiliancyTest_IllegallyChangedRecords() {
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                notInSync()
+                //resolve
+                syncBothDirections()
+
+                notInSync()//did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                syncBothDirections()
+                inSync();
+            };
+            define_ResiliancyTest_IllegallyChangedRecords();
+
+            function define_multipleNodes() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration()
+                    t.cb()
+                });
+                clearAllData();
+
+                syncBothDirections()
+                ResuableSection_verifySync()
+                inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecord_skipUpdateTime() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                notInSync()
+                syncBothDirections()
+                notInSync(); //did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                syncBothDirections();
+                inSync();
+            };
+            define_multipleNodes();
+        }
+        defineBlockSlowTests()
+
+
+        function defineSlowTests2() {
+            function define_TestDeletes() {
+                syncBothDirections()
+                ResuableSection_verifySync()
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(topology.c);
+
+                purgeDeletedRecords();
+
+                inSync();
+
+            };
+            define_TestDeletes()
+
+            function define_TestDeletes2() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration2()
+                    t.cb()
+                });
+                clearAllData();
+
+                syncBothDirections()
+                ResuableSection_verifySync()
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(b);
+                deleteRandomRecordFrom(topology.c);
+                deleteRandomRecordFrom(topology.e);
+
+                //syncBothDirections();
+                purgeDeletedRecords();
+                /*t.add(function getRecord() {
+                 b.test.getRandomRecord(function (rec) {
+                 randomRec = rec;
+                 t.cb()
+                 });
+                 });
+                 t.add(function updateRecords() {
+                 randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+                 });*/
+                //  notInSync()
+                // syncBothDirections()
+                inSync();
+
+            };
+            define_TestDeletes2()
+        }
+        defineSlowTests2()
+
+
+
+        function define_TestHubAndSpoke() {
+            asdf.g.dsdf.d
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration()
+                t.cb()
+            });
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration2()
+                t.cb()
+            });
+            clearAllData();
+
+
+            function addTimer(reason) {
+                t.add(function defineNewNodes() {
+                    if (t.timer  != null ) {
+                        var diff = sh.time.secs(t.timer)
+                        console.log('>');console.log('>');console.log('>');
+                        console.log(t.timerReason, 'time', diff);
+                        console.log('>');console.log('>');console.log('>');
+                    } else {
+
+                    }
+                    t.timerReason = reason;
+                    t.timer = new Date();
+                    t.workChain.utils.wait(1);
+                    t.cb()
+                });
+
+            }
+
+            addTimer('sync both dirs')
+            syncBothDirections()
+            addTimer('local sync')
+            ResuableSection_verifySync()
+            addTimer('deletes')
+            deleteRandomRecordFrom(b);
+            deleteRandomRecordFrom(b);
+            deleteRandomRecordFrom(topology.c);
+            deleteRandomRecordFrom(topology.e);
+
+            addTimer('purge all deletes')
+            //syncBothDirections();
+            purgeDeletedRecords();
+            /*t.add(function getRecord() {
+             b.test.getRandomRecord(function (rec) {
+             randomRec = rec;
+             t.cb()
+             });
+             });
+             t.add(function updateRecords() {
+             randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+             });*/
+            //  notInSync()
+            // syncBothDirections()
+            addTimer('insync')
+            inSync();
+            inSyncAll();
+            //TODO: Test sync on N
+            //check in sync on furthes node
+            addTimer('insyncover')
+
+        };
+        define_TestHubAndSpoke()
+
+        // breakTest()
+
+        //TODO: Add index to updated at
+
+        //test from UI
+        //let UI log in
+        //task page saeerch server
+
+        //account server
+        //TODO: To getLastPage for records
+
+        //TODO: replace getRecords, with getLastPage
+        //TODO: do delete, so mark record as deleted, store in cache,
+        //3x sends, until remove record from database ...
+
+        /*
+         when save to delete? after all synced
+         mark as deleted,
+         ask all peers to sync
+         then delete from database if we delete deleted nodes
+
+         do full sync
+         if deleteMissing -- will remove all records my peers do not have
+         ... risky b/c incomplete database might mess  up things
+         ... only delete records thata re marked as deleted
+         */
+
+        /*
+         TODO:
+         test loading config from settings object with proper cluster config
+         test auto syncing after 3 secs
+         build proper hub and spoke network ....
+         add E node that is linked to d (1 hop away)
+         */
+        /**
+         * store global record count
+         * Mark random record as deleted,
+         * sync
+         * remove deleted networks
+         * sync
+         * ensure record is gone
+         */
+
+        //Revisions
+    }
+}
+
+
+
Index: mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_handle.js.bak
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_handle.js.bak	(revision )
+++ mptransfer/DAL/sql_sharing_server/sql_sharing_server_tests_handle.js.bak	(revision )
@@ -0,0 +1,753 @@
+/**
+ * Created by user on 1/13/16.
+ */
+/**
+ * Created by user on 1/3/16.
+ */
+
+var rh = require('rhelpers');
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var express    = require('express');
+var SequelizeHelper = shelpers.SequelizeHelper;
+var EasyRemoteTester = shelpers.EasyRemoteTester;
+
+var SQLSharingServer = require('./sql_sharing_server').SQLSharingServer;
+
+if (module.parent == null) {
+
+    var config = {}
+    config.cluster_config = 'tests/'+'test_cluster_config.json'
+    var server_config = rh.loadRServerConfig(true, config);
+
+    //load confnig frome file
+    //peer has gone down ... peer comes back
+    //real loading
+    //multipe tables
+
+    //define tables to sync and time
+    //create 'atomic' modes for create/update and elete
+
+    var topology = {};
+    var allPeers = [];
+    /**
+     * Create network from config file
+     */
+    function defineTopology() {
+        var cluster_config  = server_config.cluster_config;
+        var dictPeersToIp = {};
+        var dictPeerToLinksToPeers = {};
+        sh.each(server_config.cluster_config.peers, function onPeer(peerName,peer) {
+            //  sh.each(peer, function processPeer(peerName, ip) {
+            dictPeersToIp[peerName] = peer;
+            dictPeerToLinksToPeers[peerName] = [];
+            //  });
+        })
+
+        /*
+         config.cluster_config.peers = [
+         {d:"127.0.0.1:12004"},
+         {e:"127.0.0.1:12005"}
+         ]
+         create an object where the name of the peer, and the ip address
+         do for each way
+         */
+        sh.each(server_config.cluster_config.links, function onPeer(fromPeerName,linksTo) {
+            var fromPeer = dictPeerToLinksToPeers[fromPeerName];
+            //   sh.each(peer, function processPeer(peerName, linksTo) {
+            fromPeer.linkedToPeer = sh.dv( fromPeer.linkedToPeer, {})
+            sh.each(linksTo, function processPeerLinkedTo(i, toPeerName) {
+                var toPeer = dictPeersToIp[toPeerName];
+                var toPeerConfig = {};
+                var exists = fromPeer.linkedToPeer[toPeerName]
+                if ( exists == null ) {
+                    toPeerConfig[toPeerName] = toPeer;
+                    fromPeer.push(toPeerConfig);
+                    fromPeer.linkedToPeer[toPeerName] = toPeerConfig;
+                }
+
+                function linkToPeer_to_fromPeer() {
+                    var dbg= [fromPeerName, toPeerName]
+                    var fromPeerConfig_rev = {};
+                    var fromPeer = dictPeerToLinksToPeers[toPeerName]; //siwtch
+                    fromPeer.linkedToPeer = sh.dv( fromPeer.linkedToPeer, {})
+                    var exists = fromPeer.linkedToPeer[fromPeerName]
+                    var fromPeerIp =  dictPeersToIp[fromPeerName]
+                    if ( exists == null ) {
+                        fromPeerConfig_rev[fromPeerName] = fromPeerIp;
+                        fromPeer.push(fromPeerConfig_rev);
+                        fromPeer.linkedToPeer[fromPeerName] = fromPeerConfig_rev;
+                    }
+                    //link toPeer to fromPeer
+                }
+                linkToPeer_to_fromPeer();
+            });
+            //   });
+        })
+
+
+        sh.each(server_config.cluster_config.peers, function onPeer(peerName,ip) {
+            //var ip = null;
+            if ( ip.indexOf(':') !=-1 ) {
+                var port = ip.split(':')[1];
+                ip = ip.split(':')[0];
+            }
+
+            // sh.each(peer, function processPeer(peerName, ip) {
+            var config = {};
+            config.cluster_config = cluster_config;
+            var peers = dictPeerToLinksToPeers[peerName];
+            var me = {}
+            me[peerName] = ip;
+            peers.push(me)
+            config.cluster_config.peers = peers;
+
+            config.port = port;
+            config.peerName = peerName;
+            config.tableName = peerName+'Table';
+            // config.fxDone = testInstances
+            var service = new SQLSharingServer();
+            service.init(config);
+            var a = service;
+            allPeers.push(service);
+            topology[peerName] = a;
+            //     });
+        })
+
+
+        return;
+    }
+    defineTopology();
+
+    //testInstances();
+
+    setTimeout(testInstances, 500);
+
+
+/*
+    var config = sh.clone(config);
+    config.port = 12002;
+    config.peerName = 'b';
+    config.tableName = 'bA';
+    var service = new SQLSharingServer();
+    service.init(config);
+    var b = service;
+    allPeers.push(service)
+*/
+    function __augmentNetworkConfiguration() {
+        if ( topology.augmentNetworkConfiguration) {
+            return;
+        }
+        topology.augmentNetworkConfiguration = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {c:"127.0.0.1:12003"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12003;
+        config.peerName = 'c';
+        config.tableName = 'cA';
+
+        var service = new SQLSharingServer();
+        service.init(config);
+        var c = service;
+        allPeers.push(service)
+        topology.c = c;
+        //c.linkTo({b:b});
+        b.linkTo({c:c})
+
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {b:"127.0.0.1:12002"}
+        ]
+        config.port = 12004;
+        config.peerName = 'd';
+        config.tableName = 'dA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var d = service;
+        allPeers.push(service)
+        topology.d = d;
+        //d.linkTo({c:c});
+        b.linkTo({d:d})
+
+
+    }
+    function __augmentNetworkConfiguration2() {
+        if ( topology.augmentNetworkConfiguration2) {
+            return;
+        }
+        topology.augmentNetworkConfiguration2 = true;
+        config = sh.clone(config);
+        config.cluster_config.peers = [
+            {d:"127.0.0.1:12004"},
+            {e:"127.0.0.1:12005"}
+        ]
+        config.port = 12005;
+        config.peerName = 'e';
+        config.tableName = 'eA';
+        var service = new SQLSharingServer();
+        service.init(config);
+        var e = service;
+        allPeers.push(service)
+        topology.d.linkTo({e:e})
+    }
+
+
+    function testInstances() {
+        //make chain
+        var sh = require('shelpers').shelpers;
+        var shelpers = require('shelpers');
+        var EasyRemoteTester = shelpers.EasyRemoteTester;
+        var t = EasyRemoteTester.create('Test Channel Server basics',
+            {
+                showBody:false,
+                silent:true
+            });
+
+
+
+        var b = topology.b;
+        var baseUrl = 'http://127.0.0.1:'+ b.settings.port;
+        var urls = {};
+
+        var helper = {};
+
+        function defineHelperMethod() {
+            /**
+             * Deletes all data from all nodes
+             */
+            helper.clearAllData = function clearAllData() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function (peer, fxDone) {
+                            // asdf.g
+                            peer.test.destroyAllRecords(true, recordsDestroyed)
+                            function recordsDestroyed() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        });
+                });
+                t.add(function () {
+                    sh.async(allPeers,
+                        function (peer, fxDone) {
+                            // asdf.g
+                            peer.test.createTestData(recordsCreated)
+                            function recordsCreated() {
+                                fxDone();
+                            }
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        });
+                });
+            }
+
+            helper.clearDataFromNode = function clearDataFromNode(service) {
+                service = sh.dv(service, topology.a)
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    service.test.destroyAllRecords(true, t.cb);
+                });
+
+            }
+
+            helper.pingNode = function clearDataFromNode(service) {
+                service = sh.dv(service, topology.a)
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    service.test.destroyAllRecords(true, t.cb);
+                });
+            }
+
+            helper.pingNode = function clearDataFromNode(service) {
+                service = sh.dv(service, topology.a)
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    service.test.destroyAllRecords(true, t.cb);
+                });
+            }
+
+
+            helper.verifyLocally = function verifyLocally(service) {
+                service = sh.dv(service, topology.a)
+                t.add(function getASize() {
+                    service.getSize(t.cb);
+                })
+                t.add(function getBSize() {
+                    b.getSize(t.cb);
+                })
+                t.add(function testSize() {
+                    t.assert(b.size == service.size, 'sync did ntow ork' + [b.size, service.size])
+                    t.cb();
+                })
+            }
+
+
+            helper.addRecord = function addRecord(service) {
+                service = sh.dv(service, topology.a)
+                t.add(function addNewRecord() {
+                    service.dbHelper2.addNewRecord({name: "test new"}, t.cb);
+                });
+            }
+
+
+            helper.verifySync = function verifySync () {
+                urls.verifySync = t.utils.createTestingUrl('verifySync');
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not integral ' + result.ok)
+                        return;
+                    });
+            }
+
+            /**
+             * Records need to be  marked as 'deleted'
+             * otherwise deletion doesn't count
+             * @param client
+             */
+            helper.forgetRandomRecordFrom =  function forgetRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function forgetRandomRecord() {
+                    client.test.forgetRandomRecord(t.cb);
+                });
+            }
+
+            helper.deleteRandomRecordFrom =  function deleteRandomRecordFrom(client) {
+                if ( client == null ) { client = b }
+                t.add(function deleteRandomRecord() {
+                    b.test.deleteRandomRecord(t.cb);
+                });
+            }
+
+            helper.syncIn = function syncIn() {
+                t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            helper.syncOut = function syncOut() {
+                t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+                        return;
+                    })
+            }
+            helper.syncBothDirections = function syncBothDirections() {
+                helper.syncIn()
+                helper.syncOut()
+            }
+
+            helper.notInSync = function notInSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==false, 'data is not supposed to be in sync ' + result.ok);
+                        return;
+                    });
+            }
+            helper.inSync = function inSync() {
+                t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                    .fxDone(function syncComplete(result) {
+                        t.assert(result.ok==true, 'data not inSync ' + result.ok);
+                        return;
+                    });
+            }
+
+            helper.purgeDeletedRecords = function purgeDeletedRecords() {
+                urls.purgeDeletedRecords = t.utils.createTestingUrl('purgeDeletedRecords');
+                t.getR(urls.purgeDeletedRecords).with({fromPeer:'?'})
+                    .fxDone(function purgeDeletedRecords_Complete(result) {
+                        //t.assert(result.ok==1, 'data not integral ' + result)
+
+                        return;
+                    })
+            }
+
+
+            helper.inSyncAll = function inSyncAll() {
+                t.workChain.utils.wait(1);
+                t.add(function () {
+                    sh.async(allPeers,
+                        function(peer, fxDone) {
+                            var t2 = EasyRemoteTester.create('TestInSync',
+                                {  showBody:false,  silent:true });
+                            var baseUrl = 'http://'+ peer.ip; //127.0.0.1:'+ b.settings.port;
+                            var urls = {};
+                            t2.settings.baseUrl = baseUrl;
+                            urls.verifySync = t.utils.createTestingUrl('verifySync');
+                            t2.getR(urls.verifySync).with(
+                                {sync:false,peer:'a'}
+                            )
+                                .fxDone(function syncComplete(result) {
+                                    t2.assert(result.ok==true, 'data not inSync ' + result.ok);
+                                    return;
+                                });
+                        },
+                        function dleeteAll() {
+                            t.cb()
+                        } );
+                });
+            }
+
+
+
+
+
+
+            helper.addTimer = function addTimer(reason) {
+                t.add(function defineNewNodes() {
+                    if (t.timer  != null ) {
+                        var diff = sh.time.secs(t.timer)
+                        console.log('>');console.log('>');console.log('>');
+                        console.log(t.timerReason, 'time', diff);
+                        console.log('>');console.log('>');console.log('>');
+                    } else {
+
+                    }
+                    t.timerReason = reason;
+                    t.timer = new Date();
+                    t.workChain.utils.wait(1);
+                    t.cb()
+                });
+            }
+
+
+        }
+        defineHelperMethod();
+
+        //t.add(clearAllData())
+        helper.clearAllData()
+
+        t.add(function bPullARecords(){
+            b.pull(t.cb);
+        })
+
+        helper.addRecord()
+
+
+        //do partial sync
+        //sync from http request methods
+        //batched sync
+        //remove batch tester
+        //cluster config if no config sent
+
+        function defineHTTPTestMethods() {
+            //var t = EasyRemoteTester.create('Test Channel Server basics',{showBody:false});
+            t.settings.baseUrl = baseUrl;
+            urls.getTableData = t.utils.createTestingUrl('getTableData');
+            urls.syncIn = t.utils.createTestingUrl('syncIn');
+
+            helper.addRecord();
+
+            t.getR(urls.getTableData).with({sync:false})
+                // .bodyHas('status').notEmpty()
+                .fxDone(function syncComplete(result) {
+                    return;
+                });
+
+            helper.verifySync();
+        }
+        defineHTTPTestMethods();
+
+
+        function define_TestIncrementalUpdate () {
+            urls.getTableData = t.utils.createTestingUrl('getTableDataIncremental');
+
+            t.getR(urls.getTableData).with({sync:false}) //get all records
+                .fxDone(function syncComplete(result) {
+                    return;
+                })
+            t.workChain.utils.wait(1);
+            //ResuableSection_verifySync()
+            helper.addRecord();
+
+            t.getR(urls.getTableData).with({sync:false})
+                .fxDone(function syncComplete(result) {
+                    console.log('>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<')
+                    t.assert(b.lastUpdateSize==1, 'updated wrong # of records ' + b.lastUpdateSize)
+                    return;
+                })
+
+            helper.verifySync();
+        }
+        define_TestIncrementalUpdate();
+
+
+
+        function define_TestDataIntegrity() {
+            urls.verifySync = t.utils.createTestingUrl('verifySync');
+            t.getR(urls.verifySync).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    t.assert(result.ok==true, 'data not integral ' + result.ok)
+                    return;
+                });
+        }
+        define_TestDataIntegrity();
+
+
+        function define_syncReverse() {
+            helper.addRecord();
+
+            t.add(function addNewRecord() {
+                b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+            });
+            t.add(function addNewRecord() {
+                b.dbHelper2.addNewRecord({name: "test newB"}, t.cb);
+            });
+
+            urls.syncReverse = t.utils.createTestingUrl('syncReverse');
+
+
+            t.getR(urls.syncReverse).with({sync:false,peer:'a', fromPeer:'?'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+            t.getR(urls.syncIn).with({sync:false,peer:'a'})
+                .fxDone(function syncComplete(result) {
+                    //t.assert(result.ok==1, 'data not integral ' + result)
+                    return;
+                })
+            helper.verifySync()
+        };
+        define_syncReverse();
+        ;
+
+
+
+
+        function define_TestDataIntegrity2() {
+            helper.forgetRandomRecordFrom();
+            t.workChain.utils.wait(1);
+            helper.forgetRandomRecordFrom();
+            helper.forgetRandomRecordFrom();
+            helper.notInSync();
+            helper.syncBothDirections()
+        }
+        define_TestDataIntegrity2();
+
+        function defineBlockSlowTests() {
+            function define_ResiliancyTest() {
+                helper.forgetRandomRecordFrom();
+
+                helper.forgetRandomRecordFrom(topology.a);
+                helper.forgetRandomRecordFrom(topology.a);
+                helper.forgetRandomRecordFrom();
+                helper.notInSync();
+                //notInSync();
+                helper.syncBothDirections()
+                helper.verifySync()
+                helper.inSync();
+
+            }
+
+            define_ResiliancyTest();
+
+            function define_ResiliancyTest_IllegallyChangedRecords() {
+                helper.syncBothDirections();
+                helper.verifySync();
+                helper.inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                helper.notInSync();
+                //resolve
+                helper.syncBothDirections();
+
+                helper.notInSync()//did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                helper.syncBothDirections();
+                helper.inSync();
+            };
+            define_ResiliancyTest_IllegallyChangedRecords();
+
+            function define_multipleNodes() {
+                /*t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration()
+                    t.cb()
+                });*/
+                helper.clearAllData();
+
+                helper.syncBothDirections()
+                helper.verifySync()
+                helper.inSync();
+                t.add(function getRecord() {
+                    b.test.getRandomRecord(function (rec) {
+                        randomRec = rec;
+                        t.cb()
+                    });
+                });
+                t.add(function updateRecord_skipUpdateTime() {
+                    randomRec.updateAttributes({name: "JJJJ"}).then(t.cb)
+                });
+                helper.notInSync()
+                helper.syncBothDirections()
+                helper.notInSync(); //did not upldate global date
+                t.add(function updateRecords() {
+                    randomRec.updateAttributes({global_updated_at: new Date()}).then(t.cb)
+                });
+                helper.syncBothDirections();
+                helper.inSync();
+            };
+            define_multipleNodes();
+        }
+        defineBlockSlowTests()
+
+        function defineSlowTests2() {
+            function define_TestDeletes() {
+                helper.syncBothDirections()
+                helper.verifySync()
+                helper.deleteRandomRecordFrom(b);
+                helper.deleteRandomRecordFrom(b);
+                helper.deleteRandomRecordFrom(topology.c);
+
+                helper.purgeDeletedRecords();
+
+                helper.inSync();
+
+            };
+            define_TestDeletes()
+
+            function define_TestDeletes2() {
+                t.add(function defineNewNodes() {
+                    augmentNetworkConfiguration2()
+                    t.cb()
+                });
+                helper.clearAllData();
+
+                helper.syncBothDirections()
+                helper.verifySync()
+                helper.deleteRandomRecordFrom(b);
+                helper.deleteRandomRecordFrom(b);
+                helper.deleteRandomRecordFrom(topology.c);
+                helper.deleteRandomRecordFrom(topology.e);
+
+                //syncBothDirections();
+                helper.purgeDeletedRecords();
+                /*t.add(function getRecord() {
+                 b.test.getRandomRecord(function (rec) {
+                 randomRec = rec;
+                 t.cb()
+                 });
+                 });
+                 t.add(function updateRecords() {
+                 randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+                 });*/
+                //  notInSync()
+                // syncBothDirections()
+                helper.inSync();
+
+            };
+            define_TestDeletes2()
+        }
+        defineSlowTests2()
+
+
+
+        function define_TestHubAndSpoke() {
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration()
+                t.cb()
+            });
+            t.add(function defineNewNodes() {
+                augmentNetworkConfiguration2()
+                t.cb()
+            });
+            helper.clearAllData();
+
+            helper.addTimer('sync both dirs')
+            helper.syncBothDirections()
+            helper.addTimer('local sync')
+            helper.verifySync()
+            helper.addTimer('deletes')
+            helper.deleteRandomRecordFrom(b);
+            helper.deleteRandomRecordFrom(b);
+            helper.deleteRandomRecordFrom(topology.c);
+            helper.deleteRandomRecordFrom(topology.e);
+
+            helper.addTimer('purge all deletes')
+            //syncBothDirections();
+            helper.purgeDeletedRecords();
+            /*t.add(function getRecord() {
+             b.test.getRandomRecord(function (rec) {
+             randomRec = rec;
+             t.cb()
+             });
+             });
+             t.add(function updateRecords() {
+             randomRec.updateAttributes({name:"JJJJ"}).then( t.cb  )
+             });*/
+            //  notInSync()
+            // syncBothDirections()
+            helper.addTimer('insync')
+            helper.inSync();
+            helper.inSyncAll();
+            //TODO: Test sync on N
+            //check in sync on furthes node
+            helper.addTimer('insyncover')
+
+        };
+        define_TestHubAndSpoke()
+
+
+        //TODO: Add index to updated at
+
+        //test from UI
+        //let UI log in
+        //task page saeerch server
+
+        //account server
+        //TODO: To getLastPage for records
+
+        //TODO: replace getRecords, with getLastPage
+        //TODO: do delete, so mark record as deleted, store in cache,
+        //3x sends, until remove record from database ...
+
+        /*
+         when save to delete? after all synced
+         mark as deleted,
+         ask all peers to sync
+         then delete from database if we delete deleted nodes
+
+         do full sync
+         if deleteMissing -- will remove all records my peers do not have
+         ... risky b/c incomplete database might mess  up things
+         ... only delete records thata re marked as deleted
+         */
+
+        /*
+         TODO:
+         test loading config from settings object with proper cluster config
+         test auto syncing after 3 secs
+         build proper hub and spoke network ....
+         add E node that is linked to d (1 hop away)
+         */
+        /**
+         * store global record count
+         * Mark random record as deleted,
+         * sync
+         * remove deleted networks
+         * sync
+         * ensure record is gone
+         */
+
+        //Revisions
+    }
+}
+
+
+
Index: mptransfer/DAL/sql_sharing_server/tests/test_cluster_config.json
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/tests/test_cluster_config.json	(revision )
+++ mptransfer/DAL/sql_sharing_server/tests/test_cluster_config.json	(revision )
@@ -0,0 +1,19 @@
+{
+  "peers":{
+    "a":"127.0.0.1:9991",
+    "b":":9992",
+    "c":"127.0.0.1:9993",
+    "d":"127.0.0.1:9994",
+    "e":"127.0.0.1:9995"
+  },
+  "links": {
+    "a":["b", "c"],
+    "b":[],
+    "d":["c"],
+    "e":["d"]
+  },
+  "name" : "test splurge",
+  "tables" : ["user", "file"],
+  "syncTime" : 60
+
+}
Index: mptransfer/DAL/utils/server_config_override_file.json
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/utils/server_config_override_file.json	(revision )
+++ mptransfer/DAL/utils/server_config_override_file.json	(revision )
@@ -0,0 +1,5 @@
+{
+  "mysql":{
+    "ip" : "5.79.75.96"
+  }
+}
Index: mptransfer/DAL/sql_sharing_server/readme.txt
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/sql_sharing_server/readme.txt	(revision )
+++ mptransfer/DAL/sql_sharing_server/readme.txt	(revision )
@@ -0,0 +1,347 @@
+Why: Enables multiple servers ina  cluster to share configuration
+
+
+
+/usr/sbin/node /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server_tests_bulk_config.js
+10.211.55.4 ip address
+10.211.55.4 ip address
+>>>*>  SQLSharingServer init  started server on 9991 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:37:14)
+>>>*>  SQLSharingServer identify  ip address 127.0.0.1:9991 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:999:14)
+....
+....
+undefined 'self peers' [ { b: ':9992' },
+  { c: '127.0.0.1:9993' },
+  { a: '127.0.0.1' },
+  linkedToPeer: { b: { b: ':9992' }, c: { c: '127.0.0.1:9993' } } ]
+>>>*>  SQLSharingServer identify a a foundPeerEntryForSelf true 2 :9992,127.0.0.1:9993 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1034:14)
+DEPRECATION WARNING: The logging-option should be either a function or false. Default: console.log
+10.211.55.4 ip address
+>>>*>  SQLSharingServer init  started server on 9992 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:37:14)
+>>>*>  SQLSharingServer identify  ip address 127.0.0.1:9992 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:999:14)
+undefined 'self peers' [ { a: '127.0.0.1:9991' },
+  { b: '' },
+  linkedToPeer: { a: { a: '127.0.0.1:9991' } } ]
+>>>*>  SQLSharingServer identify b b foundPeerEntryForSelf true 1 127.0.0.1:9991 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1034:14)
+DEPRECATION WARNING: The logging-option should be either a function or false. Default: console.log
+....
+10.211.55.4 ip address
+....
+....
+>>>*>  SQLSharingServer init  started server on 9993 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:37:14)
+>>>*>  SQLSharingServer identify  ip address 127.0.0.1:9993 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:999:14)
+undefined 'self peers' [ { a: '127.0.0.1:9991' },
+  { d: '127.0.0.1:9994' },
+  { c: '127.0.0.1' },
+  linkedToPeer: { a: { a: '127.0.0.1:9991' }, d: { d: '127.0.0.1:9994' } } ]
+>>>*>  SQLSharingServer identify c c foundPeerEntryForSelf true 2 127.0.0.1:9991,127.0.0.1:9994 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1034:14)
+DEPRECATION WARNING: The logging-option should be either a function or false. Default: console.log
+10.211.55.4 ip address
+>>>*>  SQLSharingServer init  started server on 9994 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:37:14)
+>>>*>  SQLSharingServer identify  ip address 127.0.0.1:9994 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:999:14)
+undefined 'self peers' [ { c: '127.0.0.1:9993' },
+  { e: '127.0.0.1:9995' },
+  { d: '127.0.0.1' },
+  linkedToPeer: { c: { c: '127.0.0.1:9993' }, e: { e: '127.0.0.1:9995' } } ]
+>>>*>  SQLSharingServer identify d d foundPeerEntryForSelf true 2 127.0.0.1:9993,127.0.0.1:9995 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1034:14)
+DEPRECATION WARNING: The logging-option should be either a function or false. Default: console.log
+....
+....
+10.211.55.4 ip address
+>>>*>  SQLSharingServer init  started server on 9995 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:37:14)
+>>>*>  SQLSharingServer identify  ip address 127.0.0.1:9995 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:999:14)
+undefined 'self peers' [ { d: '127.0.0.1:9994' },
+  { e: '127.0.0.1' },
+  linkedToPeer: { d: { d: '127.0.0.1:9994' } } ]
+....
+>>>*>  SQLSharingServer identify e e foundPeerEntryForSelf true 1 127.0.0.1:9994 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1034:14)
+DEPRECATION WARNING: The logging-option should be either a function or false. Default: console.log
+10.211.55.4
+ ip address free space
+10.211.55.4
+ ip address free space
+10.211.55.4
+ ip address free space
+10.211.55.4
+ ip address free space
+10.211.55.4
+ ip address free space
+10.211.55.4
+ ip address free space
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invite_Campaigns` (`id` INTEGER(11) NOT NULL , `name` VARCHAR(255), `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): SHOW INDEX FROM `Invite_Campaigns`
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `Invites` (`id` INTEGER(11) NOT NULL , `invite_code` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `forumname` VARCHAR(255), `joindate` DATETIME, `trialExpire` DATETIME, `creatorip` VARCHAR(255), `creator` VARCHAR(255), `datecreated` DATETIME NOT NULL, `dateupdated` DATETIME NOT NULL, `InviteCampaignId` INTEGER(11), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`), FOREIGN KEY (`InviteCampaignId`) REFERENCES `Invite_Campaigns` (`id`) ON DELETE SET NULL ON UPDATE CASCADE) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): SHOW INDEX FROM `Invites`
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `users` (`id` INTEGER NOT NULL auto_increment , `username` VARCHAR(255) NOT NULL, `password` VARCHAR(255), `level` ENUM('FREE USER', 'INVITED', 'NEOPHITE', 'PAID USER', 'ADMIN'), `email` VARCHAR(255), `lastlogindate` DATETIME, `lastloginip` VARCHAR(255), `status` ENUM('ACTIVE', 'PENDING', 'DISABLED', 'SUSPENDED') NOT NULL DEFAULT 'active', `title` VARCHAR(255), `firstname` VARCHAR(255) DEFAULT '', `lastname` VARCHAR(255) DEFAULT '', `createdip` VARCHAR(255), `lastPayment` DATETIME DEFAULT NULL, `paidExpiryDate` DATETIME DEFAULT NULL, `paymentTracker` VARCHAR(255) DEFAULT '', `passwordResetHash` VARCHAR(255) DEFAULT '', `identifier` VARCHAR(255) DEFAULT '', `apikey` VARCHAR(255) DEFAULT '', PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): SHOW INDEX FROM `users`
+Executing (default): CREATE TABLE IF NOT EXISTS `aTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `aTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `bTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `bTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `cTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `cTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `dTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `eTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): CREATE TABLE IF NOT EXISTS `eTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `aTables`
+Executing (default): SHOW INDEX FROM `aTables`
+Executing (default): SHOW INDEX FROM `bTables`
+Executing (default): SHOW INDEX FROM `bTables`
+Executing (default): SHOW INDEX FROM `cTables`
+Executing (default): SHOW INDEX FROM `cTables`
+Executing (default): SHOW INDEX FROM `dTables`
+Executing (default): SHOW INDEX FROM `eTables`
+Executing (default): SHOW INDEX FROM `eTables`
+Executing (default): CREATE TABLE IF NOT EXISTS `dTables` (`id` INTEGER(10) NOT NULL auto_increment , `name` VARCHAR(255), `desc` VARCHAR(255), `user_id` VARCHAR(255), `imdb_id` VARCHAR(255), `content_id` VARCHAR(255), `progress` VARCHAR(255), `source_node` VARCHAR(255), `id_timestamp` VARCHAR(255), `updated_by_source` VARCHAR(255), `global_updated_at` DATETIME NOT NULL, `version` VARCHAR(255), `deleted` TINYINT(1), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB COLLATE utf8_general_ci;
+Executing (default): SHOW INDEX FROM `dTables`
+Connection has been established successfully.
+table ready
+Connection has been established successfully.
+table ready
+Connection has been established successfully.
+table ready
+Connection has been established successfully.
+table ready
+Connection has been established successfully.
+table ready
+blocking is  true for c
+Executing (default): DELETE FROM `aTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 a all records destroyed (undefined
+Executing (default): DELETE FROM `bTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 b all records destroyed (undefined
+Executing (default): DELETE FROM `cTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 c all records destroyed (undefined
+Executing (default): DELETE FROM `dTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 d all records destroyed (undefined
+Executing (default): DELETE FROM `eTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 e all records destroyed (undefined
+>>>*>  syncPeer  b syninc peer 127.0.0.1:9991 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:649:26)
+>>>*>  Object getCount [as handle] a who is request from b (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `aTables` AS `aTable`;
+Issue with:http://127.0.0.1:9991/count
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` ORDER BY `global_updated_at`, `DESC` LIMIT 1000;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/getNextPage?a=b__a&of=0 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+>>>*>  allDone  b all records synced (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:654:26)
+Executing (default): INSERT INTO `aTables` (`id`,`name`,`source_node`,`id_timestamp`,`global_updated_at`,`createdAt`,`updatedAt`) VALUES (NULL,'test new','a','Sun Jan 24 2016 21:52:59 GMT-0500 (EST)_0.633336768951267_0.002477402100339532','2016-01-25 02:52:59','2016-01-25 02:52:59','2016-01-25 02:52:59');
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1335:26 a all records created 1 (undefined
+Executing (default): DELETE FROM `aTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 a all records destroyed (undefined
+Executing (default): DELETE FROM `bTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 b all records destroyed (undefined
+Executing (default): DELETE FROM `cTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 c all records destroyed (undefined
+Executing (default): DELETE FROM `dTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 d all records destroyed (undefined
+Executing (default): DELETE FROM `eTables`
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1574:26 e all records destroyed (undefined
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+Issue with:http://127.0.0.1:9992/count
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/count
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/count
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+Issue with:http://127.0.0.1:9992/count
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+Issue with:http://127.0.0.1:9992/count
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+---------->counts counts on start { a: { count: 0 },
+  b: { count: 0 },
+  c: { count: 0 },
+  d: { count: 0 },
+  e: { count: 0 } }
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  verifySyncPeer  b verifying peer 127.0.0.1:9991 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:846:26)
+>>>*>  Object getCount [as handle] a who is request from b (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `aTables` AS `aTable`;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9991/count
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` ORDER BY `global_updated_at`, `DESC` LIMIT 1000;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/getNextPage?a=b__a&of=0 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  verifySync  b verifying b 0 127.0.0.1:9991 0 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:973:22)
+true
+>>>*>  allDone  b all records verified (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:855:26)
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/verifySync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/verifySync
+>>>*>  Object atomicAction [as handle] c c block (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:362:22)
+{ [Error: ETIMEDOUT] code: 'ETIMEDOUT' }
+response is null
+Issue with:http://127.0.0.1:9991/atomicAction?0=a&type=update
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/atomicAction?0=a&type=update (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Commit atomic on peers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+{ [Error: ESOCKETTIMEDOUT] code: 'ESOCKETTIMEDOUT' }
+response is null
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `bTables` AS `bTable` WHERE (`bTable`.`id_timestamp` = 'Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568' AND `bTable`.`source_node` = 'b');
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9993/atomicAction?0=c&type=update (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9993/atomicAction?0=c&type=update
+>>>*>  null <anonymous> b found existing records (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1231:30)
+Executing (default): INSERT INTO `bTables` (`id`,`name`,`source_node`,`id_timestamp`,`global_updated_at`,`createdAt`,`updatedAt`) VALUES (NULL,'yyy2','b','Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568','2016-01-25 02:52:58','2016-01-25 02:53:05','2016-01-25 02:53:05');
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1292:34 b all records created 1 (undefined
+>>>*>  upserted  b return b (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:483:30)
+done2 update b
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/atomicAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Purge records on peers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` WHERE (`aTable`.`id_timestamp` = 'Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568' AND `aTable`.`source_node` = 'b');
+Issue with:http://127.0.0.1:9992/atomicAction
+>>>*>  null <anonymous> a found existing records (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1231:30)
+Executing (default): INSERT INTO `aTables` (`id`,`name`,`source_node`,`id_timestamp`,`global_updated_at`,`createdAt`,`updatedAt`) VALUES (NULL,'yyy2','b','Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568','2016-01-25 02:52:58','2016-01-25 02:53:05','2016-01-25 02:53:05');
+done2 update a
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1292:34 a all records created 1 (undefined
+>>>*>  upserted  a return a (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:483:30)
+>>>*>  Object atomicAction [as handle] c c block (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:362:22)
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/atomicAction?0=a&type=update (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+{ [Error: ETIMEDOUT] code: 'ETIMEDOUT' }
+response is null
+Issue with:http://127.0.0.1:9991/atomicAction?0=a&type=update
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Commit atomic on peers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `bTables` AS `bTable` WHERE (`bTable`.`id_timestamp` = 'Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.006601016037166119_0.513677337905392' AND `bTable`.`source_node` = 'b');
+{ [Error: ESOCKETTIMEDOUT] code: 'ESOCKETTIMEDOUT' }
+response is null
+Issue with:http://127.0.0.1:9993/atomicAction?0=c&type=update
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9993/atomicAction?0=c&type=update (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  null <anonymous> b found existing records (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1231:30)
+Executing (default): INSERT INTO `bTables` (`id`,`name`,`source_node`,`id_timestamp`,`global_updated_at`,`createdAt`,`updatedAt`) VALUES (NULL,'yyy2','b','Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.006601016037166119_0.513677337905392','2016-01-25 02:52:58','2016-01-25 02:53:08','2016-01-25 02:53:08');
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1292:34 b all records created 1 (undefined
+>>>*>  upserted  b return b (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:483:30)
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/atomicAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+done2 update b
+Issue with:http://127.0.0.1:9992/atomicAction
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Purge records on peers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` WHERE (`aTable`.`id_timestamp` = 'Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.006601016037166119_0.513677337905392' AND `aTable`.`source_node` = 'b');
+>>>*>  null <anonymous> a found existing records (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:1231:30)
+Executing (default): INSERT INTO `aTables` (`id`,`name`,`source_node`,`id_timestamp`,`global_updated_at`,`createdAt`,`updatedAt`) VALUES (NULL,'yyy2','b','Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.006601016037166119_0.513677337905392','2016-01-25 02:52:58','2016-01-25 02:53:08','2016-01-25 02:53:08');
+done2 update a
+>>>*>  /media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server js:1292:34 a all records created 1 (undefined
+>>>*>  upserted  a return a (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:483:30)
+>>>*>  Object atomicAction [as handle] c c block (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:362:22)
+{ [Error: ETIMEDOUT] code: 'ETIMEDOUT' }
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/atomicAction?0=a&type=delete (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+response is null
+Issue with:http://127.0.0.1:9991/atomicAction?0=a&type=delete
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Commit atomic on peers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `bTables` AS `bTable` WHERE `bTable`.`id_timestamp` IN ('Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568');
+{ [Error: ESOCKETTIMEDOUT] code: 'ESOCKETTIMEDOUT' }
+response is null
+Executing (default): DELETE FROM `bTables` WHERE `id_timestamp` IN ('Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568')
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9993/atomicAction?0=c&type=delete (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9993/atomicAction?0=c&type=delete
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/atomicAction (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/atomicAction
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Purge records on peers (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` WHERE `aTable`.`id_timestamp` IN ('Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568');
+Executing (default): DELETE FROM `aTables` WHERE `id_timestamp` IN ('Sun Jan 24 2016 21:52:58 GMT-0500 (EST)_0.15028579835779965_0.2215316544752568')
+Executing (default): SELECT count(*) AS `count` FROM `aTables` AS `aTable`;
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+Issue with:http://127.0.0.1:9992/count
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Issue with:http://127.0.0.1:9992/count
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/count
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/count
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  Object getCount [as handle] b who is request from  (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `bTables` AS `bTable`;
+Issue with:http://127.0.0.1:9992/count
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+---------->counts undefined { a: { count: 1 },
+  b: { count: 1 },
+  c: { count: 1 },
+  d: { count: 1 },
+  e: { count: 1 } }
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete TestInSync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
+>>>*>  verifySyncPeer  b verifying peer 127.0.0.1:9991 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:846:26)
+>>>*>  Object getCount [as handle] a who is request from b (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:550:18)
+Executing (default): SELECT count(*) AS `count` FROM `aTables` AS `aTable`;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/count (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9991/count
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` ORDER BY `global_updated_at`, `DESC` LIMIT 1000;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/getNextPage?a=b__a&of=0 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `aTables` AS `aTable` ORDER BY `global_updated_at`, `DESC` LIMIT 1, 1000;
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9991/getNextPage?a=b__a&of=1 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Executing (default): SELECT `id`, `name`, `desc`, `user_id`, `imdb_id`, `content_id`, `progress`, `source_node`, `id_timestamp`, `updated_by_source`, `global_updated_at`, `version`, `deleted`, `createdAt`, `updatedAt` FROM `bTables` AS `bTable` WHERE `bTable`.`global_updated_at` >= '2016-01-25 02:52:58' AND (`bTable`.`global_updated_at` <= '2016-01-25 02:52:58') ORDER BY `global_updated_at`, `DESC`;
+>>>*>  verifySync  b verifying b 1 127.0.0.1:9991 1 (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:973:22)
+true
+>>>*>  allDone  b all records verified (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/sql_sharing_server/sql_sharing_server.js:855:26)
+>>>*>  Object onQuickRequestResponse [as fx2] http://127.0.0.1:9992/verifySync (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/EasyRemoteTester.js:90:26)
+Issue with:http://127.0.0.1:9992/verifySync
+>>>*>  self startNextMethod [as _onTimeout] ***Chain Complete Test Channel Server basics (/media/psf/Dropbox/projects/ritv2/videoproject/Code/node_scripts/node_modules/shelpers/lib/PromiseHelperV3.js:57:30)
Index: mptransfer/DAL/utils/benchmarks/thoucalls.js
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
--- mptransfer/DAL/utils/benchmarks/thoucalls.js	(revision )
+++ mptransfer/DAL/utils/benchmarks/thoucalls.js	(revision )
@@ -0,0 +1,106 @@
+/**
+ * Created by user2 on 4/11/16.
+ */
+var sh = require('shelpers').shelpers;
+var shelpers = require('shelpers');
+var rh = require('rhelpers');
+
+function BasicClass() {
+    var p = BasicClass.prototype;
+    p = this;
+    var self = this;
+    p.init = function init(url, appCode) {
+        self.startTime = new Date();
+
+        var ex = []
+        for (var i = 0; i < 1000; i++) {
+            ex.push(i)
+        }
+
+        sh.async(ex, function doIt(i, fx) {
+            //console.log(i)
+            fx()
+
+        }, function ended() {
+
+            self.proc('how long', sh.time.secs(self.startTime));
+             self.testOver();
+        })
+
+
+       // self.proc('how long', sh.time.secs(self.startTime));
+    }
+    p.testOver = function testOver() {
+        var testOverrides = {
+            "mysql":{
+                "ip" : "127.0.0.1",
+                //"databasename" : "yetidb",
+                "user" : "yetidbuser",
+                "pass" : "aSDDD545y^",
+                // "port" : "3306"
+            },
+            "global":{
+              //  "environment":"productionx"
+            },
+        }
+        rh.addConfigOverride(testOverrides);
+
+        var	sequelize = rh.getSequelize();
+        self.sequelize = sequelize;
+
+
+        self.startTime = new Date();
+
+        var ex = []
+        for ( var i = 0;  i < 1000; i++ ) {
+            ex.push(i)
+        }
+
+
+        sh.async(ex, function doIt(i, fx){
+
+            var query = {
+                where: {
+                  //  username: Math.random(),
+                }
+            }
+
+            self.sequelize.models.user.findAll(query).then(function (objs) {
+                if ( objs == null || objs.length ==0  ) {
+                    //return;
+                }
+           //     self.proc(i, query)
+                fx()
+            }).catch(function(error) {
+                console.error('error occurred', error, error.stack)
+                throw (new Error(error));
+            });
+        }, function ended() {
+            self.proc('how long', sh.time.secs(self.startTime));
+        })
+
+
+
+
+
+    }
+
+    p.proc = function debugLogger() {
+        if ( self.silent == true) {
+            return
+        }
+        sh.sLog(arguments)
+    }
+
+
+}
+
+exports.BasicClass = BasicClass;
+
+if (module.parent == null) {
+
+    var i = new BasicClass()
+    i.init();
+}
+
+
