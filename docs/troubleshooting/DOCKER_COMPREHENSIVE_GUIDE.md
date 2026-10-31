# Docker Comprehensive Guide

Reference and troubleshooting for FoodMe's Docker setups. To get the app running, start with the [Docker Development Guide](../../DOCKER_DEVELOPMENT_GUIDE.md). For what each file in `docker/` does, see [docker/README.md](../../docker/README.md).

## Services

| Service | Container | Simple | Full | Notes |
|---|---|---|---|---|
| `foodme` | `foodme-app` | yes | yes | Node/Express app on port 3000. Reads `../.env`. Serves the Angular build from the mounted `dist/`. |
| `nginx` | `foodme-nginx` | yes | yes | Reverse proxy. Port 80 (`HTTP_PORT` in simple, `NGINX_PORT` in full). The full setup also maps 443 (`NGINX_SSL_PORT`). |
| `db` | `foodme-db` | yes | yes | PostgreSQL 16. Port 5432 is open to other containers only, not to your machine. Data lives in the `db-data` volume. |
| `newrelic-infra` | `foodme-infra` | no | yes | A minimal stand-in for the infrastructure agent. |

The database is created from `db/init/01-init-schema.sql` and `db/init/02-import-restaurants-uuid.sql`. Docker runs those only when the `db-data` volume is first created. To run them again, use `npm run docker:clean` and start again. That deletes the data.

## Secrets and configuration

Both compose files pass `../.env` to the containers with `env_file`, so the same file configures local Docker and the npm scripts. Keep it out of git. For how to handle keys and passwords, see [Secret Management](../setup/SECRET_MANAGEMENT.md). For the variables themselves, see [Environment Variables](../setup/ENVIRONMENT_VARIABLES.md) and `.env.example`.

- A container reads `.env` once, when it is created. After editing it, recreate the container with `up -d --force-recreate`.
- Do not put secrets in Dockerfiles, build arguments, or images.
- `npm run docker:with-secrets` points at `run-with-secrets.sh`, which is not in the repository.

## Everyday commands

Use `docker-compose.arm64.yml` in place of the simple file for the full setup.

```bash
# Logs for one service
docker-compose -f docker/docker-compose.dev-simple.yml logs -f foodme

# Restart one service (does not pick up new .env values)
docker-compose -f docker/docker-compose.dev-simple.yml restart foodme

# Rebuild and recreate one service (use this after server code or .env changes)
docker-compose -f docker/docker-compose.dev-simple.yml up -d --build --force-recreate foodme

# Database
npm run db:connect:simple      # psql
npm run db:backup:simple       # backup_<date>.sql
npm run db:restore:simple      # restores backup.sql
```

## Troubleshooting

### The page says "Error loading application"
The server cannot find `index.html` in `dist/browser`, because the container serves the Angular build from the mounted `dist/`. Run `npm run build:angular`, then reload. If the folder has files and the error stays, the mount may not resolve. See "Mounts denied" below.

### `ng build` fails with "You installed esbuild for another platform"
`node_modules` was installed on a different operating system than the one running the build, for example in the dev container (Linux) and then built on a Mac. Build where `node_modules` was installed, or reinstall there. Switching back and forth breaks it each time.

### My change doesn't show up
| You changed | Needed |
|---|---|
| Angular code | `npm run build:angular` |
| Server code | `up -d --build --force-recreate foodme` |
| `.env` | `up -d --force-recreate foodme` |

### Containers won't start
```bash
docker-compose -f docker/docker-compose.dev-simple.yml logs
sudo lsof -i :80 -i :3000 -i :443     # something else on the port?
npm run docker:clean && npm run docker:dev:simple
```
Stop other services on ports 80, 443 and 3000. PostgreSQL needs 30 to 60 seconds on first start, and `foodme` waits for it to be healthy.

### The database won't connect
Check `docker-compose -f docker/docker-compose.dev-simple.yml logs db`, then test with `npm run db:connect:simple`. If you changed `DB_PASSWORD` after the first start, the volume still holds the old password: use `npm run docker:clean` to start fresh.

### "Mounts denied: The path ... is not shared from the host"
```
(HTTP code 500) server error - Mounts denied: The path /workspaces/foodme/... is not shared from the host and is not known to Docker.
```
A bind mount such as `../dist:/dist` is resolved by the Docker engine on the host, not inside the dev container. In the dev container the workspace is `/workspaces/foodme`, a path your host does not have, so Docker refuses it. Options:

- Run the compose commands from a terminal on your machine, not inside the dev container.
- In the dev container, use a compose configuration that does not mount host paths. See [DevContainer Setup](../setup/DEVCONTAINER_SETUP.md).
- Disable the monitoring container in the dev container, which is the one that mounts `newrelic-integrations`. The earlier fix for this used a `profiles: [disabled]` entry on `newrelic-infra`, from the files now in `docker/archive/`.

### SSL certificate errors on ARM64
The full setup handles these automatically; they are normal on ARM64 Macs.

### Older documents that use `docker/docker-compose.yml`
`docker/archive/` holds the earlier compose files and Dockerfiles (`docker-compose.yml`, the dev, devcontainer and load test overrides, and `Dockerfile.secure`). Some older documents still use commands such as `docker-compose -f docker/docker-compose.yml up`. That file is in the archive now. Use the compose files listed in [docker/README.md](../../docker/README.md).

## New Relic in the containers

- **No browser data, or "New Relic header is empty":** check that `NEW_RELIC_LICENSE_KEY` is set in `.env` and recreate the container. The server injects the browser agent into the page when it starts up. The very first page request waits a few seconds on purpose, to let the agent finish starting.
- **Agent not connecting:** the key must be valid and New Relic reachable from the container.
- **Browser app and APM app in New Relic:** both report as `FoodMe`. See [New Relic Demo Features](../NEW_RELIC_DEMO.md).

## Load testing

Locust runs from the npm scripts on your machine against the app on port 3000 (`npm run loadtest`, `loadtest:headless`, `loadtest:web`). See [Load Testing](../LOAD_TESTING.md). The earlier Docker-based load test setup is in `docker/archive/`.
