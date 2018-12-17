
var middleware = {
    log: function (req, res, next) {
        console.log('%s %s %s', req.method, req.url, req.path)
        next()
    },
    header: function (req, res, next) {
        res.writeHead(200, {
            "Content-Type": "text/html;charset=utf-8"
        });
        next()
    },
    log_error: function (err, req, res, next) {
        console.error(err.stack)
        next(err)
    },
    client_error_handler: function (err, req, res, next) {
        if (req.xhr) {
            res.status(400).sender('error',{
                err_msg: 'something failed!',
                url: req.originalUrl
            })
        } else {
            next(err)
        }
    },
    error_handler(err, req, res, next) {
        res.status(500)
            .render('error', {
                err_msg: err,
                url: req.originalUrl
            })
    },
    timeout: function (req, res, next) {
        req.setTimeout(5000)
        res.setTimeout(10000)
        next()
    }
}

module.exports = middleware