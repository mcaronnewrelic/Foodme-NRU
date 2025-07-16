#!/bin/bash
exec > >(tee -a /var/log/user-data-execution.log)
exec 2>&1

echo "🚀 ===== FOODME USER_DATA SCRIPT START ====="
echo "📅 Timestamp: $(date)"
echo "🔧 Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo 'unknown')"
echo "🌍 Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region || echo 'unknown')"
echo "================================================"

# Function to log progress
log_progress() {
    echo "🔄 PROGRESS: $1 - $(date)"
    echo "🔄 PROGRESS: $1 - $(date)" >> /var/log/cloud-init-output.log
}

# Enable strict error handling only after initial setup
set -e
log_progress "Starting user_data script execution"
# Variables from Terraform
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
APP_VERSION="${app_version}"
NEW_RELIC_LICENSE_KEY="${new_relic_license_key}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_PORT="${db_port}"

# Update and install packages with timeout and error handling
echo "📦 Updating system packages..."
timeout 300 dnf update -y

echo "📦 Installing required packages..."
timeout 300 dnf install -y git wget nginx htop unzip amazon-cloudwatch-agent nodejs npm postgresql16-server postgresql16 postgresql16-contrib --allowerasing 

# Install Node.js 22 with timeout
echo "📦 Installing Node.js 22..."
timeout 120 curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
timeout 120 dnf install -y nodejs || echo "⚠️ Node.js installation failed"
log_progress "Package installation completed, starting New Relic setup"
# Install New Relic Infrastructure Agent with compatibility fixes
echo "📦 Installing New Relic Infrastructure Agent..."
if timeout 60 curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2023/x86_64/newrelic-infra.repo; then
    if timeout 120 dnf -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'; then
        # Install with --skip-broken to handle dependency issues
        if timeout 180 dnf install -y newrelic-infra nri-nginx nri-postgresql --skip-broken; then
            echo "✅ New Relic components installed"
        else
            echo "❌ New Relic installation failed due to dependency conflicts (common on AL2023)"
        fi
    fi
fi

log_progress "New Relic setup completed, configuring New Relic agent"

# Configure New Relic (if installed)
if command -v newrelic-infra >/dev/null 2>&1; then
    cat > /etc/newrelic-infra.yml << EOF
license_key: ${new_relic_license_key}
display_name: FoodMe-${environment}-EC2
log_file: /var/log/newrelic-infra/newrelic-infra.log
verbose: 0
EOF
    chmod 640 /etc/newrelic-infra.yml
    chown root:newrelic-infra /etc/newrelic-infra.yml 2>/dev/null || chown root:root /etc/newrelic-infra.yml
    echo "✅ New Relic configured"
else
    echo "⚠️ New Relic not installed, skipping configuration"
fi

log_progress "New Relic configuration completed, starting PostgreSQL installation"

# Install and configure PostgreSQL 16
echo "📦 Installing PostgreSQL 16..."
dnf install -y postgresql16-server postgresql16 postgresql16-contrib

# Initialize and start PostgreSQL
echo "🔧 Setting up PostgreSQL..."
/usr/pgsql-16/bin/postgresql-16-setup initdb || sudo -u postgres /usr/pgsql-16/bin/initdb -D /var/lib/pgsql/16/data/

if [ -f "/var/lib/pgsql/16/data/postgresql.conf" ]; then
    # Basic PostgreSQL configuration
    echo "port = ${db_port}" >> /var/lib/pgsql/16/data/postgresql.conf
    echo "listen_addresses = 'localhost'" >> /var/lib/pgsql/16/data/postgresql.conf
    
    # Simple authentication setup
    cat > /var/lib/pgsql/16/data/pg_hba.conf << EOF
local all all peer
host all all 127.0.0.1/32 scram-sha-256
host all all ::1/128 scram-sha-256
EOF
    chown -R postgres:postgres /var/lib/pgsql/16/data/ && chmod 700 /var/lib/pgsql/16/data/
    
    # Start PostgreSQL and create database
    systemctl enable postgresql-16 && systemctl start postgresql-16
    sleep 10  # Wait for startup
    
    # Create database and user
    sudo -u postgres psql << EOF || echo "⚠️ DB setup failed, continuing..."
CREATE USER ${db_user} WITH PASSWORD '${db_password}';
CREATE DATABASE ${db_name} OWNER ${db_user};
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};
EOF
    echo "✅ PostgreSQL setup completed"
else
    echo "❌ PostgreSQL init failed, skipping"
    SKIP_POSTGRES=true
fi
log_progress "PostgreSQL setup completed, creating directories and downloading configs"

# Create directories
mkdir -p /var/www/foodme /var/log/foodme /var/www/foodme/server /home/ec2-user/foodme/config /home/ec2-user/foodme/db
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme /home/ec2-user/foodme

# Function to download files with retry
download_config_file() {
    local url="$1" output_path="$2" i=0
    while [ $i -lt 3 ]; do
        if wget -q --timeout=30 -O "$output_path" "$url" 2>/dev/null && [ -s "$output_path" ]; then
            echo "✅ Downloaded $(basename $output_path)"
            return 0
        fi
        i=$((i+1))
        [ $i -lt 3 ] && sleep $((i*2))
    done
    echo "❌ Failed to download $(basename $output_path)"
    return 1
}

# Download configuration files with error handling
echo "Downloading configuration files from GitHub..."

# Configure Nginx
if ! download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/nginx.conf" "/etc/nginx/conf.d/foodme.conf"; then
    echo "⚠️ Failed to download nginx.conf"
fi

# Configure New Relic integrations (basic setup)
if [ -d "/etc/newrelic-infra/integrations.d" ]; then
    cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << 'EOF'
integrations:
  - name: nri-nginx
    env:
      STATUS_URL: http://localhost/nginx_status
      METRICS: true
    interval: 30s
EOF
    cat > /etc/newrelic-infra/integrations.d/postgres-config.yml << EOF
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
    echo "✅ New Relic integrations configured"
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
    echo "⚠️ Failed to download deploy.sh"
}
# Download database schema files
if [ "$SKIP_POSTGRES" != "true" ] && download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/db/init/01-init-schema.sql" "/home/ec2-user/foodme/db/01-init-schema.sql"; then
    echo "Executing database schema initialization..."
    if timeout 120 sudo -u postgres psql -d ${db_name} -a -f /home/ec2-user/foodme/db/01-init-schema.sql; then
        echo "✅ Database schema initialized successfully"
    else
        echo "❌ Failed to execute schema initialization (timeout or error)"
    fi
else
    echo "⚠️ Schema file not available or PostgreSQL not configured"
fi

# Download sample data
if [ "$SKIP_POSTGRES" != "true" ] && download_config_file "https://raw.githubusercontent.com/your-repo/foodme/main/db/init/02-import-restaurants-uuid.sql" "/home/ec2-user/foodme/db/02-import-restaurants-uuid.sql"; then
    echo "Importing sample restaurant data..."
    if timeout 60 sudo -u postgres psql -d ${db_name} -a -f /home/ec2-user/foodme/db/02-import-restaurants-uuid.sql; then
        echo "✅ Sample data imported successfully"
    else
        echo "❌ Failed to import sample data (timeout or error), but continuing..."
    fi
else
    echo "⚠️ Sample data file not available or PostgreSQL not configured"
fi

# Make scripts executable and set proper ownership
chmod +x /home/ec2-user/foodme/config/*.sh 2>/dev/null || echo "No scripts to make executable"
chown -R ec2-user:ec2-user /home/ec2-user/foodme/

# Set proper permissions for downloaded config files
chmod 640 /etc/newrelic-infra/integrations.d/*.yml 2>/dev/null || echo "No New Relic integration files to set permissions"
chown root:newrelic-infra /etc/newrelic-infra/integrations.d/*.yml 2>/dev/null || echo "No New Relic integration files to change ownership"

systemctl daemon-reload

# Start services one by one with error checking
if systemctl enable nginx; then
    echo "✅ Enabled nginx"
else
    echo "❌ Failed to enable nginx"
fi

if systemctl start nginx; then
    echo "✅ Started nginx"
else
    echo "❌ Failed to start nginx"
    systemctl status nginx --no-pager || true
fi

# Only try to start New Relic if it's installed
if command -v newrelic-infra >/dev/null 2>&1; then
    if systemctl enable newrelic-infra; then
        echo "✅ Enabled newrelic-infra"
    else
        echo "❌ Failed to enable newrelic-infra"
    fi
    
    if systemctl start newrelic-infra; then
        echo "✅ Started newrelic-infra"
    else
        echo "❌ Failed to start newrelic-infra"
        systemctl status newrelic-infra --no-pager || true
    fi
else
    echo "⚠️ New Relic Infrastructure Agent not installed, skipping service start"
fi

echo "✅ EC2 setup completed at $(date)"
echo "�📅 End timestamp: $(date)"
echo "⏱️  Total execution time: $SECONDS seconds"
echo "📄 Full log available at: /var/log/user-data-execution.log"
echo "=================================================="
