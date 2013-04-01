var requests = require('./requests'),
    utils = require('./utils'),
    Registration = require('./registration');

var discovery = function(cb /* (err, profileURI) */) {
    if( this.cache.profileURI ) {
        cb( null, this.cache.profileURI );
    } else {

        var that = this;
        var reqParams = {
            url: that.entityURI,
            method: 'HEAD',
            body: null,
            onResult: function(err, headers, data) {

                if( err ) { cb(err, null); return; }

                if( !headers.link ) {
                    cb('Link section not found in headers received during discovery.', null);
                    return;
                }

                // the link looks like this: <https:// ... >, we want it
                var profileUrl = /<[^>]*>/.exec(headers.link);
                // now we want to get rid of the '<' and '>'
                profileUrl = (""+profileUrl).replace(/[<>]/g,'');

                that.cache.profileURI = profileUrl;
                cb( null, that.cache.profileURI );
            }
        };

        requests.run( reqParams );
    }
};

var getApiRoot = function(cb) {
    this.profileGet( this.PROFILE_CORE, function(err, p) {
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

/**
 * Call with params =
 *      { appInfo: object, callback: function( err, OAuthUrl, AppInfoFull ) }
 *  or
 *      { mac_key: String, mac_key_id: String, id (facultative): String }
 */
var register = function(params) {

    var that = this;

    if( params.appInfo && params.callback ) {

        var cb = params.callback;

        function makeOAuthURL( apiRootUrl ) {
            var scope = Object.keys(that.cache.app.scopes).join(',');

            utils.generateUniqueToken(function(stateString) {
                // TODO customize creation of oauthURL
                var oauthUrl = apiRootUrl +
                    '/oauth/authorize?client_id=' + that.cache.app.id +
                    '&redirect_uri=' + that.cache.app.redirect_uris[0] +
                    '&scope=' + scope +
                    '&response_type=code' +
                    '&state=' + stateString +
                    '&tent_profile_info_types=all' + // TODO give the possibility to choose which profile_info are needed
                    '&tent_post_types=all'; // TODO give the possibility to choose which post_types are needed

		that.setState( stateString, that );
                cb( null, oauthUrl, that.cache.app );
            });
        };

        this.getApiRoot(function(err, apiRootUrl) {
            if( err ) {
                params.callback( err );
                return;
            }

            requests.run({
                url: apiRootUrl + '/apps',
                method: 'POST',
                body: JSON.stringify( params.appInfo ),
                onResult: function(err, headers, data) {
                    var appInfoEnhanced = JSON.parse(data);

                    that.cache.app = appInfoEnhanced;
                    that.credentials.app = new Registration( that.cache.app.mac_key, that.cache.app.mac_key_id );

                    makeOAuthURL( apiRootUrl );
                }
            });
        });

    } else if( params.mac_key && params.mac_key_id ) {

        that.credentials.app = new Registration( params.mac_key, params.mac_key_id );
        if( params.id ) {
            that.cache.app = that.cache.app || {};
            that.cache.app.id = params.id;
            that.appGet(function(err, app) {
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

var get = function( cb ) {
    var that = this;
    if( !that.credentials.app || !that.cache.app || !that.cache.app.id ) {
        cb( 'App not registered or id not found', null );
        return;
    }

    that.apiCall({
        url: '/apps/' + that.cache.app.id,
        method: 'GET',
        mac_key: that.credentials.app.mac_key,
        mac_key_id: that.credentials.app.mac_key_id,
        onResult: function(err, headers, data) {
            if(err) { cb(err); return; }
            that.cache.app = JSON.parse( data );
            cb(null, that.cache.app);
        }
    }, cb);
};

var update = function( appInfo, cb ) {

    var that = this;
    if( !that.credentials.app || !that.cache.app || !that.cache.app.id ) {
        cb( 'App not registered or id not found', null );
        return; // TODO factorize
    }

    that.apiCall({
        url: '/apps/' + that.cache.app.id,
        method: 'PUT',
        body: JSON.stringify( appInfo ),
        mac_key: that.credentials.app.mac_key,
        mac_key_id: that.credentials.app.mac_key_id,
        onResult: function(err, headers, data) {
            if(err) {
                cb(err);
                return;
            }

            console.log('headers: ' + JSON.stringify(headers));

            that.cache.app = JSON.parse( data );
            cb(null, that.cache.app);
        }
    }, cb);
};

var delete_ = function( cb ) {

    var that = this;
    if( !that.credentials.app || !that.cache.app || !that.cache.app.id ) {
        cb( 'App not registered or id not found', null );
        return; // TODO factorize
    }

    that.apiCall({
        url: '/apps/' + that.cache.app.id,
        method: 'DELETE',
        mac_key: that.credentials.app.mac_key,
        mac_key_id: that.credentials.app.mac_key_id,
        onResult: function(err, headers, data) {
            if(err) { cb(err); return; }
            cb(null);
        }
    }, cb);
};

module.exports = function(proto) {
    proto.discovery = discovery;
    proto.getApiRoot = getApiRoot;

    proto.appRegister = register;
    proto.appGet = get;
    proto.appUpdate = update;
    proto.appDelete = delete_;
};
