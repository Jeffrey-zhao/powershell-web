var express = require('express'),
    router = express.Router(),
    param_mw = require('../middlewares/param_middleware')
    script_ctl=require('../controllers/script_controller')

//for script list
router.use('/script/list',param_mw.req_script_dir)
//script/
router.get('/script', script_ctl.index)
router.get('/script/index', script_ctl.index)

router.get('/script/list', script_ctl.list)

router.get('/script/function/:file_path/:fn_name', script_ctl.function)

router.get('/script/detail/:file_path/:fn_name', script_ctl.detail)

router.get('/script/command/:file_path/:fn_name', script_ctl.command)

router.post('/script/execute/:file_path/:fn_name', script_ctl.execute)

router.param(param_mw.param)

router.param('file_path', param_mw.validator);

router.param('fn_name', param_mw.validator);

module.exports = router