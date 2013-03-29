var url = require('url');
var utils = require('./utils');

var Opts = function( cibleUrl, method ) {
    this.opts = url.parse( cibleUrl );
    this.opts.method = method;
    this.opts.headers = {
        "Accept" : "application/vnd.tent.v0+json"
    };
};

Opts.prototype.addBody = function( body ) {
    this.opts.headers["Content-Type"] = "application/vnd.tent.v0+json";
    this.opts.headers["Content-Length"] = body.length.toString();
};

Opts.prototype.addAuth = function( mac_key, mac_key_id ) {
    this.opts.headers['Authorization'] = utils.createHmacAuth( this.opts, mac_key, mac_key_id );
};

Opts.prototype.get = function() {
    return this.opts;
}

exports.Opts = Opts;
