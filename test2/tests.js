/**
 * Created by user2 on 2/13/16.
 */

window.testsLoaded = true;

//test2.html?runTest=true&testName=rHome
//http://10.211.55.4:33031/index.html?runTest=true&testName=rHome#

function testStackingDemo2() {
// return
    window.tests.rHome = function defineTestA(tH) {
        var t = tH.createNewTest();

        function searchDialogClose() {
            tH.clickJ('#dialogSearch .closebtn')
        }

        tH.click('test 2');
        tH.log('test 2')
        searchDialogClose(); //just in case
        tH.run(function addSearchText(){
            $('#search').val('Test Started ')
        })
        tH.desc('waiting for task page to load')
        tH.waitFor(function(){
            return $('.media-num').length > 10;
            t.data.mediaFiles = $('.media-num').length
        } )
        tH.desc('click to get more b uttons')
        tH.clickJ('#btnMore');
        tH.wait(1)
        tH.desc('verify more buttons created')
        tH.run(function addSearchText(){
            t.data.mediaFiles2 = $('.media-num').length;
            if ( t.data.mediaFiles2 <= t.data.mediaFiles ) {
                tH.fail();
            }
        })
        tH.run(function addSearchText(){
            $('#search').val('yyy ... ')
            //$('#search').trigger(jQuery.Event('keypress', {which: 13}));
            var e = jQuery.Event("keypress");
            e.which = 13; //choose the one you want
            e.keyCode = 13;
            e.charCode = 13;
            $('#search').trigger(e)
        })

        tH.run(function addSearchText(){
            $('#search').val('yyy ... ')
            //$('#search').trigger(jQuery.Event('keypress', {which: 13}));
            var e = jQuery.Event("keypress");
            e.which = 13; //choose the one you want
            e.keyCode = 13;
            e.charCode = 13;
            $('#search').trigger(e)
        });

        tH.desc('try search isDialogVisible')
        tH.waitFor(function isDialogVisible(){
            return $("#dialogSearch").is(":visible")
        });
        tH.desc('try search once');
        //tH.wait(3); //wait for results to come back
        tH.waitFor(function verifyNoSearchResults(){
            if ( $('.search-result').length == 0 )
                return true;

            if ( $('.search-result').length == 1 &&
                $('.search-result').text().indexOf('00') != -1  )
                return true;
            return false
        });
        tH.desc('try search again')
        tH.clickJ('#dialogSearch .closebtn')

        tH.waitForHide( "#listing");

        function performSearch(query) {
            tH.run(function addSearchText(){
                query = sh.dv(query)
                $('#search').val(query)
                var e = jQuery.Event("keypress");
                e.which = 13; //choose the one you want
                e.keyCode = 13;
                e.charCode = 13
                $('#search').trigger(e)
            });
        }

        performSearch();




        //tH.enter();
        tH.waitForShow( "#dialogSearch" );

        tH.moreThanX( '.search-result', 0 );
        tH.wait(1);
        tH.clickOne( '.search-result', 0 );
        tH.wait(1);
        tH.desc('expect the error container to show')
        tH.waitForShow( '#containerError')

        tH.clickJ('.video-wrapper .closebtn')
        tH.desc('hide the error container')
        tH.waitForHide( '#containerError')

        tH.desc('seach again')
        performSearch();
        tH.waitForShow( "#dialogSearch" );
        tH.moreThanX( '.result', 0 );
        tH.wait(1);
        //tH.clickOne( '.result', -2*-1 );
        tH.clickOne( '.result', 4 );
        tH.desc('playing vid')

        tH.waitForShow( '#videoplayer')

        tH.verifyHidden( '#containerError');
        tH.wait(3);
        tH.run(function verifyPlayer(){
            var vp = videojs('#videoplayer');
            vp.src() //verify source
            t.data.currentTime = vp.currentTime();
        });



        tH.wait(2);
        tH.verify(function verifyPlayer(){
            var vp = videojs('#videoplayer');
            vp.src() //verify source
            return t.data.currentTime < vp.currentTime();
        });
        tH.wait(1)
        tH.clickJ('.vjs-play-control.vjs-control.vjs-playing')
        tH.run(function pausePlayerWithClick(){
            var vp = videojs('#videoplayer');
            t.data.currentTime = vp.currentTime();
        });
        tH.wait(1)
        tH.desc('ensure player is paused... ')
        tH.verify(function pausePlayerWithClick(){
            var vp = videojs('#videoplayer');
            return t.data.currentTime == vp.currentTime();
        });


        tH.wait(1)
        tH.clickJ('.video-wrapper .closebtn')
        // tH.waitForHide( '#videoplayer')
        tH.wait(1)
        tH.clickJ('#dialogSearch > .closebtn')
        //Next Steps ... login and account page test
        tH.desc('dialogSearch vid')
        tH.wait(3)
        //test payment
        tH.waitForHide( "#dialogSearch" )

        tH.log('test 2')
        /*tH.run(function(){
         alert('ran test 2')
         })*/
    }
}
testStackingDemo2();





/**
 * Created by user2 on 2/13/16.
 */
//test2.html?runTest=true&testName=rHome
//http://10.211.55.4:33031/login.html?runTest=true&testName=rLogin&redirectrunTest=true&redirecttestName=rHome#
function testLogin() {
    window.tests.rLogin = function defineTestA(tH) {
        var t = tH.createNewTest();
        tH.log('Starting login test')
        tH.waitForShow('#loginPasswordMain')
        tH.set('#loginUsernameMain', 'admin');
        tH.set('#loginPasswordMain', 'password');
        tH.nextTest('rHome', 'index.html')
        tH.clickJ('#btnLogin')

        return;
        function searchDialogClose() {
            tH.clickJ('#dialogSearch .closebtn')
        }

        tH.click('test 2');
        tH.log('test 2')
        searchDialogClose(); //just in case
        tH.run(function addSearchText(){
            $('#search').val('Test Started ')
        })
        tH.desc('waiting for task page to load')
        tH.waitFor(function(){
            return $('.media-num').length > 10;
            t.data.mediaFiles = $('.media-num').length
        } )
        tH.desc('click to get more buttons')
        tH.clickJ('#btnMore');
        tH.wait(1)
        tH.desc('verify more buttons created')
        tH.run(function addSearchText(){
            t.data.mediaFiles2 = $('.media-num').length;
            if ( t.data.mediaFiles2 <= t.data.mediaFiles ) {
                tH.fail();
            }
        })
        tH.run(function addSearchText(){
            $('#search').val('yyy ... ')
            //$('#search').trigger(jQuery.Event('keypress', {which: 13}));
            var e = jQuery.Event("keypress");
            e.which = 13; //choose the one you want
            e.keyCode = 13;
            $('#search').trigger(e)
        })

        tH.run(function addSearchText(){
            $('#search').val('yyy ... ')
            //$('#search').trigger(jQuery.Event('keypress', {which: 13}));
            var e = jQuery.Event("keypress");
            e.which = 13; //choose the one you want
            e.keyCode = 13;
            $('#search').trigger(e)
        });

        tH.waitFor(function isDialogVisible(){
            return $("#dialogSearch").is(":visible")
        });
        tH.verify(function verifyNoSearchResults(){
            if ( $('.search-result').length == 0 )
                return true;

            if ( $('.search-result').length == 1 &&
                $('.search-result').text().indexOf('00') != -1  )
                return true;
            return false
        });
        tH.desc('try search again')
        tH.clickJ('#dialogSearch .closebtn')

        tH.waitForHide( "#listing");

        function performSearch(query) {
            tH.run(function addSearchText(){
                query = sh.dv(query)
                $('#search').val(query)
                var e = jQuery.Event("keypress");
                e.which = 13; //choose the one you want
                e.keyCode = 13;
                $('#search').trigger(e)
            });
        }

        performSearch();

        //tH.enter();
        tH.waitForShow( "#dialogSearch" );

        tH.moreThanX( '.search-result', 0 );
        tH.clickOne( '.search-result', 0 );
        tH.desc('expect the error container to show')
        tH.waitForShow( '#containerError')
        tH.clickJ('.video-wrapper .closebtn')
        tH.waitForHide( '#containerError')

        performSearch();
        tH.waitForShow( "#dialogSearch" );
        tH.moreThanX( '.result', 0 );
        tH.clickOne( '.result', -2 );
        tH.waitForShow( '#videoplayer')
        tH.verifyHidden( '#containerError');
        tH.wait(3);
        tH.run(function verifyPlayer(){
            var vp = videojs('#videoplayer');
            vp.src() //verify source
            t.data.currentTime = vp.currentTime();
        });
        tH.wait(2);
        tH.verify(function verifyPlayer(){
            var vp = videojs('#videoplayer');
            vp.src() //verify source
            return t.data.currentTime < vp.currentTime();
        });
        tH.wait(1)
        tH.clickJ('.vjs-play-control.vjs-control.vjs-playing')
        tH.run(function pausePlayerWithClick(){
            var vp = videojs('#videoplayer');
            t.data.currentTime = vp.currentTime();
        });
        tH.wait(1)
        tH.desc('ensure player is paused... ')
        tH.verify(function pausePlayerWithClick(){
            var vp = videojs('#videoplayer');
            return t.data.currentTime == vp.currentTime();
        });


        tH.wait(1)
        tH.clickJ('.video-wrapper .closebtn')
        // tH.waitForHide( '#videoplayer')

        //Next Steps ... login and account page test
        //test payment

        tH.log('test 2')
        /*tH.run(function(){
         alert('ran test 2')
         })*/
    }
}
testLogin();


//http://10.211.55.4:33031/account.html?runTest=true&testName=rAccount
function testAccount() {
    window.tests.rAccount = function rAccount(tH) {
        var t = tH.createNewTest();
        tH.log('Starting account test');
        tH.log('Starting account test...');
        tH.waitForShow('#btc-paybtn');
        tH.verify(function verifyUsernameSet(){
            var isUsernameSet = $('.js-accountname').html() != '';
            return isUsernameSet;
        });
        //tH.nextTest('rLogout', 'index.html');

    }
}
testAccount();


//http://10.211.55.4:33031/account.html?runTest=true&testName=rLogout
function testLogout() {
    window.tests.rLogout = function rAccount(tH) {
        var t = tH.createNewTest();
        tH.log('Starting logout test');
        tH.waitForShow('.js-logout');
        /* tH.verify(function verifyUsernameSet(){
         var isUsernameSet = $('.js-accountname').html() != ''
         return isUsernameSet;
         });*/
        tH.clickJ('.js-logout');

    }
}
testLogout();





//http://10.211.55.4:33031/login.html?runTest=true&testName=rLoginExpiredUser&redirectrunTest=true&redirecttestName=rExpiredUser#
function testExpiredUser() {
    //login
    //go to index
    //verify user cannot login

    window.tests.rLoginExpiredUser = function defineTestA(tH) {
        var t = tH.createNewTest();
        tH.log('Starting login test')
        tH.waitForShow('#loginPasswordMain')
        tH.set('#loginUsernameMain', 'markExpired');
        tH.set('#loginPasswordMain', 'randomTask2');
        tH.set('#loginUsernameMain', 'markExpired');
        tH.nextTest('rLoginExpired', 'index.html')
        //tH.wait(1)
        tH.clickJ('#btnLogin')
    }

    window.tests.rLoginExpired = function defineTestA(tH) {
        var t = tH.createNewTest();
        tH.log('Starting login-expired test')
        //alert('d')
        /*
         tH.waitForShow('#loginPasswordMain')
         tH.set('#loginUserMain', 'markExpired');
         tH.set('#loginPasswordMain', 'randomTask2');
         tH.nextTest('rLoginExpired', 'index.html')
         tH.clickJ('#btnLogin')
         */

        tH.waitFor(function(){
            return $('.media-num').length > 10;
            t.data.mediaFiles = $('.media-num').length
        } )
        tH.desc('click to get more buttons');
        tH.clickJ('#btnMore');
        tH.wait(1)
        tH.desc('verify user expired');
        tH.verify(function verifyPlayer(){
            return window.config.expired == true
        });
    }
}
testExpiredUser();



