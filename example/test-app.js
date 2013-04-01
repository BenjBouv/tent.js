var fs = require('fs');
var tent = require('../lib/tent');
var config = require('./config').config;

var client = new tent.Client( config.entity );

fs.readFile( 'credentials.app.js', function(_, data) {
    var cred = JSON.parse(data);

    client.appRegister({
        mac_algorithm: cred.mac_algorithm,
        mac_key: cred.mac_key,
        mac_key_id: cred.mac_key_id,
        id: cred.id,
        callback: function(err, app) {
           if(err) console.error(err);
           else {
                console.log('app: ' + JSON.stringify(app) + '\n');

                var appInfo = config.app;
                appInfo.name = 'DataStalkerInc';
                client.appUpdate( appInfo, function(err2, app2) {
                    if( err2 ) { console.error(err2); return; }
                    console.log("updated app: " + JSON.stringify(app2) + '\n');
                });

           }
        }
    });
});
