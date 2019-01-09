var express = require('express'),
    bodyParser = require('body-parser'),
    path = require('path'),
    util = require('./util'),
    open = require('open'),
    addRequestId = require('express-request-id')(),
    morgan = require('morgan'),
    fs = require('fs'),
    app = express(),
    config_args = util.config_args(),
    platform_cmd = util.platform_cmd(),
    build_env

if (config_args.build_env === 'production') {
    build_env = 'dist'
} else {
    build_env = 'build'
}

// logger
var logDirectory = path.join(__dirname, build_env, 'log')

// ensure log directory exists
fs.existsSync(logDirectory) || fs.mkdirSync(logDirectory)
// create a write stream (in append mode)
var logPath = path.join(logDirectory, config_args.env + '_access.log')

app.use(addRequestId);

morgan.token('id', function getId(req) {
    return req.id
});
var loggerFormat = ':id [:date[web]] ":method :url" :status :response-time';

app.use(morgan(loggerFormat, {
    skip: function (req, res) {
        return res.statusCode < 400
    },
    stream: process.stderr
}));

app.use(morgan(loggerFormat, {
    skip: function (req, res) {
        return res.statusCode >= 400
    },
    stream: process.stdout
}));

var swig = require('./' + build_env + '/public/vendor/swig/lib/swig'),
    routeIndex = require('./' + build_env + '/routes/index'),
    routeGantt = require('./' + build_env + '/routes/gantt'),
    routeScript = require('./' + build_env + '/routes/script')

var base_mw = require('./' + build_env + '/middlewares/base')

//engine
app.engine('html', swig.renderFile)
app.set('view engine', 'html')
app.set('views', path.join(__dirname, build_env, 'views'))

//custom swig filter
swig.setFilter('paramFilter', function (input, arg) {
    console.log(input)
    var filterItems = input.filter(x => x.Name == arg)
    console.log(filterItems)
    return filterItems
})
//custom swig filter to get input type
swig.setFilter('paramTypeFilter', function (input, arg, types) {
    var validCol = types
    var filterItems = input.filter(x => x.Name == arg && x.Attributes &&
        x.Attributes.filter(y => validCol.includes(y.TypeName.toLowerCase())).length > 0)
    var typeItems = null
    if (filterItems) {
        typeItems = filterItems.map(x => {
            return {
                Name:x.Name,
                DefaultValue:x.DefaultValue,
                Attributes: x.Attributes.filter(y => validCol.includes(y.TypeName.toLowerCase()))
                    .map(y => {
                        return {
                            TypeName: y.TypeName,
                            Arguments: y.PositionalArguments
                        }
                    })
            }
        }).map(x => {
            return {
                Name: x.Name,
                DefaultValue: x.DefaultValue,
                TypeName: x.Attributes[0].TypeName,
                Arguments: x.Attributes[0].Arguments
            }
        })
        if(typeItems){
            return typeItems[0]
        }
    }
    return typeItems
})
//custom variable
app.set('script_dir', path.join(__dirname, 'CmdLets/Scripts'))
app.set('cmdlets_dir', path.join(__dirname, 'CmdLets'))
app.set('root', path.join(__dirname))
app.set('build_env', build_env)
app.set('deploy_env', config_args.env)
app.set('cmd', platform_cmd)

// hook up with your app
app.use(bodyParser.urlencoded({
    extended: true
}));
app.use(bodyParser.json());

//route
app.use(routeIndex)
app.use(routeGantt)
app.use(routeScript)

//staic file
app.use(express.static(path.join(__dirname, build_env, 'public')));

//base middleware
app.use(base_mw.beforelog(logPath));
app.use(base_mw.afterlog(logPath));

//error handler
app.use(base_mw.log_error)
app.use(base_mw.client_error_handler)
app.use(base_mw.error_handler)

app.listen(config_args.port, function () {
    console.log("Server is running on port " + config_args.port + " of enviroment " + build_env + "...")
    console.log('please navigate http://127.0.0.1:' + config_args.port + " to view...")
})

open('http://127.0.0.1:' + config_args.port)