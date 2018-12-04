var express = require('express'),
    router = express.Router(),
    param_mw = require('../middlewares/param_middleware')
    script_ctl=require('../controllers/script_controller')

//for script list
router.use('/script/list',param_mw.req_script_dir)

router.get('/script', script_ctl.index)

router.get('/script/list', script_ctl.list)
router.get('/script/:file_path/detail',script_ctl.file_detail)

router.get('/script/:file_path/:fn_name/detail', script_ctl.fn_detail)

router.get('/script/:file_path/:fn_name/commandline', script_ctl.commandline)

router.post('/script/:file_path/:fn_name/execute', script_ctl.execute)

router.param(param_mw.param)

router.param('file_name', param_mw.validator);

router.param('fn_name', param_mw.validator);

router.get('/script/:file_name/:fn_name', function (req, res) {
    console.log('/script/:file_name/:fn_name')
    console.log(req.script)
    res.end()
})

module.exports = router