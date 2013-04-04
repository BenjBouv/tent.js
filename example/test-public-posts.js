var tent = require('../lib/tent');
var config = require('./config').config;

var client = new tent.Client( config.stalkedEntity );
var params = {
    limit: 1,
    post_types: client.POSTS.essay.url
};

client.postsGetPublic( params, function(err, posts) {
    if(err) { console.error(err); } else {
        console.log('last post from stalked entity: ' + JSON.stringify(posts) );
    }
});

