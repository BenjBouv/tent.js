utils = require './utils'

AppModule = require './app'
#PostsModule = require './posts'
#ProfileModule = require './profile'
#FollowingModule = require './following'
#FollowerModule = require './followers'

TentRequest = require './tent-requests'

#Credentials = require './credentials'
Synq = require './synq'

class Client
    constructor: (@entity) ->
        # sub-modules
        @app = new AppModule @
        #@posts = new PostsModule @

        # properties
        @queue = new Synq
        @appId = null
        @appPost = null
        @appCred = null
        @clientCred = null

    # Applies the discovery dance and returns the meta post to the callback
    # Param: cb(maybeError, meta)
    discovery: (cb) ->
        req = new TentRequest @
        req.url = @entity
        req.method = 'HEAD'
        req.accept 'all'

        req.run (maybeError, body, headers) =>
            if maybeError
                cb maybeError
                return

            if not headers.link
                cb 'Link section not found in headers during discovery'
                return

            metaURL = TentRequest.prototype.parseLink(headers.link).link

            # Get meta post
            getMetaReq = new TentRequest @
            getMetaReq.url = metaURL
            getMetaReq.method = 'GET'
            getMetaReq.accept 'post'

            getMetaReq.run (maybeError2, body2, headers2) =>
                if maybeError2
                    cb maybeError2
                    return

                metaPost = body2.post
                @meta = metaPost
                cb null, @meta
        @

    # cb(maybeError, meta)
    getMeta: (cb) ->
        @queue.push () =>
            @getMetaCall (err, meta) =>
                cb err, meta
                @queue.free()
        @

    getMetaCall: (cb) ->
        if @meta
            cb null, @meta
        else
            @discovery cb
        @

    # cb(maybeError, full auth url)
    authUrl: (cb) ->
        @app.authUrl cb
        @

    setAppId: (appId) ->
        @appId = appId
        @

    setUserCredentials: (userAuthObj) ->
        userAuthObj.id = userAuthObj.access_token
        @userCred = userAuthObj
        @

    setAppCredentials: (appAuthObj) ->
        if appAuthObj.content
            id = appAuthObj.id
            appAuthObj = appAuthObj.content
            appAuthObj.id = id
        @appCred = appAuthObj

        if not @appId
            @appId = appAuthObj.id

        @

module.exports = Client
