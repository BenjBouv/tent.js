var fs = require('fs');
var config = require('./config').config;
var tent = require('../lib/tent');

fs.readFile( 'credentials.user.js', function(err, data) {
    if( err ) {
        console.error(err);
        return;
    }

    var cred = JSON.parse( data );
    var mac_algo = cred.mac_algorithm;
    var mac_key = cred.mac_key;
    var mac_key_id = cred.mac_key_id;

    var client = new tent.Client(config.entity);
    client.clientRegister( mac_algo, mac_key, mac_key_id );
    client.postsGet( function(err, posts) {
        if( err ) {
            console.error(err);
            return;
        }

        console.log('first time');
        console.log( JSON.stringify(posts) );
        client.postsGet( function(err, p2) {
            console.log('second time');
        });
    });
});
