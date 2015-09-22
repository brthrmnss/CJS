

var forwardFx = function forwardFx(fxName, fxIfUndef) {

    function convertArgumentsToArray(_arguments) {
        var args = Array.prototype.slice.call(_arguments, 0);
        return args
    }

    function callIfDefined(fx) {
        if (fx == undefined)
            return;
        var args = convertArgumentsToArray(arguments)
        args = args.slice(1, args.length)

        // console.debug('args', tojson(args))
        return fx.apply(null, args)
        //return;
    }


    return function controllerStandIn( ) {
        var fxForwardTo = fxIfUndef;
        var fxReloaded = window[fxName];
        if ( fxReloaded != null ) {
            fxForwardTo = fxReloaded;
        };
        var args = convertArgumentsToArray(arguments)
        fxForwardTo.apply(this, args)
        // callIfDefined(fxForwardTo)
    }

}

console.log('Reloading active');


var forwardFx = function forwardFx(fxName, ctrlVal) {

    function convertArgumentsToArray(_arguments) {
        var args = Array.prototype.slice.call(_arguments, 0);
        return args
    }

    function callIfDefined(fx) {
        if (fx == undefined)
            return;
        var args = convertArgumentsToArray(arguments)
        args = args.slice(1, args.length)

        // console.debug('args', tojson(args))
        return fx.apply(null, args)
        //return;
    }

    var ctrlValOrig = ctrlVal;
    if ($.isArray(ctrlVal ) ) {
        var lastParamAsFx = ctrlVal.slice(-1)[0]
        if ( $.isFunction(lastParamAsFx) ) {
            ctrlVal =  lastParamAsFx
        }
    }



     function controllerStandIn( ) {
        var fxForwardTo = ctrlVal;
        var fxReloaded = window[fxName];
        if ( fxReloaded != null ) {
            fxForwardTo = fxReloaded;
        };
        var args = convertArgumentsToArray(arguments)
        if ( fxForwardTo == null || fxForwardTo == undefined) {
            console.error('null for', '....', fxName)
            asdf.g
        }
        fxForwardTo.apply(this, args)
        // callIfDefined(fxForwardTo)
    }



    var controllerStandInVal = controllerStandIn;

    if ($.isArray(ctrlValOrig ) ) {
        controllerStandInVal = ctrlValOrig
        controllerStandInVal.pop()
        controllerStandInVal.push(controllerStandIn)
    }


    return controllerStandInVal

}


spgrtApp.controllerOld = spgrtApp.controller;

spgrtApp.controller = function addController(ctrlName, ctrl) {
    // console.error('redirected', ctrlName, ctrl)
    if ( ctrlName == 'dealerHoldingsCtrl') {
        console.error('redirected', ctrlName, ctrl)
        spgrtApp.controllerOld(ctrlName,  forwardFx(ctrlName, ctrl));
    } else {
        spgrtApp.controllerOld(ctrlName,   ctrl );
    }

}






setTimeout(reInitCtrl, 4000)

function reInitCtrl() {
    window['dealerHoldingsCtrl'] = function newXIn2($scope, $timeout, printSetSvc, $element) {

        alert('... new msg2 ...')
        $scope.name  = 'dealerHoldingsCtrl';

        $scope.$on('globalDateChange', function(event, args){
            $scope.inputDate = args.val;
        });

        $scope.$on('sidebarHidden', function(event, args){
            $timeout(function() {
                $scope.equalizeCharts();
            }, 500);
        });


        $scope.inputDate = $scope.$parent.globalDate || new Date();

        var splitArray = function split(a, n) {
            var len = a.length,out = [], i = 0;
            while (i < len) {
                var size = Math.ceil((len - i) / n--);
                out.push(a.slice(i, i += size));
            }
            return out;
        }

        $scope.$watch('asOfDate.data', function() {
            if ($scope.asOfDate && $scope.asOfDate.data) {
                $scope.asOfDateDisplay = $scope.asOfDate.data;
            }
        });

        $scope.$watch('contributingDealers.data', function() {
            if ($scope.contributingDealers && $scope.contributingDealers.data) {
                $scope.dealersSplit = splitArray($scope.contributingDealers.data, 2);

            }
        });


        var printWatchFunction = function() {
            if (isReady()) {
                $timeout(function() {
                    printSetSvc.ready("dealerHoldings");
                });
            }
        } ;

        $scope.$watch('contributingDealers.data', printWatchFunction);
        $scope.$watch('agencyResi.data', printWatchFunction);
        $scope.$watch('ABS.data', printWatchFunction);
        $scope.$watch('OtherABS.data', printWatchFunction);
        $scope.$watch('RMBS.data', printWatchFunction);
        $scope.$watch('CMBS.data', printWatchFunction);


        function isReady() {

            return  (
                ($scope.agencyResi && $scope.agencyResi.data ) &&
                    ($scope.contributingDealers && $scope.contributingDealers.data ) &&
                    ($scope.ABS && $scope.ABS.data ) &&
                    ($scope.OtherABS && $scope.OtherABS.data ) &&
                    ($scope.RMBS && $scope.RMBS.data ) &&
                    ($scope.CMBS && $scope.CMBS.data)
                ) ;

        }

        /*
         HighCharts functions
         */

        $scope.xAxisLabelsFormatter= function() {
            var d = new Date(this.value),
                monthNum = d.getMonth() + 1,
                dateNum = d.getDate(),
                fullYear = d.getFullYear();

            return monthNum + '/' + dateNum + '/' + fullYear;
        }

        $scope.y2AxisLabelsFormatter = function(){
            return (this.value * 100).toFixed(0) + '%';
        }

        $scope.yAxisLabelsFormatter = function(){
            return (this.value / 1000).toFixed(0) + ('B');
        }

        $scope.legendLabelFormatter = function(){
            if (this.name == 'DealerTotal') {
                return 'Dealer Total';
            }
            if (this.name == 'DealerExMS') {
                return 'Dealer ex MS';
            }
            if (this.name == 'MSPct') {
                return 'MS Position %';
            }
            if (this.name == 'TracePct') {
                return 'Trace Mkt Share';
            }
            return this.name;
        }

        $scope.toolTipFormatter = function() {
            var seriesName = this.series.name,
                yVal;

            if (seriesName == 'DealerTotal') {
                seriesName = 'Dealer Total';
            }
            if (seriesName == 'DealerExMS') {
                seriesName = 'Dealer ex MS';
            }
            if (seriesName == 'MSPct') {
                seriesName = 'MS Position';
            }
            if (seriesName == 'TracePct') {
                seriesName = 'Trace Mkt Share';
            }

            if (this.series.name.match(/Dealer/) !== null) {
                yVal = Number((this.y * 1000000).toFixed(0)).toLocaleString('en');
            } else {
                yVal = (this.y * 100).toFixed(1) + '%';
            }

            return '<em>' + new Date(this.x).toLocaleDateString() + '</em><br>' + seriesName + ': <strong>' +  yVal + '</strong>';
        }

        $scope.xAxisTickPositioner =  function() {
            var ticks = [],
                srcDate = $scope.asOfDateDisplay || $scope.inputDate,
                counterDate = new Date(srcDate.getFullYear(), srcDate.getMonth(), 4);

            while (ticks.length < 12) {
                if (counterDate < srcDate)
                    ticks.push(Date.UTC(counterDate.getFullYear(), counterDate.getMonth(), 4));
                counterDate.setMonth(counterDate.getMonth() - 1);
            }

            //dates.info defines what to show in labels
            //apparently dateTimeLabelFormats is always ignored when specifying tickPosistioner
            ticks.info = {
                unitName: "day",
                // unitName: "day",
                higherRanks: {} // Omitting this would break things
            };

            return ticks;
        }

        $scope.equalizeCharts = function (media) {

            // console.log('EQUALIZE CHARTS');

            var maxWidth = 0,
                maxHeight = 0,
                selecter = '.screenOnly .stackedChartWrapper',
                itemArray;

            if(media=='print')
                selecter = '.printOnly .stackedChartWrapper';

            itemArray = $($element).find(selecter);

            itemArray.each(function(i, obj) {
                $(obj).width('');
                $(obj).height('');
            });

            itemArray.each(function(i, obj) {
                obj = $(obj);
                if(maxHeight == 0) {
                    maxHeight = obj.height();
                    maxWidth = obj.width();
                    return true;
                }
                if(obj.width() < maxWidth) {
                    obj.width(maxWidth);
                }
                if(obj.height() > maxHeight) {
                    var newHeight = obj.height();
                    obj.parents('.stackedContainerRow').find('.stackedChartWrapper').height(newHeight);
                }
                if(obj.width() > maxWidth) {
                    var newWidth = obj.width();
                    itemArray.each(function(i, obj) {
                        $(obj).width(newWidth);
                    });
                }

            });
            /*
             $timeout(function() {
             if ($($element).find('.highcharts-container').length && ($($element).find('.highcharts-container').width() != $($element).find('.stackedChartWrapper').width())) {
             $(window).resize();
             }
             }, 100);
             */

        };

        $timeout(function() {
            $scope.equalizeCharts();
            $scope.equalizeCharts('print');
        }, 250);

        var fn = _.debounce($scope.equalizeCharts, 100);

        $(window).resize(fn);

        $scope.$on('$destroy', function() {
            $(window).off('resize', fn);
            $scope = null;
        });

    }
}
