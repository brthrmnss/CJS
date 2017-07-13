function forwardArgsTo(fx, args, delay) {
    if (fx == undefined)
        return;
    if (args != null && args.length == null) {
        var args = convertArgumentsToArray(args)
    }
    if ( delay != null ) {
        setTimeout(function onDelayedForwardArgs()  {
            //debugger
            fx.apply(null, args)
        }, delay)
        return undefined;
    }

    return fx.apply(null, args)
}

function convertArgumentsToArray(_arguments) {
    var args = Array.prototype.slice.call(_arguments, 0);
    return args;
}


function defaultValue(input, ifNullUse) {
    if (input == null) {
        return ifNullUse
    }
    return input;
}
var dv = defaultValue;


function callIfDefined(fx) {
    var args = convertArgumentsToArray(arguments)
    args = args.slice(1, args.length)

    if (fx == undefined)
        return args[0];

    if ( fx == null ) {
        return;
    }

    if ( $.isFunction(fx) == false ) {
        return;
    }

    // console.debug('args', tojson(args))
    return fx.apply(null, args)
    //return; 
}

function convertArgumentsToArray(_arguments) {
    var args = Array.prototype.slice.call(_arguments, 0);
    return args
}

function throwIfNull(prop, msg) {
    if (prop == null) {
        throw new Error(msg)
    }
}

function defineUtils2() {
    $.async = function asyncHelper(items, fx, fxAllDone, delay, playIndex) {
        //var index = 0
        var asyncController = {};
        asyncController.index = 0;
        asyncController.getNext = function getNextItem() {
            var next = items[asyncController.index + 1];
            return next;
        }
        if (playIndex > 0) {
            asyncController.index = playIndex;
        }
        if (playIndex < 0) {
            asyncController.index = items.length - 1 + playIndex;
        }

        asyncController.length = items.length;

        if (delay == null && $.isNumeric(fxAllDone)) {
            delay = fxAllDone;
        }

        function goToNextSpan() {
            var item = items[asyncController.index];
            console.log('playindex', asyncController.index)
            if (asyncController.index > items.length - 1) {
                if (fxAllDone) {
                    fxAllDone();
                }
                return;
            }
            fx(/*asyncController.index,*/ item, fxCallback, asyncController, asyncController.index)
            asyncController.index++;

            function fxCallback() {
                if (delay) {
                    setTimeout(goToNextSpan, delay);
                    return;
                }
                goToNextSpan();
            }
        }

        goToNextSpan();
        asyncController.runIteration = function runIteration() {
            goToNextSpan();
        }
        return asyncController;
    }

    if ($.isObject == null) {
        $.isObject = function isObject(obj) {
            if ($.isFunction(obj)) {
                return false;
            }
            if (obj == null) {
                return false;
            }
            return typeof obj == 'object'
        }

    }
}
defineUtils2();


var uiUtils = {};
window.uiUtils = uiUtils;

function defineUtils() {
    var self = uiUtils;
    var p = uiUtils;
    var u = p;

    u.data = {}

    uiUtils.dictCfg = {};

    uiUtils.cid = uiUtils.callIfDefined = callIfDefined

    u.dv = dv;
    uiUtils.qq = function qq(txt) {
        return '"' + txt + '"'
    }

    uiUtils.paren = function paren(txt) {
        return '(' + txt + ')'
    }

    uiUtils.b = function b(txt) {
        return '<b>' + txt + '</b>'
    }

    $.isString = function isString(objectOrString) {
        //return (objectOrString instanceof String)
        return typeof objectOrString == 'string'
    }

    p.convertArgumentsToArray =
        p.args = function convertArgumentsToArray_(_arguments) {
            var args = Array.prototype.slice.call(_arguments, 0);
            return args
        }

    p.forwardArgsTo = forwardArgsTo;


    self.clone = function clone(e) {
        var eee = JSON.stringify(e)
        return JSON.parse(eee)
    }

    uiUtils.makeHiderBtn = function makeHiderBtn(jqBtn, jqContainer, parentUI, hideOnInit) {
        var btnHide = $(jqBtn)
        if (parentUI) {
            btnHide = parentUI.find(jqBtn)
        }

        btnHide.attr('title', 'Hide this element')
        btnHide.addClass('unselectable2')
        btnHide.addClass('useFingerPointerCursor')

        var hideContainer = $(jqContainer)
        if (parentUI) {
            hideContainer = parentUI.find(jqContainer)
        }

        function onToggleVisibility() {
            btnHide.hidden = !btnHide.hidden;
            if (btnHide.hidden) {
                hideContainer.hide()
            } else {
                hideContainer.show();
            }
        }


        btnHide.click(onToggleVisibility)

        if (hideOnInit) {
            setTimeout(function () {
                onToggleVisibility()
            }, 150)
        }
    }


    uiUtils.makePanel = function makePanel(cfg) {
        throwIfNull(cfg.id, 'need an id')
        u.cfg.fixId(cfg)
        var existingUI = $(cfg.id);


        if (cfg.clearOld && cfg.id) {
            $(cfg.id).remove();
        }

        if (existingUI.length > 0) {
            if (existingUI.length > 0) {
                console.warn('you have multiple things')
            }
            if (cfg.clearIfFound !== true) {
                //if ( cfg.toggleMode != false ) {
                //		}
                existingUI.show();
                var cfg = uiUtils.dictCfg[cfg.id]
                //debugger;
                return existingUI.cfg;
            } else {
                console.warn('removing existing version')
                existingUI.remove();
            }
        }

        cfg = dv(cfg, {});
        uiUtils.dictCfg[cfg.id] = cfg;

        var panel = $('<div />')//
        // style="position: fixed; bottom: 10px; right: 10px;display: none; color:red; " id="testLogPanel">asdf  </div>')
        panel.attr('id', u.cfg.getId(cfg.id));
        panel.css('position', 'fixed');
        panel.css('bottom', '10px');
        panel.css('left', '10px');
        panel.css('z-index', '1001');
        panel.css('background-color', '#f2f2f2');
        panel.css('padding', '10px');
        panel.css('border', '1px #666666 solid');
        //panel.attr('id', cfg.id);
        //panel.attr('id', cfg.id);


        function onCloseDialog() {
            panel.hide()
            return;
        }

        cfg.fxClose = onCloseDialog;
        //panel.cfg = cfg;
        //panel.html('sdfsdf');
        $('body').append(panel);
        cfg.ui = cfg.panel = panel;
        uiUtils.lastUI = panel;

    };

    uiUtils.panel = uiUtils.makePanel;

    uiUtils.panel.tr = function makeBrPanel(cfg) {
        cfg = u.cfg.str(cfg, 'id')
        cfg = p.panel(cfg);
        u.clearPositions(cfg.ui)
        cfg.ui.css('top', '10px');
        cfg.ui.css('right', '10px');
    }

    uiUtils.clearPositions = function clearPositions(ui) {
        ui.css('left', '');
        ui.css('bottom', '');
        ui.css('right', '');
        ui.css('top', '');
    }
    uiUtils.panel.br = function makeBrPanel(cfg) {
        /*if ( cfg.length ) {
         var cfg = {ui:cfg}
         }*/
        cfg = u.cfg.str(cfg, 'id')
        p.panel(cfg);
        u.clearPositions(cfg.ui)
        cfg.ui.css('bottom', '10px');
        cfg.ui.css('right', '10px');
    }

    uiUtils.panel.bl = function makeBrPanel(cfg) {
        cfg = u.cfg.str(cfg, 'id')
        p.panel(cfg);
        u.clearPositions(cfg.ui)
        cfg.ui.css('bottom', '10px');
        cfg.ui.css('left', '10px');
    }


    uiUtils.position = function position(lOrUI, t, r, b, bz) {
        var ui = uiUtils.lastUI;

        var l = lOrUI
        if (lOrUI.length) {
            ui = lOrUI
            l = t;
            t = r
            r = b
            b = bz
        }
        if (l != null) {
            ui.css('left', l + 'px')
        } else {
            if (l === null) {
                ui.css('left', '')
            }
        }

        if (t != null) {
            ui.css('top', t + 'px')
        } else {
            if (t === null) {
                ui.css('top', '')
            }
        }

        if (r != null) {
            ui.css('right', r + 'px')
        } else {
            if (r === null) {
                ui.css('right', '')
            }
        }

        if (b != null) {
            ui.css('bottom', b + 'px')
        } else {
            if (b === null) {
                ui.css('bottom', '')
            }
        }
        /*console.log(
         ui,
         ui.css('left'),
         ui.css('top'),
         ui.css('right'),
         ui.css('bottom')
         )*/
        //debugger

        /*
         if (  t != null )
         ui.css('top', t + 'px')
         if (  r != null )
         ui.css('right', r + 'px')
         if (  b != null )
         ui.css('bottom', b + 'px')
         */
    }

    u.pos = u.position;
    u.pos.br = function movetoButtonRight(ui, b, r) {
        b = dv(b, 10)
        r = dv(r, 10)
        u.position(ui, null, null, b, r)
    }

    uiUtils.makeAbs = function makeAbs(jquery, highPosition) {
        jquery.css('position', 'absolute');
        if (highPosition) {
            jquery.css('z-index', highPosition + 200);
        }

        uiUtils.position(jquery, 0, 0)

    }

    uiUtils.ifFound = function ifFound(id) {
        if (id.includes('#') == false) {
            id = '#' + id;
        }
        var isFound = $(id).length > 0;
        return isFound;
    }

    uiUtils.addDefaultCfg = function addDefaultCfg(cfg) {
        uiUtils.flagCfg = cfg;
    }
    uiUtils.flagCfg = {};

    uiUtils.makeCheckbox = function makeCheckbox(cfg, id) {
        cfg = u.cfg.str(cfg, 'text');
        u.cfg.addToCfg(cfg, 'id', id);
        cfg.tag = dv(cfg.tag, 'input');
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var ui = u.tag(cfg.tag)
        ui.attr('type', 'checkbox')
        ui.html(cfg.text)

        if (cfg.windowProp) {
            var keyVal = 'store.' + cfg.windowProp;
            var previousVal = uiUtils.getVal(keyVal);


            if (previousVal != null) {
            } else {
                if (cfg.defaultValue) {
                    previousVal = cfg.defaultValue;
                }
            }

            console.log('keyval', keyVal, previousVal)

            if (previousVal != null) {
                uiUtils.setVal(keyVal, previousVal);
                setTimeout(function onLateR() {
                    callIfDefined(cfg.fxChange, previousVal)
                }, 500)

                window[cfg.windowProp] = previousVal;
                var val = eval('window.' + cfg.windowProp);
                ui.prop('checked', val);
            }
        }


        ui.click(onChangeOptions);
        function onChangeOptions(event) {
            console.log('...', cfg.windowProp);
            var val = ui.is(':checked');
            if (cfg.windowProp) {
                var val = eval('window.' + cfg.windowProp + '=' + val);
                uiUtils.setVal(keyVal, val);
                //ui.prop('checked', val);
            }
            ;

            callIfDefined(cfg.fxChange, val)

        }


        //	lbl.css('user-select', 'none');
        u.addUI(cfg, ui);

        if (cfg.label) {
            uiUtils.addLabel(cfg.label)
        }

        return cfg;
    }

    uiUtils.addDropdown = function addLabel(cfg) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = dv(cfg.tag, 'select');
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var ui = u.tag(cfg.tag)
        ui.html(cfg.text)

        if (cfg.options) {
            $.each(cfg.options, function onAddOtpion(k, v) {


                if (v.value == null) {
                    v = {value: v, text: v}
                }
                console.log('k', v)
                ui.append($('<option>', /*{
                 value: item.value,
                 text: item.text
                 }*/v));

            })
        }
        //$('<span/>')
        /*if (cfg.width){
         if ( $.isNumeric(cfg.width) ) {
         cfg.width = cfg.width+'px';
         }
         lbl.css('width', cfg.width);
         lbl.css('display', 'inline-block');
         }
         lbl.css('user-select', 'none');*/
        u.addUI(cfg, ui);
        return cfg;
    }

    uiUtils.addDD = uiUtils.addDropdown

    uiUtils.addNumber = function addNumber(cfg) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = dv(cfg.tag, 'input');
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var lbl = u.tag(cfg.tag)
        lbl.html(cfg.text)
        //$('<span/>')
        /*if (cfg.width){
         if ( $.isNumeric(cfg.width) ) {
         cfg.width = cfg.width+'px';
         }
         lbl.css('width', cfg.width);
         lbl.css('display', 'inline-block');
         }
         lbl.css('user-select', 'none');*/
        lbl.attr('type', 'number');

        u.addUI(cfg, lbl);
        return cfg;
    }

    uiUtils.addSection = function addSection(fx) {
        fx();
    }
    uiUtils.addLabel = function addLabel(cfg, id) {
        cfg = u.cfg.str(cfg, 'text');
        u.cfg.addToCfg(cfg, 'id', id);
        cfg.tag = dv(cfg.tag, 'span');
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var lbl = u.tag(cfg.tag)
        lbl.html(cfg.text)
        //$('<span/>')
        if (cfg.width) {
            if ($.isNumeric(cfg.width)) {
                cfg.width = cfg.width + 'px';
            }
            lbl.css('width', cfg.width);
            lbl.css('display', 'inline-block');
        }
        if ( cfg.unselectable ) {
            lbl.css('user-select', 'none');
        }
        u.addUI(cfg, lbl);
        return cfg;
    }
    uiUtils.addRadio = function addLabel(cfg, id) {
        cfg = u.cfg.str(cfg, 'text');
        u.cfg.addToCfg(cfg, 'id', id);
        cfg.tag = dv(cfg.tag, 'input');
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        //   <input type="radio" name="managerelradio" value="No" id="Remove">


        var ui = u.tag(cfg.tag)
        ui.attr('type', 'radio')


        sh.throwIfNull(cfg.name, 'need a radio name')
        sh.throwIfNull(cfg.value, 'need a radio value')
        ui.attr('name', cfg.name)
        ui.attr('value', cfg.value)

        ui.css('min-height', '0px')
        ui.css( 'cursor', 'pointer' );

        //$('<span/>')
        /*  if (cfg.width) {
         if ($.isNumeric(cfg.width)) {
         cfg.width = cfg.width + 'px';
         }
         lbl.css('width', cfg.width);
         lbl.css('display', 'inline-block');
         }
         lbl.css('user-select', 'none');*/
        u.addUI(cfg, ui);

        if ( cfg.selected ) {
            // debugger
            $(":radio[name='"+cfg.name+"']").attr('checked', true);
        }

        return cfg;
    }

    u.setRadioVal = function setRadioVal(k,v,val) {
        $('input:radio[name="'+k+'"]').filter('[value="'+v+'"]').attr('checked', val);
    }

    uiUtils.addHeadingLabel = function addLabel(cfg) {
        cfg.tag = 'h3'
        uiUtils.addLabel(cfg)
        return cfg;
    }

    uiUtils.addDiv = function addDiv(cfg, mergeInCfg) {
        cfg = u.cfg.str(cfg, 'id')
        //or .type
        cfg.tag = dv(cfg.tag, 'div');
        uiUtils.utils.mergeIn(mergeInCfg, cfg);
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);


        var ui = u.tag(cfg.tag)

        /*if (){
         //uiUtils.skipNextAdd = true
         }*/

        ui.html(cfg.text)
        u.addUI(cfg, ui);
        if (cfg.newBaseContainer) {
            cfg.lastAddTo = cfg.addTo
            cfg.addTo = ui;
        }
        return cfg;
    }
    uiUtils.create =
        uiUtils.make = uiUtils.addDiv;

    uiUtils.addA =
        uiUtils.makeA = function makeA(typeOrCfg, justCfg) {

            //make it but dont'add it
            // uiUtils.skipNextAdd = true
            var cfg = uiUtils.createA(typeOrCfg, justCfg);
            //debugger
            return cfg;
        }

    uiUtils.createA = function addA(typeOrCfg, justCfg) {
        var cfg = typeOrCfg
        if (justCfg) {
            if ($.isObject(justCfg) == false) {
                throw new Error('bad input')
            }
            ;
            cfg = justCfg;
        }
        if ($.isString(typeOrCfg)) {
            cfg = {};
            if ($.isObject(justCfg)) {
                cfg = justCfg
            }
            cfg.tag = typeOrCfg
        }
        cfg = uiUtils.make(cfg);
        //debugger
        return cfg;
    }

    uiUtils.addFloatingDiv = function addFloatingDiv(cfg) {
        //var cfg = uiUtils.addDiv(cfg)
        //var div = uiUtils.getLast()
        var div = $('<div/>')
        $('body').append(div)
        uiUtils.lastUI = div;
        uiUtils.makeAbs(div);
        return div;
    }


    uiUtils.addDialog = function addFloatingDiv(cfg) {
        var fxRevenrt = u.addRootTemp()
        var cfg = uiUtils.addDiv(cfg)
        fxRevenrt();

        var ui = div = cfg.ui;
        //var div = $('<div/>')
        $('body').append(div)
        uiUtils.lastUI = div;
        uiUtils.makeAbs(div);
        uiUtils.position(10, 10)
        if (cfg.addDefaultStyles != false) {
            //panel.attr('id', u.cfg.getId(cfg.id));

            ui.css('position', 'absolute');
            ui.css('z-index', '1001');
            ui.css('background-color', '#f2f2f2');
            ui.css('padding', '10px');
            ui.css('border', '1px #666666 solid');
        }
        if (cfg.class) {
            ui.addClass(cfg.class)
        }
        if (cfg.addPadding != false) {
            ui.css('padding', '10px');
        }


        return div;
    }


    uiUtils.addSpan = function addSpan(cfg) {
        cfg = u.cfg.str(cfg, 'id')
        cfg.tag = dv(cfg.tag, 'span');
        cfg = uiUtils.addDiv(cfg)
        return cfg;
    }
    uiUtils.changeContainer = function focusOnContainer() {
        uiUtils.flagCfg.lastAddTo = uiUtils.flagCfg.addTo;
        uiUtils.flagCfg.addTo = uiUtils.lastCfg.ui;
        //console.log('adding to', uiUtils.flagCfg.addTo)
    }
    uiUtils.popContainer = function popContainer() {
        uiUtils.flagCfg.addTo = uiUtils.flagCfg.lastAddTo;
    }
    uiUtils.addRow = function addRow(id, fx, asSpan) {

        var tagName = 'div'
        if ( asSpan === true  ) {
            tagName = 'span'
        }

        uiUtils.addDiv(
            {
                id: id,
                tag:tagName
                //width:170
            })
        //uiUtils.addBorder();
        //uiUtils.makeInline();
        uiUtils.changeContainer();
        callIfDefined(fx)
    }
    uiUtils.leaveRow = function leaveRow() {
        uiUtils.popContainer();
    }

    uiUtils.style = function style(prop, val) {
        uiUtils.flagCfg.addTo.css(prop, val)
    }
    p.addTitle = function addtitle(cfg) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = 'div'
        u.addLabel(cfg)
    }

    p.addIcon = function addIcon(iconName) {
        var cfg = {}; //cfg = u.cfg.str(cfg, 'text')
        cfg.tag = 'span'
        var cfg = u.addLabel(cfg)
        var span = cfg.ui;
        span.addClass('glyphicon')
        span.addClass('glyphicon-' + iconName) //+'-circle')
        return cfg
    }

    uiUtils.fxTest = function fxTest() {
        console.log('hello');
    }

    uiUtils.addBorder = function addBorder() {
        uiUtils.lastCfg.ui.css('border', 'solid 1px #f2f2f2')
    }

    uiUtils.makeInline = function makeInline() {
        uiUtils.lastCfg.ui.css('display', 'inline-block')
    }

    function defineScrollable() {
        uiUtils.scrollToBottom = function scrollToBottom(jq) {

            var ui = $(jq)
            //$("body").animate({ scrollTop: $('#messages').prop("scrollHeight")}, 200);
            $(jq).clearQueue();
            $(jq).stop(true, true);
            $(jq).animate({scrollTop: $(jq).prop("scrollHeight")}, 10);
            console.log('scrollto', ui.prop('scrollHeight'), ui.scrollTop())
        }

        uiUtils.makeScrollable = function makeScrollaboe(div, height) {
            div.css('overflow', 'auto')
            div.css('max-height', height + 'px')
            //debugger
        }
        uiUtils.scrollToTop = function scrollToTop(jq) {
            //$("body").animate({ scrollTop: $('#messages').prop("scrollHeight")}, 200);
            $(jq).clearQueue();
            $(jq).stop(true, true);
            $(jq).animate({scrollTop: 0}, 10);
        }
    }

    defineScrollable()

    uiUtils.addBtn = function addBtn(cfg, fxD) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = dv(cfg.tag, 'button');
        cfg.fxDone = dv(cfg.fxDone, fxD);
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var btn = u.tag(cfg.tag)
        btn.html(cfg.text)

        //debugger;
        /*
         if ( cfg.addTo ) {
         //debugger;
         cfg.addTo.append(btn)
         }
         */

        u.addUI(cfg, btn)

        btn[0].onclick = cfg.fxDone
        if (cfg.fxClick) {
            $(btn).on('click', function fx_onClickForward(e) {
                //debugger
                cfg.fxClick(e, cfg.data)

            })
        }

        if (cfg.data) {
            btn[0].data = cfg.data
        }

        if (cfg.addSpacer) {
            uiUtils.spacer();
        }

        btn.addClass('btn')
        btn.addClass('btn-primary btn-sm')
        //btn.on('click', cfg.fxDone)
    }
    p.addButton = u.addBtn;


    uiUtils.addLink = function addLink(cfg, fxD) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = dv(cfg.tag, 'a');
        cfg.fxDone = dv(cfg.fxDone, fxD);
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var btn = u.tag(cfg.tag)
        btn.html(cfg.text)

        u.addUI(cfg, btn)
        btn[0].onclick = cfg.fxDone
        if (cfg.fxClick) {
            $(btn).on('click', cfg.fxClick)
        }

        if (cfg.data) {
            btn[0].data = cfg.data
        }

        if (cfg.addSpacer) {
            uiUtils.spacer();
        }


        if (cfg.href)
            btn.attr('href', cfg.href)

        if (cfg.link) {
            btn.attr('href', cfg.link)
        }

        if (cfg.blank || cfg.openInBlank)
            btn.attr('target', '_blank')


        u.addUI(cfg, btn);
        cfg.ui = btn;
        //btn.addClass('btn')
        //btn.addClass('btn-primary btn-sm')
        //btn.on('click', cfg.fxDone)
        return cfg;
    }

    uiUtils.addTextInput = function addTextInput(cfg, fxD) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = dv(cfg.tag, 'input');
        cfg.fxDone = dv(cfg.fxDone, fxD);
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var ui = u.tag(cfg.tag);
        ui.val(cfg.text)

        if (cfg.id) {
            ui.attr('id', cfg.id);
        }

        ui.attr('placeholder', cfg.placeholder);
        if (cfg.onDebounce) {
            u.onChangeDebounced(ui, cfg.onDebounce)
        }

        //ui.addClass('form-control')
        ui.addClass('input-sm')
        u.addUI(cfg, ui);
        cfg.ui = ui;
        return cfg;
    }

    uiUtils.addSelect = function addSelect(cfg, fxD) {
        cfg = u.cfg.str(cfg, 'text')
        cfg.tag = dv(cfg.tag, 'select');
        cfg.fxDone = dv(cfg.fxDone, fxD);
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var ui = u.tag(cfg.tag)
        ui.html(cfg.text)

        if (cfg.id) {
            ui.attr('id', cfg.id);
        }
        ui.on('change', function onChange() {
            console.debug('selected from list', this.value);
            u.cid(cfg.fxDone, this.value)
        })
        u.addUI(cfg, ui)
    }

    uiUtils.select = {};
    uiUtils.select.addOption = function addOption(ui, k,v) {
        var opt = {};
        opt[k]=v;
        uiUtils.updateSelect(ui, opt, false);
    }



    u.getUI = function getUI (idOrItem) {
        if ( $.isString(idOrItem) &&
            idOrItem.startsWith('#') == false) {
            idOrItem = '#' + idOrItem;
        }
        var ui2 = u.cfg.getDiv(idOrItem);
        //var ui2 = $(ui)
        return ui2;
    }

    u.addChange = function addChange(ui, fx, waitOnit) {


        if ( $.isFunction(ui) && fx == null ) {
            fx = ui;
            ui = null
            ui = u.getLast();
        }
        ui = u.getUI(ui)

        if (waitOnit  ) {
            //arguments[2] = false
            u.forwardArgsTo(u.addChange, [ui, fx], 1500);
            return;
        }

//debugger;
        if ( ui.attr('type') == 'radio' ) {
            var jq = 'input[name='+ui.attr('name')+']'
            ui = $(jq)//.val();
            // debugger;
        }


        console.log(ui, 'ok', 'change')

        if ( ui.is('input')) {
            if ( ui.attr('type') == null ) {
                u.onChangeDebounced(ui, onChange)
                return;
            }

        }

        function onChange(a,b,c) {
            console.debug('selected from list', this.value);
            if ( this.value) {
                a = this.value
            }
            u.cid(fx, a,b,c)
        }

        ui.on('change', onChange)

    }

    uiUtils.addImage = function addBtn(cfg, id) {
        cfg = u.cfg.str(cfg, 'src')
        u.cfg.addToCfg(cfg, 'id', id);
        cfg.tag = dv(cfg.tag, 'img');
        //cfg.fxDone = dv(cfg.fxDone, fxD);
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

        var ui = u.tag(cfg.tag)
        ui.attr('src', cfg.src)

        u.addUI(cfg, ui)

        uiUtils.lastUI = ui;
    }

    uiUtils.addClick = function addClick(fxD) {
        uiUtils.lastUI[0].onclick = fxD;
    }
    uiUtils.addTooltip = function addTooltip(title) {
        uiUtils.lastUI.attr('title', title)
    }


    function defineStyles() {
        uiUtils.pad = function addPadding(l, t, r, b) {
            if (l) {
                uiUtils.lastUI.css('padding-left', l + 'px')
            }
            if (t) {
                uiUtils.lastUI.css('padding-top', t + 'px')
            }
            if (b) {
                uiUtils.lastUI.css('padding-right', r + 'px')
            }
            if (r) {
                uiUtils.lastUI.css('padding-bottom', b + 'px')
            }
        }
        uiUtils.wH = function setWidthAndHeight(w, h) {
            if (w) {
                uiUtils.lastUI.css('width', w + 'px')
            }
            if (h) {
                uiUtils.lastUI.css('height', h + 'px')
            }
        }
        uiUtils.color = function color(ui, color) {
            if (color == null) {
                color = ui
                ui = uiUtils.lastUI;
            }

            ui.css('color', color)
        }

        uiUtils.removeWrap = function removeWrap(ui) {
            ui = uiUtils.lastUI;

            ui.css('display', 'display-inline')
        }

        uiUtils.title = function title(title) {
            uiUtils.lastUI.attr('title', title)
        }
        uiUtils.tooltip = uiUtils.title;


        uiUtils.centerVertically = function centerVertically(l, t, r, b) {
            var css = {
                'display': 'flex',
                'flex-direction': 'row',
                'flex-wrap': 'nowrap',
                'justify-content': 'center',
                'align-content': 'center',
                'align-items': 'center'
            }
            uiUtils.lastUI.css(css)
        }
        uiUtils.bg = function setBgColor(l, ui) {
            var ui = uiUtils.lastUI;
            ui.css('background-color', l)
        }

        uiUtils.opacity = function setOpacity(opacity, _ui) {
            var ui = uiUtils.lastUI;
            if (_ui) {
                ui = _ui;
            }
            opacity = opacity.toString();
            if (opacity.startsWith('.')) {
                opaicty = '0' + opacity;
            }
            ui.css('opacity', opacity)
        }

        uiUtils.opac = uiUtils.opacity


        uiUtils.copySize = function copySize(ui1, ui2) {
            ui2.css('width', ui1.css('width'))
            ui2.css('height', ui1.css('height'))
        }
        uiUtils.copyWH = uiUtils.copySize;

        uiUtils.copyXY = function copyXY(ui1, ui2) {
            var position = $(ui1).offset();
            ui2 = $(ui2)
            console.log('position---', position)
            ui2.css(position)
        }

        uiUtils.copyPosition = uiUtils.copyPos
            = uiUtils.copyXY;


        uiUtils.reset = function reset() {
            if (uiUtils.flagCfg) {
                uiUtils.flagCfg.addTo = $('body')
            }
        }
        uiUtils.addRootTemp = function addRootTemp() {
            if (uiUtils.flagCfg) {
                var addTo = uiUtils.flagCfg.addTo;
                uiUtils.flagCfg.addTo = $('body')
            }
            function fxRevert() {
                if (addTo && uiUtils.flagCfg) {
                    uiUtils.flagCfg.addTo = addTo;
                }

            }

            return fxRevert
        }

        uiUtils.addOverlay = function addOverlay(ui, bgColor) {
            var overlay = $('<div/>');
            uiUtils.makeAbs(overlay, true)
            if (bgColor) {
                overlay.css('background', bgColor)
            }

            /*	overlay.css('height', '100%');
             overlay.css('width', '100%');*/
            uiUtils.copyWH(ui, overlay)
            uiUtils.position(overlay, 0, 0)
            //u.opacity(overlay, 0.3)
            overlay.css('opacity', 0.7)
            ui.append(overlay);
        }

    }

    defineStyles();

    uiUtils.br = function addBr(cfg, fxD) {
        cfg = dv(cfg, {})
        cfg = u.cfg.str(cfg, 'text')
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);
        var btn = u.tag('br')
        u.addUI(cfg, btn)
    }


    uiUtils.showTemp = function showTemp(cfg) {
        cfg = dv(cfg, {});
        u.cfg.fixId(cfg);
        div = u.cfg.getDiv(cfg.id);

        div.show()
        u.ifProp(cfg.text, function onSetText(textVal){
            div.text(textVal)
        })

        setTimeout(function onHide(){
            div.hide();
        },2000)
    }


    p.ifProp = function ifProp(val, fx) {
        if ( val != null ) {
            fx(val)
        }
    }




    uiUtils.addWhitespace = function addWhitespace(cfg, fxD) {
        cfg = dv(cfg, {})
        cfg = u.cfg.str(cfg, 'text')
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);
        var ui = u.tag('span')
        ui.html(' ')
        u.addUI(cfg, ui)
    }
    uiUtils.ws = uiUtils.addWhitespace;

    uiUtils.hr = function addBr(cfg, fxD) {
        cfg = dv(cfg, {})
        cfg = u.cfg.str(cfg, 'text')
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);
        var btn = u.tag('hr')
        u.addUI(cfg, btn)
    }

    uiUtils.spacer = function spacer(cfg, fxD) {
        cfg = dv(cfg, {})
        cfg = u.cfg.str(cfg, 'text')
        uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);
        var btn = u.tag('div')
        btn.css('width', '10px')
        if ( cfg.width ) {
            btn.css('width', cfg.width+'px')
        }
        btn.css('display', 'inline-block');
        u.addUI(cfg, btn)
        return cfg
    }
    uiUtils.addSpace = uiUtils.spacer;

    uiUtils.spacerSlim = function spacer(cfg, fxD) {
        var cfg2 = uiUtils.addSpace(cfg, fxD)
        cfg2.ui.css('width', '2px')
        return cfg2
    }


    uiUtils.disable = function disable(id, fxD) {
        $(id).css('opacity', 0.3);
    }

    uiUtils.enable = function enable(id, fxD) {
        $(id).css('opacity', 1);
    }


    uiUtils.styles = {}
    uiUtils.s = uiUtils.styles;

    uiUtils.s.disable = function disable(id, fxD) {
        console.error('disable', id)
        $(id).css('opacity', 0.3);
    }

    uiUtils.s.enable = function enable(id, fxD) {
        console.error('enable', id)
        $(id).css('opacity', 1);
    }


    uiUtils.waitFor = function waitFor(id, fxD, count) {
        var ui = $(id)
        if (ui.length == 0) {
            if (count > 20) {
                console.error('timed out')
                throw new Error('timeoud ')
            }
            count += 1;
            setTimeout(uiUtils.waitFor, 250, id, fxD, count)
            return;
        }

        fxD(ui)
    }


    p.cfg = {};
    p.cfg.str = function ifCfgIsStri(cfg, prop) {
        if ($.isString(cfg)) {
            var _cfg = {};
            _cfg[prop] = cfg;
            cfg = _cfg;
        }
        if (cfg == null) {
            cfg = {};
        }
        return cfg;
    };

    p.cfg.addToCfg = function addToCfg(cfg, prop, val) {
        if (val != null) {
            cfg[prop] = val;
        }
        ;
        return cfg;
    }

    p.cfg.fixId = function fixId(cfg, prop) {
        if ($.isString(cfg.id)) {

            if (cfg.id.includes('#') == false) {
                cfg.id = '#' + cfg.id;
            }

        }
        return cfg;
    }
    p.cfg.getId = function fixId(cfg, propId) {
        if ($.isString(cfg.id)) {
            cfg = cfg.id;
        }

        if ($.isString(cfg)) {
            var baseId = cfg;
            var id = baseId;
            if (baseId.slice(0, 1) == '#') {
                id = baseId.slice(1);
            }
        }

        return id;
    }
    p.cfg.getDiv = function fixId(cfg, propId) {
        if ($.isString(cfg.id)) {
            cfg = cfg.id;
        }
        var div = $(cfg);
        return div;
    }


    p.addUI = function addUI(cfg, ui) {
        if (cfg.addSpacerBefore) {
            u.spacer();
        }

        if (cfg.addTo) {
            if (u.doNotAdd == true) {
                //u.skipNextAdd = false
            }
            else if (u.skipNextAdd == true) {
                u.skipNextAdd = false
            }
            else {
                if (cfg.prepend) {
                    cfg.addTo.prepend(ui)
                } else {
                    cfg.addTo.append(ui)
                }
            }
        }

        if ( u.collector && u.collector.storeUIs === true ) {
            u.collector.list.push(ui)
        }

        if (cfg.addSpacerAfter || cfg.addSpaceAfter) {
            u.spacer()
        }

        if (cfg.defaultValue) {
            ui.val(cfg.defaultValue)
        }
        if (cfg.addClass) {
            ui.addClass(cfg.addClass)
        }
        if (cfg.addStyles) {
            ui.css(cfg.addStyles)
        }

        if (cfg.width) {
            if ($.isNumeric(cfg.width)) {
                cfg.width = cfg.width + 'px';
            }
            ui.css('width', cfg.width);
            //lbl.css('display', 'inline-block');
        }

        if (cfg.id) {
            cfg.jid = cfg.id;
            ui.attr('id', cfg.id);
            cfg.id = '#' + cfg.id;
        }
        if (cfg.tooltip) {
            ui.attr('title', cfg.tooltip)
        }
        if (cfg.title) {
            ui.attr('title', cfg.title)
        }
        if (cfg.html) {
            ui.html(cfg.html)
        }
        cfg.ui = ui;
        u.lastCfg = cfg;
        u.lastUI = ui;
    }
    p.tag = function createTag(type) {
        return $('<' + type + '/>');
    }


    p.lastId = function lastId(type) {
        return u.lastCfg.id;
    }
    p.getLast = function getLast() {
        return u.lastUI;
    }

    function defineBasicMethods() {
        p.enable = function enabled(id) {
            var ui = $(id)
            ui.prop('disabled', false);
            ui.css('opacity', 1);

        }

        p.disable = function disable(id) {
            var ui = $(id)
            ui.prop('disabled', true);
            ui.css('opacity', 0.3);
        }
        p.ifEmpty = function ifEmpty(id, fx) {
            throwIfNull(fx, 'need a function for ' + id)
            var ui = $(id)
            console.log('txt', ui.text(), ui.html())
            if (ui.is('input') && ui.val() == '') {
                fx(ui)
            }
            if (ui.text() == '') {
                fx(ui)
            }
        }

        p.secs = function howManySecodsHavePastSince(a, b, ms) {
            if (b == null) {
                b = new Date();
            }
            var diff = b.getTime() - a.getTime()
            diff = diff / 1000;
            return diff;
        };

        p.getTimestamp = function getTimestamp() {
            var d = new Date();
            d = d.toString()
            d = d.split(' GMT')[0]
            d = d.replace(/ /gi, '_');
            d = d.replace(/:/gi, '-');
            d = '_' + d;
            return d;
        }
        p.getTimestamp2 = function getTimestamp2() {
            var d = new Date();
            var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
                'Oct', 'Nov', 'Dec'];
            var dx = [
                '_'+months[d.getMonth()],
                d.getDay(),
                d.getFullYear(),
                'at',
                d.getHours(),
                d.getMinutes(),
            ].join('_')
            d = d.toString()
            d = d.split(' GMT')[0]
            d = d.replace(/ /gi, '_');
            d = d.replace(/:/gi, '-');
            d = '_' + d;
            return dx;
        }


    }

    defineBasicMethods();

    function defineSetValues() {
        p.setText = function setText(jq, val) {
            var ui = $(jq)
            //console.log('what is ', jq, ui, val)
            if (ui.length == 0) {
                console.warn('cannot set', jq, 'to', val, 'empty query set')
            }
            ui.val(val)
            if (ui.is('span')) {
                ui.text(val)
            }
        }
        uiUtils.setVal2 = function setVal2(id, val, newOptions) {
            var ui = id;
            if ($.isString(id)) {
                if (id.includes('#') == false) {
                    id = '#' + id;
                }
                var ui = $(id);
            }
            if (ui.is('span') || ui.is('div')) {
                return ui.html(val);
            }
            if ( ui.attr('type')=='radio') {
                $('input[name='+ui.attr('name')+']:checked').val(val);
                debugger;
                return val;
            }
            return ui.val(val)
        }



        p.clearText = function clearText(delay, jq) {
            throwIfNull(jq, 'need a jquery for delay');
            delay = dv(3)
            setTimeout(
                function clearText() {
                    uiUtils.setText(jq, '')
                }
                , delay * 1000)
        }

        p.setHtml = function setHtml(jq, val) {
            var ui = $(jq)
            //console.log('what is ', jq, ui, val)
            if (ui.length == 0) {
                console.warn('cannot set', jq, 'to', val, 'empty query set')
            }
            ui.html(val)
        }
        p.glyph = function addGlyphIcon(iconName, val) {
            var iconHTML = '<span class="glyphicon glyphicon-' + iconName + '" aria-hidden="true"></span>'
            var icon = $(iconHTML);
            return icon;
        }

        p.setSelect = function setSelect(jq, vals, keyProp, valProp) {
            var ui = $(jq)

            //debugger

            ui.empty();

            $.each(vals, function addVal(k, v) {
                var option = $("<option />")
                if ($.isString(v)) {
                    var val = v;
                    var key = v;
                }
                if (keyProp) {
                    key = v[keyProp]
                }

                if (valProp) {
                    val = v[valProp]
                }

                option.val(val)
                option.text(key);
                ui.append(option)

            });
        }


        uiUtils.updateSelect = function updateSelect(id, newOptions, empty) {
            var ui = id;

            if ($.isString(id)) {
                if (id.includes('#') == false) {
                    id = '#' + id;
                }

                var ui = $(id)
            }

            if ( empty != false ) {
                ui.empty(); // remove old options
            }
            $.each(newOptions, function (key, value) {

                ui.append($("<option></option>")
                    .attr("value", value).text(key));
            });

        }

        uiUtils.getVal2 = function getVal2(id, newOptions) {
            var ui = id;
            if ($.isString(id)) {
                if (id.includes('#') == false) {
                    id = '#' + id;
                }
                var ui = $(id);
            }
            if (ui.is('span') || ui.is('div')) {
                return ui.html();
            }
            return ui.val()
        }


        uiUtils.later = function later(fx, argumentRest) {
            var args = convertArgumentsToArray(arguments)
            args = args.slice(1)
            function calledLater() {
                fx.apply(fx, args)
            }

            setTimeout(calledLater, 500);
        }
        uiUtils.callMethodRepeat = function callMethodRepeat(fx, secs, obj, prop, fxDone) {
            var cfg = {};
            cfg.fx = fx;
            cfg.secs = secs;
            cfg.obj = obj;
            cfg.prop = prop;
            cfg.fxDone = fxDone;
            cfg.countRepeat = 0;
            function fxRepeatThing(repeat, fxDone) {
                if (cfg.obj && cfg.prop && cfg.obj[cfg.prop] != true) {
                    console.warn('done with this task', cfg.fx.name);
                    return;
                }
                cfg.countRepeat++;
                if (cfg.log != null)
                    console.info('fxRepeatThing', cfg.log, cfg.fx.name, cfg.secs);

                if (repeat) {
                    setTimeout(fxRepeatThing, cfg.secs * 1000, true)
                }

                fx() //(function onSaved(){
                //console.log('autosaved...')
                //})
            }

            fxRepeatThing(true)

            return cfg;
        }


        uiUtils.repeatUntil = function repeatUntil(fxCond, fx2, maxRetry, attemptIndex) {
            //why: use to repeated call fx, until fxCond is true
            //why:for ui elements that are lazily loaded
            var result = fxCond();
            if (result) {
                fx2()
                return;
            }
            if (maxRetry == null) {
                maxRetry = 10;
            }
            if (attemptIndex > maxRetry) {
                console.error('gave up ', 'tried', maxRetry, 'times', attemptIndex)
                return
            }
            if (attemptIndex == null) {
                attemptIndex = 0
            }
            attemptIndex++
            setTimeout(uiUtils.repeatUntil, 500, fxCond, fx2, maxRetry, attemptIndex)
        }

        uiUtils.repeatFxUtils = uiUtils.repeatUntil;

    }

    defineSetValues();


    function defineClickHandler() {
        p.setupclickListener = function setupclickListener(jq, val) {
            function onKeyDown(e) {
                if (e.keyCode == 16) {
                    //alert(e.which + " or Shift was pressed");
                    window.shiftKey = true
                    console.log('keydown')
                }
            }

            function onKeyUp(e) {
                if (e.keyCode == 16) {
                    //alert(e.which + " or Shift was pressed");
                    window.shiftKey = false
                    console.log('keyup')
                }
            }

            $(document).off('keydown', onKeyDown);
            $(document).off('keyup', onKeyUp);

            $(document).keydown(onKeyDown);
            window.onKeyDown = onKeyDown;

            $(document).keyup(onKeyUp);
            window.onKeyUp = onKeyUp;

        }
        //	p.setupclickListener()
    }

    defineClickHandler();

    function defineAnnotationMethods() {
        uiUtils.removeWithClass = function removeWithClass(className) {
            $('.' + className).remove();
        }

        uiUtils.moveAToB = function moveCursorTo(ui, toHere) {
            var element = $(toHere)
            var position = $(element).offset();

            // position.left += element.width();

            if (position == null) {
                console.warn('failed to cursor to ', toHere, 'position was null')
                return;
            }

            //var dbg = [position.left , $('body').width()]
            //debugger;
            if (position.left >= $('body').width() * .80) {
                delete position.left;
                position.right = 20;
                console.log('move on left size')
                //positon.left = $('body').width - 250;
            } else {
                position.left += element.width();
                position.left -= 0.1 * element.width(); //nudge over so inside component
                // position.left -= 10;
            }

            //position.top += 10;

            console.log('where is', ui, position)
            console.log('\t', $(element).offset(), $(element).width())
            //annotation.css(position)

            ui.css(position)
        }

        uiUtils.pos.getPos = uiUtils.getPos = function getPos(ui) {
            if ( ui == null ) {
                throw 'is null'
            }
            var position = $(ui).offset();
            return position;
        }

        uiUtils.pos.getPosL = function getPos(ui) {
            if ( ui == null ) {
                throw 'is null'
            }
            var position = $(ui).position();
            return position;
        }

        uiUtils.pos.setPos = uiUtils.setPos = function getPos(ui, pos, animate) {
            if (animate) {
                $(ui).animate(pos, 1000);
            } else {
                $(ui).offset(pos);
            }
        }

        uiUtils.pos.adjust = function adjust(ui, t, r, b, l) {
            var lefti = ui.css('left');
            lefti = px(lefti)

            function px(pxVal) {
                pxVal = pxVal.replace('px');
                pxVal = parseInt(pxVal);
                return pxVal;
            }


            var topi = ui.css('top');
            topi = px(topi)

            var righti = ui.css('right');
            righti = px(righti)

            var bottomi = ui.css('bottom');
            bottomi = px(bottomi)

            if (l != null) {
                ui.css('left', (lefti + l) + 'px')
            } else {
                if (l === null) {
                    ui.css('left', '')
                }
            }

            if (t != null) {
                console.log(ui.css('top'), (topi + t) + 'px')
                ui.css('top', (topi + t) + 'px')
            } else {
                if (t === null) {
                    ui.css('top', '')
                }
            }

            if (r != null) {
                ui.css('right', (righti + r) + 'px')
            } else {
                if (r === null) {
                    ui.css('right', '')
                }
            }

            if (b != null) {
                ui.css('bottom', (bottomi + b) + 'px')
            } else {
                if (b === null) {
                    ui.css('bottom', '')
                }
            }
        }
        uiUtils.pos.adjust2 = function adjust2(ui, t, r, b, l, animate) {

            function px(pxVal) {
                pxVal = pxVal.replace('px');
                pxVal = parseInt(pxVal);
                return pxVal;
            }


            var lefti = ui.css('left');
            lefti = px(lefti)

            var topi = ui.css('top');
            topi = px(topi)

            var righti = ui.css('right');
            righti = px(righti)

            var bottomi = ui.css('bottom');
            bottomi = px(bottomi)


            var finalPos = {};
            function getPxVal(prop, start, add) {
                var valFinal = null
                if (add != null) {
                    valFinal = (start + add) + 'px'
                } else {
                    if (add === null) {
                        valFinal = ''
                    }
                }
                finalPos[prop] = valFinal
            }



            getPxVal('left', lefti, l)
            getPxVal('top', topi, t)
            getPxVal('bottom', bottomi, b)
            getPxVal('right', righti, r)

            //console.log(finalPos, t,r, righti)

            if (animate) {
                if ( $.isNumeric(animate)) {
                    duration = animate;
                } else {
                    duration = 200
                }

                $(ui).animate(finalPos, duration);
            } else {
                $(ui).offset(finalPos);
            }
        }

        uiUtils.percentChance = function percentChance(percent, fx) {
            if ( Math.random() < percent/100 )
                fx()
        }
    }

    defineAnnotationMethods();

    p.utils = {};
    p.utils.mergeIn = function mergeIn(a, b, overwriteVals) {
        if (a == null) {
            return
        }
        if (b == null) {
            return
        }
        //function copyProps(from, to) {
        $.each(a, function (k, v) {
            var existingVal = b[k];
            if (existingVal && overwriteVals !== true) {
                return;
            }
            b[k] = v;
        });
        //	}
    }


    p.utils.addIfDoesStartWith = function addIfDoesStartWith(u, strStrasWith) {
        var charStr = u.slice(0, 1);

        if (charStr == strStrasWith) {
            return u
        }

        return strStrasWith + u;
    }

    p.utils.loadScripts = function loadScripts(listScripts, fxDone) {
        var loadScript2 = function loadScript2(_scripts2, preamble) {
            if (_scripts2.length == 0) {
                console.log('finished');
                callIfDefined(fxDone)
                return;
            }
            var url = _scripts2.shift();
            if (preamble == null) {
                preamble = '';
            }
            url = preamble + url;
            jQuery.getScript(url)
                .done(function () {
                })
                .always(function doneLoadingFile() {
                    loadScript2(_scripts2);
                })
                .fail(function (a, b, c, d) {
                    console.error('failed to load', url, a == null, b, c, d);
                    console.error(c.stack)
                });
        }

        if ($.isString(listScripts)) {
            listScripts = [listScripts]
        }
        loadScript2(listScripts)

    }
    p.utils.loadScript = p.utils.loadScripts;


    p.utils.getParams = function getParams() {
        function getQueryObj() {
            var query_string = {};
            //console.debug('search', window.location.search);
            var query = window.location.search.substring(1);
            if (query == '' && window.location.hash.indexOf('?') != 0) {
                query = window.location.hash.split('?')[1];
            }
            if (query == null) {
                return {};
            }
            var vars = query.split("&");
            for (var i = 0; i < vars.length; i++) {
                var pair = vars[i].split("=");
                // If first entry with this name
                if (typeof query_string[pair[0]] === "undefined") {
                    query_string[pair[0]] = decodeURIComponent(pair[1]);
                    // If second entry with this name
                } else if (typeof query_string[pair[0]] === "string") {
                    var arr = [query_string[pair[0]], decodeURIComponent(pair[1])];
                    query_string[pair[0]] = arr;
                    // If third or later entry with this name
                } else {
                    query_string[pair[0]].push(decodeURIComponent(pair[1]));
                }
            }
            return query_string;
        };

        var params = getQueryObj();
        self.utils.params = params;
        return params;
    }

    uiUtils.isSimiliarInArray = function isSimiliarInArray(prop, obj, items) {
        var found = null;
        var foundItem = null;
        var likeVal = obj[prop];
        $.each(items, function findSimiliar(k, v) {
            var val = v[prop];
            if (val == likeVal) {
                foundItem = v;
                found = true;
                return false;
            }
        })

        return found;
    }

    function defineEffects() {
        uiUtils.fadeIn = function fadeIn(_ui, duration) {
            var cfg = {ui: _ui, duration: duration}
            if (_ui.length == null) {
                var cfg = _ui;
            }
            cfg.ui.show();
            cfg.ui.css('opacity', 0.0)
            cfg.duration = u.dv(cfg.duration, 600);
            cfg.opacity = u.dv(cfg.opacity, 1.0);

            $(cfg.ui).animate({
                    opacity: cfg.opacity
                },
                {
                    duration: duration,
                    complete: function onEnd() {
                        // _ui.hide();
                    }
                });
            //}
            console.error('fade in')
        }


        uiUtils.fadeOut = function fadeOut(_ui) {
            //function onHoverOut() {
            // debugger

            $(_ui).clearQueue();
            $(_ui).stop(true, true);
            $(_ui).animate({
                    opacity: 0.0
                },
                {
                    duration: 300,
                    complete: function onEnd() {
                        _ui.hide();
                    }
                }
            );
            console.error('fadeOut', _ui)
            //}
        }


        uiUtils.beatFade = function beatFade(_ui) {
            var startingOpacity = _ui.css('opacity');
            if (startingOpacity == null || startingOpacity == '') {
                startingOpacity = 1;
            }
            startingOpacity = 1;
            // console.error('starting', startingOpacity)
            $(_ui).clearQueue();
            $(_ui).stop(true, true);
            setTimeout(function out() {
                console.error('go to ', 0.7)
                $(_ui).animate({
                    opacity: 0.7
                }, 500);
            }, 0)

            setTimeout(function beatIn() {
                console.error('go to ', 1)
                $(_ui).animate({
                    opacity: startingOpacity
                }, 500);
            }, 500)
        }

    }

    defineEffects();

    function defineUrlMethods() {
        p.inUrl = function inUrl(dlg) {
            if (window.location.search.indexOf(dlg) != -1) {
                return true;
            }
            if (window.location.hash &&
                window.location.hash.indexOf(dlg) != -1) {
                return true;
            }
            return false;
        }

        p.reload = function reload(dlg) {
            window.location.reload();
        }

        p.addToUrl = function addToUrl(key, val, doNotSetIfValIsNull) {
            /*
             1: hash is present
             2: ? is present ... so parse vars
             3: var alreayd exists
             */

            var params = uiUtils.utils.getParams();

            var dbg = false;
            //dbg = true
            if (dbg)
                console.debug('addToUrl', 'params', window.location.hash,
                    window.location.search, params)
            if (val) {
                val = val.toString()
            }
            if (params[key] == val) {
                return;
            }
            if (doNotSetIfValIsNull && val == null) {
                console.debug('did not set val', key, 'val is null')
                return;
            }

            params[key] = val;
            if (val == null) {
                delete params[key]
            }
            ;

            var str = jQuery.param(params);

            var hash = window.location.hash;
            var urlFinal = '';
            urlFinal = location.href
            if (urlFinal.includes('?')) {
                urlFinal = urlFinal.split('?')[0];
            }
            if (urlFinal.includes('#')) {
                urlFinal = urlFinal.split('#')[0];
            }
            if (dbg)
                console.debug('addToUrl', 'start', urlFinal)
            var isEmptyHash = hash.slice(0, 2) == '#?';
            if (dbg)
                console.debug('addToUrl', 'hash', hash)
            if (isEmptyHash) {
                //urlFinal +=  ''
                urlFinal += '#'
            } else if (hash != '') {
                var hashOnly = hash;
                if (hashOnly.includes('?')) {
                    hashOnly = hashOnly.split('?')[0];
                }
                urlFinal += hashOnly;
            } else {
                urlFinal += '#'//'empty has to prevent reload
            }
            urlFinal += '?' + str;
            document.location = urlFinal
            if (dbg) {
                console.debug('addToUrl', urlFinal, document.location, window.location.search)
            }
            if (dbg) {
                console.debug('addToUrl', 'endwith', urlFinal)
            }
        }

        p.setUrlVal = p.addToUrl;

        p.getUrlVal = function getUrlVal(val) {
            var params = uiUtils.utils.getParams();
            var val = params[val]
            return val;
        }


        p.getSearch = function getSearchParam() {
            var urlFinal = location.href;
            if (urlFinal.includes('?') == false) {
                return null;
            }
            if (urlFinal.includes('#')) {
                urlFinal = urlFinal.split('#')[1];
            }
            if (urlFinal.includes('?')) {
                urlFinal = urlFinal.split('?')[1];
            }
            //console.log('getSearch', urlFinal)
            //if ? is before # warn user ...
            return urlFinal;
        }


        p.getHash = function getHash() {
            //why: get has only, not the search
            var urlFinal = location.href;
            if (urlFinal.includes('#') == false) {
                return null;
            }
            //if ( urlFinal.includes('#')) {
            urlFinal = urlFinal.split('#')[1];
            //	}
            if (urlFinal.includes('?')) {
                urlFinal = urlFinal.split('?')[0];
            }
            // console.log('getHash', urlFinal)
            return urlFinal;
        }


        p.getUrlVar = function getUrlVar() {
            var urlFinal = location.href;
            if (urlFinal.includes('#')) {
                urlFinal = urlFinal.split('#')[0];
            }
            if (urlFinal.includes('?')) {
                urlFinal = urlFinal.split('?')[0];
            }
            //console.log('getUrlVar', urlFinal)
            //if ? is before # warn user ...
            return urlFinal;
        }

        p.setHash = function setHash(hash) {
            var urlX = window.location.href;
            hash = uiUtils.utils.addIfDoesStartWith(hash, '#')
            var url = self.getUrlVar()
                + hash;
            var search = self.getSearch();
            var params = uiUtils.utils.getParams();
            var str = jQuery.param(params);
            if (str) {
                url += '?' + str
            }
            var debug = false;
            if (debug) {
                console.error('starting', urlX);
                console.error('setting hash to', hash, url);
            }
            //debugger
            /*if ( self.getSearch() ) {
             url += '?'+self.getSearch()
             }*/

            window.location.href = url;
            if (debug) {
                console.error('end', window.location.href);
            }

        }


    }

    defineUrlMethods();


    function defineUI() {
        p.utils.loadPage = function loadPage(cfg) {
            var div = $(cfg.div)
            if (div && div.empty() && cfg.id) {
                //var id = cfg.id;
                if (cfg.id.startsWith('#') == false) {
                    cfg.id = '#' + cfg.id;
                }
                div = u.cfg.getDiv(cfg.id);
            }
            if (div.length == 0) {
                throw new Error('could not find area ' + cfg.div);
            }
            //debugger
            $.ajax({
                url: cfg.url,
                datattype: "html",
                //data: data,
                success: function (data) {

                    var output = p.utils.parseBodyHTML(data);

                    //debugger;
                    div.html(output.body.html());

                    output.addStyles();

                    cfg.ui = div;

                    callIfDefined(cfg.fxDone, data, output.body)
                },
                error: function (a, b, c) {
                    //debugger;
                    console.error('cannot get loadPage info');
                    uiUtils.remoteFailed(a, b, c)
                }
            });
        }


        uiUtils.remoteFailed = function remoteFailed(a, b, c) {
            console.error(a, b, c)
            debugger
        }


        p.utils.parseBodyHTML = function parseBodyHTML(d) {
            // replace the `HTML` tags with `NOTHTML` tags
            // and the `BODY` tags with `NOTBODY` tags
            d = d.replace(/(<\/?)html( .+?)?>/gi, '$1NOTHTML$2>', d);
            d = d.replace(/(<\/?)body( .+?)?>/gi, '$1NOTBODY$2>', d);
            // select the `notbody` tag and log for testing
            //console.log($(d).find('notbody').html())
            var output = {};

            output.raw = d;
            output.jquery = $(d);
            output.body = $(d).find('notbody');
            output.html = $(d).find('nothml');
            output.style = $(d).find('style')

            output.addStyles = function addHtmlTo(div) {
                $('head').append(output.style)
            }

            return output;
        }
    }

    defineUI()
    p.makeUIDict = function makeUIDict(name, why) {
        function UIDict() {
            //why: stores many ui items for action on later
            var self = this;
            var p = this;

            self.data = {};
            self.data.name = name;
            self.data.why = why;
            self.data.data = {};

            p.addUI = function addUI(why, ui) {
                var uiData = {}
                uiData.why = why;
                uiData.ui = ui;
                if (ui == null) {
                    uiData.ui = uiUtils.getLastId()
                }
                dict.data.push(uiData)
            }

            p.addUI2 = function addUI2(why, ui) {
                dict.data
            }

            p.getAllUI = function getAllUI() {
                var results = [];
                $.each(self.data, function onAdd(k, v) {
                    var ui2 = ui.ui;
                    if ($.isString(ui2)) {
                        ui2 = $(ui2)
                    }
                    results.push(ui2)
                })

                return results;
            }
        }

        var dict = new UIDict()
        return dict

    }

    p.t = function setTimeoutShorten() {
        var args = convertArgumentsToArray(arguments);
        if (args.length == 1)
            args.push(500);
        //debugger
        setTimeout.apply(null, args)
    }


    function defineComparison() {
        p.utils.copyStyles = function copyStyles(from, to) {
            //console.info('copy the thing', from.text())
            var styleList = ['fontFamily', 'fontSize',
                //	'transform',
                'color', 'fontStyle', 'fontWeight']
            $.each(styleList, function copyProp(k, v) {
                var val = from.css(v)
                to.css(v, val);
                //console.info('copy prop', v, val)
            })
            var prop = 'origFont';
            to.attr(prop, from.attr(prop))
        }

        p.utils.stylesDifferent = function stylesDifferent(a, b, dbg) {
            var styleList = ['fontFamily', 'fontSize',
                //	'transform',
                'color', 'fontStyle', 'fontWeight'];
            var equal = true
            $.each(styleList, function copyProp(k, v) {
                var val = a.css(v);
                var valB = b.css(v)
                if (val != valB) {
                    equal = false;
                    if (dbg) {
                        console.info('failed on', v, val, valB, b.text())
                        //debugger;
                    }
                    return false
                }
            })
            var prop = 'origFont';
            var val = a.attr(prop);
            var valB = b.attr(prop);
            //console.info('origFont', prop, val, valB, val != valB)
            if (equal == true && val != valB) {
                equal = false;
                if (dbg) {
                    console.info('failed on origFont', prop, val, valB, b.text());
                }
            }
            return !equal;
        }
    }

    defineComparison();

    function defineUrl() {
        p.getContentAfter = function getContentAfter(url, findStr) {
            if ( url.includes(findStr)) {
                var output = url.split(findStr)[1]
                return output;
            }
            return url;
        }

        p.getContentBefore = function getContentBefore(url, findStr) {
            if ( url.includes(findStr)) {
                var output = url.split(findStr)[0]
                return output;
            }
            return url;
        }

        p.getHostname = function getHostname(url) {
            var urlOrig = url;

            //debugger
            var hostname = u.getContentAfter(url, "://")
            hostname = u.getContentBefore(hostname, '/')
            hostname = u.getContentBefore(hostname, ':')

            return hostname;
        }

        p.getLocation = function getLocation(path, port, overrideBaseurl) {
            if (path.startsWith('/') == false) {
                path = '/' + path;
            }
            if (port == null) {
                port = ''
            } else {
                port = ':' + port
            }
            var baseUrl = 'http://' + window.location.hostname;
            if (overrideBaseurl) {
                baseUrl = 'http://' + u.getHostname(overrideBaseurl)
            }
            var url = baseUrl + port
                + path;
            return url;
        }
        p.getUrl = function getUrl(url, data, fxDone, fxError) {
            if ($.isFunction(data) && $.isPlainObject(fxDone)) {
                //criss cross
                var _fxDone = data;
                data = fxDone;
                fxDone = _fxDone;
            }

            if ($.isFunction(data)) {
                fxDone = data;
            }

            //console.log('data', data)

            $.ajax({
                url: url,
                data: data,
                success: function (data) {
                    callIfDefined(fxDone, data)
                },
                error: function (a, b, c) {
                    console.error(url, 'request failed', a, b, c)
                    //gUtils.remoteFailed(a,b,c)
                    callIfDefined(fxError, a, b, c, url)
                }
            });
        }

        p.postUrl = function postUrl(url, data, fxDone) {
            if ($.isFunction(data)) {
                fxDone = data;
            }

            $.ajax({
                url: url,
                type: 'post',
                data: data,
                success: function (data) {
                    callIfDefined(fxDone, data)
                },
                error: function (a, b, c) {
                    console.error('request failed', a, b, c)
                    //gUtils.remoteFailed(a,b,c)
                }
            });
        }

        p.openNewWindow = function openNewWindow(url) {
            window.open(url, 'status', "height=200,width=200");

            return;
            var win = window.open(url, '_blank');
            win.focus();
        }

        p.utils.getR = p.getUrl;
        p.utils.postR = p.postUrl;
    }

    defineUrl();

    function defineCookies() {
        p.getVal = function getVal(key) {
            var val = localStorage.getItem(key)
            var json = JSON.parse(val);
            return json
        }

        p.setVal = function setVal(key, val) {
            var json = JSON.stringify(val)
            localStorage.setItem(key, json)
        }
    }

    defineCookies();


    function defineFX() {
        u.onChangeDebounced = function onChangeDebounced(jquery, fx, time) {
            if (time == null) time = 500;

            var ui = $(jquery);
            //console.log('sdf', jquery, ui.length);
            if (ui.length == 0) {
                throw new Error(['not found', jquery].join(' '))
            }


            var d = {}
            d.debounce = function debounce(fx) {
                if (d.waiting) {
                    clearTimeout(d.waiting)
                }
                //console.log('waiting', fx.name)
                //d.waiting = true;
                d.waiting = setTimeout(function onDebounced() {
                    fx(ui.val(), ui)
                }, time)
            }

            ui.keyup(function onKeyUp(e) {

                //console.log('keyup', e)
                d.debounce(fx, time)
                //startWaiting()

            });
        }

    }

    defineFX();
    u.debouncer = function debouncer(fx, name, time) {
        //if ( time )
        var d = {}
        d.debounce = function debounce(fx2) {
            if (d.waiting) {
                clearTimeout(d.waiting)
            }
            //console.log('waiting', fx.name)
            //d.waiting = true;
            d.waiting = setTimeout(function onDebounced() {
                if (fx2) {
                    fx2();
                    return;
                }
                fx()
            }, time)
        }
        return d;
    }


    function defineDebounce() {
        uiUtils.debounce = null;
        uiUtils.debouncers = null;

        uiUtils.debounce = function onDeb(cfg) {
            if (uiUtils.debouncers == null) {
                uiUtils.debouncers = {};
            }

            var dbg = false;
            var d = uiUtils.debouncers[cfg.name];

            if (cfg.time == null) {
                cfg.time = 1500
            }

            if (d == null) {
                d = {};
                d.waitCount = 0;
                if (dbg)
                    console.info('defined a new one')
                d.debounce = function debounceHandler() {
                    d.waitCount++;
                    var waitCountTmp = d.waitCount;
                    cfg.waiting = d.waitCount + '_' + Math.random();
                    if (dbg)
                        console.log('waiting', cfg.fx.name, d.waitCount)
                    //d.waiting = true;
                    setTimeout(function onDebounced() {
                        if (d.waitCount == waitCountTmp) {
                        } else {
                            if (dbg)
                                console.warn('missed it', waitCountTmp, d.waitCount, d.waiting)
                            return;
                        }
                        d.waiting = null;
                        cfg.fx(cfg.args)
                    }, cfg.time)

                }
            }

            uiUtils.debouncers[cfg.name] = d;

            d.debounce()
        }

        uiUtils.debounceOld =
            function debounce(func, wait, immediate) {
                var timeout;
                return function() {
                    var context = this, args = arguments;
                    var later = function() {
                        timeout = null;
                        if (!immediate) func.apply(context, args);
                    };
                    var callNow = immediate && !timeout;
                    clearTimeout(timeout);
                    timeout = setTimeout(later, wait);
                    if (callNow) func.apply(context, args);
                };
            };

    }

    defineDebounce();

    function ifHelpers() {
        u.ifFxReplace = function ifFxReplace(potFx, fxShoudlBeNull) {
            if ($.isFunction(potFx) && fxShoudlBeNull) {
                return potFx;
            }
            return fxShoudlBeNull;
        }
    }

    ifHelpers()


    p.fadeInOnHover = function fadeInOnHover(ui) {
        $(ui).css('opacity', 0.0)
        $(ui).hover(
            function onHover() {
                $(ui).animate({
                    opacity: 1
                }, 300);
                //console.log('fade in')
            },
            function onHoverOut() {
                $(ui).animate({
                    opacity: 0.0
                }, 300);
            }
        );
    }

    function defineAppendHelperMethods() {

        uiUtils.clear = function clearHTLM(jq) {
            $(jq).html('')
        }
        uiUtils.addTo = function setLastUI(jq) {
            var ui = $(jq);
            //uiUtils.lastUI =   $(jq);
            //uiUtils.flagCfg.lastAddTo = cfg.addTo
            uiUtils.flagCfg.addTo = ui;
        }

        uiUtils.addToLast = function addToLast() {
            uiUtils.flagCfg.addTo = uiUtils.lastUI;
        }

        uiUtils.setId = function setId(id) {
            uiUtils.lastUI.attr('id', id)
        }
    }

    defineAppendHelperMethods();


    function defineLookAt() {
        var gUtils = uiUtils
        gUtils.setLocationHash = function setLocationHash(newHashVal) {
            setTimeout(function setLocationLater() {
                //window.location.hash = e;// '#listDialog';
                uiUtils.setHash(newHashVal);
            }, 0);
        }
        gUtils.setFocus = function setFocus(e) {
            setTimeout(function setFocus() {
                $(e).focus();
            }, 0);
        }
        gUtils.hide = function hide(jq) {
            $(jq).hide()
        }
        gUtils.show = function show(jq) {
            $(jq).show()
        }
        gUtils.ifShow = function show(exp, jq) {
            if (exp) {
                //console.error('addi', exp, 'show')
                $(jq).show();
            } else {
                //	console.error('addi', exp, 'hide')
                $(jq).hide();
            }
        }
        gUtils.ifHide = function ifExpIsTrueHide(exp, jq) {
            gUtils.ifShow(!exp, jq);
        }
        gUtils.off = function off(jq) {
            $(jq).off()
        }
        gUtils.offChildren = function offChildren(jq) {
            $(jq).off()
            $(jq).find('*').off()
        }

        gUtils.addToken = function addToken(jq) {
            if (jq == null) {
                return
            }
            var uiHolder = $(jq);
            uiHolder.html('');
            var token = uiUtils.tag('span');
            token.attr('id', uiHolder.attr('id') + 'Token');
            uiHolder.append(token);
        }

        gUtils.lorem = function lorem() {
            var times = 150
            var txt = ''
            var things = ['Rock', 'Paper', 'Scissor'];
            for (var i = 0; i < times; i++) {
                var word = things[Math.floor(Math.random() * things.length)];
                txt += word + ' ';
            }
            return txt;
        }


        gUtils.onEnter = function onenter(jquery, fx) {
            $(jquery).keypress(function (e) {
                if (e.which == 13) {//Enter key pressed
                    fx();
                }
            });
        }
        gUtils.onClick = function onClick(jquery, fx, gY) {

            throwIfNull(fx, 'need a function for ' + jquery)
            throwIfNull(jquery, 'need a jquery for ' + jquery, fx.name)
            $(jquery).click(function onClick(e) {
                fx();
            });
        }
        gUtils.makeBtn = function onClick(jquery, tooltip) {
            $(jquery).attr('title', tooltip);
            $(jquery).css('cursor', 'pointer')
        }
        gUtils.makeRolloverPopup = function makeRolloverPopup(yyy, yy, btnHoverClass) {
            var h = {}
            h.dialog = yy;
            h.dropdown = h.dd = yy;
            h.btnTrigger = yyy;
            yyy.on('mouseenter', function onMouseOver() {
                h.mouseOverBtn = true;
                if (btnHoverClass)
                    h.btnTrigger.addClass(btnHoverClass);
                yy.show();
            })

            yyy.on('mouseleave', function onMouseOut(delayed) {
                h.mouseOverBtn = false;
                if (delayed != true) {
                    setTimeout(onMouseOut, 500, true)
                    return;
                }
                if (h.mouseOverDialog == true) {
                    return;
                }
                if (btnHoverClass)
                    h.btnTrigger.removeClass(btnHoverClass);
                yy.hide();
            })

            yy.on('mouseenter', function onMouseOverDropDown() {
                h.mouseOverDialog = true;
            })

            yy.on('mouseleave', function onMouseOverDropDown() {
                h.mouseOverDialog = false;
                if (h.mouseOverBtn == false) {
                    h.dropdown.hide();
                    if (btnHoverClass)
                        h.btnTrigger.removeClass(btnHoverClass);
                }
            })


            yy.hide();
        }


        gUtils.makeRolloverPopup2 = function makeRolloverPopup2(uiHoverInit, yy, btnHoverClass) {
            var h = {}
            h.dialog = yy;
            h.dropdown = h.dd = yy;
            h.btnTrigger = uiHoverInit;
            var closeOrig = false;
            uiHoverInit.on('mouseenter', function onMouseOver() {
                h.mouseOverBtn = true;
                if (btnHoverClass)
                    h.btnTrigger.addClass(btnHoverClass);
                if (closeOrig) {
                    yy.show();
                }
            })

            uiHoverInit.on('mouseleave', function onMouseOut(delayed) {
                h.mouseOverBtn = false;
                if (delayed != true) {
                    setTimeout(onMouseOut, 500, true)
                    return;
                }
                if (h.mouseOverDialog == true) {
                    return;
                }
                if (closeOrig) {
                    if (btnHoverClass)
                        h.btnTrigger.removeClass(btnHoverClass);
                    yy.hide();
                }
            })

            yy.on('mouseenter', function onMouseOverDropDown() {
                h.mouseOverDialog = true;
            })

            yy.on('mouseleave', function onMouseOverDropDown() {
                h.mouseOverDialog = false;
                if (h.mouseOverBtn == false) {
                    h.dropdown.hide();
                    if (btnHoverClass)
                        h.btnTrigger.removeClass(btnHoverClass);
                }
            })


            yy.hide();
        }


        uiUtils.toggleContainer = function toggleContainer(jq) {
            var ui = $(jq)
            if (ui.hasClass('hide')) {
                ui.removeClass('hide')
            } else {
                ui.addClass('hide')
            }
        }


        uiUtils.putToLeftOfLastDialog = function putToLeftOfLastDialog(ui, ui2) {
            if (ui == null) {
                var overrideOffset = {top: 60, left: 20};
                ui = $('<div />');
            }
            if (ui2 == null)
                return;
            if (uiUtils.putToLeftOfLastDialog.rowMaxHeight == null) {
                uiUtils.putToLeftOfLastDialog.rowMaxHeight = 0;
            }

            var position = $(ui).offset();
            if (overrideOffset) {
                position = overrideOffset;
            }
            position.left += 10;
            // position.top += 6
            //   debugger;
            position.left += ui.width();
            if (position.left + ui2.width() > $('body').width() - 50) {

                position.top += uiUtils.putToLeftOfLastDialog.rowMaxHeight
                uiUtils.putToLeftOfLastDialog.rowMaxHeight = 0
                console.log('\t', 'put new row', position.top, uiUtils.putToLeftOfLastDialog.rowMaxHeight)
                position.left = 0;
            }

            if (ui2.height() > uiUtils.putToLeftOfLastDialog.rowMaxHeight) {
                uiUtils.putToLeftOfLastDialog.rowMaxHeight = ui2.height();
            }

            console.log('put', ui.attr('id'), '--', ui2.attr('id'), position, uiUtils.putToLeftOfLastDialog.rowMaxHeight)
            ui2.css(position)
        }
    }

    defineLookAt();


    function defineSockets() {
        uiUtils.socket = {};
        uiUtils.socket.dict = {};
        uiUtils.socket.nextEmit = function nextEmit(t) {
            uiUtils.socket.nextEmitter = t;
        }

        uiUtils.socket.emit =
            uiUtils.socket.emitAndCatchResult = function emitAndCatchResult(msg, data, fxDone) {

                self.data.socket.emit(msg, data)
                var key = null;
                if (key == null && uiUtils.socket.nextEmitter != null) {
                    key = uiUtils.socket.nextEmitter
                }
                var existingListener = uiUtils.socket.dict[key];
                if (existingListener != null) {
                    console.warn('u already set this ...')
                    return; //skip ...
                }
                uiUtils.socket.dict[key] = fxDone;
                console.info('g-catching', data.cmd)
                self.data.socket.on(data.cmd + '_results', function _onResults(msg) {
                    console.info('g-catching', 'result', msg);
                    fxDone(msg)

                })

            }

        if ( typeof sh === 'undefined') {
            sh = u;
        }
        uiUtils.socket.emitOne = function emitOne(msgType, data, fxDone) {
            /*
             create one time lsiter, clear when done if dual exists show an error and remove
             */
            sh.throwIfNull(fxDone,'need a callback')
            sh.throwIfNull(data.cmd, 'need a cmd for result')
            uiUtils.socket.dictEmitOne = sh.dv(uiUtils.socket.dictEmitOne, {})
            self.data.socket.emit(msgType, data);
            var typeResult = data.cmd + '_results'
            var lastOne = uiUtils.socket.dictEmitOne[typeResult]


            var fxName = '\t'+'emitOne'

            if ( lastOne ) {
                console.warn(fxName, 'failed on last one removing')
                uiUtils.socket.off(typeResult)
                uiUtils.socket.dictEmitOne[typeResult] = null;
            }
            console.info(fxName, 'send', msgType, sh.paren(typeResult) )
            self.data.socket.on(typeResult, function _onResults(result) {
                console.info(fxName, 'result', result);
                fxDone(result)
                //u.cid(fxDone, result)
                self.data.socket.removeListener(typeResult)
                uiUtils.socket.dictEmitOne[typeResult] = null;
            })



            return;


            var key = null;
            if (key == null && uiUtils.socket.nextEmitter != null) {
                key = uiUtils.socket.nextEmitter
            }
            var existingListener = uiUtils.socket.dict[key];
            if (existingListener != null) {
                console.warn('u already set this ...')
                return; //skip ...
            }
            uiUtils.socket.dict[key] = fxDone;
            console.info('g-catching', data.cmd)
            self.data.socket.on(data.cmd + '_results', function _onResults(msg) {
                console.info('g-catching', 'result', msg);
                fxDone(msg)

            })

        }

        uiUtils.socket.addListener = function addListener(type, fxDone, retryCount) {
            if (self.data.socket == null) {
                if (retryCount == null) {
                    retryCount = 0;
                }
                if (retryCount > 10) {
                    console.error('failed to ', this.name, type, fxDone)
                }
                setTimeout(function onRetry() {
                    retryCount++
                    addListener(type, fxDone, retryCount)
                }, 500);
                return;
            }
            self.data.socket.on(type, function _onResults(data) {
                //console.log('msg', msg);
                fxDone(data)

            })

        }
    }

    defineSockets();


    uiUtils.makeDict = function makeDict(arr, prop) {
        var dict = {};
        $.each(arr, function n(k, v) {
            var val = v[prop]
            dict[val] = v;
        })
        return dict;
    }
    uiUtils.socket.upgradeSocket = function upgradeSocket(socket) {
        socket.emit2 = function emit(msg, data, fxDone) {
            socket.emit(msg, data)
            var key = null;
            if (key == null && uiUtils.socket.nextEmitter != null) {
                key = uiUtils.socket.nextEmitter
            }
            var existingListener = uiUtils.socket.dict[key];
            if (existingListener != null) {
                console.warn('u already set this ...')
                return; //skip ...
            }


            //debugger
            uiUtils.socket.dict[key] = fxDone;
            socket.on(data.cmd + '_results', function _onResults(msg) {
                console.log('msg', msg);
                fxDone(msg)

            })

        }

        socket.addListener2 = function addListener(type, fxDone, retryCount) {
            if (socket == null) {
                if (retryCount == null) {
                    retryCount = 0;
                }
                if (retryCount > 10) {
                    console.error('failed to ', this.name, type, fxDone)
                }
                setTimeout(function onRetry() {
                    retryCount++
                    addListener(type, fxDone, retryCount)
                }, 500);
                return;
            }
            socket.on(type, function _onResults(data) {
                //console.log('msg', msg);
                fxDone(data)

            })

        }


        uiUtils.waitForComp = function waitForComp(id, fx, args) {
            var args = convertArgumentsToArray(args);
            ui = $(id)
            console.log('waitforcomp')
            if (ui.length == 0) {
                setTimeout(function onRetry() {
                    console.log('onRetry')
                    //retryCount++
                    //addListener(type, fxDone, retryCount)
                    forwardArgsTo(fx, args);
                }, 500);
                console.log('ui.length')
                return true
            }
            console.log('waitForComp')
            return false
        }


        socket.listenForStatus = function listenForStatus(divId, fxDone, retryCount, type) {
            var h = {};

            divId = '#' + divId;
            socket.divId = divId;
            var ui = $(divId)

            if (uiUtils.waitForComp(divId, socket.asdf, arguments)) {
                console.log('block')
                return;
            }

            console.log('ok.l')
            var msg = u.tag('ui')
            msg.attr('id', 'messages')
            ui.append(msg)

            uiUtils.makeScrollable(ui, 70)


            console.log('listening to', socket)
            socket.on('updateStatus', function onRecieveStatusMsg(data) {
                /*if (msg.indexOf('eval-')==0) {
                 msg = msg.replace('eval-', '')
                 eval(msg);
                 }*/

                var scrollContainer = $(divId)
                var ui = scrollContainer.find('#messages')
                var li = $('<li>').text(data.msg)
                ui.append(li);
                console.log('chat', data, li, ui)
                uiUtils.scrollToBottom(scrollContainer);
            });

        }


        socket.updateStatus = function updateStatus(txt) {

            var args = convertArgumentsToArray(arguments)
            txt = args.join(' ')

            var divId = socket.divId


            var scrollContainer = $(divId)
            var ui = scrollContainer.find('#messages')
            var li = $('<li>').text(txt)
            ui.append(li);
            //console.log('chat', txt, li, ui)
            uiUtils.scrollToBottom(scrollContainer);

        }
    }




    function defineCC() {
        function BasicClass() {
            var p = BasicClass.prototype;
            p = this;
            var self = this;
            p.method1 = function method1(url, appCode) {
            }

            p.proc = function debugLogger() {
                if ( self.silent == true) {
                    return
                }
                sh.sLog(arguments)
            }


        }

        //debugger
        u.collector = {};
        u.collector.start = function start() {
            u.collector.list = []
            u.collector.storeUIs = true;
        }


        u.collector.stop = function stop() {
            u.collector.storeUIs = false;
            return u.collector.list
        }
    }
    defineCC();

    uiUtils.debug =
        uiUtils.dbg = function  bg(txt, obj) {
            console.debug('dbg', txt)
            $.each(obj, function onX(k,v) {
                console.debug('\t', k,v)
            });

        }

    uiUtils.ripProps = function ripProps(ui){

        var dbg = false;
        if ( dbg ) {

        }
        var children = $(ui).find('*')
        //debugger
        var props = {};
        $.each(children, function on(k,v){
            var ui = $(v)
            var val = ui.val();
            var valText = val;
            var text = ui.text();
            if (text) {
                val = text;
            }
            var id = ui.attr('id');
            if ( ui.is('button')) {
                return;
            }
            //console.debug('...dbg', ui, text, valText)
            if ( id == null ) {
                if ( dbg )
                    console.debug('no id', id)
                return;
            }
            if ( val == null ) {
                if ( dbg )
                    console.debug('val', ui.attr('id'), val)
                return;
            }
            //debugger
            if ( dbg )
                console.debug('val', ui.attr('id'), val)
            props[id] = val;
        })



        // uiUtils.dbg(props)
        uiUtils.debug('db', props)


        return props;
    }


    uiUtils.ripPropsSet = function ripPropsSet(rippedProps){
        var dbg = false;
        if ( dbg ) {

        }
        var props = {};
        $.each(rippedProps, function on(id,v){
            var ui = $('#'+id)
            ui.val(v);
            //ui.text(v);
            return;
        })
    }


    uiUtils.setTextSD = function setSelDestructingMessage(txt, msg) {
        uiUtils.setText(txt , msg);
        //self.data.lastLogText = msg;
        setTimeout(function onClearStatusText() {
            var  val = uiUtils.getText(txt);
            if ( val == msg ) {
                uiUtils.setText(txt, '');
            }
        }, 5000)
    }

    uiUtils.getText = function getText(jq) {
        var ui = $(jq)
        //console.log('what is ', jq, ui, val)
        if ( ui.length == 0 ) {
            console.warn('cannot set', jq, 'to', val, 'empty query set')
        }
        var val=ui.val()
        if ( ui.is('span')) {
            var val = ui.text()
        }
        return val;
    }

    u.selectAction = function selectAction(id) {
        var ui = $(id)
        ui.change()
    }



    function defineKeyboard() {
        u.addKeyListener = function addKeyListener() {

        }

        u.onKey = function onKey(va) {

        }
    }

    defineKeyboard();

    function defineScrollable() {
        uiUtils.scrollToBottom = function scrollToBottom(jq) {

            var ui = $(jq)
            //$("body").animate({ scrollTop: $('#messages').prop("scrollHeight")}, 200);
            $(jq).clearQueue();
            $(jq).stop(true, true);
            $(jq).animate({scrollTop: $(jq).prop("scrollHeight")}, 10);
            console.log('scrollto', ui.prop('scrollHeight'), ui.scrollTop())
        }

        uiUtils.makeScrollable = function makeScrollaboe(div, height) {
            div.css('overflow', 'auto')
            div.css('max-height', height + 'px')
            //debugger
        }
        uiUtils.scrollToTop = function scrollToTop(jq) {
            //$("body").animate({ scrollTop: $('#messages').prop("scrollHeight")}, 200);
            $(jq).clearQueue();
            $(jq).stop(true, true);
            $(jq).animate({scrollTop: 0}, 10);
        }


        uiUtils.getScrollPosition = function getScrollPosition(ui) {
            var position = $(ui).prop('scrollHeight');
            var position = $(ui).scrollTop();
            return position;
        }

        uiUtils.setScrollPosition = function setScrollPosition(ui, pos, animate) {
            ui = $(ui)
            //debugger
            if ( animate != false  ) {
                ui.clearQueue();
                ui.stop(true, true);
                ui.animate({scrollTop: pos}, 10);
            }
            else {
                ui.scrollTop(pos)
            }



            return;
            var position = $(ui).offset();

            return position;
        }

    }
    defineScrollable()

}
defineUtils();

window.restartTest = function restartTest() {
    window.location.href =
        'http://localhost:33031/index.html#?loadTestFramework=true&dialogSearchTests=true&testName=rSmoke&runTest=true'
    setTimeout(function onReload() {
        window.location.reload();
    }, 50);
}