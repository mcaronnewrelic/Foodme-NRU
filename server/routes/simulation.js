const { Router } = require("express");
const axios = require("axios");

module.exports = function createSimulationRouter({ logger }) {
  const router = Router();

  router.get("/error/sync", (req, res, next) => {
    throw new Error("This is a synchronous internal server error!");
  });

  router.get("/error/async-unhandled", async (req, res, next) => {
    await new Promise((resolve, reject) => {
      setTimeout(() => {
        reject(
          new Error(
            "This is an unhandled promise rejection from an async operation!",
          ),
        );
      }, 100);
    });
    res.send("This should not be reached.");
  });

  router.get("/cpu-hog", (req, res) => {
    const startTime = Date.now();
    const iterations = parseInt(req.query.iterations) || 100000000;
    logger.info(
      { requestId: req.requestId, endpoint: "/simulate/cpu-hog", iterations },
      "Starting CPU intensive simulation",
    );
    const cpuStartTime = process.cpuUsage();
    const startTime2 = Date.now();
    for (let index = 0; index < iterations; index++) {
      Math.sqrt(index);
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
        user: cpuEndTime.user / 1000,
        system: cpuEndTime.system / 1000,
      },
      memoryUsage: process.memoryUsage(),
    };
    logger.info(performanceData, "CPU intensive simulation completed");
    res.json({
      message: "CPU simulation completed",
      performance: performanceData,
    });
  });

  const leakyArray = [];
  router.get("/memory-leak", (req, res) => {
    for (let index = 0; index < 10000; index++) {
      leakyArray.push({
        id: Math.random(),
        data: Buffer.alloc(1024 * 10, "a").toString("base64"),
      });
    }
    const currentMemory = process.memoryUsage().heapUsed / (1024 * 1024);
    res.send(
      `Memory increased. Current heap usage: ${currentMemory.toFixed(2)} MB. Array size: ${leakyArray.length}`,
    );
  });

  router.get("/memory-leak/clear", (req, res) => {
    leakyArray.length = 0;
    res.send("Leaky array cleared. Memory should stabilize.");
  });

  router.get("/slow-response", (req, res) => {
    const delay = parseInt(req.query.delay) || 5000;
    console.log(`Simulating a ${delay}ms delay...`);
    setTimeout(() => {
      res.send(`Response after ${delay}ms delay.`);
    }, delay);
  });

  router.get("/external-api-timeout", async (req, res, next) => {
    const externalApiUrl =
      "http://localhost:3000/simulate/slow-response?delay=10000";
    const timeoutMs = 2000;
    try {
      const response = await axios.get(externalApiUrl, { timeout: timeoutMs });
      res.json({
        message:
          "External API call succeeded (unexpectedly if timeout was hit)",
        data: response.data,
      });
    } catch (error) {
      if (error.code === "ECONNABORTED" || error.message.includes("timeout")) {
        logger.error(
          { error: error.message, timeout: 5000 },
          "External API call timed out",
        );
        res.status(504).json({
          status: "error",
          message: `External API call timed out after ${timeoutMs}ms.`,
          details: error.message,
        });
      } else {
        logger.error({ error: error.message }, "Error calling external API");
        next(error);
      }
    }
  });

  router.get("/uncaught-exception", (req, res) => {
    setTimeout(() => {
      nonExistentFunction();
    }, 100);
    res.send("Attempting to trigger an uncaught exception...");
  });

  return router;
};
