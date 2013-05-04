var fs = require('fs');
var config = require('./config');
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

    var client = new tent(config.entity);
    client.setUserCredentials( mac_key, mac_key_id );
    client.posts.get( {limit:1, type: "status"}, function(err, posts) {
        if( err ) {
            console.error(err);
            return;
        }

        console.log('last post received: ');
        console.log( JSON.stringify(posts) );

        var myStatus = {
            type: 'status',
            content: {
                text: 'Hello, world!'
            },
            permissions: {public:true}
        };

        client.posts.create(
        myStatus, function(err, enhancedPost) {
            if(err) { console.error(err); return }

            var postId = enhancedPost.id;
            console.log( 'Post has been created with id ' + postId );
            console.log( 'Trying to update the post...' );

            myStatus.content.text = 'Hello from nodejs tent client!';
            client.posts.update( postId, myStatus, function(err, enhancedPost2) {
                if( err ) { console.error(err); return }
                console.log('Post updated! Deleting it.');
                client.posts.delete( enhancedPost2.id, {}, function(err) {
                if( err ) { console.error(err); return }
                console.log('Everything went good.');
                });
            });

        });
    });
});
