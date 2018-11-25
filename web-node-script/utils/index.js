var PSRunner=require('./psRunner')
var cmdString=`{"cmd":"pwsh","file":"test.ps1","command":"Write-Stuff -arg 'zhao'"}`
var promise=PSRunner.send(cmdString)
.then(function(data){console.log(data)},function(data){console.log(data)})
