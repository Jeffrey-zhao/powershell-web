var express = require('express'),
    path = require('path'),
    run_env = require('./util').run_env(),
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

var base_mw=require('./'+env+'/middlewares/base_middleware')

//engine
app.engine('html', swig.renderFile)
app.set('view engine', 'html')
app.set('views', path.join(__dirname, env, 'views'))

//custom variable
app.set('script_dir',path.join(__dirname,'Cmdlets/scripts'))

//route
app.use(routeBase)
app.use(routeIndex)
app.use(routeGantt)
app.use(routeScript)

//staic file
app.use(express.static(path.join(__dirname, env, 'public/')));
console.log(path.join(__dirname, env, 'public/'))
//error handler
app.use(base_mw.log_error)
app.use(base_mw.client_error_handler)
app.use(base_mw.error_handler)

var server=app.listen(3000, function () {
    console.log('env: '+ env)
    console.log('Server is Ready...')
})
