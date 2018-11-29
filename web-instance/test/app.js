var express = require('express');
var app = express();

var requestTime = function (req, res, next) {
  req.requestTime = Date.now();
  next();
};

app.use(requestTime);

app.get('/', function (req, res) {
  var responseText = 'Hello World!';
  responseText += 'Requested at: ' + req.requestTime + '';
  res.send(responseText);
});

app.param(function (param, validator) {
  return function (req, res, next, value) {
    if (validator(value)) {
      if (!req.script) {
        req.script = {}
      }
      next()
    } else {
      res.sendStatus(403);
    }
  }
})

app.param(['id', 'page'], function (data) {
  console.log('CALLED ONLY ONCE with', data);
  return true
});

app.get('/user/:id', function (req, res, next) {
  console.log('although this matches 1');
  next()
});

app.get('/user/:id/:page', function (req, res, next) {
  console.log('although this matches 2');
  next()
});

app.get('/user/:id/:page/test', function (req, res) {
  console.log('and this matches test 3');
  res.end();
});

app.listen(3000);