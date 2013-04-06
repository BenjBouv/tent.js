class MacRegistration
    constructor: ( @mac_key, @mac_key_id) ->
        @mac_algorithm = 'hmac-sha-256'

    addParams: ( req ) ->
        req.mac_key = @mac_key
        req.mac_key_id = @mac_key_id
        @

module.exports = () ->
    type = arguments[0]
    if type == 'hmac-sha-256'
        new MacRegistration arguments[1], arguments[2]
    else
        throw new Error 'Registration type not found!'
