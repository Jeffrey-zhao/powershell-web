var gulp = require('gulp'),
    runSequence = require('run-sequence'),
    msbuild = require('gulp-msbuild'),
    spawn = require("child_process").spawn,
    child;

gulp.task('default', function () {
    runSequence('clean', 'build', 'powershell');
});

gulp.task('build', ['clean'], function () {
    return gulp.src('../../*.sln')
        .pipe(msbuild({
            toolsVersion: 14.0,
            targets: ['Rebuild'],
            errorOnFail: true,
            properties: {
                DeployOnBuild: true,
                DeployTarget: 'Package',
                PublishProfile: 'Development'
            },
            maxBuffer: 2048 * 1024,
            stderr: true,
            stdout: true,
            fileLoggerParameters: 'LogFile=Build.log;Append;Verbosity=detailed',
        }));
});

gulp.task('powershell', function (callback) {
    child = spawn("powershell.exe", ["c:\\temp\\helloworld.ps1"]);
    child.stdout.on("data", function (data) {
        console.log("Powershell Data: " + data);
    });
    child.stderr.on("data", function (data) {
        console.log("Powershell Errors: " + data);
    });
    child.on("exit", function () {
        console.log("Powershell Script finished");
    });
    child.stdin.end(); //end input
    callback();
});

//edit 1

var exec = require('child_process').exec;
var commnad='Powershell.exe  -executionpolicy remotesigned -File  file.ps1'
gulp.task('powershell', function (callback) {
    exec(commnad, function (err, stdout, stderr) {
        console.log(stdout);
        callback(err)
    });
});

//edit 2 file.ps1
/*
function Write-Stuff($arg1, $arg2){
    Write-Output $arg1;
    Write-Output $arg2;
}
Write-Stuff -arg1 "hello" -arg2 "See Ya"
*/

//edit 3

gulp.task('powershell', function (callback) {
    exec("Powershell.exe  -executionpolicy remotesigned . .\\file.ps1; Write-Stuff -arg1 'My first param' -arg2 'second one here'", function (err, stdout, stderr) {
        console.log(stdout);
        callback(err)
    });
});