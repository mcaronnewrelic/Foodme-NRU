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
EOF
chmod 640 /etc/newrelic-infra.yml
chown root:newrelic-infra /etc/newrelic-infra.yml

# Configure New Relic integrations
mkdir -p /etc/newrelic-infra/integrations.d
cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << 'EOF'
integrations:
  - name: nri-nginx
    env:
      STATUS_URL: http://localhost/nginx_status
      METRICS: true
      CUSTOM_ATTRIBUTES: '{"service":"nginx","environment":"'"${environment}"'","application":"foodme"}'
    interval: 30s
EOF

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
      CUSTOM_ATTRIBUTES: '{"service":"postgresql","environment":"'"${environment}"'","application":"foodme"}'
    interval: 30s
EOF
chmod 640 /etc/newrelic-infra/integrations.d/*.yml
chown root:newrelic-infra /etc/newrelic-infra/integrations.d/*.yml

# Initialize and configure PostgreSQL
postgresql-setup --initdb --unit postgresql-16
cat >> /var/lib/pgsql/16/data/postgresql.conf << EOF
listen_addresses = 'localhost'
port = ${db_port}
max_connections = 100
shared_buffers = 256MB
EOF

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
CREATE TABLE restaurants (id SERIAL PRIMARY KEY, name VARCHAR(255), description TEXT, rating DECIMAL(2,1), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE menu_items (id SERIAL PRIMARY KEY, restaurant_id INTEGER REFERENCES restaurants(id), name VARCHAR(255), price DECIMAL(10,2), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE customers (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE orders (id SERIAL PRIMARY KEY, customer_id INTEGER REFERENCES customers(id), restaurant_id INTEGER REFERENCES restaurants(id), total_amount DECIMAL(10,2), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO restaurants (name, description, rating) VALUES ('The Burger Joint', 'Best burgers in town', 4.5), ('Pasta Palace', 'Authentic Italian cuisine', 4.7), ('Sushi Zen', 'Fresh sushi and Japanese dishes', 4.8);
EOF

# Create directories
mkdir -p /var/www/foodme /var/log/foodme /var/www/foodme/server
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme

# Create nginx configuration
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    gzip on;
    gzip_types application/javascript application/json text/css text/plain;
    location = /health { proxy_pass http://localhost:3000/health; access_log off; }
    location = /nginx_status { stub_status on; access_log off; allow 127.0.0.1; allow 10.0.0.0/8; deny all; }
    location /api/ { proxy_pass http://localhost:3000; proxy_set_header Host $host; }
    location / { proxy_pass http://localhost:3000; proxy_set_header Host $host; }
}
EOF

# Create systemd service
cat > /etc/systemd/system/foodme.service << EOF
[Unit]
Description=FoodMe Node.js Application
After=network.target postgresql-16.service
Requires=postgresql-16.service
[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme/dist/server
ExecStart=/usr/bin/node start.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=NEW_RELIC_LICENSE_KEY=$${NEW_RELIC_LICENSE_KEY}
Environment=NEW_RELIC_APP_NAME=FoodMe-$${ENVIRONMENT}
Environment=DB_HOST=localhost
Environment=DB_PORT=$${DB_PORT}
Environment=DB_NAME=$${DB_NAME}
Environment=DB_USER=$${DB_USER}
Environment=DB_PASSWORD=$${DB_PASSWORD}
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF

# Create deployment script
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e
cd /var/www/foodme/dist/server
if [ -f "package.json" ]; then
    npm install --production
    sudo systemctl restart foodme
fi
sleep 15
curl -f http://localhost:3000/health && echo "✅ Deployment successful!" || echo "❌ Health check failed"
EOF
chmod +x /var/www/foodme/deploy.sh
chown ec2-user:ec2-user /var/www/foodme/deploy.sh

# Start services
sudo -u ec2-user bash -c 'cd /var/www/foodme/server && npm install' || true
systemctl daemon-reload
systemctl enable nginx foodme newrelic-infra
systemctl start nginx foodme newrelic-infra

echo "EC2 setup completed at $(date)"
