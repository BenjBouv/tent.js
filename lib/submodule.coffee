Request = require './requests'

class Submodule
    constructor: (@client) ->

    call: (reqParam, cb) ->
        @client.getApiRoot (err, apiroot) ->
            if err
                cb err
                return

            reqParam.url = apiroot + reqParam.url
            if reqParam.needAuth and not reqParam.auth
                throw new Error 'Credentials not found'

            req = new Request reqParam, cb
            req.run()
        @

module.exports = Submodule
