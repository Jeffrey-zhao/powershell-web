var psExecutor = require('../public/utils/psExecutor'),
    util = require('../public/utils/util'),
    path = require('path')

var controller = {
    // common method: invoke script
    invoker: function (req, res) {
        var path = req.body.path
        //var cmdObject = req.params.command
        var cmdObject = {
            cmd: 'powershell.exe',
            type: 'cmd',
            file: 'build/public/utils/test.ps1',
            command: "help get-help"
        }
        psExecutor.send(cmdObject).then(data => {
            res.render(path, {
                ret: data
            })
        }, (err) => {
            res.sender('error', {
                err_msg: err.toString()
            })
        })
    },
    // route: index 
    index: function (req, res) {
        res.render('script/index')
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
    // route: command
    command: function (req, res) {
        res.body = {
            path: 'script/index'
        }
        controller.invoker(req, res)
    },
    //route: fn detail
    detail: function (req, res) {
        res.body = {
            path: 'script/index'
        }
        controller.invoker(req, res)
    },
    //route: function
    function: function (req, res) {
        res.body = {
            path: 'script/index'
        }
        controller.invoker(req, res)
    },
    //route: execute
    execute: function (req, res) {
        res.body = {
            path: 'script/index'
        }
        controller.invoker(req, res)
    }
}

module.exports = controller