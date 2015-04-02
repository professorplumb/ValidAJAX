var express = require('express');
var router = express.Router();

var validators = {
    name: function (val) {
        if (!val) throw "can't be blank";
    },
    state: function (val) {
        if (['ca', 'hi', 'or', 'tx'].indexOf(val.toLowerCase()) == -1)
            throw "must be one of CA, HI, OR, or TX";
        return {
            ca: "California",
            hi: "Hawai'i",
            or: "Oregon",
            tx: "Texas"
        }[val.toLowerCase()];
    },
    status: function (val) {
        if (!val) throw "can't be blank";
        if (val === 'both') throw "that makes no sense!"
    },
    interests: function (val) {
        var numRequired = 2;
        if (val.split(',').length < numRequired)
            throw 'must select at least ' + numRequired + ' interests'
    },
    description: function (val) {
        var minLength = 5;
        if (val.trim().split(' ').length < minLength)
            throw 'must be at least ' + minLength + ' words long';
    }
};

for (var endpoint in validators) {
    if (!validators.hasOwnProperty(endpoint)) continue;
    router.get(
        '/forms/demoform/' + endpoint,
        function (ep) {
            return function (req, res, next) {
                var payload = {
                    success: true
                };
                var result;
                try {
                    result = validators[ep](req.query.val);
                    if (result)
                        payload.message = result;
                } catch (e) {
                    payload.success = false;
                    payload.message = e;
                } finally {
                    res.json(payload);
                }
            }
        }(endpoint));
}

module.exports = router;
