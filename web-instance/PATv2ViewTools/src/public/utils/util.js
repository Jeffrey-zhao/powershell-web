var path = require('path'),
    fs = require('fs')

var Util = {
    getCommand: function (cmdObjct) {
        var ret = null
        try {
            if (cmdObjct) {
                ret = {
                    "platform_cmd": cmdObjct.cmd,
                    "args": ["-Command",
                        "&{import-module ./" + cmdObjct.file + " -force; " + cmdObjct.command + " }",
                        "-ExecutionPolicy",
                        "Unrestricted"
                    ]
                }
            }
        } catch (e) {
            console.log('passed string is not json format...')
        } finally {
            return ret
        }
    },
    readDirectory: function (path) {
        var filePaths=[]
        readDir(path)

        function readDir(path){
            fs.readdir(path,function(err,menu){	
                if(!menu)
                    return;
                menu.forEach(function(ele){	
                    fs.stat(path+"/"+ele,function(err,info){
                        if(info.isDirectory()){
                            readDir(path+"/"+ele);
                        }else{
                            filePaths.push(ele)
                        }	
                    })
                })			
            })
        }
        return filePaths
    }
}
module.exports = Util