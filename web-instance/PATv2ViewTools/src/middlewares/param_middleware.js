var middleware = {
    param: function (param, validator) {
        return function (req, res, next, value) {
            if (validator(value)) {
                if (!req.script) {
                    req.script = {}
                }
                req.script[param] = value
                next()
            } else {
                res.sendStatus(403);
            }
        }
    },
    validator: function (data) {
        console.log('called with data: ', data);
        return true
    }
}

module.exports = middleware