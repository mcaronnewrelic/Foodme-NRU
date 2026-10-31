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
    echo "This script validates PostgreSQL and application monitoring setup."
    echo ""
    echo "Examples:"
    echo "  $0 -e staging"
    echo "  $0 -e production -r us-west-2"
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

echo "🔍 FoodMe Application Monitoring Validation"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "AWS Region: $AWS_REGION"
echo "AWS Profile: $AWS_PROFILE"
echo "Stack Name: $STACK_NAME"
echo "Timestamp: $(date)"
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

# Function to run quick command on EC2
run_command() {
    local command="$1"
    local description="$2"
    
    # Check SSM connectivity first
    if ! AWS_PROFILE="$AWS_PROFILE" aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query 'InstanceInformationList[0].PingStatus' \
        --output text 2>/dev/null | grep -q "Online"; then
        echo "SSM_OFFLINE"
        return 1
    fi
    
    local command_id=$(AWS_PROFILE="$AWS_PROFILE" aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$command\"]" \
        --timeout-seconds 30 \
        --region "$AWS_REGION" \
        --query 'Command.CommandId' \
        --output text 2>/dev/null) || return 1
    
    sleep 5  # Increased wait time
    local result=$(AWS_PROFILE="$AWS_PROFILE" aws ssm get-command-invocation \
        --command-id "$command_id" \
        --instance-id "$INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query 'StandardOutputContent' \
        --output text 2>/dev/null || echo "ERROR")
    
    # Clean up result
    echo "$result" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Counters for summary
PASSED=0
FAILED=0
WARNINGS=0

track_result() {
    case $1 in
        "PASS") PASSED=$((PASSED + 1)) ;;
        "FAIL") FAILED=$((FAILED + 1)) ;;
        "WARN") WARNINGS=$((WARNINGS + 1)) ;;
    esac
}

# Check CloudFormation stack
echo "📋 INFRASTRUCTURE STATUS"
echo "------------------------"
echo -n "CloudFormation stack: "
if AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &>/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Stack '$STACK_NAME' not found"
    track_result "FAIL"
    exit 1
fi

# Get instance information
INSTANCE_ID=$(get_stack_output "EC2InstanceId")
ALB_DNS=$(get_stack_output "LoadBalancerDNS")

echo -n "EC2 instance: "
if [ -n "$INSTANCE_ID" ]; then
    echo "✅ PASS ($INSTANCE_ID)"
    track_result "PASS"
else
    echo "❌ FAIL - Instance ID not found"
    track_result "FAIL"
    exit 1
fi

echo -n "Instance running: "
INSTANCE_STATE=$(AWS_PROFILE="$AWS_PROFILE" aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null || echo "unknown")

if [ "$INSTANCE_STATE" = "running" ]; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Instance state: $INSTANCE_STATE"
    track_result "FAIL"
    exit 1
fi

echo ""
echo "🌐 APPLICATION STATUS"
echo "--------------------"

# Test web application
echo -n "Web application: "
if [ -n "$ALB_DNS" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$ALB_DNS" || echo "000")
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "✅ PASS (HTTP $HTTP_CODE)"
        track_result "PASS"
    else
        echo "❌ FAIL (HTTP $HTTP_CODE)"
        track_result "FAIL"
    fi
else
    echo "❌ FAIL - No ALB DNS found"
    track_result "FAIL"
fi

# Test API
echo -n "API endpoint: "
if [ -n "$ALB_DNS" ]; then
    API_RESPONSE=$(curl -s --connect-timeout 5 "http://$ALB_DNS/api/restaurant" || echo "ERROR")
    if [[ "$API_RESPONSE" == *"\"name\":"* ]]; then
        echo "✅ PASS (Restaurant data available)"
        track_result "PASS"
    else
        echo "❌ FAIL (No restaurant data)"
        track_result "FAIL"
    fi
else
    echo "❌ FAIL - No ALB DNS found"
    track_result "FAIL"
fi

echo ""
echo "🐘 POSTGRESQL STATUS"
echo "-------------------"

# PostgreSQL service
echo -n "PostgreSQL service: "
RESULT=$(run_command "systemctl is-active postgresql" "PostgreSQL status")
if [[ "$RESULT" == "active" ]]; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL ($RESULT)"
    track_result "FAIL"
fi

# Database accessibility
echo -n "Database accessible: "
RESULT=$(run_command "sudo -u postgres psql -d foodme -c '\\q' 2>/dev/null && echo OK" "Database access")
if [[ "$RESULT" == *"OK"* ]]; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL"
    track_result "FAIL"
fi

# Restaurant data
echo -n "Restaurant data: "
RESULT=$(run_command "sudo -u postgres psql -d foodme -tAc 'SELECT COUNT(*) FROM restaurants'" "Restaurant count")
if [[ "$RESULT" =~ ^[0-9]+$ ]] && [[ "$RESULT" -gt 0 ]]; then
    echo "✅ PASS ($RESULT restaurants)"
    track_result "PASS"
else
    echo "❌ FAIL (No data found)"
    track_result "FAIL"
fi

echo ""
echo "📊 MONITORING STATUS"
echo "-------------------"

# New Relic Infrastructure
echo -n "New Relic Infrastructure: "
RESULT=$(run_command "systemctl is-active newrelic-infra" "New Relic status")
if [[ "$RESULT" == "active" ]]; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "⚠️  WARN ($RESULT)"
    track_result "WARN"
fi

# PostgreSQL integration
echo -n "PostgreSQL integration: "
RESULT=$(run_command "rpm -qa | grep nri-postgresql" "PostgreSQL integration")
if [[ "$RESULT" == *"nri-postgresql"* ]]; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "⚠️  WARN (Not installed)"
    track_result "WARN"
    echo "   Install with: dnf install -y nri-postgresql"
fi

# Nginx integration  
echo -n "Nginx integration: "
RESULT=$(run_command "rpm -qa | grep nri-nginx" "Nginx integration")
if [[ "$RESULT" == *"nri-nginx"* ]]; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "⚠️  WARN (Not installed)"
    track_result "WARN"
    echo "   Install with: dnf install -y nri-nginx"
fi

echo ""
echo "📈 SUMMARY"
echo "=========="
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo "⚠️  Warnings: $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 Application is healthy and operational!"
    if [ $WARNINGS -gt 0 ]; then
        echo "💡 Consider addressing warnings to enable full monitoring capabilities."
    fi
    echo ""
    echo "🔗 Application URL: http://$ALB_DNS"
    exit 0
else
    echo "⚠️  Application has issues that need attention."
    exit 1
fi