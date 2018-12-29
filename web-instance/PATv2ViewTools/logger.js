var bunyan = require('bunyan')

var logger = {
    loggerInstance: function (path) {
        return bunyan.createLogger({
            name: 'transaction-notifier',
            serializers: {
                req: require('bunyan-express-serializer'),
                res: bunyan.stdSerializers.res,
                err: bunyan.stdSerializers.err
            },
            level: 'info',
            streams: [{
                path: path,
            }]
        })
    },

    logResponse: function (id, body, statusCode, path) {
        var log = this.loggerInstance(path).child({
            id: id,
            body: body,
            statusCode: statusCode
        }, true)
        log.info('response')
    }
}

module.exports = logger