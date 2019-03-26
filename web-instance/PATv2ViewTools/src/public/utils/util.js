var path = require('path'),
    fs_promise = require('fs-promise')

var Util = {
    // format req object to command object
    getCommand: function (ps,cmdObjct) {
        try {
            if (cmdObjct) {
                console.log(cmdObjct)
                switch (cmdObjct.type) {
                    case 'file':
                        {
                            ps.clear()
                            ps.addCommand(" set-location -Path '" + cmdObjct.dir + "' ")
                            cmdObjct.files.map(file => {
                                ps.addCommand(" Import-Module '" + file + "'")
                            })
							ps.addCommand(cmdObjct.command)
                            break;
                        }
                    case 'cmd':
                        {
                            ps.clear()
                            ps.addCommand(cmdObjct.command)
                            break;
                        }
                }
            }
        } catch (e) {
            console.log('passed string is not json format...')
        } finally {
            return ps
        }
    },
    rreaddir: async function (dir, isRecurise = false, allFiles = []) {
        var files = (await fs_promise.readdir(dir)).map(f => path.join(dir, f))
        allFiles.push(...files)
        if (isRecurise) {
            await Promise.all(files.map(async f => (
                (await fs_promise.stat(f)).isDirectory() && this.rreaddir(f, isRecurise, allFiles)
            )))
        }
        return allFiles
    },
    rreadFile: async function (filePath) {
        return await fs_promise.readFile(filePath, {
            encoding: 'utf-8'
        })
    },
    GetEnvCommand: function (req, res) {
        var retcmdString = ''
        retcmdString += '.\\' + path.join('Scripts', 'SetupEnvironment.ps1')
        retcmdString += ' -Environment ' + req.app.get('deploy_env') + ' -WorkingDir ' + req.app.get('cmdlets_dir') + ";"
        return retcmdString
    }
}
module.exports = Util