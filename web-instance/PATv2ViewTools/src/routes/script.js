var express = require('express'),
    router = express.Router(),
    script_ctl = require('../controllers/script_controller')

//script/
router.get('/script', script_ctl.index)
router.get('/script/index', script_ctl.index)

router.get('/script/list', script_ctl.list)

router.get('/script/file', script_ctl.file)

router.get('/script/function', script_ctl.fn)

router.get('/script/detail', script_ctl.detail)

router.get('/script/command', script_ctl.command)

router.post('/script/execute', script_ctl.execute)

router.post('/script/upload', script_ctl.upload)

module.exports = router