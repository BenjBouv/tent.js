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

            @call reqParam, (err, h, data) =>
                if err
                    cb err
                    return

                appInfo = JSON.parse data
                if @id and appInfo.id == @id
                    @info = appInfo
                cb null, appInfo
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

            if not @info
                cb 'no application info!'
                return

            # required parameters
            if not @id or not @info.redirect_uri
                cb 'missing required parameters when getting auth url: client_id, redirect_uri!'

            scopes = @info.scopes || {}
            scopes_str = Object.keys( scopes ).join ','

            profiles = @profile_info_types || []
            profiles_str = profiles.map(@client.profile.expand).join ','

            posts = @post_types || []
            posts_str = posts.map(@client.posts.expand).join ','

            utils.generateUniqueToken (state) =>
                @state = state
                authUrl = apiRootUrl + '/oauth/authorize?client_id=' + @id +
                    '&redirect_uri=' + @info.redirect_uris[0] +
                    '&response_type=code' +
                    '&state=' + state

                if scopes_str.length > 0
                    authUrl += '&scope=' + scopes_str

                if profiles_str.length > 0
                    authUrl += '&tent_profile_info_types=' + profiles_str

                if posts_str.length > 0
                    authUrl += '&tent_post_types=' + posts_str

                if @notification_url
                    authUrl += '&tent_notification_url=' + @notification_url

                cb null, authUrl, @info
        @

    register: (appInfo, cb) =>
        reqParam =
            url: '/apps'
            method: 'POST'
            body: JSON.stringify appInfo

        @profile_info_types = appInfo.profile_info_types || []
        @post_types = appInfo.post_types || []
        @notification_url = appInfo.notification_url || ''

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
        if not @state
            cb 'no application state!'
            return

        if @state != state
            cb 'state different than the one used in registration.'
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
