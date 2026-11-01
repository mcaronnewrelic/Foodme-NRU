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
var open = require('open').default; // open 11 is an ES module

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

// Which demo failure scenario is armed (env > manual override > weekly
// rotation). See demo-failures.js.
const DemoFailures = require('./demo-failures');
const demoFailures = new DemoFailures(logger);

// Utility function to generate consistent user IDs for New Relic tracking
function generateUserID(customerData) {
  if (!customerData) return null;
  
  // Prefer email as the primary identifier
  if (customerData.email) {
    return `user_${customerData.email.toLowerCase().replace(/[^a-z0-9]/g, '_')}`;
  }
  
  // Fallback to phone if available
  if (customerData.phone) {
    return `user_phone_${customerData.phone.replace(/[^0-9]/g, '')}`;
  }
  
  // Fallback to name if available
  if (customerData.name) {
    return `user_name_${customerData.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}`;
  }
  
  return null;
}

// Utility function to set New Relic user ID if user data is available
function setNewRelicUserID(customerData, context = '') {
  const userID = generateUserID(customerData);
  if (userID) {
    try {
      newrelic.setUserID(userID);
      logger.debug({ userID, context }, 'New Relic user ID set');
      return userID;
    } catch (error) {
      logger.warn({ err: error, context }, 'Failed to set New Relic user ID');
    }
  }
  return null;
}

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
  
  logger.info({
    environment: isProduction ? 'production' : 'development',
    dataSource: useDatabase ? 'PostgreSQL database' : 'JSON file'
  }, 'Server configuration initialized');
  
  // Flag to track if this is the first request
  let isFirstRequest = true;

  // log requests
  app.use(morgan('combined'));
  app.locals.newrelic = newrelic;
  
  // Serve Angular app static files (excluding index.html)
  // The Angular build lands in a different place per layout, so use whichever exists:
  // ../browser      production image: /foodme/app/server/ -> /foodme/app/browser/
  // ../dist/browser local dev, local Docker mount, and EC2 (/opt/foodme/backend -> /opt/foodme/dist/browser)
  const isDocker = process.env.DOCKER_COMPOSE === 'true' || process.cwd() === '/foodme';
  const ANGULAR_DIST_CANDIDATES = [
    path.join(__dirname, '../browser'),
    path.join(__dirname, '../dist/browser')
  ];
  const ANGULAR_DIST_DIR = ANGULAR_DIST_CANDIDATES.find(dir => fs.existsSync(dir)) || ANGULAR_DIST_CANDIDATES[0];
  logger.info({
    angularDir: ANGULAR_DIST_DIR,
    directoryExists: fs.existsSync(ANGULAR_DIST_DIR)
  }, 'Angular static files configuration');
  
  // Request tracing middleware - add unique request ID and logging
  app.use((req, res, next) => {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const startTime = Date.now();
    
    // Add request ID to request object for use in other middleware/routes
    req.requestId = requestId;
    
    // Set request ID header for tracing
    res.setHeader('X-Request-ID', requestId);
    
    // Log incoming request
    logger.info({
      requestId,
      method: req.method,
      url: req.url,
      userAgent: req.get('User-Agent'),
      ip: req.ip || req.connection.remoteAddress,
      headers: {
        contentType: req.get('Content-Type'),
        contentLength: req.get('Content-Length'),
        authorization: req.get('Authorization') ? '[REDACTED]' : undefined
      }
    }, 'Incoming request');
    
    // Override res.end to log response
    const originalEnd = res.end;
    res.end = function(chunk, encoding) {
      const duration = Date.now() - startTime;
      
      logger.info({
        requestId,
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        duration,
        contentLength: res.get('Content-Length')
      }, 'Request completed');
      
      originalEnd.call(this, chunk, encoding);
    };
    
    next();
  });

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

  // Handle unhandled promise rejections and uncaught exceptions
  process.on('unhandledRejection', (reason, promise) => {
      logger.error({ promise, reason }, 'Unhandled promise rejection detected');
      // You might want to log this to your APM and then gracefully shut down
      // process.exit(1); // Consider exiting for critical unhandled rejections in production
  });

  process.on('uncaughtException', (err) => {
      logger.fatal({ err }, 'Uncaught exception detected - server will exit');
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
  // CPU simulation with performance monitoring
  app.get('/simulate/cpu-hog', (req, res) => {
      const startTime = Date.now();
      const iterations = parseInt(req.query.iterations) || 100000000;
      
      logger.info({
          requestId: req.requestId,
          endpoint: '/simulate/cpu-hog',
          iterations
      }, 'Starting CPU intensive simulation');
      
      const cpuStartTime = process.cpuUsage();
      const startTime2 = Date.now();
      
      for (let i = 0; i < iterations; i++) {
          Math.sqrt(i);
      }
      
      const cpuEndTime = process.cpuUsage(cpuStartTime);
      const duration = Date.now() - startTime2;
      const totalDuration = Date.now() - startTime;
      
      const performanceData = {
          requestId: req.requestId,
          iterations,
          duration,
          totalDuration,
          cpuUsage: {
              user: cpuEndTime.user / 1000, // Convert to milliseconds
              system: cpuEndTime.system / 1000
          },
          memoryUsage: process.memoryUsage()
      };
      
      logger.info(performanceData, 'CPU intensive simulation completed');
      
      res.json({
          message: `CPU simulation completed`,
          performance: performanceData
      });
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
              logger.error({ error: error.message, timeout: 5000 }, 'External API call timed out');
              res.status(504).json({
                  status: 'error',
                  message: `External API call timed out after ${timeoutMs}ms.`,
                  details: error.message
              });
          } else {
              logger.error({ error: error.message }, 'Error calling external API');
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

  // Lets the Angular "Behind the scenes" callouts build New Relic links for the current account
  app.get('/api/nr-config', (req, res) => {
    const scenario = demoFailures.getState();
    res.json({
      accountId: process.env.NEW_RELIC_ACCOUNT_ID || null,
      browserEntityGuid: process.env.NEW_RELIC_BROWSER_ENTITY_GUID || null,
      // Shown in the site's behind-the-scenes content so learners are not
      // guessing which target fails; the checks still have to find the
      // failure in the data. Null when nothing is armed.
      armedScenario: scenario.armed
        ? { ...scenario.armed, source: scenario.source }
        : null
    });
  });

  // Demo failure scenarios: read the current state, arm one manually, or
  // clear the manual override (back to env / weekly rotation). Deliberately
  // unauthenticated — a teaching demo; changes are logged. See
  // demo-failures.js for the priority rules.
  app.get('/api/demo/failures', (req, res) => {
    res.json(demoFailures.getState());
  });

  app.post('/api/demo/failures', jsonParser, (req, res) => {
    const { kind, target } = req.body || {};
    if (kind === 'off') {
      const state = demoFailures.setManual('off');
      logger.info({ ip: req.ip }, 'Demo failure scenario disarmed by manual override');
      return res.json(state);
    }
    if (!['restaurant', 'order-restaurant', 'order-item'].includes(kind) || !target) {
      return res.status(400).json({
        error: 'Body must be {kind: "restaurant" | "order-restaurant" | "order-item", target: "<name or slug>"}, or {kind: "off"}'
      });
    }
    const state = demoFailures.setManual(kind, String(target));
    logger.info({ kind, target: state.armed?.target, ip: req.ip }, 'Demo failure scenario armed by manual override');
    return res.json(state);
  });

  app.delete('/api/demo/failures', (req, res) => {
    const state = demoFailures.clearManual();
    logger.info({ ip: req.ip }, 'Demo failure manual override cleared');
    res.json(state);
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

      // Set appropriate HTTP status code based on health
      const statusCode = healthStatus.status === 'healthy' ? 200 : 
                        healthStatus.status === 'degraded' ? 200 : 503;
      
      res.status(statusCode).json(healthStatus);
    } catch (error) {
      logger.error({ err: error }, 'Health check failed');
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
    const startTime = Date.now();
    logger.info({
      requestId: req.requestId,
      endpoint: 'GET /api/restaurant',
      useDatabase
    }, 'Fetching all restaurants');
    
    try {
      let restaurants;
      if (useDatabase) {
        const dbStartTime = Date.now();
        restaurants = await dbService.getAllRestaurants();
        const dbDuration = Date.now() - dbStartTime;
        
        logger.info({
          requestId: req.requestId,
          operation: 'database.getAllRestaurants',
          duration: dbDuration,
          resultCount: restaurants.length
        }, 'Database query completed');
        
        res.status(200).send(restaurants.map(removeMenuItems));
      } else {
        restaurants = storage.getAll();
        logger.info({
          requestId: req.requestId,
          operation: 'storage.getAll',
          resultCount: restaurants.length
        }, 'In-memory storage query completed');
        
        res.status(200).send(restaurants.map(removeMenuItems));
      }
      
      const totalDuration = Date.now() - startTime;
      logger.info({
        requestId: req.requestId,
        endpoint: 'GET /api/restaurant',
        statusCode: 200,
        resultCount: restaurants.length,
        duration: totalDuration
      }, 'Successfully fetched restaurants');
      
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ 
        requestId: req.requestId,
        endpoint: 'GET /api/restaurant',
        err: error,
        duration
      }, 'Failed to fetch restaurants from API');
      res.status(500).send({ error: 'Failed to fetch restaurants' });
    }
  });


  app.post(API_URL, async function(req, res, next) {
    const startTime = Date.now();
    logger.info({
      requestId: req.requestId,
      endpoint: 'POST /api/restaurant',
      restaurantName: req.body?.name,
      hasMenuItems: !!(req.body?.menuItems && req.body.menuItems.length > 0),
      useDatabase
    }, 'Adding new restaurant');
    
    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const restaurant = await dbService.addRestaurant(req.body);
        const dbDuration = Date.now() - dbStartTime;
        
        logger.info({
          requestId: req.requestId,
          operation: 'database.addRestaurant',
          restaurantId: restaurant.id,
          duration: dbDuration
        }, 'Restaurant added to database');
        
        const totalDuration = Date.now() - startTime;
        logger.info({
          requestId: req.requestId,
          endpoint: 'POST /api/restaurant',
          statusCode: 201,
          restaurantId: restaurant.id,
          duration: totalDuration
        }, 'Successfully added restaurant');
        
        return res.status(201).send(restaurant);
      } else {
        var restaurant = new RestaurantRecord(req.body);
        var errors = [];

        if (restaurant.validate(errors)) {
          storage.add(restaurant);
          
          logger.info({
            requestId: req.requestId,
            operation: 'storage.add',
            restaurantId: restaurant.id
          }, 'Restaurant added to storage');
          
          const totalDuration = Date.now() - startTime;
          logger.info({
            requestId: req.requestId,
            endpoint: 'POST /api/restaurant',
            statusCode: 201,
            restaurantId: restaurant.id,
            duration: totalDuration
          }, 'Successfully added restaurant');
          
          return res.status(201).send(restaurant);
        }

        logger.warn({
          requestId: req.requestId,
          endpoint: 'POST /api/restaurant',
          errors: errors
        }, 'Restaurant validation failed');
        
        return res.status(400).send({ error: errors });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ 
        requestId: req.requestId,
        endpoint: 'POST /api/restaurant',
        err: error,
        duration
      }, 'Failed to add restaurant');
      res.status(500).send({ error: 'Failed to add restaurant' });
    }
  });

  app.post(API_URL_ORDER, jsonParser, async function(req, res, next) {  
    const startTime = Date.now();
    const order = req.body;
    
    logger.info({
      requestId: req.requestId,
      endpoint: 'POST /api/order',
      customerName: order.deliverTo?.name || order.customer?.name,
      restaurantId: order.restaurant?.id,
      restaurantName: order.restaurant?.name,
      itemCount: order.items?.length || 0
    }, 'Processing order checkout');
    
    // Log the full order for debugging (can be removed in production)
    logger.debug({ requestId: req.requestId, order }, 'Order details');
    
    try {
      var itemCount = 0;
      var orderTotal = 0;
      order.items.forEach(function(item) { 
        itemCount += item.qty;
        orderTotal += item.price * item.qty;
      });

      logger.info({
        requestId: req.requestId,
        orderMetrics: {
          totalItems: itemCount,
          totalAmount: orderTotal,
          uniqueMenuItems: order.items.length
        }
      }, 'Order metrics calculated');

      // Set New Relic user ID for transaction tracking
      const customerData = order.deliverTo || order.customer;
      const userID = setNewRelicUserID(customerData, 'order_creation');
      
      logger.info({
        requestId: req.requestId,
        userID: userID,
        customerEmail: customerData?.email,
        customerName: customerData?.name
      }, 'User ID set for order creation transaction');

      // Add New Relic monitoring
      newrelic.addCustomAttributes({
        'customer': order.deliverTo?.name || order.customer?.name || 'Unknown',
        'customerEmail': order.deliverTo?.email || order.customer?.email || 'Unknown',
        'userID': userID || 'anonymous',
        'restaurant': order.restaurant?.name || 'Unknown',
        'itemCount': itemCount,
        'orderTotal': orderTotal,
        'requestId': req.requestId
      });

      // Planned failures for the "find the failed order in New Relic" exercise; each is off unless its variable is set.
      // They run after the attributes above, so the failed transaction still says who ordered what, and before the
      // Order event and metrics below, so a failed order isn't counted as a sale.
      const { nameToSlug } = require('./url-utils');
      const failing = demoFailures.getFailing();
      const failingItem = failing.orderItem
        ? order.items.find(item => nameToSlug(item.name) === failing.orderItem)
        : undefined;
      if (failingItem) {
        newrelic.addCustomAttributes({ failedItem: failingItem.name });
        throw new Error(`Inventory check failed for "${failingItem.name}": stock count is -2`);
      }
      if (failing.orderRestaurant && nameToSlug(order.restaurant?.name || '') === failing.orderRestaurant) {
        throw new Error(`Kitchen at "${order.restaurant.name}" is not accepting orders: ticket printer offline`);
      }

      newrelic.incrementMetric("Orders/count", 1);
      newrelic.recordMetric('Orders/total', parseInt(orderTotal));

      newrelic.recordCustomEvent('Order', {
        customer: order.deliverTo?.name || order.customer?.name || 'Unknown',
        customerEmail: order.deliverTo?.email || order.customer?.email || 'Unknown',
        userID: userID || 'anonymous',
        restaurant: order.restaurant?.name || 'Unknown',
        itemCount: itemCount,
        orderTotal: orderTotal,
        requestId: req.requestId
      });

      // Actually create the order in the database if using database
      let orderId = Date.now(); // fallback for in-memory storage
      
      if (useDatabase && dbService) {
        try {
          const dbStartTime = Date.now();
          const result = await dbService.createOrder(order);
          const dbDuration = Date.now() - dbStartTime;
          
          orderId = result.orderId;
          
          logger.info({
            requestId: req.requestId,
            operation: 'database.createOrder',
            orderId: orderId,
            orderNumber: result.orderNumber,
            customerId: result.customerId,
            duration: dbDuration
          }, 'Order created successfully in database');
          
        } catch (dbError) {
          logger.error({
            requestId: req.requestId,
            operation: 'database.createOrder',
            err: dbError,
            orderData: {
              customerName: order.deliverTo?.name || order.customer?.name,
              restaurantId: order.restaurant?.id,
              itemCount,
              orderTotal
            }
          }, 'Database order creation failed');
          
          // Continue with fallback behavior for backward compatibility
          logger.info({ requestId: req.requestId }, 'Falling back to memory-based order processing');
        }
      } else {
        logger.info({
          requestId: req.requestId,
          operation: 'memory.createOrder',
          orderId
        }, 'Order processed in memory mode');
      }

      newrelic.addCustomAttributes({ orderId });

      const totalDuration = Date.now() - startTime;
      logger.info({
        requestId: req.requestId,
        endpoint: 'POST /api/order',
        statusCode: 201,
        orderId,
        duration: totalDuration,
        orderTotal
      }, 'Order processing completed successfully');

      return res.status(201).send({ orderId: orderId, requestId: req.requestId });
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({
        requestId: req.requestId,
        endpoint: 'POST /api/order',
        err: error,
        duration,
        orderData: {
          customerName: order.deliverTo?.name || order.customer?.name,
          restaurantId: order.restaurant?.id,
          itemCount: order.items?.length
        }
      }, 'Error processing order');
      return next(error);
    }
  });


  app.get(API_URL_ID, async function(req, res, next) {
    const startTime = Date.now();
    const restaurantId = req.params.id;
    
    logger.info({
      requestId: req.requestId,
      endpoint: 'GET /api/restaurant/:id',
      restaurantId,
      useDatabase
    }, 'Fetching restaurant by ID');
    
    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const restaurant = await dbService.getRestaurantById(restaurantId);
        const dbDuration = Date.now() - dbStartTime;
        
        if (restaurant) {
          logger.info({
            requestId: req.requestId,
            operation: 'database.getRestaurantById',
            restaurantId,
            restaurantName: restaurant.name,
            duration: dbDuration
          }, 'Restaurant found in database');
          
          const totalDuration = Date.now() - startTime;
          logger.info({
            requestId: req.requestId,
            endpoint: 'GET /api/restaurant/:id',
            statusCode: 200,
            restaurantId,
            duration: totalDuration
          }, 'Successfully fetched restaurant');
          
          return res.status(200).send(restaurant);
        }
        
        logger.warn({
          requestId: req.requestId,
          operation: 'database.getRestaurantById',
          restaurantId,
          duration: dbDuration
        }, 'Restaurant not found in database');
        
        return res.status(404).send({ error: 'No restaurant with id "' + restaurantId + '"!' });
      } else {
        var restaurant = storage.getById(restaurantId);
        if (restaurant) {
          logger.info({
            requestId: req.requestId,
            operation: 'storage.getById',
            restaurantId,
            restaurantName: restaurant.name
          }, 'Restaurant found in storage');
          
          const totalDuration = Date.now() - startTime;
          logger.info({
            requestId: req.requestId,
            endpoint: 'GET /api/restaurant/:id',
            statusCode: 200,
            restaurantId,
            duration: totalDuration
          }, 'Successfully fetched restaurant');
          
          return res.status(200).send(restaurant);
        }
        
        logger.warn({
          requestId: req.requestId,
          operation: 'storage.getById',
          restaurantId
        }, 'Restaurant not found in storage');
        
        return res.status(404).send({ error: 'No restaurant with id "' + restaurantId + '"!' });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ 
        requestId: req.requestId,
        endpoint: 'GET /api/restaurant/:id',
        restaurantId,
        err: error,
        duration
      }, 'Failed to fetch restaurant by ID');
      res.status(500).send({ error: 'Failed to fetch restaurant' });
    }
  });

  // New endpoint for getting restaurant by name slug
  app.get('/api/restaurant/by-name/:name', async function(req, res, next) {
    newrelic.addCustomAttributes({ restaurantSlug: req.params.name });
    try {
      // Planned failure for the "find the error in New Relic" exercise;
      // armed dynamically (env, instructor override, or weekly rotation)
      if (demoFailures.getFailing().restaurant === req.params.name) {
        throw new Error(`Menu data for "${req.params.name}" is corrupted: menu_items.category is null for 3 rows`);
      }
      if (useDatabase) {
        const restaurant = await dbService.getRestaurantByName(req.params.name);
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({ error: 'No restaurant with name "' + req.params.name + '"!' });
      } else {
        // For non-database mode, we need to search by name in storage
        const { nameToSlug } = require('./url-utils');
        const restaurant = storage.getAll().find(r => nameToSlug(r.name) === req.params.name);
        
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({ error: 'No restaurant with name "' + req.params.name + '"!' });
      }
    } catch (error) {
      logger.error({ err: error, restaurantName: req.params.name }, 'Failed to fetch restaurant by name');
      next(error);
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
      logger.error({ err: error, restaurantId: req.params.id }, 'Failed to update restaurant');
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
      logger.error({ err: error, restaurantId: req.params.id }, 'Failed to delete restaurant');
      res.status(500).send({ error: 'Failed to delete restaurant' });
    }

    return res.status(400).send({ error: 'No restaurant with id "' + req.params.id + '"!' });
  });

  // Orders API endpoints
  app.get('/api/orders/customer/:email', async function(req, res, next) {
    const startTime = Date.now();
    const customerEmail = req.params.email;
    
    // Set New Relic user ID for transaction tracking
    const userID = setNewRelicUserID({ email: customerEmail }, 'orders_by_email');
    
    logger.info({
      requestId: req.requestId,
      endpoint: 'GET /api/orders/customer/:email',
      customerEmail,
      userID,
      useDatabase
    }, 'Fetching orders by customer email');
    
    // Add New Relic custom attributes for this transaction
    newrelic.addCustomAttributes({
      'customerEmail': customerEmail,
      'userID': userID || 'anonymous',
      'requestId': req.requestId,
      'operation': 'get_orders_by_email'
    });
    
    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const orders = await dbService.getOrdersByCustomerEmail(customerEmail);
        const dbDuration = Date.now() - dbStartTime;
        
        logger.info({
          requestId: req.requestId,
          operation: 'database.getOrdersByCustomerEmail',
          customerEmail,
          orderCount: orders.length,
          duration: dbDuration
        }, 'Orders retrieved from database');
        
        const totalDuration = Date.now() - startTime;
        logger.info({
          requestId: req.requestId,
          endpoint: 'GET /api/orders/customer/:email',
          statusCode: 200,
          customerEmail,
          orderCount: orders.length,
          duration: totalDuration
        }, 'Successfully fetched customer orders');
        
        return res.status(200).send(orders);
      } else {
        logger.info({
          requestId: req.requestId,
          operation: 'memory.getOrders',
          customerEmail
        }, 'Using memory mode - returning empty orders');
        
        return res.status(200).send([]);
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ 
        requestId: req.requestId,
        endpoint: 'GET /api/orders/customer/:email',
        customerEmail,
        err: error,
        duration
      }, 'Failed to fetch orders by customer email');
      res.status(500).send({ error: 'Failed to fetch orders' });
    }
  });

  app.get('/api/orders/customer/phone/:phone', async function(req, res, next) {
    const startTime = Date.now();
    const customerPhone = req.params.phone;
    
    // Set New Relic user ID for transaction tracking
    const userID = setNewRelicUserID({ phone: customerPhone }, 'orders_by_phone');
    
    logger.info({
      requestId: req.requestId,
      endpoint: 'GET /api/orders/customer/phone/:phone',
      customerPhone,
      userID,
      useDatabase
    }, 'Fetching orders by customer phone');
    
    // Add New Relic custom attributes for this transaction
    newrelic.addCustomAttributes({
      'customerPhone': customerPhone,
      'userID': userID || 'anonymous',
      'requestId': req.requestId,
      'operation': 'get_orders_by_phone'
    });
    
    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const orders = await dbService.getOrdersByCustomerPhone(customerPhone);
        const dbDuration = Date.now() - dbStartTime;
        
        logger.info({
          requestId: req.requestId,
          operation: 'database.getOrdersByCustomerPhone',
          customerPhone,
          orderCount: orders.length,
          duration: dbDuration
        }, 'Orders retrieved from database by phone');
        
        const totalDuration = Date.now() - startTime;
        logger.info({
          requestId: req.requestId,
          endpoint: 'GET /api/orders/customer/phone/:phone',
          statusCode: 200,
          customerPhone,
          orderCount: orders.length,
          duration: totalDuration
        }, 'Successfully fetched customer orders by phone');
        
        return res.status(200).send(orders);
      } else {
        logger.info({
          requestId: req.requestId,
          operation: 'memory.getOrders',
          customerPhone
        }, 'Using memory mode - returning empty orders');
        
        return res.status(200).send([]);
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ 
        requestId: req.requestId,
        endpoint: 'GET /api/orders/customer/phone/:phone',
        customerPhone,
        err: error,
        duration
      }, 'Failed to fetch orders by customer phone');
      res.status(500).send({ error: 'Failed to fetch orders' });
    }
  });

  app.get('/api/orders/:id', async function(req, res, next) {
    const startTime = Date.now();
    const orderId = req.params.id;
    
    logger.info({
      requestId: req.requestId,
      endpoint: 'GET /api/orders/:id',
      orderId,
      useDatabase
    }, 'Fetching order by ID');
    
    // Add New Relic custom attributes for this transaction
    newrelic.addCustomAttributes({
      'orderId': orderId,
      'requestId': req.requestId,
      'operation': 'get_order_by_id'
    });
    
    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const order = await dbService.getOrderById(orderId);
        const dbDuration = Date.now() - dbStartTime;
        
        if (order) {
          // Set user ID if we have customer information in the order
          if (order.customer_email || order.customer_phone || order.customer_name) {
            const userID = setNewRelicUserID({
              email: order.customer_email,
              phone: order.customer_phone,
              name: order.customer_name
            }, 'order_by_id');
            
            // Update New Relic attributes with user information
            newrelic.addCustomAttributes({
              'customerEmail': order.customer_email,
              'customerPhone': order.customer_phone,
              'userID': userID || 'anonymous'
            });
          }
          
          logger.info({
            requestId: req.requestId,
            operation: 'database.getOrderById',
            orderId,
            duration: dbDuration,
            hasCustomerInfo: !!(order.customer_email || order.customer_phone)
          }, 'Order retrieved from database');
          
          const totalDuration = Date.now() - startTime;
          logger.info({
            requestId: req.requestId,
            endpoint: 'GET /api/orders/:id',
            statusCode: 200,
            orderId,
            duration: totalDuration
          }, 'Successfully fetched order');
          
          return res.status(200).send(order);
        }
        
        logger.warn({
          requestId: req.requestId,
          orderId,
          duration: Date.now() - startTime
        }, 'Order not found');
        
        return res.status(404).send({ error: 'No order with id "' + orderId + '"!' });
      } else {
        logger.info({
          requestId: req.requestId,
          operation: 'memory.getOrder',
          orderId
        }, 'Using memory mode - returning 404');
        
        return res.status(404).send({ error: 'Order not found' });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ 
        requestId: req.requestId,
        endpoint: 'GET /api/orders/:id',
        orderId,
        err: error,
        duration
      }, 'Failed to fetch order by ID');
      res.status(500).send({ error: 'Failed to fetch order' });
    }
  });

  // Helper function to inject New Relic into HTML
  function injectNewRelicIntoHtml(htmlContent, newRelicHeader) {
    // Debug: Log the New Relic header to see what we're getting
    logger.debug({ headerLength: newRelicHeader ? newRelicHeader.length : 0 }, 'New Relic header retrieved');
    
    // If New Relic header is empty, skip injection
    if (!newRelicHeader || newRelicHeader.trim() === '') {
      logger.warn('New Relic header is empty - skipping injection');
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
    const indexPath = path.join(ANGULAR_DIST_DIR, 'index.html');
    fs.readFile(indexPath, 'utf8', async function(err, htmlContent) {
      if (err) {
        logger.error({ err }, 'Error reading index.html file');
        return res.status(500).send('Error loading application');
      }
      
      // Get New Relic browser timing header
      let newRelicHeader = '';
      try {
        
        // There is a race condition where the first request might not have New Relic initialized yet.
        // We can handle this by checking if it's the first request and applying a delay.
        if (isFirstRequest) {
          const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
          logger.info('First request detected - applying startup delay...');
          await sleep(3000); // Sleep for 3 seconds
          isFirstRequest = false; // Mark that we've handled the first request
          logger.info('Startup delay completed');
        }

        newRelicHeader = newrelic.getBrowserTimingHeader();
        logger.debug({
          hasLicenseKey: !!process.env.NEW_RELIC_LICENSE_KEY,
          agentVersion: newrelic.version || 'unknown',
          headerLength: newRelicHeader ? newRelicHeader.length : 0
        }, 'New Relic agent state');
        
      } catch (error) {
        logger.error({ err: error }, 'Failed to get New Relic browser timing header');
      }
      
      const modifiedHtml = injectNewRelicIntoHtml(htmlContent, newRelicHeader);
      res.setHeader('Content-Type', 'text/html');
      res.send(modifiedHtml);
    });
  });

  // Global error handling middleware with enhanced logging.
  // Must stay after every route: Express only sends errors to handlers registered later than the route that failed.
  app.use((err, req, res, next) => {
      if (res.headersSent) {
          return next(err);
      }

      // Generate error correlation ID if not present
      const errorId = req.requestId ? `${req.requestId}_err` : `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // Determine error severity
      const isServerError = !err.statusCode || err.statusCode >= 500;
      const logLevel = isServerError ? 'error' : 'warn';
      
      // Enhanced error logging with full context
      logger[logLevel]({
          errorId,
          requestId: req.requestId,
          err: {
              name: err.name,
              message: err.message,
              stack: err.stack,
              code: err.code,
              statusCode: err.statusCode
          },
          request: {
              method: req.method,
              url: req.url,
              userAgent: req.get('User-Agent'),
              ip: req.ip || req.connection.remoteAddress,
              body: req.method === 'POST' ? req.body : undefined
          },
          timestamp: new Date().toISOString()
      }, 'Express error handler caught error');
      
      // Set error ID in response headers for correlation
      res.setHeader('X-Error-ID', errorId);
      
      // Send appropriate error response
      const statusCode = err.statusCode || 500;
      const errorResponse = {
          status: 'error',
          message: isServerError ? 'Internal Server Error' : err.message,
          errorId: errorId,
          timestamp: new Date().toISOString()
      };
      
      // Include stack trace in development
      if (process.env.NODE_ENV === 'development') {
          errorResponse.stack = err.stack;
      }
      
      res.status(statusCode).json(errorResponse);
  });

  // Start the server
  async function startServer() {
    try {
      if (useDatabase) {
        logger.info('🔍 Checking database availability...');
        const dbAvailable = await dbService.isAvailable();
        if (!dbAvailable) {
          logger.warn('⚠️  Database not available, falling back to JSON file');
          useDatabase = false;
        } else {
          logger.info('✅ Database is available and ready');
        }
      }

      if (!useDatabase) {
        logger.info({ dataFile: DATA_FILE }, '📁 Loading data from JSON file');
        fs.readFile(DATA_FILE, function(err, data) {
          if (err) {
            logger.fatal({ err }, '❌ Error reading JSON file - server will exit');
            process.exit(1);
          }
          
          JSON.parse(data).forEach(function(restaurant) {
            storage.add(new RestaurantRecord(restaurant));
          });
          
          logger.info({ restaurantCount: storage.getAll().length }, '✅ Loaded restaurants from JSON file');
          startHttpServer();
        });
      } else {
        logger.info('✅ Using database for restaurant data');
        startHttpServer();
      }
    } catch (error) {
      logger.fatal({ err: error }, '❌ Error starting server - process will exit');
      process.exit(1);
    }
  }

  function startHttpServer() {
    app.listen(PORT, function() {
      logger.info({
        port: PORT,
        url: `http://localhost:${PORT}/`,
        dataSource: useDatabase ? 'PostgreSQL Database' : 'JSON File'
      }, '🚀 FoodMe server started successfully');
      
      // Only open browser in development mode
      if (!useDatabase) {
        open('http://localhost:' + PORT + '/');
      }
      
      logger.info('Node Server started on http://localhost:' + PORT + '/');
    });
  }

  // Handle graceful shutdown
  process.on('SIGTERM', async () => {
    logger.info('🛑 Received SIGTERM, shutting down gracefully...');
    if (dbService) {
      await dbService.close();
    }
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    logger.info('🛑 Received SIGINT, shutting down gracefully...');
    if (dbService) {
      await dbService.close();
    }
    process.exit(0);
  });

  // Start the application
  startServer();
};
