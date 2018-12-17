var minimist = require('minimist');

var util = {
    config_args: function () {
        var deploy_env = {
            int: {
                env: 'int',
                port: 3333
            },
            prod: {
                env: 'prod',
                port: 3000
            }
        }
        var knownOptions = {
            string: ['build_env', 'port', 'env', 'host'],
            default: {
                build_env: process.env.NODE_ENV || 'production',
                env: deploy_env.int.env,
                port: deploy_env.int.port
            }
        };
        return minimist(process.argv.slice(2), knownOptions);
    },
    platform_cmd: function () {
        var osvar = process.platform;
        var cmd = 'powershell.exe'
        if (osvar == 'darwin') {
            cmd = 'pwsh'
            console.log("you are on a mac os");
        } else if (osvar == 'win32') {
            cmd = 'powershell.exe'
            console.log("you are on a windows os")
        } else {
            cmd = 'unknown cmd'
            console.log("unknown os")
        }
        return cmd
    }
}

module.exports = util