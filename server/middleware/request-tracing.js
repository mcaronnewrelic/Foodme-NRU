module.exports = function createRequestTracing({ logger }) {
  return (req, res, next) => {
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
  };
};
