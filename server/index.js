// Disable New Relic for local development
const defaultNewRelic = require("newrelic");
/*var newrelic = {
  getBrowserTimingHeader: () => '',
  addCustomAttributes: () => {},
  incrementMetric: () => {},
  recordMetric: () => {},
  recordCustomEvent: () => {}
};
*/

const defaultLogger = require("pino")();

const express = require("express");
const { engine } = require("express-handlebars");
const path = require("path");

var fs = require("fs");
var open = require("open").default; // open 11 is an ES module

var RestaurantRecord = require("./model").Restaurant;
var MemoryStorage = require("./storage").Memory;
const DatabaseService = require("./database");
const DashboardLinks = require("./dashboard-links");
const createSimulationRouter = require("./routes/simulation");
const createRestaurantRouter = require("./routes/restaurant");
const createOrderRouter = require("./routes/order");
const createDemoRouter = require("./routes/demo");

// Which demo failure scenario is armed (env > manual override > weekly
// rotation). See demo-failures.js.
const DemoFailures = require("./demo-failures");
const DemoInvestigations = require("./demo-investigations");
const OrderStatusWorker = require("./order-status-worker");

exports.createApp = function (dependencies = {}) {
  const environment = dependencies.environment || process.env;
  const {
    logger = defaultLogger,
    newrelic = defaultNewRelic,
    storage = new MemoryStorage(),
    dbService = new DatabaseService(),
    demoFailures = new DemoFailures(logger),
    demoInvestigations = new DemoInvestigations(logger),
    dashboardLinks = new DashboardLinks({
      apiKey: environment.NEW_RELIC_API_KEY,
      account: environment.NEW_RELIC_ACCOUNT_ID || 1352811,
      guid: environment.NEW_RELIC_DASHBOARD_GUID || undefined,
      region: environment.NEW_RELIC_REGION || "us",
    }),
    staticDir = path.join(__dirname, "../angular-app/src/app"),
    useDatabase = environment.NODE_ENV === "production" ||
      environment.DOCKER_COMPOSE === "true" ||
      environment.DB_HOST === "db",
  } = dependencies;
  var app = express();

  const isProduction = environment.NODE_ENV === "production";

  logger.info(
    {
      environment: isProduction ? "production" : "development",
      dataSource: useDatabase ? "PostgreSQL database" : "JSON file",
    },
    "Server configuration initialized",
  );

  // Flag to track if this is the first request
  let isFirstRequest = true;

  app.locals.newrelic = newrelic;

  // Serve Angular app static files (excluding index.html)
  // The Angular build lands in a different place per layout, so use whichever exists:
  // ../browser      production image: /orderup/app/server/ -> /orderup/app/browser/
  // ../dist/browser local dev, local Docker mount, and EC2 (/opt/orderup/backend -> /opt/orderup/dist/browser)
  const isDocker =
    environment.DOCKER_COMPOSE === "true" || process.cwd() === "/orderup";
  const ANGULAR_DIST_CANDIDATES = [
    path.join(__dirname, "../browser"),
    path.join(__dirname, "../dist/browser"),
  ];
  const ANGULAR_DIST_DIR =
    dependencies.angularDistDir ||
    ANGULAR_DIST_CANDIDATES.find((dir) => fs.existsSync(dir)) ||
    ANGULAR_DIST_CANDIDATES[0];
  logger.info(
    {
      angularDir: ANGULAR_DIST_DIR,
      directoryExists: fs.existsSync(ANGULAR_DIST_DIR),
    },
    "Angular static files configuration",
  );

  // Request tracing middleware - add unique request ID and logging
  app.use((req, res, next) => {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const startTime = Date.now();

    // Add request ID to request object for use in other middleware/routes
    req.requestId = requestId;

    // Set request ID header for tracing
    res.setHeader("X-Request-ID", requestId);

    // Log incoming request
    logger.info(
      {
        requestId,
        method: req.method,
        url: req.url,
        userAgent: req.get("User-Agent"),
        ip: req.ip || req.connection.remoteAddress,
        headers: {
          contentType: req.get("Content-Type"),
          contentLength: req.get("Content-Length"),
          authorization: req.get("Authorization") ? "[REDACTED]" : undefined,
        },
      },
      "Incoming request",
    );

    // Override res.end to log response
    const originalEnd = res.end;
    res.end = function (chunk, encoding) {
      const duration = Date.now() - startTime;

      logger.info(
        {
          requestId,
          method: req.method,
          url: req.originalUrl,
          statusCode: res.statusCode,
          duration,
          contentLength: res.get("Content-Length"),
        },
        "Request completed",
      );

      originalEnd.call(this, chunk, encoding);
    };

    next();
  });

  app.use((req, res, next) => {
    // Block direct access to index.html - let the catch-all handler serve it with New Relic
    if (req.path === "/index.html" || req.path === "/") {
      return next();
    }
    express.static(ANGULAR_DIST_DIR)(req, res, next);
  });

  // Serve the original static files as fallback (if needed)
  app.use("/legacy", express.static(staticDir));

  app.use("/simulate", createSimulationRouter({ logger }));

  app.use(
    "/api",
    createDemoRouter({
      logger,
      environment,
      demoFailures,
      demoInvestigations,
      dashboardLinks,
    }),
  );

  // Health check endpoint
  app.get("/health", async function (req, res) {
    try {
      const healthStatus = {
        status: "healthy",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        pid: process.pid,
        version: process.version,
        environment: environment.NODE_ENV || "development",
        dataSource: useDatabase ? "PostgreSQL" : "JSON file",
      };

      // Test database connection if using database
      if (useDatabase && dbService) {
        try {
          const isDbHealthy = await dbService.isAvailable();
          healthStatus.database = {
            status: isDbHealthy ? "connected" : "disconnected",
            type: "PostgreSQL",
          };

          if (!isDbHealthy) {
            healthStatus.status = "degraded";
          }
        } catch (dbError) {
          healthStatus.database = {
            status: "error",
            error: dbError.message,
            type: "PostgreSQL",
          };
          healthStatus.status = "degraded";
        }
      } else {
        healthStatus.database = {
          status: "not_applicable",
          type: "JSON file",
        };
      }

      // Set appropriate HTTP status code based on health
      const statusCode =
        healthStatus.status === "healthy"
          ? 200
          : healthStatus.status === "degraded"
            ? 200
            : 503;

      res.status(statusCode).json(healthStatus);
    } catch (error) {
      logger.error({ err: error }, "Health check failed");
      res.status(503).json({
        status: "unhealthy",
        timestamp: new Date().toISOString(),
        error: error.message,
        uptime: process.uptime(),
        pid: process.pid,
      });
    }
  });

  app.use(
    "/api/restaurant",
    createRestaurantRouter({
      storage,
      dbService,
      useDatabase,
      logger,
      newrelic,
      demoFailures,
      demoInvestigations,
    }),
  );

  app.use(
    "/api",
    createOrderRouter({
      storage,
      dbService,
      useDatabase,
      logger,
      newrelic,
      demoFailures,
      demoInvestigations,
    }),
  );

  // Helper function to inject New Relic into HTML
  function injectNewRelicIntoHtml(htmlContent, newRelicHeader) {
    // Debug: Log the New Relic header to see what we're getting
    logger.debug(
      { headerLength: newRelicHeader ? newRelicHeader.length : 0 },
      "New Relic header retrieved",
    );

    // If New Relic header is empty, skip injection
    if (!newRelicHeader || newRelicHeader.trim() === "") {
      logger.warn("New Relic header is empty - skipping injection");
      return htmlContent;
    }

    // Inject New Relic header after the <head> tag
    return htmlContent.replace(
      "<head>",
      `<head>\n  <!-- New Relic Browser Timing Header -->\n  ${newRelicHeader}`,
    );
  }

  // Catch-all handler for Angular routing - serve index.html for non-API routes
  app.use(function (req, res, next) {
    // Skip if it's an API route
    if (req.path.startsWith("/api/") || req.path.startsWith("/simulate/")) {
      return next();
    }

    // Read Angular's built index.html and inject New Relic
    const indexPath = path.join(ANGULAR_DIST_DIR, "index.html");
    fs.readFile(indexPath, "utf8", async function (err, htmlContent) {
      if (err) {
        logger.error({ err }, "Error reading index.html file");
        return res.status(500).send("Error loading application");
      }

      // Get New Relic browser timing header
      let newRelicHeader = "";
      try {
        // There is a race condition where the first request might not have New Relic initialized yet.
        // We can handle this by checking if it's the first request and applying a delay.
        if (isFirstRequest) {
          const sleep = (ms) =>
            new Promise((resolve) => setTimeout(resolve, ms));
          logger.info("First request detected - applying startup delay...");
          await sleep(3000); // Sleep for 3 seconds
          isFirstRequest = false; // Mark that we've handled the first request
          logger.info("Startup delay completed");
        }

        newRelicHeader = newrelic.getBrowserTimingHeader();
        logger.debug(
          {
            hasLicenseKey: !!environment.NEW_RELIC_LICENSE_KEY,
            agentVersion: newrelic.version || "unknown",
            headerLength: newRelicHeader ? newRelicHeader.length : 0,
          },
          "New Relic agent state",
        );
      } catch (error) {
        logger.error(
          { err: error },
          "Failed to get New Relic browser timing header",
        );
      }

      const modifiedHtml = injectNewRelicIntoHtml(htmlContent, newRelicHeader);
      res.setHeader("Content-Type", "text/html");
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
    const errorId = req.requestId
      ? `${req.requestId}_err`
      : `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Determine error severity
    const isServerError = !err.statusCode || err.statusCode >= 500;
    const logLevel = isServerError ? "error" : "warn";

    // Enhanced error logging with full context
    logger[logLevel](
      {
        errorId,
        requestId: req.requestId,
        err: {
          name: err.name,
          message: err.message,
          stack: err.stack,
          code: err.code,
          statusCode: err.statusCode,
        },
        request: {
          method: req.method,
          url: req.url,
          userAgent: req.get("User-Agent"),
          ip: req.ip || req.connection.remoteAddress,
          body: req.method === "POST" ? req.body : undefined,
        },
        timestamp: new Date().toISOString(),
      },
      "Express error handler caught error",
    );

    // Set error ID in response headers for correlation
    res.setHeader("X-Error-ID", errorId);

    // Send appropriate error response
    const statusCode = err.statusCode || 500;
    const errorResponse = {
      status: "error",
      message: isServerError ? "Internal Server Error" : err.message,
      errorId: errorId,
      timestamp: new Date().toISOString(),
    };

    // Include stack trace in development
    if (environment.NODE_ENV === "development") {
      errorResponse.stack = err.stack;
    }

    res.status(statusCode).json(errorResponse);
  });

  return app;
};

exports.start = function (PORT, STATIC_DIR, DATA_FILE, TEST_DIR) {
  const logger = defaultLogger;
  const storage = new MemoryStorage();
  const dbService = new DatabaseService();
  const demoFailures = new DemoFailures(logger);
  const demoInvestigations = new DemoInvestigations(logger);
  const orderStatusWorker = new OrderStatusWorker(logger);
  let useDatabase =
    process.env.NODE_ENV === "production" ||
    process.env.DOCKER_COMPOSE === "true" ||
    process.env.DB_HOST === "db";
  void demoInvestigations.syncSideEffects();

  process.on("unhandledRejection", (reason, promise) => {
    logger.error({ promise, reason }, "Unhandled promise rejection detected");
  });

  process.on("uncaughtException", (err) => {
    logger.fatal({ err }, "Uncaught exception detected - server will exit");
  });

  // Start the server
  async function startServer() {
    try {
      if (useDatabase) {
        logger.info("🔍 Checking database availability...");
        const dbAvailable = await dbService.isAvailable();
        if (!dbAvailable) {
          logger.warn("⚠️  Database not available, falling back to JSON file");
          useDatabase = false;
        } else {
          logger.info("✅ Database is available and ready");
        }
      }

      if (!useDatabase) {
        logger.info({ dataFile: DATA_FILE }, "📁 Loading data from JSON file");
        fs.readFile(DATA_FILE, function (err, data) {
          if (err) {
            logger.fatal(
              { err },
              "❌ Error reading JSON file - server will exit",
            );
            process.exit(1);
          }

          JSON.parse(data).forEach(function (restaurant) {
            storage.add(new RestaurantRecord(restaurant));
          });

          logger.info(
            { restaurantCount: storage.getAll().length },
            "✅ Loaded restaurants from JSON file",
          );
          startHttpServer();
        });
      } else {
        logger.info("✅ Using database for restaurant data");
        startHttpServer();
      }
    } catch (error) {
      logger.fatal(
        { err: error },
        "❌ Error starting server - process will exit",
      );
      process.exit(1);
    }
  }

  function startHttpServer() {
    const app = exports.createApp({
      logger,
      storage,
      dbService,
      demoFailures,
      demoInvestigations,
      useDatabase,
      staticDir: STATIC_DIR,
    });
    app.listen(PORT, function () {
      // Orders advance through their lifecycle only in database mode.
      if (useDatabase) orderStatusWorker.start();
      logger.info(
        {
          port: PORT,
          url: `http://localhost:${PORT}/`,
          dataSource: useDatabase ? "PostgreSQL Database" : "JSON File",
        },
        "🚀 FoodMe server started successfully",
      );

      // Only open browser in development mode
      if (!useDatabase) {
        open("http://localhost:" + PORT + "/");
      }

      logger.info("Node Server started on http://localhost:" + PORT + "/");
    });
  }

  // Handle graceful shutdown
  process.on("SIGTERM", async () => {
    logger.info("🛑 Received SIGTERM, shutting down gracefully...");
    if (dbService) {
      await dbService.close();
    }
    process.exit(0);
  });

  process.on("SIGINT", async () => {
    logger.info("🛑 Received SIGINT, shutting down gracefully...");
    if (dbService) {
      await dbService.close();
    }
    process.exit(0);
  });

  // Start the application
  startServer();
};
