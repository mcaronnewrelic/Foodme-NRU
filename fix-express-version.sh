#!/bin/bash

# fix-express-version.sh - Fix Express version compatibility issue
# Run this on the EC2 instance to fix the path-to-regexp error

set -e

echo "🔧 Fixing Express version compatibility issue..."

# Stop the service
echo "🛑 Stopping foodme service..."
sudo systemctl stop foodme || true

# Navigate to server directory
if [ -d "/var/www/foodme/server" ]; then
    cd /var/www/foodme/server
elif [ -d "/var/www/foodme" ]; then
    cd /var/www/foodme
else
    echo "❌ Cannot find foodme directory"
    exit 1
fi

echo "📂 Working in directory: $(pwd)"

# Check current Express version
echo "🔍 Current Express version:"
npm list express 2>/dev/null || echo "Express not found in package.json"

# Update package.json to use Express 4.x
echo "📝 Updating package.json to use Express 4.18.3..."
if [ -f "package.json" ]; then
    # Create backup
    cp package.json package.json.backup
    
    # Update Express version using sed
    sed -i 's/"express": ".*"/"express": "^4.18.3"/' package.json
    
    echo "✅ Updated package.json"
    echo "Express version in package.json:"
    grep '"express"' package.json || echo "Express not found"
else
    echo "❌ package.json not found in $(pwd)"
    ls -la
    exit 1
fi

# Clear node_modules and package-lock.json to ensure clean install
echo "🧹 Clearing old node_modules..."
rm -rf node_modules package-lock.json

# Install dependencies
echo "📦 Installing dependencies with Express 4.x..."
npm install --production

# Verify Express version
echo "✅ New Express version:"
npm list express 2>/dev/null || echo "Express installation failed"

# Start the service
echo "🔄 Starting foodme service..."
sudo systemctl start foodme

# Wait and check status
sleep 5
echo "📊 Service status:"
sudo systemctl status foodme --no-pager -l

echo "🧪 Testing endpoints..."
echo "Testing direct Node.js health check:"
curl -s http://localhost:3000/health | head -3 || echo "Direct health check failed"

echo "Testing via nginx:"
curl -s http://localhost/health | head -3 || echo "Nginx health check failed"

echo "📋 Recent logs:"
sudo journalctl -u foodme -n 10 --no-pager

echo "🎯 Express version fix complete!"
echo "💡 If issues persist, check the logs above for any remaining errors."
