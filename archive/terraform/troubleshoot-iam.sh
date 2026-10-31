#!/bin/bash
# Troubleshoot IAM role conflicts and deployment issues

echo "🔍 Checking IAM role status..."

# Function to check IAM role with better error handling
check_iam_role() {
    local role_name=$1
    echo "Checking IAM role: $role_name"
    
    if command -v aws >/dev/null 2>&1; then
        # Check if role exists in AWS
        if aws iam get-role --role-name "$role_name" > /dev/null 2>&1; then
            echo "✅ IAM role '$role_name' exists in AWS"
            
            # Show role details
            echo "📋 Role details:"
            aws iam get-role --role-name "$role_name" --query 'Role.{Name:RoleName,Created:CreateDate,Arn:Arn}' --output table 2>/dev/null || echo "   Could not retrieve role details"
            
            # Check attached policies
            echo "📎 Attached policies:"
            aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[].PolicyName' --output table 2>/dev/null || echo "   Could not retrieve policies"
        else
            echo "❌ IAM role '$role_name' does not exist in AWS"
        fi
    else
        echo "⚠️ AWS CLI not available - cannot check IAM role in AWS"
    fi
}

# Check the specific role
check_iam_role "foodme-staging-ec2-role"

# Check Terraform state
echo ""
echo "🔍 Checking Terraform state..."
cd "$(dirname "$0")"

if command -v terraform >/dev/null 2>&1; then
    # Initialize terraform if needed
    if [ ! -d ".terraform" ]; then
        echo "Initializing Terraform..."
        terraform init -input=false > /dev/null 2>&1
    fi
    
    if terraform show 2>/dev/null | grep -A 5 -B 5 "foodme_ec2" > /dev/null 2>&1; then
        echo "✅ IAM role found in Terraform state"
        
        # Show current state
        echo "📋 Current Terraform state:"
        terraform show 2>/dev/null | grep -A 10 -B 2 "aws_iam_role.foodme_ec2" || echo "   Could not show detailed state"
    else
        echo "❌ IAM role NOT found in Terraform state"
        echo "💡 Consider running: terraform import aws_iam_role.foodme_ec2 foodme-staging-ec2-role"
    fi
else
    echo "⚠️ Terraform not available - cannot check Terraform state"
fi

echo ""
echo "🛠️ Common solutions:"
echo "1. Import existing role: ./import-iam-role.sh"
echo "2. Check AWS credentials: aws sts get-caller-identity"
echo "3. Verify Terraform initialization: terraform init"
echo "4. Plan deployment: terraform plan"
