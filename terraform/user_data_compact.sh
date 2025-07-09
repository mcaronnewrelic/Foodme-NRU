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

# Create nginx configuration
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    location /api/ { proxy_pass http://localhost:3000; }
    location /health { proxy_pass http://localhost:3000/health; access_log off; }
    location / { root /var/www/foodme; try_files $uri $uri/ /index.html; }
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
ExecStartPre=/bin/bash -c 'if [ -f package.json ]; then npm install --production; fi'
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

# Create minimal placeholder app
cat > /var/www/foodme/package.json << 'EOF'
{"name":"foodme","version":"1.0.0","main":"server/start.js","dependencies":{"express":"^4.18.2"}}
EOF

cat > /var/www/foodme/server/start.js << 'EOF'
const express = require('express');
const app = express();
app.use(express.json());
app.get('/health', (req, res) => res.json({status: 'ok', timestamp: new Date().toISOString()}));
app.get('/api/health', (req, res) => res.json({status: 'ok', api: 'placeholder'}));
app.get('/api/restaurant', (req, res) => res.json({restaurants: []}));
app.get('*', (req, res) => res.send('<!DOCTYPE html><html><head><title>FoodMe - Starting</title></head><body><h1>🍕 FoodMe Starting...</h1><p>Application will be deployed shortly...</p></body></html>'));
app.listen(3000, '0.0.0.0', () => console.log('FoodMe placeholder running on port 3000'));
EOF

# Install placeholder and start services
sudo -u ec2-user bash -c 'cd /var/www/foodme && npm install'
systemctl daemon-reload
systemctl enable nginx foodme
systemctl start nginx foodme

# Create deployment script for GitHub Actions
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e
echo "Starting FoodMe deployment..."
if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    echo "Deploying real FoodMe application..."
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

echo "EC2 setup completed at $(date)"
