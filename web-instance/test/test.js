var fs = require('fs'),
    path = require('path')

var paths = ['E:\\GitHub\\Powershell-Web\\web-instance\\PATv2ViewTools\\Cmdlets\\scripts\\1.ps1',
    'E:\\GitHub\\Powershell-Web\\web-instance\\PATv2ViewTools\\Cmdlets\\scripts\\2.ps1',
    'E:\\GitHub\\Powershell-Web\\web-instance\\PATv2ViewTools\\Cmdlets\\scripts\\parent',
    'E:\\GitHub\\Powershell-Web\\web-instance\\PATv2ViewTools\\Cmdlets\\scripts\\parent\\3.ps1'
]

var ret_files = [];
for(file in paths)
{
    fs.stat(file, function (err, stats) {
        if (stats.isDirectory()) {
            ret_files.push({
                'name': path.basename(file, path.extname(file)),
                'type': 'Directory',
                'path': file,
                'lastModifiedTime': stats.ctime
            })
        } else {
            ret_files.push({
                'name': path.basename(file, path.extname(file)),
                'type': 'File',
                'path': file,
                'lastModifiedTime': stats.ctime
            })
        }
    })
}

paths.forEach(file => {
    await fs.statSync(file, function (err, stats) {
        if (stats.isDirectory()) {
            ret_files.push({
                'name': path.basename(file, path.extname(file)),
                'type': 'Directory',
                'path': file,
                'lastModifiedTime': stats.ctime
            })
        } else {
            ret_files.push({
                'name': path.basename(file, path.extname(file)),
                'type': 'File',
                'path': file,
                'lastModifiedTime': stats.ctime
            })
        }
    })
})

console.log(ret_files)