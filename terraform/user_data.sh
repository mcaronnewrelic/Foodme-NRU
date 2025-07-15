#!/bin/bash
set -e

# Variables from Terraform
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
APP_VERSION="${app_version}"
NEW_RELIC_LICENSE_KEY="${new_relic_license_key}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_PORT="${db_port}"

# Update and install packages
dnf update -y
dnf install -y git wget nginx htop unzip amazon-cloudwatch-agent nodejs npm postgresql16-server postgresql16 postgresql16-contrib --allowerasing

# Install Node.js 22
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs
npm install -g pm2

# Install New Relic Infrastructure Agent
curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2/x86_64/newrelic-infra.repo
dnf -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
dnf install -y newrelic-infra nri-nginx nri-postgresql

# Configure New Relic Infrastructure Agent
cat > /etc/newrelic-infra.yml << EOF
license_key: ${new_relic_license_key}
display_name: FoodMe-${environment}-EC2
log_file: /var/log/newrelic-infra/newrelic-infra.log
verbose: 0
passthrough_environment:
  - DB_PORT
  - DB_NAME
  - DB_USER
  - DB_PASSWORD
EOF
chmod 640 /etc/newrelic-infra.yml
chown root:newrelic-infra /etc/newrelic-infra.yml

# Set proper permissions for integration configs
chmod 640 /etc/newrelic-infra/integrations.d/*.yml
chown root:newrelic-infra /etc/newrelic-infra/integrations.d/*.yml

echo "New Relic integrations configuration completed"

# Install and configure PostgreSQL 16
echo "Installing PostgreSQL 16..."
dnf install -y postgresql16-server postgresql16 postgresql16-contrib

# Initialize PostgreSQL database
echo "Initializing PostgreSQL database..."
postgresql-setup --initdb --unit postgresql-16
cat >> /var/lib/pgsql/16/data/postgresql.conf << EOF
listen_addresses = 'localhost'
port = ${db_port}
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
ssl = off
password_encryption = scram-sha-256
EOF

# Configure pg_hba.conf for authentication
cat > /var/lib/pgsql/16/data/pg_hba.conf << EOF
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             10.0.0.0/8              scram-sha-256
host    all             all             ::1/128                 scram-sha-256
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF
chown -R postgres:postgres /var/lib/pgsql/16/data/
chmod 700 /var/lib/pgsql/16/data/
chmod 600 /var/lib/pgsql/16/data/postgresql.conf /var/lib/pgsql/16/data/pg_hba.conf

# Start PostgreSQL and create database
systemctl enable postgresql-16
systemctl start postgresql-16
sleep 10

sudo -u postgres psql << EOF
CREATE USER ${db_user} WITH PASSWORD '${db_password}';
CREATE DATABASE ${db_name} OWNER ${db_user};
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};
\c ${db_name}
GRANT ALL ON SCHEMA public TO ${db_user};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${db_user};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${db_user};

-- Alter default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${db_user};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${db_user};
EOF
echo "PostgreSQL 16 setup completed successfully"

# Create directories
mkdir -p /var/www/foodme /var/log/foodme /var/www/foodme/server /home/ec2-user/foodme/config /home/ec2-user/foodme/db
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme /home/ec2-user/foodme

# Function to download files with retry and error handling
download_config_file() {
    local url="$1"
    local output_path="$2"
    local max_retries=3
    local retry_count=0
    local wait_time=5
    
    echo "Downloading $url to $output_path..."
    
    while [ $retry_count -lt $max_retries ]; do
        if wget --timeout=30 --tries=1 --no-check-certificate -O "$output_path" "$url" 2>/dev/null; then
            if [ -f "$output_path" ] && [ -s "$output_path" ]; then
                echo "✅ Successfully downloaded $(basename $output_path)"
                return 0
            else
                echo "⚠️ Downloaded file is empty: $(basename $output_path)"
            fi
        else
            echo "❌ Failed to download $(basename $output_path) (attempt $((retry_count + 1))/$max_retries)"
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "Retrying in $wait_time seconds..."
            sleep $wait_time
            wait_time=$((wait_time * 2))  # Exponential backoff
        fi
    done
    
    echo "❌ Failed to download $url after $max_retries attempts"
    return 1
}

# Download configuration files with error handling
echo "Downloading configuration files from GitHub..."

# Configure Nginx
if ! download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/nginx.conf" "/etc/nginx/conf.d/foodme.conf"; then
    echo "⚠️ Failed to download nginx.conf, creating fallback configuration..."
    cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    location = /health { proxy_pass http://localhost:3000/health; }
    location = /nginx_status { stub_status on; allow 127.0.0.1; deny all; }
    location /api/ { proxy_pass http://localhost:3000; proxy_set_header Host $host; }
    location / { proxy_pass http://localhost:3000; proxy_set_header Host $host; }
}
EOF
    echo "✅ Created fallback nginx configuration"
fi

# Configure New Relic integrations
if ! download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/nginx-config.yml" "/etc/newrelic-infra/integrations.d/nginx-config.yml"; then
    echo "⚠️ Failed to download nginx-config.yml, creating fallback..."
    cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << 'EOF'
integrations:
  - name: nri-nginx
    env:
      STATUS_URL: http://localhost/nginx_status
      METRICS: true
    interval: 30s
EOF
fi

if ! download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/postgres-config.yml" "/etc/newrelic-infra/integrations.d/postgres-config.yml"; then
    echo "⚠️ Failed to download postgres-config.yml, creating fallback..."
    cat > /etc/newrelic-infra/integrations.d/postgres-config.yml << 'EOF'
integrations:
  - name: nri-postgresql
    env:
      HOSTNAME: localhost
      PORT: ${db_port}
      USERNAME: ${db_user}
      DATABASE: ${db_name}
      PASSWORD: ${db_password}
      METRICS: true
    interval: 30s
EOF
fi

# Configure Systemd service
if ! download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/foodme.service" "/etc/systemd/system/foodme.service"; then
    echo "⚠️ Failed to download foodme.service"
fi

# Get health check and deploy scripts
download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/health-check.sh" "/home/ec2-user/foodme/config/health-check.sh" || {
    echo "⚠️ Failed to download health-check.sh, creating basic version..."
    cat > /home/ec2-user/foodme/config/health-check.sh << 'EOF'
#!/bin/bash
curl -f http://localhost:3000/health || exit 1
EOF
}

download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/deploy.sh" "/home/ec2-user/foodme/config/deploy.sh" || {
    echo "⚠️ Failed to download deploy.sh, creating basic version..."
    cat > /home/ec2-user/foodme/config/deploy.sh << 'EOF'
#!/bin/bash
set -e
cd /var/www/foodme/dist/server
npm install --production
sudo systemctl restart foodme
EOF
}

# Initialize database with downloaded SQL files
echo "Downloading database initialization files..."

# Download database schema files
if download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/db/init/01-init-schema.sql" "/home/ec2-user/foodme/db/01-init-schema.sql"; then
    echo "Executing database schema initialization..."
    if sudo -u postgres psql -d ${db_name} -a -f /home/ec2-user/foodme/db/01-init-schema.sql; then
        echo "✅ Database schema initialized successfully"
    else
        echo "❌ Failed to execute schema initialization"
    fi
fi

# Download sample data
if download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/db/init/02-import-restaurants-uuid.sql" "/home/ec2-user/foodme/db/02-import-restaurants-uuid.sql"; then
    echo "Importing sample restaurant data..."
    if sudo -u postgres psql -d ${db_name} -a -f /home/ec2-user/foodme/db/02-import-restaurants-uuid.sql; then
        echo "✅ Sample data imported successfully"
    else
        echo "❌ Failed to import sample data, but continuing..."
    fi
fi

# Make scripts executable and set proper ownership
chmod +x /home/ec2-user/foodme/config/*.sh 2>/dev/null || echo "No scripts to make executable"
chown -R ec2-user:ec2-user /home/ec2-user/foodme/

# Set proper permissions for downloaded config files
chmod 640 /etc/newrelic-infra/integrations.d/*.yml 2>/dev/null || echo "No New Relic integration files to set permissions"
chown root:newrelic-infra /etc/newrelic-infra/integrations.d/*.yml 2>/dev/null || echo "No New Relic integration files to change ownership"

# Verify critical files exist before starting services
echo "Verifying configuration files..."
MISSING_FILES=0

if [ ! -f "/etc/nginx/conf.d/foodme.conf" ]; then
    echo "❌ Missing nginx configuration"
    MISSING_FILES=$((MISSING_FILES + 1))
else
    echo "✅ Nginx configuration found"
fi

if [ ! -f "/etc/systemd/system/foodme.service" ]; then
    echo "❌ Missing systemd service file"
    MISSING_FILES=$((MISSING_FILES + 1))
else
    echo "✅ Systemd service file found"
fi

if [ $MISSING_FILES -gt 0 ]; then
    echo "⚠️ $MISSING_FILES critical configuration files are missing"
    echo "Deployment may have issues, but continuing..."
else
    echo "✅ All critical configuration files are present"
fi

# Start services with error checking
echo "Starting services..."
sudo -u ec2-user bash -c 'cd /var/www/foodme/server && npm install' || echo "⚠️ npm install failed or no package.json found"

systemctl daemon-reload

# Start services one by one with error checking
for service in nginx newrelic-infra; do
    if systemctl enable $service; then
        echo "✅ Enabled $service"
    else
        echo "❌ Failed to enable $service"
    fi
    
    if systemctl start $service; then
        echo "✅ Started $service"
    else
        echo "❌ Failed to start $service"
        systemctl status $service --no-pager || true
    fi
done

# Note: foodme service will be started by GitHub Actions deployment

echo "✅ EC2 setup completed at $(date)"
echo "📊 Configuration summary:"
echo "  - PostgreSQL 16: $(systemctl is-active postgresql-16 2>/dev/null || echo 'inactive')"
echo "  - Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'inactive')"
echo "  - New Relic: $(systemctl is-active newrelic-infra 2>/dev/null || echo 'inactive')"
echo "  - FoodMe app: Will be started by deployment process"
