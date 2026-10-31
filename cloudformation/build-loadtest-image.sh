#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
ENVIRONMENT="staging"
AWS_REGION=""

# Function to show usage
usage() {
    echo "Usage: $0 -e ENVIRONMENT [-r AWS_REGION]"
    echo ""
    echo "Options:"
    echo "  -e ENVIRONMENT    Environment name (staging/production) [required]"
    echo "  -r AWS_REGION     AWS region (defaults to current AWS CLI region)"
    echo "  -h                Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -e staging -r us-east-1"
    exit 1
}

# Parse command line arguments
while getopts "e:r:h" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        r)
            AWS_REGION="$OPTARG"
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
    AWS_REGION=$(aws configure get region)
    if [ -z "$AWS_REGION" ]; then
        echo "❌ AWS region not configured. Please set it with -r option or configure AWS CLI"
        exit 1
    fi
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR repository name and URI
ECR_REPOSITORY_NAME="${ENVIRONMENT}-foodme-loadtest"
ECR_REPOSITORY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}"

echo "🚀 Building and pushing load test container"
echo "   Environment: $ENVIRONMENT"
echo "   AWS Region: $AWS_REGION"
echo "   ECR Repository: $ECR_REPOSITORY_URI"

# Check if repository exists, create if it doesn't
if ! aws ecr describe-repositories --repository-names "$ECR_REPOSITORY_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo "📦 Creating ECR repository: $ECR_REPOSITORY_NAME"
    aws ecr create-repository --repository-name "$ECR_REPOSITORY_NAME" --region "$AWS_REGION"
fi

# Get ECR login token and login to Docker
echo "🔐 Logging into ECR"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPOSITORY_URI"

# Build the Docker image
echo "🔨 Building load test Docker image"
cd "$PROJECT_ROOT"
docker build -f docker/Dockerfile.locust -t "$ECR_REPOSITORY_NAME" .

# Tag the image for ECR
echo "🏷️  Tagging image for ECR"
docker tag "$ECR_REPOSITORY_NAME:latest" "$ECR_REPOSITORY_URI:latest"

# Push the image to ECR
echo "📤 Pushing image to ECR"
docker push "$ECR_REPOSITORY_URI:latest"

echo "✅ Load test container successfully built and pushed to ECR"
echo "   Image URI: $ECR_REPOSITORY_URI:latest"