#!/bin/bash
set -e

echo "Starting FoodMe deployment..."

if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    echo "Deploying real application..."
    npm install --production
    
    if [ -d "angular-app" ]; then
        cd angular-app && npm install && npm run build && cd ..
    fi
    
    if [ -d "angular-app/dist" ]; then
        cp -r angular-app/dist/* /var/www/foodme/ 2>/dev/null || true
    fi
    
    sudo systemctl restart foodme
else
    echo "Placeholder deployment..."
    sudo systemctl restart foodme
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
