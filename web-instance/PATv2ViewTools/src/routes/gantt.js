var express = require('express'),
    router = express.Router()

router.get('/gantt/:view?', function (req, res) {
    console.log(req.params)
    var view = req.params.view
    switch (view) {
        case 'job':
            {
                res.render('gantt/job')
                break;
            }
        case 'template':
            {
                res.render('gantt/template')
                break;
            }
        default:{
            res.render('gantt/index')
            break;
        }
    }
})

module.exports = router