#!/bin/bash

# Script to clean up unused AWS VPCs and related resources
# This helps resolve the "VpcLimitExceeded" error

set -e

REGION="us-west-2"
VPC_NAME_PATTERN="foodme-staging-vpc"

echo "🧹 AWS VPC Cleanup Script"
echo "========================"
echo "Region: $REGION"
echo "Looking for VPCs with pattern: $VPC_NAME_PATTERN"
echo ""

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "❌ Error: AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    echo "✅ AWS CLI configured"
}

# Function to list VPCs
list_vpcs() {
    echo "📋 Current VPCs in $REGION:"
    aws ec2 describe-vpcs --region "$REGION" \
        --query 'Vpcs[*].{VpcId:VpcId,State:State,CidrBlock:CidrBlock,Name:Tags[?Key==`Name`].Value|[0]}' \
        --output table
    echo ""
}

# Function to check if VPC is default
is_default_vpc() {
    local vpc_id=$1
    aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$vpc_id" \
        --query 'Vpcs[0].IsDefault' --output text
}

# Function to get VPC name
get_vpc_name() {
    local vpc_id=$1
    aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$vpc_id" \
        --query 'Vpcs[0].Tags[?Key==`Name`].Value|[0]' --output text 2>/dev/null || echo "None"
}

# Function to check if VPC has running instances
has_running_instances() {
    local vpc_id=$1
    local instance_count=$(aws ec2 describe-instances --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'length(Reservations[].Instances[])' --output text)
    [ "$instance_count" != "0" ]
}

# Function to delete VPC and its dependencies
delete_vpc_with_dependencies() {
    local vpc_id=$1
    local vpc_name=$(get_vpc_name "$vpc_id")
    
    echo "🗑️  Deleting VPC: $vpc_id ($vpc_name)"
    
    # Delete Internet Gateway attachments and gateways
    echo "  🔌 Cleaning up Internet Gateways..."
    aws ec2 describe-internet-gateways --region "$REGION" \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" \
        --query 'InternetGateways[].InternetGatewayId' --output text | \
    while read igw_id; do
        if [ -n "$igw_id" ] && [ "$igw_id" != "None" ]; then
            echo "    Detaching IGW: $igw_id"
            aws ec2 detach-internet-gateway --region "$REGION" --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" 2>/dev/null || true
            echo "    Deleting IGW: $igw_id"
            aws ec2 delete-internet-gateway --region "$REGION" --internet-gateway-id "$igw_id" 2>/dev/null || true
        fi
    done
    
    # Delete subnets
    echo "  🌐 Cleaning up Subnets..."
    aws ec2 describe-subnets --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[].SubnetId' --output text | \
    while read subnet_id; do
        if [ -n "$subnet_id" ] && [ "$subnet_id" != "None" ]; then
            echo "    Deleting subnet: $subnet_id"
            aws ec2 delete-subnet --region "$REGION" --subnet-id "$subnet_id" 2>/dev/null || true
        fi
    done
    
    # Delete route tables (except main)
    echo "  🛣️  Cleaning up Route Tables..."
    aws ec2 describe-route-tables --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | \
    while read rt_id; do
        if [ -n "$rt_id" ] && [ "$rt_id" != "None" ]; then
            echo "    Deleting route table: $rt_id"
            aws ec2 delete-route-table --region "$REGION" --route-table-id "$rt_id" 2>/dev/null || true
        fi
    done
    
    # Delete security groups (except default)
    echo "  🔒 Cleaning up Security Groups..."
    aws ec2 describe-security-groups --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | \
    while read sg_id; do
        if [ -n "$sg_id" ] && [ "$sg_id" != "None" ]; then
            echo "    Deleting security group: $sg_id"
            aws ec2 delete-security-group --region "$REGION" --group-id "$sg_id" 2>/dev/null || true
        fi
    done
    
    # Finally, delete the VPC
    echo "  🏗️  Deleting VPC: $vpc_id"
    if aws ec2 delete-vpc --region "$REGION" --vpc-id "$vpc_id" 2>/dev/null; then
        echo "  ✅ VPC deleted successfully: $vpc_id"
    else
        echo "  ❌ Failed to delete VPC: $vpc_id (may have dependencies)"
    fi
    echo ""
}

# Function to clean up FoodMe VPCs
cleanup_foodme_vpcs() {
    echo "🔍 Finding FoodMe VPCs to clean up..."
    
    # Get VPCs with foodme name pattern
    local vpc_ids=$(aws ec2 describe-vpcs --region "$REGION" \
        --filters "Name=tag:Name,Values=*foodme*" \
        --query 'Vpcs[].VpcId' --output text)
    
    if [ -z "$vpc_ids" ] || [ "$vpc_ids" = "None" ]; then
        echo "ℹ️  No FoodMe VPCs found to clean up"
        return
    fi
    
    for vpc_id in $vpc_ids; do
        local vpc_name=$(get_vpc_name "$vpc_id")
        local is_default=$(is_default_vpc "$vpc_id")
        
        # Skip default VPC
        if [ "$is_default" = "True" ]; then
            echo "⚠️  Skipping default VPC: $vpc_id"
            continue
        fi
        
        # Check for running instances
        if has_running_instances "$vpc_id"; then
            echo "⚠️  Skipping VPC with running instances: $vpc_id ($vpc_name)"
            continue
        fi
        
        echo "🎯 Found VPC to clean up: $vpc_id ($vpc_name)"
        read -p "Delete this VPC? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_vpc_with_dependencies "$vpc_id"
        else
            echo "  ⏭️  Skipped: $vpc_id"
        fi
    done
}

# Main execution
main() {
    check_aws_cli
    echo ""
    
    list_vpcs
    
    echo "🚨 WARNING: This script will delete VPCs and ALL their associated resources!"
    echo "Make sure you don't have any important resources in these VPCs."
    echo ""
    
    read -p "Continue with VPC cleanup? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_foodme_vpcs
        echo ""
        echo "🔄 Updated VPC list:"
        list_vpcs
        echo "🎉 Cleanup completed!"
    else
        echo "❌ Cleanup cancelled."
    fi
    
    echo ""
    echo "💡 Alternative solutions:"
    echo "   1. Use existing VPC instead of creating new ones"
    echo "   2. Request VPC limit increase from AWS Support"
    echo "   3. Use the default VPC for testing"
}

# Run main function
main "$@"
