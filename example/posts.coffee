fs = require 'fs'
config = require './config'
tent = require '../lib/'

p = (something) ->
    if typeof something != 'string'
        console.log JSON.stringify something, null, '  '
    else
        console.log something

client = new tent config.entity

appPost = JSON.parse fs.readFileSync 'credentials/app.v3.json'
appAuth = JSON.parse fs.readFileSync 'credentials/appcred.v3.json'
userAuth = JSON.parse fs.readFileSync 'credentials/user.v3.json'

client.setAppCredentials appAuth.post
client.setUserCredentials userAuth
client.setAppId appPost.post.id

status =
    type: 'status'
    content:
        text: "This statement is false."

###
client.posts.create status, (err2, _) ->
    if err2
        console.error err2
        return

    console.log 'Post created: '
    console.log _
###

client.posts.get {}, (err2, feed) ->
    if err2
        console.error err2
        return
    p feed
