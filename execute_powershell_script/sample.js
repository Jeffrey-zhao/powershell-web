var util = require('./util')
var PSRunner = {
    send: function (cmdString,callback) {
        var result = ''
        var child_process = require('child_process')
        var spawn = child_process.spawn,
            child
        var cmdObject = util.getCmdObject(cmdString)
        if (!cmdObject) {
            console.log('some errors happends...')
            return null
        }
        child = spawn(cmdObject.platform_cmd, cmdObject.args)

        child.stdout.on("data", function (data) {
            result += data.toString()
            //console.log('data from child: ' + data.toString());
        });
        child.stderr.on("data", function (data) {
            result += data.toString()
            //console.log('error from child: ' + data.toString());
        });
        child.on('close', function (code) {
            callback(result)
        })
    },
};

module.exports = PSRunner;