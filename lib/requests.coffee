http = require 'http'
https = require 'https'
url = require 'url'
qs = require 'querystring'

utils = require './utils'

class Request

    constructor: (params, @cb, headers) ->

        throw new Error('no cible defined') unless params.url
        throw new Error('no method defined') unless params.method

        if params.additional and Object.keys(params.additional).length > 0
            params.url += '?' + qs.stringify( params.additional )

        @opts = url.parse params.url
        @opts.method = params.method
        @opts.headers = headers ||
            "Accept": "application/vnd.tent.v0+json"

        if params.body
            @body = params.body
            @opts.headers['Content-Type'] = "application/vnd.tent.v0+json"
            @opts.headers['Content-Length'] = @body.length.toString()
        else
            @body = null

        if params.auth
            @opts.headers['Authorization'] = params.auth.getAuthorization @opts


    run: () ->

        utils.debug 'requests.headers', @opts

        reqMeth = if utils.isSecured @opts then https.request else http.request
        req = reqMeth @opts, (res) =>
            data = ''

            res.on 'data', (chunk) ->
                data += chunk

            res.on 'end', () =>
                utils.debug 'response.headers', res.headers

                if res.headers.status and res.headers.status.substring(0, 3) != '200'
                    @cb "Status isn't 200 OK but " + res.headers.status + "\nData received: " + data
                else
                    try
                        if data.length > 0
                            data = JSON.parse data
                        @cb null, res.headers, data
                    catch err
                        @cb 'when parsing JSON response: ' + err
                @

        req.on 'error', @cb

        if @body then req.end @body else req.end()

        @

module.exports = Request
