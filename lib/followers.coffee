SubModule = require './submodule'
utils = require './utils'

class Followers extends SubModule
    get: (params, cb) ->
        url = '/followers'
        reqParam =
            url: url
            additional: params
            method: 'GET'
        rcb = utils.makeGenericCallback cb
        @call reqParam, rcb
        @

module.exports = Followers

