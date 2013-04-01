var qs = require('querystring');
var requests = require('./requests'),
    utils = require('./utils');


var get = function(cb /* (err, profiles) */) {

    var that = this;
    if( that.cache.profiles ) {
        cb( null, that.cache.profiles );
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
                    var profiles = JSON.parse(data);
                    that.cache.profiles = profiles;
                    cb( null, that.cache.profiles );
                }
            };
            requests.run( reqParam );

        } );
    }
};

/**
 * call with params = {
 *      type: string required,
 *      profile: object required
 * };
 */
var update = function( params, cb /* (err, enhancedProfile) */ ) {
    if( !params.type || !params.profile ) {
        cb( 'When updating profile, missing parameters.' );
        return;
    }

    // for known types, check that required params are present
    if( PROFILE_TYPES[ params.type ] ) {
        var required = PROFILE_TYPES[ params.type ].required;
        for( var i = 0; i < required.length; ++i ) {
            if( !params.profile[ required[i] ] ) {
                cb( 'When updating profile of type ' + params.type + ', missing required parameter ' + required[i] );
                return;
            }
        }
        params.type = PROFILE_TYPES[ params.type ].url;
    }

    var that = this;
    var url = '/profile/' + qs.escape(params.type);
    if( params.version ) {
        url += '?' + qs.stringify({version: params.version});
    }

    this.apiCall({
        url: url,
        method: 'PUT',
        body: JSON.stringify( params.profile ),

        needAuth: true,
        auth: that.credentials.user,

        onResult: function( err, headers, data ) {
            if(err) { cb(err); return; }
            that.cache.profiles = JSON.parse(data);
            cb( null, that.cache.profiles );
        }
    }, cb);
};

/**
 *  same params as update, with:
 *      version: int facultative,
 */
var getSpecific = function( params, cb /* (err, profile) */) {
    if( !params.type ) {
        cb( 'When getting specific profile, no type given!' );
        return;
    }

    if( PROFILE_TYPES[ params.type ] ) {
        params.type = PROFILE_TYPES[ params.type ].url;
    }

    var url = '/profile/' + qs.escape(params.type);
    if( params.version ) {
        url += '?' + qs.parse({version: params.version});
    }

    var that = this;
    this.apiCall({
        url: url,
        method: 'GET',

        needAuth: true,
        auth: that.credentials.user,

        onResult: function( err, headers, data ) {
            if(err) { cb(err); return; }
            cb( null, JSON.parse(data) );
        }
    }, cb);
};

var delete_ = function( params, cb /* err */ ) {
    if( !params.type ) {
        cb( 'When deleting specific profile, no type given!' );
        return;
    }

    if( PROFILE_TYPES[ params.type ] ) {
        params.type = PROFILE_TYPES[ params.type ].url;
    }

    var url = '/profile/' + qs.escape(params.type);
    if( params.version ) {
        url += '?' + qs.parse({version: params.version});
    }

    var that = this;
    this.apiCall({
        url: url,
        method: 'DELETE',

        needAuth: true,
        auth: that.credentials.user,

        onResult: function( err, headers, data ) {
            if(err) { cb(err); return; }
            // TODO check header?
            cb( null );
        }
    }, cb);
};

var PROFILE_TYPES = {
    core: {
        url: "https://tent.io/types/info/core/v0.1.0",
        required: ['entity', 'licenses', 'servers']
    },

    basic: {
        url: "https://tent.io/types/info/basic/v0.1.0",
        required: []
    },

    cursor: {
        url: "https://tent.io/types/info/cursor/v0.1.0",
        required: ['post', 'entity']
    }
};

module.exports = function( proto ){
    proto.PROFILES = PROFILE_TYPES;
    proto.profileGet = get;
    proto.profileGetSpecific = getSpecific;
    proto.profileUpdate = update;
    proto.profileDelete = delete_;
};
