var path = require('path'),
    fs_promise = require('fs-promise')

var Util = {
    // format req object to command object
    getCommand: function (cmdObjct) {
        var ret = null
        try {
            if (cmdObjct) {
                switch (cmdObjct.type) {
                    case 'file':
                        ret = {
                            "platform_cmd": cmdObjct.cmd,
                            "args": ["-Command",
                                "&{import-module ./" + cmdObjct.file + " -force; " + cmdObjct.command + " }",
                                "-ExecutionPolicy",
                                "Unrestricted"
                            ]
                        }
                    case 'cmd':
                        ret = {
                            "platform_cmd": cmdObjct.cmd,
                            "args": ["-Command",
                                "&{" + cmdObjct.command + " }",
                                "-ExecutionPolicy",
                                "Unrestricted"
                            ]
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