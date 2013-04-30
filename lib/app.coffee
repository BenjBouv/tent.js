Hawk = require 'hawk'

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

                appInfo = data
                if appInfo.authorizations and appInfo.authorizations.length > 0
                    @profile_info_types = appInfo.authorizations[0].profile_info_types
                    @post_types = appInfo.authorizations[0].post_types
                    @notification_url = appInfo.authorizations[0].notification_url

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

        if not @id
            cb 'No app id in getAuthUrl!'
            return

        @client.getMeta (err, meta) =>
            if err
                cb err
                return

            utils.generateUniqueToken (state) =>
                @state = state
                url = @prefixEntity meta.content.servers[0].urls.oauth_auth
                url += '?client_id=' + @id + '&state=' + @state
                cb null, url

        ###
        @client.getApiRoot (err, apiRootUrl) =>
            if err
                cb err
                return

            if not @id
                cb 'no application id!'
                return

            next = =>
                # required parameters
                if not @id or not @info.redirect_uris
                    cb 'missing required parameters when getting auth url: client_id, redirect_uris!'
                    return

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

            if not @info or not @info.name
                @get (err, appInfo) =>
                    if err
                        cb err
                        return

                    @info = appInfo
                    next()
            else
                next()
        ###
        @

    register: (appInfo, cb) =>
        appPost =
            type: 'https://tent.io/types/app/v0#'
            content: appInfo
            permissions:
                public: false

        rcb = (err, h, data) =>
            if err
                cb err
                return

            if not h.link
                cb 'No link in headers'
                return

            link = @prefixEntity utils.parseLink(h.link).link

            @info = data
            @id = @info.id

            # Get credentials post
            getCredParam =
                url: link
                method: 'GET'

            cb2 = (erz, headerz, dataz) =>
                if erz
                    cb erz
                    return

                @credentials = dataz
                cb null, @info, @credentials

            new Request(getCredParam, cb2).run()

        @newPost appPost, rcb
        @

    tradeCode: ( code, state, cb ) =>
        if not @id
            cb 'tradeCode: no application id!'
            return

        ###
        if not @state
            cb 'tradeCode: no application state!'
            return

        if @state != state
            cb 'tradeCode: state different than the one used in registration.'
            return
        ###
        # TODO for test purpose only

        @client.getMeta (err, meta) =>
            if err
                cb err
                return

            url = @prefixEntity meta.content.servers[0].urls.oauth_token
            reqParam =
                url: url
                method: 'POST'
                body: JSON.stringify
                    code: code
                    token_type: "https://tent.io/oauth/hawk-token"

            credentials =
                id: @credentials.id
                key: @credentials.content.hawk_key
                algorithm: @credentials.content.hawk_algorithm

            headers =
                'Content-Type': 'application/json'
                'Accept': 'application/json'
                'Authorization': Hawk.client.header(url, 'POST',
                    credentials: credentials
                    app: @info.id
                    ).field

            new Request(reqParam, utils.makeGenericCallback(cb), headers).run()

        @


module.exports = Application
