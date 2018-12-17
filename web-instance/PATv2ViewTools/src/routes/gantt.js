var express = require('express'),
    gantt_ctl = require('../controllers/gantt_controller'),
    router = express.Router()

router.get('/gantt/:view?', function (req, res) {
    var view = req.params.view || ''
    switch (view) {
        case 'job':
            {
                gantt_ctl.job(req, res)
                break;
            }
        case 'template':
            {
                gantt_ctl.template(req, res)
                break;
            }
    }
})

module.exports = router