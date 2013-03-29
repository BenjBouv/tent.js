var utils = require('./utils');
var requests = require('./requests');

// map< apiRootUrl, object>
var apps = {};
var states = {};

var debug = true;
function print(msg, obj) {
    if(debug)
        console.log( msg + ': ' + JSON.stringify(obj) );
}

function headProfile(entityUrl, cb /* (profileUrl) */) {

    var reqParams = {
        url: entityUrl,
        method: 'HEAD',
        body: null,
        onResult: function(err, headers, data) {
            print("headProfile:headers", headers);

            // the link looks like this: <https:// ... >, we want it
            var profileUrl = /<[^>]*>/.exec(headers.link);
            // now we want to get rid of the '<' and '>'
            profileUrl = (""+profileUrl).replace(/[<>]/g,'');

            print("profileUrl",profileUrl);
            cb( profileUrl );
        }
    };

    requests.run( reqParams );
};

exports.registerApp = function registerApp(entityUrl, appInfo, cb /*function( OAuthURL )*/ ) {
    getProfile( entityUrl, function( profile ) {
            var core = profile["https://tent.io/types/info/core/v0.1.0"];
        generateAuthenticationUrl( core, appInfo, cb );
    });
}

var cacheProfiles = {};
function getProfile(entityUrl, cb) {
    if( !cacheProfiles[ entityUrl ] ) {
        headProfile( entityUrl, function( profileUrl ) {

            var reqParam = {
                url: profileUrl,
                method: 'GET',
                body: null,
                onResult: function(err, headers, data) {
                    print("getProfile:headers", headers);
                    var profile = JSON.parse(data);
                    cacheProfiles[ entityUrl ] = profile;
                    cb( profile );
                }
            };
            requests.run( reqParam );

        } );
    } else {
        cb( cacheProfiles[ entityUrl ] );
    }
};

function getApiRoot( entityUrl, cb ) {
    getProfile( entityUrl, function( profile ) {
        var core = profile["https://tent.io/types/info/core/v0.1.0"];
        cb( core.servers[0] );
    });
};

function generateAuthenticationUrl(profileCore, appInfo, cb) {
    var content = JSON.stringify( appInfo );
    var apiRootUrl = profileCore.servers[0];

    var reqParam = {
        url: apiRootUrl + '/apps',
        method: 'POST',
        body: content,
        onResult: function(err, headers, data) {

            print('postApps:headers', headers);
            var components = JSON.parse(data);
            print('components', components);

            if( !components.scopes ) {
                // TODO handle error
                console.error("no components scopes...");
                return;
            }

            apps[ apiRootUrl ] = {
                components: components
            };

            makeOAuthURL( apiRootUrl, cb );
        }
    };

    requests.run( reqParam );
}

function makeOAuthURL( apiRootUrl, cb ) {
    var components = apps[ apiRootUrl ].components;
    var scope = Object.keys(components.scopes).join(',');

    utils.generateUniqueToken(function(stateString) {
        var oauthUrl = apiRootUrl +
            '/oauth/authorize?client_id=' + components.id +
            '&redirect_uri=' + components.redirect_uris[0] +
            '&scope=' + scope +
            '&response_type=code' +
            '&state=' + stateString +
            '&tent_profile_info_types=all' +
            '&tent_post_types=all';
        states[ stateString ] = apiRootUrl;
        cb( oauthUrl, components );
    });
};

exports.finishRegistration = finishRegistration;
function finishRegistration(code, stateString, cb) {

    var apiRootUrl = states[ stateString ] || null;
    if( apiRootUrl == null ) {
        console.error('no state string corresponding to an apiRootUrl...');
        cb('state_string_not_found'); // TODO
        return;
    }

    delete states[ stateString ];
    var oauthComponents = apps[ apiRootUrl ].components;
    var mac_key = oauthComponents.mac_key;
    var mac_key_id = oauthComponents.mac_key_id;

    var requestBody = JSON.stringify({
        'code' : code,
        'token_type' : "mac"
    });

    var reqParam = {
        url: apiRootUrl + '/apps/' + oauthComponents.id + '/authorizations',
        method: 'POST',
        body: requestBody,
        mac_key: mac_key,
        mac_key_id: mac_key_id,
        onResult: function( err, headers, data ) {
            print('auth.headers', headers);
            var behalfUser = JSON.parse( data );
            cb( behalfUser );
        }
    };
    requests.run( reqParam );
}

exports.getPosts = function( entityUrl, mac_key, mac_key_id, cb /* posts */ ) {
    getApiRoot( entityUrl, function( apiRootUrl ) {
        var reqParam = {
            url: apiRootUrl + '/posts',
            method: 'GET',
            mac_key: mac_key,
            mac_key_id: mac_key_id,
            onResult: function( err, headers, data) {
                cb( JSON.parse(data) );
            }
        };

        requests.run(reqParam);
    });
};
