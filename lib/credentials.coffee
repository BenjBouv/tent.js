utils = require './utils'
Hawk = require 'hawk'

class HawkAuth
    constructor: ( id, key, algorithm, @app ) ->
        @credentials =
            id: id
            key: key
            algorithm: algorithm

    make: ( url, method ) ->
        ###
        utils.debug 'credentials', @credentials
        utils.debug 'url', url
        utils.debug 'method', method
        utils.debug 'appId', appId
        ###

        return Hawk.client.header(url, method,
            credentials: @credentials
            app: @app.id
        ).field

HawkTokenType = "https://tent.io/oauth/hawk-token"

module.exports =
    types:
        hawk: HawkTokenType

    make: ( authObj, app ) ->
        # default token type is hawk token type (used for apps)
        authObj.token_type ?= HawkTokenType

        if authObj.token_type == HawkTokenType
            return new HawkAuth authObj.id, authObj.hawk_key, authObj.hawk_algorithm, app
        else
            throw new Error 'When creating Credentials, unknown token type: ' + authObj.token_type + '\n' + new Error().stack

