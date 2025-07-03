# Deployment Quick Reference

This quick reference shows all the ways to deploy and manage the FoodMe application using the shared `.env` file.

## 🚀 One-Command Deployments

| Command | Description |
|---------|-------------|
| `npm run deploy` | **Full deployment workflow** - builds, marks deployment, asks to start |
| `npm run docker:with-secrets` | **Docker deployment with secrets** - interactive script |
| `docker-compose up --build` | **Docker Compose** - automatically loads .env file |

## 🔧 Individual Components

| Command | Description |
|---------|-------------|
| `npm run deploy:build` | Build only (no deployment marker) |
| `npm run deploy:marker` | Send deployment marker only |
| `npm run deploy:start` | Start application only |
| `npm run deploy:test` | Run load tests |

## 📋 Environment Setup

| Command | Description |
|---------|-------------|
| `npm run setup:env` | Create .env from template |
| `npm run validate:env` | Check if .env exists |
| `./deploy.sh --help` | Show detailed help |

## 🐳 Docker Options

| Method | Command | Use Case | Security Level |
|--------|---------|----------|----------------|
| **Runtime secrets** | `docker run --env-file .env foodme:latest` | ✅ Recommended | 🔒 High |
| **Compose** | `docker-compose up --build` | Multi-service | 🔒 High |
| **Secrets** | `docker-compose up --build foodme-with-secrets` | Production | 🔐 Highest |

## 📁 Required Files

- ✅ `.env` - Your actual secrets (from `.env.template`)
- ✅ `.env.template` - Template with placeholders
- ✅ `deploy.sh` - Main deployment script
- ✅ `docker-compose.yml` - Container orchestration

## 🔑 Environment Variables in .env

```bash
# Required for deployment markers
NEW_RELIC_API_KEY="NRAK-..."        # User API key from New Relic
ENTITY_GUID="MTM1MjgxMX..."          # Application Entity GUID

# Required for APM agent
NEW_RELIC_LICENSE_KEY="515d3eb..."   # Account license key
NEW_RELIC_APP_NAME="FoodMe"          # App name in New Relic
```

## 🎯 Common Workflows

### First Time Setup
```bash
npm run setup:env      # Create .env file
# Edit .env with actual values
npm run validate:env    # Verify setup
npm run deploy         # Full deployment
```

### Development
```bash
npm run deploy:build   # Build only
npm start             # Start locally
npm run deploy:test   # Run load tests
```

### Production Docker
```bash
npm run docker:with-secrets  # Interactive deployment
# OR
docker-compose up --build    # Compose deployment
```

### CI/CD Pipeline
```bash
# In your CI/CD system, set environment variables then:
./deploy.sh --build          # Build only
./deploy.sh --marker         # Mark deployment
# Deploy to production...
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| `.env not found` | `npm run setup:env` |
| `placeholder values` | Edit .env with real credentials |
| `permission denied` | `chmod +x deploy.sh run-with-secrets.sh` |
| `deployment marker fails` | Check NEW_RELIC_API_KEY and ENTITY_GUID |

## 🌟 Best Practices

- ✅ Use `.env` file for all environments
- ✅ Keep `.env.template` updated
- ✅ Never commit `.env` to git
- ✅ Use different credentials per environment
- ✅ Rotate API keys regularly
- ✅ Use Docker secrets for production
- ✅ Use runtime secrets, not build-time arguments
- ❌ Never use `ARG` for sensitive data in Dockerfiles
- ❌ Avoid build-time arguments for secrets (visible in image history)
