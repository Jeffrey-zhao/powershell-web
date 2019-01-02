var psExecutor = require('../public/utils/psExecutor'),
    util = require('../public/utils/util'),
    path = require('path'),
    fs = require('fs')

var controller = {
    // route: index 
    index: function (req, res) {
        res.render('script/introduction')
    },
    // route: list
    list: function (req, res) {
        var folder = req.query.dirname || ""
        var root_dirname = req.app.get('script_dir')
        var script_dir = path.join(root_dirname, folder)
        var folder_items = folder.split('\\')
        var tempUrl = '\\'
        var paths = [{
            text: 'root',
            url: '\\'
        }]
        for (i = 0; i < folder_items.length; i++) {
            if (folder_items[i] == '') continue
            tempUrl = path.join(tempUrl, folder_items[i])
            paths.push({
                text: folder_items[i],
                url: tempUrl
            })
        }

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
                        dirname: folder,
                        list_paths: paths
                    })
                }).catch(err => {
                    res.render('error', {
                        err_msg: 'something errors happened when search files...' + err.toString()
                    })
                })
        } else {
            res.render('error', {
                err_msg: "cannot find 'Cmdlets/scripts' folder,please check your server..."
            })
        }
    },
    // route: command
    command: function (req, res) {
        var filepath = req.query.filepath
        var fn = req.query.fn
        if (filepath && fn) {
            var file_path = path.join(req.app.get('script_dir'), filepath).replace(/\s+/g, '` ')
            var invoker_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psInvoker.ps1').replace(/\s+/g, '` ')
            var function_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psFunction.ps1').replace(/\s+/g, '` ')
            var help_file_path = path.join(req.app.get('root'), req.app.get('build_env'), 'scripthelps').replace(/\s+/g, '` ')
            var fn_path = path.join(help_file_path, path.basename(filepath, path.extname(filepath)), fn + '.txt')
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                file: [function_path, invoker_path, file_path],
                command: " Invoke-Function -ScriptPath " + file_path + " -FunctionName " + fn
            }

            psExecutor.send(cmdObject).then(data => {
                var commands = JSON.parse(data)
                return commands
            }).then(data => {
                fs.readFile(fn_path, 'utf-8', (err, content) => {
                    if (err) {
                        return res.render('error', {
                            err_msg: "when reading function's detail errors happended..." + err.toString()
                        })
                    }
                    return res.render('script/command', {
                        commands: data,
                        file_path: filepath,
                        function_name: fn,
                        content: content
                    })
                })
            }).catch(err => {
                res.render('error', {
                    err_msg: err.toString()
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
        var filepath = req.query.filepath
        var fn = req.query.fn || ''
        if (filepath) {
            var help_file_path = path.join(req.app.get('root'), req.app.get('build_env'), 'scripthelps').replace(/\s+/g, '` ')
            var file_name = 'script.txt'
            if (fn) {
                fn_param = " -FunctionName " + fn
                file_name = fn + ".txt"
            }
            var file_path = path.join(help_file_path, path.basename(filepath, path.extname(filepath)), file_name)
            fs.readFile(file_path, 'utf-8', (err, content) => {
                if (err) {
                    res.render('error', {
                        err_msg: 'cannot find detail file or when reading file errors happended...'
                    })
                }
                res.send({
                    content: content
                })
            })
        }
    },
    //route: file
    file: function (req, res) {
        var filepath = req.query.filepath
        if (filepath) {
            var file_path = path.join(req.app.get('script_dir'), filepath)
            res.sendFile(file_path)
            /*
            util.rreadFile(file_path).then(data => {
                console.log("file:", data)
                res.render('script/file', {
                    content: data,
                    file_path: filepath
                })
            }).catch(err => {
                res.render('error', {
                    err_msg: err.toString()
                })
            })
            */
        } else {
            res.render('error', {
                err_msg: 'please choose valid file path...'
            })
        }
    },
    //route: function
    function: function (req, res) {
        var filepath = req.query.filepath
        if (filepath) {
            var file_path = path.join(req.app.get('script_dir'), filepath).replace(/\s+/g, '` ')
            var invoker_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psInvoker.ps1').replace(/\s+/g, '` ')
            var function_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psFunction.ps1').replace(/\s+/g, '` ')
            var help_file_path = path.join(req.app.get('root'), req.app.get('build_env'), 'scripthelps').replace(/\s+/g, '` ');
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                file: [function_path, invoker_path, file_path],
                command: " Invoke-Script -ScriptPath " + file_path + " -HelpFilePath " + help_file_path
            }
            psExecutor.send(cmdObject).then(data => {
                var list = JSON.parse(data)
                res.render('script/function', {
                    list: list,
                    file_path: filepath
                })
            }).catch(err => {
                res.render('error', {
                    err_msg: err.toString()
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
            var file_path = path.join(req.app.get('script_dir'), base[1].file_path).replace(/\s+/g, '` ')
            var invoker_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psInvoker.ps1').replace(/\s+/g, '` ')
            var function_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psFunction.ps1').replace(/\s+/g, '` ')
            var preEnvCmdString = util.GetEnvCommand(req, res)
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                file: [function_path, invoker_path, file_path],
                command: preEnvCmdString + " Execute-Function -FunctionName " + base[0].function_name + " -ArgumentList " + escape(JSON.stringify(req.body.data))
            }
            psExecutor.send(cmdObject).then(data => {
                res.send({
                    content: data.toString()
                })
            }).catch(err => {
                res.send({
                    content: 'when handling cmdlets errors happend...\n ' + err.toString(),
                })
            })
        } else {
            res.send({
                content: 'please supply valid data...'
            })
        }
    }
}

module.exports = controller