$(document).ready(function() {

	$(document).on('click', '.js-openaccount', window.navigateToAccount);
	$(document).on('click', '.js-DVRResetVideo', replayCurrentVideo);
	$(document).on('click', '.js-confirmCreditSpend', onConfirmCreditSpend);
	$(document).on('click',	'.js-close2',gUtils.onBack)
	$(document).on('click',	'.js-logout',gUtils.onLogout)

	gUtils.onBackspaceGoBack = function onBackspaceGoBack () {
		$(document).on('keydown',onSearchKeyPress);

		function onSearchKeyPress(e) {


			var ui  = $(e.target);
			var isInput = ui.is('input') ||
					ui.is('textarea')
				;
//			console.debug(isInput, e.charCode , e.keyCode, e)
			if ( isInput )
				return;
			if (_.isObject(e) && (  e.keyCode === 8)) {
				console.debug('back')
				window.history.back()
			}
		}

	}

	gUtils.onBackspaceGoBack();


});

function replayCurrentVideo(e){
	console.log('... reload')
	videojs("#videoplayer").currentTime(0);
	window.location.reload();
}

function onConfirmCreditSpend (e) {
	//this is where you want to add tasks when credits are too be spent
	var search_result = window.DVR.lastPlayedState.search_result,
		imdb_id = window.DVR.currentMedia.imdb_id || '',
	//url_playstate = window.DVR.url_state.play,
		play_state = window.DVR.lastPlayedState.url_state.play,
		media_short_url = null,
		session_id 	= window.config.session;

	if( search_result )
		media_short_url = search_result.localFilePath;

	var content_id = media_short_url || imdb_id;

	//$('.video-wrapper').removeClass('no-credit');
	creditHelper.closeCreditDialog();
	$.get(
		'http://' + window.location.hostname + ':' + window.config.files.port + '/api/use_credit?content_id=' + content_id + '&session_id='+ session_id,
		function success(result){
			console.log('test', result);
			if( !result.hasOwnProperty('error') ) {
				videojs("#videoplayer").play();
			}
		}).fail(function(err){
		console.log('error',err);
	});
}

var gUtils = {};
function defineUtilsG() {
	gUtils.setLocationHash = function setLocationHash(e) {
		setTimeout(function setLocationLater(){
			window.location.hash = e;// '#listDialog';
		}, 0);
	}
	gUtils.setFocus = function setFocus(e) {
		setTimeout(function setFocus(){
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
		if ( exp ) {
			$(jq).show();
		} else {
			$(jq).hide();
		}
	}

	gUtils.addToken = function addToken(jq) {
		if ( jq == null ){ return }
		var uiHolder = $(jq);
		uiHolder.html('');
		var token = uiUtils.tag('span');
		token.attr('id', uiHolder.attr('id')+'Token');
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

	gUtils.onChangeDebounced = function onenter(jquery, fx, time) {
		if (time == null) time = 500;
		var d = {}
		d.debounce = function debounce(fx) {
			if (d.waiting) {
				clearTimeout(d.waiting)
			}
			//d.waiting = true;
			d.waiting = setTimeout(function onDebounced() {
				fx()
			}, time)
		}

		$(jquery).keyup(function (e) {
			d.debounce(fx, time)
			//startWaiting()

		});
	}

	gUtils.showTall = function showTall() {
		gUtils.show('#taskPageArea')
		setBodyCanOverflow(true)
		console.error('show hide')
	}

	gUtils.hideTall = function hideTall() {
		gUtils.hide('#taskPageArea')
		//debugger;
		setBodyCanOverflow(false)
		console.error('close hide')
	}



	gUtils.getParams = function getParamsFromUrl() {
		gUtils.params = uiUtils.utils.getParams();
	}
	gUtils.getParams();


	gUtils.remoteFailed = function remoteFailed(a,b,c) {
		if ( c == 'Unauthorized') {
			gUtils.refreshPage()
		}
	}

	gUtils.refreshPage = function refreshPage() {
		location.reload();
	}


	gUtils.onBack  = function onBack() {
		console.debug('back')
		window.history.back()
	}
	gUtils.onLogout  = function onLogout() {
		//debugger
		function eraseCookieFromAllPaths(name) {
			// This function will attempt to remove a cookie from all paths.
			var pathBits = location.pathname.split('/');
			var pathCurrent = ' path=';

			// do a simple pathless delete first.
			document.cookie = name + '=; expires=Thu, 01-Jan-1970 00:00:01 GMT;';

			for (var i = 0; i < pathBits.length; i++) {
				pathCurrent += ((pathCurrent.substr(-1) != '/') ? '/' : '') + pathBits[i];
				document.cookie = name + '=; expires=Thu, 01-Jan-1970 00:00:01 GMT;' + pathCurrent + ';';
			}
		}
		eraseCookieFromAllPaths('logCred')
		eraseCookieFromAllPaths()
		eraseCookieFromAllPaths(window.location.hostname+':'+window.location.port)

		//debugger



		function expireAllCookies(name, paths) {
			var expires = new Date(0).toUTCString();

			// expire null-path cookies as well
			document.cookie = name + '=; expires=' + expires;

			for (var i = 0, l = paths.length; i < l; i++) {
				document.cookie = name + '=; path=' + paths[i] + '; expires=' + expires;
			}
		}

		expireAllCookies('name', ['/', '/path/']);

		function expireActiveCookies(name) {
			var pathname = location.pathname.replace(/\/$/, ''),
				segments = pathname.split('/'),
				paths = [];

			for (var i = 0, l = segments.length, path; i < l; i++) {
				path = segments.slice(0, i + 1).join('/');

				paths.push(path);       // as file
				paths.push(path + '/'); // as directory
			}

			expireAllCookies(name, paths);
		}

		expireActiveCookies()
		expireActiveCookies('logCred')

		window.location = '/logout';
	}






	gUtils.titleCase  = function titleCase(str) {
		str = str.toLowerCase().split(' ');
		for (var i = 0; i < str.length; i++) {
			str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
		}
		return str.join(' ');
	}

	gUtils.fixStr  = function fixStr(chars) {
		//str = str.toLowerCase().split(' ');
		var symbols = [',', '.', '?'];

		var outputStr = '';
		for (var i = 0; i < chars.length; i++) {

			var char = chars[i]
			var nextChar = chars[i+1];
			var prevChar = chars[i-1];

			nextChar =dv(nextChar, '')
			prevChar =dv(prevChar, '')

			outputStr += char;

			var isNotUpperCase = prevChar.toUpperCase() != prevChar
			if ( isNotUpperCase &&
				symbols.includes(char) && nextChar.trim() != '' ) {
				outputStr += ' '
			}


		}
		return outputStr;
	}

	gUtils.fixTitle  = function fixTitle(chars) {
		var outputStr = chars;
		var isAllUpperCase = true;
		var isAllLowerCase = true;
		for (var i = 0; i < chars.length; i++) {
			var char = chars[i]
			var isNotUpperCase = char.toUpperCase() != char
			if ( isNotUpperCase  ) {
				isAllUpperCase = false;
			}
			var isNotLowerCase = char.toLowerCase() != char
			if ( isNotLowerCase  ) {
				isAllLowerCase = false;
			}
		}

		if ( isAllUpperCase ) {
			outputStr = gUtils.titleCase(chars)
		}
		if ( isAllLowerCase ) {
			outputStr = gUtils.titleCase(chars)
		}
		return outputStr;
	}
}
defineUtilsG();

function CreditHelper () {
	var self = this;
	var p = this;

	self.data = {};

	p.init = function init() {
		if ( $('#chkAutoplay').length == 0 ) {
			console.log('waiting for page')
			setTimeout(self.init, 500)
			return;
		}
		if ( serverHelper.utils.test('dialog')) {
//?test=dialog
			self.openCreditDialog();
		}
		//debugger
		$('#chkAutoplay').val(window.config.user.profile);
		$('#chkAutoplay').change(function onAutoPlayChanged() {
			var checked = $(this).is(":checked")
			if( checked ) {

			}
			//$('#textbox1').val($(this).is(':checked'));

			var profile = dv(window.config.user.profile, {})
			profile.autoplay = checked;
			window.config.user.profile = profile;

			window.serverHelper.saveUser(window.config.user)
		});
	}
	p.openCreditDialog = function openCreditDialog() {
		self.data.open = true;
		$('.video-wrapper').addClass('no-credit');
		$('#creditDialog').show();

		$('#dialogModal').show();
		gUtils.hideTall();

		var creditCount = window.serverHelper.data.user.credits;
		$('#txtCreditCount').text('You have '+creditCount + ' credits')
		if ( creditCount == 1 )
			$('#txtCreditCount').text('You have '+creditCount + ' credit')
		if (creditCount == 0) {
			gUtils.show('#cd-account')
			gUtils.hide('#cd-usecredit')
			gUtils.hide('#cd-autoplay')
		} else {
			gUtils.hide('#cd-account')
			gUtils.show('#cd-usecredit')
			gUtils.show('#cd-autoplay')
		}
	};
	p.showCreditDialog = p.openCreditDialog

	p.closeCreditDialog = function closeCreditDialog(doCheck) {
		if ( self.data.open != true ) {
			self.data.open = false;
			return;
		}
		$('.video-wrapper').removeClass('no-credit');
		$('#creditDialog').hide();
		('no-credit');
		$('#dialogModal').hide();
		gUtils.showTall();
	}
	;


	p.useCreditOnCurrent = function useCreditOnCurrent() {
		window.serverHelper.useCredit(null,function () {
			self.closeCreditDialog();
			//return;
			//videojs("#videoplayer").play();
			//videojs("#videoplayer").currentTime(0);
			window.location.reload();
		})
	}
	;
}

window.creditHelper = new CreditHelper();
window.creditHelper.init()


function ServerHelper () {
	var self = this;
	var p = this;
	self.data = {};
	p.init = function init() {
		self.data.servers = window.config;

		var prot = self.data.servers.files.default_server.split('//')[0];
		var yyy = self.data.servers.files.default_server.split('//')[1];
		var yyy2 = yyy.split('/')[0];

		self.data.servers.files.server = prot+'//'+yyy2+'/';

		//self.data.session = window.config.session;
		self.data.session_id = window.config.session;

		defineTests();
		window.tH2.utils = self.utils;



		tH2.createDB = function createDB() {
			/*
			 make div - ion bottom right
			 add buttons to click other functions
			 update user info
			 logout
			 clearCredits
			 tryToUseCdreidts
			 hr
			 start tests
			 */
			window.serverHelper.utils.addToUrl('db', true)
			var cfg = {}
			cfg.id = 'testPanel';
			window.uiUtils.makePanel(cfg);
			uiUtils.flagCfg = {};
			uiUtils.flagCfg.id = cfg.id;
			uiUtils.flagCfg.addTo = $('#testPanel');
			//window.uiUtils.addLabel('DB')
			window.uiUtils.addTitle('DB');
			window.uiUtils.addButton('Load Tests',  tH2.loadTests);
			window.uiUtils.br();
			window.uiUtils.addButton('Contact', function onContact() {
				window.location.hash = '#contact';
			});
			window.uiUtils.br();
			window.uiUtils.addButton('Get User Info', window.serverHelper.getUserInfo);
			window.uiUtils.br();
			window.uiUtils.br();
			window.uiUtils.addButton('Clear Library', tH2.clearCredits);
			window.uiUtils.br();
			window.uiUtils.addButton('Set 0 Credits', tH2.resetCreditCount3);
			window.uiUtils.br();
			window.uiUtils.addButton('Set !0 Credits', window.tH2.resetCreditCount2);
			window.uiUtils.br();
			window.uiUtils.addButton('Show Library', tH2.showCreditCache);
			window.uiUtils.br();
			window.uiUtils.br();
			window.uiUtils.addButton('Add 1 Met', tH2.clearCredits);
			window.uiUtils.addButton('Add 3 Met', tH2.clearCredits);
		}
		if ( window.serverHelper.utils.inUrl('db='))
			tH2.createDB();


		tH2.goAnal = function goAnal() {
			var urlAServer = 'http://localhost:'+
				window.config.analyticz_server.port;
			var urlAServer2 = 'http://localhost:'+
				(parseInt(window.config.analyticz_server.port)+1);
			var fileSocketIO = 'socket.io-1.2.0.js.ignore'
			fileSocketIO = urlAServer + '/'+
				fileSocketIO;
			uiUtils.utils.loadScript(fileSocketIO, function onLoaded() {
				console.log('...', 'socket loaded' )
				var socket = io( urlAServer2 );
				window.socket = socket;
			})

		}
		tH2.goAnal()
		//debugger;
	}
	p.hasCreditForItem = function hasCreditForItem(content_id, fxDone) {
		var url  = self.utils.getUrl(self.data.servers.files.server,
			'/api/has_credit/')
		var data = {};
		data.content_id = content_id
		if ( content_id == null) {
			data.content_id = self.utils.getCurrentMedia()
		}
		data.session_id = self.data.session_id;

		$.ajax({
			url: url,
			data: data,
			success: function (data) {
				var has = true
				if ( data.error ){
					has =false
				}
				callIfDefined(fxDone, data)
				console.log('can user watch', data)
				//	debugger;
			},
			error: function (a,b,c) {
				debugger;
				console.error('cannot get user info')
				gUtils.remoteFailed(a,b,c)
			}
		});
	};

	p.watchItem = function watchItem(content_id, fxDone) {

		var data = {};
		data.content_id = content_id;
		if ( content_id == null) {
			data.content_id = self.utils.getCurrentMedia()
		}
		var url  = self.utils.getUrl(self.data.servers.files.server,
			'/api/get_content/media/'+data.content_id)

		data.session_id = self.data.session_id;

		data.testPercent = 50
		$.ajax({
			url: url,
			data: data,
			success: function (data) {
				var has = true
				if ( data.error ){
					has =false
				}
				callIfDefined(fxDone, data)
				console.log('can user watch', data)
				//	debugger;
			},
			error: function (a,b,c) {
				//debugger;
				console.error('cannot get user info')
				gUtils.remoteFailed(a,b,c)
			}
		});
	};

	p.getUserInfo = function getUserInfo(fxDone) {
		var data = {};
		/*data.actions  = [
		 {
		 asdf:'test',
		 text:'test',
		 action :'test thing',
		 test_item : true
		 }
		 ]*/
		$.ajax({
			url: '/getUserInfo',
			data: data,
			success: function (data) {
				self.data.user = data;

				uiUtils.waitFor('#txtCredits', function onUpdate(ui){
					ui.text('('+data.credits+')');
				})
				$('#txtCredits').text('('+data.credits+')')
				console.debug('userinfo', data)
				callIfDefined(fxDone, data);
				//utils.showAlert('added ajax')
			},
			error: function (a,b,c) {
				console.error('cannot get user info')
				gUtils.remoteFailed(a,b,c)
			}
		});
	} ;


	p.saveUser = function saveUser(_data, fxDone) {
		var __data = dv(_data, self.data.user);

		var data = {}
		var allowedProps = ['username', 'password', 'profile']
		$.each(allowedProps, function asdf(k,prop) {
			//return;
			data[prop] = 	__data[prop];
		});
		//	debugger;


		$.ajax({
			method:"post",

			url: '/saveUser',
			data: data,
			success: function (data) {

				if ( data.status == "false") {
					console.error(data.msg)
					return;
				}
				console.log('user saved')
				callIfDefined(fxDone)

				//self.data.user = data;
			},
			error: function (a,b,c) {
				console.error('cannot get user info')
				gUtils.remoteFailed(a,b,c)
			}
		});
	} ;


	p.getCreditCount = function getCreditCount(fxDone, refresh) {
		if ( refresh ) {
			self.getUserInfo(function asdf(){
				p.getCreditCount(fxDone);
			})
			return;
		};
		callIfDefined(fxDone, self.data.user.credits);
	}


	p.useCredit = function useCredit(content_id, fxDone, _session_id) {
		var url  = self.utils.getUrl(self.data.servers.files.server,
			'/api/use_credit/');
		var data = {};
		data.content_id = content_id;
		if ( content_id == null) {
			data.content_id = p.utils.getCurrentMedia();
		}
		data.session_id = self.data.session_id;

		$.ajax({
			url: url,
			data: data,
			success: function (data) {
				self.data.user.credits--;
				callIfDefined(fxDone)
				//debugger;
			},
			error: function (a,b,c) {
				debugger;
				console.error('cannot get user info')
				gUtils.remoteFailed(a,b,c)
			}
		});
	}



	p.utils = {};
	p.utils.getUrl = function getUrl(url, asdf) {
		var fUrl = url + '/' + asdf;;
		if ( gUtils.beginsWith(asdf, '/')){
			fUrl = url  + asdf;;
		}
		if ( url.slice ) {
			if (url.slice(-1) == '/' && asdf.slice(0, 1) == '/') {
				fUrl = url.slice(0, -1) + '/' + asdf.slice(1);
			}
			if (url.slice(-1) == '/' && asdf.slice(0, 1) != '/') {
				fUrl = url.slice(0, -1) + asdf.slice(1);
			}
			if (url.slice(-1) != '/' && asdf.slice(0, 1) == '/') {
				fUrl = url.slice(0, -1) + asdf.slice(1);
			}

		}
		if ($.isNumeric(url)) {
			var baseUrl = 'http://' + window.location.hostname
			fUrl = baseUrl + ':' + fUrl;
		}
		fUrl +='?session_id='+ window.config.session;
		return fUrl
	}

	p.utils.lorem = function lorem () {
		var times = 150
		var txt = ''
		for ( var i = 0; i < times; i++) {
			txt = Math.floor(Math.random() * 3) + ' ';
		}
		return txt ;
	}

	p.utils.request2 = function request2(cfg) {

		if ( cfg.divLoading ) {
			gUtils.show(cfg.divLoading)
		}
		$.ajax({
			url: cfg.url,
			data: cfg.data,
			success: function (data) {
				callIfDefined(cfg.fxDone,data)
				gUtils.hide(cfg.divLoading)
				//debugger;
			},
			error: function (a,b,c) {
				gUtils.hide(cfg.divLoading)
				gUtils.addToken(cfg.divLoadingToken)
				callIfDefined(cfg.fxError)
				console.error('cannot get info', cfg.url)
				gUtils.remoteFailed(a,b,c)
			}
		});
	}


	p.utils.getCurrentMedia = function getCurrentMedia() {
		var ret = DVR.currentMedia.title
		var p =  DVR.currentMedia.playterm;
		if ( p ) {
			if ( p.indexOf('get_content/media/') != -1 ) {
				p = p.split('get_content/media/')[1]
			}
			if ( p.indexOf('api/get_content/') != -1 ) {
				p = p.split('api/get_content/')[1]
			}
			if ( p.indexOf('?') != -1 ) {
				p = p.split('?')[0]
			}
			ret = p
			return p
		}
		return ret;
	}

	p.utils.test = function test(dlg) {
		if ( window.location.search.indexOf('test='+dlg)!= -1 ) {
			return true;
		}
		return false;
	}
	p.utils.inUrl = function inUrl(dlg) {
		return uiUtils.inUrl(dlg)
	}

	p.utils.addToUrl = function addToUrl(key, val) {
		uiUtils.addToUrl(key, val)
	}

}

window.serverHelper = new ServerHelper();
window.serverHelper.getUserInfo();


function defineTests() {
	//gUtils.loadPartial('testDialog', '#testDialog')
	function TestHelper() {
		var self = this;
		var p = this;

		p.turnOffAutoplay = function turnOffAutoplay(autoplay) {
			autoplay = dv(autoplay, false);
			var profile = dv(window.config.user.profile, {});
			profile.autoplay = autoplay;
			window.config.user.profile = profile;
			window.serverHelper.saveUser(window.config.user);
		}

		p.turnOnAutoplay = function turnOnAutoplay() {
			p.turnOffAutoplay(true)
		}


		p.canUserWatchItem = function canUserWatchShow(content_id, fxDone, _session_id) {
			window.serverHelper.hasCreditForItem(content_id, fxDone);
		}

		p.watchItem = function canUserWatchShow(content_id, fxDone, _session_id) {
			window.serverHelper.watchItem(content_id, fxDone);
		}


		p.clearCredits = function clearCredits() {
			var url  = self.utils.getUrl(window.serverHelper.data.servers.files.server,
				'/api/clear_credits/');
			var cfg = {};
			cfg.url = url;
			cfg.fxDone = function onCleared() {
				console.log('cleared')
			};
			self.utils.request2(cfg);
		}
		p.showCreditCache = function showCreditCache() {
			var url  = self.utils.getUrl(window.serverHelper.data.servers.files.server,
				'/api/show_credit_cache/');
			var cfg = {};
			cfg.url = url;
			cfg.fxDone = function onCleared(data) {
				console.log('cache', data)
			};
			self.utils.request2(cfg);
		}
		p.resetCreditCount = function resetCreditCount(count) {
			var url  = self.utils.getUrl(window.serverHelper.data.servers.files.server,
				'/api/reset_credits/'
			);
			var cfg = {};
			cfg.url = url;
			cfg.data = {count:count}
			cfg.fxDone = function onCleared() {
				console.log('cleared')
			}
			self.utils.request2(cfg);
		}
		p.resetCreditCount2 = function resetCreditCount() {
			self.resetCreditCount(2000)
		}
		p.resetCreditCount3 = function resetCreditCount() {
			self.resetCreditCount(0)
		}
		p.testDialog = function testDialog() {
			window.location  = '/index.html?test=dialog'
		}
		p.testListDialog = function testListDialog() {
			window.location  = '/index.html?test=searchListDialog'
		}


		p.loadTests = function loadTests() {
			uiUtils.utils.loadScript('test2/testLL.js')
			//bring up dialog
		}

		if ( window.location.href.indexOf('runTest=true') !=-1 )
			loadTests()
		if ( window.location.href.indexOf('tester') !=-1 )
			loadTests();

	}
	window.tH2 = new TestHelper();
}


gUtils.replace = function replace(str, find, replaceWith, i) {
	function escapeRegExp(string) {
		return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
	}
	// So in order to make the replaceAll function above safer, it could be modified to the following if you also include escapeRegExp:
	// function replaceAll(string, find, replace) {
	return str.replace(new RegExp(escapeRegExp(find), 'gi'), replaceWith);

};

gUtils.beginsWith =   function startsWith (str, subStr) {
	if (str == null) {
		return;
	}
	return str.indexOf(subStr) == 0 ;
};

function SearchListDialogHelper () {
	var self = this;
	var p = this;
	self.data = {};

	p.init = function init() {
		if (serverHelper.utils.test('searchListDialog')) {
			self.openSearchListDialog();
		}
		if (serverHelper.utils.inUrl('badSearch')) {
			setTimeout(self.setTextTo, 500, 'asdee^^&')
		}

		gUtils.onEnter('#txtSearchLists', self.doSearch)
		gUtils.onChangeDebounced('#txtSearchLists', self.doSearch)
		$('#header-list').on('click', self.openSearchListDialog);

		return;
	};

	p.setTextTo =function setTextTo(sdf) {
		$('#txtSearchLists').val(sdf)
	}

	p.monitortext = function monitortext() {
		$('#txtSearchLists').keyup(function() {
			var val = $(this).val()

			setTimeout(updateTxtSearch, 200)

			function updateTxtSearch() {
				console.log('x', val)
				//debugger
				var results = $('#hacker-list').find('.list-search-list').find('.desc,.link')

				$.each(results, function modresults(k, ui) {

					base = $(ui);
					var html = base.html();

					if ( base.htmlOrig ) {
						html = base.htmlOrig;
					} else {
						base.htmlOrig = html;
					}

					if ( val == '' ) {
						base.html(html);
						return;
					}

					var rep = gUtils.replace(html, '<strong>', '');
					rep = gUtils.replace(rep, '</strong>','');
					if ( val == '' ) base.html(rep);;
					rep = gUtils.replace(rep, val, '<strong>$&</strong>');
					base.html(rep);
				})
			}
			return;
			var base = $('#hacker-list').find('.list-search-list').find('.desc,.link')

			var html = base.html();
			var rep = gUtils.replace(html, val, '<strong>$&</strong>');
			base.html(rep);
		});
	}
	p.updateResults =function updateresults(sdf) {

		self.data.list.clear();
		$.each(sdf, function addresult(k,v) {
			v.link = window.serverHelper.utils.getUrl(
				window.serverHelper.data.servers.searchLists.port,
				'/api/content_lists/view/'+v.list_id
			)

			v.content_list_id = v.list_id;
			v.number = k + 1;
			v.desc = gUtils.fixStr(v.desc)
			v.name = gUtils.fixTitle(v.name)
			//	v.name = v.title;
			//	v.idview  = v.imdb_id;
			self.data.list.add(v);
		})

		self.highlightQueryInSearchResults()


		gUtils.ifShow(sdf.length==0,'#listResultsNoMatches')

	}

	p.highlightQueryInSearchResults =function highlightQueryInSearchResults(sdf) {

		var val = $('#txtSearchLists').val()

		setTimeout(updateTxtSearch, 200)

		function updateTxtSearch() {
			///console.log('x', val)
			//debugger
			var results = $('#hacker-list').find('.list-search-list').find('.desc,.link')
			$.each(results, function modresults(k, ui) {
				var base = $(ui);
				var html = base.html();

				if ( base.htmlOrig ) {
					html = base.htmlOrig;
				} else {
					base.htmlOrig = html;
				}

				if ( val == '' ) {
					base.html(html);
					return;
				}

				var rep = gUtils.replace(html, '<strong>', '');
				rep = gUtils.replace(rep, '</strong>','');
				if ( val == '' ) base.html(rep);;
				rep = gUtils.replace(rep, val, '<strong>$&</strong>');
				base.html(rep);
			})
		}

	}

	p.initSearchListDialogList = function initSearchListDialogList() {


		if (self.data.initedList == true) {
			return;
		}
		self.data.initedList = true;

		var options = {
			valueNames: [
				'number',
				'name',
				'desc',
				{ data: ['id'] },
				{ name: 'timestamp', attr: 'data-timestamp' },
				//{ name: 'link', attr: 'href' },
				{ name: 'link', attr: 'href2' },
				{ name: 'content_list_id', attr: 'content_list_id' },
				{ name: 'image', attr: 'src' }
			]
		};

		var hackerList = new List('hacker-list', options);

		self.data.list = hackerList;
		self.data.list.clear();

		$(document).click(function(e) {
			var t = event.target;
			t = $(t)
			var href = $(t).attr('href')
			if ( t.hasClass('urlGoLink') == false ) {
				return
			}
			fUtils.changeToPage(href)
			//debugger;
		});


		return;
		hackerList.add({
			name: 'Jonasv',
			desc: gUtils.lorem(),
			id: 2,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif'
		});

		hackerList.add({
			name: 'Jonas',
			desc: '1985',
			id: 3,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif'
		});

		hackerList.add({
			name: 'Jonas',
			desc: '1985',
			id: 4,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif'
		});



	}
	p.openSearchListDialog = function openSearchListDialog() {

		gUtils.setLocationHash('#listDialog')

		gUtils.setFocus('#txtSearchLists')

		setTimeout(self.doSearch, 500, '');

		$('#dialogLists').show();
		gUtils.hideTall();

		//$('#dialogModal').show();

		p.initSearchListDialogList();

		var creditCount = window.serverHelper.data.user.credits;
		$('#txtCreditCount').text('You have '+creditCount + ' credits')
		if ( creditCount == 1 )
			$('#txtCreditCount').text('You have '+creditCount + ' credit')
		if (creditCount == 0) {
			gUtils.show('#cd-account')
			gUtils.hide('#cd-usecredit')
			gUtils.hide('#cd-autoplay')
		} else {
			gUtils.hide('#cd-account')
			gUtils.show('#cd-usecredit')
			gUtils.show('#cd-autoplay')
		}
	};
	p.showSearchListDialog = p.openSearchListDialog

	p.closeSearchListDialog = function closeSearchListDialog(doCheck) {
		if ( doCheck && window.serverHelper.utils.inUrl('#listDialog')){
			gUtils.hideTall();
			self.showSearchListDialog();
			return;
		} else {

		};

		$('.video-wrapper').removeClass('no-credit');
		$('#dialogLists').hide();
		('no-credit');
		$('#dialogModal').hide();
		if ( doCheck != true )
			gUtils.showTall();
	} ;


	p.useCreditOnCurrent = function useCreditOnCurrent() {
		window.serverHelper.useCredit(null,function () {
			self.closeCreditDialog();
			//return;
			//videojs("#videoplayer").play();
			//videojs("#videoplayer").currentTime(0);
			window.location.reload();
		})
	};

	p.doSearch = function doSearch() {
		var txt = $('#txtSearchLists').val();
		//if ( self.utils == null )
		//	debugger
		var url  = window.serverHelper.utils.getUrl(
			window.serverHelper.data.servers.searchLists.port,
			'/api/content_lists/search');
		var cfg = {};
		cfg.url = url;
		cfg.data = {}
		cfg.data = {$any:[{name:{$like: "%"+txt+"%"}},{desc:{$like: "%"+txt+"%"}} ]};
		cfg.data = {$or:[{name:{$like: "%"+txt+"%"}},{desc:{$like: "%"+txt+"%"}} ]}
		cfg.divLoading = '#loadingPlaylistSearch';
		cfg.divLoadingToken = '#loadingPlayistSearchHolder'
		cfg.fxDone = function onCleared(results) {
			console.log('results', results.length);
			self.updateResults(results);

		};
		window.serverHelper.utils.request2(cfg);
	}
}
window.searchListDialogHelper = new SearchListDialogHelper();


function ContentListDialogHelper () {
	var self = this;
	var p = this;
	self.data = {};

	p.init = function init() {
		if (serverHelper.utils.test('contentListDialog')) {
			self.openContentListDialog();
		};
		var listId = gUtils.params['listId'];
		if ( listId ) {
			setTimeout(self.setListTo, 500, listId);
		}
		self.data.listId = '#view-content-list';
		gUtils.onChangeDebounced('#txtContentListsDialog',
			self.highlightQueryInSearchResults,100);
	};
//http://localhost:33031/index.html?test=contentListDialog&listId=ls1567897

	p.updateContentListDisplay =function updateContentListDisplay(contentList) {
		self.data.list.clear();
		var shift = contentList.shift();
		shift.name = gUtils.fixTitle(shift.name);
		$('#txtContentList').text(shift.name);
		$.each(contentList, function addresult(k,v) {
			/*v.link = window.serverHelper.utils.getUrl(
			 window.serverHelper.data.servers.searchLists.port,
			 '/api/content_lists/view/'+v.list_id
			 )*/
			v.number = k + 1;
			v.name = v.title;
			v.idview  = v.imdb_id;
			self.data.list.add(v);
		})
		self.highlightQueryInSearchResults()


	}

	p.highlightQueryInSearchResults =function highlightQueryInSearchResults(sdf) {
		self.data.txtFilterContentList= $('#txtContentListsDialog')
		var val = self.data.txtFilterContentList.val()

		setTimeout(updateTxtSearch, 200)

		function updateTxtSearch() {
			///console.log('x', val)
			//debugger
			var results = $(self.data.listId).find('.list-search-list').find('.desc,.link')
			$.each(results, function modresults(k, ui) {
				var base = $(ui);
				var html = base.html();

				if ( base.htmlOrig ) {
					html = base.htmlOrig;
				} else {
					base.htmlOrig = html;
				}

				if ( val == '' ) {
					base.html(html);
					return;
				}

				var rep = gUtils.replace(html, '<strong>', '');
				rep = gUtils.replace(rep, '</strong>','');
				if ( val == '' ) base.html(rep);;
				rep = gUtils.replace(rep, val, '<strong>$&</strong>');
				base.html(rep);
			})
		}

		var contentList = sdf;
		var results = $(self.data.listId).find('.list-search-list').find('.desc,.link')
		contentList = results;
		gUtils.ifShow(contentList.length==0,'#contentListNoResults')

	}

	p.initContentListDialogList = function initContentListDialogList() {
		if (self.data.initedList == true) {
			return;
		}
		self.data.initedList = true;

		var options = {
			valueNames: [
				'name',
				'rating',
				'number',
				'desc',
				{ data: ['id'] },
				{ name: 'timestamp', attr: 'data-timestamp' },
				//{ name: 'link', attr: 'href' },
				{ name: 'image', attr: 'src' },
				{ name: 'idview', attr: 'idview' },
			]
		};

		var hackerList = new List('view-content-list', options);
		self.data.list = hackerList;
		self.data.list.clear();

		return;
		hackerList.add({
			name: 'Jonasv',
			desc: gUtils.lorem(),
			rating:8.8,
			id: 2,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif',
			"rating": "8.7",
			"image": "https://images-na.ssl-images-amazon.com/images/M/MV5BOTIyMDY2NGQtOGJjNi00OTk4LWFhMDgtYmE3M2NiYzM0YTVmXkEyXkFqcGdeQXVyNTU1NTcwOTk@._V1._SX140_CR0,0,140,209_.jpg",
			"title": "Star Wars: Episode IV - A New Hope",
			"imdb_url": "/title/tt0076759/",
			"imdb_id": "tt0076759",
			"year": "1977",
			"desc": "Luke Skywalker joins forces with a Jedi Knight, a cocky pilot, a wookiee and two droids to save the galaxy from the Empire's world-destroying battle-station, while also attempting to rescue Princess Leia from the evil Darth Vader. (121 mins.)",
			"comment": ""
		});

		return;
		hackerList.add({
			name: 'Jonasv',
			desc: gUtils.lorem(),
			id: 2,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif'
		});

		hackerList.add({
			name: 'Jonas',
			desc: '1985',
			id: 3,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif'
		});

		hackerList.add({
			name: 'Jonas',
			desc: '1985',
			id: 4,
			timestamp: '1337',
			link: 'http://arnklint.com',
			image: 'jonas.gif'
		});



	};
	p.openContentListDialog = function openListDialog() {

		//window.location.hash = '#listContentDialog'
		gUtils.setFocus('#txtContentListsDialog')
		$('#dialogContentList').show();
		gUtils.hideTall();
		p.initContentListDialogList();

	};
	p.showContentListDialog = p.openContentListDialog

	p.closeContentListDialog = function closeContentListDialog(doCheck) {
		if ( doCheck && window.serverHelper.utils.inUrl('#listContentDialog')){
			gUtils.hideTall();
			self.showContentListDialog();

			gUtils.getParams()
			var listId = gUtils.params.listId;

			//debugger;

			self.setListTo(listId)
			return;
		}
		$('#dialogContentList').hide();
		$('#dialogModal').hide();
		if ( doCheck != true )
			gUtils.showTall();
	};

	p.setListTo = function setListTo(listId) {
		if (listId == self.data.currentListId) {
			return;
		}
		if ( window.serverHelper.data.servers == null ) {
			return;
		}
		self.data.currentListId = listId;

		//window.location.hash = '#listContentDialog'+
		//	window.location.query = 			'?listId='+listId;

		window.location.hash = '#listContentDialog'+ 	'?listId='+listId;

//debugger
		var txt = $('#txtSearchLists').val('');

		//debugger;
		var url  = window.serverHelper.utils.getUrl(
			window.serverHelper.data.servers.searchLists.port,
			'/api/content_lists/show/'+listId);
		var cfg = {};
		cfg.url = url;
		cfg.data = {}
		cfg.data = {name:{$like: "%"+txt+"%"}}
		cfg.fxDone = function onGotContentList(results) {
			console.log('results', results.length)
			if ( results.error ) {
				self.updateContentListDisplay([])
				return
			}
			self.updateContentListDisplay(results)
		};
		window.serverHelper.utils.request2(cfg);
	}
}
window.contentListDialogHelper = new ContentListDialogHelper();

gUtils.loadPage = function loadPage(cfg) {
	uiUtils.utils.loadPage(cfg)
}


$(document).ready(function onReady(){
	setTimeout(window.serverHelper.init, 10)
	function asdf() {
		window.searchListDialogHelper.init()
		window.contentListDialogHelper.init()


		function setupL() {
			$(document).click(function onClickListItem(e) {
				var t = e.target;
				t = $(t)
				var href = $(t).attr('href');

				console.debug('in')

				var content_list_id = $(t).attr('content_list_id');
				if (content_list_id != null) {
					console.error('bog');
					window.searchListDialogHelper.closeSearchListDialog();

					//	return;
					window.contentListDialogHelper.openContentListDialog();
					window.contentListDialogHelper.setListTo(content_list_id);

					return false;
				}

				if (t.hasClass('idviewgo') == false) {
					console.debug('out')
					return
				}
				console.debug('booo')

				var idview = t.attr('idview');
				console.log('id', idview)

				//window.location.search = '';
				window.location.hash = '#results=' + idview
				window.contentListDialogHelper.closeContentListDialog()
				e.preventDefault()
				console.error('prevent yyy')
				e.preventDefault();
				e.stopPropagation();
				console.debug('booo')
				return false;
				debugger;
				fUtils.changeToPage(href)
				//debugger;
			});
		}

		setupL();
	}

	setTimeout(asdf, 501)
})



window.metrics = {};
window.metrics.search = function (term) {

}
window.metrics.watch = function (term) {

}






