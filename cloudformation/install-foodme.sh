#!/bin/bash
set -e

# FoodMe Application Installation Script
# This script installs and configures the complete FoodMe application stack
#
# Key Fixes Applied:
# - Fixed Angular build output path handling (outputs to /opt/foodme/dist directly)
# - Corrected New Relic file ownership (root:root instead of root:newrelic-infra)
# - Fixed file permissions (644 instead of 640)
# - Improved PostgreSQL integration test (PGPASSWORD method)
# - Enhanced service startup with error handling and fallback
# - Added comprehensive step-by-step logging

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Amazon Linux 2023 requires IMDSv2, so plain curl to the metadata service returns nothing
imds() {
    local token
    token=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
    curl -s -H "X-aws-ec2-metadata-token: $token" "http://169.254.169.254/latest/meta-data/$1"
}

# Hostname is ip-10-0-1-x, which tells apart servers that overlap during a redeploy
host_display_name() {
    echo "foodme-$(hostname -s)"
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
CORS_ORIGIN="http://$(imds public-ipv4)"
ANGULAR_DIR="/opt/foodme/dist/browser"
NEW_RELIC_LICENSE_KEY="$new_relic_key"
NRIA_LICENSE_KEY="$new_relic_key"
NEW_RELIC_APP_NAME="FoodMe"
NEW_RELIC_PROCESS_HOST_DISPLAY_NAME="$(host_display_name)"
NEW_RELIC_ENABLED=$([[ -n "$new_relic_key" && "$new_relic_key" != "REPLACE_WITH_YOUR_LICENSE_KEY" ]] && echo "true" || echo "false")
NEW_RELIC_LOG_LEVEL="info"
NEW_RELIC_DISTRIBUTED_TRACING_ENABLED="true"
NEW_RELIC_SPAN_EVENTS_ENABLED="true"
AWS_REGION=$(imds placement/region)
ENVIRONMENT="$environment"
EOF
    
    # Create PM2 ecosystem configuration
    log "Creating PM2 ecosystem configuration..."
    cat > ecosystem.config.js << EOF
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
    
    # Fix ownership of angular-app directory
    log "Fixing Angular app permissions..."
    chown -R ec2-user:ec2-user /opt/foodme/angular-app
    
    # Build Angular application
    log "Building Angular application..."
    cd /opt/foodme/angular-app
    sudo -u ec2-user npm install
    sudo -u ec2-user npm run build
    
    # Verify Angular build output location
    log "Verifying Angular build output..."
    if [ -d "/opt/foodme/dist/browser" ]; then
        log "✅ Angular build output found at correct location: /opt/foodme/dist/browser"
    else
        log "❌ Angular build output not found at expected location"
        log "Checking alternative locations..."
        find /opt/foodme -name "browser" -type d 2>/dev/null | head -5
        exit 1
    fi
    
    log "Frontend deployment completed!"
}

# Configure Nginx
configure_nginx() {
    log "Configuring Nginx..."
    
    # Remove conflicting default server block from nginx.conf
    log "Removing default server block from nginx.conf..."
    sed -i '/^    server {/,/^    }/d' /etc/nginx/nginx.conf
    
    # Create main nginx configuration with monitoring module
    cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    listen 8080;
    server_name _;
    
    # Health check endpoint for monitoring
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Nginx status page for New Relic monitoring
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow ::1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
    }
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # API routes - proxy to Node.js backend
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 100s;
        proxy_send_timeout 100s;
    }
    
    # Health endpoint
    location /health {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }
    
    # Static assets with long cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Main application - serve everything else through Node.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
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
        
        # Set system-wide environment variable for New Relic Infrastructure
        echo "NRIA_LICENSE_KEY=$license_key" >> /etc/environment
        export NRIA_LICENSE_KEY="$license_key"
        
        # Configure New Relic Infrastructure
        cat > /etc/newrelic-infra.yml << EOF
license_key: $license_key
display_name: $(host_display_name)
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

# Configure PostgreSQL monitoring for New Relic
configure_postgresql_monitoring() {
    local license_key="$1"
    local environment="$2"
    local db_password="$3"
    
    if [[ -n "$license_key" && "$license_key" != "REPLACE_WITH_YOUR_LICENSE_KEY" ]]; then
        log "Setting up PostgreSQL monitoring for New Relic..."
        
        # Install PostgreSQL integration
        log "Installing New Relic PostgreSQL integration..."
        dnf install -y nri-postgresql
        
        # Create dedicated monitoring user for New Relic
        log "Creating New Relic monitoring user in PostgreSQL..."
        local newrelic_db_password=$(openssl rand -base64 32)
        
        sudo -u postgres psql -d foodme << EOF
-- Create monitoring user
CREATE USER newrelic WITH PASSWORD '$newrelic_db_password';

-- Grant necessary permissions for monitoring
GRANT CONNECT ON DATABASE foodme TO newrelic;
GRANT USAGE ON SCHEMA public TO newrelic;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO newrelic;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO newrelic;
GRANT pg_read_all_stats TO newrelic;

-- Grant permissions for database stats
GRANT pg_monitor TO newrelic;

-- Ensure future tables are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO newrelic;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO newrelic;

-- Test the connection
SELECT 1;
EOF
        
        # Create the integration configuration directory
        mkdir -p /etc/newrelic-infra/integrations.d
        
        # Create PostgreSQL integration configuration
        log "Creating PostgreSQL integration configuration..."
        cat > /etc/newrelic-infra/integrations.d/postgresql-config.yml << EOF
integrations:
  - name: nri-postgresql
    env:
      HOSTNAME: localhost
      PORT: 5432
      USERNAME: newrelic
      DATABASE: foodme
      PASSWORD: $newrelic_db_password
      SSL_MODE: disable
      CONNECTION_TIMEOUT: 5
      METRICS: true
      INVENTORY: true
      COLLECTION_LIST: ALL
      ENABLE_QUERY_MONITORING: true
      COLLECT_DB_LOCK_METRICS: true
      COLLECT_BLOAT_METRICS: true
      CUSTOM_ATTRIBUTES: '{"service":"postgresql","environment":"$environment","application":"foodme","database":"foodme","deployment":"ec2"}'
      CUSTOM_METRICS_QUERY: |
        SELECT 
          'database_size' as metric_name,
          'gauge' as metric_type,
          pg_database_size('foodme') as metric_value,
          'bytes' as metric_unit
        UNION ALL
        SELECT 
          'active_connections' as metric_name,
          'gauge' as metric_type,
          COUNT(*) as metric_value,
          'connections' as metric_unit
        FROM pg_stat_activity 
        WHERE state = 'active'
        UNION ALL
        SELECT 
          'idle_connections' as metric_name,
          'gauge' as metric_type,
          COUNT(*) as metric_value,
          'connections' as metric_unit
        FROM pg_stat_activity 
        WHERE state = 'idle';
    interval: 30s
    labels:
      env: $environment
      role: database
      service: postgresql
      application: foodme
      deployment: ec2
    inventory_source: config/postgresql
EOF
        
        # Set proper permissions
        chown root:root /etc/newrelic-infra/integrations.d/postgresql-config.yml
        chmod 644 /etc/newrelic-infra/integrations.d/postgresql-config.yml
        
        # Test the integration
        log "Testing PostgreSQL integration..."
        if PGPASSWORD="$newrelic_db_password" psql -h localhost -p 5432 -U newrelic -d foodme -c "SELECT 1;" > /dev/null 2>&1; then
            log "✅ PostgreSQL integration connection test successful"
        else
            log "⚠️  PostgreSQL integration connection test failed - check configuration"
        fi
        
        # Restart New Relic Infrastructure to pick up the new integration
        systemctl restart newrelic-infra
        
        log "PostgreSQL monitoring configuration completed"
    else
        log "PostgreSQL monitoring disabled (no New Relic license key provided)"
    fi
}

# Configure Nginx monitoring for New Relic
configure_nginx_monitoring() {
    local license_key="$1"
    local environment="$2"
    
    if [[ -n "$license_key" && "$license_key" != "REPLACE_WITH_YOUR_LICENSE_KEY" ]]; then
        log "Setting up Nginx monitoring for New Relic..."
        
        # Install Nginx integration
        log "Installing New Relic Nginx integration..."
        dnf install -y nri-nginx
        
        # Ensure stub_status module is available (should be included by default)
        log "Verifying Nginx status module..."
        if nginx -V 2>&1 | grep -q "http_stub_status_module"; then
            log "✅ Nginx status module is available"
        else
            log "⚠️  Nginx status module not found - some metrics may be limited"
        fi
        
        # Create the integration configuration directory if it doesn't exist
        mkdir -p /etc/newrelic-infra/integrations.d
        
        # Create Nginx integration configuration
        log "Creating Nginx integration configuration..."
        cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << EOF
integrations:
  - name: nri-nginx
    env:
      # Status URL for nginx stub_status module
      STATUS_URL: http://127.0.0.1:8080/nginx_status
      
      # Connection settings
      CONNECTION_TIMEOUT: 5
      
      # Metrics collection settings
      METRICS: true
      INVENTORY: true
      
      # Custom attributes for better organization
      CUSTOM_ATTRIBUTES: '{"service":"nginx","environment":"$environment","application":"foodme","role":"web-server","deployment":"ec2"}'
      
      # Optional: Parse nginx access logs for additional metrics
      ACCESS_LOG_PATH: /var/log/nginx/access.log
      ERROR_LOG_PATH: /var/log/nginx/error.log
      
      # Log parsing format (combined is default nginx format)
      LOG_FORMAT: combined
      
      # Enable log metrics collection
      COLLECT_LOG_METRICS: true
      
    interval: 30s
    labels:
      env: $environment
      role: web-server
      service: nginx
      application: foodme
      deployment: ec2
    inventory_source: config/nginx
EOF
        
        # Set proper permissions for the configuration file
        chown root:root /etc/newrelic-infra/integrations.d/nginx-config.yml
        chmod 644 /etc/newrelic-infra/integrations.d/nginx-config.yml
        
        # Ensure nginx log directory permissions allow New Relic to read logs
        log "Configuring Nginx log permissions for monitoring..."
        chmod 755 /var/log/nginx
        chmod 644 /var/log/nginx/*.log 2>/dev/null || true
        
        # Note: New Relic Infrastructure agent runs as root, no user group changes needed
        # The agent has proper permissions to read nginx logs via file system permissions
        
        # Test the status endpoint
        log "Testing Nginx status endpoint..."
        if curl -s http://127.0.0.1:8080/nginx_status > /dev/null 2>&1; then
            log "✅ Nginx status endpoint test successful"
            # Show a sample of the status output
            log "Status endpoint sample:"
            curl -s http://127.0.0.1:8080/nginx_status | head -3
        else
            log "⚠️  Nginx status endpoint test failed - check nginx configuration"
            log "Nginx should be configured with stub_status on port 8080"
        fi
        
        # Restart New Relic Infrastructure to pick up the new integration
        systemctl restart newrelic-infra
        
        log "Nginx monitoring configuration completed"
    else
        log "Nginx monitoring disabled (no New Relic license key provided)"
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
    
    # Run schema initialization from local files if they exist
    if [ -f "/opt/foodme/database/init/01-init-schema.sql" ]; then
        log "Running local database schema initialization..."
        sudo -u postgres psql foodme < /opt/foodme/database/init/01-init-schema.sql
        
        if [ -f "/opt/foodme/database/init/02-import-restaurants-uuid.sql" ]; then
            log "Importing restaurant data..."
            sudo -u postgres psql foodme < /opt/foodme/database/init/02-import-restaurants-uuid.sql
        fi
    else
        log "Warning: Local database initialization scripts not found"
    fi
}

# Start application services
start_services() {
    log "Starting application services..."
    
    # Start backend with PM2
    log "Starting backend application with PM2..."
    cd /opt/foodme/backend
    
    # Kill any existing PM2 processes
    sudo -u ec2-user pm2 kill 2>/dev/null || true
    
    # Start the application
    if sudo -u ec2-user pm2 start ecosystem.config.js; then
        log "✅ Backend started successfully with PM2"
        sudo -u ec2-user pm2 save
        
        # Setup PM2 startup script
        pm2 startup systemd -u ec2-user --hp /home/ec2-user
    else
        log "❌ Failed to start backend with PM2, trying direct node start..."
        # Fallback to direct node start
        nohup node start.js > /opt/foodme/logs/backend.log 2>&1 &
        log "✅ Backend started directly with node"
    fi
    
    # Ensure Nginx is enabled and running
    log "Starting and enabling Nginx..."
    systemctl enable nginx
    if systemctl restart nginx; then
        log "✅ Nginx started and enabled successfully"
    else
        log "❌ Failed to start Nginx"
        systemctl status nginx
        exit 1
    fi
    
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
    log "📋 Step 1/12: Configuring PostgreSQL..."
    configure_postgresql "$db_password"
    
    log "📋 Step 2/12: Setting up PostgreSQL monitoring extensions..."
    setup_postgresql_monitoring
    
    log "📋 Step 3/12: Installing application dependencies..."
    install_application_dependencies
    
    log "📋 Step 4/12: Setting up application structure..."
    setup_application_structure
    
    log "📋 Step 5/12: Deploying backend application..."
    deploy_backend_application "$s3_bucket" "$db_password" "$new_relic_key" "$environment" "$node_env"
    
    log "📋 Step 6/12: Deploying frontend application..."
    deploy_frontend_application "$s3_bucket"
    
    log "📋 Step 7/12: Configuring Nginx..."
    configure_nginx
    
    log "📋 Step 8/12: Configuring New Relic Infrastructure..."
    configure_new_relic "$new_relic_key" "$environment"
    
    log "📋 Step 9/12: Configuring PostgreSQL monitoring..."
    configure_postgresql_monitoring "$new_relic_key" "$environment" "$db_password"
    
    log "📋 Step 10/12: Configuring Nginx monitoring..."
    configure_nginx_monitoring "$new_relic_key" "$environment"
    
    log "📋 Step 11/12: Initializing database..."
    initialize_database "$db_password" "$s3_bucket"
    
    log "📋 Step 12/12: Starting services..."
    start_services
    
    log "🔍 Verifying deployment..."
    verify_deployment
    
    log "=== FoodMe Application Deployment Completed Successfully ==="
}

# Execute main function with parameters
main "$@"