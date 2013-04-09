var fs = require('fs');
var tent = require('../lib/tent');
var config = require('./config');

var client = new tent( config.entity );

/**
 * This example is to ensure that profile retrieval is executed
 * only one time even if it's executed several times.
 *
 * In particular, when using the tent client, a user could, for
 * instance, send multiple posts in the mean time. This means that
 * the API root is found. As it doesn't need to get fetched several
 * times, it is cached.
 *
 * To avoid async requests during API root and profile retrieval,
 * synchronism is set up during profile retrieval.
 */

var cb = function(err, profile) {
    if(err) {
        console.error(err);
    } else {
        console.log('Profile received!');
    }
};

for( var i = 0; i < 50; ++i ) {
    client.profile.get(cb);
}
