qs = require 'querystring'

utils = require './utils'
SubModule = require './submodule'

class Posts extends SubModule

    Posts::TYPES =
        status:
            required: []
            url: 'https://tent.io/types/post/status/v0.1.0'

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

    get: ( params, cb ) =>
        url = '/posts'

        req =
            url: url
            additional: params
            method: 'GET'

        if @client.credentials.user
            req.needAuth = true
            req.auth = @client.credentials.user

        rcb = utils.makeGenericCallback cb

        @call req, rcb
        @

    createOrUpdate: ( params, cb, update ) =>
        if not @checkRequiredFields params.type, params
            cb 'Missing field when creating or updating post.'
            return

        url = '/posts'

        if update
            method = 'PUT'
            url += '/' + qs.escape update
        else
            method = 'POST'

        params.type = @expand params.type
        reqParam =
            url: url
            method: method
            body: JSON.stringify params
            needAuth: true
            auth: @client.credentials.user
        rcb = (err, headers, data) ->
            if err
                cb err
            else
                cb null, JSON.parse data

        @call reqParam, rcb
        @

    create: (params, cb) ->
        @createOrUpdate params, cb
        @

    update: (id, params, cb) ->
        @createOrUpdate params, cb, id
        @

    delete: (id, params, cb) ->
        url = '/posts/' + qs.escape id

        reqParam =
            url: url
            additional: params
            method: 'DELETE'
            needAuth: true
            auth: @client.credentials.user

        @call reqParam, cb
        @

module.exports = Posts
