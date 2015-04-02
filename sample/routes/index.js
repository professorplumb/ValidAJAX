var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) {
  res.render('index');
});

router.post('/done', function (req, res, next) {
  res.render('done', req.body)
});

module.exports = router;
