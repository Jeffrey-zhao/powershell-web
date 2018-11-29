var express = require('express'),
    router = express.Router()

router.get('/gantt/:view', function (req, res) {
    var view = req.params.view
    if (!view) {
        res.render('index')
    }
    switch (view) {
        case 'job':
            {
                res.render('job')
                break;
            }
        case 'template':
            {
                res.render('job')
                break;
            }
    }
})

module.exports = router