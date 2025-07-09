#!/bin/bash
# FoodMe Nginx Configuration Fix
# This script fixes the Nginx location block ordering issue

echo "🔧 FoodMe Nginx Configuration Fix"
echo "=================================="
echo ""

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root or with sudo"
   echo "Usage: sudo ./fix-nginx-config.sh"
   exit 1
fi

echo "🎯 Fixing Nginx Configuration..."
echo ""

# Backup current config
echo "1. Backing up current Nginx config..."
cp /etc/nginx/conf.d/foodme.conf /etc/nginx/conf.d/foodme.conf.backup 2>/dev/null || echo "No existing config found"

# Create corrected Nginx configuration
echo "2. Creating corrected Nginx configuration..."
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # API endpoints - proxy to Node.js app
    location /api/ { 
        proxy_pass http://localhost:3000; 
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoint - proxy to Node.js app (exact match)
    location = /health { 
        proxy_pass http://localhost:3000/health; 
        access_log off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Static files and fallback to index.html
    location / { 
        root /var/www/foodme; 
        try_files $uri $uri/ /index.html; 
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF

echo "✅ Updated Nginx configuration"

# Test Nginx configuration
echo "3. Testing Nginx configuration..."
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    echo "Restoring backup..."
    cp /etc/nginx/conf.d/foodme.conf.backup /etc/nginx/conf.d/foodme.conf 2>/dev/null
    exit 1
fi

# Reload Nginx
echo "4. Reloading Nginx..."
systemctl reload nginx
if systemctl is-active nginx >/dev/null; then
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Nginx reload failed, restarting..."
    systemctl restart nginx
    if systemctl is-active nginx >/dev/null; then
        echo "✅ Nginx restarted successfully"
    else
        echo "❌ Nginx failed to start"
        exit 1
    fi
fi

# Test the endpoints
echo ""
echo "🔗 Testing Endpoints:"
echo "--------------------"

# Test health endpoint
echo -n "Testing /health endpoint: "
if curl -s http://localhost/health | grep -q "status"; then
    echo "✅ Working"
else
    echo "❌ Not working"
    echo "Checking if Node.js app is running..."
    if systemctl is-active foodme >/dev/null; then
        echo "  FoodMe service is running"
        echo "  Testing direct connection to Node.js..."
        if curl -s http://localhost:3000/health | grep -q "status"; then
            echo "  ✅ Node.js app responds directly"
            echo "  ❌ Nginx proxy configuration issue"
        else
            echo "  ❌ Node.js app not responding"
        fi
    else
        echo "  ❌ FoodMe service not running"
        echo "  Starting FoodMe service..."
        systemctl start foodme
        sleep 3
        if systemctl is-active foodme >/dev/null; then
            echo "  ✅ FoodMe service started"
        else
            echo "  ❌ FoodMe service failed to start"
        fi
    fi
fi

# Test root endpoint
echo -n "Testing / (root) endpoint: "
if curl -s http://localhost/ | grep -q "FoodMe"; then
    echo "✅ Working"
else
    echo "❌ Not working"
fi

echo ""
echo "📊 Current Status:"
echo "-----------------"
echo "Nginx: $(systemctl is-active nginx)"
echo "FoodMe: $(systemctl is-active foodme)"
echo ""

echo "🎉 Nginx Configuration Fix Complete!"
echo "===================================="
echo ""
echo "Test your application:"
echo "• Root: http://54.188.233.101/"
echo "• Health: http://54.188.233.101/health"
echo "• API: http://54.188.233.101/api/health"
echo ""
echo "Key changes made:"
echo "• Used exact match (=) for /health location"
echo "• Added proper proxy headers"
echo "• Ensured location order is correct"
echo "• Added caching headers for static files"
