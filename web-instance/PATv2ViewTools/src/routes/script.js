var express = require('express'),
    router = express.Router(),
    param_mw = require('../middlewares/param_middleware')
    script_ctl=require('../controllers/script_controller')

//for script list
router.use('/script/list',param_mw.req_script_dir)

router.get('/script', script_ctl.index)

router.get('/script/list', script_ctl.list)
router.get('/script/:file_name/:fn_name/detail', function (req, res) {
    console.log('detail')
    res.end()
})

router.get('/script/:file_name/:fn_name/commandline', function (req, res) {
    console.log('commandline')
    res.end()
})

router.post('/script/:file_name/:fn_name/execute', function (req, res) {
    console.log('execute')
    res.end()
})

router.param(param_mw.param)

router.param('file_name', param_mw.validator);

router.param('fn_name', param_mw.validator);

router.get('/script/:file_name/:fn_name', function (req, res) {
    console.log('/script/:file_name/:fn_name')
    console.log(req.script)
    res.end()
})

module.exports = router