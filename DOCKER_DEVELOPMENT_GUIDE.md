# FoodMe Docker Development Guide

The quick start for running FoodMe on your machine. For what each file in `docker/` does, see [docker/README.md](./docker/README.md). When something breaks, see the [Docker Comprehensive Guide](./docs/troubleshooting/DOCKER_COMPREHENSIVE_GUIDE.md).

## Quick start

1. **Prerequisites.** A Docker engine ([Rancher Desktop](https://rancherdesktop.io/) works well on a Mac) or the [dev container](./docs/setup/DEVCONTAINER_SETUP.md). Clone the repository.
2. **Configure.** Copy `.env.example` to `.env` and fill in at least `NEW_RELIC_LICENSE_KEY` and `DB_PASSWORD`. See [Environment Variables](./docs/setup/ENVIRONMENT_VARIABLES.md).
3. **Build the website.** The containers serve the Angular build from `dist/`, so it has to exist first:
   ```bash
   npm run build:angular
   ```
   Run it where `node_modules` was installed for the same platform. Outside the dev container, `ng build` can fail with an esbuild "another platform" error. In that case build in a container from your terminal instead:
   ```bash
   npm run build:angular:docker
   ```
4. **Start.**
   ```bash
   npm run docker:dev:simple
   ```
5. **Open** http://localhost (through nginx) or http://localhost:3000 (the app directly).

| URL | What it is |
|---|---|
| http://localhost | The site, through nginx |
| http://localhost:3000 | The Node app directly |
| http://localhost/health | Health check |
| http://localhost/api/restaurant | The restaurant API |

## Pick a setup

| | Simple | Full |
|---|---|---|
| Command | `npm run docker:dev:simple` | `npm run docker:dev:full` |
| Runs | App, PostgreSQL, nginx | The same, plus a New Relic infrastructure agent stand-in and database monitoring |
| Compose file | `docker/docker-compose.dev-simple.yml` | `docker/docker-compose.arm64.yml` |
| Use it for | Feature work and debugging | Testing monitoring and production-like behavior |
| Startup | About 30 seconds | About 60 seconds |

## Commands

```bash
npm run docker:dev:simple:build  # build Angular in a container, rebuild the images, recreate everything
npm run docker:status            # what is running
npm run docker:logs              # follow the logs
npm run docker:stop              # stop everything
npm run docker:clean             # stop and delete containers and volumes (the database is lost)

npm run db:connect:simple        # psql into the database (db:connect:full for the full setup)
npm run db:backup:simple         # write backup_<date>.sql (db:backup:full for the full setup)
```

## Working on code

What you changed decides what to run. The server code is copied into the image when it is built, so it does not reload by itself.

| You changed | Run |
|---|---|
| Angular code (`angular-app/`) | `npm run build:angular`. No restart needed: `dist/` is mounted into the container. |
| Server code (`server/`) | `docker-compose -f docker/docker-compose.dev-simple.yml up -d --build --force-recreate foodme` |
| `.env` | `docker-compose -f docker/docker-compose.dev-simple.yml up -d --force-recreate foodme`. The file is read only when the container is created, so a plain restart does not pick up changes. |
| Database scripts in `db/init/` | `npm run docker:clean`, then start again. They only run when the database volume is first created. |

From a Mac terminal, `npm run docker:dev:simple:build` covers all of the first three rows at once. It builds Angular in a `node:24` container, rebuilds the images and recreates the containers. The database volume is kept.

## Using Docker directly

The npm scripts are thin wrappers:

```bash
docker-compose -f docker/docker-compose.dev-simple.yml up -d
docker-compose -f docker/docker-compose.dev-simple.yml ps
docker-compose -f docker/docker-compose.dev-simple.yml logs -f
docker-compose -f docker/docker-compose.dev-simple.yml down
```

Use `docker/docker-compose.arm64.yml` in place of the simple file for the full setup.
