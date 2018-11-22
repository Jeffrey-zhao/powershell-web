var PSRunner=require('./sample')
var cmdString=`{"cmd":"powershell.exe","file":"test.ps1","command":"Write-Stuff -arg 'zhao'"}`
PSRunner.send(cmdString,(data)=>{console.log(data)})