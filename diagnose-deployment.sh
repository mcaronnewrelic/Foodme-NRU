#!/bin/bash
# FoodMe EC2 Diagnostic Script
# Run this script on your EC2 instance to diagnose deployment issues

echo "🔍 FoodMe Deployment Diagnostic Script"
echo "======================================"
echo ""

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root or with sudo"
   echo "Usage: sudo ./diagnose-deployment.sh"
   exit 1
fi

echo "📋 System Information"
echo "-------------------"
echo "Date: $(date)"
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'Not available')"
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'Not available')"
echo ""

echo "🔧 Service Status"
echo "----------------"
echo "Nginx Status:"
systemctl is-active nginx && echo "✅ Nginx is running" || echo "❌ Nginx is not running"

echo ""
echo "FoodMe App Status:"
systemctl is-active foodme && echo "✅ FoodMe service is running" || echo "❌ FoodMe service is not running"

echo ""
echo "PostgreSQL Status:"
systemctl is-active postgresql-16 && echo "✅ PostgreSQL is running" || echo "❌ PostgreSQL is not running"

echo ""
echo "📁 File System Check"
echo "-------------------"
echo "FoodMe directory contents:"
ls -la /var/www/foodme/ 2>/dev/null || echo "❌ /var/www/foodme directory not found"

echo ""
echo "FoodMe server directory:"
ls -la /var/www/foodme/server/ 2>/dev/null || echo "❌ /var/www/foodme/server directory not found"

echo ""
echo "Check for index.html:"
if [ -f "/var/www/foodme/index.html" ]; then
    echo "✅ index.html exists"
else
    echo "❌ index.html missing - this causes the 403 error"
fi

echo ""
echo "🌐 Network & Port Check"
echo "----------------------"
echo "Checking port 3000:"
if netstat -tlnp | grep :3000 >/dev/null; then
    echo "✅ Port 3000 is listening"
    netstat -tlnp | grep :3000
else
    echo "❌ Port 3000 is not listening - Node.js app not running"
fi

echo ""
echo "Checking port 80:"
if netstat -tlnp | grep :80 >/dev/null; then
    echo "✅ Port 80 is listening"
    netstat -tlnp | grep :80
else
    echo "❌ Port 80 is not listening - Nginx not running properly"
fi

echo ""
echo "📊 Service Logs (Last 10 lines)"
echo "------------------------------"
echo "FoodMe Service Logs:"
journalctl -u foodme --no-pager -n 10 || echo "No FoodMe service logs found"

echo ""
echo "Nginx Error Logs:"
tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "No Nginx error logs found"

echo ""
echo "🔗 Connectivity Tests"
echo "--------------------"
echo "Testing localhost:3000/health:"
curl -s http://localhost:3000/health 2>/dev/null && echo " ✅ Health endpoint responding" || echo "❌ Health endpoint not responding"

echo ""
echo "Testing localhost/health via Nginx:"
curl -s http://localhost/health 2>/dev/null && echo " ✅ Nginx proxy to health endpoint working" || echo "❌ Nginx proxy not working"

echo ""
echo "🔧 Quick Fixes"
echo "-------------"
echo "1. Create missing index.html file:"
echo "   sudo cat > /var/www/foodme/index.html << 'EOF'"
echo "   <!DOCTYPE html>"
echo "   <html><head><title>FoodMe</title></head>"
echo "   <body><h1>🍕 FoodMe Application</h1><p>Welcome to FoodMe!</p></body></html>"
echo "   EOF"
echo ""
echo "2. Fix file permissions:"
echo "   sudo chown -R nginx:nginx /var/www/foodme"
echo "   sudo chmod -R 755 /var/www/foodme"
echo ""
echo "3. Restart services:"
echo "   sudo systemctl restart foodme nginx"
echo ""
echo "4. Check service status:"
echo "   sudo systemctl status foodme"
echo "   sudo systemctl status nginx"

echo ""
echo "🎯 Diagnostic Complete"
echo "====================="
