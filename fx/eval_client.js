/**
 * Created by user on 8/15/15.
 */


$.urlParam = function(name){
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (results==null){
        return null;
    }
    else{
        return results[1] || 0;
    }
}



var getUrlParameter = function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};



//http://localhost:5557/index.html?rec=true&file=a.txt
function Utilx() {
    var p = this;
    var self = this;

    p.start = function () {
        self.file = getUrlParameter('file')
        if ( self.file != null ) {
            $.ajax({
                url: '/getFile',
                data: {file:self.file},
                success: function (data) {
                    //$(".result").html(data);
                    //alert("Load was performed.");
                },
                //dataType: dataType
            });
        }
    }
}




var utils = new Utilx()
utils.start();
//console.log('....', getUrlParameter('rec'))

console.log('ready')


var socket = io();
$('form').submit(function(){
    socket.emit('chat message', $('#m').val());
    $('#m').val('');
    return false;
});
socket.on('chat message', function(msg){
    if (msg.indexOf('eval-')==0) {
        msg = msg.replace('eval-', '')
        eval(msg);
    }
    console.log('chat')
    $('#messages').append($('<li>').text(msg));
});


socket.on('runcmd', function(msg){
    console.log('run command', msg)
    if (msg.eval != null) {
        console.log('running', msg.eval)
        var result = eval(msg.eval);
        setTimeout(function cmdDone() {
            $.ajax({
                url: '/next',
                data: {result:result},
                success: function (data) {
                },
            });
        }, 250 )
    }
    $('#messages').append($('<li>').text(msg));
});


$('#btnTestClick').click(function(){
    alert('alert')
    /*
     eval-$('#btnTestClick').click();
     eval-$('#messages').append($('<li>').text('test messaging to me')); $('#btnSend').click();
     */
    return false;
});