var tent = require('../lib/tent');
var config = require('./config');

var client = new tent( config.stalkedEntity );

var params = {
    limit: 1,
    post_types: client.posts.TYPES.essay.url
};

client.posts.get( params, function(err, posts) {
    if(err) { console.error(err); } else {
        console.log('last post from stalked entity: ' + JSON.stringify(posts) );

        client.followings.get({}, function(err, followings) {
            if(err) { console.error(err); } else {
                console.log( 'followings:\n' + JSON.stringify(followings));
                client.followers.get({}, function(err, followers) {
                    if(err) { console.error(err); } else {
                        console.log( 'followers:\n' + JSON.stringify(followers) );
                    }
                });
            }
        });
    }
});

