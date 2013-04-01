var fs = require('fs');
var tent = require('../lib/client');

fs.readFile( 'credentials.user.js', function(err, data) {
	var cred = JSON.parse( data );
	var mac_key = cred.mac_key;
	var mac_key_id = cred.access_token;

	var tenturl = 'https://bnj.tent.is';

/*
	tent.getPosts( tenturl, mac_key, mac_key_id, function(posts) {
		console.log('first time');
		console.log( JSON.stringify(posts) );
		tent.getPosts( tenturl, mac_key, mac_key_id, function(p2) {
			console.log('second time');
		});
	});
*/
});
