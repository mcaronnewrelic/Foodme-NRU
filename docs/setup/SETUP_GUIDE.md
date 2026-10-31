# FoodMe Development Environment Setup Guide

This guide explains how to set up a secure HTTPS development environment for the FoodMe application using the automated setup script.

## Overview

The `setup.sh` script automates the creation of a local HTTPS development environment with:

- **SSL Certificates**: Automatically generated using mkcert
- **Nginx Reverse Proxy**: Handles HTTPS termination and forwards requests to your app
- **Docker Compose**: Manages the nginx container
- **Hosts File Management**: Adds your custom domain to `/etc/hosts`
- **Cross-Platform Support**: Works on macOS, Linux, and Windows (via WSL)

## Prerequisites

Before running the setup script, ensure you have:

1. **Docker Desktop** installed and running
   - [Download Docker Desktop](https://docs.docker.com/get-docker/)
   - Verify installation: `docker --version` and `docker compose version`

2. **Internet Connection** (to download mkcert)

3. **Administrative Privileges** (for hosts file modification)

4. **Available Ports** 80 and 443 on your system

## Quick Start

1. **Make the script executable**:
   ```bash
   chmod +x setup.sh
   ```

2. **Run the setup**:
   ```bash
   ./setup.sh foodme.local foodme 3000
   ```

3. **Start your FoodMe application** on port 3000

4. **Visit** https://foodme.local in your browser

## Script Usage

```bash
./setup.sh <domain> <app_name> <port>
```

### Parameters

- **`domain`**: The local domain name (e.g., `foodme.local`, `myapp.dev`)
- **`app_name`**: Application name for Docker containers (e.g., `foodme`)
- **`port`**: Port where your application runs (e.g., `3000`)

### Examples

```bash
# Standard FoodMe setup
./setup.sh foodme.local foodme 3000

# Custom domain and port
./setup.sh myapp.dev myapp 8080

# Development environment
./setup.sh dev.foodme.local foodme-dev 4000
```

## What the Script Does

### Step-by-Step Process

1. **System Detection**: Identifies your OS and architecture
2. **Input Validation**: Validates domain format, app name, and port number
3. **Dependency Check**: Verifies Docker is installed and running
4. **Workspace Setup**: Creates `.setup/` directory for generated files
5. **mkcert Download**: Downloads the appropriate mkcert binary for your system
6. **Certificate Generation**: Creates SSL certificates for your domain
7. **Nginx Configuration**: Generates nginx config with security headers
8. **Docker Compose Setup**: Creates container orchestration file
9. **Hosts File Update**: Adds domain to your system's hosts file
10. **Service Startup**: Starts the nginx container
11. **Verification**: Validates the setup was successful

### Generated Files

After running the script, you'll find these files in the `.setup/` directory:

```
.setup/
├── mkcert                           # mkcert binary
├── docker-compose.yml              # Container orchestration
├── certs/
│   ├── foodme.local.crt            # SSL certificate
│   └── foodme.local.key            # SSL private key
└── nginx/
    └── foodme.local.conf            # Nginx configuration
```

## Configuration Details

### Nginx Features

The generated nginx configuration includes:

- **HTTPS Redirect**: All HTTP traffic redirected to HTTPS
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, HSTS, etc.
- **WebSocket Support**: For real-time features
- **Health Check Endpoints**: `/nginx-health` and `/nginx-status`
- **Proper Proxy Headers**: X-Forwarded-* headers for backend compatibility

### Docker Compose Features

- **Health Checks**: Monitors nginx container health
- **Auto-Restart**: Container restarts on failure
- **Volume Mounts**: Read-only mounts for configs and certificates
- **Network Isolation**: Custom bridge network for the application

### Security Features

- **TLS 1.2/1.3 Only**: Modern TLS protocols
- **Strong Ciphers**: ECDHE-based cipher suites
- **Security Headers**: HSTS, frame options, XSS protection
- **Certificate Validation**: Automatic mkcert CA installation

## Managing the Environment

### Useful Commands

```bash
# Navigate to setup directory
cd .setup

# Check container status
docker compose ps

# View nginx logs
docker compose logs nginx

# Restart nginx
docker compose restart nginx

# Stop all services
docker compose down

# Start services
docker compose up -d

# Rebuild and restart
docker compose up -d --force-recreate
```

### Troubleshooting

#### Port Conflicts
If ports 80 or 443 are in use:
```bash
# Check what's using the ports
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting services
sudo systemctl stop apache2  # or nginx, if running natively
```

#### Certificate Issues
If browsers show certificate warnings:
```bash
# Reinstall mkcert CA
cd .setup
./mkcert -install

# Regenerate certificates
./mkcert -key-file certs/foodme.local.key -cert-file certs/foodme.local.crt foodme.local "*.foodme.local"
```

#### Domain Resolution Issues
If the domain doesn't resolve:
```bash
# Check hosts file entry
grep foodme.local /etc/hosts

# Manually add if missing
echo "127.0.0.1 foodme.local" | sudo tee -a /etc/hosts
```

#### Container Issues
If nginx container won't start:
```bash
# Check Docker daemon
docker info

# Test nginx config
docker compose config

# Check for syntax errors
docker compose logs nginx
```

## Cleanup

To remove the HTTPS setup:

```bash
# Stop and remove containers
cd .setup
docker compose down --volumes

# Remove generated files
cd ..
rm -rf .setup

# Remove hosts file entry (manual)
sudo nano /etc/hosts  # Remove the line with your domain

# Uninstall mkcert CA (optional)
mkcert -uninstall
```

## Advanced Usage

### Multiple Domains

You can run the script multiple times with different domains:

```bash
./setup.sh foodme.local foodme 3000
./setup.sh api.foodme.local foodme-api 3001
./setup.sh admin.foodme.local foodme-admin 3002
```

### Custom Nginx Configuration

To customize the nginx configuration:

1. Edit `.setup/nginx/foodme.local.conf`
2. Restart nginx: `cd .setup && docker compose restart nginx`

### Environment Variables

The setup script respects these environment variables:

- `SETUP_PROCESS_DIR`: Override the default `.setup` directory
- `SETUP_SKIP_HOSTS`: Skip hosts file modification (set to `1`)
- `SETUP_MKCERT_VERSION`: Specify mkcert version (default: `latest`)

Example:
```bash
SETUP_PROCESS_DIR=".ssl-setup" ./setup.sh foodme.local foodme 3000
```

## Security Considerations

- **Certificate Storage**: SSL certificates are stored locally in `.setup/certs/`
- **Hosts File**: The script modifies your system hosts file (requires sudo)
- **Container Security**: Nginx runs in a containerized environment
- **Network Isolation**: Uses Docker bridge networks for isolation
- **File Permissions**: Certificates have appropriate read-only permissions

## Integration with FoodMe

The setup script is designed to work seamlessly with the FoodMe application:

1. **Run the setup script** first to create the HTTPS environment
2. **Start FoodMe** with `npm run dev` (the app will run on port 3000)
3. **Access the app** at https://foodme.local
4. **Development workflow** continues as normal with HTTPS

The nginx proxy will forward all requests to your FoodMe application while providing SSL termination and security headers.
