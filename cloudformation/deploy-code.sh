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
SHOW_LOGS=false

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
    echo "  --logs            Show recent backend and nginx logs at the end"
    echo "  -h                Show this help message"
    echo ""
    echo "Environment values synced to the instance .env when set in the caller's"
    echo "environment (CI passes them from GitHub secrets/variables):"
    echo "  NEW_RELIC_ACCOUNT_ID, NEW_RELIC_BROWSER_ENTITY_GUID"
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
        --logs)
            SHOW_LOGS=true
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

if ! command -v jq > /dev/null; then
    echo "❌ jq is required (brew install jq, or dnf/apt install jq)"
    exit 1
fi

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
        --parameters "$(jq -n --arg c "$command" '{commands: [$c]}')" \
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

        # Keep the current code (without node_modules) so a bad deploy can be rolled back by hand
        tar -czf /opt/foodme/backend-backup.tgz --exclude=node_modules -C /opt/foodme/backend .

        # Download and unpack the new code
        aws s3 cp s3://$S3_BUCKET/server.zip /tmp/server.zip
        rm -rf /tmp/server-new && mkdir /tmp/server-new
        unzip -q /tmp/server.zip -d /tmp/server-new

        # Copy everything, including data/ and views/. The .env file and ecosystem.config.js only exist on
        # the instance, and the zip does not contain them, so they stay as they are.
        cp -r /tmp/server-new/server/. /opt/foodme/backend/
        rm -rf /tmp/server-new /tmp/server.zip
        chown -R ec2-user:ec2-user /opt/foodme/backend

        # Install what package.json asks for, as the user that runs the app
        cd /opt/foodme/backend
        sudo -u ec2-user npm install --omit=dev --no-audit --no-fund

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

# Environment sync
# A small set of non-secret values is managed outside the instance and synced
# into the instance .env here, because code deploys otherwise never change
# instance configuration (the .env exists only on the instance, and the code
# zip excludes it on purpose). Set a variable in the caller's environment to
# sync it; unset or empty variables leave the instance value exactly as it is.
# This mechanism is for non-secret configuration only: values travel as SSM
# command parameters. Secrets stay in stack parameters / instance-only config.
SYNC_ENV_KEYS=("NEW_RELIC_ACCOUNT_ID" "NEW_RELIC_BROWSER_ENTITY_GUID")
sync_assignments=()
for key in "${SYNC_ENV_KEYS[@]}"; do
    if [ -n "${!key:-}" ]; then
        sync_assignments+=("$key=${!key}")
    fi
done

if [ "$UPDATE_BACKEND" = true ] && [ ${#sync_assignments[@]} -gt 0 ]; then
    echo ""
    echo "🔐 Syncing environment values to the instance .env..."
    assignments=$(printf '%s\n' "${sync_assignments[@]}")
    ENV_SYNC_COMMANDS="
        set -e
        cd /opt/foodme/backend
        touch .env
        cp .env .env.bak
        while IFS='=' read -r key value; do
            [ -z \"\$key\" ] && continue
            grep -v \"^\${key}=\" .env > .env.tmp || true
            printf '%s=%s\n' \"\$key\" \"\$value\" >> .env.tmp
            mv .env.tmp .env
        done <<'SYNC_EOF'
$assignments
SYNC_EOF
        chown ec2-user:ec2-user .env
        echo 'Instance .env updated'
    "
    COMMAND_ID=$(execute_on_ec2 "$ENV_SYNC_COMMANDS")
    wait_for_command "$COMMAND_ID"
    echo "✅ Environment synced (${#sync_assignments[@]} value(s)); applies on the restart below"
fi

# Restart services
if [ "$RESTART_SERVICES" = true ]; then
    echo ""
    echo "🔄 Restarting services..."
    
    RESTART_COMMANDS="
        set -e
        cd /opt/foodme/backend

        # The backend is a PM2 process owned by ec2-user
        if sudo -u ec2-user pm2 describe foodme-backend > /dev/null 2>&1; then
            sudo -u ec2-user pm2 restart foodme-backend --update-env
        else
            sudo -u ec2-user pm2 start ecosystem.config.js
        fi
        sudo -u ec2-user pm2 save

        # Give it a moment, then make sure it answers
        sleep 5
        curl -sf http://localhost:3000/health > /dev/null || { echo 'Backend did not answer /health'; sudo -u ec2-user pm2 logs foodme-backend --nostream --lines 30; exit 1; }
        echo 'Backend answers /health'

        systemctl reload nginx
        systemctl is-active nginx
    "

    COMMAND_ID=$(execute_on_ec2 "$RESTART_COMMANDS")
    wait_for_command "$COMMAND_ID"
    
    echo "✅ Services restarted"
fi

# Check the application through the load balancer
echo ""
echo "🌐 Application Status:"
APP_URL=$(get_stack_output "ApplicationURL")
HEALTH_URL=$(get_stack_output "HealthCheckURL")
if [ -n "$HEALTH_URL" ]; then
    echo "   Application URL: $APP_URL"
    echo "   Health check:    $HEALTH_URL"
    healthy=false
    for attempt in 1 2 3 4 5 6; do
        if curl -sf --max-time 10 "$HEALTH_URL" > /dev/null; then healthy=true; break; fi
        echo "   Waiting for the load balancer to see a healthy instance (attempt $attempt/6)..."
        sleep 10
    done
    if [ "$healthy" != true ]; then
        echo "❌ $HEALTH_URL did not answer after the deployment"
        exit 1
    fi
    echo "   ✅ Health check passed"
fi

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🔍 To check it again:"
echo "   - Application: curl -s -o /dev/null -w '%{http_code}' $APP_URL"
echo "   - API:         curl -s $APP_URL/api/restaurant"
echo "   - Logs:        $0 -e $ENVIRONMENT --logs"

# Optional: Show recent logs
if [ "$SHOW_LOGS" = true ]; then
    echo ""
    echo "📜 Recent application logs:"
    LOG_COMMANDS="
        echo '=== Backend Logs ==='
        sudo -u ec2-user pm2 logs foodme-backend --nostream --lines 20
        echo
        echo '=== Nginx Error Logs ==='
        tail -20 /var/log/nginx/error.log
    "
    
    COMMAND_ID=$(execute_on_ec2 "$LOG_COMMANDS")
    wait_for_command "$COMMAND_ID"
fi