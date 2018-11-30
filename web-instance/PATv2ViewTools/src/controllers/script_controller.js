var invoke = require('../public/utils/psInvoker'),
    util=require('../public/utils/util')

var controller = {
    invoker: function (req, res) {
        var cmdObject = req.params.command
        invoke(cmdObject, data => {
            res.send(data)
        })
    },

    index: function (req, res) {
        res.render('script/index')
    },

    list: function (req, res) {
        var direcory=__dirname+
        util.readDirectory()
    }
}

module.exports = controller