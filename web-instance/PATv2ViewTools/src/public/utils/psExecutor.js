var util = require('./util')
var psExecutor = {
    send: function (cmdObject, results = []) {
        return new Promise((resolve, reject) => {
            var child_process = require('child_process')
            var spawn = child_process.spawn,
				child
            var command = util.getCommand(cmdObject)

            if (!command) {
                reject('request param cmdObject enconters errors...')
            }
            console.log(command.args)
            child = spawn(command.platform_cmd, command.args)
            child.stdout.on('data', function (data) {
                results += data
                console.log(data.toString())
            })

            child.stderr.on('data', function (data) {
                results += data
                console.log(data.toString())
                reject(data)
            })

            child.on('exit', function () {
                resolve(results)
            })
        })
    }
}

module.exports = psExecutor