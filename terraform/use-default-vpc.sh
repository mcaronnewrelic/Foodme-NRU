#!/bin/bash

# Quick fix script to use default VPC and avoid VPC limit errors
# This modifies terraform.tfvars to use existing default VPC

set -e

REGION="us-west-2"
TFVARS_FILE="terraform.tfvars"

echo "🔧 Quick VPC Limit Fix"
echo "====================="
echo "This script will configure Terraform to use the default VPC"
echo "instead of creating a new one, avoiding VPC limit errors."
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get default VPC information
echo "🔍 Finding default VPC in $REGION..."
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" \
    --filters "Name=isDefault,Values=true" \
    --query 'Vpcs[0].VpcId' --output text)

if [ "$DEFAULT_VPC_ID" = "None" ] || [ -z "$DEFAULT_VPC_ID" ]; then
    echo "❌ No default VPC found in $REGION"
    echo "💡 You may need to create a default VPC or clean up existing VPCs"
    exit 1
fi

echo "✅ Found default VPC: $DEFAULT_VPC_ID"

# Get default subnet
echo "🔍 Finding default public subnet..."
DEFAULT_SUBNET_ID=$(aws ec2 describe-subnets --region "$REGION" \
    --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" "Name=default-for-az,Values=true" \
    --query 'Subnets[0].SubnetId' --output text)

if [ "$DEFAULT_SUBNET_ID" = "None" ] || [ -z "$DEFAULT_SUBNET_ID" ]; then
    echo "❌ No default subnet found in default VPC"
    exit 1
fi

echo "✅ Found default subnet: $DEFAULT_SUBNET_ID"

# Create or update terraform.tfvars
echo "📝 Creating/updating $TFVARS_FILE..."

cat > "$TFVARS_FILE" << EOF
# Auto-generated configuration to use default VPC
# This avoids VPC limit exceeded errors

# Use existing default VPC instead of creating new one
use_existing_vpc = true
existing_vpc_id = "$DEFAULT_VPC_ID"
existing_public_subnet_id = "$DEFAULT_SUBNET_ID"

# Standard configuration
aws_region = "$REGION"
environment = "staging"
instance_type = "t3.small"
app_port = 3000

# Optional: Uncomment if you have these configured
# key_name = "your-key-name"
# allowed_cidr_blocks = ["0.0.0.0/0"]
EOF

echo "✅ Created $TFVARS_FILE with default VPC configuration"
echo ""
echo "🎯 Next steps:"
echo "1. Review the generated $TFVARS_FILE file"
echo "2. Add your EC2 key name if you have one configured"
echo "3. Run your Terraform deployment - it will use the default VPC"
echo ""
echo "📋 Current configuration:"
echo "- VPC ID: $DEFAULT_VPC_ID"
echo "- Subnet ID: $DEFAULT_SUBNET_ID"
echo "- Region: $REGION"
echo ""
echo "⚠️  Note: Using default VPC is fine for testing/staging"
echo "For production, consider cleaning up unused VPCs or requesting limit increase"
