# Secret Management Guide

This guide covers the best practices for managing secrets (API keys, tokens, etc.) in the FoodMe application across different environments.

## Quick Start

1. **Setup your environment file:**
   ```bash
   npm run setup:env
   # Edit .env with your actual values
   ```

2. **Run with secrets (recommended):**
   ```bash
   npm run docker:with-secrets
   ```

## Methods for Adding Secrets to Docker

### 1. 🔒 Runtime Secrets with .env File (RECOMMENDED)

**Best for:** Development and production deployments

```bash
# Build the image
docker build -t foodme:latest .

# Run with .env file
docker run -p 3000:3000 --env-file .env foodme:latest
```

**Pros:**
- ✅ Secrets never embedded in image
- ✅ Easy to manage and update
- ✅ Works well with Docker Compose
- ✅ Secure - secrets only in container environment at runtime

**Cons:**
- ❌ .env file must be present on host
- ❌ Secrets visible in container environment (but not in image)

### 2. 🐳 Docker Compose with .env

**Best for:** Multi-service applications and development

```bash
# Using docker-compose
docker-compose up --build

# Or specific service
docker-compose up --build foodme
```

**Pros:**
- ✅ Easy service orchestration
- ✅ Automatic .env file loading
- ✅ Good for development environments
- ✅ Secrets managed at runtime only

### 3. 🔐 Docker Secrets (Production)

**Best for:** Docker Swarm and production environments

```bash
# Create secrets
echo "your_license_key" | docker secret create new_relic_license_key -
echo "your_api_key" | docker secret create new_relic_api_key -

# Deploy with secrets
docker-compose up --build foodme-with-secrets
```

**Pros:**
- ✅ Most secure method
- ✅ Secrets encrypted at rest
- ✅ Granular access control
- ✅ Never visible in image or build history

**Cons:**
- ❌ Requires Docker Swarm
- ❌ More complex setup

### ❌ What We DON'T Recommend

**Build-time Arguments (SECURITY RISK):**
```bash
# DON'T DO THIS - Insecure!
docker build --build-arg NEW_RELIC_API_KEY="secret" .
```

**Why this is bad:**
- ❌ Secrets visible in image history (`docker history`)
- ❌ Secrets embedded in image layers
- ❌ Can be extracted from built images
- ❌ Violates security best practices

## Environment Variables

The application uses these environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `NEW_RELIC_LICENSE_KEY` | ✅ | New Relic account license key |
| `NEW_RELIC_API_KEY` | ✅ | New Relic API key for deployments |
| `NEW_RELIC_APP_NAME` | ❌ | App name in New Relic (default: FoodMe-App) |
| `NODE_ENV` | ❌ | Node environment (default: development) |

## Security Best Practices

### ✅ DO
- Use `.env` files for local development
- Use Docker secrets for production
- Set proper file permissions on `.env` files (`chmod 600 .env`)
- Use different secrets for different environments
- Rotate secrets regularly
- Use secret management services (AWS Secrets Manager, Azure Key Vault, etc.)

### ❌ DON'T
- Commit `.env` files to version control
- Use build-time args for sensitive data in production
- Store secrets in environment variables in production
- Use the same secrets across environments
- Log or print secret values

## Validation

Check if your environment is properly configured:

```bash
# Validate .env file exists
npm run validate:env

# Test the application with secrets
npm run docker:with-secrets
```

## Troubleshooting

### Common Issues

1. **`.env file not found`**
   ```bash
   npm run setup:env
   # Then edit .env with actual values
   ```

2. **Placeholder values in .env**
   - Make sure to replace `your_newrelic_api_key_here` with actual values

3. **Permission denied on scripts**
   ```bash
   chmod +x run-with-secrets.sh
   chmod +x docker-build.sh
   ```

4. **Container fails to start**
   ```bash
   # Check logs
   docker logs foodme-app
   
   # Verify environment variables
   docker exec foodme-app env | grep NEW_RELIC
   ```

## Production Deployment

For production deployments, consider:

1. **Cloud-native secret management:**
   - AWS: Secrets Manager, Parameter Store
   - Azure: Key Vault
   - GCP: Secret Manager
   - Kubernetes: Secrets

2. **Environment-specific configuration:**
   ```bash
   # Production
   NODE_ENV=production docker-compose -f docker-compose.prod.yml up
   
   # Staging
   NODE_ENV=staging docker-compose -f docker-compose.staging.yml up
   ```

3. **Secret rotation strategy:**
   - Implement automated secret rotation
   - Use versioned secrets
   - Monitor secret usage and access

## Additional Resources

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [New Relic Configuration](https://docs.newrelic.com/docs/apm/agents/nodejs-agent/installation-configuration/nodejs-agent-configuration/)
