SubModule = require './submodule'
utils = require './utils'

class Followings extends SubModule
    get: (params, cb) ->
        url = '/followings'
        reqParam =
            url: url
            additional: params
            method: 'GET'
            # no auth?
        rcb = utils.makeGenericCallback cb
        @call reqParam, rcb
        @

module.exports = Followings
