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
const DatabaseService = require('./database');

var API_URL = '/api/restaurant';
var API_URL_ID = '/api/restaurant/:id';
var API_URL_ORDER = '/api/order';

// Global variables for data access
let storage = null;
let dbService = null;
let useDatabase = false;

var removeMenuItems = function(restaurant) {
  var clone = {};

  Object.getOwnPropertyNames(restaurant).forEach(function(key) {
    if (key !== 'menuItems') {
      clone[key] = restaurant[key];
    }
  });

  // Add image URL based on restaurant original ID
  if (restaurant.original_id) {
    clone.image = `/assets/img/restaurants/${restaurant.original_id}.jpg`;
  } else if (restaurant.id) {
    // Fallback to regular id for non-database sources
    clone.image = `/assets/img/restaurants/${restaurant.id}.jpg`;
  }

  return clone;
};


exports.start = function(PORT, STATIC_DIR, DATA_FILE, TEST_DIR) {
  var app = express();
  storage = new MemoryStorage();
  dbService = new DatabaseService();
  
  // Determine data source based on environment
  const isProduction = process.env.NODE_ENV === 'production';
  const isDockerCompose = process.env.DOCKER_COMPOSE === 'true' || process.env.DB_HOST === 'db';
  useDatabase = isProduction || isDockerCompose;
  
  console.log('Environment:', isProduction ? 'production' : 'development');
  console.log('Data source:', useDatabase ? 'PostgreSQL database' : 'JSON file');
  
  // Flag to track if this is the first request
  let isFirstRequest = true;

  // log requests
  app.use(morgan('combined'));
  app.locals.newrelic = newrelic;
  
  // Serve Angular app static files (excluding index.html)
  // Determine Angular dist directory based on environment
  // In dev: server runs from /server/, Angular build is in /dist/browser/
  // In prod: server runs from /dist/server/, Angular build is in /dist/browser/
  // In Docker: server runs from /foodme/app/server/, Angular build is in /foodme/app/browser/
  const isDocker = process.env.DOCKER_COMPOSE === 'true' || process.cwd() === '/foodme';
  let ANGULAR_DIST_DIR;
  ANGULAR_DIST_DIR = path.join(__dirname, '../browser'); // Docker: /foodme/app/server/ -> /foodme/app/browser/
  console.log('Directory exists:', fs.existsSync(ANGULAR_DIST_DIR));
  
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

  // Health check endpoint
  app.get('/health', async function(req, res) {
    try {
      const healthStatus = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        pid: process.pid,
        version: process.version,
        environment: process.env.NODE_ENV || 'development',
        dataSource: useDatabase ? 'PostgreSQL' : 'JSON file'
      };

      // Test database connection if using database
      if (useDatabase && dbService) {
        try {
          const isDbHealthy = await dbService.isAvailable();
          healthStatus.database = {
            status: isDbHealthy ? 'connected' : 'disconnected',
            type: 'PostgreSQL'
          };
          
          if (!isDbHealthy) {
            healthStatus.status = 'degraded';
          }
        } catch (dbError) {
          healthStatus.database = {
            status: 'error',
            error: dbError.message,
            type: 'PostgreSQL'
          };
          healthStatus.status = 'degraded';
        }
      } else {
        healthStatus.database = {
          status: 'not_applicable',
          type: 'JSON file'
        };
      }

      // Test data availability
      try {
        let restaurantCount = 0;
        if (useDatabase) {
          // Quick count query to test database
          const restaurants = await dbService.getAllRestaurants();
          restaurantCount = restaurants.length;
        } else {
          restaurantCount = storage.getAll().length;
        }
        
        healthStatus.data = {
          restaurants_loaded: restaurantCount,
          status: restaurantCount > 0 ? 'available' : 'empty'
        };
        
        if (restaurantCount === 0) {
          healthStatus.status = 'degraded';
        }
      } catch (dataError) {
        healthStatus.data = {
          status: 'error',
          error: dataError.message
        };
        healthStatus.status = 'unhealthy';
      }

      // Set appropriate HTTP status code based on health
      const statusCode = healthStatus.status === 'healthy' ? 200 : 
                        healthStatus.status === 'degraded' ? 200 : 503;
      
      res.status(statusCode).json(healthStatus);
    } catch (error) {
      console.error('Health check error:', error);
      res.status(503).json({
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error.message,
        uptime: process.uptime(),
        pid: process.pid
      });
    }
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
  app.get(API_URL, async function(req, res, next) {
    try {
      if (useDatabase) {
        const restaurants = await dbService.getAllRestaurants();
        res.status(200).send(restaurants.map(removeMenuItems));
      } else {
        res.status(200).send(storage.getAll().map(removeMenuItems));
      }
    } catch (error) {
      console.error('Error fetching restaurants:', error);
      res.status(500).send({ error: 'Failed to fetch restaurants' });
    }
  });


  app.post(API_URL, async function(req, res, next) {
    try {
      if (useDatabase) {
        const restaurant = await dbService.addRestaurant(req.body);
        return res.status(201).send(restaurant);
      } else {
        var restaurant = new RestaurantRecord(req.body);
        var errors = [];

        if (restaurant.validate(errors)) {
          storage.add(restaurant);
          return res.status(201).send(restaurant);
        }

        return res.status(400).send({ error: errors });
      }
    } catch (error) {
      console.error('Error adding restaurant:', error);
      res.status(500).send({ error: 'Failed to add restaurant' });
    }
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


  app.get(API_URL_ID, async function(req, res, next) {
    try {
      if (useDatabase) {
        const restaurant = await dbService.getRestaurantById(req.params.id);
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      } else {
        var restaurant = storage.getById(req.params.id);
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      }
    } catch (error) {
      console.error('Error fetching restaurant by ID:', error);
      res.status(500).send({ error: 'Failed to fetch restaurant' });
    }
  });


  app.put(API_URL_ID, async function(req, res, next) {
    try {
      if (useDatabase) {
        const restaurant = await dbService.updateRestaurant(req.params.id, req.body);
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      } else {
        var restaurant = storage.getById(req.params.id);
        var errors = [];

        if (restaurant) {
          restaurant.update(req.body);
          return res.status(200).send(restaurant);
        }

        restaurant = new RestaurantRecord(req.body);
        if (restaurant.validate(errors)) {
          storage.add(restaurant);
          return res.status(201).send(restaurant);
        }

        return res.status(400).send({ error: errors });
      }
    } catch (error) {
      console.error('Error updating restaurant:', error);
      res.status(500).send({ error: 'Failed to update restaurant' });
    }
  });


  app.delete(API_URL_ID, async function(req, res, next) {
    try {
      if (useDatabase) {
        const success = await dbService.deleteRestaurant(req.params.id);
        if (success) {
          return res.status(204).send(null);
        }
        return res.status(404).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      } else {
        if (storage.deleteById(req.params.id)) {
          return res.status(204).send(null);
        }
        return res.status(404).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      }
    } catch (error) {
      console.error('Error deleting restaurant:', error);
      res.status(500).send({ error: 'Failed to delete restaurant' });
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
    // Use the same logic as ANGULAR_DIST_DIR to determine the correct path
    let indexPath;
    indexPath = path.join(__dirname, '../browser/index.html'); // Docker: /foodme/app/server/ -> /foodme/app/browser/index.html   
    // console.log('Index.html exists:', fs.existsSync(indexPath));
    
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

  // Start the server
  async function startServer() {
    try {
      if (useDatabase) {
        console.log('🔍 Checking database availability...');
        const dbAvailable = await dbService.isAvailable();
        if (!dbAvailable) {
          console.log('⚠️  Database not available, falling back to JSON file');
          useDatabase = false;
        } else {
          console.log('✅ Database is available and ready');
        }
      }

      if (!useDatabase) {
        console.log('📁 Loading data from JSON file:', DATA_FILE);
        fs.readFile(DATA_FILE, function(err, data) {
          if (err) {
            console.error('❌ Error reading JSON file:', err);
            process.exit(1);
          }
          
          JSON.parse(data).forEach(function(restaurant) {
            storage.add(new RestaurantRecord(restaurant));
          });
          
          console.log('✅ Loaded', storage.getAll().length, 'restaurants from JSON file');
          startHttpServer();
        });
      } else {
        console.log('✅ Using database for restaurant data');
        startHttpServer();
      }
    } catch (error) {
      console.error('❌ Error starting server:', error);
      process.exit(1);
    }
  }

  function startHttpServer() {
    app.listen(PORT, function() {
      console.log('🚀 FoodMe server started successfully!');
      console.log('📍 URL: http://localhost:' + PORT + '/');
      console.log('📊 Data source:', useDatabase ? 'PostgreSQL Database' : 'JSON File');
      
      // Only open browser in development mode
      if (!useDatabase) {
        open('http://localhost:' + PORT + '/');
      }
      
      logger.info('Node Server started on http://localhost:' + PORT + '/');
    });
  }

  // Handle graceful shutdown
  process.on('SIGTERM', async () => {
    console.log('🛑 Received SIGTERM, shutting down gracefully...');
    if (dbService) {
      await dbService.close();
    }
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    console.log('🛑 Received SIGINT, shutting down gracefully...');
    if (dbService) {
      await dbService.close();
    }
    process.exit(0);
  });

  // Start the application
  startServer();
};
