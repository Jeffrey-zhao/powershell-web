var util = require('./util')
var psExecutor = {
	send: function (cmdObject, results=[]) {
		return new Promise((resolve, reject) => {
			var child_process = require('child_process')
			var spawn = child_process.spawn,
				child
			var command = util.getCommand(cmdObject)
			if (!command) {
				reject('request param cmdObject enconters errors...')
			}			
			child = spawn(command.platform_cmd, command.args)
			child.stdout.on('data', function (data) {
				results += data.toString() + "\n"
			})

			child.stderr.on('data', function (data) {
				results += data.toString() + "\n"
				reject(data.toString())
			})

			child.on('exit', function () {
				console.log(results)
				resolve(results)
			})
		})
	}
}

module.exports = psExecutor