var tent = require('../lib/tent');
var express = require('express')
  , http = require('http')
  , path = require('path')
  , fs   = require('fs');

var PORT = 1044;

var config = require('./config').config;

var app = express();
app.configure(function(){
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser('tell me a secret'));
  app.use(express.session());
  app.use(express.csrf());
  app.use(app.router);
  app.enable('trust proxy')
  app.use(express.static(path.join(__dirname, 'public')));
});

app.configure('development', function(){
  app.use(express.errorHandler());
  app.locals.pretty = true;
});

var client = new tent.Client( config.entity );

app.get('/', function(req, res) {
    client.registerApp({
        appInfo: config.app,
        callback: function(err, oauthurl, components) {
            if( err ) {
                console.error( err );
                res.send(500);
                return;
            }
            fs.writeFileSync('credentials.app.js', JSON.stringify(components) );
            res.redirect( oauthurl );
        }
    });
});

app.get('/callback', function(req, res) {
    var code = req.param('code'),
        state = req.param('state');

    tent.registerClient(code, state, function(err, components) {
        if( err ) {
            console.error( err );
            res.send(501);
            return;
        }

        fs.writeFileSync('credentials.user.js', JSON.stringify(components) );
        res.send('Message: ' + JSON.stringify(components));
        client.registerClient( components.mac_key, components.mac_key_id );
    });
});

http.createServer(app).listen(PORT, function(){
    console.log("Express server listening on port " + PORT);
});

