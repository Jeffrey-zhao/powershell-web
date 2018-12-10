var express = require('express'),
    router = express.Router(),
    param_mw = require('../middlewares/param_middleware')
    script_ctl=require('../controllers/script_controller')

//for script 
router.use('/script/*',param_mw.req_script_dir)
//script/
router.get('/script', script_ctl.index)
router.get('/script/index', script_ctl.index)

router.get('/script/list', script_ctl.list)

router.get('/script/function', script_ctl.function)

router.get('/script/detail', script_ctl.detail)

router.get('/script/command', script_ctl.command)

router.post('/script/execute', script_ctl.execute)

router.param(param_mw.param)

router.param('file_path', param_mw.validator);

router.param('fn_name', param_mw.validator);

module.exports = router