Request = require './requests'

class Submodule
    constructor: (@client) ->

    prefixEntity: (sthg) ->
        @client.prefixEntity sthg

    newPost: (postObj, cb, method) ->
        @client.getMeta (err, meta) =>
            if err
                cb err
                return

            url = @client.prefixEntity meta.content.servers[0].urls.new_post
            reqParam =
                url: url
                method: method || 'POST'
                contentType: postObj.type
                body: JSON.stringify postObj

            # TODO take care of auth?
            if reqParam.needAuth and not reqParam.auth
                throw new Error 'Credentials not found'

            new Request(reqParam, cb).run()
        @

module.exports = Submodule
