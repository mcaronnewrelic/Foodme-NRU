# DevContainer & Docker Compose Configurations

This document explains how to use the different Docker Compose configurations available in the FoodMe project, especially when working in restricted environments like dev containers.

## 📋 Available Configurations

### 1. Main Configuration (`docker-compose.yml`)
**Purpose**: Production-ready setup with comprehensive monitoring

**Features**:
- Full New Relic infrastructure monitoring with privileged access
- Nginx reverse proxy with SSL support  
- PostgreSQL database with health checks
- Complete host system monitoring
- Process-level metrics collection

**Best for**: 
- Host development environments
- CI/CD pipelines
- Production deployments
- Full monitoring requirements

### 2. DevContainer Configuration (`docker-compose.dev.yml`)
**Purpose**: Simplified setup for restricted environments

**Features**:
- Basic New Relic monitoring without privileged access
- Docker container monitoring only
- No host filesystem access required
- Compatible with GitHub Codespaces and VS Code dev containers

**Best for**:
- GitHub Codespaces
- VS Code dev containers
- Restricted development environments
- Security-conscious setups

### 3. Load Testing Configuration (`docker-compose.loadtest.yml`)
**Purpose**: Isolated performance testing

**Features**:
- Locust load testing framework
- Configurable user simulation
- Performance metrics collection
- Network connectivity to main application

**Best for**:
- Performance testing
- Load benchmarking
- CI/CD performance validation

## 🚀 Usage Instructions

### Using DevContainer Configuration

#### Option 1: Override Configuration
```bash
# Start with dev container friendly settings
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Stop services
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

#### Option 2: NPM Scripts (Recommended)
```bash
# Start dev container setup
npm run docker:compose:dev

# View logs
npm run docker:dev:logs

# Stop services  
npm run docker:dev:down
```

#### Option 3: Environment Variable
```bash
# Set environment preference
export DOCKER_COMPOSE_ENV=dev

# Use in scripts or automation
if [ "$DOCKER_COMPOSE_ENV" = "dev" ]; then
  docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
else
  docker compose up -d
fi
```

### Using Load Testing Configuration

#### Quick Load Test
```bash
# Start load testing
npm run docker:compose:loadtest

# View test results
npm run docker:loadtest:logs

# Stop load testing
npm run docker:loadtest:down
```

#### Custom Load Test Parameters
```bash
# Edit docker-compose.loadtest.yml to customize:
# -u: number of users
# -r: spawn rate (users per second)  
# -t: test duration

# Example: 10 users, 2 per second, 60 seconds
docker compose -f docker-compose.loadtest.yml run --rm locust \
  locust -f locustfile.py --host=http://foodme:3000 \
  --headless -u 10 -r 2 -t 60s
```

## 🔧 Configuration Differences

### New Relic Monitoring Comparison

| Feature | Main Config | DevContainer Config |
|---------|-------------|-------------------|
| **Container Name** | `newrelic-infra` | `newrelic-infra-simple` |
| **Privileged Access** | ✅ `privileged: true` | ❌ Removed |
| **Host PID Namespace** | ✅ `pid: host` | ❌ Removed |
| **Process Monitoring** | ✅ `NRIA_ENABLE_PROCESS_METRICS=true` | ❌ `false` |
| **Host Filesystem** | ✅ `/:/host:ro` | ❌ Docker socket only |
| **Network Mode** | Custom bridge network | `network_mode: bridge` |
| **Capabilities** | ✅ `SYS_PTRACE` | ❌ None |

### Volume Mounts Comparison

**Main Configuration**:
```yaml
volumes:
  - "/var/run/docker.sock:/var/run/docker.sock:ro"
  - "/:/host:ro"  # Full host access
  - "./newrelic-integrations:/etc/newrelic-infra/integrations.d:ro"
```

**DevContainer Configuration**:
```yaml
volumes:
  - "/var/run/docker.sock:/var/run/docker.sock:ro"  # Docker only
```

## 🛠️ Troubleshooting

### Common DevContainer Issues

#### Permission Denied Errors
```bash
# If you see: "permission denied" or "operation not permitted"
# Switch to dev configuration:
npm run docker:compose:dev
```

#### Privileged Access Required
```bash
# If you see: "privileged access required"
# Use the simplified monitoring:
docker compose -f docker-compose.dev.yml up newrelic-infra-simple -d
```

#### Volume Mount Failures
```bash
# If host volume mounts fail, dev config uses minimal mounts:
docker compose -f docker-compose.dev.yml logs newrelic-infra-simple
```

### Monitoring Verification

#### Check New Relic Agent Status
```bash
# Main configuration
docker compose logs newrelic-infra

# DevContainer configuration  
docker compose -f docker-compose.dev.yml logs newrelic-infra-simple
```

#### Verify Data Collection
```bash
# Check environment variables
docker compose exec newrelic-infra env | grep NRIA

# Check integration files
docker compose exec newrelic-infra ls -la /etc/newrelic-infra/integrations.d/
```

## 📊 Monitoring Capabilities

### What You Get with Each Configuration

#### Main Configuration Monitoring
- ✅ Host system metrics (CPU, memory, disk, network)
- ✅ Process-level monitoring
- ✅ Docker container metrics
- ✅ Nginx integration (HTTP metrics)
- ✅ PostgreSQL integration (database metrics)
- ✅ Custom business metrics

#### DevContainer Configuration Monitoring
- ✅ Docker container metrics
- ✅ Basic system metrics (limited)
- ❌ Host process monitoring
- ❌ Host filesystem metrics
- ❌ Advanced integration data

#### Load Testing Metrics
- ✅ Request latency and throughput
- ✅ Error rates and response codes
- ✅ User simulation metrics
- ✅ Performance over time

## 🔐 Security Considerations

### Why DevContainer Config is More Secure

1. **No Privileged Access**: Reduces attack surface
2. **Limited Host Access**: Only Docker socket, no filesystem
3. **Process Isolation**: Cannot monitor host processes
4. **Network Isolation**: Uses standard Docker networking

### Production vs Development

- **Production**: Use main configuration for comprehensive monitoring
- **Development**: Use dev configuration for compatibility and security
- **Testing**: Use load test configuration for performance validation

## 📝 Adding Your Own Configurations

### Creating Custom Compose Files

```yaml
# docker-compose.custom.yml
services:
  your-service:
    image: your-image
    networks:
      - foodme_network
    depends_on:
      - foodme

networks:
  foodme_network:
    external: true
```

### Using Custom Configurations

```bash
# Combine multiple configs
docker compose -f docker-compose.yml -f docker-compose.custom.yml up -d

# Add to package.json
"docker:custom": "docker compose -f docker-compose.yml -f docker-compose.custom.yml up -d"
```

## 🆘 Support

If you encounter issues with any configuration:

1. **Check logs**: Use the appropriate logging command for your config
2. **Verify environment**: Ensure `.env` file is properly configured
3. **Test connectivity**: Verify Docker daemon and network connectivity
4. **Fallback**: Try the dev configuration if main config fails

For more help, see:
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Complete setup instructions
- [NEW_RELIC_INFRA_SETUP.md](./NEW_RELIC_INFRA_SETUP.md) - New Relic configuration
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Deployment workflows
