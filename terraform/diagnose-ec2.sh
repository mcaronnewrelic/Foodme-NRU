#!/bin/bash
# EC2 Deployment Diagnostic Script

INSTANCE_IP="${1:-52.10.167.10}"

echo "🔍 FoodMe EC2 Deployment Diagnostics"
echo "======================================"
echo "Instance IP: $INSTANCE_IP"
echo "Timestamp: $(date)"
echo ""

# Function to test endpoint with detailed output
test_endpoint_detailed() {
    local url=$1
    local name=$2
    
    echo "🌐 Testing $name: $url"
    
    # Get HTTP status code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$url" 2>/dev/null)
    echo "   Status Code: $status_code"
    
    # Get response time
    response_time=$(curl -s -o /dev/null -w "%{time_total}" -m 10 "$url" 2>/dev/null)
    echo "   Response Time: ${response_time}s"
    
    # Get actual response (first 200 chars)
    response=$(curl -s -m 10 "$url" 2>/dev/null | head -c 200)
    if [[ -n "$response" ]]; then
        echo "   Response: ${response}..."
    else
        echo "   Response: No response received"
    fi
    
    echo ""
}

# Function to check port connectivity
check_port() {
    local ip=$1
    local port=$2
    local service=$3
    
    echo "🔌 Checking $service (port $port)..."
    if nc -z -w5 "$ip" "$port" 2>/dev/null; then
        echo "   ✅ Port $port is open"
    else
        echo "   ❌ Port $port is closed or filtered"
    fi
}

# Basic connectivity tests
echo "🏥 CONNECTIVITY TESTS"
echo "===================="

# Ping test
echo "📡 Ping test..."
if ping -c 3 -W 5 "$INSTANCE_IP" > /dev/null 2>&1; then
    echo "   ✅ Instance is reachable"
else
    echo "   ❌ Instance is not reachable"
fi
echo ""

# Port tests
check_port "$INSTANCE_IP" 22 "SSH"
check_port "$INSTANCE_IP" 80 "HTTP"
check_port "$INSTANCE_IP" 443 "HTTPS"
check_port "$INSTANCE_IP" 3000 "Node.js App"

echo ""
echo "🌍 ENDPOINT TESTS"
echo "================"

# Test various endpoints
test_endpoint_detailed "http://$INSTANCE_IP/" "Root endpoint (port 80)"
test_endpoint_detailed "http://$INSTANCE_IP/health" "Health endpoint (port 80)"
test_endpoint_detailed "http://$INSTANCE_IP/api/restaurant" "API endpoint (port 80)"
test_endpoint_detailed "http://$INSTANCE_IP:3000/" "Root endpoint (port 3000)"
test_endpoint_detailed "http://$INSTANCE_IP:3000/health" "Health endpoint (port 3000)"
test_endpoint_detailed "http://$INSTANCE_IP:3000/api/restaurant" "API endpoint (port 3000)"

echo "🔍 NGINX CONFIGURATION CHECK"
echo "============================"

# Check if nginx is serving a default page
default_response=$(curl -s -m 5 "http://$INSTANCE_IP/" 2>/dev/null)
if [[ "$default_response" == *"nginx"* ]] || [[ "$default_response" == *"Apache"* ]]; then
    echo "   ⚠️ Default web server page detected - app may not be configured"
elif [[ "$default_response" == *"FoodMe"* ]] || [[ "$default_response" == *"foodme"* ]]; then
    echo "   ✅ FoodMe application detected"
else
    echo "   ❓ Unknown response from web server"
fi

echo ""
echo "📋 SUMMARY & RECOMMENDATIONS"
echo "============================="

# Check if any endpoint is working
working_endpoints=0
for endpoint in "/" "/health" "/api/restaurant" ":3000/" ":3000/health" ":3000/api/restaurant"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "http://$INSTANCE_IP$endpoint" 2>/dev/null)
    if [[ "$status" =~ ^[2-3][0-9][0-9]$ ]]; then
        ((working_endpoints++))
    fi
done

echo "Working endpoints: $working_endpoints/6"

if [ $working_endpoints -eq 0 ]; then
    echo ""
    echo "❌ NO ENDPOINTS RESPONDING"
    echo "Possible causes:"
    echo "1. Application failed to start"
    echo "2. Docker containers not running"
    echo "3. Nginx not configured properly"
    echo "4. Security group blocking traffic"
    echo "5. User data script failed"
    echo ""
    echo "🛠️ DEBUGGING STEPS:"
    echo "1. SSH to instance: ssh -i your-key.pem ec2-user@$INSTANCE_IP"
    echo "2. Check system logs: sudo journalctl -f"
    echo "3. Check cloud-init logs: sudo cat /var/log/cloud-init-output.log"
    echo "4. Check nginx: sudo systemctl status nginx"
    echo "5. Check docker: sudo docker ps -a"
    echo "6. Check app logs: sudo docker logs foodme-app 2>&1 | tail -50"
elif [ $working_endpoints -lt 3 ]; then
    echo ""
    echo "⚠️ PARTIAL FUNCTIONALITY"
    echo "Some endpoints working, but not all. Check nginx configuration."
else
    echo ""
    echo "✅ MOST ENDPOINTS WORKING"
    echo "Application appears to be running correctly."
fi

echo ""
echo "🔗 Quick test commands:"
echo "curl -v http://$INSTANCE_IP/health"
echo "curl -v http://$INSTANCE_IP:3000/health"
