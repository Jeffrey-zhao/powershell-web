var express = require('express'),
    bodyParser = require('body-parser'),
    path = require('path'),
    util = require('./util'),
    open = require('open'),
    config_args = util.config_args(),
    platform_cmd = util.platform_cmd(),
    build_env

if (config_args.build_env === 'production') {
    build_env = 'dist'
} else {
    build_env = 'build'
}
console.log(build_env, config_args)
var swig = require('./' + build_env + '/public/vendor/swig/lib/swig'),
    app = express(),
    routeBase = require('./' + build_env + '/routes/base'),
    routeIndex = require('./' + build_env + '/routes/index'),
    routeGantt = require('./' + build_env + '/routes/gantt'),
    routeScript = require('./' + build_env + '/routes/script')

var base_mw = require('./' + build_env + '/middlewares/base_middleware')

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

//custom variable
app.set('script_dir',path.join(__dirname, 'CmdLets/Scripts'))
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
app.use(routeBase)
app.use(routeIndex)
app.use(routeGantt)
app.use(routeScript)

//base middleware
app.use(base_mw.log)

//staic file
app.use(express.static(path.join(__dirname, build_env, 'public')));

//error handler
app.use(base_mw.log_error)
app.use(base_mw.client_error_handler)
app.use(base_mw.error_handler)

app.listen(config_args.port, function () {
    console.log("Server is running on port " + config_args.port + " of enviroment " + build_env + "...")
    console.log('please navigate http://127.0.0.1:' + config_args.port + " to view...")
})

open('http://127.0.0.1:' + config_args.port)