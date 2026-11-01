# New Relic Infrastructure Integrations - Installation Guide

## Overview
The `newrelic-infra.dockerfile` has been updated to include the `nri-nginx` and `nri-postgresql` New Relic integration packages for comprehensive monitoring of the FoodMe application stack.

## Installed Integrations

### 1. nri-nginx
- **Purpose**: Monitors Nginx web server performance and health
- **Metrics**: Request rates, response times, connection counts, error rates
- **Configuration**: `newrelic-integrations/nginx-config.yml`

### 2. nri-postgresql  
- **Purpose**: Monitors PostgreSQL database performance and health
- **Metrics**: Query performance, connection counts, database size, lock metrics
- **Configuration**: `newrelic-integrations/postgres-config.yml`

## Dockerfile Changes Made

```dockerfile
# Install New Relic integrations packages
USER root
RUN microdnf update -y && \
    microdnf install -y \
        nri-nginx \
        nri-postgresql && \
    microdnf clean all
USER newrelic
```

## Configuration Files

### Nginx Integration (`nginx-config.yml`)
- Monitors Nginx status endpoint at `http://nginx:80/nginx_status`
- Collects metrics and inventory data
- Configured for Docker Compose networking

### PostgreSQL Integration (`postgres-config.yml`)
- Connects to database container `db` on port 5432
- Uses credentials from environment variables
- Collects extended metrics including lock information
- SSL disabled for internal Docker networking

## How to Rebuild and Deploy

### 1. Rebuild the New Relic Infrastructure Container
```bash
# From the docker directory
docker-compose build newrelic-infra
```

### 2. Restart Services with New Integration
```bash
# Stop current services
docker-compose down

# Start with rebuilt infrastructure monitoring
docker-compose up -d
```

### 3. Verify Integration Installation
```bash
# Check that integrations are installed in the container
docker exec foodme-infra ls -la /var/db/newrelic-infra/newrelic-integrations/bin/

# Check integration logs
docker logs foodme-infra
```

## Expected New Relic Data

After deployment, you should see in New Relic:

### Nginx Metrics
- Request throughput and response times
- HTTP status code distributions  
- Active connections and waiting requests
- Upstream server health

### PostgreSQL Metrics
- Database connections and transactions
- Query performance and slow queries
- Table and index statistics
- Lock contention and deadlocks

## Troubleshooting

### Common Issues
1. **Integration not appearing in New Relic**: 
   - Check container logs: `docker logs foodme-infra`
   - Verify configuration files are properly mounted
   - Ensure New Relic license key is set

2. **Connection errors to services**:
   - Verify Docker networking between containers
   - Check service endpoints are accessible from infra container
   - Validate credentials and connection parameters

3. **Missing metrics**:
   - Ensure target services (nginx, postgresql) are running
   - Check that status endpoints are enabled
   - Verify integration configuration syntax

### Debug Commands
```bash
# Test connectivity to services from infra container
docker exec foodme-infra wget -qO- http://nginx:80/nginx_status
docker exec foodme-infra nc -zv db 5432

# Check integration configuration
docker exec foodme-infra cat /etc/newrelic-infra/integrations.d/nginx-config.yml
docker exec foodme-infra cat /etc/newrelic-infra/integrations.d/postgres-config.yml
```

## Security Notes
- PostgreSQL integration uses environment variables for credentials
- SSL is disabled for internal Docker networking (recommended for containers)
- Integration runs as `newrelic` user for security
- Configuration files have appropriate read-only permissions

The integrations are now ready to provide comprehensive monitoring of your FoodMe application infrastructure!