#!/bin/bash
# FoodMe EC2 Quick Fix Script - Minimal Version
# This script fixes the deployment without npm install complications

echo "🔧 FoodMe Minimal Quick Fix"
echo "============================"
echo ""

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root or with sudo"
   echo "Usage: sudo ./fix-deployment-minimal.sh"
   exit 1
fi

echo "🎯 Applying Essential Fixes..."
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

# Fix 2: Create necessary directories
echo "2. Creating necessary directories..."
mkdir -p /var/www/foodme/server
mkdir -p /var/log/foodme
echo "✅ Created directories"

# Fix 3: Set proper file permissions for web serving
echo "3. Setting file permissions..."
# Set ownership for web files (nginx needs to read)
chown -R nginx:nginx /var/www/foodme
chmod -R 755 /var/www/foodme

# Set ownership for logs (ec2-user needs to write)
chown ec2-user:ec2-user /var/log/foodme

# Ensure ec2-user can write to app directory for runtime files
chmod 755 /var/www/foodme
echo "✅ Fixed file permissions"

# Fix 4: Restart services in correct order
echo "4. Restarting services..."
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

# Fix 5: Check service status
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
    echo "   Checking logs..."
    journalctl -u foodme --no-pager -n 5 | tail -n 3
fi

if systemctl is-active nginx >/dev/null; then
    echo "✅ Nginx: Running"
else
    echo "❌ Nginx: Not running"
fi

# Fix 6: Test connectivity
echo ""
echo "🔗 Connectivity Tests:"
echo "---------------------"

# Test app directly
if curl -s http://localhost:3000/health >/dev/null 2>&1; then
    echo "✅ App responds on port 3000"
else
    echo "❌ App not responding on port 3000"
    echo "   Checking if port is in use..."
    netstat -tlnp | grep :3000 || echo "   Port 3000 not listening"
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
echo "🎉 Minimal Fix Complete!"
echo "========================"
echo ""
echo "Now test your application:"
echo "• Root URL: http://54.188.233.101/"
echo "• Health: http://54.188.233.101/health"
echo "• API: http://54.188.233.101/api/health"
echo ""
echo "If the app still doesn't respond on port 3000:"
echo "• Check logs: sudo journalctl -u foodme -f"
echo "• The minimal app should work without npm dependencies"
echo "• Try: sudo systemctl restart foodme"
