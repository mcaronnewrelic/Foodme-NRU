# New Relic Infrastructure Agent Integration

## Overview
The EC2 deployment has been enhanced to include New Relic Infrastructure agent monitoring for comprehensive server and application monitoring.

## What's Included

### 1. New Relic Infrastructure Agent
- **Server Monitoring**: CPU, memory, disk, network metrics
- **Process Monitoring**: Application processes and resource usage
- **Custom Attributes**: Environment, application name, instance type, region
- **Display Name**: `FoodMe-EC2-{environment}-{instance-id}`

### 2. New Relic APM Integration
- **Application Performance Monitoring**: Node.js application metrics
- **App Name**: `FoodMe-{environment}` (e.g., `FoodMe-staging`, `FoodMe-production`)
- **Transaction Tracing**: Web transactions, database queries, external services
- **Error Tracking**: Application errors and exceptions

### 3. Nginx Integration
- **Web Server Metrics**: Request rates, response times, error rates
- **Status Endpoint**: `http://127.0.0.1/nginx_status` for New Relic monitoring
- **Custom Labels**: Environment and role tagging

## Configuration

### Required Secrets
Add these to your GitHub repository secrets:

1. **NEW_RELIC_LICENSE_KEY** - Your New Relic license key for Infrastructure agent
2. **NEW_RELIC_API_KEY** - Your New Relic API key for deployment tracking (already configured)

### Environment Variables
The following environment variables are automatically set for the Node.js application:
- `NEW_RELIC_LICENSE_KEY`: Infrastructure monitoring license key
- `NEW_RELIC_APP_NAME`: Application name for APM (FoodMe-{environment})
- `NEW_RELIC_NO_CONFIG_FILE`: Uses environment variables instead of config file

## Monitoring Features

### Infrastructure Monitoring
- **System Metrics**: CPU usage, memory usage, disk space, network I/O
- **Process Monitoring**: Node.js processes, nginx processes
- **Log Monitoring**: Application logs, nginx access/error logs
- **Alert Conditions**: Configurable alerts for high CPU, memory, disk usage

### Application Performance Monitoring (APM)
- **Web Transactions**: API endpoint performance
- **Database Queries**: Database connection and query performance
- **External Services**: HTTP requests to external APIs
- **Error Tracking**: Application exceptions and errors
- **Custom Events**: Order tracking, user actions

### Nginx Web Server Monitoring
- **Request Metrics**: Requests per second, response codes
- **Performance**: Response times, throughput
- **Error Tracking**: 4xx and 5xx error rates
- **Upstream Monitoring**: Backend application health

## Setup Instructions

### 1. Get New Relic License Key
1. Log into your New Relic account
2. Go to Account Settings → License Key
3. Copy your license key

### 2. Add GitHub Secrets
1. Go to your GitHub repository
2. Navigate to Settings → Secrets and Variables → Actions
3. Add `NEW_RELIC_LICENSE_KEY` with your license key

### 3. Deploy
Run your GitHub Actions workflow. The New Relic Infrastructure agent will be automatically:
- Installed during EC2 instance setup
- Configured with your license key
- Started and enabled as a system service

## Verification

### Check Infrastructure Agent Status
SSH into your EC2 instance and run:
```bash
sudo systemctl status newrelic-infra
sudo journalctl -u newrelic-infra -f
```

### Verify in New Relic Dashboard
1. Log into New Relic One
2. Go to Infrastructure → Hosts
3. Look for your server: `FoodMe-EC2-{environment}-{instance-id}`
4. Check APM & Services for your application: `FoodMe-{environment}`

## Configuration Files

### Infrastructure Agent Config
Location: `/etc/newrelic-infra.yml`
```yaml
license_key: {YOUR_LICENSE_KEY}
display_name: FoodMe-EC2-{environment}-{instance-id}
custom_attributes:
  environment: {environment}
  application: foodme
  instance_type: {instance_type}
  region: {aws_region}
```

### Nginx Integration Config
Location: `/etc/newrelic-infra/integrations.d/nginx-config.yml`
```yaml
integrations:
  - name: nri-nginx
    env:
      METRICS: true
      STATUS_URL: http://127.0.0.1/nginx_status
      STATUS_MODULE: discover
      REMOTE_MONITORING: true
    labels:
      environment: {environment}
      role: webserver
```

## Troubleshooting

### Infrastructure Agent Not Reporting
1. Check service status: `sudo systemctl status newrelic-infra`
2. Check logs: `sudo journalctl -u newrelic-infra -n 50`
3. Verify license key in `/etc/newrelic-infra.yml`
4. Ensure network connectivity to New Relic endpoints

### APM Not Showing Data
1. Check application logs: `sudo journalctl -u foodme -n 50`
2. Verify environment variables are set in systemd service
3. Check New Relic agent initialization in application startup logs

### Nginx Integration Issues
1. Verify nginx status endpoint: `curl http://127.0.0.1/nginx_status`
2. Check nginx configuration: `/etc/nginx/conf.d/foodme.conf`
3. Restart nginx: `sudo systemctl restart nginx`

## Cost Considerations
- New Relic Infrastructure agent monitoring is included in most New Relic plans
- Check your New Relic pricing tier for any usage limits
- Infrastructure data retention varies by plan

## Security Notes
- License key is passed securely through GitHub Secrets
- Nginx status endpoint is only accessible from localhost (127.0.0.1)
- All monitoring traffic is encrypted in transit
- No sensitive application data is transmitted to New Relic

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
