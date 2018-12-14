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
			child = spawn(command.platform_cmd, command.args)
			child.stdout.on('data', function (data) {
				results += data
				console.log('data-out:', results.toString())
			})

			child.stderr.on('data', function (data) {
				results += data
				console.log('data-err:', results.toString())
				reject(data)
			})

			child.on('exit', function () {
				console.log('exit:', results.toString())
				resolve(results)
			})
		})
	}
}

module.exports = psExecutor