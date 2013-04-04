var requests = require('./requests');

var get = function( cb ) {
    var that = this;
    this.apiCall({
        url: '/posts',
        method: 'GET',

        needAuth: true,
        auth: that.credentials.user,

        onResult: function(err, headers, data) {
            if( err ) { cb(err, null); }
            else cb( null, JSON.parse(data) );
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

var checkRequired = function( known_type, obj ) {
    var r = REQUIRED_BY_ALL;
    for( var i = 0; i < r.length; ++i ) {
        if( ! obj[ r[i] ] ) return false;
    }

    var found = POSTS_TYPES[type];
    if( found ) {
        var s = found.required;
        for( var i = 0; i < s.length; ++i ) {
            if( ! obj[s[i]] ) return false;
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
    proto.postsGet = get;
};
