
 function server(port,env) {
    var express = require('express')
    var bodyParser = require('body-parser')
    var path = require('path')
    var port = port
    var app = express()

    app.use(express.static(path.join(__dirname, env)))
    app.use(bodyParser.urlencoded({
        extended: true
    }))

    app.listen(port, function () {
        console.log("Server is running on port " + port + "...")
        console.log('please navigate http://127.0.0.1:' + port + " to view...")
    })
}

module.exports={
    server:server
};