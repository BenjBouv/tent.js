var MacRegistration = function( mac_key, mac_key_id ) {
    this.mac_key = mac_key;
    this.mac_key_id = mac_key_id;
    this.mac_algorithm = 'hmac-sha-256';
};

MacRegistration.prototype.addParams = function( req ) {
    req.mac_key = this.mac_key;
    req.mac_key_id = this.mac_key_id;
};

var make = function( ) {
    var type = arguments[0];
    if( type === 'hmac-sha-256' ) {
        return new MacRegistration( arguments[1], arguments[2] );
    } else {
        throw 'Registration type not found!';
    }
};

module.exports = make;

