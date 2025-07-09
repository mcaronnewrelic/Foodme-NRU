#!/bin/bash
# Enhanced health check script with better diagnostics

echo "🏥 Performing enhanced health check..."

# Get parameters
INSTANCE_IP="${1:-52.10.167.10}"
SKIP_SSH_DEPLOYMENT="${2:-false}"
MAX_ATTEMPTS=15
WAIT_TIME=30

echo "🖥️ Instance IP: $INSTANCE_IP"
echo "⚙️ SSH deployment skipped: $SKIP_SSH_DEPLOYMENT"

# Wait longer if SSH deployment was skipped
if [ "$SKIP_SSH_DEPLOYMENT" == "true" ]; then
    echo "ℹ️ SSH deployment was skipped, waiting longer for user_data script to complete..."
    sleep 180  # Wait 3 minutes for user_data to complete
fi

# Function to check basic connectivity
check_connectivity() {
    echo "🔌 Checking basic connectivity to $INSTANCE_IP..."
    
    # Check if instance is reachable
    if ping -c 3 -W 5 "$INSTANCE_IP" > /dev/null 2>&1; then
        echo "✅ Instance is reachable via ping"
    else
        echo "❌ Instance is not reachable via ping"
        return 1
    fi
    
    # Check if any HTTP service is running
    if nc -z -w5 "$INSTANCE_IP" 80 2>/dev/null; then
        echo "✅ Port 80 is open"
    else
        echo "❌ Port 80 is not open"
    fi
    
    if nc -z -w5 "$INSTANCE_IP" 3000 2>/dev/null; then
        echo "✅ Port 3000 is open"
    else
        echo "❌ Port 3000 is not open"
    fi
}

# Function to test different endpoints
test_endpoints() {
    local ip=$1
    local attempt=$2
    
    echo "🔍 Testing endpoints (attempt $attempt)..."
    
    # Test health endpoint (primary)
    if curl -f -m 10 "http://$ip/health" 2>/dev/null; then
        echo "✅ Health endpoint responded"
        return 0
    fi
    
    # Test root endpoint as fallback
    if curl -f -m 10 "http://$ip/" 2>/dev/null; then
        echo "✅ Root endpoint responded"
        return 0
    fi
    
    # Test port 3000 directly
    if curl -f -m 10 "http://$ip:3000/health" 2>/dev/null; then
        echo "✅ Health endpoint on port 3000 responded"
        return 0
    fi
    
    if curl -f -m 10 "http://$ip:3000/" 2>/dev/null; then
        echo "✅ Root endpoint on port 3000 responded"
        return 0
    fi
    
    # Test API endpoints
    if curl -f -m 10 "http://$ip/api/restaurant" 2>/dev/null; then
        echo "✅ API endpoint responded"
        return 0
    fi
    
    return 1
}

# Function to show detailed diagnostics
show_diagnostics() {
    local ip=$1
    echo ""
    echo "🔍 Detailed diagnostics for $ip:"
    
    # Show HTTP response codes
    echo "📊 HTTP response codes:"
    for endpoint in "/" "/health" ":3000/" ":3000/health" "/api/restaurant"; do
        response=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "http://$ip$endpoint" 2>/dev/null)
        echo "   http://$ip$endpoint -> $response"
    done
    
    # Check if services might be starting
    echo ""
    echo "🔄 Checking for startup indicators:"
    
    # Try to get any response (even errors)
    response=$(curl -s -m 5 "http://$ip/" 2>&1)
    if [[ -n "$response" ]]; then
        echo "   Got response from root: ${response:0:100}..."
    fi
    
    response=$(curl -s -m 5 "http://$ip:3000/" 2>&1)
    if [[ -n "$response" ]]; then
        echo "   Got response from port 3000: ${response:0:100}..."
    fi
}

# Main health check loop
echo ""
echo "🚀 Starting health check (max $MAX_ATTEMPTS attempts)..."

# Initial connectivity check
check_connectivity "$INSTANCE_IP"

for i in $(seq 1 $MAX_ATTEMPTS); do
    echo ""
    echo "🔄 Health check attempt $i/$MAX_ATTEMPTS..."
    
    if test_endpoints "$INSTANCE_IP" "$i"; then
        echo "✅ Health check passed on attempt $i"
        echo "health_passed=true" >> $GITHUB_OUTPUT
        exit 0
    fi
    
    # Show diagnostics every 3rd attempt
    if [ $((i % 3)) -eq 0 ]; then
        show_diagnostics "$INSTANCE_IP"
    fi
    
    if [ $i -lt $MAX_ATTEMPTS ]; then
        echo "⏳ Attempt $i failed, waiting $WAIT_TIME seconds..."
        sleep $WAIT_TIME
    fi
done

echo ""
echo "❌ Health check failed after $MAX_ATTEMPTS attempts"
echo "health_passed=false" >> $GITHUB_OUTPUT

# Final diagnostics
show_diagnostics "$INSTANCE_IP"

echo ""
echo "🛠️ Troubleshooting suggestions:"
echo "1. Check EC2 instance logs: AWS Console -> EC2 -> Instance -> Actions -> Monitor and troubleshoot -> Get system log"
echo "2. Check user_data script execution: /var/log/cloud-init-output.log"
echo "3. SSH into instance and check:"
echo "   - sudo systemctl status nginx"
echo "   - sudo systemctl status docker"
echo "   - sudo docker ps"
echo "   - sudo docker logs <container_name>"
echo "4. Check security group allows HTTP traffic on ports 80 and 3000"
echo "5. Verify the application is actually running: ps aux | grep node"

exit 1
