var platform_cmd = require('../../util').platform_cmd

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
    cmd: function (req, res, next) {
        if (!req.script) {
            req.script = {}
        }
        req.script['cmd'] = platform_cmd()
        //console.log('%s', req.script['cmd'])
        next()
    },
    log_error: function (err, req, res, next) {
        console.error(err.stack)
        next(err)
    },
    client_error_handler: function (err, req, res, next) {
        if (req.xhr) {
            res.status(500).send({
                error: 'something failed!'
            })
        } else {
            next(err)
        }
    },
    error_handler(err, req, res, next) {
        res.status(500)
        res.render('error', {
            err_msg: err,
            url: req.originUrl
        })
    },
    timeout:function(req,res,next){
        req.setTimeout(5000)
        res.setTimeout(10000)
        next()
    }
}

module.exports = middleware