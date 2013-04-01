var requests = require('./requests'),
    utils = require('./utils');

var makeCredentials = require('./registration');

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

Client.prototype.states = {};
Client.prototype.setState = function( str, value ) {
    Client.prototype.states[ str ] = value;
}

Client.prototype.clientRegister = function() {
    this.credentials.user = makeCredentials.apply(this, arguments);
};

exports.clientRegister = function( code, state, cb ) {
    var client = Client.prototype.states[ state ] || null;
    if( client == null ) {
        cb('State string not found...');
        return;
    }

    delete Client.prototype.states[ state ];

    var requestBody = JSON.stringify({
        'code' : code,
        'token_type' : "mac" // TODO here
    });

    var reqParam = {
        url: '/apps/' + client.cache.app.id + '/authorizations',
        method: 'POST',
        body: requestBody,

        needAuth: true,
        auth: client.credentials.app,

        onResult: function( err, headers, data ) {
            var data = JSON.parse(data);
		utils.debug( 'data', data );
		utils.debug( 'data.mac_algorithm', data.mac_algorithm );
            client.credentials.user = makeCredentials( data.mac_algorithm, data.mac_key, data.access_token );
            cb( null, client.credentials.user );
        }
    };

    client.apiCall( reqParam, cb );
};

Client.prototype.apiCall = function(reqParam, cb) {
    this.getApiRoot( function(err, apiRootUrl) {

        if( err ) {
            cb( err );
            return;
        }

        reqParam.url = apiRootUrl + reqParam.url;

        if( reqParam.needAuth ) {
            if( reqParam.auth ) {
                reqParam.auth.addParams( reqParam );
            } else {
                cb('Credentials not found');
                return;
            }
        }
        requests.run( reqParam );
    });
};

require('./app') ( Client.prototype );
require('./profile') ( Client.prototype );
require('./posts') ( Client.prototype );

exports.Client = Client;

