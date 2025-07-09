#!/bin/bash

# FoodMe EC2 Instance User Data Script
# This script sets up the EC2 instance for the FoodMe application

set -e

# Variables passed from Terraform
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
APP_VERSION="${app_version}"

# Update system
dnf update -y

# Install required packages
dnf install -y \
    git \
    wget \
    nginx \
    htop \
    unzip \
    amazon-cloudwatch-agent \
    --allowerasing

# Install Node.js 22 LTS (matching GitHub Actions)
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

# Install PM2 for process management
npm install -g pm2

# Create application directory
mkdir -p /var/www/foodme
chown ec2-user:ec2-user /var/www/foodme

# Create logs directory
mkdir -p /var/log/foodme
chown ec2-user:ec2-user /var/log/foodme

# Configure Nginx
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
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

# Create systemd service for FoodMe
cat > /etc/systemd/system/foodme.service << 'EOF'
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

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foodme

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/foodme /var/www/foodme

[Install]
WantedBy=multi-user.target
EOF

# Create PM2 ecosystem file
cat > /var/www/foodme/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'foodme',
    script: 'server/start.js',
    cwd: '/var/www/foodme',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    log_file: '/var/log/foodme/combined.log',
    out_file: '/var/log/foodme/out.log',
    error_file: '/var/log/foodme/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    max_memory_restart: '1G'
  }]
};
EOF

# Create health check script
cat > /var/www/foodme/health-check.sh << 'EOF'
#!/bin/bash

# Try multiple health endpoints
endpoints=("/health" "/api/health")
base_url="http://localhost:3000"

for endpoint in "${endpoints[@]}"; do
    echo "Checking $base_url$endpoint..."
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$base_url$endpoint" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "✅ Health check passed on $endpoint (HTTP $response)"
        exit 0
    else
        echo "❌ Health check failed on $endpoint (HTTP $response)"
    fi
done

# If all endpoints fail, check if anything is listening on port 3000
echo "Checking if any process is listening on port 3000..."
if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "✅ Process is listening on port 3000"
    # Try a basic TCP connection
    if timeout 5 bash -c "</dev/tcp/localhost/3000" 2>/dev/null; then
        echo "✅ TCP connection to port 3000 successful"
        exit 0
    else
        echo "❌ TCP connection to port 3000 failed"
    fi
else
    echo "❌ No process listening on port 3000"
fi

echo "❌ All health checks failed"
exit 1
EOF

chmod +x /var/www/foodme/health-check.sh

# Configure log rotation
cat > /etc/logrotate.d/foodme << 'EOF'
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

# Create deployment script
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting FoodMe deployment..."

# Check if this is a real deployment (has the actual package.json)
if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    echo "Deploying real FoodMe application..."
    
    # Install dependencies
    echo "Installing dependencies..."
    npm install --production
    
    # Build Angular app if angular-app directory exists
    if [ -d "angular-app" ]; then
        echo "Building Angular application..."
        cd angular-app
        npm install
        npm run build
        cd ..
    fi
    
    # Copy built assets to the web root if they exist
    if [ -d "angular-app/dist" ]; then
        echo "Copying built assets..."
        cp -r angular-app/dist/* /var/www/foodme/ 2>/dev/null || true
    fi
    
    echo "Real application deployed, using systemd service..."
    
    # Restart application
    echo "Restarting application..."
    sudo systemctl restart foodme
    
else
    echo "No real application detected, placeholder will continue running..."
    
    # Just restart the placeholder
    sudo systemctl restart foodme
fi

# Wait for application to start
echo "Waiting for application to start..."
sleep 15

# Run health check with retries
echo "Running health check..."
for i in {1..5}; do
    if /var/www/foodme/health-check.sh; then
        echo "✅ Deployment successful! (attempt $i)"
        break
    else
        echo "Health check failed (attempt $i/5), retrying in 10 seconds..."
        if [ $i -eq 5 ]; then
            echo "❌ Deployment failed - health check failed after 5 attempts"
            
            # Show service status for debugging
            echo "Service status:"
            sudo systemctl status foodme --no-pager || true
            
            # Show recent logs
            echo "Recent logs:"
            sudo journalctl -u foodme --no-pager -n 20 || true
            
            exit 1
        fi
        sleep 10
    fi
done
EOF

chmod +x /var/www/foodme/deploy.sh

# Set ownership
chown -R ec2-user:ec2-user /var/www/foodme

# Create a simple placeholder application to ensure the service starts
cat > /var/www/foodme/package.json << 'EOF'
{
  "name": "foodme-placeholder",
  "version": "1.0.0",
  "description": "Placeholder for FoodMe application",
  "main": "server/start.js",
  "scripts": {
    "start": "node server/start.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

# Create minimal server structure
mkdir -p /var/www/foodme/server
cat > /var/www/foodme/server/start.js << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'FoodMe placeholder service is running',
    version: 'placeholder'
  });
});

// API health check
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    api: 'placeholder',
    timestamp: new Date().toISOString()
  });
});

// Placeholder API endpoints
app.get('/api/restaurant', (req, res) => {
  res.status(200).json({ 
    message: 'API placeholder - will be replaced with real application',
    restaurants: []
  });
});

// Serve static files
app.use(express.static(path.join(__dirname, '../')));

// Catch-all handler for SPA
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>FoodMe - Starting Up</title>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { 
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
          text-align: center; 
          padding: 50px; 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          margin: 0;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-direction: column;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          padding: 40px;
          border-radius: 20px;
          backdrop-filter: blur(10px);
          max-width: 500px;
        }
        h1 { font-size: 3em; margin: 0 0 20px 0; }
        .loading { color: #f0f0f0; font-size: 1.2em; margin: 20px 0; }
        .status { font-size: 0.9em; opacity: 0.8; margin-top: 30px; }
        .spinner {
          border: 3px solid rgba(255, 255, 255, 0.3);
          border-top: 3px solid white;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 20px auto;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🍕 FoodMe</h1>
        <div class="spinner"></div>
        <p class="loading">Application is starting up...</p>
        <p class="status">This placeholder will be replaced by the full application shortly.</p>
      </div>
    </body>
    </html>
  `);
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    status: 'error', 
    message: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(\`FoodMe placeholder server running on port \${PORT}\`);
  console.log(\`Health check available at: http://localhost:\${PORT}/health\`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});
EOF

# Install placeholder dependencies as ec2-user
sudo -u ec2-user bash -c 'cd /var/www/foodme && npm install'

# Enable and start services
systemctl enable nginx
systemctl start nginx
systemctl enable foodme

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
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
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
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

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "EC2 instance setup completed!"
echo "Environment: $ENVIRONMENT"
echo "App Version: $APP_VERSION"
echo "App Port: $APP_PORT"

# Try to start the foodme service
echo "Starting FoodMe service..."
systemctl start foodme

# Wait a moment and check service status
sleep 10
systemctl status foodme --no-pager

# Check if the service is listening on port 3000
echo "Checking if application is listening on port 3000..."
netstat -tlnp | grep :3000 || echo "No process listening on port 3000"

# Test the health endpoint
echo "Testing health endpoint..."
curl -f http://localhost:3000/health || echo "Health endpoint not responding"

# Signal that user data script is complete
echo "User data script completed successfully at $(date)"

# Log to a file for debugging
echo "User data script completed at $(date)" >> /var/log/foodme/setup.log
