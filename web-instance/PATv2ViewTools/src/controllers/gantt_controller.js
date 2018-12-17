
var controller = {
    //route: job
    job: function (req, res) {
        res.render('gantt/job')
    },
    //route: template
    template: function (req, res) {
        res.render('gantt/template')
    }
}

module.exports = controller