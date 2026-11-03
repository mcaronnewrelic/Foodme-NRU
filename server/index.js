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

var MemoryStorage = require("./storage").Memory;
const DatabaseService = require("./database");
const DashboardLinks = require("./dashboard-links");
const createSimulationRouter = require("./routes/simulation");
const createRestaurantRouter = require("./routes/restaurant");
const createOrderRouter = require("./routes/order");
const createDemoRouter = require("./routes/demo");
const createRequestTracing = require("./middleware/request-tracing");
const createErrorHandler = require("./middleware/error-handler");
const createAngularFallback = require("./middleware/angular-fallback");

// Which demo failure scenario is armed (env > manual override > weekly
// rotation). See demo-failures.js.
const DemoFailures = require("./demo-failures");
const DemoInvestigations = require("./demo-investigations");

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

  app.use(createRequestTracing({ logger }));

  app.use((req, res, next) => {
    // Block direct access to index.html - let the catch-all handler serve it with New Relic
    if (req.path === "/index.html" || req.path === "/") {
      return next();
    }
    express.static(ANGULAR_DIST_DIR)(req, res, next);
  });

  // Serve the original static files as fallback (if needed)
  app.use("/legacy", express.static(staticDir));

  app.use("/simulate", createSimulationRouter({ logger, newrelic }));

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

  app.use(
    createAngularFallback({
      logger,
      newrelic,
      environment,
      angularDistDir: ANGULAR_DIST_DIR,
    }),
  );

  // Must stay after every route and the Angular fallback.
  app.use(createErrorHandler({ logger, environment }));

  return app;
};
