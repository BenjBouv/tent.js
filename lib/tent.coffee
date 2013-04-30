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

    prefixEntity: (link) ->
        if link[0] == '/' then return @entity + link else return link

    discovery: (cb) ->

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

            metaURL = utils.parseLink(headers.link).link
            metaURL = @prefixEntity metaURL

            # Get meta post
            getMetaParams =
                url: metaURL
                method: 'GET'

            cb2 = (erz, headerz, dataz) =>
                if erz then cb erz
                else
                    @meta = dataz
                    cb null, @meta

            new Request( getMetaParams, cb2 ).run()

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

    getMeta: (cb) ->
        if @meta
            cb null, @meta
            return

        @discovery cb

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
