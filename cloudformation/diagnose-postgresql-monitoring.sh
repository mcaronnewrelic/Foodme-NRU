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
    echo "  diagnose          Check PostgreSQL monitoring status and configuration"
    echo "  fix               Attempt to fix PostgreSQL monitoring issues"
    echo "  test              Test PostgreSQL monitoring functionality"
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

echo "🔍 PostgreSQL New Relic Monitoring Diagnostics"
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

diagnose_postgresql_monitoring() {
    echo "🔍 Diagnosing PostgreSQL monitoring setup..."
    echo ""
    
    echo "1️⃣ Checking New Relic Infrastructure agent status..."
    execute_on_ec2 "systemctl is-active newrelic-infra && echo '✅ New Relic Infrastructure is running' || echo '❌ New Relic Infrastructure is not running'"
    echo ""
    
    echo "2️⃣ Checking if PostgreSQL integration is installed..."
    execute_on_ec2 "rpm -qa | grep nri-postgresql && echo '✅ PostgreSQL integration is installed' || echo '❌ PostgreSQL integration is not installed'"
    echo ""
    
    echo "3️⃣ Checking PostgreSQL integration configuration..."
    execute_on_ec2 "
        if [ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]; then
            echo '✅ PostgreSQL config file exists'
            echo 'Configuration:'
            cat /etc/newrelic-infra/integrations.d/postgresql-config.yml
        else
            echo '❌ PostgreSQL config file does not exist'
        fi
    "
    echo ""
    
    echo "4️⃣ Checking PostgreSQL service status..."
    execute_on_ec2 "systemctl is-active postgresql && echo '✅ PostgreSQL is running' || echo '❌ PostgreSQL is not running'"
    echo ""
    
    echo "5️⃣ Checking New Relic monitoring user in PostgreSQL..."
    execute_on_ec2 "
        sudo -u postgres psql -d foodme -c \"SELECT usename FROM pg_user WHERE usename = 'newrelic';\" 2>/dev/null | grep newrelic && echo '✅ New Relic user exists' || echo '❌ New Relic user does not exist'
    "
    echo ""
    
    echo "6️⃣ Testing PostgreSQL connection for monitoring..."
    execute_on_ec2 "
        if [ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]; then
            # Extract password from config (this is safe since we're running on the same machine)
            PASS=\$(grep 'PASSWORD:' /etc/newrelic-infra/integrations.d/postgresql-config.yml | awk '{print \$2}' | tr -d '\"')
            if [ -n \"\$PASS\" ]; then
                PGPASSWORD=\"\$PASS\" psql -h localhost -p 5432 -U newrelic -d foodme -c 'SELECT 1;' > /dev/null 2>&1 && echo '✅ Database connection test successful' || echo '❌ Database connection test failed'
            else
                echo '⚠️  Could not extract password from config file'
            fi
        else
            echo '❌ No config file to test'
        fi
    "
    echo ""
    
    echo "7️⃣ Checking New Relic Infrastructure logs for PostgreSQL..."
    execute_on_ec2 "
        if [ -f /var/log/newrelic-infra/newrelic-infra.log ]; then
            echo 'Recent PostgreSQL integration logs:'
            grep -i 'postgres\|nri-postgresql' /var/log/newrelic-infra/newrelic-infra.log | tail -10 || echo 'No PostgreSQL-related logs found'
        else
            echo '❌ New Relic Infrastructure log file not found'
        fi
    "
    echo ""
    
    echo "8️⃣ Checking integration directory permissions..."
    execute_on_ec2 "
        ls -la /etc/newrelic-infra/integrations.d/ 2>/dev/null || echo 'Integration directory does not exist'
    "
}

fix_postgresql_monitoring() {
    echo "🔧 Attempting to fix PostgreSQL monitoring..."
    echo ""
    
    # Create comprehensive fix script
    local fix_script="
        set -e
        
        echo '1️⃣ Installing PostgreSQL integration if missing...'
        if ! rpm -qa | grep -q nri-postgresql; then
            dnf install -y nri-postgresql
            echo '✅ PostgreSQL integration installed'
        else
            echo '✅ PostgreSQL integration already installed'
        fi
        
        echo '2️⃣ Creating monitoring user if missing...'
        if ! sudo -u postgres psql -d foodme -tAc \"SELECT 1 FROM pg_roles WHERE rolname='newrelic'\" | grep -q 1; then
            echo 'Creating newrelic user...'
            NEWRELIC_DB_PASSWORD=\$(openssl rand -base64 32)
            
            sudo -u postgres psql -d foodme << 'EOF'
CREATE USER newrelic WITH PASSWORD '\$NEWRELIC_DB_PASSWORD';
GRANT CONNECT ON DATABASE foodme TO newrelic;
GRANT USAGE ON SCHEMA public TO newrelic;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO newrelic;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO newrelic;
GRANT pg_monitor TO newrelic;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO newrelic;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO newrelic;
EOF
            echo \$NEWRELIC_DB_PASSWORD > /tmp/newrelic_db_password
            echo '✅ New Relic user created'
        else
            echo '✅ New Relic user already exists'
            # Generate new password for existing user
            NEWRELIC_DB_PASSWORD=\$(openssl rand -base64 32)
            sudo -u postgres psql -d foodme -c \"ALTER USER newrelic WITH PASSWORD '\$NEWRELIC_DB_PASSWORD';\"
            echo \$NEWRELIC_DB_PASSWORD > /tmp/newrelic_db_password
            echo '✅ New Relic user password updated'
        fi
        
        echo '3️⃣ Creating integration configuration...'
        mkdir -p /etc/newrelic-infra/integrations.d
        
        NEWRELIC_DB_PASSWORD=\$(cat /tmp/newrelic_db_password)
        
        cat > /etc/newrelic-infra/integrations.d/postgresql-config.yml << EOF
integrations:
  - name: nri-postgresql
    env:
      HOSTNAME: localhost
      PORT: 5432
      USERNAME: newrelic
      DATABASE: foodme
      PASSWORD: \$NEWRELIC_DB_PASSWORD
      SSL_MODE: disable
      CONNECTION_TIMEOUT: 5
      METRICS: true
      INVENTORY: true
      COLLECT_DB_LOCK_METRICS: true
      COLLECT_BLOAT_METRICS: true
      CUSTOM_ATTRIBUTES: '{\"service\":\"postgresql\",\"environment\":\"$ENVIRONMENT\",\"application\":\"foodme\",\"database\":\"foodme\",\"deployment\":\"ec2\"}'
    interval: 30s
    labels:
      env: $ENVIRONMENT
      role: database
      service: postgresql
      application: foodme
      deployment: ec2
    inventory_source: config/postgresql
EOF
        
        echo '4️⃣ Setting proper permissions...'
        chown root:newrelic-infra /etc/newrelic-infra/integrations.d/postgresql-config.yml
        chmod 640 /etc/newrelic-infra/integrations.d/postgresql-config.yml
        
        echo '5️⃣ Testing database connection...'
        PGPASSWORD=\"\$NEWRELIC_DB_PASSWORD\" psql -h localhost -p 5432 -U newrelic -d foodme -c 'SELECT 1;' > /dev/null && echo '✅ Database connection test successful' || echo '❌ Database connection test failed'
        
        echo '6️⃣ Restarting New Relic Infrastructure...'
        systemctl restart newrelic-infra
        
        echo '7️⃣ Cleaning up temporary files...'
        rm -f /tmp/newrelic_db_password
        
        echo '✅ PostgreSQL monitoring fix completed'
    "
    
    execute_on_ec2 "$fix_script" 300
}

test_postgresql_monitoring() {
    echo "🧪 Testing PostgreSQL monitoring functionality..."
    echo ""
    
    local test_script="
        set -e
        
        echo '1️⃣ Testing PostgreSQL integration executable...'
        if command -v /var/db/newrelic-infra/newrelic-integrations/bin/nri-postgresql > /dev/null 2>&1; then
            echo '✅ PostgreSQL integration executable found'
        else
            echo '❌ PostgreSQL integration executable not found'
        fi
        
        echo '2️⃣ Testing configuration syntax...'
        if [ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]; then
            echo 'Testing YAML syntax...'
            python3 -c \"import yaml; yaml.safe_load(open('/etc/newrelic-infra/integrations.d/postgresql-config.yml'))\" && echo '✅ Configuration syntax is valid' || echo '❌ Configuration syntax is invalid'
        else
            echo '❌ Configuration file not found'
        fi
        
        echo '3️⃣ Testing database connectivity...'
        if [ -f /etc/newrelic-infra/integrations.d/postgresql-config.yml ]; then
            PASS=\$(grep 'PASSWORD:' /etc/newrelic-infra/integrations.d/postgresql-config.yml | awk '{print \$2}' | tr -d '\"')
            if [ -n \"\$PASS\" ]; then
                echo 'Testing basic connection...'
                PGPASSWORD=\"\$PASS\" psql -h localhost -p 5432 -U newrelic -d foodme -c 'SELECT version();' && echo '✅ Basic connection successful'
                
                echo 'Testing monitoring queries...'
                PGPASSWORD=\"\$PASS\" psql -h localhost -p 5432 -U newrelic -d foodme -c 'SELECT COUNT(*) FROM pg_stat_activity;' && echo '✅ Monitoring queries successful'
                
                echo 'Testing custom metrics query...'
                PGPASSWORD=\"\$PASS\" psql -h localhost -p 5432 -U newrelic -d foodme -c \"SELECT 'database_size' as metric_name, pg_database_size('foodme') as metric_value;\" && echo '✅ Custom metrics query successful'
            else
                echo '❌ Could not extract password from config'
            fi
        else
            echo '❌ No configuration file to test'
        fi
        
        echo '4️⃣ Checking service status...'
        systemctl is-active newrelic-infra && echo '✅ New Relic Infrastructure service is active' || echo '❌ New Relic Infrastructure service is not active'
        
        echo '5️⃣ Checking recent logs for errors...'
        echo 'Recent New Relic Infrastructure logs (last 5 lines):'
        tail -5 /var/log/newrelic-infra/newrelic-infra.log 2>/dev/null || echo 'Log file not accessible'
    "
    
    execute_on_ec2 "$test_script" 180
}

# Main execution
case $ACTION in
    diagnose)
        diagnose_postgresql_monitoring
        ;;
    fix)
        fix_postgresql_monitoring
        ;;
    test)
        test_postgresql_monitoring
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