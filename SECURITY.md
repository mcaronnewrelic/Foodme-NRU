# Security Documentation - FoodMe Application

## Overview
This document outlines the security measures implemented in the FoodMe application to protect sensitive information and follow security best practices.

## Secret Management

### Environment Variables
All sensitive configuration is managed through environment variables:

- `NEW_RELIC_LICENSE_KEY`: New Relic monitoring license key
- `NEW_RELIC_API_KEY`: New Relic API key for deployments
- `NODE_ENV`: Application environment (production/development)
- `PORT`: Application port (defaults to 3000)

### Configuration Files
- **`.env.example`**: Template file showing required environment variables
- **`.env`**: Local environment file (excluded from version control)
- **`.env.local`**: Additional local environment overrides (excluded from version control)

## File Exclusions

### Version Control (.gitignore)
The following sensitive files are excluded from Git:
```
.env
.env.local
newrelic_agent.log
```

### Docker Build Context (.dockerignore)
The following files are excluded from Docker builds:
```
**/.env
**/.env.local
**/newrelic_agent.log
**/*.log
```

## Docker Security

### Multi-stage Build
- Uses multi-stage Docker build to minimize final image size
- Separates build dependencies from runtime dependencies
- Only production dependencies are included in final image

### User Security
- Runs as non-root user (`node`) in production container
- Uses minimal `node:22-slim` base image for production

### Build Security
- No hardcoded secrets in Dockerfile
- Uses environment variables for runtime configuration
- Excludes sensitive files via .dockerignore

## Source Code Security

### New Relic Configuration
- License key sourced from environment variable: `process.env.NEW_RELIC_LICENSE_KEY`
- No hardcoded credentials in source code
- Proper header exclusions for sensitive data

### Dependencies
- Production dependencies separated from development dependencies
- Regular security audits via `npm audit`
- Minimal dependency footprint in production

## Security Validation

### Automated Checks
The `validate-security.sh` script performs comprehensive security validation:

1. **Dockerfile Security**
   - Checks for hardcoded secrets in ARG instructions
   - Validates ENV instructions don't contain hardcoded credentials

2. **Build Script Security**
   - Ensures no --build-arg with secrets in shell scripts

3. **Docker Compose Security**
   - Validates build args don't contain sensitive data

4. **Source Code Security**
   - Scans for hardcoded license keys, API keys, and secrets
   - Excludes node_modules and dist directories from scanning

5. **File Security**
   - Ensures .env files are properly excluded from Docker context
   - Validates .env files are gitignored

### Docker Security Linting
- Uses Hadolint for Dockerfile security best practices
- Run via: `npm run security:docker`

## Deployment Security

### Environment Variable Injection
Scripts properly handle environment variables:
- `docker:run`: Uses --env-file .env for local development
- `docker:run:prod`: Uses explicit environment variables for production

### Deployment Validation
- `validate-loadtest.sh`: Ensures .env file exists before deployment
- `deploy.sh`: Includes environment validation steps

## Best Practices Implemented

1. **Never commit secrets**: All sensitive data via environment variables
2. **Principle of least privilege**: Non-root user in containers
3. **Minimal attack surface**: Slim base images, production-only dependencies
4. **Defense in depth**: Multiple layers of exclusion (.gitignore, .dockerignore)
5. **Automated validation**: Security checks in CI/CD pipeline
6. **Documentation**: Clear examples and templates for configuration

## Usage

### Setup Environment
1. Copy template: `cp .env.example .env`
2. Edit with actual values: `nano .env`
3. Validate setup: `npm run validate:env`

### Run Security Checks
```bash
# Full security validation
npm run security:validate

# Docker-specific security checks
npm run security:docker
```

### Deployment
```bash
# Local development
npm run docker:run

# Production deployment
npm run deploy
```

## Security Monitoring

### New Relic Security
- Browser monitoring enabled with security headers excluded
- Custom attributes exclude sensitive request/response headers
- Transaction tracing with appropriate filtering

### Log Security
- Sensitive headers excluded from logging
- New Relic agent logs excluded from version control
- Structured logging via Pino

## Incident Response

In case of security incidents:
1. Rotate affected credentials immediately
2. Update environment variables in deployment environment
3. Re-deploy application with new credentials
4. Review logs for potential data exposure
5. Run security validation to ensure compliance

---

**Last Updated**: July 3, 2025
**Security Review**: Comprehensive audit completed - all checks passing
