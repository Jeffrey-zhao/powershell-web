var express = require('express'),
    path = require('path'),
    util = require('./util'),
    port = 3000,
    open = require('open'),
    run_env=util.run_env(),
    platform_cmd=util.platform_cmd(),
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

//custom variable
app.set('script_dir', path.join(__dirname, 'Cmdlets/scripts'))
app.set('env',env)
app.set('cmd',platform_cmd)

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