var https = require('https');
var util = require('util');

var srv = https.createServer(function(req, res) {
	req.on('end', function() {
		res.writeHead(200);
		res.end();
		util.puts(req.url);
	});
});
srv.on('error', function(error) {
	util.puts(error);
});
srv.listen(8080);
