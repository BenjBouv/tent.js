http = require 'http'
https = require 'https'
url = require 'url'
qs = require 'querystring'

utils = require './utils'

class Request

    # Public interface
    constructor: ->
        @url = null
        @method = null
        @headers = {}
        @body = null
        @queryparam = {}
        @expected = 200 # OK

    setBody: (body) ->
        @body = if typeof body == 'string' then body else JSON.stringify body
        @headers['Content-Length'] = @body.length.toString()
        @

    addHeader: (name, value) ->
        if name and value
            @headers[name] = value
        @

    addQueryParameter: (name, value) ->
        if name and value
            @queryparam[name] = value
        @

    # Runs a request.
    # params:
    #   cb(maybeError, body, headers)
    run: (cb) ->

        if !@url
            cb 'Request: no URL given. Request aborted'
            return
        if !@method
            cb 'Request: no method given. Request aborted'
            return

        opts = url.parse @url
        opts.method = @method
        opts.headers = @headers

        utils.debug 'request.headers', @headers
        utils.debug 'request.body', @body

        requestFunction = if isSecured opts then https.request else http.request
        cbCalled = false
        req = requestFunction opts, (res) =>
            data = ''

            res.on 'data', (chunk) ->
                data += chunk

            res.on 'end', () =>
                if cbCalled
                    return

                utils.debug 'response.headers', res.headers
                utils.debug 'response.body', data

                if res.statusCode and res.statusCode != @expected
                    cb "Request: Status isn't " + @expected + " but " + res.headers.status + "\nData received: " + data
                else
                    if data.length > 0
                        try
                            data = JSON.parse data
                        catch err
                            cb 'when parsing JSON response: ' + err + '\n' + new Error().stack
                    cbCalled = true
                    cb null, data, res.headers
                @

        req.on 'error', (err) ->
            if cbCalled
                console.error 'Request: callback already called, but error received: ' + err
                return

            ###
            # TODO is that really happening?
            if err.code != 'HPE_INVALID_CONSTANT'
                cbCalled = true
                cb err
            ###

        if @body then req.end @body else req.end()
        @

    # Private interface
    # methods for the headers
    isSecured = (opts) ->
        opts.protocol == 'https:'

    getPort = (opts) ->
        port = opts.port
        if !port
            port = if isSecured opts then 443 else 80
        port

module.exports = Request
