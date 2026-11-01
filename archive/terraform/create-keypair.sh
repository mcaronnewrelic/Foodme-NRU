#!/bin/bash

# Script to create EC2 Key Pair for FoodMe deployment
# This script will create a new key pair and save the private key locally

set -e

# Configuration
KEY_NAME="foodme-deploy-key"
REGION="us-west-2"
PRIVATE_KEY_FILE="$HOME/.ssh/foodme-deploy-key.pem"

echo "Creating EC2 Key Pair: $KEY_NAME in region $REGION"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if key pair already exists
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "Key pair '$KEY_NAME' already exists in $REGION"
    echo "If you want to recreate it, delete it first with:"
    echo "aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION"
    exit 1
fi

# Create the key pair and save private key
echo "Creating key pair and saving private key to $PRIVATE_KEY_FILE"
aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$PRIVATE_KEY_FILE"

# Set correct permissions
chmod 600 "$PRIVATE_KEY_FILE"

echo "✅ Key pair created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Add the following secrets to your GitHub repository:"
echo "   - EC2_KEY_NAME: $KEY_NAME"
echo "   - EC2_PRIVATE_KEY: (paste the content of $PRIVATE_KEY_FILE)"
echo ""
echo "2. To get the private key content for GitHub secrets:"
echo "   cat $PRIVATE_KEY_FILE"
echo ""
echo "3. To test SSH access later:"
echo "   ssh -i $PRIVATE_KEY_FILE ec2-user@<instance-ip>"
echo ""
echo "🔐 Private key saved to: $PRIVATE_KEY_FILE"
echo "🔑 Key pair name: $KEY_NAME"
echo "🌍 Region: $REGION"
