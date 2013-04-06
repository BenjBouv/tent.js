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
    }
});

