const fs = require("fs");
const path = require("path");

module.exports = function createAngularFallback({
  logger,
  newrelic,
  environment,
  angularDistDir,
}) {
  // Flag to track if this is the first request
  let isFirstRequest = true;

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

  // Serves index.html for non-API routes so Angular can handle routing
  return function (req, res, next) {
    // Skip if it's an API route
    if (req.path.startsWith("/api/") || req.path.startsWith("/simulate/")) {
      return next();
    }

    // Read Angular's built index.html and inject New Relic
    const indexPath = path.join(angularDistDir, "index.html");
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
  };
};
