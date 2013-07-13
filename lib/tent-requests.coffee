Request = require './requests'
Hawk = require 'hawk'

class TentRequest extends Request

    TentRequest::CONTENT_TYPE =
        all: '*/*'
        json: 'application/json'
        post: 'application/vnd.tent.post.v0+json'
        feed: 'application/vnd.tent.posts-feed.v0+json'
        error: 'application/vnd.tent.error.v0+json'
        attachment: 'multipart/form-data'

    TentRequest::parseLink = (link) ->
        linkpart = /<([^>]*)>/.exec link
        relpart = /; rel="(.*)"/.exec link

        if linkpart.length < 1 or relpart.length < 1 then return null

        return {
            link: linkpart[1]
            rel: relpart[1]
        }

    constructor: (client) ->
        if not client
            throw 'No client given on TentRequest initialization!'
        @client = client
        @entity = client.entity

        @needAuth = false
        @auth = null
        super

    setBody: (post) ->
        if post.type
            post.type = TentRequest::POST_TYPE[post.type] || post.type
        super post

    accept: (type) ->
        @addHeader 'Accept', TentRequest::CONTENT_TYPE[ type ] || type

    postType: (type, fragment) ->
        contentType = TentRequest::CONTENT_TYPE['post']
        contentType += '; type="' + (TentRequest::POST_TYPE[type] || type)

        if fragment
            contentType += fragment
        contentType += '"'
        @addHeader 'Content-Type', contentType

    setAuthNeeded: (type) ->
        @needAuth = type

    # Finds the URL corresponding to an endpoint as specified in the meta post
    TentRequest::lookupEndpoint = (meta, lookup) ->
        # Finds the preferred server and lookup the url
        meta.content.servers.sort( (a,b) =>
            if a.preference < b.preference
                return -1
            else if a.preference == b.preference
                return 0
            else
                return 1
        )[0].urls[lookup] || null

    genericRun: (cb) ->
        @run (maybeError, post, headers) ->
            cb maybeError, post

    prepareAuth: (cb) ->
        hawkHeader = null
        if @needAuth
            if @needAuth == 'app'
                if not @client.appCred
                    cb 'TentRequest.run: app auth needed but no credentials given. Request aborted'
                    return
                else
                    credObj = @client.appCred
            else if @needAuth == 'user'
                if not @client.userCred
                    cb 'TentRequest.run: client auth needed but no credentials given. Request aborted'
                    return
                else
                    credObj = @client.userCred
            else
                cb 'TentRequest.run: unknown auth needed method'
                return

            credentials =
                id: credObj.id
                key: credObj.hawk_key
                algorithm: credObj.hawk_algorithm
            authParams =
                credentials: credentials
                app: @client.appId
            hawkHeader = Hawk.client.header @url, @method, authParams
            hawkHeader = hawkHeader.field

        cb null, hawkHeader
        @

    run: (cb) ->
        if @url[0] == '/' then @url = @entity + @url
        if @url[0] == '@'
            @client.getMeta (maybeError, meta) =>
                if maybeError
                    cb maybeError
                    return
                lookup = @url.slice 1
                @url = TentRequest::lookupEndpoint meta, lookup
                if @url == null
                    cb 'Tent request run: no URL found for ' + lookup
                    return

                @prepareAuth (maybeError, authHeader) =>
                    if maybeError
                        cb maybeError
                        return

                    if authHeader then @addHeader 'Authorization', authHeader
                    super cb
        else
            @prepareAuth (maybeError, authHeader) =>
                if maybeError
                    cb maybeError
                    return

                if authHeader then @addHeader 'Authorization', authHeader
                super cb
        @

module.exports = TentRequest
