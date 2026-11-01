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
    echo "This script validates the complete PostgreSQL monitoring setup and provides"
    echo "actionable recommendations for fixing any issues found."
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

echo "🔍 FoodMe Monitoring Validation Report"
echo "======================================"
echo "Environment: $ENVIRONMENT"
echo "AWS Region: $AWS_REGION"
echo "AWS Profile: $AWS_PROFILE"
echo "Stack Name: $STACK_NAME"
echo "Timestamp: $(date)"
echo ""
echo "This script validates PostgreSQL and Nginx monitoring setup"
echo ""

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Function to track check results
track_result() {
    local status="$1"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    case $status in
        "PASS")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        "FAIL")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        "WARN")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
    esac
}

# Function to get stack output
get_stack_output() {
    local output_key="$1"
    AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text 2>/dev/null || echo ""
}

# Function to execute commands on EC2 with better error handling
execute_on_ec2_quiet() {
    local command="$1"
    local timeout="${2:-30}"  # Reduced timeout from 60 to 30
    
    local command_id=$(AWS_PROFILE="$AWS_PROFILE" aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$command\"]" \
        --timeout-seconds "$timeout" \
        --region "$AWS_REGION" \
        --query 'Command.CommandId' \
        --output text 2>/dev/null) || return 1
    
    # Wait for command completion with shorter intervals
    local max_wait=$timeout
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        local status=$(AWS_PROFILE="$AWS_PROFILE" aws ssm get-command-invocation \
            --command-id "$command_id" \
            --instance-id "$INSTANCE_ID" \
            --region "$AWS_REGION" \
            --query 'Status' \
            --output text 2>/dev/null || echo "InProgress")
        
        case $status in
            "Success")
                AWS_PROFILE="$AWS_PROFILE" aws ssm get-command-invocation \
                    --command-id "$command_id" \
                    --instance-id "$INSTANCE_ID" \
                    --region "$AWS_REGION" \
                    --query 'StandardOutputContent' \
                    --output text 2>/dev/null
                return 0
                ;;
            "Failed"|"Cancelled"|"TimedOut")
                return 1
                ;;
            *)
                sleep 2  # Reduced from 3 to 2 seconds
                wait_time=$((wait_time + 2))
                ;;
        esac
    done
    
    return 1
}

echo "📋 INFRASTRUCTURE VALIDATION"
echo "----------------------------"

# Check if CloudFormation stack exists
echo -n "CloudFormation stack exists: "
if AWS_PROFILE="$AWS_PROFILE" aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &>/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Stack '$STACK_NAME' not found"
    track_result "FAIL"
    echo "   Fix: Deploy the CloudFormation stack first"
    exit 1
fi

# Get instance information
INSTANCE_ID=$(get_stack_output "EC2InstanceId")
echo -n "EC2 instance available: "
if [ -n "$INSTANCE_ID" ]; then
    echo "✅ PASS ($INSTANCE_ID)"
    track_result "PASS"
else
    echo "❌ FAIL - Instance ID not found in stack outputs"
    track_result "FAIL"
    exit 1
fi

# Check instance state
echo -n "EC2 instance running: "
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
    echo "   Fix: Start the EC2 instance"
    exit 1
fi

# Check SSM connectivity
echo -n "SSM connectivity: "
if AWS_PROFILE="$AWS_PROFILE" aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text 2>/dev/null | grep -q "Online"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - SSM agent not online"
    track_result "FAIL"
    echo "   Fix: Ensure SSM agent is running on EC2 instance"
fi

echo ""
echo "🌐 NGINX VALIDATION"
echo "-------------------"

# Check Nginx service
echo -n "Nginx service status: "
if execute_on_ec2_quiet "systemctl is-active nginx" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Nginx not running"
    track_result "FAIL"
    echo "   Fix: systemctl start nginx"
fi

# Check status module
echo -n "Nginx status module: "
if execute_on_ec2_quiet "nginx -V 2>&1 | grep -q 'http_stub_status_module'" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "⚠️  WARN - Status module not available"
    track_result "WARN"
    echo "   Fix: Nginx may need to be compiled with --with-http_stub_status_module"
fi

# Check status endpoint
echo -n "Nginx status endpoint: "
if execute_on_ec2_quiet "curl -s http://127.0.0.1:8080/nginx_status > /dev/null 2>&1" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Status endpoint not accessible"
    track_result "FAIL"
    echo "   Fix: Configure status server on port 8080"
fi

# Check main application
echo -n "Main application endpoint: "
if execute_on_ec2_quiet "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/ | grep -q '200'" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Main application not responding"
    track_result "FAIL"
    echo "   Fix: Check nginx configuration and backend service"
fi

echo ""
echo "📊 NEW RELIC NGINX INTEGRATION VALIDATION"
echo "-----------------------------------------"

# Check Nginx integration package
echo -n "Nginx integration installed: "
if execute_on_ec2_quiet "rpm -qa | grep -q nri-nginx" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - nri-nginx package not installed"
    track_result "FAIL"
    echo "   Fix: dnf install -y nri-nginx"
fi

# Check Nginx integration configuration
echo -n "Nginx integration config: "
if execute_on_ec2_quiet "[ -f /etc/newrelic-infra/integrations.d/nginx-config.yml ]" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Configuration file missing"
    track_result "FAIL"
    echo "   Fix: Create /etc/newrelic-infra/integrations.d/nginx-config.yml"
fi

# Check Nginx configuration syntax
echo -n "Nginx config syntax valid: "
if execute_on_ec2_quiet "python3 -c \"import yaml; yaml.safe_load(open('/etc/newrelic-infra/integrations.d/nginx-config.yml'))\"" >/dev/null 2>&1; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Invalid YAML syntax"
    track_result "FAIL"
    echo "   Fix: Validate YAML syntax in nginx configuration file"
fi

# Check log file permissions
echo -n "Nginx log permissions: "
NGINX_LOG_PERMS=$(execute_on_ec2_quiet "stat -c '%a' /var/log/nginx/access.log 2>/dev/null" || echo "")
if [ -n "$NGINX_LOG_PERMS" ] && [ "$NGINX_LOG_PERMS" -ge 644 ]; then
    echo "✅ PASS ($NGINX_LOG_PERMS)"
    track_result "PASS"
else
    echo "⚠️  WARN - Log permissions: $NGINX_LOG_PERMS"
    track_result "WARN"
    echo "   Fix: chmod 644 /var/log/nginx/*.log"
fi

echo ""
echo "🐘 POSTGRESQL VALIDATION"
echo "------------------------"

# Check PostgreSQL service
echo -n "PostgreSQL service status: "
if execute_on_ec2_quiet "systemctl is-active postgresql" 2>/dev/null | grep -q "active"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - PostgreSQL not running"
    track_result "FAIL"
    echo "   Fix: systemctl start postgresql"
fi

# Check database exists and is accessible
echo -n "FoodMe database accessible: "
if execute_on_ec2_quiet "sudo -u postgres psql -d foodme -c '\q' 2>/dev/null && echo 'OK'" 2>/dev/null | grep -q "OK"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Cannot access foodme database"
    track_result "FAIL"
    echo "   Fix: Ensure foodme database exists and is accessible"
fi

# Check if application can connect to database
echo -n "Application database connection: "
if execute_on_ec2_quiet "cd /opt/foodme/server && node -e 'const db = require(\"./database.js\"); db.testConnection().then(() => console.log(\"OK\")).catch(() => process.exit(1))' 2>/dev/null" 2>/dev/null | grep -q "OK"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Application cannot connect to database"
    track_result "FAIL"
    echo "   Fix: Check database credentials and connectivity"
fi

# Check database has data (restaurants)
echo -n "Database contains restaurant data: "
if execute_on_ec2_quiet "sudo -u postgres psql -d foodme -tAc \"SELECT COUNT(*) FROM restaurants\"" 2>/dev/null | grep -E "^[0-9]+$" | awk '$1 > 0 {print "OK"}' | grep -q "OK"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - No restaurant data found"
    track_result "FAIL"
    echo "   Fix: Import restaurant data into the database"
fi

# Check PostgreSQL logs are being generated
echo -n "PostgreSQL logging configured: "
if execute_on_ec2_quiet "sudo -u postgres psql -c \"SHOW log_destination\" 2>/dev/null" | grep -q "stderr"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "⚠️  WARN - PostgreSQL logging not configured for monitoring"
    track_result "WARN"
    echo "   Fix: Configure PostgreSQL logging for better monitoring"
fi

echo ""
echo "📊 NEW RELIC INFRASTRUCTURE VALIDATION"
echo "--------------------------------------"

# Check New Relic agent
echo -n "New Relic Infrastructure service: "
if execute_on_ec2_quiet "systemctl is-active newrelic-infra" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - New Relic Infrastructure not running"
    track_result "FAIL"
    echo "   Fix: systemctl start newrelic-infra"
fi

# Check license key configuration
echo -n "New Relic license key: "
if execute_on_ec2_quiet "grep -q '^license_key:' /etc/newrelic-infra/newrelic-infra.yml 2>/dev/null && [ \$(grep '^license_key:' /etc/newrelic-infra/newrelic-infra.yml | cut -d':' -f2 | tr -d ' ' | wc -c) -gt 10 ]"; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - License key not configured"
    track_result "FAIL"
    echo "   Fix: Configure NEW_RELIC_LICENSE_KEY in environment"
fi

# Check PostgreSQL integration package
echo -n "PostgreSQL integration installed: "
if execute_on_ec2_quiet "rpm -qa | grep -q nri-postgresql" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - nri-postgresql package not installed"
    track_result "FAIL"
    echo "   Fix: dnf install -y nri-postgresql"
fi

# Check integration configuration
echo -n "PostgreSQL integration config: "
if execute_on_ec2_quiet "[ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]" >/dev/null; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Configuration file missing"
    track_result "FAIL"
    echo "   Fix: Create /etc/newrelic-infra/integrations.d/postgresql-config.yml"
fi

# Check configuration syntax
echo -n "Configuration syntax valid: "
if execute_on_ec2_quiet "python3 -c \"import yaml; yaml.safe_load(open('/etc/newrelic-infra/integrations.d/postgresql-config.yml'))\"" >/dev/null 2>&1; then
    echo "✅ PASS"
    track_result "PASS"
else
    echo "❌ FAIL - Invalid YAML syntax"
    track_result "FAIL"
    echo "   Fix: Validate YAML syntax in configuration file"
fi

# Check file permissions
echo -n "Configuration file permissions: "
CONFIG_PERMS=$(execute_on_ec2_quiet "stat -c '%a %U:%G' /etc/newrelic-infra/integrations.d/postgresql-config.yml 2>/dev/null" || echo "")
if echo "$CONFIG_PERMS" | grep -q "640 root:newrelic-infra\|600 root:root"; then
    echo "✅ PASS ($CONFIG_PERMS)"
    track_result "PASS"
else
    echo "⚠️  WARN - Permissions: $CONFIG_PERMS"
    track_result "WARN"
    echo "   Fix: chown root:newrelic-infra config.yml && chmod 640 config.yml"
fi

echo ""
echo "🔗 CONNECTIVITY VALIDATION"
echo "--------------------------"

# Test database connection
echo -n "Database connection test: "
DB_TEST_RESULT=$(execute_on_ec2_quiet "
    if [ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]; then
        PASS=\$(grep 'PASSWORD:' /etc/newrelic-infra/integrations.d/postgresql-config.yml | awk '{print \$2}' | tr -d '\"')
        if [ -n \"\$PASS\" ]; then
            PGPASSWORD=\"\$PASS\" psql -h localhost -p 5432 -U newrelic -d foodme -c 'SELECT 1;' >/dev/null 2>&1 && echo 'SUCCESS' || echo 'FAILED'
        else
            echo 'NO_PASSWORD'
        fi
    else
        echo 'NO_CONFIG'
    fi
" 2>/dev/null)

case "$DB_TEST_RESULT" in
    "SUCCESS")
        echo "✅ PASS"
        track_result "PASS"
        ;;
    "FAILED")
        echo "❌ FAIL - Connection failed"
        track_result "FAIL"
        echo "   Fix: Check username, password, and database access"
        ;;
    "NO_PASSWORD")
        echo "❌ FAIL - No password in config"
        track_result "FAIL"
        echo "   Fix: Add PASSWORD field to configuration"
        ;;
    "NO_CONFIG")
        echo "❌ FAIL - No configuration file"
        track_result "FAIL"
        echo "   Fix: Create configuration file"
        ;;
    *)
        echo "❌ FAIL - Unknown error"
        track_result "FAIL"
        ;;
esac

# Test monitoring queries
echo -n "Monitoring queries test: "
MONITOR_TEST_RESULT=$(execute_on_ec2_quiet "
    if [ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]; then
        PASS=\$(grep 'PASSWORD:' /etc/newrelic-infra/integrations.d/postgresql-config.yml | awk '{print \$2}' | tr -d '\"')
        if [ -n \"\$PASS\" ]; then
            PGPASSWORD=\"\$PASS\" psql -h localhost -p 5432 -U newrelic -d foodme -c 'SELECT COUNT(*) FROM pg_stat_activity;' >/dev/null 2>&1 && echo 'SUCCESS' || echo 'FAILED'
        else
            echo 'NO_PASSWORD'
        fi
    else
        echo 'NO_CONFIG'
    fi
" 2>/dev/null)

case "$MONITOR_TEST_RESULT" in
    "SUCCESS")
        echo "✅ PASS"
        track_result "PASS"
        ;;
    *)
        echo "❌ FAIL"
        track_result "FAIL"
        echo "   Fix: Ensure newrelic user has monitoring permissions"
        ;;
esac

echo ""
echo "📈 VALIDATION SUMMARY"
echo "======================"
echo "Total Checks: $TOTAL_CHECKS"
echo "✅ Passed: $PASSED_CHECKS"
echo "❌ Failed: $FAILED_CHECKS"
echo "⚠️  Warnings: $WARNING_CHECKS"
echo ""

# Calculate success rate
if [ $TOTAL_CHECKS -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    echo "Success Rate: ${SUCCESS_RATE}%"
else
    SUCCESS_RATE=0
    echo "Success Rate: 0%"
fi

echo ""
echo "💡 RECOMMENDATIONS"
echo "==================="

if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    echo "🎉 All checks passed! Your PostgreSQL and Nginx monitoring are properly configured."
    echo ""
    echo "Next steps:"
    echo "1. Monitor data flow in New Relic One → Infrastructure → Integrations"
    echo "2. Set up alerts for database and web server metrics"
    echo "3. Create custom dashboards for PostgreSQL and Nginx metrics"
elif [ $FAILED_CHECKS -gt 0 ]; then
    echo "🔧 Fix required - $FAILED_CHECKS failed checks detected."
    echo ""
    echo "Quick fix commands:"
    echo "   PostgreSQL: ./diagnose-postgresql-monitoring.sh -e $ENVIRONMENT -a fix"
    echo "   Nginx:      ./diagnose-nginx-monitoring.sh -e $ENVIRONMENT -a fix"
    echo ""
    echo "Manual steps:"
    echo "1. Review the failed checks above"
    echo "2. Apply the suggested fixes"
    echo "3. Re-run this validation script"
else
    echo "⚠️  Minor issues detected - $WARNING_CHECKS warnings."
    echo ""
    echo "Consider addressing the warnings for optimal performance."
fi

echo ""
echo "📚 USEFUL COMMANDS"
echo "=================="
echo "View New Relic logs:"
echo "   tail -f /var/log/newrelic-infra/newrelic-infra.log"
echo ""
echo "Test integrations manually:"
echo "   /var/db/newrelic-infra/newrelic-integrations/bin/nri-postgresql -pretty"
echo "   /var/db/newrelic-infra/newrelic-integrations/bin/nri-nginx -pretty"
echo ""
echo "Restart New Relic service:"
echo "   systemctl restart newrelic-infra"
echo ""
echo "Check specific monitoring:"
echo "   PostgreSQL: ./diagnose-postgresql-monitoring.sh -e $ENVIRONMENT -a test"
echo "   Nginx:      ./diagnose-nginx-monitoring.sh -e $ENVIRONMENT -a test"
echo ""
echo "Test endpoints manually:"
echo "   curl http://127.0.0.1:8080/nginx_status"
echo "   curl http://127.0.0.1/health"

# Exit with appropriate code
if [ $FAILED_CHECKS -gt 0 ]; then
    exit 1
elif [ $WARNING_CHECKS -gt 0 ]; then
    exit 2
else
    exit 0
fi