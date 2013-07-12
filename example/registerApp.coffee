fs = require 'fs'

config = require './config'
tent = require '../lib/tent'
p = console.log

client = new tent config.entity
client.discovery (err, post) ->
    if err
        console.error err
        return

    p post
    client.app.register config.app, (err2, appPost, credPost) ->
        if err2
            console.error err2
            return

        p 'App post:'
        p appPost
        p 'Credentials:'
        p credPost
        fs.writeFileSync 'credentials/app.v3.json', JSON.stringify appPost
        fs.writeFileSync 'credentials/appcred.v3.json', JSON.stringify credPost
        p 'Everything went ok :)'
