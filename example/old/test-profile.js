var fs = require('fs');
var config = require('./config');
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

    var client = new tent(config.entity);
    client.setUserCredentials( mac_key, mac_key_id );
    client.profile.getSpecific('basic', {}, function(err, profile) {

        if(err) { console.error( err ); return; }
        var profileText = JSON.stringify(profile)
        var oldProfile = JSON.parse( profileText ); // deep copy
        console.log('Basic profile: ' + JSON.stringify(profile));

        var newProfile = profile;
        profile.bio += ' (CoffeeScript rules, BTW)';

        client.profile.update('basic', newProfile, function(err, enhancedProfile) {
            if(err) { console.error('ERROR: '+ err ); return; }
            console.log('Enhanced updated profile: ' + JSON.stringify(enhancedProfile) );

            client.profile.delete('basic', {}, function(err) {
                if(err) { console.error( err ); return; }

                console.log('Deletion seems ok.');
                client.profile.update('basic', oldProfile, function(err) {
                    console.log('Old profile set back.');
                });
            });
        });
    });
});
