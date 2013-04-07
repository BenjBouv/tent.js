SubModule = require './submodule'
utils = require './utils'
qs = require 'querystring'

class Profile extends SubModule

    expand: ( type ) ->
        found = Profile::TYPES[type]
        if found then found.url else type

    get: ( cb ) ->
        @client.getProfile cb
        @

    getSpecific: ( type, params, cb ) =>
        type = @expand type
        url = '/profile/' + qs.escape type
        reqParam =
            url: url
            method: 'GET'
            additional: params
            needAuth: true
            auth: @client.credentials.user
        rcb = utils.makeGenericCallback cb
        @call reqParam, rcb
        @

    update: ( type, profile, cb ) =>
        found = Profile::TYPES[ type ]
        if found
            valid = ( !!profile[ field ] for field in found.required ).reduce (a,b) ->
                a and b
            , true

            if not valid
                cb 'When updating a profile, required fields missing'
                return

        type = @expand type
        reqParam =
            url: '/profile/' + qs.escape type
            method: 'PUT'
            body: JSON.stringify profile
            needAuth: true
            auth: @client.credentials.user
        rcb = (err, h, data) =>
            if err
                cb err
            else
                @client.profiles = JSON.parse data
                cb null, @client.profiles

        @call reqParam, rcb
        @

    delete: ( type, params, cb ) =>
        type = @expand type
        url = '/profile/' + qs.escape type
        reqParam =
            url: url
            method: 'DELETE'
            additional: params
            needAuth: true
            auth: @client.credentials.user
        rcb = (err, h, data) ->
            cb if err then err else null
        @call reqParam, rcb
        @

    Profile::TYPES =
        core:
            url: "https://tent.io/types/info/core/v0.1.0"
            required: ['entity', 'licenses', 'servers']
        basic:
            url: "https://tent.io/types/info/basic/v0.1.0"
            required: []
        cursor:
            url: "https://tent.io/types/info/cursor/v0.1.0"
            required: ['post', 'entity']

module.exports = Profile
