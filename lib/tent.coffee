utils = require './utils'

Request = require './requests'

AppModule = require './app'
PostsModule = require './posts'
ProfileModule = require './profile'
FollowingModule = require './following'
FollowerModule = require './followers'

Credentials = require './credentials'

class Client
    constructor: (@entity) ->
        @app = new AppModule @
        @posts = new PostsModule @
        @profile = new ProfileModule @
        @followings = new FollowingModule @
        @followers = new FollowerModule @

        @queue = []
        @queueBusy = false

        @credentials = {}

    discovery: (cb) ->
        if @profileUrl
            cb null, @profileUrl
            return

        reqParam =
            url: @entity
            method: 'HEAD'

        rcb = (err, headers, data) =>
            if err
                cb err, null
                return
            if not headers.link
                cb 'Link section not found in headers during discovery'
                return

            @profileUrl = /<[^>]*>/.exec headers.link
            @profileUrl = ( ""+@profileUrl ).replace /[<>]/g, ''
            cb null, @profileUrl

        r = new Request reqParam, rcb,
            "Accept": "*/*"

        r.run()

        @

    queueFree: ->
        @queueBusy = false
        @queueEmpty()
        @

    queueEmpty: ->
        if not @queueBusy and @queue.length > 0
            @queueBusy = true
            f = @queue.pop()
            f()
        @

    getProfile: (cb) ->
        @queue.push () =>
            @getProfileLaunch (err, data) =>
                cb err, data
                @queueFree()

        @queueEmpty()
        @

    getProfileLaunch: (cb) ->
        if @profiles
            cb null, @profiles
            return

        @discovery (err, pURL) =>
            if err
                cb err
                return

            reqParam =
                url: pURL
                method: 'GET'
            rcb = (err, headers, data) =>
                @profiles = data
                @queueFree()
                cb null, @profiles

            r = new Request reqParam, rcb
            r.run()

    getApiRoot: (cb) ->
        if @apiRoot
            cb null, @apiRoot
            return

        @getProfile (err, p) =>
            if err
                cb err
                return

            core = p[ "https://tent.io/types/info/core/v0.1.0" ]
            if core and core.servers and core.servers.length > 0
                @apiRoot = core.servers[0]
                if @apiRoot[ @apiRoot.length-1 ] == '/'
                    @apiRoot = @apiRoot.slice 0, @apiRoot.length - 1

                cb null, @apiRoot
            else
                cb 'profile key error: no core or servers'
        @

    # TODO do not depend on mk and mkid
    setUserCredentials: (mk, mkid) ->
        @credentials.user = Credentials 'hmac-sha-256', mk, mkid
        @

    setAppCredentials: (mk, mkid) ->
        @credentials.app = Credentials 'hmac-sha-256', mk, mkid
        @

module.exports = Client
