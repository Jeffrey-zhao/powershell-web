var spawn = require('child_process').spawn,child

var cmd="powershell.exe -ExecutionPolicy Unrestricted -Command { . ./test.ps1; Write-Stuff -arg1 'Hello' -arg2 'Jeffrey'} "
child=spawn(cmd)
exec(cmd, function (err, stdout, stderr) {
	console.log(stdout)
})
