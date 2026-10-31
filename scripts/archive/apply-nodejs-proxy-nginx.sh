#!/bin/bash

echo "=========================================="
echo "Applying Node.js Proxy Nginx Configuration"
echo "=========================================="

# This script ensures nginx proxies ALL requests to Node.js
# allowing the catch-all handler in server/index.js to serve index.html

echo "Creating nginx configuration that proxies ALL requests to Node.js..."

# Update the Terraform nginx config file
sudo tee /etc/nginx/conf.d/foodme.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;

    # Health check endpoint with exact match to avoid conflicts
    location = /health {
        proxy_pass http://localhost:3000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }

    # API endpoints
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
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
    
    # Static assets - proxy to Node.js with caching headers
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # All other requests - proxy to Node.js (including / and Angular routes)
    # This allows the catch-all handler in server/index.js to serve index.html
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
EOF

echo "✓ Created nginx configuration that proxies ALL requests to Node.js"

# Remove any conflicting default configs
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/conf.d/default.conf

echo "✓ Removed conflicting nginx configurations"

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Nginx configuration is valid"
    
    # Reload nginx
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✓ Nginx reloaded successfully"
    else
        echo "❌ Failed to reload nginx, trying restart..."
        sudo systemctl restart nginx
        if [ $? -eq 0 ]; then
            echo "✓ Nginx restarted successfully"
        else
            echo "❌ Failed to restart nginx"
            exit 1
        fi
    fi
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Check services status
echo ""
echo "Current service status:"
echo "Nginx: $(sudo systemctl is-active nginx)"
echo "FoodMe: $(sudo systemctl is-active foodme)"

echo ""
echo "=========================================="
echo "Nginx Node.js Proxy Configuration Applied!"
echo "=========================================="
echo ""
echo "IMPORTANT: All requests now proxy to Node.js"
echo "• No static file serving from nginx"
echo "• Node.js catch-all handler serves index.html"
echo "• Angular routing handled by Node.js"
echo ""
echo "Test the changes:"
echo "curl -i http://localhost/"
echo "curl -i http://localhost/health"
echo "curl -i http://localhost/some-angular-route"
echo ""
