var path = require('path'),
    fs = require('fs')

function readDirectory(filePath) {
    var allFiles = []
    readDir(filePath)

    function readDir(filePath) {
        fs.readdir(filePath, function (err, files) {
            if (!files) {
                console.err(err);
                return []
            }

            files.forEach(function (filename) {
                var filedir = path.join(filePath, filename)
                fs.stat(filedir, function (err, stats) {
                    if (stats.isDirectory()) {
                        readDir(filedir);
                    } else {
                        allFiles.push(filedir)
                    }
                })
            })
        })
    }
    return allFiles
}

readDirectory("E:\\GitHub\\Powershell-Web\\web-instance\\PATv2ViewTools\\Cmdlets\\scripts")
module.exports = readDirectory