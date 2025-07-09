#!/bin/bash
# FoodMe EC2 Quick Fix Script
# This script fixes common deployment issues

echo "🔧 FoodMe Quick Fix Script"
echo "=========================="
echo ""

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root or with sudo"
   echo "Usage: sudo ./fix-deployment.sh"
   exit 1
fi

echo "🎯 Applying Quick Fixes..."
echo ""

# Fix 1: Create missing index.html file
echo "1. Creating index.html file..."
cat > /var/www/foodme/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoodMe - Restaurant Discovery App</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        p {
            font-size: 1.2rem;
            margin-bottom: 1.5rem;
            opacity: 0.9;
        }
        .status {
            background: rgba(255, 255, 255, 0.2);
            padding: 1rem;
            border-radius: 10px;
            margin: 1rem 0;
        }
        .api-links {
            margin-top: 2rem;
        }
        .api-links a {
            color: #fff;
            text-decoration: none;
            margin: 0 1rem;
            padding: 0.5rem 1rem;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 5px;
            transition: background 0.3s;
        }
        .api-links a:hover {
            background: rgba(255, 255, 255, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍕 FoodMe</h1>
        <p>Your favorite restaurant discovery app is now live!</p>
        
        <div class="status">
            <strong>✅ Application Status:</strong> Running on EC2
        </div>
        
        <div class="api-links">
            <a href="/health">Health Check</a>
            <a href="/api/health">API Health</a>
            <a href="/api/restaurant">Restaurants</a>
        </div>
        
        <p style="margin-top: 2rem; font-size: 0.9rem; opacity: 0.7;">
            Deployed with Terraform • Monitored with New Relic • Powered by Node.js
        </p>
    </div>

    <script>
        // Simple health check indicator
        fetch('/health')
            .then(response => response.json())
            .then(data => {
                console.log('Health check:', data);
            })
            .catch(error => {
                console.log('Health check failed:', error);
            });
    </script>
</body>
</html>
EOF

echo "✅ Created index.html"

# Fix 2: Set proper file permissions
echo "2. Setting proper file permissions..."
chown -R nginx:nginx /var/www/foodme
chmod -R 755 /var/www/foodme
echo "✅ Fixed file permissions"

# Fix 3: Ensure directories exist
echo "3. Creating necessary directories..."
mkdir -p /var/www/foodme/server
mkdir -p /var/log/foodme
chown ec2-user:ec2-user /var/log/foodme
echo "✅ Created directories"

# Fix 4: Install Node.js dependencies
echo "4. Installing Node.js dependencies..."
cd /var/www/foodme
if [ -f package.json ]; then
    sudo -u ec2-user npm install --production
    echo "✅ Dependencies installed"
else
    echo "⚠️  No package.json found - this might be normal if using minimal setup"
fi

# Fix 5: Restart services in correct order
echo "5. Restarting services..."
systemctl stop foodme 2>/dev/null
systemctl stop nginx 2>/dev/null

# Start PostgreSQL first
systemctl start postgresql-16
sleep 2

# Start FoodMe app
systemctl start foodme
sleep 3

# Start Nginx last
systemctl start nginx
sleep 2

echo "✅ Services restarted"

# Fix 6: Check service status
echo ""
echo "📊 Service Status Check:"
echo "----------------------"

if systemctl is-active postgresql-16 >/dev/null; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not running"
fi

if systemctl is-active foodme >/dev/null; then
    echo "✅ FoodMe App: Running"
else
    echo "❌ FoodMe App: Not running"
fi

if systemctl is-active nginx >/dev/null; then
    echo "✅ Nginx: Running"
else
    echo "❌ Nginx: Not running"
fi

# Fix 7: Test connectivity
echo ""
echo "🔗 Connectivity Tests:"
echo "---------------------"

# Test app directly
if curl -s http://localhost:3000/health >/dev/null 2>&1; then
    echo "✅ App responds on port 3000"
else
    echo "❌ App not responding on port 3000"
fi

# Test through Nginx
if curl -s http://localhost/health >/dev/null 2>&1; then
    echo "✅ Nginx proxy working"
else
    echo "❌ Nginx proxy not working"
fi

# Test root page
if curl -s http://localhost/ | grep -q "FoodMe" 2>/dev/null; then
    echo "✅ Root page accessible"
else
    echo "❌ Root page not accessible"
fi

echo ""
echo "🎉 Quick Fix Complete!"
echo "====================="
echo ""
echo "Now test your application:"
echo "• Root URL: http://54.188.233.101/"
echo "• Health: http://54.188.233.101/health"
echo "• API: http://54.188.233.101/api/health"
echo ""
echo "If issues persist, run: sudo ./diagnose-deployment.sh"
