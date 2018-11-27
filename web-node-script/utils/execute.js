function execute(cmdString, callback) {
    var PSRunner = require('./psRunner')
    //var cmdString=`{"cmd":"pwsh","file":"test.ps1","command":"Write-Stuff -arg 'zhao'"}`
    PSRunner.send(cmdString, callback)
}

module.exports = execute