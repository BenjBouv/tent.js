http = require 'http'
https = require 'https'
url = require 'url'
qs = require 'querystring'

utils = require './utils'

class Request

    Request::CONTENT_TYPE =
        post: 'application/vnd.tent.post.v0+json'
        feed: 'application/vnd.tent.posts-feed.v0+json'
        error: 'application/vnd.tent.error.v0+json'
        attachment: 'multipart/form-data'

    constructor: (params, @cb, headers, appId) ->

        if not params.url
            @cb 'Request: no cible defined.'
            return
        if not params.method
            @cb 'Request: no method defined.'
            return
        if params.needAuth and not params.auth
            @cb 'Request needs authentication, but no credentials were given.'
            return

        if params.additional and Object.keys(params.additional).length > 0
            params.url += '?' + qs.stringify( params.additional )

        @opts = url.parse params.url
        @opts.method = params.method
        @opts.headers = headers || {}

        # Accept field
        if not headers or not headers.accept
            if params.accept
                @opts.headers['Accept'] = Request::CONTENT_TYPE[ params.accept ] || null
            else
                console.warn 'No accept field in request (' + params.method + ' ' + params.url + ' )'

        # Body, body length and content type
        if params.body
            @body = params.body
            @opts.headers['Content-Length'] = @body.length.toString()

            if not headers or not headers['Content-Type']
                contentType = Request::CONTENT_TYPE[ params.contentType ] || null
                if params.postType
                    contentType += '; type="' + params.postType + '"'
                @opts.headers['Content-Type'] = contentType

        else
            @body = null

        # Authentication
        if params.auth and appId
            @opts.headers['Authorization'] = params.auth.make params.url, params.method, appId

        @

    run: () ->

        utils.debug 'requests.headers', @opts

        reqMeth = if utils.isSecured @opts then https.request else http.request
        cbCalled = false
        req = reqMeth @opts, (res) =>
            data = ''

            res.on 'data', (chunk) ->
                data += chunk

            res.on 'end', () =>
                if cbCalled
                    return

                cbCalled = true
                utils.debug 'response.headers', res.headers
                utils.debug 'response.body', data

                if res.statusCode and res.statusCode != 200
                    @cb "Status isn't 200 OK but " + res.headers.status + "\nData received: " + data
                else
                    try
                        if data.length > 0
                            data = JSON.parse data
                        @cb null, res.headers, data
                    catch err
                        @cb 'when parsing JSON response: ' + err + '\n' + new Error().stack
                @

        req.on 'error', (err) ->
            if cbCalled
                console.error 'Request: callback already called, but error received: ' + err
                return

            if err.code != 'HPE_INVALID_CONSTANT'
                cbCalled = true
                cb err

        if @body then req.end @body else req.end()
        @

module.exports = Request
