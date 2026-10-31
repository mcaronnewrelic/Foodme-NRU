# Docker Comprehensive Guide for FoodMe

This comprehensive guide covers all aspects of Docker usage in the FoodMe application, including setup, secrets management, and file organization.

## 📁 Docker File Organization

All Docker-related files are now organized in the `/docker/` directory for better project structure and maintainability.

### Files in `/docker/` Directory

#### Dockerfiles
- **`Dockerfile`** - Main application Dockerfile for production builds
- **`Dockerfile.secure`** - Security-hardened version with multi-stage build
- **`nginx.dockerfile`** - Custom Nginx reverse proxy configuration
- **`newrelic-infra.dockerfile`** - Custom New Relic Infrastructure agent
- **`Dockerfile.locust`** - Load testing with Locust

#### Docker Compose Files
- **`docker-compose.yml`** - Main production configuration
- **`docker-compose.dev.yml`** - Development environment overrides
- **`docker-compose.loadtest.yml`** - Load testing configuration

#### Other Files
- **`.dockerignore`** - Files and directories to exclude from Docker builds
- **`README.md`** - Quick reference guide for Docker operations

## 🏗️ Architecture Overview

The Docker Compose setup includes the following services:

1. **foodme** - Main FoodMe application (Node.js/Express)
2. **nginx** - Reverse proxy with HTTPS support
3. **db** - PostgreSQL database for data persistence
4. **newrelic-infra** - New Relic Infrastructure monitoring (optional)

## 🚀 Quick Start

### Prerequisites

1. **Docker and Docker Compose** installed
2. **Environment variables** configured
3. **SSL certificates** generated (for HTTPS)

### Basic Usage

```bash
# Start all services
docker-compose -f docker/docker-compose.yml up -d

# Start development environment
docker-compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up -d

# Run load tests
docker-compose -f docker/docker-compose.loadtest.yml run --rm locust

# Stop all services
docker-compose -f docker/docker-compose.yml down
```

### Using npm Scripts (Recommended)

All Docker operations are available via npm scripts:

```bash
# Build and deployment
npm run docker:build              # Build main application container
npm run docker:compose            # Start all services
npm run docker:compose:dev        # Start development environment
npm run docker:compose:prod       # Start production environment

# Load testing
npm run docker:compose:loadtest   # Run load tests

# Development utilities
npm run docker:dev:logs           # View development container logs
npm run docker:dev:down           # Stop development containers
```

## 📋 Service Details

### FoodMe Application (`foodme`)

- **Port**: 3000 (internal), exposed through nginx
- **Environment**: Uses `.env` file for configuration
- **Dependencies**: PostgreSQL database
- **Health**: Depends on database being healthy

**Build Configuration:**
```yaml
build:
  context: ..
  dockerfile: docker/Dockerfile
```

### Nginx Reverse Proxy (`nginx`)

- **Ports**: 
  - 80 (HTTP - redirects to HTTPS)
  - 443 (HTTPS)
- **SSL Certificates**: Located in `.setup/certs/`
- **Configuration**: `.setup/nginx/foodme.local.conf`
- **Health Check**: Built-in nginx health endpoint

**Build Configuration:**
```yaml
build:
  context: ..
  dockerfile: docker/nginx.dockerfile
```

### PostgreSQL Database (`db`)

- **Image**: `postgres:16-alpine`
- **Database**: `foodme`
- **User**: `foodme_user`
- **Password**: From environment variables or Docker secrets
- **Port**: 5432 (internal only)
- **Data**: Persisted in `db-data` volume
- **Initialization**: SQL scripts in `db/init/`

## 🔐 Secrets Management

### Secret Types Required

The FoodMe app requires these secrets:
- `NEW_RELIC_LICENSE_KEY` - Your New Relic license key
- `NEW_RELIC_API_KEY` - Your New Relic API key (for deployment tracking)  
- `NEW_RELIC_APP_NAME` - Application name in New Relic (optional)
- `POSTGRES_PASSWORD` - Database password

### 1. Development (Local with .env file)

Create a `.env` file in the project root:
```bash
# New Relic Configuration
NEW_RELIC_LICENSE_KEY=your_license_key_here
NEW_RELIC_API_KEY=your_api_key_here
NEW_RELIC_APP_NAME=FoodMe-Dev

# Database Configuration
POSTGRES_DB=foodme
POSTGRES_USER=foodme_user
POSTGRES_PASSWORD=your_secure_password
```

Run with:
```bash
npm run docker:compose
# or
docker-compose -f docker/docker-compose.yml up -d
```

### 2. Production (Environment Variables)

Export secrets as environment variables:
```bash
export NEW_RELIC_LICENSE_KEY="your_license_key_here"
export NEW_RELIC_API_KEY="your_api_key_here"
export NEW_RELIC_APP_NAME="FoodMe-Prod"
export POSTGRES_PASSWORD="your_secure_database_password"
```

Run with:
```bash
npm run docker:compose:prod
# or
docker-compose -f docker/docker-compose.yml up -d
```

### 3. Docker Swarm (Production)

For orchestration platforms, use Docker secrets:

```bash
# Create secrets
echo "your_license_key" | docker secret create new_relic_license_key -
echo "your_api_key" | docker secret create new_relic_api_key -
echo "secure_db_password" | docker secret create postgres_password -

# Deploy with secrets
docker stack deploy -c docker/docker-compose.yml foodme-stack
```

### 4. Cloud Platform Examples

**AWS ECS with Secrets Manager:**
```json
{
  "secrets": [
    {
      "name": "NEW_RELIC_LICENSE_KEY",
      "valueFrom": "arn:aws:secretsmanager:region:account:secret:prod/newrelic/license-key"
    }
  ]
}
```

**Kubernetes:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: newrelic-secrets
type: Opaque
data:
  license-key: <base64-encoded-license-key>
  api-key: <base64-encoded-api-key>
```

## 🛠️ Management Commands

### Service Management
```bash
# Start services
docker-compose -f docker/docker-compose.yml up -d

# Stop services
docker-compose -f docker/docker-compose.yml down

# Restart specific service
docker-compose -f docker/docker-compose.yml restart foodme

# View logs
docker-compose -f docker/docker-compose.yml logs -f foodme
```

### Database Management
```bash
# Connect to database
docker-compose -f docker/docker-compose.yml exec db psql -U foodme_user -d foodme

# Backup database
docker-compose -f docker/docker-compose.yml exec db pg_dump -U foodme_user foodme > backup.sql

# Restore database
cat backup.sql | docker-compose -f docker/docker-compose.yml exec -T db psql -U foodme_user -d foodme
```

### Building Individual Containers
```bash
# Main application
docker build -f docker/Dockerfile -t foodme:latest .

# Nginx reverse proxy
docker build -f docker/nginx.dockerfile -t foodme-nginx .

# New Relic Infrastructure
docker build -f docker/newrelic-infra.dockerfile -t foodme-newrelic .

# Load testing
docker build -f docker/Dockerfile.locust -t foodme-locust .
```

## 🔒 Security Features

### SSL/TLS
- **TLS 1.2/1.3 only**: Modern encryption protocols
- **Security headers**: HSTS, X-Frame-Options, etc.
- **Self-signed certificates**: For development (use Let's Encrypt for production)

### Database Security
- **Environment variables**: Secure password handling
- **No exposed ports**: Database not accessible from outside Docker network
- **User isolation**: Dedicated database user with limited privileges

### Network Security
- **Internal network**: Services communicate via Docker network
- **Reverse proxy**: Application not directly exposed
- **Health checks**: Automatic service monitoring

### Secret Security Best Practices

#### ✅ DO:
- Use environment variables for runtime secrets
- Use Docker secrets for orchestrated deployments
- Use `.env` files only for local development
- Store secrets in secure secret management systems
- Rotate secrets regularly
- Use least-privilege access principles

#### ❌ DON'T:
- Hardcode secrets in Dockerfiles
- Include secrets in Docker images
- Commit `.env` files to version control
- Pass secrets as build arguments for runtime secrets
- Use plain text files for secrets in production

## 📁 File Structure

```
├── docker/
│   ├── README.md                  # Quick Docker reference
│   ├── docker-compose.yml         # Main compose configuration
│   ├── docker-compose.dev.yml     # Development overrides
│   ├── docker-compose.loadtest.yml # Load testing setup
│   ├── Dockerfile                 # Main application container
│   ├── Dockerfile.secure          # Security-hardened container
│   ├── nginx.dockerfile           # Nginx reverse proxy
│   ├── newrelic-infra.dockerfile  # New Relic Infrastructure
│   ├── Dockerfile.locust          # Load testing container
│   └── .dockerignore              # Docker build exclusions
├── db/
│   └── init/
│       └── 01-init-schema.sql     # Database initialization
├── .setup/
│   ├── nginx/
│   │   └── foodme.local.conf      # Nginx configuration
│   └── certs/
│       ├── foodme.local.crt       # SSL certificate
│       └── foodme.local.key       # SSL private key
├── .env                           # Environment variables (local)
└── .env.example                   # Template for environment variables
```

## 🐛 Troubleshooting

### Common Issues

#### Services won't start
```bash
# Check logs
docker-compose -f docker/docker-compose.yml logs

# Check port conflicts
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :3000

# Recreate containers
docker-compose -f docker/docker-compose.yml down
docker-compose -f docker/docker-compose.yml up -d --force-recreate
```

#### SSL certificate errors
```bash
# Regenerate certificates
cd .setup
./mkcert -key-file certs/foodme.local.key -cert-file certs/foodme.local.crt foodme.local "*.foodme.local"

# Restart nginx
docker-compose -f docker/docker-compose.yml restart nginx
```

#### Database connection errors
```bash
# Check database logs
docker-compose -f docker/docker-compose.yml logs db

# Test database connection
docker-compose -f docker/docker-compose.yml exec db psql -U foodme_user -d foodme -c "SELECT version();"
```

#### New Relic Issues
- **"New Relic header is empty"**: Check that `NEW_RELIC_LICENSE_KEY` is set correctly
- **Agent not connecting**: Verify the key is valid and New Relic servers are reachable
- **Missing data**: Ensure the New Relic agent can write to the application directory

#### Load Testing Issues
```bash
# Check if services are running
docker-compose -f docker/docker-compose.yml ps

# Run load test manually
docker-compose -f docker/docker-compose.loadtest.yml run --rm locust \
  locust -f locustfile.py --host=http://foodme:3000 --headless -u 5 -r 1 -t 30s
```

## 🔧 Advanced Configuration

### Custom Domains
To use a different domain:
1. Update nginx configuration in `.setup/nginx/`
2. Regenerate SSL certificates for new domain
3. Update hosts file entry

### Production Deployment
For production use:
1. Use real SSL certificates (Let's Encrypt)
2. Configure proper database backups
3. Set up monitoring and logging
4. Use Docker secrets in swarm mode
5. Configure firewall rules

### Development vs Production
```bash
# Development (current setup)
docker-compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up -d

# Production (with all security features)
docker-compose -f docker/docker-compose.yml up -d

# Production with Docker Swarm
docker stack deploy -c docker/docker-compose.yml foodme
```

## 📊 Monitoring and Logging

### Health Checks
All services include health checks:
- **nginx**: HTTP endpoint check
- **database**: PostgreSQL ready check  
- **foodme**: Application-specific health check

### Centralized Logging
```bash
# Real-time logs for all services
docker-compose -f docker/docker-compose.yml logs -f

# Logs for specific service
docker-compose -f docker/docker-compose.yml logs -f foodme

# Logs with timestamp filter
docker-compose -f docker/docker-compose.yml logs --since "1h" --until "30m"
```

### New Relic Monitoring
The application includes New Relic APM integration:
- Application performance monitoring
- Error tracking and alerting
- Infrastructure monitoring (with newrelic-infra service)
- Custom metrics and dashboards

## 📝 Migration from Root Directory

This section documents the reorganization of Docker files:

### Files Moved to `/docker/` Directory
- `dockerfile` → `docker/Dockerfile`
- `dockerfile.secure` → `docker/Dockerfile.secure`
- `nginx.dockerfile` → `docker/nginx.dockerfile`
- `newrelic-infra.dockerfile` → `docker/newrelic-infra.dockerfile`
- `Dockerfile.locust` → `docker/Dockerfile.locust`
- `docker-compose.yml` → `docker/docker-compose.yml`
- `docker-compose.dev.yml` → `docker/docker-compose.dev.yml`
- `docker-compose.loadtest.yml` → `docker/docker-compose.loadtest.yml`
- `.dockerignore` → `docker/.dockerignore`

### Updated References
All scripts, documentation, and configuration files have been updated to reference the new paths. The reorganization maintains full functionality while providing better organization and maintainability.

## Benefits of Organized Structure

1. **Cleaner Root Directory** - All Docker files are organized in one place
2. **Better Project Structure** - Easier navigation and maintenance
3. **Consistent Documentation** - All references updated throughout the project
4. **Team Collaboration** - Clearer separation of concerns for different environments
5. **Easier Maintenance** - Docker configurations are centralized
6. **Improved Security** - Centralized secret management documentation
7. **Better CI/CD** - Simplified build and deployment workflows

This comprehensive setup provides a complete development and production environment with HTTPS, database persistence, monitoring, security best practices, and production-like architecture while maintaining ease of use for development.
