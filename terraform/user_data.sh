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
dnf install -y git wget nginx htop unzip amazon-cloudwatch-agent --allowerasing

# Install Node.js 22
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs
npm install -g pm2

# Install New Relic Infrastructure Agent
echo "Installing New Relic Infrastructure Agent..."
curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2/x86_64/newrelic-infra.repo
dnf -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
dnf install -y newrelic-infra

# Configure New Relic Infrastructure Agent
cat > /etc/newrelic-infra.yml << EOF
license_key: ${NEW_RELIC_LICENSE_KEY}
display_name: FoodMe-${ENVIRONMENT}-EC2
log_file: /var/log/newrelic-infra/newrelic-infra.log
verbose: 0
EOF

# Set proper permissions for New Relic config
chmod 640 /etc/newrelic-infra.yml
chown root:newrelic-infra /etc/newrelic-infra.yml

# Start and enable New Relic Infrastructure Agent
systemctl enable newrelic-infra
systemctl start newrelic-infra

# Verify New Relic Infrastructure Agent status
systemctl status newrelic-infra --no-pager || echo "Warning: New Relic Infrastructure agent status check failed"

echo "New Relic Infrastructure Agent installation completed"

# Install New Relic integrations
echo "Installing New Relic integrations..."
dnf install -y nri-nginx nri-postgresql

# Configure Nginx integration
mkdir -p /etc/newrelic-infra/integrations.d
cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << 'EOF'
integrations:
  - name: nri-nginx
    env:
      # Nginx status endpoint (need to configure nginx status module)
      STATUS_URL: http://localhost/nginx_status
      STATUS_MODULE: discover
      # Remote monitoring configuration
      REMOTE_MONITORING: true
      # Nginx metrics configuration
      METRICS: true
      # Nginx inventory configuration
      INVENTORY: true
      # Connection timeout
      CONNECTION_TIMEOUT: 5
      # HTTP timeout
      HTTP_TIMEOUT: 30
      # Validate SSL certificates
      VALIDATE_CERTS: false
      # Custom attributes for easier filtering
      CUSTOM_ATTRIBUTES: '{"service":"nginx","environment":"'"${ENVIRONMENT}"'","application":"foodme","instance_type":"ec2"}'
    interval: 30s
    labels:
      env: ${ENVIRONMENT}
      role: reverse-proxy
      service: nginx
      deployment: ec2
    inventory_source: config/nginx
EOF

# Configure PostgreSQL integration (if using RDS or local PostgreSQL)
cat > /etc/newrelic-infra/integrations.d/postgres-config.yml << 'EOF'
integrations:
  - name: nri-postgresql
    env:
      # PostgreSQL connection details
      HOSTNAME: localhost
      PORT: ${DB_PORT}
      USERNAME: ${DB_USER}
      DATABASE: ${DB_NAME}
      PASSWORD: ${DB_PASSWORD}
      # SSL configuration
      SSL_MODE: disable
      # Connection timeout
      CONNECTION_TIMEOUT: 5
      # Enable metrics collection
      METRICS: true
      # Enable inventory collection
      INVENTORY: true
      # Collect extended metrics
      COLLECT_DB_LOCK_METRICS: true
      COLLECT_BLOAT_METRICS: true
      # Custom attributes for easier filtering
      CUSTOM_ATTRIBUTES: '{"service":"postgresql","environment":"'"${ENVIRONMENT}"'","application":"foodme","deployment":"ec2"}'
      # Enable custom queries for FoodMe-specific metrics
      CUSTOM_METRICS_QUERY: |
        SELECT 
          'restaurants' as table_name,
          COUNT(*) as row_count
        FROM restaurants
        UNION ALL
        SELECT 
          'menu_items' as table_name,
          COUNT(*) as row_count
        FROM menu_items
        UNION ALL
        SELECT
          'orders' as table_name,
          COUNT(*) as row_count
        FROM orders
        UNION ALL
        SELECT
          'customers' as table_name,
          COUNT(*) as row_count
        FROM customers;
    interval: 30s
    labels:
      env: ${ENVIRONMENT}
      role: database
      service: postgresql
      application: foodme
      deployment: ec2
EOF

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

# Configure PostgreSQL
echo "Configuring PostgreSQL..."

# Update postgresql.conf for better performance and security
cat >> /var/lib/pgsql/16/data/postgresql.conf << EOF

# Custom FoodMe configuration
listen_addresses = 'localhost'
port = ${DB_PORT}
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Logging configuration
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

# Security settings
ssl = off
password_encryption = scram-sha-256
EOF

# Configure pg_hba.conf for authentication
cat > /var/lib/pgsql/16/data/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer

# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             10.0.0.0/8              scram-sha-256

# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256

# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

# Set proper ownership and permissions
chown -R postgres:postgres /var/lib/pgsql/16/data/
chmod 700 /var/lib/pgsql/16/data/
chmod 600 /var/lib/pgsql/16/data/postgresql.conf
chmod 600 /var/lib/pgsql/16/data/pg_hba.conf

# Create log directory
mkdir -p /var/log/postgresql
chown postgres:postgres /var/log/postgresql
chmod 750 /var/log/postgresql

# Start and enable PostgreSQL
systemctl enable postgresql-16
systemctl start postgresql-16

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
sleep 10

# Verify PostgreSQL is running
if systemctl is-active postgresql-16 > /dev/null; then
    echo "✅ PostgreSQL 16 is running"
else
    echo "❌ PostgreSQL 16 failed to start"
    systemctl status postgresql-16 --no-pager
    exit 1
fi

# Create database and user
echo "Setting up FoodMe database and user..."
sudo -u postgres psql << EOF
-- Create database user
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';

-- Create database
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};

-- Connect to the foodme database and set up schema
\c ${DB_NAME}

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};

-- Alter default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};

-- Create tables for the FoodMe application
CREATE TABLE IF NOT EXISTS restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    cuisine_type VARCHAR(100),
    rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
    delivery_time VARCHAR(50),
    delivery_fee DECIMAL(10,2),
    min_order DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image_url VARCHAR(500),
    category VARCHAR(100),
    is_available BOOLEAN DEFAULT true,
    ingredients TEXT[],
    allergens TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(10,2) NOT NULL,
    delivery_address TEXT,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    special_instructions TEXT,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_restaurants_original_id ON restaurants(original_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine_type ON restaurants(cuisine_type);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_active ON restaurants(is_active);
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id ON menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON menu_items(is_available);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON order_items(menu_item_id);

EOF

# Test database connection
echo "Testing database connection..."
if sudo -u postgres psql -d ${DB_NAME} -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Database connection successful"
    echo "Database: ${DB_NAME}"
    echo "User: ${DB_USER}"
    echo "Port: ${DB_PORT}"
else
    echo "❌ Database connection failed"
    exit 1
fi

echo "PostgreSQL 16 setup completed successfully"

# Create directories
mkdir -p /var/www/foodme /var/log/foodme /var/www/foodme/server
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme

# Create nginx configuration - Proxy ALL requests to Node.js for Angular routing
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
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
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;

    # Health check endpoint with exact match to avoid conflicts
    location = /health {
        proxy_pass http://localhost:3000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }

    # Nginx status endpoint for New Relic monitoring
    location = /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        deny all;
    }

    # API endpoints
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
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
    
    # Static assets - proxy to Node.js with caching headers
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # All other requests - proxy to Node.js (including / and Angular routes)
    # This allows the catch-all handler in server/index.js to serve index.html
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
Environment=NEW_RELIC_LICENSE_KEY=$NEW_RELIC_LICENSE_KEY
Environment=NEW_RELIC_APP_NAME=FoodMe-$ENVIRONMENT
Environment=DB_HOST=localhost
Environment=DB_PORT=$DB_PORT
Environment=DB_NAME=$DB_NAME
Environment=DB_USER=$DB_USER
Environment=DB_PASSWORD=$DB_PASSWORD
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foodme
[Install]
WantedBy=multi-user.target
EOF



# Create deployment script for GitHub Actions
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e
echo "Starting FoodMe deployment..."
cd /var/www/foodme/dist/server
if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    echo "Deploying FoodMe application..."

    npm install --production
    if [ -d "server" ]; then
        echo "✅ Server directory found"
    else
        echo "❌ Server directory missing!"
        exit 1
    fi
    sudo systemctl restart foodme
else
    echo "No real application detected, placeholder continues..."
fi
sleep 15
curl -f http://localhost:3000/health && echo "✅ Deployment successful!" || echo "❌ Health check failed"
EOF

chmod +x /var/www/foodme/deploy.sh
chown ec2-user:ec2-user /var/www/foodme/deploy.sh

# Start services
sudo -u ec2-user bash -c 'cd /var/www/foodme/server && npm install'
systemctl daemon-reload
systemctl enable nginx foodme
systemctl start nginx foodme

# Restart New Relic Infrastructure agent to pick up integrations
echo "Restarting New Relic Infrastructure agent to load integrations..."
systemctl restart newrelic-infra

# Wait a moment and verify all services are running
sleep 5
echo "Final service status check:"
systemctl is-active postgresql-16 && echo "✅ PostgreSQL 16 is running" || echo "❌ PostgreSQL 16 failed"
systemctl is-active nginx && echo "✅ Nginx is running" || echo "❌ Nginx failed"
systemctl is-active foodme && echo "✅ FoodMe app is running" || echo "❌ FoodMe app failed"
systemctl is-active newrelic-infra && echo "✅ New Relic Infrastructure agent is running" || echo "❌ New Relic Infrastructure agent failed"

# Final database connectivity test
echo "Final database connectivity test:"
if sudo -u postgres psql -d ${DB_NAME} -c "SELECT COUNT(*) FROM restaurants;" > /dev/null 2>&1; then
    echo "✅ Database connectivity confirmed"
    RESTAURANT_COUNT=$(sudo -u postgres psql -d ${DB_NAME} -t -c "SELECT COUNT(*) FROM restaurants;" | xargs)
    echo "📊 Database contains $RESTAURANT_COUNT restaurants"
else
    echo "❌ Database connectivity test failed"
fi

echo "EC2 setup completed at $(date)"
