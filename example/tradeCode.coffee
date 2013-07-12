fs = require 'fs'
config = require './config'
tent = require '../lib/'

readline = require 'readline'
rl = readline.createInterface
  input: process.stdin
  output: process.stdout

client = new tent config.entity
client.discovery (err, _) ->
    if err
        console.error err
        return

    appPost = JSON.parse fs.readFileSync 'credentials/app.v3.json'
    credPost = JSON.parse fs.readFileSync 'credentials/appcred.v3.json'

    client.setAppCredentials credPost.post
    client.setAppId appPost.post.id

    client.app.authUrl (err, auth) ->
        if err
            console.error err
            return
        console.log auth
        rl.question 'Enter the code here?', (answer) ->

            client.app.tradeCode answer, '', (err, userAuth) ->
                if err
                    console.error err
                    return

                console.log 'Authentication worked!'
                fs.writeFileSync 'credentials/user.v3.json', JSON.stringify userAuth

            rl.close()

