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
        var root_dirname = req.app.get('script_dir')
        var script_dir = path.join(root_dirname, folder)
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
                                'lastModifiedTime': stats.ctime.toUTCString('MM/dd/yyyy HH:mm:ss')
                            })
                        } else {
                            ret_files.push({
                                'name': path.basename(file, path.extname(file)),
                                'type': 'File',
                                'path': file,
                                'dirname': path.dirname(file).replace(root_dirname, ''),
                                'relativePath': relativePath,
                                'lastModifiedTime': stats.ctime.toUTCString('MM/dd/yyyy HH:mm:ss')
                            })
                        }
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
        var filepath = req.query.filepath
        var fn = req.query.fn
        console.log(filepath, fn)
        if (filepath && fn) {
            var file_path = path.join(req.app.get('script_dir'), filepath)
            var invoker_path = path.join(req.app.get('root'), req.app.get('env'), 'public/utils/psInvoker.ps1')
            var function_path = path.join(req.app.get('root'), req.app.get('env'), 'public/utils/psFunction.ps1')
            console.log(invoker_path)
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                file: [function_path, invoker_path, file_path],
                command: " Invoke-Function -ScriptPath " + file_path + " -FunctionName " + fn
            }

            psExecutor.send(cmdObject).then(data => {
                console.log(data)
                var commands = JSON.parse(data)
                console.log(commands)
                res.render('script/command', {
                    commands: commands,
                    file_path: filepath,
                    function_name: fn
                })
            }, err => {
                res.render('error', {
                    err_msg: err,
                    url: req.originalUrl
                })
            })
        } else {
            res.render('error', {
                err_msg: 'please choose valid file or function ...'
            })
        }
    },
    //route: fn detail
    detail: function (req, res) {
        res.send('testing data')
    },
    //route: function
    function: function (req, res) {
        var filepath = req.query.filepath
        if (filepath) {
            var file_path = path.join(req.app.get('script_dir'), filepath)
            var invoker_path = path.join(req.app.get('root'), req.app.get('env'), 'public/utils/psInvoker.ps1')
            var function_path = path.join(req.app.get('root'), req.app.get('env'), 'public/utils/psFunction.ps1')
            console.log(invoker_path)
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                file: [function_path, invoker_path, file_path],
                command: " Invoke-Script -ScriptPath " + file_path
            }
            psExecutor.send(cmdObject).then(data => {
                var list = JSON.parse(data)

                res.render('script/function', {
                    list: list,
                    file_path: filepath
                })
            }, err => {
                res.render('error', {
                    err_msg: err,
                    url: req.originalUrl
                })
            })
        } else {
            res.render('error', {
                err_msg: 'please choose valid file path...'
            })
        }
    },
    //route: execute
    execute: function (req, res) {
        var base = req.body.base
        if (base && base.length == 2) {
            var file_path = path.join(req.app.get('script_dir'), base[1].file_path)
            var invoker_path = path.join(req.app.get('root'), req.app.get('env'), 'public/utils/psInvoker.ps1')
            var function_path = path.join(req.app.get('root'), req.app.get('env'), 'public/utils/psFunction.ps1')
            console.log(" -ArgumentList " + JSON.stringify(req.body.data))
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                file: [function_path, invoker_path, file_path],
                command: "Execute-Function -FunctionName " + base[0].function_name + " -ArgumentList " + escape(JSON.stringify(req.body.data))
            }
            psExecutor.send(cmdObject).then(data => {
                res.send({
                    content: data.toString()
                })
            }, err => {
                res.send({
                    content: 'when handling cmdlets errors happend...\n ' + err.toString(),
                })
            })
        } else {
            res.send({
                content: 'please supply valid data...'
            })
        }
    },
    test: function (req, res) {
        console.log('testing')
        console.log(req.body)
        console.log(req.body.file)
        res.send(req.body.param)
    }
}

module.exports = controller