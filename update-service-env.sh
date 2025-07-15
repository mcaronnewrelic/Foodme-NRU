#!/bin/bash
# Script to update environment variables for the FoodMe systemd service
# Usage: ./update-service-env.sh NEW_RELIC_LICENSE_KEY DB_PASSWORD [other_vars...]

set -e

# Create environment file
ENV_FILE="/etc/systemd/system/foodme.env"

echo "Creating environment file: $ENV_FILE"

# Create the environment file with passed parameters
sudo tee "$ENV_FILE" > /dev/null << EOF
NODE_ENV=production
PORT=3000
NEW_RELIC_LICENSE_KEY=${1:-}
NEW_RELIC_APP_NAME=FoodMe-${2:-staging}
DB_HOST=localhost
DB_PORT=${3:-5432}
DB_NAME=${4:-foodme}
DB_USER=${5:-foodme_user}
DB_PASSWORD=${6:-foodme_secure_password_2025!}
EOF

# Update systemd service to use environment file
sudo tee /etc/systemd/system/foodme.service > /dev/null << EOF
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
EnvironmentFile=$ENV_FILE
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foodme

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
sudo chmod 640 "$ENV_FILE"
sudo chown root:ec2-user "$ENV_FILE"

# Reload systemd
sudo systemctl daemon-reload

echo "✅ Environment file created and systemd service updated"
echo "Environment file location: $ENV_FILE"
echo "To view current environment: sudo cat $ENV_FILE"
