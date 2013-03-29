var crypto = require('crypto');

var generateUniqueToken = function(cb) {
    crypto.randomBytes(32, function(_, buf) {
        var token = buf.toString('hex');
        cb(token);
    });
};

var createHmacAuth = function( opts, mac_key, mac_key_id ) {
    var path = opts.path,
        host = opts.host,
        method = opts.method,
        port = getPort( opts );

    // create OAuth 2.0 Message Authentication Code (MAC) Tokens
    var nonce = "";
    while (nonce.length < 5) {
        var c = crypto.randomBytes(1);
        if(/[a-z0-9]/.test(c))
            nonce = nonce + c;
    }

    var timeStamp = parseInt((new Date()).getTime() / 1000, 10); 
    var normalizedRequestString = "" 
            + timeStamp + '\n'
            + nonce + '\n'
            + method + '\n'
            + path + '\n'
            + host + '\n'
            + port + '\n'
            + '\n' ;

    var hmac = crypto.createHmac('sha256', mac_key);
    hmac.update(normalizedRequestString);
    var digest = hmac.digest('base64');

    return 'MAC id="' + mac_key_id
        + '", ts="' + timeStamp
        + '", nonce="' + nonce
        + '", mac="' + digest
        + '"';
};

function getPort(opts) {
    var port = opts.port;
    if(! port ) {
        if( isSecured(opts) ) {
            port = 443;
        } else {
            port = 80;
        }
    }
    return port;
}

function isSecured(opts) {
    return ( opts.protocol === 'https:' )
};

exports.generateUniqueToken = generateUniqueToken;
exports.createHmacAuth = createHmacAuth;
exports.isSecured = isSecured;

