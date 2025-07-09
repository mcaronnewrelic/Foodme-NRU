#!/bin/bash

# force-redeploy-with-express-fix.sh - Complete re-deployment with Express 4.x
# Run this on the EC2 instance for a complete fresh deployment

set -e

echo "🚀 Force re-deployment with Express 4.x fix..."

# Stop all related services
echo "🛑 Stopping services..."
sudo systemctl stop foodme || true
sudo systemctl stop nginx || true

# Backup current deployment
echo "💾 Creating backup..."
sudo cp -r /var/www/foodme /var/www/foodme.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Clean the deployment directory
echo "🧹 Cleaning deployment directory..."
sudo rm -rf /var/www/foodme/node_modules
sudo rm -rf /var/www/foodme/server/node_modules
sudo rm -rf /var/www/foodme/package-lock.json
sudo rm -rf /var/www/foodme/server/package-lock.json

# Create a corrected package.json for the server
echo "📝 Creating corrected server package.json..."
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
    "express": "^4.18.3",
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

# Update root package.json if it exists
if [ -f "/var/www/foodme/package.json" ]; then
    echo "📝 Updating root package.json..."
    sudo sed -i 's/"express": "[^"]*"/"express": "^4.18.3"/' /var/www/foodme/package.json
fi

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R ec2-user:ec2-user /var/www/foodme
sudo chmod -R 755 /var/www/foodme

# Install dependencies
echo "📦 Installing dependencies..."
cd /var/www/foodme/server
npm cache clean --force
npm install --production

# Verify installation
echo "✅ Verifying installation..."
echo "Express version installed:"
npm list express

echo "Checking for path-to-regexp version:"
npm list path-to-regexp || echo "path-to-regexp not directly installed"

# Update systemd service to ensure correct working directory
echo "🔧 Updating systemd service..."
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

# Reload systemd and start services
echo "🔄 Reloading systemd and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl start nginx
sudo systemctl start foodme

# Wait and verify
sleep 10

echo "📊 Service status:"
sudo systemctl status foodme --no-pager -l

echo "🧪 Testing endpoints..."
echo "Direct health check:"
curl -s -w "HTTP %{http_code}\n" http://localhost:3000/health || echo "Failed"

echo "Via nginx:"
curl -s -w "HTTP %{http_code}\n" http://localhost/health || echo "Failed"

echo "📋 Recent logs (last 20 lines):"
sudo journalctl -u foodme -n 20 --no-pager

echo "🎯 Force re-deployment complete!"

# Final verification
echo "🔍 Final verification:"
echo "Working directory: $(pwd)"
echo "Node.js version: $(node --version)"
echo "Express version in package.json:"
grep '"express"' package.json
echo "Actual Express version installed:"
npm list express | head -3
echo "Process running on port 3000:"
sudo netstat -tlnp | grep :3000 || echo "Nothing on port 3000"
