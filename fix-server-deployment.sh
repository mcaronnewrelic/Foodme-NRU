#!/bin/bash

# fix-server-deployment.sh - Fix server directory and package.json deployment issues
# Run this on the EC2 instance to fix server-specific deployment problems

set -e

echo "🚀 Fixing server directory deployment issues..."

# 1. Check current deployment structure
echo "📂 Checking current deployment structure..."
echo "Contents of /var/www/foodme:"
ls -la /var/www/foodme/ || echo "Directory not found"

if [ -d "/var/www/foodme/dist" ]; then
    echo "Contents of /var/www/foodme/dist:"
    ls -la /var/www/foodme/dist/
fi

if [ -d "/var/www/foodme/server" ]; then
    echo "Contents of /var/www/foodme/server:"
    ls -la /var/www/foodme/server/
fi

# 2. Stop the service
echo "🛑 Stopping foodme service..."
sudo systemctl stop foodme || true

# 3. Fix the server directory structure
echo "🔧 Fixing server directory structure..."

# Check if we have dist/server but no root server
if [ -d "/var/www/foodme/dist/server" ] && [ ! -d "/var/www/foodme/server" ]; then
    echo "Moving server files from dist/server to root level..."
    sudo cp -r /var/www/foodme/dist/server /var/www/foodme/
fi

# Ensure server directory exists and has the right structure
if [ ! -d "/var/www/foodme/server" ]; then
    echo "❌ Server directory not found after copying. Available directories:"
    find /var/www/foodme -type d -name "*server*" || echo "No server directories found"
    exit 1
fi

# 4. Create server package.json if it doesn't exist
echo "📦 Ensuring server package.json exists..."
if [ ! -f "/var/www/foodme/server/package.json" ]; then
    echo "Creating server/package.json..."
    sudo tee /var/www/foodme/server/package.json > /dev/null << 'EOF'
{
  "name": "foodme-server",
  "version": "1.0.0",
  "description": "FoodMe Node.js Server",
  "main": "start.js",
  "scripts": {
    "start": "node start.js",
    "start:prod": "NODE_ENV=production node start.js"
  },
  "dependencies": {
    "body-parser": "^1.20.0",
    "csv": ">=0.2.1",
    "express": "^5.1.0",
    "express-handlebars": "^8.0.2",
    "morgan": "^1.10.0",
    "newrelic": "^12.21.0",
    "open": "^8.4.2",
    "pg": "^8.12.0",
    "pino": "^8.7.0",
    "uuid": "^9.0.1"
  },
  "engines": {
    "node": ">=20.14.0"
  },
  "license": "MIT"
}
EOF
fi

# 5. Set proper permissions
echo "🔐 Setting proper permissions..."
sudo chown -R ec2-user:ec2-user /var/www/foodme
sudo chmod -R 755 /var/www/foodme

# 6. Install dependencies in server directory
echo "📦 Installing Node.js dependencies in server directory..."
cd /var/www/foodme/server && npm install --production

# 7. Update systemd service to use server directory
echo "🔧 Updating systemd service configuration..."
sudo tee /etc/systemd/system/foodme.service > /dev/null << 'EOF'
[Unit]
Description=FoodMe Node.js Application
After=network.target postgresql.service

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme/server
ExecStart=/usr/bin/node start.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foodme

[Install]
WantedBy=multi-user.target
EOF

# 8. Reload systemd and start service
echo "🔄 Reloading systemd and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl start foodme

# 9. Wait and check status
sleep 5

echo "📊 Service status:"
sudo systemctl status foodme --no-pager -l

echo "🧪 Testing endpoints..."
echo "Testing health check:"
curl -s http://localhost:3000/health || echo "Direct health check failed"

echo "Testing via nginx:"
curl -s http://localhost/health || echo "Nginx health check failed"

echo "🎯 Server deployment fix complete!"

# 10. Show final directory structure
echo "📂 Final directory structure:"
echo "Server directory:"
ls -la /var/www/foodme/server/
echo "Server package.json:"
cat /var/www/foodme/server/package.json | jq '.name, .main' 2>/dev/null || head -5 /var/www/foodme/server/package.json
