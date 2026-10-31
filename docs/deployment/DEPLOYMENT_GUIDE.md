# Deployment Quick Reference

This quick reference shows all the ways to deploy and manage the FoodMe application using the shared `.env` file.

## Node.js version

FoodMe runs on **Node.js 24**. Amazon Linux 2023 packages it as `nodejs24` and `nodejs24-npm`, so the install scripts (`terraform/user_data.sh`, `cloudformation/install-foodme.sh`) use Amazon's own repository, not NodeSource.

**New instances** get Node 24 from those scripts. For CloudFormation, upload the updated `install-foodme.sh` to the S3 bucket first, because instances download it at launch.

**An existing instance keeps the version it was built with.** cloud-init runs user data once, at first boot, so changing `user_data` in Terraform does not reinstall anything (it only makes `terraform apply` stop and start the instance). Upgrade a running instance by hand, before deploying the new code:

```bash
sudo dnf install -y nodejs24 nodejs24-npm
sudo alternatives --set node /usr/bin/node-24
node -v                                          # v24.x
cd /var/www/foodme/dist/server && sudo -u ec2-user npm install --omit=dev   # rebuilds native modules for the new Node
sudo systemctl restart foodme
sudo journalctl -u foodme -n 20
```

The service runs `/usr/bin/node`, which `alternatives` now points at Node 24. To go back, run `sudo alternatives --set node /usr/bin/node-22` (the older package stays installed) and restart the service. The CloudFormation layout uses `/opt/foodme` instead of `/var/www/foodme`.

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

- ✅ `.env` - Your actual secrets (from `.env.example`)
- ✅ `.env.example` - Template with placeholders
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
- ✅ Keep `.env.example` updated
- ✅ Never commit `.env` to git
- ✅ Use different credentials per environment
- ✅ Rotate API keys regularly
- ✅ Use Docker secrets for production
- ✅ Use runtime secrets, not build-time arguments
- ❌ Never use `ARG` for sensitive data in Dockerfiles
- ❌ Avoid build-time arguments for secrets (visible in image history)
