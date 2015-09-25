'use strict';

/**
 * Listen for socket, when receieve data
 * reload file  css or html
 */
(function(){


    var mTH = {};




    var app = spgrtApp;

    var quickReloadDemo = function quickReloadDemo(//$templateRequest,
                                                   $compile,
                                                   $interpolate//,
                                                   // transcludeHelper
        ) {
        // var utilsParent = transcludeHelper.new(this);
        console.log('creating', document.currentScript)
        function link(scope, element, attrs){
            $templateRequest('scripts/quick_module/demo/quickreload.dir.demo.html').then(
                function(html){
                    var utils = transcludeHelper.new();
                    utils.dictTemplates = utilsParent.dictTemplates; //copy over dictionary of templates
                    utils.$compile = $compile;
                    utils.loadTemplate(html, element, attrs);
                    scope.render(utils);
                }
            )


            controllerReference.$id = Math.random();
            console.log('top', controllerReference.$id,
                controllerReference.title, controllerReference.items, controllerReference.items2 );
        };

        var templateOriginal = null;
        var dictTemplates = {};
        var controllerReference = null;
        var compile = function (tElem, attrs) {
            // utilsParent.storeTemplate(tElem, attrs);
            templateOriginal = tElem.children.clone();
            function defineDirectiveDefaults() {
                if ( attrs.selectedIndex === null  ) {
                    attrs['selectedIndex'] = "-1";
                };
            }
            defineDirectiveDefaults();

            return {
                pre: function(scope, element, attrs, controller){
                    controllerReference = controller;
                    return;
                },
                post: link
            };
        }
        return {
            scope: {
                title: '@',
                fxItemSelected: '&',
                id: '@',
                views: '@',
                views2: '@'
            },
            controller: 'QuickReloadDemoController',
            controllerAs: 'vm',
            bindToController:true,
            compile: compile
        };
    };


    app.directive('quickReloadDemo', quickReloadDemo);

    var QuickReloadDemoController =
        function QuickReloadDemoController ($scope,
                                            //sh,
                                            $http,
                                            $templateCache,
                                            $rootScope,
                                            $cacheFactory,
                                            $compile
            ) {
            //  sdfg.h
            var sh = {};
            sh.each = angular.forEach;
            sh.callIfDefined =callIfDefined

            function callIfDefined(fx) {
                if (fx == undefined)
                    return;
                var args = convertArgumentsToArray(arguments)
                args = args.slice(1, args.length)

                // console.debug('args', tojson(args))
                return fx.apply(null, args)
                //return;
            }
            function convertArgumentsToArray(_arguments) {
                var args = Array.prototype.slice.call(_arguments, 0);
                return args
            }

            sh.dv = function defaultValue(input, ifNullUse) {
                if (input == null) {
                    return ifNullUse
                }
                return input;
            }


            var types = {};
            var count = 0;
            $scope.count = count;
            $scope.render = function render_reRenderComponent(utils) {
                $scope.count++;
                var scope = $scope;
                var html = $scope.html.clone();
                if ( $scope.last == null ) {
                    $scope.last = html;
                }
                var element = $scope.element;
                var $compile = $scope.$compile;
                element.html(
                    $compile(html)(scope));
                console.log('reload count',scope.count ) //, scope.$compile==$compile )

                setTimeout(function updateLater() {
                    $scope.$apply();
                }, 20);
            };

            if ( window.fxInvoke == null ) {
                console.log('setup invoke')

                //What is this?
                //Entry point from socket-reloader lib.
                window.fxInvoke = function (classToUpdate) {
                    try {
                        var str = classToUpdate.split('/').slice(-1)[0]
                        $rootScope.$emit(classToUpdate, classToUpdate)
                        $rootScope.$emit(str, classToUpdate)
                    } catch (e  ) {}
                    window.fxInvoke.checkAll(classToUpdate)
                };



                //Setup fxTestConditionFilterFunctions
                window.fxInvoke.sets = [];
                window.fxInvoke.reloadFilterFunctions = window.fxInvoke.sets;
                //BasicFilter TODO: do away with pattern
                window.fxInvoke.includes = function addReloadTestConditionCallback(addOnLink, fx) {
                    window.fxInvoke.sets.push([addOnLink, fx])
                };

                window.fxInvoke.addGenericFilterMethod = function addReloadTestConditionCallback(fxReloadCheck_FilterMethod) {
                    window.fxInvoke.reloadFilterFunctions.push(fxReloadCheck_FilterMethod);
                };

                //Run check for FilterFunctions

                window.fxInvoke.checkAll = function checkConditionsForReloadMatch(reloadData) {
                    var filenameToReload  = reloadData;
                    window.fxInvoke.listFilesToReload = []; //Store files
                    $.each(window.fxInvoke.sets, function findMatch(i, set) {
                        var file = set[0]
                        if ( angular.isFunction(set)) {
                            var fxReloadCheck_FilterMethod = set;
                            var testResult = fxReloadCheck_FilterMethod(reloadData)
                            return;
                        }
                        if ( angular.isString(filenameToReload)) {
                            var fx = set[1];
                            var fileMatched = filenameToReload.toLowerCase().indexOf(file.toLowerCase()) != -1;
                            console.log('checking...', file, fileMatched, 'in >>>', filenameToReload.toLowerCase());
                            if ( fileMatched ) {
                                fx(s);
                            };
                        }

                    })
                    if ( window.fxInvoke.listFilesToReload.length > 0 ) {
                        //do a reload
                        //do a rerender
                    }
                }
            };


            $scope.watchFile = function watchFile(file) {
                if ( $scope.watchingFiles == null ) {
                    $scope.watchingFiles = [];
                }
                if ( $scope.watchingFiles.indexOf(file) != -1 ) {
                    return false;
                }
                $scope.watchingFiles.push(file);
                window.fxInvoke.includes(file, function watchFile_reloadOnMatch (fileMatch) {
                    console.log('found match', fileMatch);
                    $scope.onReload2()
                })

            };

            /**
             * More abstract ...
             * @param file
             */
            $scope.watchDir = function watchDir(dir) {
                $scope.watchDirs = sh.dv($scope.watchDirs, []);
                if ( $scope.watchDirs.indexOf(dir) != -1 ) {
                    return;
                }
                $scope.watchDirs.push(dir);
                //load the file if matched in the dir
                window.fxInvoke.includes(dir, function (file_in_dirMatch) {
                    ///Users/user2/Dropbox/projects/learn angular/port3/app/scripts/quick_module/services/uiXService.js

                    var loadFile = file_in_dirMatch.split(dir)[1];
                    loadFile = dir + '/' + loadFile;
                    console.log('found dirMatch', file_in_dirMatch, loadFile);
                    $scope.onReload2(loadFile )
                })

            };

            window.fxInvoke.includes('quick/quickreloadable.dir', function (fileMatch) {
                console.log('found match', fileMatch);
                $scope.onReload2();
            })

            $scope.watchFile("/scripts/quick_module/services/reloadableHelperTestService.js")
            //$scope.watchFile("/scripts/quick_module/services/quickUIService.js")
            //$scope.watchFile("/scripts/quick_module/services/angFuncService.js")
            $scope.watchDir("/scripts/quick_module/services/")

            window.fxInvoke.addGenericFilterMethod(function performEval(actions) {
                console.log('reload2.js', 'action', actions)
                if ( actions.type == 'eval') {
                    eval(actions.eval)
                }

                if ( actions  == 'reloadcss') {
                    reloadStylesheets();
                }

                $scope.render();
                $templateCache.removeAll();
            })


            /**
             * Forces a reload of all stylesheets by appending a unique query string
             * to each stylesheet URL.
             */
            function reloadStylesheets() {
                var queryString = '?reload=' + new Date().getTime();
                $('link[rel="stylesheet"]').each(function () {
                    this.href = this.href.replace(/\?.*|$/, queryString);
                });
            }


            //Reload specific file url
            $scope.reloadFile = function reloadFile(file, fx) {
                $scope.watchFile(file)
                console.log('reloadFile', file);
                jQuery.ajax({
                    url: file,
                    dataType: "script",
                    cache: true
                })
                    .error(function(s, b) {
                        alert('error loading ' +  file)
                    })
                    .done(function() {
                        sh.callIfDefined(fx)
                    });
            }

            $scope.onReload = function onReload() {
                console.log('...');
                jQuery.ajax({
                    url: "/scripts/quick_module/quick/quickreloadable.dir.js",
                    dataType: "script",
                    cache: true
                }).done(function() {
                    console.log('updated')
                    $templateCache.removeAll();
                    $scope.render();
                    //jQuery.cookie("cookie_name", "value", { expires: 7 });
                });
            }


            /*
             Uses template thing
             same as onReload but, ???
             */
            $scope.onReload2 = function onReload_redraw(addFile) {

                if (addFile) {
                    console.log('addfile', addFile)
                    $scope.reloadFile(addFile);
                } else {
                    sh.each($scope.watchingFiles, function (i,file) {
                        $scope.reloadFile(file);
                        // $scope.reloadFile("/scripts/quick_module/services/reloadableHelperTestService.js")
                        // $scope.reloadFile("/scripts/quick_module/services/reloadableHelperTestService.js")
                    });
                }
                console.log('...');
                jQuery.ajax({
                    url: "/scripts/quick_module/quick/quickreloadable.dir.js?q="+Math.random(),
                    dataType: "script",
                    cache: false
                })
                    .error(function(s, b) {
                        alert('error loading ' +  addFile)
                    })
                    .done(function(s, b) {
                        console.log('updated', $cacheFactory)
                        $templateCache.removeAll();
                        $scope.render()
                    });
            }

            $scope.triggerRelink = function() {
                $rootScope.$broadcast('testRelink');
            };

        }
    app
        .controller('QuickReloadDemoController', QuickReloadDemoController);
    //asdf.g
    app
        .filter('to_trusted', ['$sce', function($sce){
            return function(text) {
                return $sce.trustAsHtml(text);
            };
        }]);

    app.directive('helloWorld', function helloWorldDirective($compile) {
        var helper = {};
        function link(scope, element, attrs){
            //  $templateRequest('scripts/quick_module/demo/quickreload.dir.demo.html').then(
            //     function(html){
            //         var utils = transcludeHelper.new();
            //         utils.dictTemplates = utilsParent.dictTemplates; //copy over dictionary of templates
            //         utils.$compile = $compile;
            //         utils.loadTemplate(html, element, attrs);
            scope.element = element;
            scope.html = templateOriginal;
            scope.$compile = $compile;
           // sdfg.h
            if ( helper.renderedOnce != true ) {
                helper.renderedOnce = true;
                scope.render();
            } else {
                console.log('rendered before')
            }

            //}
            //)


            // controllerReference.$id = Math.random();
            console.log('top', scope.$id  );
        };

        var templateOriginal = null;
        var dictTemplates = {};
        var controllerReference = null;
        var compile = function (tElem, attrs) {
            console.log('compile reloadable')
            templateOriginal =  tElem.clone().children().clone();;
            // utilsParent.storeTemplate(tElem, attrs);
            function defineDirectiveDefaults() {
                if ( attrs.selectedIndex === null  ) {
                    attrs['selectedIndex'] = "-1";
                };
            }
            defineDirectiveDefaults();

            return {
                pre: function(scope, element, attrs, controller){
                    // controllerReference = controller;
                    return;
                },
                post: link
            };
        }

        return {
            scope: {},  // use a new isolated scope
            restrict: 'AE',
            replace: true,
            // template: '<h3 style="background-color:{{color}}">Hello World</h3>',
            controller: 'QuickReloadDemoController',
            controllerAs: 'vm',
            bindToController:true,
            compile:  compile
            /*
             function(scope, elem, attrs) {
             elem.bind('click', function() {
             elem.css('background-color', 'white');
             scope.$apply(function() {
             scope.color = "white";
             });
             });
             elem.bind('mouseover', function() {
             elem.css('cursor', 'pointer');
             });
             console.log('in controller')
             }*/
        };
    });





    function helloWorld2($compile) {
        console.log('in running  controller')
        console.log('dI: $compile ...', $compile )
        return {
            scope: {},  // use a new isolated scope
            restrict: 'AE',
            replace: true,
            template: '<h3 style="background-color:{{color}}">Hello World2</h3>',
            link:
                function linkMethod (scope, elem, attrs) {
                    elem.bind('click', function() {
                        elem.css('background-color', 'white');
                        scope.$apply(function() {
                            scope.color = "white";
                        });
                    });
                    elem.bind('mouseover', function() {
                        elem.css('cursor', 'pointer');
                    });
                    console.log('in  controller')
                }
        };
    }
    helloWorld2.$inject = ['$compile']
    app.directive('helloWorld2',  ["$compile", helloWorld2 ]);
}());
