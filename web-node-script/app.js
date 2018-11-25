var express = require('express');
var app = express();
var fs = require("fs");

//get 
app.get('/', function (req, res) {

})

var server = app.listen(8081, function () {

  var host = server.address().address
  var port = server.address().port

  console.log("please visit http://%s:%s", host, port)

})
