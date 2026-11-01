#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="foodme-staging"
TEMPLATE_FILE="$SCRIPT_DIR/cloudformation/foodme-production-stack.yaml"
PROJECT_ROOT="$SCRIPT_DIR"

# AWS Configuration
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile Team-Account-Standard-365309403645 --query Account --output text)
S3_BUCKET_NAME="foodme-deployments-${AWS_ACCOUNT_ID}-${AWS_REGION}"

echo "🚀 Starting FoodMe Simple Deployment"
echo "📍 Region: $AWS_REGION"
echo "🪣 S3 Bucket: $S3_BUCKET_NAME"
echo "📋 Stack: $STACK_NAME"
echo "📄 Template: $TEMPLATE_FILE"

# Create S3 bucket if it doesn't exist
echo "📦 Creating S3 bucket if needed..."
if ! aws s3api head-bucket --bucket "$S3_BUCKET_NAME" --profile Team-Account-Standard-365309403645 2>/dev/null; then
    aws s3api create-bucket --bucket "$S3_BUCKET_NAME" --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" \
        --profile Team-Account-Standard-365309403645
    echo "✅ S3 bucket created: $S3_BUCKET_NAME"
else
    echo "✅ S3 bucket already exists: $S3_BUCKET_NAME"
fi

# Upload application code
echo "📤 Uploading application code..."
TEMP_DIR="/tmp/foodme-deployment-$$"
mkdir -p "$TEMP_DIR"

# Package server code
echo "📦 Packaging server code..."
cd "$PROJECT_ROOT/server"
tar -czf "$TEMP_DIR/server.tar.gz" .
aws s3 cp "$TEMP_DIR/server.tar.gz" "s3://$S3_BUCKET_NAME/server.tar.gz" --profile Team-Account-Standard-365309403645

# Package angular app
echo "📦 Packaging Angular app..."
cd "$PROJECT_ROOT/angular-app"
tar -czf "$TEMP_DIR/angular-app.tar.gz" .
aws s3 cp "$TEMP_DIR/angular-app.tar.gz" "s3://$S3_BUCKET_NAME/angular-app.tar.gz" --profile Team-Account-Standard-365309403645

# Package database scripts
echo "📦 Packaging database scripts..."
cd "$PROJECT_ROOT"
tar -czf "$TEMP_DIR/db.tar.gz" db/
aws s3 cp "$TEMP_DIR/db.tar.gz" "s3://$S3_BUCKET_NAME/db.tar.gz" --profile Team-Account-Standard-365309403645

# Upload installation script
echo "📦 Uploading installation script..."
aws s3 cp "$PROJECT_ROOT/cloudformation/install-foodme.sh" "s3://$S3_BUCKET_NAME/install-foodme.sh" --profile Team-Account-Standard-365309403645

echo "✅ All code uploaded to S3"

# Clean up temp directory
rm -rf "$TEMP_DIR"

# Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."

# Generate random password if not set
DB_PASSWORD=${DATABASE_PASSWORD:-$(openssl rand -base64 12)}

aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        Environment=staging \
        InstanceType=t3.medium \
        KeyPairName=foodme-keypair \
        DatabasePassword="$DB_PASSWORD" \
        NewRelicLicenseKey="" \
        S3BucketName="$S3_BUCKET_NAME" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region "$AWS_REGION" \
    --profile Team-Account-Standard-365309403645

echo "✅ CloudFormation stack deployed successfully!"

# Get outputs
echo "📊 Stack Outputs:"
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --profile Team-Account-Standard-365309403645 \
    --query 'Stacks[0].Outputs[?OutputKey==`ApplicationURL`].OutputValue' \
    --output text

echo "🎉 Deployment completed successfully!"
echo "🌐 Application should be available at the URL above"
echo "💾 Database password: $DB_PASSWORD"