var fs = require('fs');
var tent = require('../lib/tent');

fs.readFile( 'credentials.user.js', function(err, data) {
    if( err ) {
        console.error(err);
        return;
    }

    var cred = JSON.parse( data );
    var mac_key = cred.mac_key;
    var mac_key_id = cred.access_token;

    var tenturl = 'https://bnj.tent.is';

    var client = new tent.Client(tenturl);
    client.clientRegister( mac_key, mac_key_id );
    client.getPosts( function(err, posts) {
        if( err ) {
            console.error(err);
            return;
        }

        console.log('first time');
        console.log( JSON.stringify(posts) );
        client.getPosts( function(err, p2) {
            console.log('second time');
        });
    });
});
