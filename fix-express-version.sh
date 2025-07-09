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
    
    # Show current content
    echo "Current package.json content:"
    cat package.json
    
    # Update Express version using sed (handle both single and double quotes)
    sed -i 's/"express": "[^"]*"/"express": "^4.18.3"/' package.json
    sed -i "s/'express': '[^']*'/'express': '^4.18.3'/" package.json
    
    echo "✅ Updated package.json"
    echo "Express version in package.json after update:"
    grep '"express"' package.json || grep "'express'" package.json || echo "Express not found"
else
    echo "❌ package.json not found in $(pwd)"
    ls -la
    exit 1
fi

# Also check and update parent directory package.json if it exists
if [ -f "../package.json" ]; then
    echo "📝 Also updating parent package.json..."
    cp ../package.json ../package.json.backup
    sed -i 's/"express": "[^"]*"/"express": "^4.18.3"/' ../package.json
    echo "Updated parent package.json Express version:"
    grep '"express"' ../package.json || echo "Express not found in parent"
fi

# Clear node_modules and package-lock.json to ensure clean install
echo "🧹 Clearing old node_modules and npm cache..."
rm -rf node_modules package-lock.json
# Also clear npm cache to ensure no cached Express 5.x
npm cache clean --force

# Clear parent node_modules if exists
if [ -d "../node_modules" ]; then
    echo "🧹 Clearing parent node_modules..."
    rm -rf ../node_modules ../package-lock.json
fi

# Install dependencies
echo "📦 Installing dependencies with Express 4.x..."
npm install --production

# Also install in parent directory if package.json exists there
if [ -f "../package.json" ]; then
    echo "📦 Installing dependencies in parent directory..."
    cd ..
    npm install --production
    cd server 2>/dev/null || cd .
fi

# Verify Express version in all locations
echo "✅ Verifying Express versions:"
echo "Current directory:"
npm list express 2>/dev/null || echo "Express not found in current directory"

if [ -f "../package.json" ]; then
    echo "Parent directory:"
    cd .. && npm list express 2>/dev/null && cd server || cd .
fi

# Check for any remaining Express 5.x installations
echo "🔍 Checking for any Express 5.x installations:"
find /var/www/foodme -name "package.json" -exec grep -l "express.*5\." {} \; 2>/dev/null || echo "No Express 5.x found"

# Check what the systemd service is actually running
echo "🔍 Checking systemd service configuration:"
sudo systemctl cat foodme | grep -E "(WorkingDirectory|ExecStart)"

# Check if there are multiple Node.js processes or scripts
echo "🔍 Checking for multiple Node.js files:"
find /var/www/foodme -name "*.js" -exec grep -l "placeholder\|port.*3000" {} \; 2>/dev/null || echo "No placeholder files found"

# Check the actual start.js file being executed
echo "🔍 Contents of start.js:"
if [ -f "start.js" ]; then
    head -10 start.js
elif [ -f "../start.js" ]; then
    head -10 ../start.js
else
    echo "start.js not found"
fi

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
