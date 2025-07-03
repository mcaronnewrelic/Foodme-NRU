// Disable New Relic for local development
var newrelic = require('newrelic');
/*var newrelic = {
  getBrowserTimingHeader: () => '',
  addCustomAttributes: () => {},
  incrementMetric: () => {},
  recordMetric: () => {},
  recordCustomEvent: () => {}
};
*/

const logger = require('pino')();

const express = require('express');
var morgan = require('morgan');
var bodyParser = require('body-parser');
const { engine } = require('express-handlebars');
const path = require('path');

var fs = require('fs');
var open = require('open');

var RestaurantRecord = require('./model').Restaurant;
var MemoryStorage = require('./storage').Memory;

var API_URL = '/api/restaurant';
var API_URL_ID = API_URL + '/:id';
var API_URL_ORDER = '/api/order';

var removeMenuItems = function(restaurant) {
  var clone = {};

  Object.getOwnPropertyNames(restaurant).forEach(function(key) {
    if (key !== 'menuItems') {
      clone[key] = restaurant[key];
    }
  });

  return clone;
};


exports.start = function(PORT, STATIC_DIR, DATA_FILE, TEST_DIR) {
  var app = express();
  var storage = new MemoryStorage();
  
  // Flag to track if this is the first request
  let isFirstRequest = true;

  // log requests
  app.use(morgan('combined'));
  app.locals.newrelic = newrelic;
  
  // Serve Angular app static files (excluding index.html)
  // Determine Angular dist directory based on environment
  // In dev: server runs from /server/, Angular build is in /dist/browser/
  // In prod: server runs from /dist/server/, Angular build is in /dist/browser/
  const isProduction = process.env.NODE_ENV === 'production';
  const ANGULAR_DIST_DIR = isProduction 
    ? path.join(__dirname, '../browser')     // Production: /dist/server/ -> /dist/browser/
    : path.join(__dirname, '../dist/browser'); // Development: /server/ -> /dist/browser/
  
  console.log('Environment:', isProduction ? 'production' : 'development');
  console.log('Angular dist directory:', ANGULAR_DIST_DIR);
  
  app.use((req, res, next) => {
    // Block direct access to index.html - let the catch-all handler serve it with New Relic
    if (req.path === '/index.html' || req.path === '/') {
      return next();
    }
    express.static(ANGULAR_DIST_DIR)(req, res, next);
  });
  
  // Serve the original static files as fallback (if needed)
  app.use('/legacy', express.static(STATIC_DIR));

  // create application/json parser
  var jsonParser = bodyParser.json()

  // Global error handling middleware 
  app.use((err, req, res, next) => {
      console.error('Caught error:', err.stack);
      res.status(err.statusCode || 500).json({
          status: 'error',
          message: err.message || 'Something went wrong!',
      });
  });

  // Handle unhandled promise rejections and uncaught exceptions
  process.on('unhandledRejection', (reason, promise) => {
      console.error('Unhandled Rejection at:', promise, 'reason:', reason);
      // You might want to log this to your APM and then gracefully shut down
      // process.exit(1); // Consider exiting for critical unhandled rejections in production
  });

  process.on('uncaughtException', (err) => {
      console.error('Uncaught Exception:', err);
      // You might want to log this to your APM and then gracefully shut down
      // process.exit(1); // It's generally recommended to exit for uncaught exceptions
  });

  // Simulate an synchronous error
  app.get('/simulate/error/sync', (req, res, next) => {
      throw new Error('This is a synchronous internal server error!');
  });

  // Simulate an asynchronous error
  app.get('/simulate/error/async-unhandled', async (req, res, next) => {
      // Simulate an async operation that fails
      await new Promise((resolve, reject) => {
          setTimeout(() => {
              reject(new Error('This is an unhandled promise rejection from an async operation!'));
          }, 100);
      });
      res.send('This should not be reached.'); // This line will not be executed
  });

  //Simulate high CPU usage
  app.get('/simulate/cpu-hog', (req, res) => {
      console.time('cpu-intensive-task');
      let i = 0;
      while (i < 500000000) { // Adjust this value based on your system and desired load
          i++;
      }
      console.timeEnd('cpu-intensive-task');
      res.send(`CPU hog completed. Counted to ${i}.`);
  });

  const leakyArray = [];
  // Simulate memory leak
  app.get('/simulate/memory-leak', (req, res) => {
      // Continuously add large objects to the array
      for (let i = 0; i < 10000; i++) {
          leakyArray.push({
              id: Math.random(),
              data: Buffer.alloc(1024 * 10, 'a').toString('base64') // 10KB string
          });
      }
      const currentMemory = process.memoryUsage().heapUsed / (1024 * 1024);
      res.send(`Memory increased. Current heap usage: ${currentMemory.toFixed(2)} MB. Array size: ${leakyArray.length}`);
  });

  // Optional: Route to clear the leaky array
  app.get('/simulate/memory-leak/clear', (req, res) => {
      leakyArray.length = 0; // Clears the array, allowing garbage collection
      res.send('Leaky array cleared. Memory should stabilize.');
  });

  // Simulate slow response
  app.get('/simulate/slow-response', (req, res) => {
      const delay = parseInt(req.query.delay) || 5000; // Default to 5 seconds
      console.log(`Simulating a ${delay}ms delay...`);
      setTimeout(() => {
          res.send(`Response after ${delay}ms delay.`);
      }, delay);
  });

  const axios = require('axios'); // npm install axios
  // Simulate external API timeout
  app.get('/simulate/external-api-timeout', async (req, res, next) => {
      const externalApiUrl = 'http://localhost:3000/simulate/slow-response?delay=10000'; // Target our own slow endpoint
      const timeoutMs = 2000; // Set a 2-second timeout

      try {
          const response = await axios.get(externalApiUrl, { timeout: timeoutMs });
          res.json({ message: 'External API call succeeded (unexpectedly if timeout was hit)', data: response.data });
      } catch (error) {
          if (error.code === 'ECONNABORTED' || error.message.includes('timeout')) {
              console.error('External API call timed out:', error.message);
              res.status(504).json({
                  status: 'error',
                  message: `External API call timed out after ${timeoutMs}ms.`,
                  details: error.message
              });
          } else {
              console.error('Error calling external API:', error.message);
              next(error); // Pass other errors to the general error handler
          }
      }
  });
  // Simulate uncaught exception
  app.get('/simulate/uncaught-exception', (req, res) => {
      // This will throw an error that is not within a try/catch block
      // or a promise chain, and Express might not catch it directly.
      // It will be caught by the global process.on('uncaughtException') handler.
      setTimeout(() => {
          nonExistentFunction(); // This will cause an uncaught exception
      }, 100);
      res.send('Attempting to trigger an uncaught exception...');
  });

  /*
  Hit the Simulation Endpoints: Use curl or a web browser to access the simulation routes:
  http://localhost:3000/simulate/error/sync
  http://localhost:3000/simulate/error/async-unhandled
  http://localhost:3000/simulate/cpu-hog (hit this multiple times rapidly)
  http://localhost:3000/simulate/memory-leak (hit this repeatedly and observe memory usage in your APM or a tool like top/htop or Task Manager)
  http://localhost:3000/simulate/slow-response?delay=7000
  http://localhost:3000/simulate/external-api-timeout
  http://localhost:3000/simulate/uncaught-exception
  */
  // API
  app.get(API_URL, function(req, res, next) {
    res.status(200).send(storage.getAll().map(removeMenuItems));
  });


  app.post(API_URL, function(req, res, next) {
    var restaurant = new RestaurantRecord(req.body);
    var errors = [];

    if (restaurant.validate(errors)) {
      storage.add(restaurant);
      return res.send(201, restaurant);
    }

    return res.status(400).send({ error: errors });
  });

  app.post(API_URL_ORDER, jsonParser, function(req, res, next) {  
    logger.info(req.body, 'checkout');
    
    var order = req.body;
    var itemCount = 0;
    var orderTotal = 0;
    order.items.forEach(function(item) { 
      itemCount += item.qty;
      orderTotal += item.price * item.qty;
    });

    newrelic.addCustomAttributes({
      'customer': order.deliverTo.name,
      'restaurant': order.restaurant.name,
      'itemCount': itemCount,
      'orderTotal': orderTotal
    });
    
    newrelic.incrementMetric("Orders/count",4);
    newrelic.recordMetric('Orders/total', parseInt(orderTotal));

    newrelic.recordCustomEvent('Order', {
      customer: order.deliverTo.name,
      restaurant: order.restaurant.name,
      itemCount: itemCount,
      orderTotal: orderTotal
    });

    return res.status(201).send({ orderId: Date.now() });
  });


  app.get(API_URL_ID, function(req, res, next) {
    var restaurant = storage.getById(req.params.id);
    if (restaurant) {
      return res.status(200).send(restaurant);
    }
    return res.status(400).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
  });


  app.put(API_URL_ID, function(req, res, next) {
    var restaurant = storage.getById(req.params.id);
    var errors = [];

    if (restaurant) {
      restaurant.update(req.body);
      return res.status(200).send(restaurant);
    }

    restaurant = new RestaurantRecord(req.body);
    if (restaurant.validate(errors)) {
      storage.add(restaurant);
      return res.send(201, restaurant);
    }

    return res.send(400, { error: errors });
  });


  app.delete(API_URL_ID, function(req, res, next) {
    if (storage.deleteById(req.params.id)) {
      return res.send(204, null);
    }

    return res.send(400, { error: 'No restaurant with id "' + req.params.id + '"!' });
  });

  // Helper function to inject New Relic into HTML
  function injectNewRelicIntoHtml(htmlContent, newRelicHeader) {
    // Debug: Log the New Relic header to see what we're getting
    console.log('New Relic Header length:', newRelicHeader ? newRelicHeader.length : 0);
    
    // If New Relic header is empty, skip injection
    if (!newRelicHeader || newRelicHeader.trim() === '') {
      console.warn('New Relic header is empty - skipping injection');
      return htmlContent;
    }
    
    // Inject New Relic header after the <head> tag
    return htmlContent.replace(
      '<head>',
      `<head>\n  <!-- New Relic Browser Timing Header -->\n  ${newRelicHeader}`
    );
  }

  // Catch-all handler for Angular routing - serve index.html for non-API routes
  app.use(function(req, res, next) {
    // Skip if it's an API route
    if (req.path.startsWith('/api/') || req.path.startsWith('/simulate/')) {
      return next();
    }
    
    // Read Angular's built index.html and inject New Relic
    const indexPath = isProduction 
      ? path.join(__dirname, '../browser/index.html')     // Production: /dist/server/ -> /dist/browser/index.html
      : path.join(__dirname, '../dist/browser/index.html'); // Development: /server/ -> /dist/browser/index.html
    
    fs.readFile(indexPath, 'utf8', async function(err, htmlContent) {
      if (err) {
        console.error('Error reading index.html:', err);
        return res.status(500).send('Error loading application');
      }
      
      // Get New Relic browser timing header
      let newRelicHeader = '';
      try {
        
        // There is a race condition where the first request might not have New Relic initialized yet.
        // We can handle this by checking if it's the first request and applying a delay.
        if (isFirstRequest) {
          const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
          console.log('First request detected - applying startup delay...');
          await sleep(3000); // Sleep for 3 seconds
          isFirstRequest = false; // Mark that we've handled the first request
          console.log('Startup delay completed');
        }

        newRelicHeader = newrelic.getBrowserTimingHeader();
        console.log('New Relic agent state:', {
          hasLicenseKey: !!process.env.NEW_RELIC_LICENSE_KEY,
          agentVersion: newrelic.version || 'unknown',
          headerLength: newRelicHeader ? newRelicHeader.length : 0
        });
        
      } catch (error) {
        console.error('Error getting New Relic browser timing header:', error);
      }
      
      const modifiedHtml = injectNewRelicIntoHtml(htmlContent, newRelicHeader);
      res.setHeader('Content-Type', 'text/html');
      res.send(modifiedHtml);
    });
  });

  // start the server
  // read the data from json and start the server
  fs.readFile(DATA_FILE, function(err, data) {
    JSON.parse(data).forEach(function(restaurant) {
      storage.add(new RestaurantRecord(restaurant));
    });

    app.listen(PORT, function() {
      open('http://localhost:' + PORT + '/');
      logger.info('Node Server started on http://localhost:' + PORT + '/');
    });
  });

};
