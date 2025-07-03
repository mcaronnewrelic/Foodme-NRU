# New Relic Infrastructure Integrations for FoodMe

This directory contains New Relic infrastructure integration configurations for monitoring the FoodMe application stack.

## 🔧 Configured Integrations

### 1. Infrastructure Agent (`newrelic-infra`)
- **Purpose**: Monitors host system, Docker containers, and processes
- **Features**:
  - Docker container monitoring
  - Process metrics collection
  - Host system monitoring
  - Custom attributes for filtering

### 2. Nginx Integration (`newrelic-nginx`)
- **Purpose**: Monitors nginx reverse proxy performance
- **Metrics Collected**:
  - Request throughput and response times
  - Connection statistics
  - HTTP status codes
  - Upstream server health
- **Configuration**: `nginx-config.yml`
- **Status Endpoint**: `http://nginx:80/nginx_status`

### 3. PostgreSQL Integration (`newrelic-postgres`)
- **Purpose**: Monitors PostgreSQL database performance
- **Metrics Collected**:
  - Connection pool statistics
  - Query performance
  - Database size and growth
  - Lock contention metrics
  - Custom FoodMe business metrics (restaurant/menu counts)
- **Configuration**: `postgres-config.yml`
- **Custom Queries**: Tracks FoodMe-specific table row counts

## 🚀 Getting Started

### Prerequisites
- New Relic account with license key
- Docker and Docker Compose
- FoodMe application running

### Setup Steps

1. **Configure New Relic License Key**
   ```bash
   # Add to your .env file
   NEW_RELIC_LICENSE_KEY=your_license_key_here
   ```

2. **Start the Integrations**
   ```bash
   # Start all services including New Relic integrations
   docker-compose up -d
   
   # Or start specific integrations
   docker-compose up -d newrelic-infra newrelic-nginx newrelic-postgres
   ```

3. **Verify Integration Status**
   ```bash
   # Check container status
   docker-compose ps
   
   # Check logs for any errors
   docker-compose logs newrelic-infra
   docker-compose logs newrelic-nginx
   docker-compose logs newrelic-postgres
   ```

## 📊 Monitoring Dashboards

### Infrastructure
- **Host Metrics**: CPU, memory, disk, network
- **Container Metrics**: Docker containers, resource usage
- **Process Metrics**: Application processes, resource consumption

### Nginx
- **Performance**: Request rate, response times, error rates
- **Connections**: Active connections, request/response ratios
- **Upstream Health**: Backend server status and response times

### PostgreSQL
- **Database Performance**: Query performance, slow queries, locks
- **Connection Pool**: Active connections, idle connections, wait times
- **Business Metrics**: Restaurant count, menu items, orders, customers
- **Storage**: Database size, table sizes, index usage

## 🔧 Configuration Details

### Custom Attributes
All integrations include custom attributes for easier filtering:
- `environment`: "docker-compose"
- `application`: "foodme"
- Service-specific attributes (service, role, etc.)

### Security
- Database password is mounted via Docker secrets
- Nginx status endpoint is restricted to internal networks
- All communications use internal Docker networks

### Intervals
- **Infrastructure**: Real-time monitoring
- **Nginx**: 30-second intervals
- **PostgreSQL**: 30-second intervals

## 🔍 Troubleshooting

### Common Issues

1. **Integration Not Appearing in New Relic**
   - Verify license key is correct
   - Check container logs for errors
   - Ensure network connectivity

2. **Nginx Status Endpoint Not Available**
   - Verify nginx configuration includes stub_status
   - Check nginx container is running
   - Ensure status endpoint is accessible

3. **PostgreSQL Connection Issues**
   - Verify database credentials
   - Check PostgreSQL container is running
   - Ensure database secrets are mounted correctly

### Useful Commands

```bash
# Test nginx status endpoint
curl http://localhost/nginx_status

# Check PostgreSQL connection
docker-compose exec db psql -U foodme_user -d foodme -c "SELECT version();"

# View integration logs
docker-compose logs -f newrelic-infra
docker-compose logs -f newrelic-nginx
docker-compose logs -f newrelic-postgres

# Restart specific integration
docker-compose restart newrelic-nginx
```

## 📈 Custom Metrics

### FoodMe Business Metrics
The PostgreSQL integration includes custom queries that track:
- Total restaurants in the system
- Total menu items across all restaurants
- Total orders placed
- Total customers registered

These metrics help monitor the business side of the application alongside technical performance.

## 🔒 Security Considerations

- Database passwords are handled via Docker secrets
- Nginx status endpoint is restricted to internal networks
- All integrations run in isolated containers
- No sensitive data is exposed in logs or metrics

## 🚀 Production Considerations

For production deployment:
1. Use external secrets management (AWS Secrets Manager, HashiCorp Vault)
2. Configure alerts and notifications
3. Set up custom dashboards for business metrics
4. Implement log aggregation and analysis
5. Consider using New Relic's Kubernetes integration for container orchestration

## 📚 Additional Resources

- [New Relic Infrastructure Documentation](https://docs.newrelic.com/docs/infrastructure/)
- [New Relic Nginx Integration](https://docs.newrelic.com/docs/infrastructure/host-integrations/host-integrations-list/nginx-monitoring-integration/)
- [New Relic PostgreSQL Integration](https://docs.newrelic.com/docs/infrastructure/host-integrations/host-integrations-list/postgresql-monitoring-integration/)
