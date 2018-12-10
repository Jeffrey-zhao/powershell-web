var psExecutor = require('../public/utils/psExecutor'),
    util = require('../public/utils/util'),
    path = require('path'),
    fs = require('fs')

var controller = {
    // common method: invoke script
    invoker: function (req, res) {
        /*
        
                */
        res.send('tst')
    },
    // route: index 
    index: function (req, res) {
        res.render('script/index')
    },
    // route: list
    list: function (req, res) {
        var folder = req.query.dirname || ""
        var root_dirname = req.body.script_dir
        var script_dir = path.join(root_dirname, folder)
        console.log(script_dir)
        if (script_dir) {
            util.rreaddir(script_dir, false)
                .then(pFiles => {
                    var ret_files = []
                    pFiles.map(file => {
                        var stats = fs.statSync(file)
                        var relativePath = file.replace(script_dir, '')
                        if (stats.isDirectory()) {
                            ret_files.push({
                                'name': path.basename(file, path.extname(file)),
                                'type': 'Directory',
                                'path': file,
                                'dirname': file.replace(root_dirname, ''),
                                'relativePath': relativePath,
                                'lastModifiedTime': stats.ctime.toUTCString('yyyy-MM-dd HH-mm-ss')
                            })
                        } else {
                            ret_files.push({
                                'name': path.basename(file, path.extname(file)),
                                'type': 'File',
                                'path': file,
                                'dirname': path.dirname(file).replace(root_dirname, ''),
                                'relativePath': relativePath,
                                'lastModifiedTime': stats.ctime.toUTCString('yyyy-MM-dd HH-mm-ss')
                            })
                        }
                    })
                    console.log({
                        list: ret_files,
                        dirname: folder
                    })
                    res.render('script/list', {
                        list: ret_files,
                        dirname: folder
                    })
                }).catch(err => {
                    console.error(err)
                    return []
                })
        }
    },
    // route: command
    command: function (req, res) {
        res.send('command')
    },
    //route: fn detail
    detail: function (req, res) {
        //var cmdObject = req.params.command
        var cmdObject = {
            cmd: 'powershell.exe',
            type: 'cmd',
            file: 'build/public/utils/test.ps1',
            command: "help get-help"
        }
        psExecutor.send(cmdObject).then(data => {
            res.render('script/function', {
                ret: data
            })
        }, (err) => {
            res.sender('error', {
                err_msg: err
            })
        })
    },
    //route: function
    function: function (req, res) {
        res.send('function')
    },
    //route: execute
    execute: function (req, res) {
        //var cmdObject = req.params.command
        var cmdObject = {
            cmd: 'powershell.exe',
            type: 'cmd',
            file: 'build/public/utils/test.ps1',
            command: "help get-help"
        }
        psExecutor.send(cmdObject).then(data => {
            res.render('script/command', {
                ret: data
            })
        }, (err) => {
            res.sender('error', {
                err_msg: err
            })
        })
    }
}

module.exports = controller