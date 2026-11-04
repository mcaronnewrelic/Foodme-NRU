# FoodMe Project Structure

This document explains the clean, organized structure of the FoodMe project.

## 📁 Root Directory Overview

```
foodme/
├── README.md                    # 👈 START HERE - Project overview and quick start
├── DOCKER_DEVELOPMENT_GUIDE.md # 🐳 Complete Docker development guide
├── package.json                # 📦 Main project dependencies and scripts
├── .env.example                # 🔧 Environment variables template
│
├── angular-app/                # 🅰️ Angular frontend application
├── server/                     # 🌐 Node.js backend server
├── docker/                     # 🐳 Docker configurations (simplified)
├── scripts/                    # 🔧 Deployment and utility scripts
│   ├── deploy.sh              # 🚀 Main deployment script
│   ├── deploy-simple.sh       # 🚀 Simple deployment script
│   └── archive/               # 📚 Legacy scripts and tools
│
├── docs/                       # 📚 Organized documentation
│   ├── README.md              # 📋 Documentation index
│   ├── setup/                 # 🛠️ Setup and configuration guides
│   ├── deployment/            # 🚀 Deployment documentation
│   ├── troubleshooting/       # 🔧 Problem-solving guides
│   └── *.md                   # 📊 Monitoring, security, testing docs
│
├── cloudformation/             # ☁️ AWS CloudFormation templates
├── archive/                    # 🗄️ Retired code kept for reference (Terraform)
├── nginx-config/              # 🌐 Nginx reverse proxy configuration
├── newrelic-integrations/     # 📊 New Relic monitoring configuration
└── db/                        # 🗄️ Database initialization and scripts
```

## 🎯 For New Developers

**Quick Start Path:**
1. **README.md** - Overview and context
2. **DOCKER_DEVELOPMENT_GUIDE.md** - Get up and running quickly
3. **docs/README.md** - Find specific documentation as needed

## 🗂️ What Was Cleaned Up

### Moved to `docs/`:
- All setup guides and configuration documentation
- Deployment guides and troubleshooting
- Monitoring and security documentation
- ARM64 and Docker technical documentation

### Moved to `scripts/archive/`:
- Legacy setup scripts (setup.sh, docker-setup.sh, etc.)
- Complex deployment and validation scripts
- Load testing and development container scripts
- Python load testing files

### Removed:
- Python cache files (__pycache__)
- Virtual environments (.venv, venv)
- Log files (newrelic_agent.log)
- Temporary files

## Backend Construction And Startup

`server/index.js` exports `createApp(dependencies)`, which returns the configured Express app without listening, registering process handlers, loading restaurant data, synchronizing demo side effects, or starting the order-status worker. It keeps Pino request logging and New Relic instrumentation.

The optional dependency object accepts `storage`, `dbService`, `useDatabase`, `logger`, `newrelic`, `demoFailures`, `demoInvestigations`, `dashboardLinks`, `environment`, `staticDir`, and `angularDistDir`. Defaults use the normal services and process environment; injected storage should already contain its restaurant data.

Route factories live in `server/routes/` and receive their services explicitly:

- `restaurant.js`: mounted at `/api/restaurant`, including the demo socket-failure middleware.
- `order.js`: mounted at `/api`, serving `/order` checkout and `/orders` lookups.
- `demo.js`: mounted at `/api`, serving demo controls, `/nr-config`, and `/dashboard`.
- `simulation.js`: mounted at `/simulate`, with memory-leak state isolated per router instance.

Middleware factories live in `server/middleware/`:

- `request-tracing.js`: request IDs and request/response logging, registered first.
- `angular-fallback.js`: serves Angular's `index.html` for non-API routes and injects the New Relic browser timing header.
- `error-handler.js`: the global error handler, registered last, after all routers and the Angular fallback.

`server/index.js` wires these together with the static file serving and `/health`. Public endpoint URLs remain unchanged.

`server/start.js` is the entry point and owns the lifecycle: `start(PORT, STATIC_DIR, DATA_FILE)` checks the database, loads JSON data when needed, constructs the app, starts the listener and worker, and handles process signals. Tests can import `server/index.js` and call `createApp` without starting the application.

Live order tracking hangs off that lifecycle: `server/order-status-stream.js` is a WebSocket endpoint (`/api/orders/stream`, under `/api/` because the nginx `/api/` location already forwards the Upgrade headers). `start.js` attaches it to the HTTP server and wires the worker's `onAdvance` callback to it, so each committed batch pushes the changed orders' new statuses to subscribed browsers; a subscribe first answers with a snapshot read through the app's `getOrderById`. On the client, `OrderStatusService` owns the channel (REST seed, socket pushes, polling fallback) and persists the tracked order so the header's status pill follows it across pages.

## 🎨 Design Principles

1. **Root Directory**: Only essential files for getting started
2. **Documentation**: Organized by purpose in `/docs/`
3. **Scripts**: Grouped in `/scripts/` with archive for legacy
4. **Configuration**: Clear separation by service (docker/, nginx-config/, etc.)
5. **No Clutter**: Temporary files, logs, and caches properly ignored

## 🚀 Quick Commands

```bash
# Start developing (most common)
npm run docker:dev:simple

# View documentation index
open docs/README.md

# Deploy to AWS
./scripts/deploy.sh

# Check project status
npm run docker:status
```

This structure eliminates confusion for new developers while keeping all advanced functionality accessible for experienced users.