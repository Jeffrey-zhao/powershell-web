var util = require('./util')
var PSRunner = {
	send: function (cmdString) {
		return new Promise((resolve, reject) => {
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
				result += data.toString()
			})

			child.stderr.on('data', function (data) {
				reject(data)
			})

			child.on('exit', function () {
				resolve(result)
			})
		})
	}
}

module.exports = PSRunner