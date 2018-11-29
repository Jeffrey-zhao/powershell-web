var express = require('express'),
    path = require('path'),
run_env = require('./env').env,
    env

if (run_env === 'production') {
    env = 'dist'
} else {
    env = 'build'
}

var swig = require('./' + env + '/vendor/swig/lib/swig'),
    http = require('http'),
    app = express(),
    routeBase = require('./' + env + '/routes/base'),
    routeIndex = require('./' + env + '/routes/index'),
    routeGantt = require('./' + env + '/routes/gantt'),
    routeScript = require('./' + env + '/routes/script')

    console.log(env)
app.engine('html', swig.renderFile)
app.set('view engine', 'html')
app.set('views', path.join(__dirname, env, 'views'))

//route
app.use(routeBase) 
app.use(routeIndex) 
app.use(routeGantt) 
app.use(routeScript)

app.listen(3000, function () {
    console.log('ready')
})