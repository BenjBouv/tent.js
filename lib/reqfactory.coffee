Request = require './requests'

class RequestFactory
    constructor: (@entity) ->

    setMeta: (@meta) ->

    setAppId: (@appId) ->

    prefixEntity: (link) ->
        if link[0] == '/' then @entity + link else link

    expand: (link) ->
        if @meta
            found = @meta.content.servers[0].urls[ link ]
            if found then found else link
        else
            link

    prepare: (params) ->
        params.url = @expand params.url
        params.url = @prefixEntity params.url
        params

    createAuth: (params, cb, headers) ->
        params = @prepare params
        return new Request params, cb, headers, @appId

    create: (params, cb, headers) ->
        params = @prepare params
        return new Request params, cb, headers, null

module.exports = RequestFactory
