var fs = require('fs');
var tent = require('../lib/tent');
var config = require('./config');

var client = new tent( config.entity );

fs.readFile( 'credentials.app.js', function(_, data) {
    var cred = JSON.parse(data);

    client.setAppCredentials( cred.mac_key, cred.mac_key_id );
    client.app.setId( cred.id );

    client.app.getAuthUrl(function(err, authUrl) {
        if(err) {
            console.error( err );
            return
        }
        console.log('Auth url: ' + authUrl);
        client.app.getAuthUrl( function(err, sameAuthUrl) {
            if(err) {
                console.error( err );
                return
            }
            console.log('Same auth url (state should be different): ' + sameAuthUrl);
            client.app.get(function(err, app) {
               if(err) console.error(err);
               else {
                    console.log('app: ' + JSON.stringify(app) + '\n');

                    var appInfo = config.app;
                    appInfo.name = 'DataStalkerInc';
                    appInfo.scopes.write_profile = 'Advertise your profile for higher results!';
                    client.app.update( appInfo, function(err2, app2) {
                        if( err2 ) { console.error(err2); return; }
                        console.log("updated app: " + JSON.stringify(app2) + '\n');
                    });

               }
            });
        } );
    });
});
