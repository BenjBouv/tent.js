utils = require './utils'

AppModule = require './app'
PostsModule = require './posts'
#ProfileModule = require './profile'
#FollowingModule = require './following'
#FollowerModule = require './followers'

RequestFactory = require './reqfactory'

Credentials = require './credentials'
Synq = require './synq'

class Client
    constructor: (@entity) ->
        @app = new AppModule @
        @posts = new PostsModule @
        @queue = new Synq
        @credentials = {}

        @reqFactory = new RequestFactory @entity

    discovery: (cb) ->

        reqParam =
            url: @entity
            method: 'HEAD'
            accept: 'post'

        rcb = (err, headers, data) =>
            if err
                cb err, null
                return

            if not headers.link
                cb 'Link section not found in headers during discovery'
                return

            metaURL = utils.parseLink(headers.link).link

            # Get meta post
            getMetaParams =
                url: metaURL
                method: 'GET'
                accept: 'post'

            cb2 = (erz, headerz, dataz) =>
                if erz then cb erz
                else
                    @meta = dataz
                    @reqFactory.setMeta @meta
                    cb null, @meta

            @reqFactory.create( getMetaParams, cb2 ).run()

        r = @reqFactory.create reqParam, rcb,
            "Accept": "*/*"
        r.run()

        @

    getMeta: (cb) ->
        @queue.push () =>
            @getMetaCall (err, meta) =>
                cb err, meta
                @queue.free()
        @

    getMetaCall: (cb) ->
        if @meta
            cb null, @meta
            return

        @discovery cb
        @

    getAuthUrl: (cb) ->
        @app.getAuthUrl cb
        @

    setAppId: (appId) ->
        @app.id = appId
        @reqFactory.setAppId appId
        @

    setUserCredentials: (userAuthObj) ->
        userAuthObj.id = userAuthObj.access_token
        @credentials.user = Credentials.make userAuthObj, @app
        @

    setAppCredentials: (appAuthObj) ->

        if appAuthObj.content
            id = appAuthObj.id
            appAuthObj = appAuthObj.content
            appAuthObj.id = id

        @credentials.app = Credentials.make appAuthObj, @app
        @

module.exports = Client
