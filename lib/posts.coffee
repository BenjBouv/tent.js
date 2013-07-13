qs = require 'querystring'

utils = require './utils'
Request = require './requests'
SubModule = require './submodule'

class ContentPost

    expandDate = (d) ->
        if d instanceof Date
            +d
        else if d instanceof String
            +Date.parse d
        else
            d

    ContentPost::TYPES =
        status:
            required: ['text']
            url: 'https://tent.io/types/status/v0#'

    constructor: (@request) ->
        @post = {}
        @

    ContentPost::expand = ( type ) ->
        found = ContentPost::TYPES[type]
        if found then found.url else type

    # basic stuff
    #############

    type: (t, fragment) ->
        t = ContentPost::expand t
        @post.type = t
        if fragment
            @post.type += fragment
        @request.postType t, fragment
        @

    content: (content) ->
        @post.content = content
        @

    published_at: (time) ->
        @post.published_at = expandDate time
        @

    # versioning
    ############
    addParent: (parent) ->
        if not parent
            return

        if parent.post
            parent = parent.post

        if not parent.version or not parent.version.id
            utils.error 'ContentPost.childOf: parent version has no version or no version.id'
            return

        @post.version ?= {}

        parentEntry =
            version: parent.version.id
            entity: if @post.entity and parent.entity and parent.entity != @post.entity then parent.entity
            # post: if @post.id and parent.id and parent.id != @post.id then parent.id
            post: parent.id

        @post.version.parents ?= []
        @post.version.parents.push parentEntry
        @

    versionMessage: (message) ->
        if message
            @post.version ?= {}
            @post.version.message = message
        @

    versionPublishedAt: (time) ->
        if time
            @post.version ?= {}
            @post.version.published_at = expandDate time
        @

    # mentions
    ##########
    mentionEntity: (entity, isPublic) ->
        if not entity
            utils.error 'ContentPost.mentionEntity: no entity given'
            return

        entityMention =
            public: isPublic
            entity: entity
        addMention entityMention
        @

    mentionPost: (postId, postVersion, isPublic) ->
        if not postId
            utils.error 'ContentPost.mentionPost: no post ID given'
            return

        postMention =
            public: isPublic
            post: postId
            version: postVersion
        addMention postMention
        @

    addMention: (mention) ->
        if not mention
            return

        if not mention.entity and not mention.post
            utils.error 'ContentPost.addMention: a mention must refer either to an entity or a post'
            return

        @post.mentions ?= []
        @post.mentions.push mention
        @

    # references
    ############

    reference: (post) ->
        if not post or not post.post
            return

        refEntry =
            post: post.post
            entity: post.entity
            version: post.version
            type: if post.permissions and post.permissions.public then post.type
        @post.refs ?= []
        @post.refs.push refEntry
        @

    # licenses
    ##########

    # license URL
    license: (license) ->
        if license
            @post.licenses ?= []
            licenseEntry =
                url: license
            @post.licenses.push licenseEntry
        @

    # permissions
    #############

    public: () ->
        @post.permissions ?= {}
        @post.permissions.public = true
        @

    private: () ->
        @post.permissions ?= {}
        @post.permissions.public = false
        @

    # entity = entity as a string
    allowEntity: (entity) ->
        if entity
            @post.permissions ?= {}
            @post.permissions.entities ?= []
            @post.permissions.entities.push entity
        @

    # group = group identifier as a string
    allowGroup: (group) ->
        if group
            @post.permissions ?= {}
            @post.permissions.groups = []
            @post.permissions.groups.push
                post: group
        @

    # generic
    #########
    run: (cb) ->
        if not @checkFields
            utils.error 'ContentPost.run: at least one required field is missing in your post.'
            return

        @request.setBody @post
        @request.genericRun cb
        @

    checkFields: ->
        found = ContentPost::TYPES[@post.type]
        valid = true
        if found
            valid &= ( !! @post.content[ field ] for field in found.required ).reduce (a,b) ->
                a and b
            , true
        valid


class Posts extends SubModule

    get: (params, cb) ->
        r = @createRequest()
        r.url = '@posts_feed'
        r.method = 'GET'
        r.accept 'feed'
        r.setAuthNeeded 'user'
        r.genericRun cb
        @

    create: (type, fragment) ->
        r = @createRequest()
        r.url = '@new_post'
        r.method = 'POST'
        r.setAuthNeeded 'user'
        cp = new ContentPost r
        if type
            cp.type type, fragment
        cp

    createStatus: (text, location, isReply) ->
        if not text
            utils.error 'Posts.createStatus: no text given for a status'
            return
        cp = @create 'status', if isReply then 'reply' else null
        cp.content
            text: text
            location: location
        cp

module.exports = Posts
