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
mkdir -p /var/www/foodme /var/log/foodme /var/www/foodme/server /home/ec2-user/foodme/config
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme /home/ec2-user/foodme

# Configure Nginx: Download from GitHub
wget -O /etc/nginx/conf.d/foodme.conf https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/nginx.conf
# Configure New Relic integrations
wget -O /etc/newrelic-infra/integrations.d/nginx-config.yml https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/nginx-config.yml
wget -O /etc/newrelic-infra/integrations.d/postgres-config.yml https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/postgres-config.yml
# Configure Systemd service
wget -O /etc/systemd/system/foodme.service https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/foodme.service
# Get health check and deploy scripts
wget -O /home/ec2-user/foodme/config/health-check.sh https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/health-check.sh
wget -O /home/ec2-user/foodme/config/deploy.sh https://raw.githubusercontent.com/your-repo/foodme/main/terraform/configs/deploy.sh

#Initialize and configure PostgreSQL
wget -O /home/ec2-user/foodme/db/01-init-schema.sql https://raw.githubusercontent.com/your-repo/foodme/main/db/init/01-init-schema.sql
wget -O /home/ec2-user/foodme/db/02-import-restaurants-uuid.sql https://raw.githubusercontent.com/your-repo/foodme/main/db/init/02-import-restaurants-uuid.sql
sudo -u postgres psql -d ${db_name} -a -f /home/ec2-user/foodme/db/01-init-schema.sql
sudo -u postgres psql -d ${db_name} -a -f /home/ec2-user/foodme/db/02-import-restaurants-uuid.sql

# Make scripts executable
chmod +x /home/ec2-user/foodme/config/*.sh
chown -R ec2-user:ec2-user /home/ec2-user/foodme/

# Start services
sudo -u ec2-user bash -c 'cd /var/www/foodme/server && npm install' || true
systemctl daemon-reload
systemctl enable nginx foodme newrelic-infra
systemctl start nginx foodme newrelic-infra

echo "EC2 setup completed at $(date)"
