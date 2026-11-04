module.exports = function createRequestTracing({ logger }) {
  return (req, res, next) => {
    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const startTime = Date.now();

    // Add request ID to request object for use in other middleware/routes
    req.requestId = requestId;

    // Set request ID header for tracing
    res.setHeader("X-Request-ID", requestId);

    // Only API and simulation routes are traced. This middleware runs
    // before static file serving, and tracing every chunk, stylesheet
    // and image drowned the log stream (~90% of lines were this pair).
    const isTracedRoute =
      req.url.startsWith("/api/") || req.url.startsWith("/simulate");

    // Log incoming request (debug: the completion line below already
    // carries method, URL, status and duration at info level)
    if (isTracedRoute) {
      logger.debug(
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
    }

    // Override res.end to log response
    if (isTracedRoute) {
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
    }

    next();
  };
};
