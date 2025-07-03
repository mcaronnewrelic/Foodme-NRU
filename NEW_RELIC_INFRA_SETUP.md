# New Relic Infrastructure Monitoring Setup Guide

## Overview
This guide explains how to enable New Relic infrastructure monitoring for the FoodMe application when running outside of a devcontainer.

## Prerequisites

1. **New Relic Account**: You need a New Relic account with a license key
2. **Docker**: Docker and Docker Compose must be installed and running
3. **Valid License Key**: Your New Relic license key must be properly configured

## Quick Setup

### 1. Configure Your License Key

Edit your `.env` file and add your actual New Relic license key:

```bash
NEW_RELIC_LICENSE_KEY=your_actual_license_key_here
```

You can find your license key at: https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher

### 2. Run the Setup Script

```bash
./setup-newrelic-infra.sh
```

This script will:
- Validate your configuration
- Start all services with New Relic monitoring enabled
- Test the integrations
- Show you the status of all monitoring components

### 3. Verify Setup

After setup, you should see these containers running:
- `newrelic-infra` - Infrastructure monitoring
- `newrelic-nginx` - Nginx monitoring
- `newrelic-postgres` - Database monitoring

## What Gets Monitored

### Infrastructure Agent
- Host system metrics (CPU, memory, disk, network)
- Docker container metrics
- Process monitoring
- Custom attributes for filtering

### Nginx Integration
- HTTP request metrics
- Response times
- Connection statistics
- Error rates
- Upstream server health

### PostgreSQL Integration
- Database performance metrics
- Connection pool statistics
- Query performance
- Table sizes and growth
- Custom FoodMe business metrics

## Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Update docker-compose.yml

The infrastructure monitoring is already configured in the main `docker-compose.yml` file with full capabilities enabled for non-devcontainer usage.

### 2. Start Services

```bash
# Stop existing services
docker compose down

# Start with New Relic monitoring
docker compose up -d
```

### 3. Test Setup

```bash
# Test New Relic integrations
./test-newrelic-integrations.sh

# Check container status
docker compose ps

# View logs
docker compose logs newrelic-infra
```

## Viewing Your Data

Once setup is complete, you can view your monitoring data in New Relic:

1. **Infrastructure Overview**: https://one.newrelic.com/launcher/infrastructure-ui.infrastructure-launcher
2. **Docker Monitoring**: Filter by `application:foodme` in the Infrastructure UI
3. **Nginx Metrics**: Look for nginx integration data in Infrastructure > Integrations
4. **PostgreSQL Metrics**: Look for postgres integration data in Infrastructure > Integrations

## Troubleshooting

### Common Issues

#### 1. License Key Issues
```bash
# Check if license key is set
grep NEW_RELIC_LICENSE_KEY .env

# Verify it's not a placeholder
grep -v "your_newrelic_license_key_here" .env
```

#### 2. Container Permission Issues
If you see permission errors, ensure Docker has the required permissions:
```bash
# Check container logs
docker compose logs newrelic-infra

# Restart with proper permissions
docker compose down
docker compose up -d
```

#### 3. Network Connectivity
Test if the containers can communicate:
```bash
# Test nginx status endpoint
curl http://localhost/nginx_status

# Test database connection
docker compose exec db psql -U foodme_user -d foodme -c "SELECT 1;"
```

### Monitoring Commands

```bash
# View all New Relic container logs
docker compose logs newrelic-infra newrelic-nginx newrelic-postgres

# Check container resource usage
docker stats

# Test specific integration
docker compose exec newrelic-infra cat /etc/newrelic-infra/integrations.d/nginx-config.yml
```

## Differences from DevContainer Setup

The main differences when running outside a devcontainer:

1. **Full Privileges**: Infrastructure agent runs with `privileged: true` and `pid: host`
2. **Host Monitoring**: Full access to host system via `/:/host:ro` volume mount
3. **Process Monitoring**: `NRIA_ENABLE_PROCESS_METRICS=true` enabled
4. **Additional Integrations**: Nginx and PostgreSQL monitoring included

## Environment Variables

Key environment variables for New Relic monitoring:

```bash
# Required
NEW_RELIC_LICENSE_KEY=your_license_key_here

# Optional (for deployment tracking)
NEW_RELIC_API_KEY=your_api_key_here
NEW_RELIC_ENTITY_GUID=your_entity_guid_here
```

## Support

If you encounter issues:

1. Check the logs: `docker compose logs newrelic-infra`
2. Verify your license key is valid
3. Ensure Docker has sufficient permissions
4. Test network connectivity between containers

For more information, see:
- [New Relic Infrastructure Agent Documentation](https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/get-started/install-infrastructure-agent/)
- [New Relic Docker Monitoring](https://docs.newrelic.com/docs/infrastructure/host-integrations/host-integrations-list/docker-monitoring-integration/)
