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
    
    # 1. Terminate and delete EC2 instances
    echo "  🖥️  Checking for EC2 instances..."
    aws ec2 describe-instances --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[].Instances[].InstanceId' --output text | \
    while read instance_id; do
        if [ -n "$instance_id" ] && [ "$instance_id" != "None" ]; then
            echo "    Terminating instance: $instance_id"
            aws ec2 terminate-instances --region "$REGION" --instance-ids "$instance_id" || true
        fi
    done
    
    # Wait for instances to terminate
    if aws ec2 describe-instances --region "$REGION" --filters "Name=vpc-id,Values=$vpc_id" --query 'Reservations[].Instances[].InstanceId' --output text | grep -q .; then
        echo "    Waiting for instances to terminate..."
        sleep 30
    fi
    
    # 2. Delete NAT Gateways
    echo "  🌉 Cleaning up NAT Gateways..."
    aws ec2 describe-nat-gateways --region "$REGION" \
        --filter "Name=vpc-id,Values=$vpc_id" \
        --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text | \
    while read nat_id; do
        if [ -n "$nat_id" ] && [ "$nat_id" != "None" ]; then
            echo "    Deleting NAT Gateway: $nat_id"
            aws ec2 delete-nat-gateway --region "$REGION" --nat-gateway-id "$nat_id" || true
        fi
    done
    
    # 3. Delete VPC Endpoints
    echo "  🔗 Cleaning up VPC Endpoints..."
    aws ec2 describe-vpc-endpoints --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'VpcEndpoints[].VpcEndpointId' --output text | \
    while read endpoint_id; do
        if [ -n "$endpoint_id" ] && [ "$endpoint_id" != "None" ]; then
            echo "    Deleting VPC Endpoint: $endpoint_id"
            aws ec2 delete-vpc-endpoint --region "$REGION" --vpc-endpoint-id "$endpoint_id" || true
        fi
    done
    
    # 4. Delete Load Balancers
    echo "  ⚖️  Cleaning up Load Balancers..."
    aws elbv2 describe-load-balancers --region "$REGION" \
        --query 'LoadBalancers[?VpcId==`'$vpc_id'`].LoadBalancerArn' --output text | \
    while read lb_arn; do
        if [ -n "$lb_arn" ] && [ "$lb_arn" != "None" ]; then
            echo "    Deleting Load Balancer: $lb_arn"
            aws elbv2 delete-load-balancer --region "$REGION" --load-balancer-arn "$lb_arn" || true
        fi
    done
    
    # Also check classic load balancers
    aws elb describe-load-balancers --region "$REGION" \
        --query 'LoadBalancerDescriptions[?VPCId==`'$vpc_id'`].LoadBalancerName' --output text | \
    while read lb_name; do
        if [ -n "$lb_name" ] && [ "$lb_name" != "None" ]; then
            echo "    Deleting Classic Load Balancer: $lb_name"
            aws elb delete-load-balancer --region "$REGION" --load-balancer-name "$lb_name" || true
        fi
    done
    
    # 5. Delete RDS instances and subnets
    echo "  🗄️  Cleaning up RDS resources..."
    aws rds describe-db-instances --region "$REGION" \
        --query 'DBInstances[?DBSubnetGroup.VpcId==`'$vpc_id'`].DBInstanceIdentifier' --output text | \
    while read db_id; do
        if [ -n "$db_id" ] && [ "$db_id" != "None" ]; then
            echo "    Deleting RDS instance: $db_id"
            aws rds delete-db-instance --region "$REGION" --db-instance-identifier "$db_id" --skip-final-snapshot || true
        fi
    done
    
    # 6. Delete Network Interfaces
    echo "  🔌 Cleaning up Network Interfaces..."
    aws ec2 describe-network-interfaces --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'NetworkInterfaces[].NetworkInterfaceId' --output text | \
    while read eni_id; do
        if [ -n "$eni_id" ] && [ "$eni_id" != "None" ]; then
            echo "    Detaching and deleting ENI: $eni_id"
            # Try to detach first
            aws ec2 detach-network-interface --region "$REGION" --network-interface-id "$eni_id" --force 2>/dev/null || true
            sleep 5
            # Then delete
            aws ec2 delete-network-interface --region "$REGION" --network-interface-id "$eni_id" 2>/dev/null || true
        fi
    done
    
    # 7. Delete Security Group rules first, then groups
    echo "  🔒 Cleaning up Security Groups..."
    aws ec2 describe-security-groups --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | \
    while read sg_id; do
        if [ -n "$sg_id" ] && [ "$sg_id" != "None" ]; then
            echo "    Removing rules from security group: $sg_id"
            # Remove all ingress rules
            aws ec2 describe-security-groups --region "$REGION" --group-ids "$sg_id" \
                --query 'SecurityGroups[0].IpPermissions' --output json | \
            jq -c '.[]?' 2>/dev/null | \
            while read rule; do
                if [ -n "$rule" ] && [ "$rule" != "null" ]; then
                    aws ec2 revoke-security-group-ingress --region "$REGION" --group-id "$sg_id" --ip-permissions "$rule" 2>/dev/null || true
                fi
            done
            # Remove all egress rules
            aws ec2 describe-security-groups --region "$REGION" --group-ids "$sg_id" \
                --query 'SecurityGroups[0].IpPermissionsEgress' --output json | \
            jq -c '.[]?' 2>/dev/null | \
            while read rule; do
                if [ -n "$rule" ] && [ "$rule" != "null" ]; then
                    aws ec2 revoke-security-group-egress --region "$REGION" --group-id "$sg_id" --ip-permissions "$rule" 2>/dev/null || true
                fi
            done
        fi
    done
    
    # Wait a bit for rules to be removed
    sleep 10
    
    # Now delete the security groups
    aws ec2 describe-security-groups --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | \
    while read sg_id; do
        if [ -n "$sg_id" ] && [ "$sg_id" != "None" ]; then
            echo "    Deleting security group: $sg_id"
            aws ec2 delete-security-group --region "$REGION" --group-id "$sg_id" 2>/dev/null || true
        fi
    done
    
    # 8. Delete Network ACLs (except default)
    echo "  🚧 Cleaning up Network ACLs..."
    aws ec2 describe-network-acls --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'NetworkAcls[?IsDefault!=`true`].NetworkAclId' --output text | \
    while read acl_id; do
        if [ -n "$acl_id" ] && [ "$acl_id" != "None" ]; then
            echo "    Deleting Network ACL: $acl_id"
            aws ec2 delete-network-acl --region "$REGION" --network-acl-id "$acl_id" 2>/dev/null || true
        fi
    done
    
    # 9. Delete route tables (except main)
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
    
    # 10. Delete Internet Gateway attachments and gateways
    echo "  🌐 Cleaning up Internet Gateways..."
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
    
    # 11. Delete subnets
    echo "  🏘️  Cleaning up Subnets..."
    aws ec2 describe-subnets --region "$REGION" \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[].SubnetId' --output text | \
    while read subnet_id; do
        if [ -n "$subnet_id" ] && [ "$subnet_id" != "None" ]; then
            echo "    Deleting subnet: $subnet_id"
            aws ec2 delete-subnet --region "$REGION" --subnet-id "$subnet_id" 2>/dev/null || true
        fi
    done
    
    # 12. Wait a bit for all resources to be cleaned up
    echo "    Waiting for resources to be fully deleted..."
    sleep 15
    
    # 13. Finally, delete the VPC
    echo "  🏗️  Deleting VPC: $vpc_id"
    for attempt in {1..3}; do
        if aws ec2 delete-vpc --region "$REGION" --vpc-id "$vpc_id" 2>/dev/null; then
            echo "  ✅ VPC deleted successfully: $vpc_id"
            return 0
        else
            echo "  ⏳ Attempt $attempt failed, waiting and retrying..."
            sleep 10
        fi
    done
    
    echo "  ❌ Failed to delete VPC: $vpc_id after 3 attempts"
    echo "  💡 Remaining dependencies:"
    aws ec2 describe-vpc-attribute --region "$REGION" --vpc-id "$vpc_id" --attribute enableDnsSupport 2>&1 || echo "    VPC may have additional dependencies"
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
