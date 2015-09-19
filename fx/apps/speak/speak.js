//console.log('...', $('#btnStart'),  $.isReady)





function tX() {
    var self = this;
    var  p = this;

    p.startOnSel = function startOnSel() {
        console.log('startSel', self.sel)
        self.start(self.sel)
    }

    p.start = function (jquery, words) {
        var el = $(jquery);
        if (el.attr('id')=='appendToApp') {
            el = $(self.sel2);
        }

        self.currentId = Math.random();

        self.el = el;
        var txt = el.text();
        var sentences = txt.split('.');
        self.lookFor = sentences;

        self.timePerWord = 200
        self.rate = 300;
        self.rate = 350;
        //var sentences = self.el.html().split('.');
        //self.lookFor = sentences;


        //var words = txt.split(' ');
        //self.lookFor = words;
        var newSentences = [];
        $.each(sentences, function breakDownMore(i,sentence) {
            var words = sentence.split(' ');
            var count = 0;
            var newSent = [];
            for ( var i = 0; i < words.length; i ++ ) {
                /*if ( i % 5 == 0 ) {
                 sentNew.push( words.slice(0,5).join(' ') )
                 words = words.slice(6)
                 }*/
                var word = words[i]
                var y = word.replaceX("\n", "")
                word = word.replace("\n", '')
                if ( word == "\n")
                    continue;
                if ( word.trim() == '')
                    continue;
                newSent.push(word)
                count++
                if ( count == 5 ) {
                    newSentences.push( newSent.join(' ') )
                    newSent = [];
                    count = 0
                };

            }
            if ( newSent.length > 0 ) {
                newSentences.push( newSent.join(' ') )
            }
        })


        //back to sentences

        var newSentences = txt.match( /[^\.!\?]+[\.!\?]+/g );
        //sentences with whitespace after
        // newSentences = txt.replace(/([.?!\n\r])\s*(?=[A-Z])/gi, "$1|").split("|")

        var txtTransformed =  txt.replace(/(?:\r\n|\r|\n)/g, '|');
        txtTransformed =  txt.replace(/[\W+](?:\r\n|\r|\n)/gi, '|');

        txtTransformed = txtTransformed.replace(/([.?!])\s*(?=[A-Z])/gi, "$1|")
        newSentences =  txtTransformed.split("|");

        self.index = 0;
        self.lookFor = newSentences;
        self.lookForAll = self.lookFor.concat();
        self.goEach();
        window.speakText = txt;
        console.log('starting...', newSentences.length)
    }

    p.back = function onBack() {
        self.index -= 5
        if ( self.index < 0 ) { self.index = 0 };
        self.lookFor = self.lookForAll.slice( self.index)
        self.state();
    }

    p.forward = function onNext() {
        self.index += 5
        if ( self.index < 0 ) { self.index = 0 };
        self.lookFor = self.lookForAll.slice( self.index)
        self.state();
    }

    p.restart = function onRestart() {
        self.index  = 0
        self.lookFor = self.lookForAll.concat();
        self.state();
        self.play();
    }

    p.play = function play() {
        self.pause = false
        self.goEach();
    }

    p.pause = function pause() {
        self.pause = true
        $('html,body').clearQueue();
        $('html,body').stop();
    }

    p.setRate = function setRate(rate) {
        self.timePerWord =1000* 1/(rate*1/60);
        self.rate = rate;
        console.log(self.timePerWord, rate)
    }

    p.state = function state() {
        console.log('... ', self.index, self.lookFor)
    }

    p.goEach = function () {
        if ( self.lookFor.length == 0 ) {
            console.log('done')
            return;
        }
        if (  self.pause == true ) {
            console.log('paused')
            return;
        }
        self.index ++
        var sentence = self.lookFor.shift()
        //var html = self.el.html()
        //if ( self.lastReplacement != null ) {
        //    html = html.replaceX(self.lastReplacement[1], self.lastReplacement[0]);
        //}
        var rep = "<span class='smallcaps'>"+sentence+"</span>"
        self.lastReplacement = [sentence, rep];
        //html = html.replaceX(self.lastReplacement[0], self.lastReplacement[1]);
        //self.el.html(html)
        self.el.html(self.el.html().replaceX('<span class="smallcaps">','<span>'))
        self.el.wrapInTag({"words" : [sentence], tag:'span'});

        var target = $('.smallcaps');
        if (target.length) {
            $('html,body').clearQueue();
            $('html,body').stop();
            $('html,body').animate({
                scrollTop: target.offset().top-200
            }, 500);
            //return false;
        }
//return;
        console.log('update', sentence, self.lookFor.length)
        if ( self.testMode == true ) {
            setTimeout(self.goEach, self.timePerWord * sentence.split().length);
        } else {
            var curId = self.currentId;
            $.ajax({
                url: "https://local.helloworld3000.com:4444/say",
                data:{text:sentence,
                    rate:self.rate},
                success: function f(d){
                    if ( curId != self.currentId ) {
                        return;
                    }
                    self.goEach();
                },
                dataType: "text"
            }).done(function( html ) {
                //console.log('d', html)
            });;
        }

    }

    // http://stackoverflow.com/a/9795091
    $.fn.wrapInTag = function (opts) {
        // http://stackoverflow.com/a/1646618
        function getText(obj) {
            return obj.textContent ? obj.textContent : obj.innerText;
        }

        var tag = opts.tag || 'strong'
        var    words = opts.words || []
        try {
            var regex = RegExp(words.join('|'), 'gi')
        } catch ( e ) {}
        var  replacement = '<' + tag + ' class="smallcaps" >$&</' + tag + '>';

        // http://stackoverflow.com/a/298758
        $(this).contents().each(function () {
            if (this.nodeType === 3) //Node.TEXT_NODE
            {
                try {
                    // http://stackoverflow.com/a/7698745
                    $(this).replaceWith(getText(this).replace(regex, replacement));
                } catch ( e ) {}
            }
            else if (!opts.ignoreChildNodes) {
                $(this).wrapInTag(opts);
            }
        });
    };
}
t = new tX();


String.prototype.replaceX = function replace( find, replaceWith) {
    function escapeRegExp(string) {
        return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
    }

    // So in order to make the replaceAll function above safer, it could be modified to the following if you also include escapeRegExp:

    // function replaceAll(string, find, replace) {
    return this.replace(new RegExp(escapeRegExp(find), 'g'), replaceWith);
}
console.log( "readys!" );





$( document ).ready( doReady ) ;
function doReady () {

    console.log( "ready...!" );
    //t.start('#story', 4)
    $('#btnStart').click(function(event) {


    })


    if (  $('#voc_startOnSelection').length == 0 ) {
        console.log('try again...')
        setTimeout(doReady, 300)
        return;
    }

    $('#voc_startOnSelection').click(t.startOnSel)
    $('#doSel').change(changeEnabled);

    function changeEnabled(event) {
        t.enabled = this.checked;
        console.log('on',  t.enabled, this.checked, $('#doSel').val());
        localStorage.setItem('reader_Enabled', t.enabled );
    }
    //changeEnabled();


    $('#voc_btnBack').click(t.back)
    $('#voc_btnFor').click(t.forward)
    $('#voc_btnRestart').click(t.restart)
    $('#voc_btnPlay').click(t.play)
    $('#voc_btnPause').click(t.pause)
    $('#inputRate').change(function onChanged(event) {
        var val = $(event.target).val()
        console.log('changed', $(event.target).val() );
        t.setRate(val)
    });

    $('html').click(function(event) {
        //Hide the menus if visible
        // console.log('click it',event)
        if ( t.enabled == false ) {
            return;
        }

        var tar = $(event.target)
        var ancestor = $(tar).closest("article");
//if parent is control box
        if (tar.parents('.container-controls').length) {
            return;
        }
        function selectElementText(el, win) {
            win = win || window;
            var doc = win.document, sel, range;
            if (win.getSelection && doc.createRange) {
                sel = win.getSelection();
                range = doc.createRange();
                range.selectNodeContents(el);
                sel.removeAllRanges();
                sel.addRange(range);
            } else if (doc.body.createTextRange) {
                range = doc.body.createTextRange();
                range.moveToElementText(el);
                range.select();
            }
        }

        selectElementText(event.target);


        var p = tar.parent();

        t.sel = t.sel2;
        t.sel2 = p





        selectElementText(event.target.parentNode);
        var y = p.children()
        $.each(y, function (i, j ) {
            //  console.log(j);
            // selectElementText(j);
        })

        console.log('click for sel', tar, tar.text(),  t.sel,  t.sel2);
        //console.log('click', tar, tar.text());
    });


    function loadStorage() {
        // false;
        t.enabled = localStorage.getItem('reader_Enabled')=="true"
        $('#doSel')[0].checked = t.enabled;
        console.log('storage', t.enabled, $('#doSel')[0].checked,
            localStorage.getItem('reader_Enabled'), $('#doSel')[0].checked )


    }

    loadStorage();

    console.log( "ready!" );
};

if ( $.isReady ) {
    setTimeout(function () {
        console.log( "ready!" );
        // doReady();
    }, 5);
}