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
After=network.target
[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme
ExecStart=/usr/bin/node server/start.js
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

echo "EC2 setup completed at $(date)"
