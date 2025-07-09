#!/bin/bash
set -e

# Variables from Terraform
NEW_RELIC_LICENSE_KEY="${new_relic_license_key}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_PORT="${db_port}"

# Install packages
dnf update -y && dnf install -y git nginx nodejs npm amazon-cloudwatch-agent postgresql16-server postgresql16 --allowerasing
npm install -g pm2

# Install New Relic Infrastructure agent
if [ -n "$NEW_RELIC_LICENSE_KEY" ] && [ "$NEW_RELIC_LICENSE_KEY" != "none" ]; then
    echo "Installing New Relic Infrastructure agent..."
    curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2/x86_64/newrelic-infra.repo
    dnf install -y newrelic-infra
    
    # Configure New Relic Infrastructure agent
    cat > /etc/newrelic-infra.yml << EOF
license_key: $NEW_RELIC_LICENSE_KEY
display_name: FoodMe-EC2-${environment}-\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
custom_attributes:
  environment: ${environment}
  application: foodme
  instance_type: \$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
  region: \$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
EOF
    
    # Start and enable New Relic Infrastructure agent
    systemctl enable newrelic-infra
    systemctl start newrelic-infra
    
    # Configure New Relic nginx integration
    mkdir -p /etc/newrelic-infra/integrations.d
    cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << EOF
integrations:
  - name: nri-nginx
    env:
      METRICS: true
      STATUS_URL: http://127.0.0.1/nginx_status
      STATUS_MODULE: discover
      REMOTE_MONITORING: true
    labels:
      environment: ${environment}
      role: webserver
EOF

    # Configure New Relic PostgreSQL integration
    cat > /etc/newrelic-infra/integrations.d/postgres-config.yml << EOF
integrations:
  - name: nri-postgresql
    env:
      HOSTNAME: localhost
      PORT: $DB_PORT
      USERNAME: $DB_USER
      PASSWORD: $DB_PASSWORD
      DATABASE: $DB_NAME
      COLLECT_DB_LOCK_METRICS: true
      COLLECT_BLOAT_METRICS: true
    labels:
      environment: ${environment}
      role: database
EOF

    # Configure nginx status endpoint for monitoring
    cat >> /etc/nginx/conf.d/foodme.conf << 'EOF'

# New Relic nginx monitoring endpoint
server {
    listen 127.0.0.1:80;
    server_name localhost;
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF
    
else
    echo "New Relic license key not provided, skipping Infrastructure agent installation"
fi

# Setup PostgreSQL
echo "Setting up PostgreSQL 16..."
systemctl enable postgresql-16
postgresql-16-setup initdb

# Configure PostgreSQL
cat > /var/lib/pgsql/16/data/postgresql.conf << EOF
# Basic PostgreSQL configuration for FoodMe
listen_addresses = 'localhost'
port = $DB_PORT
max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = posix
max_wal_size = 1GB
min_wal_size = 80MB
log_timezone = 'UTC'
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
EOF

# Configure PostgreSQL authentication
cat > /var/lib/pgsql/16/data/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF

# Start PostgreSQL
systemctl start postgresql-16

# Create database and user
sudo -u postgres psql << EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF

# Setup directories
mkdir -p /var/www/foodme/{server,logs} && chown -R ec2-user:ec2-user /var/www/foodme

# Nginx config
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    location /api/ { proxy_pass http://localhost:3000; }
    location /health { proxy_pass http://localhost:3000/health; access_log off; }
    location / { root /var/www/foodme; try_files $uri $uri/ /index.html; }
}
EOF

# Systemd service
cat > /etc/systemd/system/foodme.service << EOF
[Unit]
Description=FoodMe App
After=network.target postgresql-16.service
[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme
ExecStart=/usr/bin/node server/start.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=NEW_RELIC_LICENSE_KEY=$NEW_RELIC_LICENSE_KEY
Environment=NEW_RELIC_APP_NAME=FoodMe-${environment}
Environment=NEW_RELIC_NO_CONFIG_FILE=true
Environment=DB_HOST=localhost
Environment=DB_PORT=$DB_PORT
Environment=DB_NAME=$DB_NAME
Environment=DB_USER=$DB_USER
Environment=DB_PASSWORD=$DB_PASSWORD
[Install]
WantedBy=multi-user.target
EOF

# Minimal app
cat > /var/www/foodme/package.json << 'EOF'
{"name":"foodme","version":"1.0.0","main":"server/start.js","dependencies":{"express":"^4.18.2"}}
EOF

cat > /var/www/foodme/server/start.js << 'EOF'
const express = require('express');
const app = express();
app.use(express.json());
app.get('/health', (req, res) => res.json({status: 'ok', timestamp: new Date().toISOString(), uptime: process.uptime()}));
app.get('/api/health', (req, res) => res.json({status: 'ok', api: 'ready'}));
app.get('/api/restaurant', (req, res) => res.json({restaurants: []}));
app.get('*', (req, res) => res.send('<!DOCTYPE html><html><head><title>FoodMe</title><style>body{font-family:Arial;text-align:center;padding:50px;background:#667eea}</style></head><body><h1>🍕 FoodMe</h1><p>Application is ready!</p></body></html>'));
app.listen(3000, () => console.log('FoodMe running on port 3000'));
EOF

# Health check script
cat > /var/www/foodme/health-check.sh << 'EOF'
#!/bin/bash
for i in {1..3}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ Health check passed"
        exit 0
    fi
    sleep 2
done
echo "❌ Health check failed"
exit 1
EOF
chmod +x /var/www/foodme/health-check.sh

# Database initialization script
cat > /var/www/foodme/init-database.sh << 'EOF'
#!/bin/bash
set -e
echo "Initializing FoodMe database..."

DB_HOST=$${DB_HOST:-localhost}
DB_PORT=$${DB_PORT:-5432}
DB_NAME=$${DB_NAME:-foodme}
DB_USER=$${DB_USER:-foodme_user}

# Check if database is accessible
if ! PGPASSWORD="$$DB_PASSWORD" psql -h "$$DB_HOST" -p "$$DB_PORT" -U "$$DB_USER" -d "$$DB_NAME" -c '\q' 2>/dev/null; then
    echo "❌ Cannot connect to database"
    exit 1
fi

# Initialize database if db/init directory exists
if [ -d "db/init" ]; then
    echo "Found database initialization files..."
    for sql_file in db/init/*.sql; do
        if [ -f "$$sql_file" ]; then
            echo "Executing: $$sql_file"
            PGPASSWORD="$$DB_PASSWORD" psql -h "$$DB_HOST" -p "$$DB_PORT" -U "$$DB_USER" -d "$$DB_NAME" -f "$$sql_file"
        fi
    done
    echo "✅ Database initialized successfully"
else
    echo "No db/init directory found, skipping database initialization"
fi
EOF
chmod +x /var/www/foodme/init-database.sh

# Deploy script
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e
echo "Deploying FoodMe..."
if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    npm install --production
    [ -d "angular-app" ] && cd angular-app && npm install && npm run build && cd .. && cp -r angular-app/dist/* . 2>/dev/null || true
    
    # Initialize database if it exists
    if [ -f "init-database.sh" ]; then
        echo "Initializing database..."
        ./init-database.sh
    fi
fi
sudo systemctl restart postgresql-16 || true
sudo systemctl restart foodme
sleep 10
/var/www/foodme/health-check.sh && echo "✅ Deploy success" || (echo "❌ Deploy failed" && exit 1)
EOF
chmod +x /var/www/foodme/deploy.sh

# CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{"metrics":{"namespace":"FoodMe","metrics_collected":{"cpu":{"measurement":["cpu_usage_user"],"metrics_collection_interval":300},"mem":{"measurement":["mem_used_percent"],"metrics_collection_interval":300}}},"logs":{"logs_collected":{"files":{"collect_list":[{"file_path":"/var/log/foodme/*.log","log_group_name":"foodme-logs","log_stream_name":"{instance_id}"}]}}}}
EOF

# Install and start
sudo -u ec2-user bash -c 'cd /var/www/foodme && npm install'
systemctl enable nginx foodme postgresql-16 && systemctl start postgresql-16 nginx foodme

# Start CloudWatch
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Test
sleep 5 && curl -f http://localhost:3000/health && echo "✅ Setup complete"
