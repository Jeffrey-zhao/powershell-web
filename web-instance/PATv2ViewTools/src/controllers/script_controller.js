var psExecutor = require('../public/utils/psExecutor'),
    util = require('../public/utils/util'),
    path = require('path'),
    fs = require('fs'),
    multiparty = require('multiparty')

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

        if (fs.existsSync(script_dir)) {
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
            var file_path = path.join(req.app.get('script_dir'), filepath)
            var invoker_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psInvoker.ps1')
            var function_path = path.join(req.app.get('root'), req.app.get('build_env'), 'public/utils/psFunction.ps1')
            var help_file_path = path.join(req.app.get('root'), req.app.get('build_env'), 'scriptHelps')
            var fn_path = path.join(help_file_path, path.basename(filepath, path.extname(filepath)), fn + '.txt')
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                dir: path.join(req.app.get('root'), 'CmdLets'),
                file: [function_path, invoker_path, file_path],
                command: " Invoke-Function -ScriptPath '" + file_path + "' -FunctionName " + fn
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
            var help_file_path = path.join(req.app.get('root'), req.app.get('build_env'), 'scriptHelps')
            var file_name = 'script.txt'
            if (fn) {
                fn_param = " -FunctionName " + fn
                file_name = fn + ".txt"
            }
            var file_path = path.join(help_file_path, path.basename(filepath, path.extname(filepath)), file_name)
            try {
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
            } catch (e) {
                fs.render('error', {
                    err_msg: "cannot find this function's or script's detail"
                })
            }

        }
    },
    //route: file
    readfile: function (req, res) {
        var filepath = req.query.filepath
        var file_path = path.join(req.app.get('script_dir'), filepath)
        if (fs.existsSync(file_path)) {
            try {
                res.sendFile(file_path)
            } catch (e) {
                res.render('error', {
                    err_msg: "cannot find this function's detail"
                })
            }

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
    fn: function (req, res) {
        var filepath = req.query.filepath
        if (filepath) {
            var file_path = path.join(req.app.get('script_dir'), filepath)
            var invoker_path = "..\\" + path.join(req.app.get('build_env'), 'public/utils/psInvoker.ps1')
            var function_path = "..\\" + path.join(req.app.get('build_env'), 'public/utils/psFunction.ps1')
            var help_file_path = "..\\" + path.join(req.app.get('build_env'), 'scriptHelps');
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                dir: req.app.get('cmdlets_dir'),
                file: [function_path, invoker_path, file_path],
                command: " Invoke-Script -ScriptPath '" + file_path + "' -HelpFilePath '" + help_file_path + "'"
            }
            psExecutor.send(cmdObject).then(data => {
                console.log(data)
                var list = JSON.parse(data)

                res.render('script/function', {
                    list: list,
                    file_path: filepath
                })
            }).catch(err => {
                console.log(err.toString())
                res.render('error', {
                    err_msg: 'the script has something wrong,please check it...'
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
        var data = req.body.data
        if (base && base.length == 2) {
            var file_path = ".\\"+path.join('Scripts', base[1].file_path)
            var invoker_path = "..\\"+path.join(req.app.get('build_env'), 'public/utils/psInvoker.ps1')
            var function_path = "..\\"+path.join(req.app.get('build_env'), 'public/utils/psFunction.ps1')
            var preEnvCmdString = util.GetEnvCommand(req, res)
            // change file's path           
            if (data) {
                console.log(data)
                data.filter(x => x.isFile == 'true' && x.value != '').forEach(function (item) {
                    item.value = path.join(req.app.get('root'), 'CmdLets/uploadFiles', path.basename(item.value))
                })
            }
            var cmdObject = {
                cmd: req.app.get('cmd'),
                type: 'file',
                dir: req.app.get('cmdlets_dir'),
                file: [function_path, invoker_path, file_path],
                command: preEnvCmdString + " Execute-Function -FunctionName " + base[0].function_name + " -ArgumentList " + escape(JSON.stringify(data))
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
    },
    upload: function (req, res) {
        var uploadDir = 'CmdLets/uploadFiles'
        var form = new multiparty.Form({
            uploadDir: uploadDir
        });

        fs.existsSync(uploadDir) || fs.mkdirSync(uploadDir)
        form.parse(req, function (err, fields, files) {
            console.log(JSON.stringify(files))
            if (err) {
                console.log('parse error: ' + err);
                res.render('error', {
                    err_msg: 'upload files is failed...'
                })
            } else {
                var err_flag = false
                for (var key in files) {
                    var inputFile = files[key][0];
                    var uploadedPath = inputFile.path;
                    var dstPath = path.join(uploadDir, inputFile.originalFilename);
                    //重命名为真实文件名
                    console.log(dstPath, uploadedPath)
                    fs.rename(uploadedPath, dstPath, function (err) {
                        if (err) {
                            err_flag = true
                        }
                    });
                }
                if (err_flag) {
                    res.render('error', {
                        err_msg: 'upload files is successful,but rename file is failed...'
                    })
                } else {
                    console.log('success')
                    res.send({
                        content: 'send files successfully',
                        uploadDir: uploadDir
                    })
                }
            }
        });
    }
}

module.exports = controller