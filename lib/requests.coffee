http = require 'http'
https = require 'https'
url = require 'url'

utils = require './utils'

class Request

    constructor: (params, @cb) ->

        throw new Error('no cible defined') unless params.cible
        throw new Error('no method defined') unless params.method

        @opts = url.parse params.cible
        @opts.method = params.method
        @opts.headers =
            "Accept": "application/vnd.tent.v0+json"

        if params.body
            @body = params.body
            @opts.headers['Content-Type'] = "application/vnd.tent.v0+json"
            @opts.headers['Content-Length'] = body.length.toString()
        else
            @body = false

        if params.auth
            # TODO make auth independent from request
            @opts.headers['Authorization'] = utils.createHmacAuth @opts, mk, mkid

    run: () ->
        reqMeth = if utils.isSecured @opts then https.request else http.request
        req = reqMeth @opts, (res) ->
            data = ''

            res.on 'data', (chunk) ->
                data += chunk

            res.on 'end', () ->
                if res.headers.status and res.headers.status.substring(0, 3) != '200'
                    @cb "Status isn't 200 OK but " + res.headers.status + "\nData received: " + data
                else
                    @cb null, res.headers, data
                @

        req.on 'error', @cb

        if @body then req.end @body else req.end()

        @

module.exports = Request
