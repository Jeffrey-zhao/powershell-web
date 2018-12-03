var invoke = require('../public/utils/psInvoker'),
    util = require('../public/utils/util')
path = require('path')

var controller = {
    invoker: function (req, res) {
        var cmdObject = req.params.command
        invoke(cmdObject, data => {
            res.send(data)
        })
    },

    index: function (req, res) {
        var cmdObject = {
            cmd: 'powershell.exe',
            file: 'build/public/utils/test.ps1',
            command: "Write-Args -arg 'zhao'"
        }
        var ret=invoke(cmdObject)
        console.log(ret)
        res.send(ret)
        res.end()
        //res.render('script/index')
    },

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
                res.send({
                    list: ret_files
                })
                res.end()
            }, () => {
                throw new Error('reading directory encounter error...')
            }).catch((err) => {
                console.error(err)
            })
        }
    }
}
module.exports = controller