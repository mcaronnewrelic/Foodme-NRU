// Only require newrelic if it's enabled
if (process.env.NEW_RELIC_ENABLED === "true") {
  require("newrelic");
}

const fs = require("fs");
const open = require("open").default; // open 11 is an ES module
const defaultLogger = require("pino")();

const { createApp } = require("./index");
const RestaurantRecord = require("./model").Restaurant;
const MemoryStorage = require("./storage").Memory;
const DatabaseService = require("./database");
const DemoFailures = require("./demo-failures");
const DemoInvestigations = require("./demo-investigations");
const OrderStatusWorker = require("./order-status-worker");
const OrderStatusStream = require("./order-status-stream");

function start(PORT, STATIC_DIR, DATA_FILE) {
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
  // Live order tracking: browsers subscribe over WebSocket and the
  // worker pushes each advance. Snapshots read through the app's own
  // order lookup, so they answer even while the worker is sick.
  const orderStatusStream = new OrderStatusStream(logger, async (orderId) => {
    if (!useDatabase) return null;
    const order = await dbService.getOrderById(orderId);
    return order ? order.status : null;
  });
  orderStatusWorker.onAdvance = (changed) => {
    for (const order of changed) {
      orderStatusStream.publish(String(order.id), order.status);
    }
  };
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
    const app = createApp({
      logger,
      storage,
      dbService,
      demoFailures,
      demoInvestigations,
      useDatabase,
      staticDir: STATIC_DIR,
    });
    const server = app.listen(PORT, function () {
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
    orderStatusStream.attach(server);
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
}

const PORT = process.env.PORT || 3000;
const STATIC_DIR = __dirname + "/../angular-app/src/app";
const DATA_FILE = __dirname + "/data/restaurants.json";

start(PORT, STATIC_DIR, DATA_FILE);
