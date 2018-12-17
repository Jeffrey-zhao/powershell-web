var Util = {
    getCmdObject: function (cmdString) {
        var ret = null
        try {
            var obj = JSON.parse(cmdString)
            if (obj) {
                ret = {
                    "platform_cmd": obj.cmd,
                    "args": ["-Command",
                        "&{import-module ./" + obj.file + " -force;" + obj.command+"}",
                        "-ExecutionPolicy",
                        "Unrestricted"
                    ]
                }
            }
        } catch(e) {
            console.log('passed string is not json format...')
        } finally {
            return ret
        }
    }
}
module.exports=Util