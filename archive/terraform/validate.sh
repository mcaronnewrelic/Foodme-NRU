#!/bin/bash

# Terraform Configuration Validation Script
# This script validates the Terraform configuration without requiring AWS credentials

set -e

echo "🔍 Validating Terraform configuration..."

cd "$(dirname "$0")"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Format check
echo "📝 Checking Terraform formatting..."
if terraform fmt -check -diff; then
    echo "✅ Terraform formatting is correct"
else
    echo "⚠️  Terraform formatting issues found. Running terraform fmt..."
    terraform fmt
    echo "✅ Terraform formatting fixed"
fi

# Validate configuration
echo "🔧 Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration has errors"
    exit 1
fi

# Check for required files
echo "📁 Checking required files..."
required_files=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "infrastructure.tf"
    "user_data.sh"
    "terraform.tfvars.example"
    ".gitignore"
    "README.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing"
        exit 1
    fi
done

# Validate user_data.sh template syntax
echo "📄 Validating user_data.sh template..."
if terraform console <<< 'templatefile("user_data.sh", {app_port=3000, environment="test", app_version="1.0.0"})' > /dev/null 2>&1; then
    echo "✅ user_data.sh template syntax is valid"
else
    echo "❌ user_data.sh template has syntax errors"
    exit 1
fi

echo ""
echo "🎉 All validations passed!"
echo ""
echo "📝 Next steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars"
echo "2. Configure your AWS credentials"
echo "3. Edit terraform.tfvars with your settings"
echo "4. Run 'terraform init' to initialize"
echo "5. Run 'terraform plan' to see planned changes"
echo "6. Run 'terraform apply' to deploy"
