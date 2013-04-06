utils = require './utils'

class MacCredentials
    constructor: ( @mac_key, @mac_key_id ) ->
        @mac_algorithm = 'hmac-sha-256'

    getAuthorization: (opts) ->
        return utils.createHmacAuth opts, @mac_key, @mac_key_id

module.exports = (type, rest...) ->
    if type == 'hmac-sha-256'
        new MacCredentials rest[0], rest[1]
    else
        throw new Error 'Credentials type not found!'
