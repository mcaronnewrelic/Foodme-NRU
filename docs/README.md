# FoodMe Documentation

Start with the [main README](../README.md), then use this page to find the one document you need.

## Which document do I need?

| I want to... | Read |
|---|---|
| Run the app on my machine | [Docker Development Guide](../DOCKER_DEVELOPMENT_GUIDE.md) |
| Use the dev container | [DevContainer Setup](setup/DEVCONTAINER_SETUP.md) |
| Know what is in `.env` | [Environment Variables](setup/ENVIRONMENT_VARIABLES.md), and `.env.example` |
| Keep secrets out of git | [Secret Management](setup/SECRET_MANAGEMENT.md) |
| Set up or reset the database | [Database Guide](setup/DATABASE_GUIDE.md) |
| Find a file or folder in the repo | [Project Structure](../PROJECT_STRUCTURE.md) |
| Use the "Behind the scenes" callouts, planned failures or source maps | [New Relic Demo Features](NEW_RELIC_DEMO.md) |
| Create the New Relic dashboard, service levels and alerts | [newrelic/README.md](../newrelic/README.md) |
| Monitor the EC2 host and Postgres with New Relic | [New Relic Infrastructure Setup](NEW_RELIC_INFRA_SETUP.md) |
| Record deployments in New Relic | [scripts/README.md](../scripts/README.md) |
| Deploy to AWS | [Deployment Guide](deployment/DEPLOYMENT_GUIDE.md), then see "Deployment" below |
| Fix a deployment that failed | See "Troubleshooting" below |
| Run a load test | [Load Testing](LOAD_TESTING.md) |
| Understand the security posture and open findings | [Security](SECURITY.md) |

## Local development

| Document | Use it when |
|---|---|
| [Docker Development Guide](../DOCKER_DEVELOPMENT_GUIDE.md) | You want the app running. The quick start. |
| [docker/README.md](../docker/README.md) | You need to know which compose file and Dockerfile does what. |
| [DevContainer Setup](setup/DEVCONTAINER_SETUP.md) | You work in VS Code's dev container, or in an environment with restricted Docker access. |
| [Setup Guide](setup/SETUP_GUIDE.md) | You want to set up the HTTPS development environment with the setup script. |
| [Environment Variables](setup/ENVIRONMENT_VARIABLES.md) | You deploy with CloudFormation and need to know which variables it reads. |
| [Secret Management](setup/SECRET_MANAGEMENT.md) | You handle API keys, license keys or database passwords. |
| [Database Guide](setup/DATABASE_GUIDE.md) | You work with PostgreSQL, its initialization scripts or its data. |

## New Relic

| Document | Use it when |
|---|---|
| [New Relic Demo Features](NEW_RELIC_DEMO.md) | You teach with the app: callouts, planned failures, source maps. |
| [newrelic/README.md](../newrelic/README.md) | You create or rebuild the dashboard, service levels, alerts and workload. |
| [New Relic Infrastructure Setup](NEW_RELIC_INFRA_SETUP.md) | You install the infrastructure agent on the EC2 host. |
| [New Relic Integrations](NEW_RELIC_INTEGRATIONS_SETUP.md) and [newrelic-integrations/README.md](../newrelic-integrations/README.md) | You monitor PostgreSQL and nginx. |
| [scripts/README.md](../scripts/README.md) | You create deployment markers for the entity. |

## Deployment

| Document | Use it when |
|---|---|
| [Deployment Guide](deployment/DEPLOYMENT_GUIDE.md) | You want the list of deployment commands. |
| [Code Deployment Guide](deployment/CODE_DEPLOYMENT_GUIDE.md) | You change only the application and want to skip rebuilding AWS infrastructure. |
| [ALB Setup Guide](deployment/ALB_SETUP_GUIDE.md) | You work on the load balancer in the CloudFormation template. |
| [cloudformation/README.md](../cloudformation/README.md) | You need to know which CloudFormation template and script does what. |
| [Deploying with GitHub Actions](deployment/DEPLOYMENT_GUIDE.md#deploying-with-github-actions) | You deploy code or the stack from GitHub, or want to know which secrets it needs. |
| [Removing a deployment](deployment/DEPLOYMENT_GUIDE.md#removing-a-deployment) | A deployment failed, or you are done with an environment, and you need to remove what it created. |
| [Node.js version](deployment/DEPLOYMENT_GUIDE.md#nodejs-version) | You need to move an existing instance to Node 24. |
| [Load Testing](LOAD_TESTING.md) and [CloudFormation Load Testing](LOAD_TESTING_CLOUDFORMATION.md) | You run Locust locally, or from AWS. |

## Troubleshooting

| Document | Use it when |
|---|---|
| [Docker Comprehensive Guide](troubleshooting/DOCKER_COMPREHENSIVE_GUIDE.md) | Docker misbehaves. It covers the services, commands, and fixes for a blank site, stale changes, and "Mounts denied" in the dev container. |
| [EC2 Troubleshooting](troubleshooting/EC2_TROUBLESHOOTING.md) | The stack fails, the code deployment fails, or the instance is up but the app is not working (PM2, nginx, health checks, database). |
| [EC2 Key Pair Setup](../archive/terraform/EC2_KEYPAIR_SETUP.md) | A deployment fails with `InvalidKeyPair.NotFound`. Written for Terraform; the key pair advice still applies. |
| [New Relic on Amazon Linux 2023](../archive/terraform/NEW_RELIC_AL2023_FIX.md) | The infrastructure agent will not install on Amazon Linux 2023. |

## Security

| Document | Use it when |
|---|---|
| [Security](SECURITY.md) | You want the practices the project follows, the checks you can run, or the open findings from the 2026-06-02 source review. |

## History, not instructions

These live in [docs/archive/](archive/). They describe changes that were made at one point in time. They explain why things look the way they do, but they are not guides, and they can be out of date.

| Document | What it records |
|---|---|
| [Root Cleanup Summary](archive/ROOT_CLEANUP_SUMMARY.md) | How the repository root was tidied |
| [Documentation Verification Report](archive/DOCUMENTATION_VERIFICATION_REPORT.md) | A link check after that reorganization |
| [Docker Simplification Summary](archive/DOCKER_SIMPLIFICATION_SUMMARY.md) | How the Docker npm scripts were reduced |
| [ARM64 Docker Setup](archive/ARM64_DOCKER_SETUP.md) | How the ARM64 compose files were created |
| [Deployment Status](archive/DEPLOYMENT_STATUS.md) | Deployment problems that were resolved |
| [PostgreSQL 16 Update](archive/POSTGRESQL_16_UPDATE.md) | The move from PostgreSQL 15 to 16 on EC2 |
| [PostgreSQL Integration Summary](archive/POSTGRESQL_INTEGRATION_SUMMARY.md) | Adding PostgreSQL to the EC2 deployment |
| [New Relic Integration Summary](archive/NEW_RELIC_INTEGRATION_SUMMARY.md) | Adding the infrastructure agent to the EC2 deployment |

## Archive

[archive/terraform](../archive/terraform/README.md) holds the Terraform deployment that CloudFormation replaced: the configuration, its scripts, its troubleshooting and cleanup guides, and the three GitHub workflows that ran it. Nothing in it runs any more.

## For contributors

[.github/copilot-instructions.md](../.github/copilot-instructions.md) holds the code review guidelines used by GitHub Copilot.
