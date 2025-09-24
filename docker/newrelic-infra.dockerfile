FROM newrelic/infrastructure:latest

# Copy the New Relic integrations configuration into the image
COPY ../newrelic-integrations/ /etc/newrelic-infra/integrations.d/

# Set proper permissions
RUN chmod -R 644 /etc/newrelic-infra/integrations.d/

# Use the default entrypoint
ENTRYPOINT ["/usr/bin/newrelic-infra-service"]
