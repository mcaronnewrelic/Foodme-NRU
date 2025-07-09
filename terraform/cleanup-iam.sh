#!/bin/bash

# Script to clean up existing IAM resources that might conflict with Terraform
# Use this if you get "EntityAlreadyExists" errors

set -e

ENVIRONMENT="staging"
REGION="us-west-2"

echo "🧹 Cleaning up existing IAM resources for FoodMe ${ENVIRONMENT}"
echo "Region: ${REGION}"
echo ""

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "❌ Error: AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    echo "✅ AWS CLI configured"
}

# Function to delete IAM resources
cleanup_iam_resources() {
    local role_name="foodme-${ENVIRONMENT}-ec2-role"
    local policy_name="foodme-${ENVIRONMENT}-ec2-policy"
    local profile_name="foodme-${ENVIRONMENT}-ec2-profile"
    
    echo "🔍 Checking for existing IAM resources..."
    
    # Check and delete instance profile
    if aws iam get-instance-profile --instance-profile-name "$profile_name" > /dev/null 2>&1; then
        echo "🗑️  Deleting instance profile: $profile_name"
        # Remove role from instance profile first
        aws iam remove-role-from-instance-profile \
            --instance-profile-name "$profile_name" \
            --role-name "$role_name" 2>/dev/null || true
        # Delete instance profile
        aws iam delete-instance-profile --instance-profile-name "$profile_name"
        echo "✅ Instance profile deleted"
    else
        echo "ℹ️  Instance profile $profile_name does not exist"
    fi
    
    # Check and delete role policy
    if aws iam get-role-policy --role-name "$role_name" --policy-name "$policy_name" > /dev/null 2>&1; then
        echo "🗑️  Deleting role policy: $policy_name"
        aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy_name"
        echo "✅ Role policy deleted"
    else
        echo "ℹ️  Role policy $policy_name does not exist"
    fi
    
    # Check and delete role
    if aws iam get-role --role-name "$role_name" > /dev/null 2>&1; then
        echo "🗑️  Deleting IAM role: $role_name"
        aws iam delete-role --role-name "$role_name"
        echo "✅ IAM role deleted"
    else
        echo "ℹ️  IAM role $role_name does not exist"
    fi
}

# Function to list existing resources
list_existing_resources() {
    echo "📋 Listing existing FoodMe IAM resources:"
    echo ""
    
    # List roles
    echo "🔐 IAM Roles:"
    aws iam list-roles --query "Roles[?contains(RoleName, 'foodme')].RoleName" --output table || true
    echo ""
    
    # List instance profiles
    echo "👤 Instance Profiles:"
    aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, 'foodme')].InstanceProfileName" --output table || true
    echo ""
}

# Main execution
main() {
    echo "🚀 FoodMe IAM Cleanup Script"
    echo "=========================="
    echo ""
    
    check_aws_cli
    echo ""
    
    list_existing_resources
    echo ""
    
    read -p "Do you want to delete the conflicting IAM resources? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_iam_resources
        echo ""
        echo "🎉 Cleanup completed! You can now run Terraform apply."
    else
        echo "❌ Cleanup cancelled. Use the random suffix approach in Terraform instead."
    fi
    
    echo ""
    echo "💡 Alternative: The Terraform configuration now uses random suffixes"
    echo "   to avoid naming conflicts, so cleanup may not be necessary."
}

# Run main function
main "$@"
