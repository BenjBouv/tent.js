tent = require '../lib/tent'
config = require './config'

client = new tent config.entity

###
This example is to ensure that meta post retrieval is executed
only one time even if it the function getMeta is called several times.

In particular, when using the tent client, a user could, for
instance, send multiple posts in the mean time. This means that
the meta post is needed. As it doesn't need to get fetched several
times, it is cached.

To avoid async requests during meta post retrieval,
synchronism is set up.

Therefore the result of this test should be only one request and
'Profile received' should be printed 50 times in a row, without
any other request.
###

cb = (err, meta) ->
    if err
        console.error err
    else
        console.log 'Profile received!'

for i in [1..50]
    client.getMeta cb

