var express = require('express');
var app = express();
var router=express.Router();

var requestTime = function (req, res, next) {
  req.requestTime = Date.now();
  next();
};

app.use(requestTime);

router.get('/', function (req, res) {
  var responseText = 'Hello World!';
  responseText += 'Requested at: ' + req.requestTime + '';
  res.send(responseText);
});

router.param(function (param, validator) {
  return function (req, res, next, value) {
    if (validator(value)) {
      if (!req.script) {
        req.script = {}
      }
      req.script[param]=value
      next()
    } else {
      res.sendStatus(403);
    }
  }
})

router.param('id', function (data) {
  console.log('CALLED ONLY ONCE with id', data);
  return true
});
router.param('page', function (data) {
  console.log('CALLED ONLY ONCE with page', data);
  return true
});
router.get('/user/:id', function (req, res, next) {
  console.log('although this matches 1');
  next()
});

router.get('/user/:id/:page', function (req, res, next) {
  console.log('although this matches 2');
  console.log(JSON.stringify(req.script))
  next()
});

router.get('/user/:id/:page/test', function (req, res) {
  console.log('and this matches test 3');
  res.end();
});

app.use(router)
app.listen(3000);