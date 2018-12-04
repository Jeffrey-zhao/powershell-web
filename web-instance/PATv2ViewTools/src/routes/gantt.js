var express = require('express'),
    router = express.Router()

router.get('/gantt/:view?', function (req, res) {
    var view = req.params.view ||''
    console.log(view)
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