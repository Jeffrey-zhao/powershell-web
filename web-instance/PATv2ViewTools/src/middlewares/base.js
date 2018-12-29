var logger = require('../../logger')

var basemiddleware = {
    beforelog: function (logPath) {
        return (req, res, next) => {
            var log = logger.loggerInstance(logPath).child({
                id: req.id,
                body: req.body
            }, true)
            log.info({
                req: req
            })
            next();
        }
    },
    afterlog: function (logPath) {
        return function (req, res, next) {
            function afterResponse() {
                res.removeListener('finish', afterResponse);
                res.removeListener('close', afterResponse);
                var log = logger.loggerInstance(logPath).child({
                    id: req.id
                }, true)
                log.info({
                    res: res
                }, 'response')
            }

            res.on('finish', afterResponse);
            res.on('close', afterResponse);
            next();
        }
    },
    header: function (req, res, next) {
        res.writeHead(200, {
            "Content-Type": "text/html;charset=utf-8"
        });
        return next()
    },
    log_error: function (err, req, res, next) {
        console.error(err.stack)
        return next(err)
    },
    client_error_handler: function (err, req, res, next) {
        if (req.xhr) {
            res.status(400).sender('error', {
                err_msg: 'something failed!',
                url: req.url
            })
        } else {
            return next(err)
        }
    },
    error_handler: function (err, req, res, next) {
        res.status(500)
            .render('error', {
                err_msg: err,
                url: req.url
            })
    },
    timeout: function (req, res, next) {
        req.setTimeout(5000)
        res.setTimeout(10000)
        return next()
    }
}

module.exports = basemiddleware