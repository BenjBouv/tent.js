Request = require './requests'

class Submodule
    constructor: (@client) ->

    call: (reqParam, cb, headers) ->
        @client.getMeta (err, _) =>
            if err
                cb err
                return

            if reqParam.needAuth then createMethod = 'createAuth' else createMethod = 'create'
            req = @client.reqFactory[createMethod] reqParam, cb, headers
            req.run()

module.exports = Submodule
