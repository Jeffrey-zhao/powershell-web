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
    },
    req_script_dir:function(req,res,next){
        // why cannot use req.params or req.query
        req.body={script_dir:req.app.get('script_dir')}
        next()
    }
}

module.exports = middleware