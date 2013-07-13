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

client.posts.create('status')
 .content
    text: 'Bonjour, monde!'
 .private()
 .run (maybeError, createdPost) ->
    if maybeError
        console.error maybeError
        return

    console.log 'Post created: '
    console.log createdPost

    client.posts.createStatus('Hello, world (previous was in French)')
     .published_at(new Date)
     .addParent(createdPost)
     .versionMessage('An international version of the previous French message')
     .license('https://www.gnu.org/licenses/gpl.html')
     .public()
     .run (maybeError2, createdPost2) ->
         if maybeError2
             console.error maybeError2
             return
         console.log 'New version created:'
         console.log createdPost2
         console.log 'Loading feed...'

         client.posts.get {}, (err2, feed) ->
            if err2
                console.error err2
                return
            p feed
