FROM newrelic/infrastructure:latest

# Switch to root for package installation
USER root

# For local development/testing, we'll skip the integrations download
# since they require specific architecture binaries and can cause SSL issues
# In production, these would be installed via package managers on the host

# Create integration directories
RUN mkdir -p /var/db/newrelic-infra/newrelic-integrations/bin/ && \
    mkdir -p /etc/newrelic-infra/integrations.d/

# Copy any local integration configs (these are the configuration files, not binaries)
COPY newrelic-integrations/ /etc/newrelic-infra/integrations.d/

# Set proper permissions for configuration files
RUN chmod -R 644 /etc/newrelic-infra/integrations.d/ || true

# Create a simple health check script for local development
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh && \
    echo 'echo "New Relic Infrastructure agent status check"' >> /usr/local/bin/healthcheck.sh && \
    echo 'ps aux | grep newrelic || echo "New Relic processes:"' >> /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Ensure integrations directory has proper permissions
RUN chmod 755 /var/db/newrelic-infra/newrelic-integrations && \
    chmod 755 /var/db/newrelic-infra/newrelic-integrations/bin

# Use the default entrypoint (runs as appropriate user automatically)
ENTRYPOINT ["/usr/bin/newrelic-infra-service"]
