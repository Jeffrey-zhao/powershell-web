var minimist = require('minimist');

var util = {
    run_env: function () {
        var knownOptions = {
            string: 'env',
            default: {
                env: process.env.NODE_ENV || 'production'
            }
        };
        return minimist(process.argv.slice(2), knownOptions);
    },
    platform_cmd: function () {
        var osvar = process.platform;
        var cmd='powershell.exe'
        if (osvar == 'darwin') {
            cmd='pwsh'
            console.log("you are on a mac os");
        } else if (osvar == 'win32') {
            cmd='powershell.exe'
            console.log("you are on a windows os")
        } else {
            cmd='unknown cmd'
            console.log("unknown os")
        }
        return cmd
    }
}

module.exports = util