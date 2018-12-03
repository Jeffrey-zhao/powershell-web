var psExecutor = require('./psExecutor')

function invoke(cmdObject) {
    psExecutor.send(cmdObject).then(data => {
        return data
    }, (err) => {
        return err
    })
}

module.exports = invoke