#!/bin/bash

echo "=========================================="
echo "Validating Node.js Proxy Nginx Configuration"
echo "=========================================="

echo "Testing that nginx proxies all requests to Node.js..."
echo ""

# Test root path
echo "1. Testing root path (/) - should proxy to Node.js:"
response=$(curl -s -w "%{http_code}" -o /tmp/root_response http://localhost/)
http_code="${response: -3}"
if [ "$http_code" = "200" ]; then
    echo "   ✓ Root path returns 200"
    if grep -q "FoodMe" /tmp/root_response; then
        echo "   ✓ Response contains 'FoodMe' content"
        if grep -q "New Relic" /tmp/root_response; then
            echo "   ✓ New Relic integration detected in response"
        else
            echo "   ⚠ New Relic integration not detected"
        fi
    else
        echo "   ❌ Response doesn't contain expected content"
        echo "   Response preview: $(head -c 200 /tmp/root_response)"
    fi
else
    echo "   ❌ Root path returns HTTP $http_code"
fi

echo ""

# Test health endpoint
echo "2. Testing health endpoint (/health) - should proxy to Node.js:"
response=$(curl -s -w "%{http_code}" -o /tmp/health_response http://localhost/health)
http_code="${response: -3}"
if [ "$http_code" = "200" ]; then
    echo "   ✓ Health endpoint returns 200"
    if grep -q "status" /tmp/health_response && grep -q "ok" /tmp/health_response; then
        echo "   ✓ Health response contains expected JSON"
    else
        echo "   ❌ Health response doesn't contain expected JSON"
        echo "   Response: $(cat /tmp/health_response)"
    fi
else
    echo "   ❌ Health endpoint returns HTTP $http_code"
fi

echo ""

# Test Angular route (should be handled by Node.js catch-all)
echo "3. Testing Angular route (/restaurants) - should proxy to Node.js catch-all:"
response=$(curl -s -w "%{http_code}" -o /tmp/angular_response http://localhost/restaurants)
http_code="${response: -3}"
if [ "$http_code" = "200" ]; then
    echo "   ✓ Angular route returns 200"
    if grep -q "FoodMe" /tmp/angular_response; then
        echo "   ✓ Angular route serves index.html content via Node.js"
    else
        echo "   ❌ Angular route doesn't serve expected content"
        echo "   Response preview: $(head -c 200 /tmp/angular_response)"
    fi
else
    echo "   ❌ Angular route returns HTTP $http_code"
fi

echo ""

# Test static asset (should proxy to Node.js)
echo "4. Testing static asset request - should proxy to Node.js:"
response=$(curl -s -w "%{http_code}" -o /tmp/static_response http://localhost/favicon.ico)
http_code="${response: -3}"
if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
    echo "   ✓ Static asset request proxied to Node.js (HTTP $http_code)"
else
    echo "   ❌ Static asset request returns HTTP $http_code"
fi

echo ""

# Check nginx configuration
echo "5. Checking nginx configuration:"
if nginx -t 2>/dev/null; then
    echo "   ✓ Nginx configuration is valid"
else
    echo "   ❌ Nginx configuration has errors"
fi

# Check if nginx is serving static files directly (should NOT happen)
echo ""
echo "6. Verifying nginx is NOT serving static files directly:"
nginx_config=$(cat /etc/nginx/conf.d/foodme.conf 2>/dev/null || cat /etc/nginx/sites-available/default 2>/dev/null)
if echo "$nginx_config" | grep -q "root /var/www" && echo "$nginx_config" | grep -q "try_files"; then
    echo "   ❌ WARNING: Nginx configuration still contains static file serving directives"
    echo "   ❌ This may interfere with Node.js routing"
    echo "   ℹ Run: sudo ./apply-nodejs-proxy-nginx.sh"
elif echo "$nginx_config" | grep -q "proxy_pass.*localhost:3000"; then
    echo "   ✓ Nginx is configured to proxy requests to Node.js"
else
    echo "   ❌ Nginx configuration doesn't appear to proxy to Node.js"
fi

echo ""

# Check service status
echo "7. Service status:"
echo "   Nginx: $(systemctl is-active nginx)"
echo "   FoodMe: $(systemctl is-active foodme)"

# Clean up temp files
rm -f /tmp/root_response /tmp/health_response /tmp/angular_response /tmp/static_response

echo ""
echo "=========================================="
echo "Validation Complete!"
echo "=========================================="
echo ""
echo "If all tests pass, your nginx is correctly configured to:"
echo "• Proxy ALL requests to Node.js on port 3000"
echo "• Allow Node.js catch-all handler to serve index.html"
echo "• Handle Angular client-side routing properly"
echo ""
echo "If any tests fail, run: sudo ./apply-nodejs-proxy-nginx.sh"
echo ""
