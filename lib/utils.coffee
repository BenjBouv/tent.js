crypto = require 'crypto'
config = require 'config'

exports.generateUniqueToken = (cb) ->
    crypto.randomBytes 32, (_, buf) ->
        token = buf.toString 'hex'
        cb token

exports.debug = (str, obj) ->
    if config.debug
        console.log str + ': ' + JSON.stringify(obj) + '\n'

exports.isSecured = isSecured = ( opts ) ->
    opts.protocol == 'https:'

getPort = (opts) ->
    port = opts.port
    if !port
        port = if isSecured opts then 443 else 80
    port

exports.createHmacAuth = ( opts, mk, mkid ) ->
    path = opts.path
    host = opts.host
    method = opts.method
    port = getPort opts

    nonce = ''
    while nonce.length < 5
        c = crypto.randomBytes 1
        if /[a-z0_9]/.test c
            nonce += c

    timestamp = parseInt (new Date()).getTime() / 1000, 10
    normalizedReqString = [timestamp, nonce, method, path, host, port].join('\n') + '\n\n'

    hmac = crypto.createHmac 'sha256', mk
    hmac.update normalizedReqString
    digest = hmac.digest 'base64'

    ['MAC id="' + mkid, 'ts="' + timestamp, 'nonce="' + nonce, 'mac="' + digest].join '", '

