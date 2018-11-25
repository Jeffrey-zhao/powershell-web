var PSRunner=require('./index')
var cmdString=`{"cmd":"powershell.exe","file":"test.ps1","command":"Write-Stuff -arg 'zhao'"}`
//var cmdObject={cmd:'powershell.exe',file:'test.ps1',command:"Write-Stuff -arg 'zhao'"}
var promise=PSRunner.send(cmdString)
.then(function(data){console.log(data)},function(data){console.log(data)})
