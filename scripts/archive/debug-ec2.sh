#!/bin/bash

# Debug EC2 Instance Script
# This script helps debug issues with the FoodMe EC2 deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get instance IP from Terraform
print_header "Getting EC2 Instance Information"

if [ ! -d "terraform" ]; then
    print_error "terraform directory not found. Run this script from the project root."
    exit 1
fi

cd terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    print_error "No terraform state found. Deploy the infrastructure first."
    exit 1
fi

# Get instance IP
INSTANCE_IP=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "")

if [ -z "$INSTANCE_IP" ]; then
    print_error "Could not get instance IP from terraform output"
    exit 1
fi

print_success "Instance IP: $INSTANCE_IP"

# Basic connectivity test
print_header "Testing Connectivity"

if ping -c 1 -W 3 "$INSTANCE_IP" >/dev/null 2>&1; then
    print_success "Instance is reachable via ping"
else
    print_warning "Instance is not responding to ping (may be normal)"
fi

# Test HTTP connectivity
print_header "Testing HTTP Endpoints"

test_endpoint() {
    local endpoint="$1"
    local description="$2"
    
    echo "Testing $description ($endpoint)..."
    
    # Get status code
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$endpoint" 2>/dev/null || echo "000")
    
    case "$HTTP_CODE" in
        "200")
            print_success "$description: HTTP $HTTP_CODE (OK)"
            return 0
            ;;
        "502")
            print_error "$description: HTTP $HTTP_CODE (Bad Gateway - nginx can't reach backend)"
            ;;
        "503")
            print_error "$description: HTTP $HTTP_CODE (Service Unavailable)"
            ;;
        "404")
            print_warning "$description: HTTP $HTTP_CODE (Not Found)"
            ;;
        "000")
            print_error "$description: Connection failed"
            ;;
        *)
            print_warning "$description: HTTP $HTTP_CODE"
            ;;
    esac
    
    return 1
}

# Test various endpoints
test_endpoint "http://$INSTANCE_IP/" "Root endpoint"
test_endpoint "http://$INSTANCE_IP/health" "Health endpoint"
test_endpoint "http://$INSTANCE_IP/api/health" "API health endpoint"

# Test with verbose curl for main endpoint
print_header "Detailed Connection Test"

echo "Testing with verbose curl..."
if ! curl -v --connect-timeout 10 --max-time 30 "http://$INSTANCE_IP/" 2>&1 | head -20; then
    print_error "Detailed connection test failed"
fi

# SSH diagnostic (if key is available)
print_header "SSH Diagnostic Information"

SSH_KEY_PATH=""
if [ -f "foodme-key.pem" ]; then
    SSH_KEY_PATH="foodme-key.pem"
elif [ -f "~/.ssh/foodme-key.pem" ]; then
    SSH_KEY_PATH="~/.ssh/foodme-key.pem"
fi

if [ -n "$SSH_KEY_PATH" ] && [ -f "$SSH_KEY_PATH" ]; then
    print_success "SSH key found at $SSH_KEY_PATH"
    echo "You can SSH to the instance with:"
    echo "  ssh -i $SSH_KEY_PATH ec2-user@$INSTANCE_IP"
    echo ""
    echo "Once connected, run these diagnostic commands:"
    echo "  sudo systemctl status nginx foodme"
    echo "  sudo journalctl -u foodme -n 50"
    echo "  sudo netstat -tlnp | grep :3000"
    echo "  curl localhost:3000/health"
    echo "  sudo tail -20 /var/log/nginx/error.log"
    echo "  sudo tail -20 /var/log/nginx/access.log"
    echo "  ps aux | grep node"
else
    print_warning "SSH key not found"
    echo "To create an SSH key and enable SSH access:"
    echo "  cd terraform && ./create-keypair.sh"
    echo "  Then add EC2_KEY_NAME and EC2_PRIVATE_KEY to GitHub secrets"
fi

print_header "Troubleshooting Suggestions"

echo "Common issues and solutions:"
echo ""
echo "1. 502 Bad Gateway:"
echo "   - Node.js app is not running or not listening on port 3000"
echo "   - Check: sudo systemctl status foodme"
echo "   - Check: sudo journalctl -u foodme -n 50"
echo ""
echo "2. Connection timeout:"
echo "   - Security groups may be blocking traffic"
echo "   - Instance may still be starting up"
echo "   - Wait 5-10 minutes after deployment"
echo ""
echo "3. 503 Service Unavailable:"
echo "   - nginx is running but backend is down"
echo "   - Check nginx config: sudo nginx -t"
echo "   - Check: sudo systemctl status nginx"
echo ""
echo "4. If placeholder app should be running:"
echo "   - SSH to instance and run: cd /var/www/foodme && ./health-check.sh"
echo "   - Check if placeholder was replaced properly"

print_header "Current Status Summary"

if test_endpoint "http://$INSTANCE_IP/health" "Health check" >/dev/null 2>&1; then
    print_success "Instance appears to be healthy"
else
    print_error "Instance is not responding correctly"
    echo ""
    echo "Next steps:"
    echo "1. Wait 5-10 minutes if deployment just completed"
    echo "2. SSH to instance for detailed diagnosis"
    echo "3. Check GitHub Actions logs for deployment errors"
    echo "4. Consider re-running deployment"
fi

cd ..
