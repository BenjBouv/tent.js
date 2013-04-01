var requests = require('./requests'),
    utils = require('./utils');

var Registration = require('./registration');

var PROFILE_CORE = "https://tent.io/types/info/core/v0.1.0";
var PROFILE_BASIC = "https://tent.io/types/info/basic/v0.1.0";


var Client = function(entityURI) {

    if( !entityURI ) {
        throw 'no entity uri given at instanciation!';
    }

    this.entityURI = entityURI;

    this.profileURI = null;
    this.profiles = null;

    this.credentials = {};
    this.credentials.app = null;
    this.credentials.user = null;

    this.app = null;
};

Client.prototype.discovery = function(cb /* (err, profileURI) */) {
    if( this.profileURI ) {
        cb( this.profileURI );
    } else {

        var that = this;
        var reqParams = {
            url: this.entityURI,
            method: 'HEAD',
            body: null,
            onResult: function(err, headers, data) {

                if( !headers.link ) {
                    cb('Link section not found in headers received during discovery.', null);
                    return;
                }

                // the link looks like this: <https:// ... >, we want it
                var profileUrl = /<[^>]*>/.exec(headers.link);
                // now we want to get rid of the '<' and '>'
                profileUrl = (""+profileUrl).replace(/[<>]/g,'');

                that.profileURI = profileUrl;
                cb( null, that.profileURI );
            }
        };

        requests.run( reqParams );
    }
};

Client.prototype.getProfile = function(type, cb /* (err, profile) */) {

    function findOrErr( profiles ) {
        if( profiles[type] ) {
            cb( null, profiles[type] );
        } else {
            cb( 'Profile not found', null );
        }
    };

    if( this.profiles ) {
        findOrErr( this.profiles );
    } else {
        var that = this;
        this.discovery( function( err, profileUrl ) {

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
                    that.profiles = profile;
                    findOrErr( that.profiles );
                }
            };
            requests.run( reqParam );

        } );
    }
};

Client.prototype.getApiRoot = function(cb) {
    this.getProfile( PROFILE_CORE, function(err, p) {
        if( err ) {
            cb(err, null);
        } else {
            if( p.servers && p.servers.length > 0 ) {
                cb(null, p.servers[0]); // TODO what to do with other servers?
            } else {
                cb('Profile key error: servers not found or server length is zero.', null);
            }
        }
    } );
};

Client.prototype.states = {};

/**
 * Call with params =
 *      { appInfo: object, callback: function( err, OAuthUrl, AppInfoFull ) }
 *  or
 *      { mac_key: String, mac_key_id: String, id (facultative): String }
 */
Client.prototype.registerApp = function(params) {
    if( params.appInfo && params.callback ) {

        var thisClient = this;
        var cb = params.callback;

        function makeOAuthURL( apiRootUrl ) {
            var scope = Object.keys(thisClient.app.scopes).join(',');

            utils.generateUniqueToken(function(stateString) {
                // TODO customize creation of oauthURL
                var oauthUrl = apiRootUrl +
                    '/oauth/authorize?client_id=' + thisClient.app.id +
                    '&redirect_uri=' + thisClient.app.redirect_uris[0] +
                    '&scope=' + scope +
                    '&response_type=code' +
                    '&state=' + stateString +
                    '&tent_profile_info_types=all' + // TODO give the possibility to choose which profile_info are needed
                    '&tent_post_types=all'; // TODO give the possibility to choose which post_types are needed

                Client.prototype.states[ stateString ] = thisClient;
                cb( null, oauthUrl, thisClient.app );
            });
        };

        this.apiCall({
            url: apiRootUrl + '/apps',
            method: 'POST',
            body: JSON.stringify( params.appInfo ),
            onResult: function(err, headers, data) {
                var appInfoEnhanced = JSON.parse(data);

                thisClient.app = appInfoEnhanced;
                thisClient.credentials.app = new Registration( thisClient.app.mac_key, thisClient.app.mac_key_id );

                makeOAuthURL( apiRootUrl );
            }
        }, cb);

    } else if( params.mac_key && params.mac_key_id ) {

        this.credentials.app = new Registration( params.mac_key, params.mac_key_id );
        if( params.id ) {
            this.app = this.app || {};
            this.app.id = params.id;
            this.getApp(function(err, app) {
                if( err ) {
                    if( params.callback ) params.callback(err);
                    else throw err; // TODO not sure how to handle errors...
                    return;
                }

                if( params.callback ) {
                    params.callback(null, app);
                }
            });
        }

    } else {
        throw 'When registering app, neither appInfo & callback nor app registration infos!';
    }
};

Client.prototype.registerClient = function(mac_key, mac_key_id) {
    // TODO hide mac stuff
    this.credentials.user = new Registration( mac_key, mac_key_id );
};

// TODO should registerClient return the Client instance in the callback?
exports.registerClient = function( code, state, cb ) {
    var client = Client.prototype.states[ state ] || null;
    if( client == null ) {
        cb('State string not found...');
        return;
    }

    delete Client.prototype.states[ state ];

    // TODO better system for authentication, so as to not show mac details everywhere
    var mac_key = client.credentials.app.mac_key;
    var mac_key_id = client.credentials.app.mac_key_id;

    var requestBody = JSON.stringify({
        'code' : code,
        'token_type' : "mac" // TODO here
    });

    var reqParam = {
        url: '/apps/' + client.app.id + '/authorizations',
        method: 'POST',
        body: requestBody,
        mac_key: mac_key, // TODO and here
        mac_key_id: mac_key_id,
        onResult: function( err, headers, data ) {
            client.credentials.user = JSON.parse( data );
            cb( null, client.credentials.user );
        }
    };

    client.apiCall( reqParam, cb );
};

Client.prototype.getApp = function( cb ) {
    if( !this.credentials.app || !this.app || !this.app.id ) {
        cb( 'App not registered or id not found', null );
        return;
    }

    var that = this;
    this.apiCall({
        url: apiRootUrl + '/apps/' + that.app.id,
        method: 'GET',
        mac_key: that.credentials.app.mac_key,
        mac_key_id: that.credentials.app.mac_key_id,
        onResult: function(err, headers, data) {
            if(err) { cb(err); return; }
            that.app = JSON.parse( data );
            cb(null, that.app);
        }
    }, cb);
};

Client.prototype.updateApp = function( appInfo, cb ) {
    if( !this.credentials.app || !this.app || !this.app.id ) {
        cb( 'App not registered or id not found', null );
        return; // TODO factorize
    }

    var that = this;
    this.apiCall({
        url: '/apps/' + that.app.id,
        method: 'PUT',
        mac_key: that.credentials.app.mac_key,
        mac_key_id: that.credentials.app.mac_key_id,
        onResult: function(err, headers, data) {
            if(err) {
                cb(err);
                return;
            }

            console.log('headers: ' + JSON.stringify(headers));

            that.app = JSON.parse( data );
            cb(null, that.app);
        }
    }, cb);
};

Client.prototype.deleteApp = function( cb ) {
    if( !this.credentials.app || !this.app || !this.app.id ) {
        cb( 'App not registered or id not found', null );
        return; // TODO factorize
    }

    var that = this;
    this.apiCall({
        url: '/apps/' + that.app.id,
        method: 'DELETE',
        mac_key: that.credentials.app.mac_key,
        mac_key_id: that.credentials.app.mac_key_id,
        onResult: function(err, headers, data) {
            if(err) { cb(err); return; }
            cb(null);
        }
    }, cb);
};

Client.prototype.getPosts = function( cb ) {
    if( !this.credentials.user ) {
        cb( 'Client not registered', null );
        return;
    }

    var that = this;
    this.apiCall({
        url: '/posts',
        method: 'GET',
        mac_key: that.credentials.user.mac_key,
        mac_key_id: that.credentials.user.mac_key_id,
        onResult: function(err, headers, data) {
            if( err ) { cb(err, null); }
            else cb( null, JSON.parse(data) );
        }
    }, cb);
};

Client.prototype.apiCall = function(reqParam, cb) {
    this.getApiRoot( function(err, apiRootUrl) {

        if( err ) {
            cb( err );
            return;
        }

        reqParam.url = apiRootUrl + reqParam.url;
        requests.run( reqParam );
    });
};

exports.Client = Client;

