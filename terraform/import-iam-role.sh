#!/bin/bash
# Import existing IAM role into Terraform state

echo "🔄 Importing existing IAM role into Terraform state..."

# Navigate to terraform directory
cd "$(dirname "$0")"

# Import the existing IAM role
terraform import aws_iam_role.foodme_ec2 foodme-staging-ec2-role

if [ $? -eq 0 ]; then
    echo "✅ Successfully imported IAM role"
    echo "📋 Run 'terraform plan' to see if there are any differences"
else
    echo "❌ Failed to import IAM role"
    exit 1
fi
