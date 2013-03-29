var http = require('http'),
    https = require('https');

var utils = require('./utils');
var Opts = require('./opts').Opts;

exports.run = function( params ) {
    var opts = new Opts( params.url, params.method );

    if( params.body ) {
        opts.addBody( params.body );
    }

    if( params.mac_key && params.mac_key_id ) {
        opts.addAuth( params.mac_key, params.mac_key_id );
    }

    opts = opts.get();

    var isSecured = utils.isSecured(opts);
    var reqMeth = ( isSecured )? https.request : http.request;

    var req = reqMeth( opts, function(res) {
        var data = '';
        res.on('data', function(chunk) { data += chunk; });
        res.on('end', function() {
            params.onResult( null, res.headers, data );
        });
    });
    req.on('error', params.onResult);
    if( params.body ) {
        req.end( params.body );
    } else {
        req.end();
    }
};
