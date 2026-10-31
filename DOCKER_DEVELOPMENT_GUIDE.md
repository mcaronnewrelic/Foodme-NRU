# FoodMe Docker Development Guide

## Quick Start for Mac with Rancher Desktop

**New to this project? Follow this simple 3-step process:**

### 1. Prerequisites
- Install [Rancher Desktop](https://rancherdesktop.io/) (recommended for Mac)
- Clone this repository
- Copy `.env.example` to `.env` and edit with your settings

### 2. Choose Your Development Style

#### Option A: Simple Development (Recommended for Beginners)
Just the app and database - perfect for getting started:
```bash
npm run docker:dev:simple
```

#### Option B: Full Local Production Simulation
All services including monitoring - for advanced development:
```bash
npm run docker:dev:full
```

### 3. Access Your Application
- **Main App**: http://localhost (via nginx proxy)
- **Direct App**: http://localhost:3000 (direct to Node.js)
- **Health Check**: http://localhost/health
- **API**: http://localhost/api/restaurant

---

## Understanding the Options

### Simple Development Setup
- **What runs**: Node.js app + PostgreSQL database + nginx proxy
- **Best for**: Learning, feature development, debugging
- **Resources**: Low CPU/memory usage
- **Startup time**: ~30 seconds

### Full Production Simulation
- **What runs**: Everything above + New Relic monitoring simulation
- **Best for**: Testing monitoring, production-like debugging
- **Resources**: Higher CPU/memory usage  
- **Startup time**: ~60 seconds

---

## Common Commands

```bash
# Start simple development environment
npm run docker:dev:simple

# Start full production simulation
npm run docker:dev:full

# Check what's running
npm run docker:status

# View logs
npm run docker:logs

# Stop everything
npm run docker:stop

# Clean up containers and volumes
npm run docker:clean
```

---

## Troubleshooting

### If containers won't start:
1. Make sure Rancher Desktop is running
2. Check if ports 80, 443, 3000, 5432 are free
3. Try: `npm run docker:clean` then start again

### If you see "SSL certificate" errors:
This is normal on ARM64 Macs - the setup automatically handles this.

### If the database won't connect:
1. Wait 30 seconds for PostgreSQL to fully start
2. Check logs: `npm run docker:logs`
3. Reset database: `npm run docker:clean` then restart

---

## Development Workflow

1. **Start**: `npm run docker:dev:simple`
2. **Develop**: Edit code - changes auto-reload in simple mode
3. **Test**: Visit http://localhost to see your changes
4. **Debug**: Use `npm run docker:logs` to see what's happening
5. **Stop**: `npm run docker:stop` when done

---

## File Structure (What You Need to Know)

```
docker/
├── docker-compose.dev-simple.yml   # Simple development setup
├── docker-compose.arm64.yml        # Full production simulation (ARM64)
├── Dockerfile.simple               # Simple Node.js build
└── Dockerfile.arm64                # Full production build
```

**You typically don't need to modify these files.** Use the npm scripts instead.

---

## Advanced: Direct Docker Commands

If you prefer using Docker directly:

```bash
# Simple setup
docker-compose -f docker/docker-compose.dev-simple.yml up -d

# Full setup
docker-compose -f docker/docker-compose.arm64.yml up -d

# Status
docker-compose -f docker/docker-compose.dev-simple.yml ps

# Logs
docker-compose -f docker/docker-compose.dev-simple.yml logs -f

# Stop
docker-compose -f docker/docker-compose.dev-simple.yml down
```