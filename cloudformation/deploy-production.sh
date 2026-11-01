#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME_PREFIX="foodme"
# Use the production-ready template with all troubleshooting fixes
TEMPLATE_FILE="$SCRIPT_DIR/foodme-production-stack.yaml"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to load environment variables from .env file
load_env_file() {
    local env_file="$PROJECT_ROOT/.env"
    if [ -f "$env_file" ]; then
        echo "📄 Loading environment variables from $env_file"
        # Export variables from .env file while ignoring comments and empty lines
        export $(grep -v '^#' "$env_file" | grep -v '^$' | xargs)
    else
        echo "⚠️  No .env file found at $env_file"
    fi
}

validate_prerequisites() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not found. Please install AWS CLI first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "❌ AWS CLI not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "❌ CloudFormation template not found: $TEMPLATE_FILE"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_ROOT/server" ]; then
        echo "❌ Server directory not found: $PROJECT_ROOT/server"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_ROOT/angular-app" ]; then
        echo "❌ Angular app directory not found: $PROJECT_ROOT/angular-app"
        exit 1
    fi
    
    echo "✅ Prerequisites validated"
}

create_s3_bucket() {
    local bucket_name="$1"
    local region="$2"
    
    echo "📦 Creating S3 bucket: $bucket_name"
    
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo "✅ S3 bucket already exists: $bucket_name"
    else
        if [ "$region" = "us-east-1" ]; then
            aws s3api create-bucket --bucket "$bucket_name" --region "$region"
        else
            aws s3api create-bucket --bucket "$bucket_name" --region "$region" \
                --create-bucket-configuration LocationConstraint="$region"
        fi
        echo "✅ S3 bucket created: $bucket_name"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
}

upload_application_code() {
    local bucket_name="$1"
    local temp_dir="/tmp/foodme-production-deployment-$$"
    
    echo "📤 Uploading application code to S3..."
    
    mkdir -p "$temp_dir"
    
    # Package server code
    echo "  📁 Packaging server code..."
    cd "$PROJECT_ROOT"
    zip -r "$temp_dir/server.zip" server/ -x "server/node_modules/*" "server/*.log" "server/.env*"
    
    # Package angular app code
    echo "  📁 Packaging frontend code..."
    zip -r "$temp_dir/angular-app.zip" angular-app/ -x "angular-app/node_modules/*" "angular-app/dist/*" "angular-app/*.log"
    
    # Package database initialization scripts
    echo "  📁 Packaging database initialization scripts..."
    if [ -d "$PROJECT_ROOT/db/init" ]; then
        cd "$PROJECT_ROOT/db"
        zip -r "$temp_dir/db-init.zip" init/
        echo "  ✅ Database scripts packaged successfully"
    else
        echo "  ⚠️  Warning: db/init directory not found, skipping database scripts"
    fi
    
    # Upload to S3
    echo "  ⬆️  Uploading server.zip..."
    aws s3 cp "$temp_dir/server.zip" "s3://$bucket_name/server.zip"
    
    echo "  ⬆️  Uploading angular-app.zip..."
    aws s3 cp "$temp_dir/angular-app.zip" "s3://$bucket_name/angular-app.zip"
    
    # Upload database scripts if they exist
    if [ -f "$temp_dir/db-init.zip" ]; then
        echo "  ⬆️  Uploading db-init.zip..."
        aws s3 cp "$temp_dir/db-init.zip" "s3://$bucket_name/db-init.zip"
    fi
    
    # Upload the enhanced install script with monitoring
    echo "  ⬆️  Uploading enhanced install-foodme.sh..."
    aws s3 cp "$SCRIPT_DIR/install-foodme.sh" "s3://$bucket_name/install-foodme.sh"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "✅ Application code uploaded successfully"
}

deploy_production_stack() {
    local environment="${1:-staging}"
    local instance_type="${2:-t3.medium}"
    local key_pair_name="$3"
    local db_password="$4"
    local new_relic_license_key="${5:-${NEW_RELIC_LICENSE_KEY:-}}"
    # Optional ACM certificate ARN (6th arg or CERTIFICATE_ARN env). Empty
    # means HTTP only; see the CertificateArn parameter in the template.
    local certificate_arn="${6:-${CERTIFICATE_ARN:-}}"
    
    if [ -z "$key_pair_name" ] || [ -z "$db_password" ]; then
        echo "❌ Missing required parameters"
        echo "Usage: $0 <environment> <instance_type> <key_pair_name> <db_password> [new_relic_license_key]"
        echo "Note: new_relic_license_key will be read from .env file if not provided"
        exit 1
    fi
    
    local stack_name="${STACK_NAME_PREFIX}-${environment}"
    local aws_region=$(aws configure get region)
    local aws_account_id=$(aws sts get-caller-identity --query Account --output text)
    local bucket_name="foodme-deployments-${aws_account_id}-${aws_region}"
    
    # Create S3 bucket and upload code
    create_s3_bucket "$bucket_name" "$aws_region"
    upload_application_code "$bucket_name"
    
    echo "🚀 Deploying Production-Ready CloudFormation stack: $stack_name"
    echo "🎯 Template: foodme-production-stack.yaml (includes all troubleshooting fixes)"
    echo "🔍 Using Amazon Linux 2023 (AL2023)"
    echo "🛠️  Includes: Proper Angular routing, Nginx port 8080, PM2 backend management"
    
    if [ -n "$certificate_arn" ]; then
        echo "🔒 HTTPS: ENABLED (certificate $certificate_arn)"
    else
        echo "🔓 HTTPS: disabled (no certificate ARN supplied)"
    fi

    # Display New Relic configuration
    if [ -n "$new_relic_license_key" ]; then
        echo "🔍 New Relic monitoring: ENABLED"
        echo "📊 Monitoring integrations: PostgreSQL, Nginx, Infrastructure"
    else
        echo "⚠️  New Relic monitoring: DISABLED (no license key provided)"
    fi
    
    aws cloudformation deploy \
        --template-file "$TEMPLATE_FILE" \
        --stack-name "$stack_name" \
        --parameter-overrides \
            Environment="$environment" \
            InstanceType="$instance_type" \
            KeyPairName="$key_pair_name" \
            DatabasePassword="$db_password" \
            NewRelicLicenseKey="$new_relic_license_key" \
            CertificateArn="$certificate_arn" \
            S3BucketName="$bucket_name" \
        --capabilities CAPABILITY_NAMED_IAM \
        --tags \
            Environment="$environment" \
            Application=FoodMe \
            ManagedBy=CloudFormation \
            MonitoringEnabled=true \
            Version=Production
    
    echo "✅ Stack deployment completed successfully!"
    
    get_stack_outputs "$stack_name"
}

get_stack_outputs() {
    local stack_name="$1"
    
    echo ""
    echo "📋 Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
    
    echo ""
    echo "🎉 Production Deployment Summary:"
    echo "   ✅ Amazon Linux 2023 (AL2023) EC2 instance"
    echo "   ✅ PostgreSQL 16 with monitoring extensions"
    echo "   ✅ Nginx on port 8080 with Angular routing fixes"
    echo "   ✅ Node.js backend with PM2 process management"
    echo "   ✅ New Relic Infrastructure + PostgreSQL + Nginx integrations"
    echo "   ✅ Application Load Balancer with API routing"
    echo "   ✅ All troubleshooting fixes incorporated"
    echo ""
    echo "🔧 Key Improvements from Troubleshooting:"
    echo "   • Fixed Angular browser/ subdirectory handling"
    echo "   • Proper Nginx configuration for port 8080"
    echo "   • API proxy routing (/api/* and /health)"
    echo "   • PM2 backend process management"
    echo "   • Enhanced user data logging"
    echo "   • New Relic configuration automation"
    echo ""
    echo "🌐 Test Endpoints:"
    local alb_dns=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' --output text)
    echo "   • Application: http://$alb_dns"
    echo "   • Health Check: http://$alb_dns/health"
    echo "   • API Base: http://$alb_dns/api/"
    echo ""
    echo "📊 Next Steps:"
    echo "   1. Test the application endpoints above"
    echo "   2. Check New Relic One Dashboard → Infrastructure"
    echo "   3. Run: ./validate-monitoring.sh -e $1 (for detailed monitoring validation)"
}

main() {
    echo "🚀 FoodMe Production Deployment"
    echo "🎯 Production-ready template with all troubleshooting fixes"
    echo "📦 Includes: AL2023, Enhanced Monitoring, Load Balancing, Auto-scaling Ready"
    echo ""
    
    load_env_file
    validate_prerequisites
    deploy_production_stack "$@"
}

main "$@"