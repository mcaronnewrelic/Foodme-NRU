#!/bin/bash
set -e

# FoodMe Application Installation Script
# This script installs and configures the complete FoodMe application stack

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting FoodMe application installation..."

# Update system and install required packages
log "Updating system and installing packages..."
dnf update -y
dnf install -y git nginx postgresql16-server postgresql16 postgresql16-contrib unzip nmap-ncat

# Install Node.js 22 using NodeSource repository
log "Installing Node.js 22..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

# Install New Relic Infrastructure agent
log "Installing New Relic Infrastructure agent..."
curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2023/x86_64/newrelic-infra.repo
dnf -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
dnf install -y newrelic-infra

# Initialize PostgreSQL
log "Initializing PostgreSQL..."
sudo -u postgres /usr/bin/postgresql-setup --initdb
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL
configure_postgresql() {
    local db_password="$1"
    
    log "Setting up PostgreSQL user and database..."
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$db_password';"
    sudo -u postgres createdb foodme
    
    # Update PostgreSQL configuration
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
    sed -i 's/host    all             all             127.0.0.1\/32            ident/host    all             all             127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf
    
    systemctl restart postgresql
    
    # Wait for PostgreSQL to be ready
    log "Waiting for PostgreSQL to be ready..."
    until sudo -u postgres psql -d foodme -c 'SELECT 1;' > /dev/null 2>&1; do
        echo "Waiting for PostgreSQL..."
        sleep 2
    done
    log "PostgreSQL is ready!"
}

# Setup PostgreSQL monitoring with comprehensive extensions
setup_postgresql_monitoring() {
    log "Setting up PostgreSQL monitoring extensions..."
    
    # Configure shared_preload_libraries and pg_stat_statements settings
    if ! grep -q "shared_preload_libraries" /var/lib/pgsql/data/postgresql.conf; then
        echo "shared_preload_libraries = 'pg_stat_statements'" >> /var/lib/pgsql/data/postgresql.conf
    else
        sed -i "s/^#*shared_preload_libraries = .*/shared_preload_libraries = 'pg_stat_statements'/" /var/lib/pgsql/data/postgresql.conf
    fi
    
    # Add comprehensive pg_stat_statements configuration
    cat >> /var/lib/pgsql/data/postgresql.conf << EOF

# PostgreSQL Monitoring Configuration
pg_stat_statements.max = 10000
pg_stat_statements.track = all
pg_stat_statements.save = on
pg_stat_statements.track_utility = on
pg_stat_statements.track_planning = on

# Additional performance monitoring settings
log_statement_stats = off
log_parser_stats = off
log_planner_stats = off
log_executor_stats = off

# Query logging for additional monitoring
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Log file permissions for monitoring
log_file_mode = 0644
EOF
    
    # Restart PostgreSQL to load the extension and apply configuration
    systemctl restart postgresql
    
    # Wait for PostgreSQL to be ready
    until sudo -u postgres psql -d foodme -c 'SELECT 1;' > /dev/null 2>&1; do
        echo "Waiting for PostgreSQL to restart..."
        sleep 2
    done
    
    # Create monitoring extensions in the database
    log "Installing PostgreSQL monitoring extensions..."
    sudo -u postgres psql -d foodme -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
    sudo -u postgres psql -d foodme -c "CREATE EXTENSION IF NOT EXISTS pg_buffercache;"
    sudo -u postgres psql -d foodme -c "CREATE EXTENSION IF NOT EXISTS pgstattuple;"
    sudo -u postgres psql -d foodme -c "CREATE EXTENSION IF NOT EXISTS pgrowlocks;"
    
    # Fix PostgreSQL log permissions for New Relic monitoring access
    log "Configuring PostgreSQL log permissions for monitoring..."
    chmod 755 /var/lib/pgsql/data/log
    chmod 644 /var/lib/pgsql/data/log/postgresql-*.log 2>/dev/null || true
    
    log "PostgreSQL monitoring extensions configured successfully!"
}

# Install Node.js application dependencies
install_application_dependencies() {
    log "Installing PM2 for process management..."
    npm install -g pm2
}

# Setup application directory structure
setup_application_structure() {
    log "Setting up application directory structure..."
    mkdir -p /opt/foodme/{frontend,backend,database,logs}
    chown -R ec2-user:ec2-user /opt/foodme
    chmod 755 /opt/foodme/logs
    
    # Create log rotation configuration for application logs
    cat > /etc/logrotate.d/foodme << EOF
/opt/foodme/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 ec2-user ec2-user
    copytruncate
}
EOF
}

# Deploy backend application
deploy_backend_application() {
    local s3_bucket="$1"
    local db_password="$2"
    local new_relic_key="$3"
    local environment="$4"
    local node_env="$5"
    
    log "Deploying backend application..."
    cd /opt/foodme/backend
    
    # Download backend code from S3
    log "Downloading backend code from S3..."
    aws s3 cp "s3://$s3_bucket/server.zip" ./server.zip
    unzip -q server.zip
    mv server/* .
    rmdir server
    rm server.zip
    
    # Install dependencies
    log "Installing backend dependencies..."
    npm install
    
    # Create environment configuration
    log "Creating environment configuration..."
    cat > .env << EOF
NODE_ENV="$node_env"
PORT=3000
DATABASE_URL="postgresql://postgres:$db_password@localhost:5432/foodme"
JWT_SECRET=$(openssl rand -base64 32)
CORS_ORIGIN="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
ANGULAR_DIR="/opt/foodme/dist/browser"
NEW_RELIC_LICENSE_KEY="$new_relic_key"
NEW_RELIC_APP_NAME="FoodMe-$environment"
NEW_RELIC_ENABLED=$([[ -n "$new_relic_key" && "$new_relic_key" != "REPLACE_WITH_YOUR_LICENSE_KEY" ]] && echo "true" || echo "false")
NEW_RELIC_LOG_LEVEL="info"
NEW_RELIC_DISTRIBUTED_TRACING_ENABLED="true"
NEW_RELIC_SPAN_EVENTS_ENABLED="true"
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ENVIRONMENT="$environment"
EOF
    
    # Create PM2 ecosystem configuration
    log "Creating PM2 ecosystem configuration..."
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'foodme-backend',
    script: 'start.js',
    node_args: '--env-file=.env',
    cwd: '/opt/foodme/backend',
    instances: 1,
    exec_mode: 'fork',
    out_file: '/opt/foodme/logs/foodme-backend-out.log',
    error_file: '/opt/foodme/logs/foodme-backend-error.log',
    log_file: '/opt/foodme/logs/foodme-backend-combined.log',
    time: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
EOF
}

# Deploy frontend application
deploy_frontend_application() {
    local s3_bucket="$1"
    
    log "Deploying frontend application..."
    cd /opt/foodme
    
    # Download Angular frontend from S3
    log "Downloading frontend code from S3..."
    aws s3 cp "s3://$s3_bucket/angular-app.zip" ./angular-app.zip
    unzip -q angular-app.zip
    rm angular-app.zip
}

# Configure Nginx
configure_nginx() {
    log "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Serve Angular frontend
    location / {
        root /opt/foodme/dist/browser;
        try_files $uri $uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }
    
    # Serve static assets with longer cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /opt/foodme/dist/browser;
        expires 1y;
        add_header Cache-Control "public, immutable";
        gzip_static on;
    }
    
    # Proxy API requests to Node.js backend
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
    
    # Error pages
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
    
    # Enable and start Nginx
    systemctl enable nginx
    systemctl start nginx
}

# Configure New Relic Infrastructure
configure_new_relic() {
    local license_key="$1"
    local environment="$2"
    
    if [[ -n "$license_key" && "$license_key" != "REPLACE_WITH_YOUR_LICENSE_KEY" ]]; then
        log "Configuring New Relic Infrastructure monitoring..."
        
        # Configure New Relic Infrastructure
        cat > /etc/newrelic-infra.yml << EOF
license_key: $license_key
display_name: foodme-$environment-$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
log_file: /var/log/newrelic-infra/newrelic-infra.log
verbose: 0
custom_attributes:
  environment: $environment
  application: foodme
  role: web-server
EOF
        
        systemctl enable newrelic-infra
        systemctl start newrelic-infra
        log "New Relic Infrastructure monitoring enabled"
    else
        log "New Relic monitoring disabled (no license key provided)"
    fi
}

# Initialize database schema
initialize_database() {
    local db_password="$1"
    local s3_bucket="$2"
    
    log "Initializing database schema..."
    
    # Check if database initialization script exists in S3
    if aws s3 ls "s3://$s3_bucket/db-init.zip" > /dev/null 2>&1; then
        log "Downloading database initialization scripts..."
        cd /opt/foodme/database
        aws s3 cp "s3://$s3_bucket/db-init.zip" ./db-init.zip
        unzip -q db-init.zip
        rm db-init.zip
        
        # Run initialization scripts if they exist
        if [ -f "init-db.sql" ]; then
            log "Running database initialization script..."
            PGPASSWORD="$db_password" psql -h localhost -U postgres -d foodme -f init-db.sql
        fi
    else
        log "No database initialization scripts found in S3"
    fi
}

# Start application services
start_services() {
    log "Starting application services..."
    
    # Start backend with PM2
    cd /opt/foodme/backend
    sudo -u ec2-user pm2 start ecosystem.config.js
    sudo -u ec2-user pm2 save
    
    # Setup PM2 startup script
    pm2 startup systemd -u ec2-user --hp /home/ec2-user
    
    # Ensure Nginx is running
    systemctl restart nginx
    
    log "All services started successfully!"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check services
    if systemctl is-active --quiet postgresql; then
        log "✅ PostgreSQL is running"
    else
        log "❌ PostgreSQL is not running"
    fi
    
    if systemctl is-active --quiet nginx; then
        log "✅ Nginx is running"
    else
        log "❌ Nginx is not running"
    fi
    
    if sudo -u ec2-user pm2 list | grep -q "foodme-backend"; then
        log "✅ Backend application is running"
    else
        log "❌ Backend application is not running"
    fi
    
    # Test API endpoint
    sleep 5
    if curl -s http://localhost/health > /dev/null; then
        log "✅ API health check passed"
    else
        log "❌ API health check failed"
    fi
    
    log "Deployment verification completed!"
}

# Main execution function
main() {
    local db_password="$1"
    local s3_bucket="$2"
    local new_relic_key="$3"
    local environment="$4"
    local node_env="$5"
    
    log "=== FoodMe Application Deployment Starting ==="
    log "Environment: $environment"
    log "S3 Bucket: $s3_bucket"
    log "New Relic: $([[ -n "$new_relic_key" && "$new_relic_key" != "REPLACE_WITH_YOUR_LICENSE_KEY" ]] && echo "Enabled" || echo "Disabled")"
    
    # Execute deployment steps
    configure_postgresql "$db_password"
    setup_postgresql_monitoring
    install_application_dependencies
    setup_application_structure
    deploy_backend_application "$s3_bucket" "$db_password" "$new_relic_key" "$environment" "$node_env"
    deploy_frontend_application "$s3_bucket"
    configure_nginx
    configure_new_relic "$new_relic_key" "$environment"
    initialize_database "$db_password" "$s3_bucket"
    start_services
    verify_deployment
    
    log "=== FoodMe Application Deployment Completed Successfully ==="
}

# Execute main function with parameters
main "$@"