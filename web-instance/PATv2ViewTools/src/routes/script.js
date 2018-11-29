var express = require('express'),
    router = express.Router()

router.param(function (param, validator) {
    return function (req, res, next, value) {
        if (validator(value)) {
            if (!req.script) {
                req.script = {}
            }
            console.log(param,validator)
            req.script[param] = value
            next()
        } else {
            res.sendStatus(500);
        }
    }
})

router.param('file_name', function (candidate) {
    return true
})

router.param('fn_name', function (candidate) {
    return true
})

router.get('/script/list', function (req, res) {
    console.log(req.path)
    next()
})

router.get('/script/:file_name/:fn_name?', function (req, res,next) {
    console.log(req.path, req.script)
    next()
})

router.get('/script/detail', function (req, res,next) {
    console.log(req.path, req.script)
    next()
})

router.get('/script/command', function (req, res,next) {
    console.log(req.path, req.script)
    next()
})

router.post('/script/execute', function (req, res,next) {
    console.log(req.path, req.script)
    next()
})
module.exports = router