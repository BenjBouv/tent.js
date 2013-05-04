class Synq
    constructor: (@maxSize) ->
        if not @maxSize
            @maxSize = 1

        @queue = []
        @current = 0

    push: (f) ->
        @queue.push f
        @empty()
        @

    empty: () ->
        if @current < @maxSize and @queue.length > 0
            @current += 1
            f = @queue.pop()
            f()
        @

    free: () ->
        @current -= 1
        @empty()
        @

module.exports = Synq
