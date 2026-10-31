# Docker Compose Mount Path Fix

## Problem Fixed
The `foodme-infra` container was failing to start due to a Docker mount path issue:
```
(HTTP code 500) server error - Mounts denied: The path /workspaces/foodme/newrelic-integrations is not shared from the host and is not known to Docker.
```

## Root Cause
The issue occurred because:
1. Different mount paths are needed for devcontainer vs regular Docker environments
2. The devcontainer runs with workspace mounted at `/workspaces/foodme/` instead of the local file system path

## Solutions Applied

### 1. Fixed Regular Docker Compose
Updated `docker/docker-compose.yml` to use the correct relative path:
```yaml
volumes:
  - "../newrelic-integrations:/etc/newrelic-infra/integrations.d:ro"
```

### 2. Fixed DevContainer Override
Updated `docker/docker-compose.devcontainer.yml` to handle devcontainer paths:
```yaml
newrelic-infra:
  volumes:
    - "/var/run/docker.sock:/var/run/docker.sock:ro"
    - "/:/host:ro"
    - "/workspaces/foodme/newrelic-integrations:/etc/newrelic-infra/integrations.d:ro"
```

## How to Run

### For Development (DevContainer)
```bash
# From the root directory (/workspaces/foodme/)
docker-compose -f docker/docker-compose.yml -f docker/docker-compose.devcontainer.yml up -d
```

### For Regular Docker Environment
```bash
# From the docker directory
cd docker/
docker-compose up -d

# Or from the root directory
docker-compose -f docker/docker-compose.yml up -d
```

## Optional: Disable New Relic in DevContainer
If you prefer to disable New Relic monitoring during development (recommended), uncomment these lines in `docker/docker-compose.devcontainer.yml`:
```yaml
newrelic-infra:
  profiles:
    - disabled
```

This will prevent the New Relic container from starting in the devcontainer environment while keeping it active in production deployments.