#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
ENVIRONMENT="staging"
AWS_REGION=""
ACTION="diagnose"

# Function to show usage
usage() {
    echo "Usage: $0 -e ENVIRONMENT [-r AWS_REGION] [-a ACTION]"
    echo ""
    echo "Options:"
    echo "  -e ENVIRONMENT    Environment name (staging/production) [required]"
    echo "  -r AWS_REGION     AWS region (defaults to current AWS CLI region)"
    echo "  -a ACTION         Action to perform: diagnose, fix, test [default: diagnose]"
    echo "  -h                Show this help message"
    echo ""
    echo "Actions:"
    echo "  diagnose          Check Nginx monitoring status and configuration"
    echo "  fix               Attempt to fix Nginx monitoring issues"
    echo "  test              Test Nginx monitoring functionality"
    echo ""
    echo "Examples:"
    echo "  $0 -e staging -a diagnose"
    echo "  $0 -e staging -a fix"
    echo "  $0 -e staging -a test"
    exit 1
}

# Parse command line arguments
while getopts "e:r:a:h" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        r)
            AWS_REGION="$OPTARG"
            ;;
        a)
            ACTION="$OPTARG"
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

# Validate action
if [[ ! "$ACTION" =~ ^(diagnose|fix|test)$ ]]; then
    echo "❌ Invalid action: $ACTION"
    usage
fi

# Get AWS region if not provided
if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(aws configure get region)
    if [ -z "$AWS_REGION" ]; then
        echo "❌ AWS region not configured. Please set it with -r option or configure AWS CLI"
        exit 1
    fi
fi

STACK_NAME="foodme-${ENVIRONMENT}"

echo "🔍 Nginx New Relic Monitoring Diagnostics"
echo "   Environment: $ENVIRONMENT"
echo "   Action: $ACTION"
echo ""

# Function to get stack output
get_stack_output() {
    local output_key="$1"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text 2>/dev/null || echo ""
}

# Get instance information
INSTANCE_ID=$(get_stack_output "InstanceId")
if [ -z "$INSTANCE_ID" ]; then
    echo "❌ Could not find EC2 instance. Make sure the CloudFormation stack '$STACK_NAME' exists."
    exit 1
fi

echo "📋 Instance ID: $INSTANCE_ID"

# Function to execute commands on EC2
execute_on_ec2() {
    local command="$1"
    local timeout="${2:-120}"
    
    local command_id=$(aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$command\"]" \
        --timeout-seconds "$timeout" \
        --region "$AWS_REGION" \
        --query 'Command.CommandId' \
        --output text)
    
    # Wait for command completion
    local max_wait=$timeout
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        local status=$(aws ssm get-command-invocation \
            --command-id "$command_id" \
            --instance-id "$INSTANCE_ID" \
            --region "$AWS_REGION" \
            --query 'Status' \
            --output text 2>/dev/null || echo "InProgress")
        
        case $status in
            "Success")
                aws ssm get-command-invocation \
                    --command-id "$command_id" \
                    --instance-id "$INSTANCE_ID" \
                    --region "$AWS_REGION" \
                    --query 'StandardOutputContent' \
                    --output text
                return 0
                ;;
            "Failed"|"Cancelled"|"TimedOut")
                echo "❌ Command failed with status: $status"
                aws ssm get-command-invocation \
                    --command-id "$command_id" \
                    --instance-id "$INSTANCE_ID" \
                    --region "$AWS_REGION" \
                    --query 'StandardErrorContent' \
                    --output text
                return 1
                ;;
            *)
                sleep 5
                wait_time=$((wait_time + 5))
                ;;
        esac
    done
    
    echo "❌ Command timed out after $max_wait seconds"
    return 1
}

diagnose_nginx_monitoring() {
    echo "🔍 Diagnosing Nginx monitoring setup..."
    echo ""
    
    echo "1️⃣ Checking New Relic Infrastructure agent status..."
    execute_on_ec2 "systemctl is-active newrelic-infra && echo '✅ New Relic Infrastructure is running' || echo '❌ New Relic Infrastructure is not running'"
    echo ""
    
    echo "2️⃣ Checking if Nginx integration is installed..."
    execute_on_ec2 "rpm -qa | grep nri-nginx && echo '✅ Nginx integration is installed' || echo '❌ Nginx integration is not installed'"
    echo ""
    
    echo "3️⃣ Checking Nginx service status..."
    execute_on_ec2 "systemctl is-active nginx && echo '✅ Nginx is running' || echo '❌ Nginx is not running'"
    echo ""
    
    echo "4️⃣ Checking Nginx status module availability..."
    execute_on_ec2 "nginx -V 2>&1 | grep -q 'http_stub_status_module' && echo '✅ Nginx status module is available' || echo '❌ Nginx status module is not available'"
    echo ""
    
    echo "5️⃣ Checking Nginx status endpoint..."
    execute_on_ec2 "curl -s http://127.0.0.1:8080/nginx_status > /dev/null 2>&1 && echo '✅ Nginx status endpoint is accessible' || echo '❌ Nginx status endpoint is not accessible'"
    echo ""
    
    echo "6️⃣ Checking Nginx status endpoint content..."
    execute_on_ec2 "
        if curl -s http://127.0.0.1:8080/nginx_status > /dev/null 2>&1; then
            echo 'Status endpoint response:'
            curl -s http://127.0.0.1:8080/nginx_status
        else
            echo '❌ Cannot retrieve status endpoint content'
        fi
    "
    echo ""
    
    echo "7️⃣ Checking Nginx integration configuration..."
    execute_on_ec2 "
        if [ -f /etc/newrelic-infra/integrations.d/nginx-config.yml ]; then
            echo '✅ Nginx config file exists'
            echo 'Configuration:'
            cat /etc/newrelic-infra/integrations.d/nginx-config.yml
        else
            echo '❌ Nginx config file does not exist'
        fi
    "
    echo ""
    
    echo "8️⃣ Checking Nginx log files and permissions..."
    execute_on_ec2 "
        echo 'Nginx access log:'
        ls -la /var/log/nginx/access.log 2>/dev/null || echo 'Access log not found'
        echo 'Nginx error log:'
        ls -la /var/log/nginx/error.log 2>/dev/null || echo 'Error log not found'
        echo 'Log directory permissions:'
        ls -ld /var/log/nginx/ 2>/dev/null || echo 'Log directory not found'
    "
    echo ""
    
    echo "9️⃣ Checking New Relic Infrastructure logs for Nginx..."
    execute_on_ec2 "
        if [ -f /var/log/newrelic-infra/newrelic-infra.log ]; then
            echo 'Recent Nginx integration logs:'
            grep -i 'nginx\|nri-nginx' /var/log/newrelic-infra/newrelic-infra.log | tail -10 || echo 'No Nginx-related logs found'
        else
            echo '❌ New Relic Infrastructure log file not found'
        fi
    "
}

fix_nginx_monitoring() {
    echo "🔧 Attempting to fix Nginx monitoring..."
    echo ""
    
    # Create comprehensive fix script
    local fix_script="
        set -e
        
        echo '1️⃣ Installing Nginx integration if missing...'
        if ! rpm -qa | grep -q nri-nginx; then
            dnf install -y nri-nginx
            echo '✅ Nginx integration installed'
        else
            echo '✅ Nginx integration already installed'
        fi
        
        echo '2️⃣ Checking and fixing Nginx configuration...'
        
        # Check if status server block exists in main configuration
        if ! grep -q 'server.*listen.*8080' /etc/nginx/conf.d/foodme.conf 2>/dev/null; then
            echo 'Adding status server block to nginx configuration...'
            
            # Backup current config
            cp /etc/nginx/conf.d/foodme.conf /etc/nginx/conf.d/foodme.conf.backup
            
            # Add status server block
            cat >> /etc/nginx/conf.d/foodme.conf << 'EOF'

# Status server for monitoring
server {
    listen 8080;
    server_name localhost;
    
    # Nginx status page for New Relic monitoring
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow ::1;
        deny all;
    }
    
    # Extended status page for additional metrics
    location /status {
        return 200 'nginx server status ok';
        access_log off;
        add_header Content-Type text/plain;
    }
}
EOF
            echo '✅ Status server block added'
        else
            echo '✅ Status server block already exists'
        fi
        
        echo '3️⃣ Testing Nginx configuration...'
        nginx -t && echo '✅ Nginx configuration is valid' || echo '❌ Nginx configuration is invalid'
        
        echo '4️⃣ Restarting Nginx...'
        systemctl restart nginx
        
        echo '5️⃣ Waiting for Nginx to be ready...'
        sleep 3
        
        echo '6️⃣ Testing status endpoint...'
        curl -s http://127.0.0.1:8080/nginx_status > /dev/null && echo '✅ Status endpoint is accessible' || echo '❌ Status endpoint is not accessible'
        
        echo '7️⃣ Creating integration configuration...'
        mkdir -p /etc/newrelic-infra/integrations.d
        
        cat > /etc/newrelic-infra/integrations.d/nginx-config.yml << EOF
integrations:
  - name: nri-nginx
    env:
      # Status URL for nginx stub_status module
      STATUS_URL: http://127.0.0.1:8080/nginx_status
      
      # Connection settings
      CONNECTION_TIMEOUT: 5
      HTTP_TIMEOUT: 30
      
      # SSL settings
      VALIDATE_CERTS: false
      
      # Metrics collection settings
      METRICS: true
      INVENTORY: true
      
      # EC2 deployment settings
      REMOTE_MONITORING: false
      
      # Custom attributes for better organization
      CUSTOM_ATTRIBUTES: '{\"service\":\"nginx\",\"environment\":\"$ENVIRONMENT\",\"application\":\"foodme\",\"role\":\"web-server\",\"deployment\":\"ec2\"}'
      
      # Optional: Parse nginx access logs for additional metrics
      ACCESS_LOG_PATH: /var/log/nginx/access.log
      ERROR_LOG_PATH: /var/log/nginx/error.log
      
      # Log parsing format (combined is default nginx format)
      LOG_FORMAT: combined
      
      # Enable log metrics collection
      COLLECT_LOG_METRICS: true
      
    interval: 30s
    labels:
      env: $ENVIRONMENT
      role: web-server
      service: nginx
      application: foodme
      deployment: ec2
    inventory_source: config/nginx
EOF
        
        echo '8️⃣ Setting proper permissions...'
        chown root:newrelic-infra /etc/newrelic-infra/integrations.d/nginx-config.yml
        chmod 640 /etc/newrelic-infra/integrations.d/nginx-config.yml
        
        # Set log permissions
        chmod 755 /var/log/nginx
        chmod 644 /var/log/nginx/*.log 2>/dev/null || true
        
        echo '9️⃣ Restarting New Relic Infrastructure...'
        systemctl restart newrelic-infra
        
        echo '✅ Nginx monitoring fix completed'
    "
    
    execute_on_ec2 "$fix_script" 300
}

test_nginx_monitoring() {
    echo "🧪 Testing Nginx monitoring functionality..."
    echo ""
    
    local test_script="
        set -e
        
        echo '1️⃣ Testing Nginx integration executable...'
        if command -v /var/db/newrelic-infra/newrelic-integrations/bin/nri-nginx > /dev/null 2>&1; then
            echo '✅ Nginx integration executable found'
        else
            echo '❌ Nginx integration executable not found'
        fi
        
        echo '2️⃣ Testing configuration syntax...'
        if [ -f /etc/newrelic-infra/integrations.d/nginx-config.yml ]; then
            echo 'Testing YAML syntax...'
            python3 -c \"import yaml; yaml.safe_load(open('/etc/newrelic-infra/integrations.d/nginx-config.yml'))\" && echo '✅ Configuration syntax is valid' || echo '❌ Configuration syntax is invalid'
        else
            echo '❌ Configuration file not found'
        fi
        
        echo '3️⃣ Testing status endpoint connectivity...'
        echo 'Basic connection test...'
        curl -s -w 'HTTP Status: %{http_code}\\nTotal time: %{time_total}s\\n' http://127.0.0.1:8080/nginx_status || echo '❌ Connection failed'
        
        echo '4️⃣ Testing status endpoint content...'
        echo 'Status endpoint output:'
        curl -s http://127.0.0.1:8080/nginx_status 2>/dev/null || echo '❌ Cannot retrieve status content'
        
        echo '5️⃣ Testing main application endpoint...'
        echo 'Testing main app on port 80...'
        curl -s -w 'HTTP Status: %{http_code}\\n' -o /dev/null http://127.0.0.1/ || echo '❌ Main app connection failed'
        
        echo '6️⃣ Checking service status...'
        systemctl is-active nginx && echo '✅ Nginx service is active' || echo '❌ Nginx service is not active'
        systemctl is-active newrelic-infra && echo '✅ New Relic Infrastructure service is active' || echo '❌ New Relic Infrastructure service is not active'
        
        echo '7️⃣ Checking recent logs for errors...'
        echo 'Recent New Relic Infrastructure logs (last 5 lines):'
        tail -5 /var/log/newrelic-infra/newrelic-infra.log 2>/dev/null || echo 'Log file not accessible'
        
        echo '8️⃣ Testing integration manually...'
        if [ -f /var/db/newrelic-infra/newrelic-integrations/bin/nri-nginx ]; then
            echo 'Manual integration test:'
            /var/db/newrelic-infra/newrelic-integrations/bin/nri-nginx -pretty 2>/dev/null | head -20 || echo 'Manual test failed'
        else
            echo '❌ Integration binary not found for manual test'
        fi
    "
    
    execute_on_ec2 "$test_script" 180
}

# Main execution
case $ACTION in
    diagnose)
        diagnose_nginx_monitoring
        ;;
    fix)
        fix_nginx_monitoring
        ;;
    test)
        test_nginx_monitoring
        ;;
esac

echo ""
echo "🏁 $ACTION completed!"
echo ""
echo "📚 Next steps:"
echo "   1. If issues persist, check New Relic One Dashboard → Infrastructure → Integrations"
echo "   2. View detailed logs: tail -f /var/log/newrelic-infra/newrelic-infra.log"
echo "   3. Restart integration if needed: systemctl restart newrelic-infra"
echo "   4. For manual testing: $0 -e $ENVIRONMENT -a test"
echo "   5. Test status endpoint: curl http://127.0.0.1:8080/nginx_status"