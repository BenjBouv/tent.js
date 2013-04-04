var tent = require('../lib/tent');
var config = require('./config').config;

var client = new tent.Client( config.stalkedEntity );
client.postsGetPublic( {limit:1}, function(err, posts) {
    if(err) { console.error(err); } else {
        console.log('last post from stalked entity: ' + JSON.stringify(posts) );
    }
});

