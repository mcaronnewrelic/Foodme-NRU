#!/bin/bash

echo "=========================================="
echo "Checking FoodMe Application Status"
echo "=========================================="

# Check what's currently running
echo "1. Service Status:"
echo "   Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'not running')"
echo "   FoodMe: $(systemctl is-active foodme 2>/dev/null || echo 'not running')"

echo ""
echo "2. Current Application Response:"
echo "   What the app currently serves:"
echo "   ---"
curl -s http://localhost/ 2>/dev/null | head -c 300 || echo "   No response"
echo ""
echo "   ---"

echo ""
echo "3. Application Type Check:"
if [ -f "/var/www/foodme/server/index.js" ]; then
    echo "   ✓ Real FoodMe application (server/index.js) - FULL APP"
    
    # Check if Angular build exists
    if [ -d "/var/www/foodme/dist" ] || [ -d "/var/www/foodme/angular-app/dist" ]; then
        echo "   ✓ Angular build found"
    else
        echo "   ⚠ Angular build missing"
    fi
    
elif [ -f "/var/www/foodme/server/start.js" ]; then
    echo "   ⚠ Placeholder app (server/start.js) - PLACEHOLDER ONLY"
    echo "   This means GitHub Actions deployment hasn't completed"
else
    echo "   ❌ No application files found"
fi

echo ""
echo "4. File Structure:"
ls -la /var/www/foodme/ 2>/dev/null | head -10 || echo "   Directory not accessible"

echo ""
echo "5. Recent Service Logs:"
journalctl -u foodme --no-pager -n 5 2>/dev/null || echo "   No service logs"

echo ""
echo "=========================================="
echo "DIAGNOSIS & SOLUTION:"
echo "=========================================="

if [ -f "/var/www/foodme/server/index.js" ]; then
    echo "✅ Full FoodMe app is deployed but may need restart"
    echo ""
    echo "SOLUTION: Restart the service"
    echo "sudo systemctl restart foodme"
    echo "sudo systemctl status foodme"
    
elif [ -f "/var/www/foodme/server/start.js" ]; then
    echo "⚠ PROBLEM: Only placeholder app is running"
    echo ""
    echo "This means the real FoodMe application hasn't been deployed yet."
    echo "The 'FoodMe Starting...' message you see is likely from a different"
    echo "deployment attempt or cached content."
    echo ""
    echo "SOLUTION: Deploy the real application"
    echo ""
    echo "Option 1 - Trigger GitHub Actions deployment:"
    echo "1. Go to GitHub Actions in your repository"
    echo "2. Run the Deploy workflow manually"
    echo ""
    echo "Option 2 - Manual deployment:"
    echo "cd /var/www/foodme"
    echo "git clone https://github.com/mcaronnewrelic/Foodme-NRU.git ."
    echo "sudo chown -R ec2-user:ec2-user /var/www/foodme"
    echo "./deploy.sh"
    echo ""
    echo "Option 3 - Quick fix with pre-built app:"
    echo "sudo systemctl stop foodme"
    echo "cd /var/www/foodme"
    echo "# Download the real application files"
    echo "sudo systemctl start foodme"
    
else
    echo "❌ PROBLEM: No application found"
    echo ""
    echo "SOLUTION: Deploy the application"
    echo "1. Check if GitHub Actions deployment is running"
    echo "2. Or deploy manually as shown above"
fi

echo ""
