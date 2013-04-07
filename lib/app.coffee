utils = require './utils'
Credentials = require './credentials'
Request = require './requests'
SubModule = require './submodule'

class Application extends SubModule

    setId: (id) ->
        @id = id
        @

    _getId: ( args, cb ) ->
        if args.length == 2
            cb( args[0], args[1] )
        else
            if not @id
                throw new Error 'no application id!'
            cb( @id, args[0] )
        @

    get: ( ) =>
        @_getId arguments, (id, cb) =>
            reqParam =
                url: '/apps/' + id
                method: 'GET'
                needAuth: true
                auth: @client.credentials.app

            rcb = utils.makeGenericCallback cb
            @call reqParam, rcb
        @

    update: ( appInfo, rest... ) =>
        @_getId rest, (id, cb) =>

            reqParam =
                url: '/apps/' + id
                method: 'PUT'
                body: JSON.stringify appInfo
                needAuth: true
                auth: @client.credentials.app

            rcb = utils.makeGenericCallback cb
            @call reqParam, rcb
        @

    delete: ( ) =>
        @_getId arguments, (id, cb) =>
            reqParam =
                url: '/apps/' + id
                method: 'DELETE'
                needAuth: true
                auth: @client.credentials.app

            rcb = utils.makeGenericCallback cb
            @call reqParam, rcb
        @

    Application::States = {}

    getAuthUrl: (cb) =>
        @client.getApiRoot (err, apiRootUrl) =>
            if err
                cb err
                return

            if not @id
                cb 'no application id!'
                return

            utils.generateUniqueToken (state) =>
                @state = state
                authUrl = apiRootUrl + '/oauth/authorize?client_id=' + @id +
                    '&redirect_uri=' + @info.redirect_uris[0] +
                    '&scope=' + Object.keys(@info.scopes).join(',') +
                    '&response_type=code' +
                    '&state' + state +
                    '&tent_profile_info_types=all' + # TODO
                    '&tent_post_types=all' + # TODO
                    ''
                cb null, authUrl, @info
        @

    register: (appInfo, cb) =>
        reqParam =
            url: '/apps'
            method: 'POST'
            body: JSON.stringify appInfo

        rcb = (err, h, data) =>
            if err
                cb err
                return

            a = @info = JSON.parse data
            @id = @info.id

            @client.setAppCredentials @info.mac_key, @info.mac_key_id
            @getAuthUrl cb

        @call reqParam, rcb
        @

    tradeCode: ( code, state, cb ) =>
        if not @id
            cb 'no application id!'
            return

        reqParam =
            url: '/apps/' + @id + '/authorizations'
            method: 'POST'
            body: JSON.stringify
                code: code
                token_type: 'mac'
            needAuth: true
            auth: @client.credentials.app

        rcb = (err, h, data) =>
            if err
                cb err
                return

            response = JSON.parse data
            @client.setUserCredentials response.mac_key, response.access_token
            cb null, @client.credentials.user

        @call reqParam, rcb
        @


module.exports = Application
