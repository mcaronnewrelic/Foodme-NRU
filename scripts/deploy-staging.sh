#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration for our specific stack
ENVIRONMENT="staging"
AWS_REGION="us-west-2"
AWS_PROFILE="Team-Account-Standard-365309403645"
UPDATE_FRONTEND=true
UPDATE_BACKEND=true
RESTART_SERVICES=true

# Stack and resource names
STACK_NAME="foodme-${ENVIRONMENT}"

echo "🚀 FoodMe Code Deployment"
echo "   Environment: $ENVIRONMENT"
echo "   AWS Region: $AWS_REGION"
echo "   AWS Profile: $AWS_PROFILE"
echo "   Frontend Update: $UPDATE_FRONTEND"
echo "   Backend Update: $UPDATE_BACKEND"
echo "   Restart Services: $RESTART_SERVICES"

# Function to get stack output
get_stack_output() {
    local output_key="$1"
    aws cloudformation describe-stacks \
        --profile "$AWS_PROFILE" \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='$output_key'].OutputValue" \
        --output text 2>/dev/null || echo ""
}

# Get stack information
echo "📋 Retrieving stack information..."
# Use EC2InstanceId instead of InstanceId for our stack
INSTANCE_ID=$(get_stack_output "EC2InstanceId")
S3_BUCKET=$(aws cloudformation describe-stacks \
    --profile "$AWS_PROFILE" \
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
    --profile "$AWS_PROFILE" \
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
    aws s3 cp "$temp_dir/${component}.zip" "s3://$S3_BUCKET/${component}.zip" --profile "$AWS_PROFILE" --region "$AWS_REGION"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Function to execute commands on EC2
execute_on_ec2() {
    local command="$1"
    aws ssm send-command \
        --profile "$AWS_PROFILE" \
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
            --profile "$AWS_PROFILE" \
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
                    --profile "$AWS_PROFILE" \
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
    echo "� Deploying Backend (Node.js Server)..."
    
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
        aws s3 cp s3://$S3_BUCKET/server.zip ./server.zip --region $AWS_REGION
        rm -rf temp_server && mkdir temp_server
        cd temp_server
        unzip -q ../server.zip
        
        # Move new files (preserve .env and node_modules)
        cd /opt/foodme/backend
        cp -r temp_server/server/* .
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
        aws s3 cp s3://$S3_BUCKET/angular-app.zip ./angular-app.zip --region $AWS_REGION
        unzip -q angular-app.zip
        rm angular-app.zip
        
        # Fix ownership
        chown -R ec2-user:ec2-user angular-app
        
        # Build Angular application
        cd angular-app
        sudo -u ec2-user npm install
        sudo -u ec2-user npm run build
        
        # Update symlinks
        cd /opt/foodme
        rm -rf browser frontend
        ln -sf angular-app/dist/browser browser
        ln -sf angular-app/dist/browser frontend
        
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
        
        # Check if we have systemd service or PM2
        if systemctl list-units --full -all | grep -q foodme-backend.service; then
            echo 'Using systemd service...'
            if systemctl is-active --quiet foodme-backend; then
                echo 'Restarting foodme-backend service...'
                systemctl restart foodme-backend
            else
                echo 'Starting foodme-backend service...'
                systemctl start foodme-backend
            fi
            sleep 5
            if systemctl is-active --quiet foodme-backend; then
                echo 'Backend service is running'
            else
                echo 'Warning: Backend service failed to start'
                systemctl status foodme-backend
            fi
        else
            echo 'Using PM2...'
            cd /opt/foodme/backend/server
            # Kill any existing PM2 processes
            pm2 kill || true
            # Install dependencies
            npm install --production
            # Start with PM2
            pm2 start index.js --name foodme-backend
            sleep 5
            if pm2 list | grep -q 'online'; then
                echo 'PM2 backend service is running'
            else
                echo 'Warning: PM2 backend service failed to start'
                pm2 status
            fi
        fi
        
        # Restart nginx
        echo 'Restarting nginx...'
        systemctl restart nginx
        
        # Check service status
        echo 'Service status:'
        systemctl is-active nginx
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
    echo "   API URL: http://$ALB_DNS/api/restaurant"
else
    PUBLIC_IP=$(get_stack_output "PublicIpAddress")
    if [ -n "$PUBLIC_IP" ]; then
        echo "   Application URL: http://$PUBLIC_IP"
        echo "   API URL: http://$PUBLIC_IP/api/restaurant"
    fi
fi

echo ""
echo "✅ Deployment completed successfully!"
echo "🍽️  Your menu items now include descriptions in the Angular application!"
echo ""
echo "🔍 To verify the deployment:"
if [ -n "$ALB_DNS" ]; then
    echo "   - Check health: curl -s http://$ALB_DNS/health"
    echo "   - Check API: curl -s http://$ALB_DNS/api/restaurant | jq '.[0].menuItems[0]'"
    echo "   - View app: http://$ALB_DNS"
fi