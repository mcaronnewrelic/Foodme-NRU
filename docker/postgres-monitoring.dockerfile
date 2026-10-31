# PostgreSQL Dockerfile with monitoring extensions
# Based on CloudFormation setup_postgresql_monitoring() configuration

FROM postgres:16-alpine

# For local development with PostgreSQL 16 Alpine, the contrib modules
# are already included in the base image, so we don't need to install them separately

# Create directory for custom scripts
RUN mkdir -p /docker-entrypoint-initdb.d/scripts

# Copy monitoring setup scripts
COPY db/scripts/ /docker-entrypoint-initdb.d/

# Set proper permissions for scripts  
RUN chmod +x /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true

# Expose PostgreSQL port
EXPOSE 5432

# Use the default PostgreSQL entrypoint
# The monitoring scripts will be executed automatically during initialization