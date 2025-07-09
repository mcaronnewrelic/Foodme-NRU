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

# Fix nginx configuration
echo "🌐 Fixing nginx configuration..."
sudo tee /etc/nginx/conf.d/foodme.conf > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    # Set the root directory for static files
    root /var/www/foodme/angular-app/dist/foodme-frontend/browser;
    index index.html;

    # Health check endpoint - proxy to Node.js app
    location = /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API routes - proxy to Node.js app
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files for Angular app
    location / {
        try_files $uri $uri/ @fallback;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Fallback to index.html for Angular routing or create simple index
    location @fallback {
        try_files /index.html =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

# Create Angular directory structure and simple index.html if it doesn't exist
echo "📁 Creating Angular directory structure..."
sudo mkdir -p /var/www/foodme/angular-app/dist/foodme-frontend/browser

# Create a simple index.html file
echo "📄 Creating index.html..."
sudo tee /var/www/foodme/angular-app/dist/foodme-frontend/browser/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoodMe - Restaurant Discovery App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0; padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
        }
        .container {
            text-align: center; max-width: 600px; padding: 2rem;
            background: rgba(255, 255, 255, 0.1); border-radius: 15px;
            backdrop-filter: blur(10px); box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        .status { margin: 1rem 0; padding: 1rem; background: rgba(0, 255, 0, 0.2); border-radius: 8px; }
        .links { margin-top: 2rem; }
        .links a {
            display: inline-block; margin: 0.5rem; padding: 0.75rem 1.5rem;
            background: rgba(255, 255, 255, 0.2); color: white; text-decoration: none;
            border-radius: 25px; transition: all 0.3s ease;
        }
        .links a:hover { background: rgba(255, 255, 255, 0.3); transform: translateY(-2px); }
        .api-info { margin-top: 2rem; text-align: left; background: rgba(0, 0, 0, 0.2); padding: 1rem; border-radius: 8px; }
        .api-info h3 { margin-top: 0; }
        .api-info ul { list-style-type: none; padding-left: 0; }
        .api-info li { margin: 0.5rem 0; padding: 0.25rem; }
        .api-info code { background: rgba(255, 255, 255, 0.2); padding: 0.2rem 0.5rem; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍕 FoodMe</h1>
        <p>Restaurant Discovery & Ordering Platform</p>
        
        <div class="status">
            ✅ Application is running successfully!
        </div>
        
        <div class="links">
            <a href="/health">Health Check</a>
            <a href="/api/restaurant">View Restaurants</a>
        </div>
        
        <div class="api-info">
            <h3>🔗 API Endpoints</h3>
            <ul>
                <li><code>GET /health</code> - Health check</li>
                <li><code>GET /api/restaurant</code> - List all restaurants</li>
                <li><code>GET /api/restaurant/:id</code> - Get specific restaurant</li>
                <li><code>POST /api/restaurant</code> - Add new restaurant</li>
                <li><code>POST /api/order</code> - Place an order</li>
            </ul>
        </div>
        
        <p style="margin-top: 2rem; opacity: 0.8; font-size: 0.9rem;">
            <strong>Node.js:</strong> v22.17.0 | <strong>Express:</strong> v4.18.3 | <strong>Environment:</strong> Production
        </p>
    </div>
</body>
</html>
EOF

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
sudo nginx -t

# Set proper permissions for nginx to read files
echo "🔐 Setting nginx file permissions..."
sudo chown -R ec2-user:ec2-user /var/www/foodme
sudo chmod -R 755 /var/www/foodme
sudo chmod 644 /var/www/foodme/angular-app/dist/foodme-frontend/browser/index.html

# Remove default nginx site that might conflict
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/conf.d/default.conf

# Reload systemd and start services
echo "🔄 Reloading systemd and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl restart nginx
sudo systemctl start foodme

# Wait and verify
sleep 10

echo "📊 Service status:"
echo "--- Nginx Status ---"
sudo systemctl status nginx --no-pager -l
echo ""
echo "--- FoodMe Service Status ---"
sudo systemctl status foodme --no-pager -l

echo "🧪 Testing endpoints..."
echo "Direct Node.js health check:"
curl -s -w "HTTP %{http_code}\n" http://localhost:3000/health || echo "Failed"

echo "Via nginx health check:"
curl -s -w "HTTP %{http_code}\n" http://localhost/health || echo "Failed"

echo "Root endpoint via nginx:"
curl -s -w "HTTP %{http_code}\n" http://localhost/ | head -3 || echo "Failed"

echo "📋 Recent logs (last 20 lines):"
echo "--- FoodMe Service Logs ---"
sudo journalctl -u foodme -n 20 --no-pager

echo "--- Nginx Error Logs ---"
sudo tail -20 /var/log/nginx/error.log 2>/dev/null || echo "No nginx error logs"

echo "--- Nginx Access Logs ---"
sudo tail -10 /var/log/nginx/access.log 2>/dev/null || echo "No nginx access logs"

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
