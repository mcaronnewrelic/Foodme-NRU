var PORT = process.env.PORT || 3000;
var STATIC_DIR = __dirname + '/../angular-app/src/app';
var TEST_DIR = __dirname + '/../test';
var DATA_FILE = __dirname + '/data/restaurants.json';
// Only require newrelic if it's enabled
if (process.env.NEW_RELIC_ENABLED === 'true') {
    var newrelic = require('newrelic');
}
require('./index').start(PORT, STATIC_DIR, DATA_FILE, TEST_DIR);
