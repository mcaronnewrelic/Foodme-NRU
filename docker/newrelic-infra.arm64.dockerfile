# New Relic Infrastructure Mock for ARM64/local development
# Ultra-simplified version that avoids any package installation

FROM alpine:latest

# Create newrelic user without additional packages
RUN addgroup -g 1000 newrelic && \
    adduser -D -u 1000 -G newrelic newrelic

# Create New Relic directories
RUN mkdir -p /etc/newrelic-infra/integrations.d/ && \
    mkdir -p /var/db/newrelic-infra/newrelic-integrations/bin/ && \
    mkdir -p /var/log/newrelic-infra

# Copy integration configs (YAML files only, not binaries)
COPY newrelic-integrations/ /etc/newrelic-infra/integrations.d/

# Set proper permissions
RUN chown -R newrelic:newrelic /etc/newrelic-infra && \
    chown -R newrelic:newrelic /var/db/newrelic-infra && \
    chown -R newrelic:newrelic /var/log/newrelic-infra && \
    chmod -R 644 /etc/newrelic-infra/integrations.d/ && \
    chmod 755 /var/db/newrelic-infra/newrelic-integrations && \
    chmod 755 /var/db/newrelic-infra/newrelic-integrations/bin

# Create a minimal New Relic agent for local development
RUN echo '#!/bin/sh' > /usr/local/bin/newrelic-infra-mock && \
    echo 'echo "New Relic Infrastructure Mock Agent for Local Development"' >> /usr/local/bin/newrelic-infra-mock && \
    echo 'echo "License Key: ${NRIA_LICENSE_KEY:-NOT_SET}"' >> /usr/local/bin/newrelic-infra-mock && \
    echo 'echo "Display Name: ${NRIA_DISPLAY_NAME:-FoodMe-Local}"' >> /usr/local/bin/newrelic-infra-mock && \
    echo 'echo "Starting monitoring simulation..."' >> /usr/local/bin/newrelic-infra-mock && \
    echo 'while true; do' >> /usr/local/bin/newrelic-infra-mock && \
    echo '  echo "$(date): Monitoring foodme application..."' >> /usr/local/bin/newrelic-infra-mock && \
    echo '  sleep 60' >> /usr/local/bin/newrelic-infra-mock && \
    echo 'done' >> /usr/local/bin/newrelic-infra-mock && \
    chmod +x /usr/local/bin/newrelic-infra-mock

# Health check script
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh && \
    echo 'echo "New Relic Infrastructure Mock - Health Check OK"' >> /usr/local/bin/healthcheck.sh && \
    echo 'exit 0' >> /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Switch to newrelic user
USER newrelic

# Use the mock agent
ENTRYPOINT ["/usr/local/bin/newrelic-infra-mock"]