#!/bin/bash
set -e

# Variables from Terraform
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
APP_VERSION="${app_version}"

# Update and install packages
dnf update -y
dnf install -y git wget nginx htop unzip amazon-cloudwatch-agent --allowerasing

# Install Node.js 22
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs
npm install -g pm2

# Create directories
mkdir -p /var/www/foodme /var/log/foodme
chown -R ec2-user:ec2-user /var/www/foodme /var/log/foodme

# Download configuration files from GitHub
GITHUB_RAW="https://raw.githubusercontent.com/your-username/foodme/main/terraform/configs"
curl -s "$GITHUB_RAW/nginx.conf" > /etc/nginx/conf.d/foodme.conf
curl -s "$GITHUB_RAW/foodme.service" > /etc/systemd/system/foodme.service
curl -s "$GITHUB_RAW/ecosystem.config.js" > /var/www/foodme/ecosystem.config.js
curl -s "$GITHUB_RAW/health-check.sh" > /var/www/foodme/health-check.sh
curl -s "$GITHUB_RAW/deploy.sh" > /var/www/foodme/deploy.sh
curl -s "$GITHUB_RAW/cloudwatch-config.json" > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

chmod +x /var/www/foodme/health-check.sh /var/www/foodme/deploy.sh

# Create minimal placeholder
cat > /var/www/foodme/package.json << 'EOF'
{"name":"foodme-placeholder","version":"1.0.0","main":"server/start.js","dependencies":{"express":"^4.18.2"}}
EOF

mkdir -p /var/www/foodme/server
cat > /var/www/foodme/server/start.js << 'EOF'
const express = require('express');
const app = express();
app.use(express.json());
app.get('/health', (req, res) => res.json({status: 'ok', timestamp: new Date().toISOString()}));
app.get('/api/health', (req, res) => res.json({status: 'ok', api: 'placeholder'}));
app.get('/api/restaurant', (req, res) => res.json({restaurants: []}));
app.get('*', (req, res) => res.send('<!DOCTYPE html><html><head><title>FoodMe - Starting</title></head><body><h1>🍕 FoodMe Starting...</h1></body></html>'));
app.listen(3000, '0.0.0.0', () => console.log('FoodMe placeholder running on port 3000'));
EOF

# Install and start services
sudo -u ec2-user bash -c 'cd /var/www/foodme && npm install'
systemctl enable nginx foodme
systemctl start nginx

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Start FoodMe service
systemctl start foodme
sleep 5

# Test health endpoint
curl -f http://localhost:3000/health || echo "Health check failed"

echo "Setup completed at $(date)"
