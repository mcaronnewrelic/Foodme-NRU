#!/bin/bash
set -e
echo "Starting FoodMe deployment..."
cd /var/www/foodme/dist/server
if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    echo "Deploying FoodMe application..."

    npm install --production
    if [ -d "server" ]; then
        echo "✅ Server directory found"
    else
        echo "❌ Server directory missing!"
        exit 1
    fi
    sudo systemctl restart foodme
else
    echo "No real application detected, placeholder continues..."
fi
sleep 15

for i in {1..5}; do
    if /var/www/foodme/health-check.sh; then
        echo "✅ Deployment successful!"
        break
    else
        if [ $i -eq 5 ]; then
            echo "❌ Deployment failed"
            sudo systemctl status foodme --no-pager || true
            sudo journalctl -u foodme --no-pager -n 20 || true
            exit 1
        fi
        sleep 10
    fi
done