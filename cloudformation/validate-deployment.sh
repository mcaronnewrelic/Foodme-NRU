#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
ENVIRONMENT="staging"
AWS_REGION=""
AWS_PROFILE="Team-Account-Standard-365309403645"

# Function to show usage
usage() {
    echo "Usage: $0 -e ENVIRONMENT [-r AWS_REGION] [-p AWS_PROFILE]"
    echo ""
    echo "Options:"
    echo "  -e ENVIRONMENT    Environment name (staging/production) [required]"
    echo "  -r AWS_REGION     AWS region (defaults to current AWS CLI region)"
    echo "  -p AWS_PROFILE    AWS profile (defaults to Team-Account-Standard-365309403645)"
    echo "  -h                Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -e staging"
    exit 1
}

# Parse command line arguments
while getopts "e:r:p:h" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        r)
            AWS_REGION="$OPTARG"
            ;;
        p)
            AWS_PROFILE="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Environment is required"
    usage
fi

# Get AWS region if not provided
if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(AWS_PROFILE="$AWS_PROFILE" aws configure get region)
    if [ -z "$AWS_REGION" ]; then
        echo "❌ AWS region not configured. Please set it with -r option or configure AWS CLI"
        exit 1
    fi
fi

STACK_NAME="foodme-${ENVIRONMENT}"

echo "🔍 Validating FoodMe Deployment"
echo "   Environment: $ENVIRONMENT"
echo "   AWS Region: $AWS_REGION"
echo "   AWS Profile: $AWS_PROFILE"
echo ""

# Function to get stack output
get_stack_output() {
    local output_key="$1"
    AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text 2>/dev/null || echo ""
}

# Check CloudFormation stack
echo "📋 Checking CloudFormation stack..."
STACK_STATUS=$(AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$STACK_STATUS" = "NOT_FOUND" ]; then
    echo "❌ CloudFormation stack '$STACK_NAME' not found"
    exit 1
elif [ "$STACK_STATUS" != "CREATE_COMPLETE" ] && [ "$STACK_STATUS" != "UPDATE_COMPLETE" ]; then
    echo "⚠️  CloudFormation stack status: $STACK_STATUS"
    echo "   The stack may not be fully deployed"
else
    echo "✅ CloudFormation stack status: $STACK_STATUS"
fi

# Get infrastructure details
INSTANCE_ID=$(get_stack_output "EC2InstanceId")
ALB_DNS=$(get_stack_output "LoadBalancerDNS")
PUBLIC_IP=$(get_stack_output "PublicIpAddress")

if [ -z "$INSTANCE_ID" ]; then
    echo "❌ Could not retrieve EC2 instance ID from stack"
    exit 1
fi

echo "   Instance ID: $INSTANCE_ID"
[ -n "$ALB_DNS" ] && echo "   ALB DNS: $ALB_DNS"
[ -n "$PUBLIC_IP" ] && echo "   Public IP: $PUBLIC_IP"

# Check EC2 instance status
echo ""
echo "🖥️  Checking EC2 instance..."
INSTANCE_STATE=$(AWS_PROFILE="$AWS_PROFILE" aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

if [ "$INSTANCE_STATE" = "running" ]; then
    echo "✅ EC2 instance is running"
else
    echo "❌ EC2 instance state: $INSTANCE_STATE"
    exit 1
fi

# Check SSM connectivity
echo ""
echo "🔐 Checking SSM connectivity..."
SSM_STATUS=$(AWS_PROFILE="$AWS_PROFILE" aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$SSM_STATUS" = "Online" ]; then
    echo "✅ SSM agent is online"
elif [ "$SSM_STATUS" = "NOT_FOUND" ]; then
    echo "⚠️  SSM agent not found - may take a few minutes after instance startup"
else
    echo "⚠️  SSM agent status: $SSM_STATUS"
fi

# Determine application URL
if [ -n "$ALB_DNS" ]; then
    APP_URL="http://$ALB_DNS"
    API_URL="http://$ALB_DNS/api"
elif [ -n "$PUBLIC_IP" ]; then
    APP_URL="http://$PUBLIC_IP"
    API_URL="http://$PUBLIC_IP:3000"
else
    echo "❌ Could not determine application URL"
    exit 1
fi

# Test application endpoints
echo ""
echo "🌐 Testing application endpoints..."

# Test main application
echo "   Testing web application..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$APP_URL" || echo "000")
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ] || [ "$HTTP_CODE" -eq 302 ]; then
    echo "✅ Web application responding (HTTP $HTTP_CODE)"
else
    echo "❌ Web application not responding (HTTP $HTTP_CODE)"
fi

# Test API
echo "   Testing API..."
API_RESPONSE=$(curl -s --connect-timeout 10 "$API_URL/restaurant" || echo "ERROR")
if [[ "$API_RESPONSE" == *"\"name\":"* ]] && [[ "$API_RESPONSE" == *"\"description\":"* ]]; then
    echo "✅ API responding with restaurant data"
else
    echo "❌ API not responding correctly"
    echo "     Response: ${API_RESPONSE:0:100}..."
fi

# Check ALB target health (if ALB exists)
if [ -n "$ALB_DNS" ]; then
    echo ""
    echo "⚖️  Checking ALB target health..."
    
    # Get target group ARNs from stack
    TG_WEB=$(AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stack-resources \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'StackResources[?LogicalResourceId==`ApplicationTargetGroup`].PhysicalResourceId' \
        --output text 2>/dev/null || echo "")
    
    TG_API=$(AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stack-resources \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'StackResources[?LogicalResourceId==`APITargetGroup`].PhysicalResourceId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$TG_WEB" ]; then
        WEB_HEALTH=$(AWS_PROFILE="$AWS_PROFILE" aws elbv2 describe-target-health \
            --target-group-arn "$TG_WEB" \
            --region "$AWS_REGION" \
            --query 'TargetHealthDescriptions[0].TargetHealth.State' \
            --output text 2>/dev/null || echo "unknown")
        echo "   Web target group health: $WEB_HEALTH"
    fi
    
    if [ -n "$TG_API" ]; then
        API_HEALTH=$(AWS_PROFILE="$AWS_PROFILE" aws elbv2 describe-target-health \
            --target-group-arn "$TG_API" \
            --region "$AWS_REGION" \
            --query 'TargetHealthDescriptions[0].TargetHealth.State' \
            --output text 2>/dev/null || echo "unknown")
        echo "   API target group health: $API_HEALTH"
    fi
fi

# Summary
echo ""
echo "📊 Validation Summary:"
echo "   Stack Status: $STACK_STATUS"
echo "   Instance State: $INSTANCE_STATE"
echo "   SSM Status: $SSM_STATUS"
echo "   Web App: $APP_URL"
echo "   API: $API_URL"

echo ""
echo "🚀 Ready for code deployment!"
echo ""
echo "To deploy code changes:"
echo "   ./deploy-code.sh -e $ENVIRONMENT                # Deploy both frontend and backend"
echo "   ./deploy-code.sh -e $ENVIRONMENT --frontend-only # Deploy only frontend"
echo "   ./deploy-code.sh -e $ENVIRONMENT --backend-only  # Deploy only backend"