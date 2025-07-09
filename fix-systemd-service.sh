#!/bin/bash

# fix-systemd-service.sh - Fix systemd service configuration on EC2
# Run this on the EC2 instance to fix the foodme service

set -e

echo "🔧 Fixing systemd service configuration..."

# Stop the service if running
sudo systemctl stop foodme || true

# Create the corrected service file
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

# Reload systemd and start the service
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl start foodme

# Check status
echo "📊 Service status:"
sudo systemctl status foodme --no-pager -l

echo "🎯 Service should now be running without npm install issues!"
