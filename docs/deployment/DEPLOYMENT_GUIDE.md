# Deployment Quick Reference

This quick reference shows all the ways to deploy and manage the FoodMe application using the shared `.env` file.

## Deploying with GitHub Actions

The **deploy-cloudformation** workflow deploys to AWS with CloudFormation. Run it from the Actions tab, or let it run by itself.

| Action | What it does | When it runs |
|---|---|---|
| `code` | Updates the running instance with the current server and Angular code, through AWS Systems Manager (no SSH). Builds Angular on the runner first, so a broken build stops before anything on the instance changes. Then it records a New Relic deployment marker. | By itself on a push to `main` that changes `server/` or `angular-app/` (staging). Or by hand. |
| `stack` | Creates or updates the CloudFormation stack `foodme-<environment>`: network, load balancer, EC2 instance, IAM role. | By hand only. A template change can interrupt the instance, so someone should choose it. |
| `delete-stack` | Deletes the stack. You must type `DELETE`. | By hand only. |

Pull requests that change `cloudformation/` get template and script checks only (`cfn-lint` and a syntax check). Nothing is deployed.

**Secrets:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `EC2_KEY_NAME` (an existing EC2 key pair in the region), `DB_PASSWORD`, `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_API_KEY` and `NEW_RELIC_APP_ID` (the entity GUID, for deployment markers). They can be set for the whole repository, or per GitHub environment (`staging`, `production`), which also lets you require approval before a deployment runs. The repository variable `AWS_REGION` is optional and defaults to `us-west-2`. The workflow no longer needs an SSH private key.

The same scripts run from your machine: `cloudformation/deploy-production.sh` for the stack and `cloudformation/deploy-code.sh -e staging` for the code. See [cloudformation/README.md](../../cloudformation/README.md).

## Removing a deployment

Use the `delete-stack` action, or:

```bash
aws cloudformation delete-stack --stack-name foodme-staging
aws cloudformation wait stack-delete-complete --stack-name foodme-staging
```

That removes everything the stack created. Two things stay behind, because the deployment script creates them outside the stack: the S3 bucket `foodme-deployments-<account>-<region>` with the deployment packages, and the EC2 key pair. Delete them yourself if you no longer need them. If a stack will not delete, `aws cloudformation describe-stack-events --stack-name foodme-staging` shows the resource that is blocking it. The older Terraform cleanup guide is in [archive/terraform](../../archive/terraform/CLEANUP_GUIDE.md).

## Node.js version

FoodMe runs on **Node.js 24**. Amazon Linux 2023 packages it as `nodejs24` and `nodejs24-npm`, so `cloudformation/install-foodme.sh` installs it from Amazon's own repository, not from NodeSource.

**New instances** get Node 24 from that script. The instance downloads it from the deployment S3 bucket at first boot, and the `stack` action uploads the current copy.

**An existing instance keeps the version it was built with.** The install script runs once, at first boot, so changing it does not touch a running instance. The staging instance built on 2026-10-31 is on Node 22. You have two ways to move it:

1. **Replace it (recommended).** Run `delete-stack`, then `stack`. It builds the same instance from scratch on Node 24 in a few minutes. The database is rebuilt from the initialization scripts, so anything stored only on the old instance is lost.
2. **Upgrade it in place.** This has not been tested on a running instance, so if anything looks wrong, use option 1.
   ```bash
   sudo dnf install -y nodejs24 nodejs24-npm
   sudo alternatives --set node /usr/bin/node-24
   node -v                                                   # v24.x
   sudo npm install -g pm2                                   # PM2 was installed under Node 22
   cd /opt/foodme/backend && sudo -u ec2-user npm install --omit=dev
   sudo -u ec2-user pm2 kill
   sudo -u ec2-user pm2 start ecosystem.config.js && sudo -u ec2-user pm2 save
   curl -s http://localhost:3000/health
   ```
   To go back: `sudo alternatives --set node /usr/bin/node-22`, then restart PM2 the same way.

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
