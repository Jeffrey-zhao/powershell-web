function server_listen(app, port, env) {

    app.listen(port, function () {
        console.log("Server is running on port " + port + " of enviroment " + env + "...")
        console.log('please navigate http://127.0.0.1:' + port + " to view...")
    })
}

module.exports = {
    server_listen: server_listen
};