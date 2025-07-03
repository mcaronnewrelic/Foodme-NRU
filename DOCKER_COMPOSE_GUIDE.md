# Docker Compose Setup Guide

This guide explains how to use the updated `docker-compose.yml` file that includes nginx reverse proxy and PostgreSQL database support.

## 🏗️ Architecture Overview

The Docker Compose setup includes the following services:

1. **foodme** - Main FoodMe application (Node.js/Express)
2. **nginx** - Reverse proxy with HTTPS support
3. **db** - PostgreSQL database for data persistence

## 🚀 Quick Start

### Prerequisites

1. **Docker and Docker Compose** installed
2. **SSL certificates** generated (run `./setup.sh` first)
3. **Database password** configured

### Setup Steps

1. **Generate SSL certificates** (if not already done):
   ```bash
   ./setup.sh foodme.local foodme 3000
   ```

2. **Set up database password**:
   ```bash
   # The password file should already exist, but you can change it
   echo "your_secure_password" > db/password.txt
   ```

3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

4. **Start all services**:
   ```bash
   docker compose up -d
   ```

5. **Access the application**:
   - HTTPS: https://foodme.local
   - HTTP: http://foodme.local (redirects to HTTPS)

## 📋 Service Details

### FoodMe Application (`foodme`)

- **Port**: 3000 (internal), exposed through nginx
- **Environment**: Uses `.env` file for configuration
- **Dependencies**: PostgreSQL database
- **Health**: Depends on database being healthy

### Nginx Reverse Proxy (`nginx`)

- **Ports**: 
  - 80 (HTTP - redirects to HTTPS)
  - 443 (HTTPS)
- **SSL Certificates**: Located in `.setup/certs/`
- **Configuration**: `.setup/nginx/foodme.local.conf`
- **Health Check**: Built-in nginx health endpoint

### PostgreSQL Database (`db`)

- **Image**: `postgres:16-alpine`
- **Database**: `foodme`
- **User**: `foodme_user`
- **Password**: Read from `db/password.txt` (Docker secret)
- **Port**: 5432 (internal only)
- **Data**: Persisted in `db-data` volume
- **Initialization**: SQL scripts in `db/init/`

## 🛠️ Management Commands

### Start Services
```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d foodme
```

### Stop Services
```bash
# Stop all services
docker compose down

# Stop and remove volumes (⚠️ deletes database data)
docker compose down -v
```

### View Logs
```bash
# All services
docker compose logs

# Specific service
docker compose logs foodme
docker compose logs nginx
docker compose logs db

# Follow logs
docker compose logs -f foodme
```

### Check Status
```bash
# Service status
docker compose ps

# Service health
docker compose ps --format table
```

### Database Management
```bash
# Connect to database
docker compose exec db psql -U foodme_user -d foodme

# Backup database
docker compose exec db pg_dump -U foodme_user foodme > backup.sql

# Restore database
cat backup.sql | docker compose exec -T db psql -U foodme_user -d foodme
```

## 📁 File Structure

```
├── docker-compose.yml          # Main compose configuration
├── db/
│   ├── password.txt           # Database password (gitignored)
│   └── init/
│       └── 01-init-schema.sql # Database initialization
├── .setup/
│   ├── nginx/
│   │   └── foodme.local.conf  # Nginx configuration
│   └── certs/
│       ├── foodme.local.crt   # SSL certificate
│       └── foodme.local.key   # SSL private key
└── .env                       # Environment variables
```

## 🔒 Security Features

### SSL/TLS
- **TLS 1.2/1.3 only**: Modern encryption protocols
- **Security headers**: HSTS, X-Frame-Options, etc.
- **Self-signed certificates**: For development (use Let's Encrypt for production)

### Database Security
- **Docker secrets**: Password stored securely
- **No exposed ports**: Database not accessible from outside Docker network
- **User isolation**: Dedicated database user with limited privileges

### Network Security
- **Internal network**: Services communicate via Docker network
- **Reverse proxy**: Application not directly exposed
- **Health checks**: Automatic service monitoring

## 🐛 Troubleshooting

### Common Issues

#### Services won't start
```bash
# Check logs
docker compose logs

# Check port conflicts
sudo lsof -i :80
sudo lsof -i :443

# Recreate containers
docker compose down
docker compose up -d --force-recreate
```

#### SSL certificate errors
```bash
# Regenerate certificates
cd .setup
./mkcert -key-file certs/foodme.local.key -cert-file certs/foodme.local.crt foodme.local "*.foodme.local"

# Restart nginx
docker compose restart nginx
```

#### Database connection errors
```bash
# Check database logs
docker compose logs db

# Verify password file
cat db/password.txt

# Test database connection
docker compose exec db psql -U foodme_user -d foodme -c "SELECT version();"
```

#### Domain not resolving
```bash
# Check hosts file
grep foodme.local /etc/hosts

# Should show: 127.0.0.1 foodme.local
```

## 🔧 Advanced Configuration

### Custom Domains
To use a different domain:

1. Update nginx configuration in `.setup/nginx/`
2. Regenerate SSL certificates for new domain
3. Update hosts file entry

### Production Deployment
For production use:

1. Use real SSL certificates (Let's Encrypt)
2. Configure proper database backups
3. Set up monitoring and logging
4. Use Docker secrets in swarm mode
5. Configure firewall rules

### Development vs Production
```bash
# Development (current setup)
docker compose up -d

# Production (with swarm secrets)
docker stack deploy -c docker-compose.yml foodme
```

## 📊 Monitoring

### Health Checks
All services include health checks:
- **nginx**: HTTP endpoint check
- **database**: PostgreSQL ready check
- **foodme**: Application-specific health check

### Logs
Centralized logging via Docker Compose:
```bash
# Real-time logs
docker compose logs -f

# Specific timeframe
docker compose logs --since "1h" --until "30m"
```

This setup provides a complete development environment with HTTPS, database persistence, and production-like architecture while maintaining ease of use for development.
