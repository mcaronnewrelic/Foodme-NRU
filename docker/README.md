# Docker files

What each file in this folder is for. To run the app, use [DOCKER_DEVELOPMENT_GUIDE.md](../DOCKER_DEVELOPMENT_GUIDE.md) and its npm scripts. If something breaks, see the [Docker Comprehensive Guide](../docs/troubleshooting/DOCKER_COMPREHENSIVE_GUIDE.md).

## Compose files

| File | Runs | Start it with |
|---|---|---|
| `docker-compose.dev-simple.yml` | App, PostgreSQL 16, nginx | `npm run docker:dev:simple` |
| `docker-compose.arm64.yml` | App, nginx, PostgreSQL with monitoring, New Relic infrastructure agent stand-in | `npm run docker:dev:full` |

## Dockerfiles

| File | Builds |
|---|---|
| `Dockerfile.simple` | The Node app for the simple setup (server code only; the Angular build is mounted from `dist/`) |
| `Dockerfile.arm64` | The Node app for the full setup, on ARM64 |
| `Dockerfile` | A multi-stage production build of the Node app |
| `nginx.dockerfile` | nginx reverse proxy |
| `postgres-monitoring.dockerfile` | PostgreSQL with the monitoring extensions |
| `newrelic-infra.arm64.dockerfile` | A minimal ARM64-compatible stand-in for the infrastructure agent, for local development |

`newrelic-integrations/` holds the integration configuration mounted into the infrastructure container. See [newrelic-integrations/README.md](../newrelic-integrations/README.md).

## Archive

`archive/` keeps the earlier compose files and Dockerfiles (`docker-compose.yml`, the dev and devcontainer overrides, the load test setup, and the security-hardened Dockerfile). They are not maintained, and documents that refer to them may be out of date.

## Environment

Both compose files read `../.env`. See [Environment Variables](../docs/setup/ENVIRONMENT_VARIABLES.md).
