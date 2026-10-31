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
    
    # Check if terraform.tfstate exists
    if [ ! -f "terraform.tfstate" ]; then
        echo "⚠️ No terraform.tfstate found - Terraform may not have been used to create resources"
        return 1
    fi
    
    # Check if state has any resources
    if ! terraform show -json 2>/dev/null | grep -q '"values"'; then
        echo "ℹ️ Terraform state is empty - no resources to destroy"
        return 1
    fi
    
    # Initialize Terraform
    if terraform init; then
        echo "✅ Terraform initialized"
    else
        echo "❌ Failed to initialize Terraform"
        return 1
    fi
    
    # Show what Terraform plans to destroy
    echo "📋 Terraform plan to destroy:"
    terraform plan -destroy \
        -var="environment=$ENVIRONMENT" \
        -var="app_version=manual-cleanup" || return 1
    
    # Try to destroy resources
    echo "🗑️ Destroying AWS resources with Terraform..."
    if terraform destroy -auto-approve \
        -var="environment=$ENVIRONMENT" \
        -var="app_version=manual-cleanup"; then
        echo "✅ Terraform destroy command completed"
        return 0
    else
        echo "⚠️ Terraform destroy encountered errors"
        return 1
    fi
}

# Function to manually clean up specific resources
manual_cleanup() {
    echo "🔧 Performing manual cleanup of AWS resources..."
    
    # Get current AWS region
    AWS_REGION=$(aws configure get region || echo "us-west-2")
    echo "Using AWS region: $AWS_REGION"
    
    # Find and terminate FoodMe instances
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
        
        # Wait for instances to terminate
        echo "⏳ Waiting for instances to terminate..."
        for instance in $INSTANCES; do
            aws ec2 wait instance-terminated --instance-ids "$instance" --region "$AWS_REGION" &
        done
        wait
        echo "✅ All instances terminated"
    else
        echo "ℹ️ No FoodMe instances found"
    fi
    
    # Clean up security groups
    echo "🔍 Looking for FoodMe security groups..."
    SECURITY_GROUPS=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=foodme-$ENVIRONMENT-*" \
        --query "SecurityGroups[?GroupName!='default'].GroupId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    if [ -n "$SECURITY_GROUPS" ]; then
        for sg in $SECURITY_GROUPS; do
            echo "🗑️ Deleting security group: $sg"
            aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" 2>/dev/null || echo "⚠️ Failed to delete $sg (may have dependencies)"
        done
        echo "✅ Security group cleanup completed"
    else
        echo "ℹ️ No FoodMe security groups found"
    fi
    
    # Clean up VPC resources
    echo "🔍 Looking for FoodMe VPCs and related resources..."
    VPCS=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=foodme-$ENVIRONMENT-*" \
        --query "Vpcs[].VpcId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    if [ -n "$VPCS" ]; then
        for vpc in $VPCS; do
            echo "🗑️ Cleaning up VPC: $vpc"
            
            # Delete subnets
            SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query "Subnets[].SubnetId" --output text --region "$AWS_REGION" 2>/dev/null || echo "")
            for subnet in $SUBNETS; do
                echo "  �️ Deleting subnet: $subnet"
                aws ec2 delete-subnet --subnet-id "$subnet" --region "$AWS_REGION" 2>/dev/null || true
            done
            
            # Delete route tables (except main)
            ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" --output text --region "$AWS_REGION" 2>/dev/null || echo "")
            for rt in $ROUTE_TABLES; do
                echo "  🗑️ Deleting route table: $rt"
                aws ec2 delete-route-table --route-table-id "$rt" --region "$AWS_REGION" 2>/dev/null || true
            done
            
            # Detach and delete internet gateway
            IGWS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[].InternetGatewayId" --output text --region "$AWS_REGION" 2>/dev/null || echo "")
            for igw in $IGWS; do
                echo "  🗑️ Detaching and deleting internet gateway: $igw"
                aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" --region "$AWS_REGION" 2>/dev/null || true
                aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$AWS_REGION" 2>/dev/null || true
            done
            
            # Delete VPC
            echo "  🗑️ Deleting VPC: $vpc"
            aws ec2 delete-vpc --vpc-id "$vpc" --region "$AWS_REGION" 2>/dev/null || echo "  ⚠️ Failed to delete VPC $vpc"
        done
        echo "✅ VPC cleanup completed"
    else
        echo "ℹ️ No FoodMe VPCs found"
    fi
    
    # Clean up key pairs
    echo "�🔍 Looking for FoodMe key pairs..."
    KEY_PAIRS=$(aws ec2 describe-key-pairs \
        --query "KeyPairs[?starts_with(KeyName, 'foodme-$ENVIRONMENT-')].KeyName" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    if [ -n "$KEY_PAIRS" ]; then
        for key in $KEY_PAIRS; do
            echo "🗑️ Deleting key pair: $key"
            aws ec2 delete-key-pair --key-name "$key" --region "$AWS_REGION" 2>/dev/null || echo "⚠️ Failed to delete $key"
        done
        echo "✅ Key pair cleanup completed"
    else
        echo "ℹ️ No FoodMe key pairs found"
    fi
}

# Function to cleanup IAM resources
cleanup_iam() {
    echo "🔍 Looking for FoodMe IAM resources..."
    
    # Find IAM roles for this environment
    IAM_ROLES=$(aws iam list-roles \
        --query "Roles[?starts_with(RoleName, 'foodme-$ENVIRONMENT-')].RoleName" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$IAM_ROLES" ]; then
        for role in $IAM_ROLES; do
            echo "🗑️ Cleaning up IAM role: $role"
            
            # Detach managed policies
            POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text 2>/dev/null || echo "")
            for policy in $POLICIES; do
                echo "  🔓 Detaching policy: $policy"
                aws iam detach-role-policy --role-name "$role" --policy-arn "$policy" 2>/dev/null || true
            done
            
            # Delete inline policies
            INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role" --query "PolicyNames" --output text 2>/dev/null || echo "")
            for policy in $INLINE_POLICIES; do
                echo "  🗑️ Deleting inline policy: $policy"
                aws iam delete-role-policy --role-name "$role" --policy-name "$policy" 2>/dev/null || true
            done
            
            # Remove from instance profiles and delete them
            INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name "$role" --query "InstanceProfiles[].InstanceProfileName" --output text 2>/dev/null || echo "")
            for profile in $INSTANCE_PROFILES; do
                echo "  🔓 Removing role from instance profile: $profile"
                aws iam remove-role-from-instance-profile --instance-profile-name "$profile" --role-name "$role" 2>/dev/null || true
                echo "  🗑️ Deleting instance profile: $profile"
                aws iam delete-instance-profile --instance-profile-name "$profile" 2>/dev/null || true
            done
            
            # Delete role
            echo "  🗑️ Deleting IAM role: $role"
            aws iam delete-role --role-name "$role" 2>/dev/null || echo "  ⚠️ Failed to delete role $role"
        done
        echo "✅ IAM cleanup completed"
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
                  "Name=tag:Environment,Values=$ENVIRONMENT" \
        --query "Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
    
    echo -e "\nSecurity Groups:"
    aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=foodme-$ENVIRONMENT-*" \
        --query "SecurityGroups[].[GroupId,GroupName]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
    
    echo -e "\nVPCs:"
    aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=foodme-$ENVIRONMENT-*" \
        --query "Vpcs[].[VpcId,Tags[?Key=='Name'].Value|[0]]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
    
    echo -e "\nIAM Roles:"
    aws iam list-roles \
        --query "Roles[?starts_with(RoleName, 'foodme-$ENVIRONMENT-')].[RoleName,Arn]" \
        --output table 2>/dev/null || echo "None found"
    
    echo -e "\nKey Pairs:"
    aws ec2 describe-key-pairs \
        --query "KeyPairs[?starts_with(KeyName, 'foodme-$ENVIRONMENT-')].[KeyName,KeyFingerprint]" \
        --output table \
        --region "$AWS_REGION" 2>/dev/null || echo "None found"
}

# Function to check if any FoodMe resources exist
check_resources_exist() {
    local AWS_REGION=$(aws configure get region || echo "us-west-2")
    
    # Check for EC2 instances
    local INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=tag:Application,Values=FoodMe" \
                  "Name=tag:Environment,Values=$ENVIRONMENT" \
                  "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    # Check for security groups
    local SECURITY_GROUPS=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=foodme-$ENVIRONMENT-*" \
        --query "SecurityGroups[?GroupName!='default'].GroupId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    # Check for VPCs
    local VPCS=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=foodme-$ENVIRONMENT-*" \
        --query "Vpcs[].VpcId" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "")
    
    # Check for IAM roles
    local IAM_ROLES=$(aws iam list-roles \
        --query "Roles[?starts_with(RoleName, 'foodme-$ENVIRONMENT-')].RoleName" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES" ] || [ -n "$SECURITY_GROUPS" ] || [ -n "$VPCS" ] || [ -n "$IAM_ROLES" ]; then
        return 0  # Resources exist
    else
        return 1  # No resources found
    fi
}

# Main execution
main() {
    echo "Starting cleanup process..."
    
    # Check AWS configuration
    check_aws_config
    
    # First, check if any resources actually exist
    echo "🔍 Checking for existing FoodMe resources..."
    if ! check_resources_exist; then
        echo "✅ No FoodMe resources found for environment '$ENVIRONMENT'"
        echo "Nothing to clean up!"
        return 0
    fi
    
    echo "⚠️ Found FoodMe resources that need cleanup"
    
    # Show current resources before cleanup
    echo "📊 Current resources before cleanup:"
    show_remaining_resources
    echo ""
    
    # Try Terraform cleanup first
    TERRAFORM_SUCCESS=false
    if cleanup_with_terraform; then
        echo "✅ Terraform cleanup completed"
        TERRAFORM_SUCCESS=true
    else
        echo "⚠️ Terraform cleanup failed or not applicable"
        TERRAFORM_SUCCESS=false
    fi
    
    # Check if resources still exist after Terraform cleanup
    echo "🔍 Checking if resources still exist after Terraform..."
    if check_resources_exist; then
        echo "⚠️ Resources still exist - performing manual cleanup..."
        manual_cleanup
        cleanup_iam
    elif [ "$TERRAFORM_SUCCESS" = true ]; then
        echo "✅ Terraform successfully removed all resources"
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
