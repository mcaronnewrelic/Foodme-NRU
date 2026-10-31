#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
ENVIRONMENT="staging"
AWS_REGION=""
UPDATE_FRONTEND=true
UPDATE_BACKEND=true
RESTART_SERVICES=true

# Function to show usage
usage() {
    echo "Usage: $0 -e ENVIRONMENT [-r AWS_REGION] [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -e ENVIRONMENT    Environment name (staging/production)"
    echo ""
    echo "Optional:"
    echo "  -r AWS_REGION     AWS region (defaults to current AWS CLI region)"
    echo "  --frontend-only   Update only Angular frontend"
    echo "  --backend-only    Update only Node.js backend"
    echo "  --no-restart      Skip restarting services"
    echo "  -h                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e staging                    # Update both frontend and backend"
    echo "  $0 -e staging --frontend-only    # Update only frontend"
    echo "  $0 -e staging --backend-only     # Update only backend"
    echo "  $0 -e staging --no-restart       # Update code but don't restart services"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r)
            AWS_REGION="$2"
            shift 2
            ;;
        --frontend-only)
            UPDATE_FRONTEND=true
            UPDATE_BACKEND=false
            shift
            ;;
        --backend-only)
            UPDATE_FRONTEND=false
            UPDATE_BACKEND=true
            shift
            ;;
        --no-restart)
            RESTART_SERVICES=false
            shift
            ;;
        -h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
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
    AWS_REGION=$(aws configure get region)
    if [ -z "$AWS_REGION" ]; then
        echo "❌ AWS region not configured. Please set it with -r option or configure AWS CLI"
        exit 1
    fi
fi

# Stack and resource names
STACK_NAME="foodme-${ENVIRONMENT}"

echo "🚀 FoodMe Code Deployment"
echo "   Environment: $ENVIRONMENT"
echo "   AWS Region: $AWS_REGION"
echo "   Frontend Update: $UPDATE_FRONTEND"
echo "   Backend Update: $UPDATE_BACKEND"
echo "   Restart Services: $RESTART_SERVICES"

# Function to get stack output
get_stack_output() {
    local output_key="$1"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text 2>/dev/null || echo ""
}

# Get stack information
echo "📋 Retrieving stack information..."
INSTANCE_ID=$(get_stack_output "EC2InstanceId")
S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Parameters[?ParameterKey==`S3BucketName`].ParameterValue' \
    --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ]; then
    echo "❌ Could not find EC2 instance. Make sure the CloudFormation stack '$STACK_NAME' exists."
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "❌ Could not find S3 bucket name from stack parameters."
    exit 1
fi

echo "   Instance ID: $INSTANCE_ID"
echo "   S3 Bucket: $S3_BUCKET"

# Check if EC2 instance is running
echo "🔍 Checking EC2 instance status..."
INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text)

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "❌ EC2 instance is not running (current state: $INSTANCE_STATE)"
    exit 1
fi

echo "✅ EC2 instance is running"

# Function to package and upload code
package_and_upload() {
    local component="$1"
    local temp_dir="/tmp/foodme-deployment-$$"
    
    mkdir -p "$temp_dir"
    
    echo "📦 Packaging $component code..."
    cd "$PROJECT_ROOT"
    
    case $component in
        "server")
            zip -r "$temp_dir/server.zip" server/ -x "server/node_modules/*" "server/*.log" "server/.env*" > /dev/null
            ;;
        "angular-app")
            zip -r "$temp_dir/angular-app.zip" angular-app/ -x "angular-app/node_modules/*" "angular-app/dist/*" "angular-app/*.log" > /dev/null
            ;;
    esac
    
    echo "📤 Uploading $component to S3..."
    aws s3 cp "$temp_dir/${component}.zip" "s3://$S3_BUCKET/${component}.zip" --region "$AWS_REGION"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Function to execute commands on EC2
execute_on_ec2() {
    local command="$1"
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$command\"]" \
        --region "$AWS_REGION" \
        --query 'Command.CommandId' \
        --output text
}

# Function to wait for SSM command completion
wait_for_command() {
    local command_id="$1"
    local max_wait=300  # 5 minutes
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
                echo "✅ Command completed successfully"
                return 0
                ;;
            "Failed"|"Cancelled"|"TimedOut")
                echo "❌ Command failed with status: $status"
                # Get command output for debugging
                aws ssm get-command-invocation \
                    --command-id "$command_id" \
                    --instance-id "$INSTANCE_ID" \
                    --region "$AWS_REGION" \
                    --query 'StandardErrorContent' \
                    --output text
                return 1
                ;;
            *)
                echo "⏳ Waiting for command completion... ($wait_time/$max_wait seconds)"
                sleep 10
                wait_time=$((wait_time + 10))
                ;;
        esac
    done
    
    echo "❌ Command timed out after $max_wait seconds"
    return 1
}

# Backend deployment
if [ "$UPDATE_BACKEND" = true ]; then
    echo ""
    echo "🔧 Deploying Backend (Node.js Server)..."
    
    # Package and upload backend
    package_and_upload "server"
    
    # Update backend on EC2
    echo "🔄 Updating backend on EC2..."
    BACKEND_COMMANDS="
        set -e
        cd /opt/foodme/backend
        
        # Backup current code
        if [ -d backup ]; then rm -rf backup; fi
        mkdir backup
        cp -r *.js *.json package* backup/ 2>/dev/null || true
        
        # Download and extract new code
        aws s3 cp s3://$S3_BUCKET/server.zip ./server.zip
        rm -rf temp_server && mkdir temp_server
        cd temp_server
        unzip -q ../server.zip
        
        # Move new files (preserve .env and node_modules)
        cd /opt/foodme/backend
        cp temp_server/server/* .
        rm -rf temp_server server.zip
        
        # Install dependencies if package.json changed
        npm install --production
        
        echo 'Backend code updated successfully'
    "
    
    COMMAND_ID=$(execute_on_ec2 "$BACKEND_COMMANDS")
    wait_for_command "$COMMAND_ID"
    
    echo "✅ Backend deployment completed"
fi

# Frontend deployment
if [ "$UPDATE_FRONTEND" = true ]; then
    echo ""
    echo "🎨 Deploying Frontend (Angular App)..."
    
    # Package and upload frontend
    package_and_upload "angular-app"
    
    # Update frontend on EC2
    echo "🔄 Updating frontend on EC2..."
    FRONTEND_COMMANDS="
        set -e
        cd /opt/foodme
        
        # Backup current angular-app
        if [ -d angular-app-backup ]; then rm -rf angular-app-backup; fi
        if [ -d angular-app ]; then mv angular-app angular-app-backup; fi
        
        # Download and extract new code
        aws s3 cp s3://$S3_BUCKET/angular-app.zip ./angular-app.zip
        unzip -q angular-app.zip
        rm angular-app.zip
        
        # Fix ownership
        chown -R ec2-user:ec2-user angular-app
        
        # Build Angular application
        cd angular-app
        sudo -u ec2-user npm install
        sudo -u ec2-user npm run build
        
        # Update symlink
        cd /opt/foodme
        rm -f browser
        ln -sf angular-app/dist/browser browser
        
        echo 'Frontend code updated successfully'
    "
    
    COMMAND_ID=$(execute_on_ec2 "$FRONTEND_COMMANDS")
    wait_for_command "$COMMAND_ID"
    
    echo "✅ Frontend deployment completed"
fi

# Restart services
if [ "$RESTART_SERVICES" = true ]; then
    echo ""
    echo "🔄 Restarting services..."
    
    RESTART_COMMANDS="
        set -e
        
        # Restart backend service
        if systemctl is-active --quiet foodme-backend; then
            echo 'Restarting foodme-backend service...'
            systemctl restart foodme-backend
            sleep 5
            if systemctl is-active --quiet foodme-backend; then
                echo 'Backend service restarted successfully'
            else
                echo 'Warning: Backend service failed to restart'
                systemctl status foodme-backend
            fi
        else
            echo 'Starting foodme-backend service...'
            systemctl start foodme-backend
        fi
        
        # Restart nginx
        echo 'Restarting nginx...'
        systemctl restart nginx
        
        # Check service status
        echo 'Service status:'
        systemctl is-active foodme-backend nginx
    "
    
    COMMAND_ID=$(execute_on_ec2 "$RESTART_COMMANDS")
    wait_for_command "$COMMAND_ID"
    
    echo "✅ Services restarted"
fi

# Get application URL
echo ""
echo "🌐 Application Status:"
ALB_DNS=$(get_stack_output "LoadBalancerDNS")
if [ -n "$ALB_DNS" ]; then
    echo "   Application URL: http://$ALB_DNS"
    echo "   API URL: http://$ALB_DNS:3000"
else
    PUBLIC_IP=$(get_stack_output "PublicIpAddress")
    if [ -n "$PUBLIC_IP" ]; then
        echo "   Application URL: http://$PUBLIC_IP"
        echo "   API URL: http://$PUBLIC_IP:3000"
    fi
fi

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🔍 To verify the deployment:"
echo "   - Check application: curl -s -o /dev/null -w '%{http_code}' http://$ALB_DNS"
echo "   - Check API: curl -s http://$ALB_DNS:3000/api/restaurant"
echo "   - View logs: $0 --logs"

# Optional: Show recent logs
if [ "$1" = "--logs" ]; then
    echo ""
    echo "📜 Recent application logs:"
    LOG_COMMANDS="
        echo '=== Backend Logs ==='
        journalctl -u foodme-backend --no-pager -n 20
        echo
        echo '=== Nginx Error Logs ==='
        tail -20 /var/log/nginx/error.log
    "
    
    COMMAND_ID=$(execute_on_ec2 "$LOG_COMMANDS")
    wait_for_command "$COMMAND_ID"
fi