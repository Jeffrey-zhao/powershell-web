var express = require('express'),
    router = express.Router(),
    param_mw=require('../middlewares/param_middleware')

router.get('/script/list', function (req, res) {
    console.log('list')
    res.send('list')
    res.end()
})
router.get('/script/:file/:fn/detail', function (req, res) {
    console.log('detail')
    res.end()
})

router.get('/script/:file/:fn/commandline', function (req, res) {
    console.log('commandline')
    res.end()
})

router.post('/script/:file/:fn/execute', function (req, res) {
    console.log('execute')
    res.end()
})

router.param(param_mw.param)

router.param('file', param_mw.validator);

router.param('fn', param_mw.validator);

router.get('/script/:file/:fn?', function (req, res) {
    console.log('/script/:file/:fn?')
    console.log(req.script)
    res.end()
})

module.exports = router