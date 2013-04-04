var requests = require('./requests'),
    qs = require('querystring');

var getBase = function( params, cb, authParams ) {
    var url = '/posts';

    // TODO provide help for posts types

    if( params ) {
        url += '?' + qs.stringify( params );
    }

    var req = {
        url: url,
        method: 'GET',

        onResult: function(err, headers, data) {
            if( err ) { cb(err, null); }
            else cb( null, JSON.parse(data) );
        }
    };

    if( authParams.needAuth && authParams.auth ) {
        req.needAuth= req.needAuth;
        req.auth = authParams.auth;
    }

    this.apiCall(req, cb);
};

var getPublic = function( params, cb ) {
    this.postsGetBase( params, cb, {} );
};

var getAll = function( params, cb ) {
    var that = this;
    this.postsGetBase( params, cb, {needAuth: true, auth: that.credentials.user} );
};

var postBase = function( params, cb, mode ) {
    if(! checkRequired( params.type, params, params.content ) ) {
        cb( 'When creating a new post, missing required fields.' );
        return;
    }

    var url = '/posts';
    var method = ( mode && mode.method ) || 'POST';
    if( method === 'PUT') {
        url += '/' + qs.escape( mode.id );
    }

    params.type = expandShortcut( params.type );

    var that = this;
    this.apiCall({
        url: url,
        method: method,
        body: JSON.stringify( params ),

        needAuth: true,
        auth: that.credentials.user,

        onResult: function(err, headers, data) {
            if( err ) { cb(err, null); }
            else cb( null, JSON.parse(data) );
        }
    }, cb);
};

var post = function( params, cb ) {
    this.postsCreateBase( params, cb, {method: 'POST'});
}

var update = function( params, cb ) {
    if( !params.id ) {
        cb('When updating an existing post, no post id was given.');
        return;
    }

    var id = params.id;
    delete params.id; // TODO don't mix...

    this.postsCreateBase( params, cb, {method: 'PUT', id: id} );
};

var delete_ = function( params, cb ) {
    if( !params.id ) {
        cb( 'When deleting post, no post id was given.' );
        return;
    }

    var url = '/posts/' + qs.escape(params.id);
    delete params.id; // TODO don't mix querystring params and needed params

    if( Object.keys(params).length > 0 )
        url += '?' + qs.stringify(params);

    var that = this;
    this.apiCall({
        url: url,
        method: 'DELETE',

        needAuth: true,
        auth: that.credentials.user,

        onResult: function(err, headers, data) {
            if( err ) { cb(err); }
            else cb( null );
        }
    }, cb);
};

var expandShortcut = function( type ) {
    var found = POSTS_TYPES[type];
    if( found ) {
        type = found.url;
    }
    return type;
}

var checkRequired = function( known_type, obj, content ) {
    var r = REQUIRED_BY_ALL;
    for( var i = 0; i < r.length; ++i ) {
        if( ! obj[ r[i] ] ) return false;
    }

    var found = POSTS_TYPES[ known_type];
    if( found ) {
        var s = found.required;
        for( var i = 0; i < s.length; ++i ) {
            if( ! content[s[i]] ) return false;
        }
    }

    return true;
}

var REQUIRED_BY_ALL = ['type', 'content', 'permissions'];

var POSTS_TYPES = {
    'status': {
        required: [],
        url: 'https://tent.io/types/post/status/v0.1.0'
    },

    'essay': {
        required: ['body'],
        url: 'https://tent.io/types/post/essay/v0.1.0'
    },

    'photo': {
        required: [],
        url: 'https://tent.io/types/post/photo/v0.1.0'
    },

    'album': {
        required: ['photos'],
        url: 'https://tent.io/types/post/album/v0.1.0'
    },

    'repost': {
        required: ['entity', 'id'],
        url: 'https://tent.io/types/post/repost/v0.1.0'
    },

    'profile': {
        required: ['types', 'action'],
        url: 'https://tent.io/types/post/profile/v0.1.0'
    },

    'delete': {
        required: ['id'],
        url: 'https://tent.io/types/post/delete/v0.1.0'
    },

    'following': {
        required: ['id', 'entity', 'action'],
        url: 'https://tent.io/types/post/following/v0.1.0'
    },

    'followers': {
        required: ['id', 'entity', 'action'],
        url: 'https://tent.io/types/post/follower/v0.1.0'
    }
};

module.exports = function( proto ) {
    proto.POSTS = POSTS_TYPES;
    proto.postsGet = getAll;
    proto.postsGetPublic = getPublic;
    proto.postsGetBase = getBase; // TODO shouldn't be exposed...

    proto.postsCreate = post;
    proto.postsUpdate = update;
    proto.postsCreateBase = postBase; // TODO shouldn't be exposed...

    proto.postsDelete = delete_;
};
