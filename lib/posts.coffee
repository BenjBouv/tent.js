qs = require 'querystring'

utils = require './utils'
Request = require './requests'
SubModule = require './submodule'

class Posts extends SubModule

    Posts::TYPES =
        status:
            required: []
            url: 'https://tent.io/types/status/v0#'
        app:
            required: []
            url: 'https://tent.io/types/app/v0#'

    get: (params, cb) ->
        reqParam =
            url: 'posts_feed'
            additional: params
            accept: 'feed'
            method: 'GET'
            appId: @client.app.id
            auth: @client.credentials.user # TODO facultative, for public posts

        @call reqParam, utils.makeGenericCallback cb

    spawnParams: (postObj, method) ->
        method ?= 'POST'
        reqParam =
            url: 'new_post'
            method: method
            contentType: 'post'
            postType: postObj.type
            body: JSON.stringify postObj
        return reqParam

    createApp: (app, cb) ->
        app.type = @expand app.type
        params = @spawnParams app, 'POST'
        @call params, cb

    create: (postObj, cb, method ) ->
        postObj.type = @expand postObj.type
        # TODO check that every required field is present

        params = @spawnParams postObj, method
        params.needAuth = true
        params.auth = @client.credentials?.user || null

        @call params, utils.makeGenericCallback cb
        @

        ###
        essay:
            required: ['body']
            url: 'https://tent.io/types/post/essay/v0.1.0'

        photo:
            required: []
            url: 'https://tent.io/types/post/photo/v0.1.0'

        album:
            required: ['photos']
            url: 'https://tent.io/types/post/album/v0.1.0'

        repost:
            required: ['entity', 'id']
            url: 'https://tent.io/types/post/repost/v0.1.0'

        profile:
            required: ['types', 'action']
            url: 'https://tent.io/types/post/profile/v0.1.0'

        delete:
            required: ['id']
            url: 'https://tent.io/types/post/delete/v0.1.0'

        following:
            required: ['id', 'entity', 'action']
            url: 'https://tent.io/types/post/following/v0.1.0'

        followers:
            required: ['id', 'entity', 'action']
            url: 'https://tent.io/types/post/follower/v0.1.0'
        ###

    Posts::REQUIRED_BY_ALL = ['type', 'content', 'permissions']

    checkRequiredFields: ( type, obj ) ->
        r = Posts::REQUIRED_BY_ALL
        valid = ( !! obj[field] for field in r ).reduce (a,b) ->
            a and b
        , true

        found = Posts::TYPES[type]
        if found
            valid &= ( !! obj.content[ field ] for field in found.required ).reduce (a,b) ->
                a and b
            , true

        valid

    expand: ( type ) ->
        found = Posts::TYPES[type]
        if found then found.url else type

module.exports = Posts
