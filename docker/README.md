# Docker Configuration for FoodMe

## For New Developers - Quick Start

**Use the npm scripts from the main directory instead of Docker commands directly:**

```bash
# Start simple development environment (recommended)
npm run docker:dev:simple

# Start full production simulation
npm run docker:dev:full

# Check status
npm run docker:status

# View logs
npm run docker:logs

# Stop everything
npm run docker:stop
```

## Development Files (Use These)

### For Daily Development
- **`docker-compose.dev-simple.yml`** - Lightweight setup (app + database + nginx)
- **`Dockerfile.simple`** - Basic Node.js application build

### For Production Testing
- **`docker-compose.arm64.yml`** - Full production simulation with monitoring
- **`Dockerfile.arm64`** - Production-ready build for ARM64 (Apple Silicon)

### Supporting Files
- **`nginx.dockerfile`** - Nginx reverse proxy configuration
- **`postgres-monitoring.dockerfile`** - PostgreSQL with monitoring extensions
- **`newrelic-infra.arm64.dockerfile`** - New Relic monitoring simulation

## Architecture Overview

### Simple Development Setup
```
Browser → nginx:80 → foodme:3000 → postgres:5432
```

### Full Production Simulation
```
Browser → nginx:80/443 → foodme:3000 → postgres:5432
                                   ↗ newrelic-infra (monitoring)
```

## Advanced Configuration

If you need to modify Docker settings, see the archived configurations in `archive/` folder.

## Troubleshooting

### Common Issues on Mac:
- **SSL Certificate Errors**: Normal on ARM64 - automatically handled
- **Port Conflicts**: Stop other services using ports 80, 443, 3000, 5432
- **Slow Startup**: Wait 30-60 seconds for all services to initialize

### Reset Everything:
```bash
npm run docker:clean
```

## Environment Variables

Make sure you have a `.env` file in the root directory. Copy from `.env.example` if needed.

Required variables:
- `NEW_RELIC_LICENSE_KEY` - For monitoring (get from New Relic)
- `DB_PASSWORD` - Database password (auto-generated if not set)

# Database Configuration
POSTGRES_DB=foodme
POSTGRES_USER=foodme_user
POSTGRES_PASSWORD=your_secure_password
```

For more detailed information, see the main project documentation files:
- [Setup Guide](../docs/setup/SETUP_GUIDE.md)
- [Docker Comprehensive Guide](../docs/troubleshooting/DOCKER_COMPREHENSIVE_GUIDE.md)
- [Deployment Guide](../docs/deployment/DEPLOYMENT_GUIDE.md)
