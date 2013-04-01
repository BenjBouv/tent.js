var fs = require('fs');
var config = require('./config').config;
var tent = require('../lib/tent');

fs.readFile( 'credentials.user.js', function(err, data) {
    if( err ) {
        console.error(err);
        return;
    }

    var cred = JSON.parse( data );
    var mac_algo = cred.mac_algorithm;
    var mac_key = cred.mac_key;
    var mac_key_id = cred.mac_key_id;

    var client = new tent.Client(config.entity);
    client.clientRegister( mac_algo, mac_key, mac_key_id );
    client.profileGetSpecific({
        type: 'basic',
    }, function(err, profile) {

        if(err) { console.error( err ); return; }
        console.log('Basic profile: ' + JSON.stringify(profile));

        var newProfile = profile;
        profile.bio += ' <= this is awesome.';
        client.profileUpdate({
            type: 'basic',
            profile: newProfile
        }, function(err, enhancedProfile) {
            if(err) { console.error( err ); return; }
            console.log('Enhanced updated profile: ' + JSON.stringify(enhancedProfile) );

            var oldProfile = enhancedProfile[ client.PROFILES.basic.url ];
            client.profileDelete({ type: 'basic' }, function(err) {
                if(err) { console.error( err ); return; }

                console.log('Deletion seems ok.');
                client.profileUpdate({ type: 'basic', profile: oldProfile }, function(err) {
                    console.log('Old profile set back.');
                });
            });
        });

    });
});
