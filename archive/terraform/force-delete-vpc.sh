#!/bin/bash

# Force delete a specific VPC and handle dependencies more aggressively
# Usage: ./force-delete-vpc.sh vpc-0eb9984455932d354

set -e

REGION="us-west-2"
VPC_ID="${1:-vpc-0eb9984455932d354}"

if [ -z "$VPC_ID" ]; then
    echo "❌ Usage: $0 <vpc-id>"
    echo "Example: $0 vpc-0eb9984455932d354"
    exit 1
fi

echo "🗑️  Force deleting VPC: $VPC_ID"
echo "Region: $REGION"
echo "========================"

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "❌ Error: AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    echo "✅ AWS CLI configured"
}

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local check_command=$2
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $resource_type to be deleted..."
    while [ $attempt -le $max_attempts ]; do
        if ! eval "$check_command" > /dev/null 2>&1; then
            echo "✅ $resource_type deleted successfully"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - still waiting..."
        sleep 10
        ((attempt++))
    done
    echo "⚠️  Timeout waiting for $resource_type deletion"
    return 1
}

# Function to delete with retries
delete_with_retry() {
    local description=$1
    local command=$2
    local max_attempts=3
    
    for attempt in $(seq 1 $max_attempts); do
        echo "  🔄 $description (attempt $attempt/$max_attempts)"
        if eval "$command" 2>/dev/null; then
            echo "  ✅ $description succeeded"
            return 0
        else
            if [ $attempt -eq $max_attempts ]; then
                echo "  ❌ $description failed after $max_attempts attempts"
                return 1
            fi
            sleep 5
        fi
    done
}

# Check AWS CLI
check_aws_cli

# Verify VPC exists
if ! aws ec2 describe-vpcs --region "$REGION" --vpc-ids "$VPC_ID" > /dev/null 2>&1; then
    echo "❌ VPC $VPC_ID not found in region $REGION"
    exit 1
fi

echo "✅ VPC found, starting deletion process..."

# 1. Terminate ALL EC2 instances
echo "🖥️  Step 1: Terminating EC2 instances..."
INSTANCES=$(aws ec2 describe-instances --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --query 'Reservations[].Instances[].InstanceId' --output text)

if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
    for instance_id in $INSTANCES; do
        echo "  Terminating instance: $instance_id"
        aws ec2 terminate-instances --region "$REGION" --instance-ids "$instance_id" || true
    done
    
    # Wait for all instances to terminate
    for instance_id in $INSTANCES; do
        echo "  Waiting for instance $instance_id to terminate..."
        aws ec2 wait instance-terminated --region "$REGION" --instance-ids "$instance_id" || true
    done
else
    echo "  No instances found"
fi

# 2. Delete NAT Gateways
echo "🌉 Step 2: Deleting NAT Gateways..."
NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --region "$REGION" \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query 'NatGateways[].NatGatewayId' --output text)

if [ -n "$NAT_GATEWAYS" ] && [ "$NAT_GATEWAYS" != "None" ]; then
    for nat_id in $NAT_GATEWAYS; do
        delete_with_retry "Delete NAT Gateway $nat_id" \
            "aws ec2 delete-nat-gateway --region '$REGION' --nat-gateway-id '$nat_id'"
    done
    
    # Wait for NAT Gateways to be deleted
    for nat_id in $NAT_GATEWAYS; do
        wait_for_deletion "NAT Gateway $nat_id" \
            "aws ec2 describe-nat-gateways --region '$REGION' --nat-gateway-ids '$nat_id' --query 'NatGateways[?State!=\`deleted\`]' --output text | grep -q ."
    done
else
    echo "  No NAT Gateways found"
fi

# 3. Delete Network Interfaces (except primary)
echo "🔌 Step 3: Deleting Network Interfaces..."
ENIS=$(aws ec2 describe-network-interfaces --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkInterfaces[?Status!=`in-use`].NetworkInterfaceId' --output text)

if [ -n "$ENIS" ] && [ "$ENIS" != "None" ]; then
    for eni_id in $ENIS; do
        # Try to detach first
        aws ec2 detach-network-interface --region "$REGION" --network-interface-id "$eni_id" --force 2>/dev/null || true
        sleep 5
        delete_with_retry "Delete ENI $eni_id" \
            "aws ec2 delete-network-interface --region '$REGION' --network-interface-id '$eni_id'"
    done
else
    echo "  No detachable Network Interfaces found"
fi

# 4. Delete Security Group rules and groups
echo "🔒 Step 4: Deleting Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)

if [ -n "$SECURITY_GROUPS" ] && [ "$SECURITY_GROUPS" != "None" ]; then
    # First remove all rules
    for sg_id in $SECURITY_GROUPS; do
        echo "  Removing rules from security group: $sg_id"
        # Remove ingress rules
        aws ec2 describe-security-groups --region "$REGION" --group-ids "$sg_id" \
            --query 'SecurityGroups[0].IpPermissions[]' --output json 2>/dev/null | \
        jq -c '.[]?' 2>/dev/null | \
        while read -r rule; do
            if [ -n "$rule" ] && [ "$rule" != "null" ]; then
                aws ec2 revoke-security-group-ingress --region "$REGION" --group-id "$sg_id" --ip-permissions "$rule" 2>/dev/null || true
            fi
        done
        
        # Remove egress rules
        aws ec2 describe-security-groups --region "$REGION" --group-ids "$sg_id" \
            --query 'SecurityGroups[0].IpPermissionsEgress[]' --output json 2>/dev/null | \
        jq -c '.[]?' 2>/dev/null | \
        while read -r rule; do
            if [ -n "$rule" ] && [ "$rule" != "null" ]; then
                aws ec2 revoke-security-group-egress --region "$REGION" --group-id "$sg_id" --ip-permissions "$rule" 2>/dev/null || true
            fi
        done
    done
    
    sleep 10
    
    # Then delete the security groups
    for sg_id in $SECURITY_GROUPS; do
        delete_with_retry "Delete Security Group $sg_id" \
            "aws ec2 delete-security-group --region '$REGION' --group-id '$sg_id'"
    done
else
    echo "  No custom Security Groups found"
fi

# 5. Delete Route Tables (non-main)
echo "🛣️  Step 5: Deleting Route Tables..."
ROUTE_TABLES=$(aws ec2 describe-route-tables --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text)

if [ -n "$ROUTE_TABLES" ] && [ "$ROUTE_TABLES" != "None" ]; then
    for rt_id in $ROUTE_TABLES; do
        # First disassociate from subnets
        echo "  Disassociating route table: $rt_id"
        aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$rt_id" \
            --query 'RouteTables[0].Associations[?Main!=`true`].RouteTableAssociationId' --output text | \
        while read -r assoc_id; do
            if [ -n "$assoc_id" ] && [ "$assoc_id" != "None" ]; then
                echo "    Disassociating: $assoc_id"
                aws ec2 disassociate-route-table --region "$REGION" --association-id "$assoc_id" 2>/dev/null || true
            fi
        done
        
        # Then remove all routes except local
        echo "  Removing routes from route table: $rt_id"
        aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$rt_id" \
            --query 'RouteTables[0].Routes[?GatewayId!=`local`]' --output json | \
        jq -c '.[]?' 2>/dev/null | \
        while read -r route; do
            if [ -n "$route" ] && [ "$route" != "null" ]; then
                DEST_CIDR=$(echo "$route" | jq -r '.DestinationCidrBlock // empty')
                if [ -n "$DEST_CIDR" ]; then
                    aws ec2 delete-route --region "$REGION" --route-table-id "$rt_id" --destination-cidr-block "$DEST_CIDR" 2>/dev/null || true
                fi
            fi
        done
        
        delete_with_retry "Delete Route Table $rt_id" \
            "aws ec2 delete-route-table --region '$REGION' --route-table-id '$rt_id'"
    done
else
    echo "  No custom Route Tables found"
fi

# 6. Detach and Delete Internet Gateways
echo "🌐 Step 6: Deleting Internet Gateways..."
IGWS=$(aws ec2 describe-internet-gateways --region "$REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[].InternetGatewayId' --output text)

if [ -n "$IGWS" ] && [ "$IGWS" != "None" ]; then
    for igw_id in $IGWS; do
        delete_with_retry "Detach IGW $igw_id" \
            "aws ec2 detach-internet-gateway --region '$REGION' --internet-gateway-id '$igw_id' --vpc-id '$VPC_ID'"
        delete_with_retry "Delete IGW $igw_id" \
            "aws ec2 delete-internet-gateway --region '$REGION' --internet-gateway-id '$igw_id'"
    done
else
    echo "  No Internet Gateways found"
fi

# 7. Delete Subnets
echo "🏘️  Step 7: Deleting Subnets..."
SUBNETS=$(aws ec2 describe-subnets --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].SubnetId' --output text)

if [ -n "$SUBNETS" ] && [ "$SUBNETS" != "None" ]; then
    for subnet_id in $SUBNETS; do
        delete_with_retry "Delete Subnet $subnet_id" \
            "aws ec2 delete-subnet --region '$REGION' --subnet-id '$subnet_id'"
    done
else
    echo "  No Subnets found"
fi

# 8. Delete Network ACLs (non-default)
echo "🚧 Step 8: Deleting Network ACLs..."
ACLS=$(aws ec2 describe-network-acls --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkAcls[?IsDefault!=`true`].NetworkAclId' --output text)

if [ -n "$ACLS" ] && [ "$ACLS" != "None" ]; then
    for acl_id in $ACLS; do
        delete_with_retry "Delete Network ACL $acl_id" \
            "aws ec2 delete-network-acl --region '$REGION' --network-acl-id '$acl_id'"
    done
else
    echo "  No custom Network ACLs found"
fi

# 9. Wait for everything to be cleaned up
echo "⏳ Step 9: Waiting for all resources to be fully deleted..."
sleep 30

# 10. Finally delete the VPC
echo "🏗️  Step 10: Deleting VPC..."
for attempt in {1..5}; do
    echo "  Attempt $attempt/5 to delete VPC $VPC_ID"
    if aws ec2 delete-vpc --region "$REGION" --vpc-id "$VPC_ID" 2>/dev/null; then
        echo "🎉 VPC $VPC_ID deleted successfully!"
        exit 0
    else
        echo "  ❌ Attempt $attempt failed"
        if [ $attempt -lt 5 ]; then
            echo "  Checking for remaining dependencies..."
            
            # Show any remaining resources
            echo "  📋 Remaining resources in VPC:"
            aws ec2 describe-subnets --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].{SubnetId:SubnetId,State:State}' --output table 2>/dev/null || echo "    No subnets"
            aws ec2 describe-route-tables --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[].{RouteTableId:RouteTableId,Main:Associations[0].Main}' --output table 2>/dev/null || echo "    No route tables"
            aws ec2 describe-network-interfaces --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[].{NetworkInterfaceId:NetworkInterfaceId,Status:Status}' --output table 2>/dev/null || echo "    No network interfaces"
            
            echo "  ⏳ Waiting 30 seconds before retry..."
            sleep 30
        fi
    fi
done

echo "❌ Failed to delete VPC $VPC_ID after 5 attempts"
echo "💡 You may need to manually check for remaining dependencies in the AWS Console"
exit 1
