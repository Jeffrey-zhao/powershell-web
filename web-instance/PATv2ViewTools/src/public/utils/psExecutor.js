var util = require('./util')
var psExecutor = {
	send: function (cmdObejct, callback) {
		var result = ''
		var child_process = require('child_process')
		var spawn = child_process.spawn,
			child
		var command = util.getCommand(cmdObejct)
		if (!cmdObject) {
			console.log('some errors happends...')
			return null
		}
		child = spawn(command.platform_cmd, command.args)
		child.stdout.on('data', function (data) {
			result += data.toString()+"\n"
		})

		child.stderr.on('data', function (data) {
			result += data.toString()+"\n"
		})

		child.on('exit', function () {
			callback(result)
		})
	}
}

module.exports = psExecutor