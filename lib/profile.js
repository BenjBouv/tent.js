var requests = require('./requests'),
    utils = require('./utils');

var get = function(type, cb /* (err, profile) */) {

    function findOrErr( profiles ) {
        if( profiles[type] ) {
            cb( null, profiles[type] );
        } else {
            cb( 'Profile type not found', null );
        }
    };

    var that = this;
    if( that.cache.profiles ) {
        findOrErr( that.cache.profiles );
    } else {
        that.discovery( function( err, profileUrl ) {

            if( err ) {
                cb(err, null);
                return;
            }

            var reqParam = {
                url: profileUrl,
                method: 'GET',
                body: null,
                onResult: function(err, headers, data) {
                    // TODO try?
                    var profile = JSON.parse(data);
                    that.cache.profiles = profile;
                    findOrErr( that.cache.profiles );
                }
            };
            requests.run( reqParam );

        } );
    }
};

var PROFILE_CORE = "https://tent.io/types/info/core/v0.1.0";
var PROFILE_BASIC = "https://tent.io/types/info/basic/v0.1.0";

module.exports = function( proto ){
    proto.PROFILE_CORE = PROFILE_CORE;
    proto.PROFILE_BASIC = PROFILE_BASIC;

    proto.profileGet = get;
};
