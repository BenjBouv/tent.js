fs = require 'fs'
config = require './config'
tent = require '../lib/tent'

readline = require 'readline'
rl = readline.createInterface
  input: process.stdin
  output: process.stdout

client = new tent config.entity
client.discovery (err, _) ->
    if err
        console.error err
        return

    appPost = JSON.parse fs.readFileSync 'app.v3.json'
    credPost = JSON.parse fs.readFileSync 'appcred.v3.json'

    client.app.info = appPost
    client.app.id = appPost.id
    client.app.credentials = credPost

    client.app.getAuthUrl (err, auth) ->
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
                fs.writeFileSync 'user.v3.json', JSON.stringify userAuth

            rl.close()

