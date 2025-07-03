# Docker Secrets Management for FoodMe App

This guide covers the best practices for handling secrets in Docker deployments of the FoodMe application.

## 🔐 Secret Types Required

The FoodMe app requires these secrets:
- `NEW_RELIC_LICENSE_KEY` - Your New Relic license key
- `NEW_RELIC_API_KEY` - Your New Relic API key (for deployment tracking)
- `NEW_RELIC_APP_NAME` - Application name in New Relic (optional, defaults to "FoodMe-App")

## 🚀 Deployment Methods

### 1. Development (Local with .env file)

Create a `.env` file in the project root:
```bash
NEW_RELIC_LICENSE_KEY=your_license_key_here
NEW_RELIC_API_KEY=your_api_key_here
NEW_RELIC_APP_NAME=FoodMe-Dev
```

Run with:
```bash
npm run docker:run
# or
docker run -p 3000:3000 --env-file .env foodme:latest
```

### 2. Production (Environment Variables)

Export secrets as environment variables:
```bash
export NEW_RELIC_LICENSE_KEY="your_license_key_here"
export NEW_RELIC_API_KEY="your_api_key_here"
export NEW_RELIC_APP_NAME="FoodMe-Prod"
```

Run with:
```bash
npm run docker:run:prod
# or
docker run -p 3000:3000 \
  -e NODE_ENV=production \
  -e NEW_RELIC_LICENSE_KEY="$NEW_RELIC_LICENSE_KEY" \
  -e NEW_RELIC_API_KEY="$NEW_RELIC_API_KEY" \
  -e NEW_RELIC_APP_NAME="$NEW_RELIC_APP_NAME" \
  foodme:latest
```

### 3. Docker Compose (Recommended)

Use the included `docker-compose.yml`:
```bash
npm run docker:compose:prod
# or
docker-compose up --build foodme
```

### 4. Docker Swarm/Kubernetes (Production)

For orchestration platforms, use their secret management:

**Docker Swarm:**
```bash
# Create secrets
echo "your_license_key" | docker secret create new_relic_license_key -
echo "your_api_key" | docker secret create new_relic_api_key -

# Deploy with secrets
docker stack deploy -c docker-compose.yml foodme-stack
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

## 🛡️ Security Best Practices

### ✅ DO:
- Use environment variables for runtime secrets
- Use Docker secrets for orchestrated deployments
- Use `.env` files only for local development
- Store secrets in secure secret management systems (AWS Secrets Manager, Azure Key Vault, etc.)
- Rotate secrets regularly
- Use least-privilege access principles

### ❌ DON'T:
- Hardcode secrets in Dockerfiles
- Include secrets in Docker images
- Commit `.env` files to version control
- Pass secrets as build arguments for runtime secrets
- Use plain text files for secrets in production

## 📝 Available npm Scripts

```bash
# Docker build and run commands
npm run docker:build          # Build Docker image
npm run docker:run            # Run with .env file (development)
npm run docker:run:prod       # Run with environment variables (production)
npm run docker:compose        # Run with docker-compose
npm run docker:compose:prod   # Run production service with docker-compose

# Standard application commands
npm run dev                   # Local development
npm run start                 # Development with build
npm run start:prod            # Production mode
npm run build                 # Build for production
```

## 🔍 Debugging

The application logs environment detection and paths:
```bash
Environment: production
Angular dist directory: /foodme/app/browser
New Relic agent state: { hasLicenseKey: true, agentVersion: '12.21.0', headerLength: 1234 }
```

## 📋 Troubleshooting

### Issue: "New Relic header is empty"
- Check that `NEW_RELIC_LICENSE_KEY` is set correctly
- Verify the key is valid and active
- Ensure the New Relic agent can connect to New Relic servers

### Issue: "Error loading application"
- Check that the Angular build completed successfully
- Verify the dist directory structure exists
- Check file permissions in the Docker container

### Issue: Docker secrets not working
- Ensure secrets are created before deployment
- Check secret names match the configuration
- Verify the service has access to the secrets

## 🌐 Cloud Platform Examples

### AWS ECS with Secrets Manager
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

### Azure Container Instances
```yaml
containers:
- name: foodme
  properties:
    environmentVariables:
    - name: NEW_RELIC_LICENSE_KEY
      secureValue: "your-license-key"
```

### Google Cloud Run
```bash
gcloud run deploy foodme \
  --image gcr.io/project/foodme \
  --set-env-vars NEW_RELIC_APP_NAME=FoodMe-Prod \
  --set-secrets NEW_RELIC_LICENSE_KEY=newrelic-license:latest
```
