#!/bin/bash

# Get Public IP and Format for Terraform
# This script helps you get your current public IP and format it correctly for Terraform

set -e

echo "🌐 Getting your public IP address..."

# Try multiple services to get public IP
get_public_ip() {
    local ip=""
    
    # Try different services
    ip=$(curl -s --max-time 5 https://checkip.amazonaws.com/ 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://icanhazip.com/ 2>/dev/null) || \
    ip=$(curl -s --max-time 5 https://ipecho.net/plain 2>/dev/null)
    
    # Clean up the response (remove whitespace)
    echo "$ip" | tr -d '[:space:]'
}

# Get the IP
PUBLIC_IP=$(get_public_ip)

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Could not determine your public IP address"
    echo "Please check your internet connection and try again"
    echo ""
    echo "You can manually find your IP at: https://whatismyipaddress.com/"
    echo "Then format it as: YOUR_IP/32"
    exit 1
fi

# Validate IP format
if [[ ! $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "❌ Invalid IP format received: $PUBLIC_IP"
    echo "Please manually check your IP address"
    exit 1
fi

echo "✅ Your public IP address: $PUBLIC_IP"
echo ""

# Format for Terraform
CIDR_BLOCK="$PUBLIC_IP/32"
echo "📋 For Terraform configuration:"
echo "   allowed_cidr_blocks = [\"$CIDR_BLOCK\"]"
echo ""

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        
        # Update the CIDR block in the new file
        if command -v sed >/dev/null 2>&1; then
            # macOS sed syntax
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|0.0.0.0/0|$CIDR_BLOCK|g" terraform.tfvars
            else
                # Linux sed syntax
                sed -i "s|0.0.0.0/0|$CIDR_BLOCK|g" terraform.tfvars
            fi
            echo "✅ Updated terraform.tfvars with your IP address"
        else
            echo "⚠️  Please manually update terraform.tfvars with your IP"
        fi
    else
        echo "❌ terraform.tfvars.example not found"
        echo "Please create terraform.tfvars manually"
    fi
else
    echo "📄 terraform.tfvars already exists"
    echo "   Consider updating the allowed_cidr_blocks value to: [\"$CIDR_BLOCK\"]"
fi

echo ""
echo "🔒 Security Note:"
echo "   - Using $CIDR_BLOCK restricts access to your IP only"
echo "   - This is more secure than 0.0.0.0/0 (all IPs)"
echo "   - Your IP may change if you're using DHCP"
echo ""

echo "📚 CIDR Examples:"
echo "   - Single IP:     192.168.1.1/32"
echo "   - Home network:  192.168.1.0/24  (256 addresses)"
echo "   - Office subnet: 10.0.0.0/16     (65,536 addresses)"
echo "   - All IPs:       0.0.0.0/0       (NOT recommended)"
echo ""

echo "🚀 Next Steps:"
echo "   1. Review and edit terraform.tfvars"
echo "   2. Set your AWS key pair name"
echo "   3. Configure other variables as needed"
echo "   4. Run: terraform plan"
