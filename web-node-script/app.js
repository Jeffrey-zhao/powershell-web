var express = require('express');
var app = express();
var fs = require("fs");
var bodyParser = require('body-parser');
var execute = require('./utils/execute')
var psRunner = require('./utils/psRunner')
//view 
app.set('view engine', 'html');
app.set('views', __dirname + '/views');

//middlemare
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({
  extended: true
}))
app.use(express.static(__dirname + '/public'));

//route
app.get('/script', function (req, res) {
  res.render('index')
})

app.post('/script', function (req, res) {
  //var cmdString=`{"cmd":"powershell.exe","file":"./scripts/test.ps1","command":"Write-Args -arg1 'zhao'"}`
  console.log(JSON.stringify(req.body))
  var cmdString = JSON.stringify(req.body)
  execute(cmdString, function (data) {
    res.send(data)
  })
})

var server = app.listen(8081, function () {

  var host = server.address().address
  var port = server.address().port

  console.log("please visit http://%s:%s", host, port)

})