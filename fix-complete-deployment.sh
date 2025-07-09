#!/bin/bash

# fix-complete-deployment.sh - Complete fix for nginx and systemd issues
# Run this on the EC2 instance to fix all deployment issues

set -e

echo "🚀 Starting complete deployment fix..."

# 1. Fix nginx configuration
echo "📝 Fixing nginx configuration..."
sudo tee /etc/nginx/conf.d/foodme.conf > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/foodme/angular-app/dist/foodme-frontend/browser;
    index index.html;

    # Health check endpoint - exact match first
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

    # API routes
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
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Optional: Add security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

# Test nginx configuration
sudo nginx -t

# 2. Fix systemd service
echo "🔧 Fixing systemd service configuration..."
sudo systemctl stop foodme || true

sudo tee /etc/systemd/system/foodme.service > /dev/null << 'EOF'
[Unit]
Description=FoodMe Node.js Application
After=network.target postgresql.service

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme
ExecStart=/usr/bin/node server/start.js
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

# 3. Ensure proper permissions
echo "🔐 Setting proper permissions..."
sudo chown -R ec2-user:ec2-user /var/www/foodme
sudo chmod -R 755 /var/www/foodme

# 4. Create a simple index.html for the root
echo "📄 Creating index.html..."
sudo mkdir -p /var/www/foodme/angular-app/dist/foodme-frontend/browser
cat > /tmp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>FoodMe Application</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { padding: 15px; margin: 20px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .links { text-align: center; margin-top: 30px; }
        .links a { display: inline-block; margin: 10px; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; }
        .links a:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍕 FoodMe Application</h1>
        <div class="status success">
            ✅ Application is running successfully!
        </div>
        <div class="links">
            <a href="/health">Health Check</a>
            <a href="/api/health">API Health</a>
            <a href="/api/restaurants">View Restaurants</a>
        </div>
        <p><strong>API Endpoints:</strong></p>
        <ul>
            <li><code>GET /health</code> - Health check</li>
            <li><code>GET /api/restaurants</code> - List restaurants</li>
            <li><code>POST /api/restaurants</code> - Add restaurant</li>
        </ul>
    </div>
</body>
</html>
EOF
sudo mv /tmp/index.html /var/www/foodme/angular-app/dist/foodme-frontend/browser/index.html
sudo chown ec2-user:ec2-user /var/www/foodme/angular-app/dist/foodme-frontend/browser/index.html

# 5. Restart services
echo "🔄 Restarting services..."
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl restart nginx
sudo systemctl start foodme

# 6. Wait a moment for services to start
sleep 5

# 7. Check status
echo "📊 Service status:"
echo "--- Nginx ---"
sudo systemctl status nginx --no-pager -l

echo "--- FoodMe Service ---"
sudo systemctl status foodme --no-pager -l

echo "--- Recent logs ---"
sudo journalctl -u foodme --no-pager -n 10

# 8. Test endpoints
echo "🧪 Testing endpoints..."
echo "Testing health check:"
curl -s http://localhost/health || echo "Health check failed"

echo "Testing API health:"
curl -s http://localhost/api/health || echo "API health check failed"

echo "🎯 Deployment fix complete!"
echo "🌐 Application should be accessible at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/"
