var psExecutor = require('./psExecutor')

function invoke(cmdObject, callback) {
    psExecutor.send(cmdObject, callback)
}

module.exports = invoke