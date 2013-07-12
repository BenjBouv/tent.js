TentRequest = require './tent-requests'

class Submodule
    constructor: (@client) ->

    createRequest: () ->
        r = new TentRequest @client
        r

module.exports = Submodule
