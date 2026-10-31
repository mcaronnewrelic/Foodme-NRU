#!/bin/bash

# Script to set up Terraform remote state infrastructure
# This creates the S3 bucket and DynamoDB table needed for Terraform state management

set -e

AWS_REGION="us-west-2"
BUCKET_NAME="foodme-terraform-state-bucket"
DYNAMODB_TABLE="foodme-terraform-locks"

echo "=================================================="
echo "Setting up Terraform Remote State Infrastructure"
echo "=================================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI not configured or no valid credentials"
    echo "Please run 'aws configure' first"
    exit 1
fi

echo "✓ AWS CLI is configured"

# Create S3 bucket for Terraform state
echo ""
echo "1. Creating S3 bucket for Terraform state..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✓ S3 bucket '$BUCKET_NAME' already exists"
else
    echo "Creating S3 bucket '$BUCKET_NAME'..."
    
    if [ "$AWS_REGION" = "us-east-1" ]; then
        # us-east-1 doesn't need LocationConstraint
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
    else
        # Other regions need LocationConstraint
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    
    echo "✓ S3 bucket '$BUCKET_NAME' created"
fi

# Enable versioning on the bucket
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "✓ Versioning enabled on S3 bucket"

# Enable encryption on the bucket
echo "Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "✓ Encryption enabled on S3 bucket"

# Block public access
echo "Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✓ Public access blocked on S3 bucket"

# Create DynamoDB table for state locking
echo ""
echo "2. Creating DynamoDB table for Terraform state locking..."

if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "✓ DynamoDB table '$DYNAMODB_TABLE' already exists"
else
    echo "Creating DynamoDB table '$DYNAMODB_TABLE'..."
    
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$AWS_REGION"
    
    echo "Waiting for DynamoDB table to be created..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
    
    echo "✓ DynamoDB table '$DYNAMODB_TABLE' created"
fi

echo ""
echo "=================================================="
echo "✅ Terraform Remote State Infrastructure Ready!"
echo "=================================================="
echo ""
echo "Resources created:"
echo "• S3 Bucket: $BUCKET_NAME"
echo "• DynamoDB Table: $DYNAMODB_TABLE"
echo "• Region: $AWS_REGION"
echo ""
echo "Your Terraform configuration is now set to use remote state."
echo "Future deployments will:"
echo "• Store state in S3 (with versioning and encryption)"
echo "• Use DynamoDB for state locking (prevents concurrent modifications)"
echo "• Reuse existing infrastructure instead of creating new resources"
echo ""
echo "Next steps:"
echo "1. Run 'terraform init' to migrate to remote state"
echo "2. Deploy your application with 'terraform plan' and 'terraform apply'"
echo ""
