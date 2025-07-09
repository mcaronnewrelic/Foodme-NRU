#!/bin/bash
# Troubleshoot IAM role conflicts

echo "🔍 Checking IAM role status..."

# Check if role exists in AWS
aws iam get-role --role-name foodme-staging-ec2-role > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ IAM role 'foodme-staging-ec2-role' exists in AWS"
    
    # Show role details
    echo "📋 Role details:"
    aws iam get-role --role-name foodme-staging-ec2-role --query 'Role.{Name:RoleName,Created:CreateDate,Arn:Arn}' --output table
else
    echo "❌ IAM role 'foodme-staging-ec2-role' does not exist in AWS"
fi

# Check Terraform state
echo ""
echo "🔍 Checking Terraform state..."
cd "$(dirname "$0")"

terraform show | grep -A 5 -B 5 "foodme_ec2" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ IAM role found in Terraform state"
else
    echo "❌ IAM role NOT found in Terraform state"
    echo "💡 Consider running: terraform import aws_iam_role.foodme_ec2 foodme-staging-ec2-role"
fi
