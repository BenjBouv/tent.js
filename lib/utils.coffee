crypto = require 'crypto'
config = require './config'

exports.generateUniqueToken = (cb) ->
    crypto.randomBytes 32, (_, buf) ->
        token = buf.toString 'hex'
        cb token

exports.debug = (str, obj) ->
    if config.debug
        console.log str + ':'
        console.log obj
        console.log()

exports.error = (str) ->
    console.error str
