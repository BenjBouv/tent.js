var requests = require('./requests');

var get = function( cb ) {
    var that = this;
    this.apiCall({
        url: '/posts',
        method: 'GET',

        needAuth: true,
        auth: that.credentials.user,

        onResult: function(err, headers, data) {
            if( err ) { cb(err, null); }
            else cb( null, JSON.parse(data) );
        }
    }, cb);
};

module.exports = function( proto ) {
    proto.postsGet = get;
};
