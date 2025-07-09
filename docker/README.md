# Docker Configuration Files

This directory contains all Docker-related configuration files for the FoodMe application.

## Files Overview

### Dockerfiles
- **`Dockerfile`** - Main application Dockerfile for production builds
- **`Dockerfile.secure`** - Security-hardened version with multi-stage build
- **`nginx.dockerfile`** - Custom Nginx reverse proxy configuration
- **`newrelic-infra.dockerfile`** - Custom New Relic Infrastructure agent
- **`Dockerfile.locust`** - Load testing with Locust

### Docker Compose Files
- **`docker-compose.yml`** - Main production configuration
- **`docker-compose.dev.yml`** - Development environment overrides
- **`docker-compose.loadtest.yml`** - Load testing configuration

### Other Files
- **`.dockerignore`** - Files and directories to exclude from Docker builds

## Quick Start

### Production Deployment
```bash
cd docker
docker-compose up -d
```

### Development Environment
```bash
cd docker
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Load Testing
```bash
cd docker
docker-compose -f docker-compose.loadtest.yml run --rm locust
```

## Environment Variables

Make sure to set up your environment variables in a `.env` file in the project root:

```bash
# New Relic Configuration
NEW_RELIC_LICENSE_KEY=your_license_key
NEW_RELIC_API_KEY=your_api_key
NEW_RELIC_APP_NAME=FoodMe-App

# Database Configuration
POSTGRES_DB=foodme
POSTGRES_USER=foodme_user
POSTGRES_PASSWORD=your_secure_password
```

For more detailed information, see the main project documentation files:
- [Setup Guide](../SETUP_GUIDE.md)
- [Docker Comprehensive Guide](../DOCKER_COMPREHENSIVE_GUIDE.md)
- [Deployment Guide](../DEPLOYMENT_GUIDE.md)
