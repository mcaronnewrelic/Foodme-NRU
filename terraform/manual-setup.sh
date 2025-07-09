#!/bin/bash

# FoodMe EC2 Instance Setup Script - Manual Run
# This script completes the setup that failed in the original user_data

set -e

echo "🚀 Starting FoodMe manual setup..."

# Variables
APP_PORT="3000"
ENVIRONMENT="staging"
APP_VERSION="latest"

echo "📦 Installing required packages with conflict resolution..."
sudo dnf update -y
sudo dnf install -y git wget nginx htop unzip amazon-cloudwatch-agent --allowerasing

echo "📦 Installing Node.js 22 LTS..."
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
sudo dnf install -y nodejs

echo "📦 Installing PM2 for process management..."
sudo npm install -g pm2

echo "📁 Setting up application directories..."
sudo mkdir -p /var/www/foodme
sudo chown ec2-user:ec2-user /var/www/foodme

sudo mkdir -p /var/log/foodme
sudo chown ec2-user:ec2-user /var/log/foodme

echo "⚙️ Configuring Nginx..."
sudo tee /etc/nginx/conf.d/foodme.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Serve static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /var/www/foodme;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }
    
    # API routes
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
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
    
    # All other routes (SPA)
    location / {
        root /var/www/foodme;
        try_files $uri $uri/ /index.html;
        
        # Cache HTML files for short time
        location ~* \.html$ {
            add_header Cache-Control "public, max-age=300";
        }
    }
}
EOF

echo "🔧 Creating systemd service for FoodMe..."
sudo tee /etc/systemd/system/foodme.service > /dev/null << 'EOF'
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

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foodme

[Install]
WantedBy=multi-user.target
EOF

echo "🔧 Creating PM2 ecosystem file..."
cat > /var/www/foodme/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'foodme',
    script: 'server/start.js',
    cwd: '/var/www/foodme',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    log_file: '/var/log/foodme/combined.log',
    out_file: '/var/log/foodme/out.log',
    error_file: '/var/log/foodme/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    max_memory_restart: '1G',
    node_args: '-r newrelic'
  }]
};
EOF

echo "🔧 Creating health check script..."
cat > /var/www/foodme/health-check.sh << 'EOF'
#!/bin/bash
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
if [ "$response" = "200" ]; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed with status: $response"
    exit 1
fi
EOF

chmod +x /var/www/foodme/health-check.sh

echo "🔧 Creating deployment script..."
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting FoodMe deployment..."

# Install dependencies if package.json exists
if [ -f "package.json" ]; then
    echo "Installing dependencies..."
    npm install --production
fi

# Restart application
echo "Restarting application..."
sudo systemctl restart foodme

# Wait for application to start
echo "Waiting for application to start..."
sleep 10

# Run health check
echo "Running health check..."
if /var/www/foodme/health-check.sh; then
    echo "✅ Deployment successful!"
else
    echo "❌ Deployment failed - health check failed"
    exit 1
fi
EOF

chmod +x /var/www/foodme/deploy.sh

echo "🔧 Setting up log rotation..."
sudo tee /etc/logrotate.d/foodme > /dev/null << 'EOF'
/var/log/foodme/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0644 ec2-user ec2-user
    postrotate
        /bin/systemctl reload foodme > /dev/null 2>&1 || true
    endscript
}
EOF

echo "👤 Setting ownership..."
sudo chown -R ec2-user:ec2-user /var/www/foodme

echo "🚀 Enabling and starting services..."
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl enable foodme

echo "☁️ Creating CloudWatch agent configuration..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOF'
{
    "metrics": {
        "namespace": "FoodMe",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/foodme/combined.log",
                        "log_group_name": "foodme-application",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "foodme-nginx-access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "foodme-nginx-error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

echo "☁️ Starting CloudWatch agent..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "✅ Manual setup completed!"
echo "Environment: $ENVIRONMENT"
echo "App Version: $APP_VERSION"
echo "App Port: $APP_PORT"

echo ""
echo "🔍 Service Status:"
sudo systemctl status nginx --no-pager -l
echo ""
sudo systemctl status foodme --no-pager -l

echo ""
echo "📋 Next Steps:"
echo "1. Deploy your application files to /var/www/foodme/"
echo "2. Test with: curl http://localhost/health"
echo "3. View logs with: sudo journalctl -u foodme -f"
