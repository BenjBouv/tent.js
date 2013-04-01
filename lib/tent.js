var requests = require('./requests'),
    utils = require('./utils');

var Registration = require('./registration');


var Client = function(entityURI) {

    if( !entityURI ) {
        throw 'no entity uri given at instanciation!';
    }

    this.entityURI = entityURI;

    this.credentials = {};
    this.credentials.app = null;
    this.credentials.user = null;

    this.cache = {};
};

require('./app') ( Client.prototype );
require('./profile') ( Client.prototype );

Client.prototype.states = {};
Client.prototype.setState = function( str, value ) {
	Client.prototype.states[ str ] = value;
}

Client.prototype.clientRegister = function(mac_key, mac_key_id) {
    // TODO hide mac stuff
    this.credentials.user = new Registration( mac_key, mac_key_id );
};

exports.clientRegister = function( code, state, cb ) {
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
        url: '/apps/' + client.cache.app.id + '/authorizations',
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

