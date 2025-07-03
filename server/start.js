var PORT = process.env.PORT || 3000;
var STATIC_DIR = __dirname + '/../angular-app/src/app';
var TEST_DIR = __dirname + '/../test';
var DATA_FILE = __dirname + '/data/restaurants.json';
var newrelic = require('newrelic');

require('./index').start(PORT, STATIC_DIR, DATA_FILE, TEST_DIR);
