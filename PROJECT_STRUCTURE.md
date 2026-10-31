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