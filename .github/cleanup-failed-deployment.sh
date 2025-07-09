#!/bin/bash

# Manual cleanup script for failed deployments
# Usage: ./cleanup-failed-deployment.sh [environment]

set -e

ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "🧹 Manual cleanup of FoodMe deployment resources"
echo "Environment: $ENVIRONMENT"
echo "Terraform directory: $TERRAFORM_DIR"

# Function to check if AWS CLI is configured
check_aws_config() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "❌ AWS CLI not configured or credentials invalid"
        echo "Please run 'aws configure' or set AWS environment variables"
        exit 1
    fi
    echo "✅ AWS credentials verified"
}

# Function to cleanup with Terraform
cleanup_with_terraform() {
    echo "🏗️ Attempting cleanup with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    if terraform init; then
        echo "✅ Terraform initialized"
    else
        echo "❌ Failed to initialize Terraform"
        return 1
    fi
    
    # Try to destroy resources
    echo "🗑️ Destroying AWS resources..."
    if terraform destroy -auto-approve \
        -var="environment=$ENVIRONMENT" \
        -var="app_version=manual-cleanup"; then
        echo "✅ Terraform destroy completed successfully"
        return 0
    else
        echo "⚠️ Terraform destroy encountered errors"
        return 1
    fi
}

# Function to manually clean up specific resources
manual_cleanup() {
    echo "🔧 Attempting manual cleanup of specific resources..."
    
    # Get current AWS region
    AWS_REGION=$(aws configure get region || echo "us-west-2")
    echo "Using AWS region: $AWS_REGION"
    
    # Find FoodMe instances
    echo "🔍 Looking for FoodMe EC2 instances..."
    INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=tag:Application,Values=FoodMe" \
                  "Name=tag:Environment,Values=$ENVIRONMENT" \
                  "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES" ]; then
        echo "🛑 Terminating EC2 instances: $INSTANCES"
        aws ec2 terminate-instances --instance-ids $INSTANCES --region "$AWS_REGION"
        echo "✅ Instance termination initiated"
    else
        echo "ℹ️ No FoodMe instances found"
    fi
    
    # Clean up security groups (after instances are terminated)
    echo "⏳ Waiting 30 seconds for instance termination to process..."
    sleep 30
    
    echo "🔍 Looking for FoodMe security groups..."
    SECURITY_GROUPS=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=foodme-*" \
        --query "SecurityGroups[?GroupName!='default'].GroupId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    if [ -n "$SECURITY_GROUPS" ]; then
        for sg in $SECURITY_GROUPS; do
            echo "🗑️ Deleting security group: $sg"
            aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" 2>/dev/null || echo "⚠️ Failed to delete $sg"
        done
    else
        echo "ℹ️ No FoodMe security groups found"
    fi
    
    # Clean up key pairs
    echo "🔍 Looking for FoodMe key pairs..."
    KEY_PAIRS=$(aws ec2 describe-key-pairs \
        --query "KeyPairs[?starts_with(KeyName, 'foodme-')].KeyName" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    if [ -n "$KEY_PAIRS" ]; then
        for key in $KEY_PAIRS; do
            echo "🗑️ Deleting key pair: $key"
            aws ec2 delete-key-pair --key-name "$key" --region "$AWS_REGION" 2>/dev/null || echo "⚠️ Failed to delete $key"
        done
    else
        echo "ℹ️ No FoodMe key pairs found"
    fi
}

# Function to cleanup IAM resources
cleanup_iam() {
    echo "🔍 Looking for FoodMe IAM resources..."
    
    # Find IAM roles
    IAM_ROLES=$(aws iam list-roles \
        --query "Roles[?starts_with(RoleName, 'foodme-')].RoleName" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$IAM_ROLES" ]; then
        for role in $IAM_ROLES; do
            echo "🗑️ Cleaning up IAM role: $role"
            
            # Detach policies
            POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text 2>/dev/null || echo "")
            for policy in $POLICIES; do
                aws iam detach-role-policy --role-name "$role" --policy-arn "$policy" 2>/dev/null || true
            done
            
            # Delete inline policies
            INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role" --query "PolicyNames" --output text 2>/dev/null || echo "")
            for policy in $INLINE_POLICIES; do
                aws iam delete-role-policy --role-name "$role" --policy-name "$policy" 2>/dev/null || true
            done
            
            # Remove from instance profiles
            INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name "$role" --query "InstanceProfiles[].InstanceProfileName" --output text 2>/dev/null || echo "")
            for profile in $INSTANCE_PROFILES; do
                aws iam remove-role-from-instance-profile --instance-profile-name "$profile" --role-name "$role" 2>/dev/null || true
                aws iam delete-instance-profile --instance-profile-name "$profile" 2>/dev/null || true
            done
            
            # Delete role
            aws iam delete-role --role-name "$role" 2>/dev/null || echo "⚠️ Failed to delete role $role"
        done
    else
        echo "ℹ️ No FoodMe IAM roles found"
    fi
}

# Function to show remaining resources
show_remaining_resources() {
    echo "🔍 Checking for any remaining FoodMe resources..."
    
    AWS_REGION=$(aws configure get region || echo "us-west-2")
    
    echo "EC2 Instances:"
    aws ec2 describe-instances \
        --filters "Name=tag:Application,Values=FoodMe" \
        --query "Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
    
    echo -e "\nSecurity Groups:"
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=foodme-*" \
        --query "SecurityGroups[].[GroupId,GroupName]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
    
    echo -e "\nVPCs:"
    aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=foodme-*" \
        --query "Vpcs[].[VpcId,Tags[?Key=='Name'].Value|[0]]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
}

# Main execution
main() {
    echo "Starting cleanup process..."
    
    # Check AWS configuration
    check_aws_config
    
    # Try Terraform cleanup first
    if cleanup_with_terraform; then
        echo "✅ Terraform cleanup successful"
    else
        echo "⚠️ Terraform cleanup failed, attempting manual cleanup..."
        manual_cleanup
        cleanup_iam
    fi
    
    echo -e "\n📊 Final resource check:"
    show_remaining_resources
    
    echo -e "\n✅ Cleanup process completed!"
    echo "💡 Please verify in the AWS console that all resources have been removed"
    echo "💡 Some resources may take a few minutes to be fully deleted"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [environment]"
    echo ""
    echo "Cleans up AWS resources created by the FoodMe deployment"
    echo ""
    echo "Arguments:"
    echo "  environment    Environment to clean up (default: staging)"
    echo ""
    echo "Examples:"
    echo "  $0                # Clean up staging environment"
    echo "  $0 production     # Clean up production environment"
    echo ""
    echo "Requirements:"
    echo "  - AWS CLI configured with appropriate permissions"
    echo "  - Terraform installed (for primary cleanup method)"
    exit 0
fi

# Run main function
main
