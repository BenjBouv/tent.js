# tent.js
tent.js is a node client for the protocol Tent. It is meant to be as
complete as possible, providing everything necessary from app registration to everyday use.

## Currently implemented

- "discovery dance"
- app registration and authentication
- app methods: get / update / delete
- profile methods: get / get a specific profile / update / delete
- posts methods: get / create / update / delete

## Compile it

To compile it, you need CoffeeScript compiler:

```npm install -g coffee-script```

Then, you can just compile all coffee files in the lib (`(cd lib && coffee -c \*.coffee)`) or import the libs from
Coffee applications.

# API
## Module separation
The entry point of this library is the Tent object. It contains different submodules which implement the different
aspects of the tent protocol.

## Error management
Most functions have signatures like the following:

```
tentClient.moduleName.function( [ all required parameters ], function(err, [ results ]) {

});
```

The user should check that err is defined. In this case, the message should allow to find where the error is.

## Creation of client

```
var Tent = require('../lib/tent');
var entity = 'https://anyentity.tent.is';
var client = new Tent( entity );
```

## App registration

```
// Registers the app
var app = {
      "name": "BigCorpAnalysisInc",
      "description": "Makes a lot of money with your data",
      "url": "http://app.example.com",
      "redirect_uris": [
        "http://app.example.com/callback"
      ],
      "scopes": {
        "read_profile": "Reads your profile and sells your personal information to big companies.",
        "write_profile": "Sponsorizes your biography with a brand name!",
        "read_followers": "Learns from your contacts to enhance understanding you!",
        "write_followers": "Block your contacts which are not bankable.",
        "read_followings": "Which of our concurrents are tracking you? That interests us.",
        "write_followings": "Adds public trademarks followers to your friends list.",
        "read_posts": "Reads your posts and sells them to advertising companies.",
        "write_posts": "Writes random ads on your timeline.",
        "read_groups": "Communities are the first aim of the company.",
        "write_groups": "Advertises also your groups of friends"
      }
    };

    client.app.register( app, function(err, oauthUrl, appComponents ) {
    if( err ) {
        console.error('Error when registering: ' + err);
        return;
    }

    // do something, for instance redirect to oauthUrl
    console.log( 'The OAuth url is: ' + oauthUrl );
    console.log( 'The app with all components (including mac_key, mac_key_id that you may want to keep): ' +
appComponents );
});

// Then, once you retrieve the code and state, you need to trade the code for a permanent authentication token:
var code = '123456789', // retrieved from the callback
    state = '123456789', // same thing
client.app.tradeCode( code, state, function(err, userComponents) {
    // check for error
    // do something with the userComponents object (which contain the mac_key, mac_key_id, mac_key_algorithm).
});
```

## Credentials

```
// Before your app closes, your credentials may have been saved somewhere.
// To reuse them in the future, you can use the set*Credentials methods:
var client = new Tent(entity);
client.setUserCredentials( user_mac_key, user_mac_key_id );
client.setAppCredentials( app_mac_key, app_mac_key_id );
```

## App methods
### Set id

```
// You have received an app id when registering the app. It is necessary to use the app API.
client.app.setId( '123456545ahfuek' );
```

### Get app

```
// for retrieving the current registered app
// WARNING: for this one, you need to have set an ID
// App credentials required
client.app.get( function(err, appComponents) {
    // check for error
    // appComponents is an object describing the app (like the one received when registering)
});

// retrieve the app with the id indicated in the first parameter
// App credentials required
client.app.get( '123456789ahfuek', function(err, appComponents) {

});
```

### Update app

```
// update app with current id.
// WARNING: for this one, you need to have set an ID
// App credentials required
client.app.update( appInfo /* a new app object */,
    function(err, appComponents) {

});

// update app with given id.
// App credentials required
client.app.update( '123456789ahfuek', function(err, appComponents) {

});
```

### Delete app

```
// delete app with current id.
// WARNING: for this one, you need to have set an ID
// App credentials required
client.app.delete( function(err, data) {
    // data contains the data received by the server
});

// delete app with given id.
// App credentials required
client.app.delete( '123456789ahfuek', function(err, data) {

});
```

### Get Authentication URL

```
client.app.getAuthUrl(function(err, authUrl, appComponents) {
    // authUrl is the OAuth URL
    // appComponents is an object describing the app
});
```

## Profile methods
### Get all profiles

```
// Needs user credentials
client.profile.get( function(err, profiles) {

});
```

### Get a specific profile

```
// Needs user credentials
// Second arguments is an object representing the additional query string parameters
client.profile.getSpecific( 'https://tent.io/types/info/core/v0.1.0', {}, function( err, profile ) {
    // retrieves only the core profile
});

// or you can also use a shortcut for tent.io predefined types
client.profile.getSpecific( 'basic', {version: "3"}, function( err, profile ) {

});

// available predefined types are: 'core', 'basic', 'cursor'
```

### Update a specific profile

```
// Needs user credentials
client.profile.update( 'basic', profileObject, function(err, profiles) {
    // tent.io protocol describes that all profiles are sent back when updating any of them.
});
```

### Delete a specific profile

```
// Needs user credentials
var additionalParams = {version: '1'}; // These are additional query string params
client.profile.delete( 'cursor', additionalParams, function(err) {
    // err if there was an error, null otherwise
});
```

## Posts methods
### Posts types
Like profiles types, posts types are predefined to provide shortcuts to the user:
- *status*
- *essay*
- *photo*
- *album*
- *repost*
- *profile*
- *delete*
- *following*
- *followers*

### Get posts

```
// Without user credentials, this retrieves public posts.
// With user credentials, it retrieves all posts, including private posts.
// The first parameter is additional query string parameters, as an object.
client.posts.get( {type: 'https://tent.io/types/post/essay/v0.1.0'}, function(err, posts) {

});
```

### Create / update post

```
// Needs user credentials.
var post = {
    type: 'status',
    content: {
        text: 'Hello, world!'
    },
    permissions: {public: true}
};

client.posts.create( post, function(err, returnedPost) {
    // returnedPost is the post returned by the server, with id, and so on.

    var id = returnedPost.id;
    post.content = 'I mean, hello, tent!';
    client.posts.update( id, post, function(err, updatedReturnedPost) {

    });
});
```

### Delete post

```
// Needs user credentials
// The second parameter is additional query string parameters, as an object.
clients.posts.delete( id, {version: '2'}, function(err) {
    // err is null if there wasn't error, or an error otherwise.
});
```

# Full Example
To see an example of working code, do the following:
- cd example
- change the values of config.js.example and rename this file to config.js
- npm install
- node app

Then, when connecting at your server, the registration process will happen and credentials will get saved into json files: credentials.app.js and credentials.user.js.

After registration and authorization, you can run all the test-\* which use the credentials.

