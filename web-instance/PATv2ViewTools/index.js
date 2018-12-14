var express = require('express'),
    bodyParser = require('body-parser'),
    path = require('path'),
    util = require('./util'),
    port = 3000,
    open = require('open'),
    run_env = util.run_env(),
    platform_cmd = util.platform_cmd(),
    env

if (run_env === 'production') {
    env = 'dist'
} else {
    env = 'build'
}

var swig = require('./' + env + '/public/vendor/swig/lib/swig'),
    app = express(),
    routeBase = require('./' + env + '/routes/base'),
    routeIndex = require('./' + env + '/routes/index'),
    routeGantt = require('./' + env + '/routes/gantt'),
    routeScript = require('./' + env + '/routes/script')

var base_mw = require('./' + env + '/middlewares/base_middleware')

//engine
app.engine('html', swig.renderFile)
app.set('view engine', 'html')
app.set('views', path.join(__dirname, env, 'views'))

//custom swig filter
swig.setFilter('paramFilter', function (input, arg) {
    console.log(input)
    var filterItems = input.filter(x => x.Name == arg)
    console.log(filterItems)
    return filterItems
})

//custom variable
app.set('script_dir', path.join(__dirname, 'Cmdlets/scripts'))
app.set('root', path.join(__dirname))
app.set('env', env)
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
app.use(express.static(path.join(__dirname, env, 'public')));

//error handler
app.use(base_mw.log_error)
app.use(base_mw.client_error_handler)
app.use(base_mw.error_handler)

app.listen(port, function () {
    console.log("Server is running on port " + port + " of enviroment " + env + "...")
    console.log('please navigate http://127.0.0.1:' + port + " to view...")
})

open('http://127.0.0.1:' + port)