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
export NRIA_MODE="PRIVILEGED" 
# Enable strict error handling only after initial setup
set -e
log_progress "Starting user_data script execution"
# Variables from Terraform
tee "/etc/profile.d/my-custom-vars.sh" > /dev/null << 'EOF'
export APP_PORT="${app_port}"
export ENVIRONMENT="${environment}"
export APP_VERSION="${app_version}"
export NEW_RELIC_LICENSE_KEY="${new_relic_license_key}"
export DB_NAME="${db_name}"
export DB_USER="${db_user}"
export DB_PASSWORD="${db_password}"
export DB_PORT="${db_port}"
export PGDATA_PATH="${pgdata_path}"
EOF
sudo chmod +x "/etc/profile.d/my-custom-vars.sh"

# Update and install packages and error handling
echo "📦 Updating system packages..."
dnf update -y

echo "📦 Installing required packages..."
dnf install -y git wget nginx htop unzip amazon-cloudwatch-agent npm postgresql16-server postgresql16 postgresql16-contrib libcap nano --allowerasing 

# Install Node.js 22 
echo "📦 Installing Node.js 22..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs22 || echo "⚠️ Node.js installation failed"
alternatives --set node /usr/bin/node-22
log_progress "Package installation completed, starting New Relic setup"

# Install New Relic Infrastructure Agent in privileged mode

log_progress "Privileged mode set for New Relic Infrastructure Agent installation"
echo "📦 Installing New Relic Infrastructure Agent..."
if curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2023/x86_64/newrelic-infra.repo; then
    if dnf -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'; then
        # Install with --skip-broken to handle dependency issues
        if dnf install -y fluent-bit newrelic-infra nri-nginx nri-postgresql --skip-broken; then
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
    chown root:newrelic /etc/newrelic-infra.yml 2>/dev/null || chown root:root /etc/newrelic-infra.yml
    echo "✅ New Relic configured"
else
    echo "⚠️ New Relic not installed, skipping configuration"
fi

log_progress "New Relic configuration completed, starting PostgreSQL installation"

# Initialize and start PostgreSQL
echo "🔧 Setting up PostgreSQL..."
sudo -u postgres /usr/bin/initdb -D "${pgdata_path}"

if [ -f "${pgdata_path}/postgresql.conf" ]; then
    # Basic PostgreSQL configuration
    tee "port = ${db_port}" >> ${pgdata_path}/postgresql.conf
    tee "listen_addresses = 'localhost'" >> ${pgdata_path}/postgresql.conf
    sudo -u postgres sed -i "s/^#log_destination = 'stderr'/log_destination = 'csvlog'/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_directory = 'log'/log_directory = 'log'/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_file_mode = 0600/log_file_mode = 0640/" "${pgdata_path}/postgresql.conf" # Readable by group
    sudo -u postgres sed -i "s/^#log_rotation_size = 10MB/log_rotation_size = 10MB/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_checkpoints = off/log_checkpoints = on/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_connections = off/log_connections = on/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_disconnections = off/log_disconnections = on/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_duration = off/log_duration = on/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_error_verbosity = default/log_error_verbosity = verbose/" "${pgdata_path}/postgresql.conf" # 'verbose' includes SQLSTATE
    sudo -u postgres sed -i "s/^#log_lock_waits = off/log_lock_waits = on/" "${pgdata_path}/postgresql.conf"
    sudo -u postgres sed -i "s/^#log_temp_files = -1/log_temp_files = 0/" "${pgdata_path}/postgresql.conf" # Log temp files larger than 0KB
    sudo -u postgres sed -i "s/^#log_autovacuum_min_duration = -1/log_autovacuum_min_duration = 0/" "${pgdata_path}/postgresql.conf" # Log all autovacuum actions
    sudo -u postgres sed -i "s/^#log_min_duration_statement = -1/log_min_duration_statement = 0/" "${pgdata_path}/postgresql.conf" # Log all statements with their duration

    # Simple authentication setup
    tee ${pgdata_path}/pg_hba.conf << EOF
local all all peer
host all all 127.0.0.1/32 scram-sha-256
host all all ::1/128 scram-sha-256
EOF
    chown -R postgres:postgres ${pgdata_path} && chmod 700 ${pgdata_path}
    
    # Start PostgreSQL and create database
    sudo systemctl enable postgresql && systemctl start postgresql
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
mkdir -p /var/www/foodme /var/log/foodme /var/www/foodme/server /home/ec2-user/foodme/config 
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme /home/ec2-user/foodme

# Download configuration files
echo "Downloading configuration files from GitHub..."

# Configure Nginx
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/terraform/configs/nginx.conf" | sudo tee "/etc/nginx/conf.d/foodme.conf" > /dev/null
# Configure New Relic integrations (basic setup)
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/terraform/configs/nginx-config.yml" | sudo tee "/etc/newrelic-infra/integrations.d/nginx-config.yml" > /dev/null
log_progress "nginx-config completed"
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/terraform/configs/postgres-config.yml" | sudo tee "/etc/newrelic-infra/integrations.d/postgres-config.yml" > /dev/null


# Configure New Relic Infrastructure Logging (Nginx and PostgreSQL)
sudo -u newrelic cp /etc/newrelic-infra/logging.d/nginx-log.yml.example /etc/newrelic-infra/logging.d/nginx-log.yml
sudo -u newrelic cp /etc/newrelic-infra/logging.d/postgresql-log.yml.example /etc/newrelic-infra/logging.d/postgresql-log.yml
echo "    file: /var/lib/pgsql/data/log/postgresql*.log/" | sudo tee -a  "/etc/newrelic-infra/logging.d/postgresql-log.yml" > /dev/null

# Get health check and deploy scripts
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/terraform/configs/health-check.sh" | sudo tee "/home/ec2-user/foodme/config/health-check.sh" > /dev/null
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/terraform/configs/deploy.sh" | sudo tee "/home/ec2-user/foodme/config/deploy.sh" > /dev/null

# Download database schema file
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/db/init/01-init-schema.sql" | sudo tee "/var/lib/pgsql/data/01-init-schema.sql" > /dev/null # do not use the ec2-user home directory for this file, it works better in the PGDATA directory
    if sudo -u postgres psql -d ${db_name} -a -f /var/lib/pgsql/data/01-init-schema.sql; then
        echo "✅ Database schema initialized successfully"
    else
        echo "❌ Failed to execute schema initialization"
    fi

# Download sample data
sudo wget -O - "https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/db/init/02-import-restaurants-uuid.sql" | sudo tee "/var/lib/pgsql/data/02-import-restaurants-uuid.sql" > /dev/null # do not use the ec2-user home directory for this file, it works better in the PGDATA directory
    echo "Importing sample restaurant data..."
    if sudo -u postgres psql -d ${db_name} -a -f /var/lib/pgsql/data/02-import-restaurants-uuid.sql; then
        echo "✅ Sample data imported successfully"
    else
        echo "❌ Failed to import sample data, but continuing..."
    fi

# Make scripts executable and set proper ownership
chmod +x /home/ec2-user/foodme/config/*.sh 2>/dev/null || echo "No scripts to make executable"
chown -R ec2-user:ec2-user /home/ec2-user/foodme/

# Set proper permissions for downloaded config files
chmod 640 /etc/newrelic-infra/integrations.d/*.yml 2>/dev/null || echo "No New Relic integration files to set permissions"
chmod 640 /etc/newrelic-infra/logging.d/*.yml 2>/dev/null || echo "No New Relic integration files to set permissions"
chown root:newrelic /etc/newrelic-infra/integrations.d/*.yml 2>/dev/null || echo "No New Relic integration files to change ownership"
chown root:newrelic /etc/newrelic-infra/logging.d/*.yml 2>/dev/null || echo "No New Relic integration files to change ownership"
sudo chmod g+rX /var/lib/pgsql/data/log
sudo usermod -a -G postgres newrelic
sudo usermod -a -G nginx newrelic

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
