utils = require './utils'
#Credentials = require './credentials'
TentRequest = require './tent-requests'
SubModule = require './submodule'

class Application extends SubModule

    Application::AUTH_TOKEN_TYPE = 'https://tent.io/oauth/hawk-token'

    authUrl: (cb) ->
        if not @client.appId
            cb 'Application/Client.authUrl: no app ID provided!'
            return

        @client.getMeta (maybeError, meta) =>
            if maybeError
                cb maybeError
                return

            utils.generateUniqueToken (state) =>
                @state = state
                url = TentRequest::lookupEndpoint meta, 'oauth_auth'
                url += '?client_id=' + @client.appId + '&state=' + @state
                cb null, url
        @

    register: (appInfo, cb) =>
        r = @createRequest()
        r.url = '@new_post'
        r.method = 'POST'
        r.postType 'app'
        appPost =
            type: 'app'
            content: appInfo
            permissions:
                public: false
        r.setBody appPost

        r.run (maybeError, appInfo, headers) =>
            if maybeError
                cb maybeError
                return

            if not headers.link
                cb 'App.register: No link in headers'
                return

            link = TentRequest.prototype.parseLink(headers.link).link
            @info = appInfo

            @client.setAppId appInfo.id
            @client.appPost = appInfo

            # Get credentials post
            getCredReq = @createRequest()
            getCredReq.url = link
            getCredReq.method = 'GET'
            getCredReq.accept 'post'

            getCredReq.run (maybeError2, appCred, headers2) =>
                if maybeError2
                    cb maybeError2
                    return

                @client.setAppCredentials appCred
                cb null, @client.appPost, appCred

        @

    # Trades the code, checks the state and calls cb(maybeError, client auth post)
    tradeCode: ( code, state, cb ) =>
        if not @client.appId
            cb 'app.tradeCode: no application id!\n'
            return

        if not @state
            cb 'app.tradeCode: no application state!\n'
            return

        ###
        if @state != state
            cb 'app.tradeCode: state different than the one used in registration.\n' + new Error().stack
            return
        ###

        r = @createRequest()
        r.url = '@oauth_token'
        r.method = 'POST'
        r.postType 'json'
        r.accept 'json'
        r.setBody
            code: code
            token_type: Application::AUTH_TOKEN_TYPE
        r.setAuthNeeded('app')
        r.genericRun cb
        @

module.exports = Application
