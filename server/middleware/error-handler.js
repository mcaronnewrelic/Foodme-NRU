// Must be registered after every route: Express only sends errors to handlers registered later than the route that failed.
module.exports = function createErrorHandler({ logger, environment }) {
  return (err, req, res, next) => {
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
  };
};
