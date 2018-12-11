var path = require('path'),
    fs_promise = require('fs-promise')

var Util = {
    // format req object to command object
    getCommand: function (cmdObjct) {
        var ret = null
        try {
            if (cmdObjct) {
                console.log(cmdObjct)
                switch (cmdObjct.type) {
                    case 'file':
                        {
                            var importFiles = ''
                            cmdObjct.file.map(file => {
                                importFiles += " import-module " + file + " -force;"
                            })
                            ret = {
                                "platform_cmd": cmdObjct.cmd,
                                "args": ["-Command",
                                    "&{" + importFiles + cmdObjct.command + " }",
                                    "-ExecutionPolicy",
                                    "Unrestricted"
                                ]
                            }
                            break;
                        }
                    case 'cmd':
                        {
                            ret = {
                                "platform_cmd": cmdObjct.cmd,
                                "args": ["-Command",
                                    "&{" + cmdObjct.command + " }",
                                    "-ExecutionPolicy",
                                    "Unrestricted"
                                ]
                            }
                            break;
                        }
                }
            }
        } catch (e) {
            console.log('passed string is not json format...')
        } finally {
            return ret
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
    }
}
module.exports = Util