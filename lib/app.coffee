utils = require './utils'
Credentials = require './credentials'
SubModule = require './submodule'

class Application extends SubModule

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
                urlWrapper =
                    url: 'oauth_auth'
                url = @client.reqFactory.prepare(urlWrapper).url
                url += '?client_id=' + @id + '&state=' + @state
                cb null, url
        @

    register: (appInfo, cb) =>
        appPost =
            type: 'app'
            content: appInfo
            permissions:
                public: false

        rcb = (err, h, appPostResponse) =>
            if err
                cb err
                return

            if not h.link
                cb 'No link in headers'
                return

            link = utils.parseLink(h.link).link
            @info = appPostResponse
            @client.setAppId appPostResponse.id

            # Get credentials post
            getCredParam =
                url: link
                method: 'GET'
                accept: 'post'

            cb2 = (erz, headerz, appCredentials) =>
                if erz
                    cb erz
                    return

                @client.setAppCredentials appCredentials
                cb null, @info, appCredentials

            @call getCredParam, cb2

        @client.posts.createApp appPost, rcb
        @

    tradeCode: ( code, state, cb ) =>
        if not @id
            cb 'tradeCode: no application id!\n' + new Error().stack
            return

        ###
        if not @state
            cb 'tradeCode: no application state!\n' + new Error().stack
            return

        if @state != state
            cb 'tradeCode: state different than the one used in registration.\n' + new Error().stack
            return
        ###
        # TODO for test purpose only

        reqParam =
            url: 'oauth_token'
            method: 'POST'
            body: JSON.stringify
                code: code
                token_type: Credentials.types['hawk']

            needAuth: true
            auth: @client.credentials.app

        headers =
            'Content-Type': 'application/json'
            'Accept': 'application/json'

        @call reqParam, utils.makeGenericCallback(cb), headers
        @

module.exports = Application
