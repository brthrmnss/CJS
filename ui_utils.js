function forwardArgsTo(fx, args) {
	if (fx == undefined)
		return;
	if (args != null && args.length == null) {
		var args = convertArgumentsToArray(args)
	}
	return fx.apply(null, args)
}

function convertArgumentsToArray(_arguments) {
	var args = Array.prototype.slice.call(_arguments, 0);
	return args
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


	// console.debug('args', tojson(args))
	return fx.apply(null, args)
	//return;
}

function convertArgumentsToArray(_arguments) {
	var args = Array.prototype.slice.call(_arguments, 0);
	return args
}

function throwIfNull(prop, msg) {
	if ( prop == null ) {
		throw new Error(msg)
	}
}



var uiUtils = {};
window.uiUtils = uiUtils;

function defineUtils() {
	var self = uiUtils;
	var p = uiUtils;
	var u = p;

	uiUtils.dictCfg = {};

	$.isString = function isString(objectOrString) {
		//return (objectOrString instanceof String)
		return typeof objectOrString == 'string'
	}

	uiUtils.makePanel = function makePanel(cfg) {
		throwIfNull(cfg.id, 'need an id')
		u.cfg.fixId(cfg)
		var existingUI = $(cfg.id);

		if ( existingUI.length > 0 ) {
			if ( existingUI.length > 1) {
				console.warn('you have multiple things')
			}
			//if ( cfg.toggleMode != false ) {

			//		}
			existingUI.show();
			var cfg = uiUtils.dictCfg[cfg.id]
			debugger;
			return existingUI.cfg;
		}



		cfg = dv(cfg,{});
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


		function onCloseDialog () {
			panel.hide()
			return;
		}

		cfg.fxClose = onCloseDialog;
		//panel.cfg = cfg;
		//panel.html('sdfsdf');
		$('body').append(panel);
		cfg.ui = cfg.panel = panel;
	};

	uiUtils.panel = uiUtils.makePanel;

	uiUtils.panel.tr =function makeBrPanel(cfg) {
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
	uiUtils.panel.br =function makeBrPanel(cfg) {
		cfg = u.cfg.str(cfg, 'id')
		p.panel(cfg);
		u.clearPositions(cfg.ui)
		cfg.ui.css('bottom', '10px');
		cfg.ui.css('right', '10px');
	}

	uiUtils.panel.bl =function makeBrPanel(cfg) {
		cfg = u.cfg.str(cfg, 'id')
		p.panel(cfg);
		u.clearPositions(cfg.ui)
		cfg.ui.css('bottom', '10px');
		cfg.ui.css('left', '10px');
	}

	uiUtils.ifFound = function ifFound(id) {
		if ( id.includes('#') == false ) {
			id = '#'+id;
		}
		var isFound = $(id).length > 0;
		return isFound;
	}

	uiUtils.addLabel = function addLabel(cfg) {
		cfg = u.cfg.str(cfg, 'text')
		cfg.tag = dv(cfg.tag, 'span');
		uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

		var lbl = u.tag(cfg.tag)
		lbl.html(cfg.text)
		//$('<span/>')

		//debugger;
		if ( cfg.addTo ) {
			//debugger;
			cfg.addTo.append(lbl)
		}
	}
	p.addTitle =function addtitle(cfg) {
		cfg = u.cfg.str(cfg, 'text')
		cfg.tag = 'div'
		u.addLabel(cfg)
	}

	uiUtils.fxTest = function fxTest() {
		console.log('hello');
	}

	uiUtils.addBtn = function addBtn(cfg, fxD) {
		cfg = u.cfg.str(cfg, 'text')
		cfg.tag = dv(cfg.tag, 'button');
		cfg.fxDone = dv(cfg.fxDone, fxD);
		uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);

		var btn = u.tag(cfg.tag)
		btn.html(cfg.text)

		//debugger;
		if ( cfg.addTo ) {
			//debugger;
			cfg.addTo.append(btn)
		}

		btn[0].onclick = cfg.fxDone
		//btn.on('click', cfg.fxDone)
	}
	p.addButton = u.addBtn;


	uiUtils.br = function addBtn(cfg, fxD) {
		cfg = dv(cfg, {})
		cfg = u.cfg.str(cfg, 'text')
		uiUtils.utils.mergeIn(uiUtils.flagCfg, cfg);
		var btn = u.tag('br')
		u.addUI(cfg, btn)
	}

	uiUtils.waitFor = function waitFor(id, fxD, count) {
		var ui = $(id)
		if ( ui.length == 0  ) {
			if ( count > 20 ) {
				console.error('timed out')
				throw new Error('timeoud ')
			}
			count += 1;
			setTimeout(uiUtils.waitFor,  250, id, fxD, count)
			return;
		}

		fxD(ui)
	}


	p.cfg = {};
	p.cfg.str = function ifCfgIsStri(cfg, prop) {
		if ( $.isString(cfg) ){
			var _cfg = {};
			_cfg[prop] = cfg;
			cfg = _cfg;
		}
		return cfg;
	}

	p.cfg.fixId = function fixId(cfg, prop) {
		if ( $.isString(cfg.id) ){

			if ( cfg.id.includes('#') == false ) {
				cfg.id = '#'+cfg.id;
			}

		}
		return cfg;
	}
	p.cfg.getId = function fixId(cfg, propId ) {
		if ( $.isString(cfg.id) ){
			cfg = cfg.id;
		}

		if ( $.isString(cfg) ){
			var baseId = cfg;
			var id = baseId;
			if ( baseId.slice(0,1) == '#') {
				id = baseId.slice(1);
			}
		}

		return id;
	}
	p.cfg.getDiv = function fixId(cfg, propId ) {
		if ( $.isString(cfg.id) ){
			cfg = cfg.id;
		}
		var div = $(cfg);
		return div;
	}


	p.addUI = function addUI(cfg, ui ) {
		if ( cfg.addTo ) {
			cfg.addTo.append(ui)
		}
	}
	p.tag = function createTag(type) {
		return $('<'+type+'/>');
	}

	p.utils = {};
	p.utils.mergeIn = function mergeIn(a, b ) {
		if ( b == null ) { return }
		//function copyProps(from, to) {
		$.each(a, function(k,v){
			b[k]=v;
		});
		//	}
	}



	p.utils.loadScripts = function loadScripts(listScripts, fxDone) {
		var loadScript2 = function loadScript2(_scripts2, preamble) {
			if ( _scripts2.length == 0 ) {
				console.log('finished');
				callIfDefined(fxDone)
				return;
			}
			var url = _scripts2.shift();
			if ( preamble == null ) {
				preamble = '';
			}
			url = preamble + url;
			jQuery.getScript(url)
				.done(function () {
				})
				.always(function doneLoadingFile () {
					loadScript2(_scripts2);
				})
				.fail(function (a,b,c,d) {
					console.error('failed to load', url, a==null,b,c,d);
					console.error(c.stack)
				});
		}

		if ( $.isString(listScripts)) {
			listScripts = [listScripts]
		}
		loadScript2(listScripts)

	}
	p.utils.loadScript = p.utils.loadScripts;



	p.utils.getParams = function getParams() {
		function getQueryObj() {
			var query_string = {};
			console.debug('search', window.location.search);
			var query = window.location.search.substring(1);
			if ( query == '' && window.location.hash.indexOf('?') != 0 ) {
				query = window.location.hash.split('?')[1];
			}
			if ( query == null ) {
				return {};
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
		};

		var params = getQueryObj();
		self.utils.params = params;
		return params;
	}


	function defineUrlMethods() {
		p.inUrl = function inUrl(dlg) {
			if ( window.location.search.indexOf(dlg)!= -1 ) {
				return true;
			}
			if ( window.location.hash &&
				window.location.hash.indexOf(dlg)!= -1 ) {
				return true;
			}
			return false;
		}

		p.reload = function reload(dlg) {
			window.location.reload();
		}

		p.addToUrl = function addToUrl(key, val) {
			/*
			 1: hash is present
			 2: ? is present ... so parse vars
			 3: var alreayd exists
			 */

			var params = uiUtils.utils.getParams();
			console.debug('addToUrl','params', window.location.hash, window.location.search,
				params)
			if ( params[key] == val.toString() ) {
				return;
			}
			params[key]=val;
			var str = jQuery.param( params );

			var hash = window.location.hash;
			var urlFinal = '';
			urlFinal = location.href
			if ( urlFinal.includes('?')) {
				urlFinal = urlFinal.split('?')[0];
			}
			if ( urlFinal.includes('#')) {
				urlFinal = urlFinal.split('#')[0];
			}

			console.debug('addToUrl', 'start', urlFinal)
			var isEmptyHash = hash.slice(0,2) == '#?';
			console.debug('addToUrl','hash', hash)
			if ( isEmptyHash ) {
				urlFinal +=  ''
			} else if ( hash != ''  ) {
				var hashOnly = hash;
				if ( hashOnly.includes('?')) {
					hashOnly = hashOnly.split('?')[0];
				}
				urlFinal += hashOnly;
			} else {
				urlFinal += '#'//'empty has to prevent reload
			}
			urlFinal += '?'+str;
			document.location = urlFinal
			console.debug('addToUrl', urlFinal, document.location, window.location.search)
		}


		p.getSearch = function getSearchParam() {
			var urlFinal = location.href;
			if ( urlFinal.includes('?') == false ) {
				return null;
			}
			if ( urlFinal.includes('#')) {
				urlFinal = urlFinal.split('#')[1];
			}
			if ( urlFinal.includes('?')) {
				urlFinal = urlFinal.split('?')[1];
			}
			//console.log('getSearch', urlFinal)
			//if ? is before # warn user ...
			return urlFinal;
		}


		p.getHash = function getHash() {
			//why: get has only, not the search 
			var urlFinal = location.href;
			if ( urlFinal.includes('#') == false ) {
				return null;
			}
			//if ( urlFinal.includes('#')) {
			urlFinal = urlFinal.split('#')[1];
			//	}
			if ( urlFinal.includes('?')) {
				urlFinal = urlFinal.split('?')[0];
			}
			// console.log('getHash', urlFinal)
			return urlFinal;
		}


		p.getUrl = function getUrl() {
			var urlFinal = location.href;
			if ( urlFinal.includes('#')) {
				urlFinal = urlFinal.split('#')[0];
			}
			if ( urlFinal.includes('?')) {
				urlFinal = urlFinal.split('?')[0];
			}
			//console.log('getUrl', urlFinal)
			//if ? is before # warn user ...
			return urlFinal;
		}

		p.setHash = function setHash(hash) {
			var url = self.getUrl()
				+ '#'+hash; 

			if ( self.getSearch() ) {
				url += '?'+self.getSearch()
			}

			window.location.href = url;
		}


	}
	defineUrlMethods();


	function defineUI() {
		p.utils.loadPage = function loadPage(cfg) {
			var div = $(cfg.div)
			if ( div && div.empty() && cfg.id ) {
				div = u.cfg.getDiv(cfg.id);
			}
			if ( div.length == 0 ){
				throw new Error('could not find area ' + cfg.div);
			}

			$.ajax({
				url: cfg.url,
				datattype: "html",
				//data: data,
				success: function (data) {

					var output = p.utils.parseBodyHTML(data);

					// debugger;
					div.html(output.body.html());

					output.addStyles();

					cfg.ui = div;

					callIfDefined(cfg.fxDone, data)
				},
				error: function (a,b,c) {
					debugger;
					console.error('cannot get loadPage info');
					gUtils.remoteFailed(a,b,c)
				}
			});
		}


		p.utils.parseBodyHTML = function parseBodyHTML(d) {
			// replace the `HTML` tags with `NOTHTML` tags
			// and the `BODY` tags with `NOTBODY` tags
			d = d.replace(/(<\/?)html( .+?)?>/gi,'$1NOTHTML$2>',d);
			d = d.replace(/(<\/?)body( .+?)?>/gi,'$1NOTBODY$2>',d);
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

defineUtils();