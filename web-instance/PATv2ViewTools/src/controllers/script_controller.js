var psExecutor = require('../public/utils/psExecutor'),
    util = require('../public/utils/util'),
    path = require('path')

var controller = {
    // common method: invoke script
    invoker: function (req, res) {
        //var cmdObject = req.params.command
        var cmdObject = {
            cmd: 'powershell.exe',
            type: 'cmd',
            file: 'build/public/utils/test.ps1',
            command: "help get-help -detailed"
        }
        psExecutor.send(cmdObject).then(data => {
            console.log(req.path, req, originUrl, req.route, req.query)
            var path = req.path.split('\\')
            res.render('script/' + path[-1], {
                ret: data
            })
        }, (err) => {
            res.send(err)
        }).catch(function (err) {
            res.send(err)
        })
    },
    // route: index 
    index: function (req, res) {
        res.render('script/' + req.params.path)
    },
    // route: list
    list: function (req, res) {
        var script_dir = req.body.script_dir
        if (script_dir) {
            util.rreaddir(script_dir).then(pFiles => {
                var ret_files = []
                pFiles.map(file => {
                    ret_files.push({
                        file_name: path.basename(file, path.extname(file)),
                        file_path: file
                    })
                })
                res.render('script/list', {
                    list: ret_files
                })
            }, () => {
                throw new Error('reading directory encounter error...')
            }).catch((err) => {
                console.error(err)
            })
        }
    },
    // route: commandLine
    command: function (req, res) {
        controller.invoker(req, res)
    },
    // route: file detail
    file_detail: function (req, res) {
        controller.invoker(req, res)
    },
    // route: function detail
    fn_detail: function (req, res) {
        controller.invoker(req, res)
    },
    // route: execute
    execute: function (req, res) {
        controller.invoker(req, res)
    },
    param: function (req, res) {
        res.render('script/' + req.params.param)
    }
}
module.exports = controller