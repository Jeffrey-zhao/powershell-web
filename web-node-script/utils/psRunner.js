var util = require('./util')
var PSRunner = {
	send: function (cmdString, callback) {
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

module.exports = PSRunner