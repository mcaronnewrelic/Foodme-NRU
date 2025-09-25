#!/bin/bash

# Complete Terraform state reset script for FoodMe
# This script will clean up all Terraform-managed resources and state

set -e

ENVIRONMENT="${1:-staging}"
REGION="us-west-2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_PROFILE="${AWS_PROFILE:-}"

# Default backend configuration
DEFAULT_STATE_BUCKET="foodme-terraform-state-bucket"
DEFAULT_LOCK_TABLE="foodme-terraform-locks"

echo "🔄 FoodMe Terraform State Reset"
echo "=============================="
echo "Environment: ${ENVIRONMENT}"
echo "Region: ${REGION}"
if [[ -n "$AWS_PROFILE" ]]; then
    echo "AWS Profile: ${AWS_PROFILE}"
fi
echo ""

validate_environment() {
    if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "💡 Usage: $0 [staging|production]"
        echo "💡 Or: AWS_PROFILE=your-profile $0 [staging|production]"
        exit 1
    fi
}

check_and_login_sso() {
    local aws_cmd=$(get_aws_command)
    
    echo "🔐 Checking SSO login status..."
    
    if [[ -n "$AWS_PROFILE" ]]; then
        # Check if profile uses SSO
        local sso_start_url=$(aws configure get sso_start_url --profile "$AWS_PROFILE" 2>/dev/null || echo "")
        
        if [[ -n "$sso_start_url" ]]; then
            echo "🔍 SSO profile detected. Checking login status..."
            
            # Try to get caller identity to check if logged in
            if ! $aws_cmd sts get-caller-identity > /dev/null 2>&1; then
                echo "🔑 SSO login required. Attempting automatic login..."
                aws sso login --profile "$AWS_PROFILE"
                
                # Verify login worked
                if ! $aws_cmd sts get-caller-identity > /dev/null 2>&1; then
                    echo "❌ SSO login failed"
                    return 1
                fi
            fi
            
            echo "✅ SSO authentication verified"
        fi
    fi
    
    return 0
}

check_aws_authentication() {
    echo "🔍 Checking AWS authentication..."
    
    local aws_cmd=$(get_aws_command)
    
    # Try SSO login first if using SSO profile
    if ! check_and_login_sso; then
        echo "❌ SSO authentication failed"
        exit 1
    fi
    
    # Try to get caller identity
    if $aws_cmd sts get-caller-identity > /dev/null 2>&1; then
        local caller_info=$($aws_cmd sts get-caller-identity --output text --query '[Arn,Account,UserId]')
        echo "✅ AWS authentication successful"
        echo "   Account: $(echo $caller_info | cut -f2)"
        echo "   User: $(echo $caller_info | cut -f1)"
        return 0
    fi
    
    # Authentication failed, provide guidance
    echo "❌ AWS authentication failed"
    echo ""
    display_authentication_help
    exit 1
}

display_authentication_help() {
    echo "🔧 Authentication troubleshooting:"
    echo ""
    
    if [[ -f ~/.aws/config ]]; then
        echo "📋 Available AWS profiles:"
        grep '\[profile' ~/.aws/config | sed 's/\[profile \(.*\)\]/   • \1/' || echo "   No profiles found"
        echo ""
        echo "💡 Try one of these options:"
        echo "   1. Use SSO profile: AWS_PROFILE=Team-Account-Standard-365309403645 $0"
        echo "   2. Login to SSO: aws sso login --profile Team-Account-Standard-365309403645"
        echo "   3. Export profile: export AWS_PROFILE=Team-Account-Standard-365309403645"
    fi
    
    echo ""
    echo "🔧 Common solutions:"
    echo "   • For SSO: aws sso login --profile <profile-name>"
    echo "   • For access keys: aws configure"
    echo "   • Check credentials: aws sts get-caller-identity"
    echo "   • Refresh SSO: aws sso logout && aws sso login --profile <profile-name>"
}

setup_backend_variables() {
    echo "🔧 Setting up backend configuration..."
    
    # Use provided environment variables or defaults
    export TERRAFORM_STATE_BUCKET="${TERRAFORM_STATE_BUCKET:-$DEFAULT_STATE_BUCKET}"
    export TERRAFORM_LOCK_TABLE="${TERRAFORM_LOCK_TABLE:-$DEFAULT_LOCK_TABLE}"
    
    echo "   State Bucket: $TERRAFORM_STATE_BUCKET"
    echo "   Lock Table: $TERRAFORM_LOCK_TABLE"
    echo "   State Key: ${ENVIRONMENT}/terraform.tfstate"
    echo ""
}

check_backend_resources_exist() {
    echo "🔍 Checking if backend resources exist..."
    
    local aws_cmd=$(get_aws_command)
    local bucket_exists=false
    local table_exists=false
    
    # Check if S3 bucket exists
    if $aws_cmd s3api head-bucket --bucket "$TERRAFORM_STATE_BUCKET" > /dev/null 2>&1; then
        echo "✅ S3 bucket exists: $TERRAFORM_STATE_BUCKET"
        bucket_exists=true
    else
        echo "⚠️  S3 bucket does not exist: $TERRAFORM_STATE_BUCKET"
    fi
    
    # Check if DynamoDB table exists
    if $aws_cmd dynamodb describe-table --table-name "$TERRAFORM_LOCK_TABLE" > /dev/null 2>&1; then
        echo "✅ DynamoDB table exists: $TERRAFORM_LOCK_TABLE"
        table_exists=true
    else
        echo "⚠️  DynamoDB table does not exist: $TERRAFORM_LOCK_TABLE"
    fi
    
    if [[ "$bucket_exists" == false ]] || [[ "$table_exists" == false ]]; then
        echo ""
        echo "💡 Backend resources missing. You can either:"
        echo "   1. Create them manually in AWS console"
        echo "   2. Use local state (not recommended for production)"
        echo "   3. Run Terraform with existing backend if resources exist with different names"
        return 1
    fi
    
    return 0
}

get_aws_command() {
    if [[ -n "$AWS_PROFILE" ]]; then
        echo "aws --profile $AWS_PROFILE"
    else
        echo "aws"
    fi
}

confirm_reset_operation() {
    echo ""
    echo "⚠️  WARNING: This will completely reset your Terraform state!"
    echo "📝 This operation will:"
    echo "   • Destroy all Terraform-managed resources"
    echo "   • Delete the remote state file from S3"
    echo "   • Remove state locks from DynamoDB"
    echo "   • Clean up local Terraform files"
    echo ""
    
    read -p "Are you absolutely sure you want to proceed? (type 'yes' to confirm): " -r
    echo ""
    
    if [[ ! "$REPLY" == "yes" ]]; then
        echo "❌ Reset operation cancelled"
        exit 0
    fi
}

initialize_terraform() {
    echo "🚀 Initializing Terraform..."
    
    if [[ ! -f "$SCRIPT_DIR/main.tf" ]]; then
        echo "❌ Terraform files not found in $SCRIPT_DIR"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    
    # Set AWS profile for Terraform if specified
    if [[ -n "$AWS_PROFILE" ]]; then
        export AWS_PROFILE="$AWS_PROFILE"
    fi
    
    setup_backend_variables
    
    if ! check_backend_resources_exist; then
        echo "⚠️  Backend resources not available, skipping Terraform operations"
        return 1
    fi
    
    # Initialize with backend configuration
    terraform init \
        -backend-config="bucket=${TERRAFORM_STATE_BUCKET}" \
        -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
        -backend-config="dynamodb_table=${TERRAFORM_LOCK_TABLE}" \
        -backend-config="region=${REGION}" \
        -reconfigure || {
        echo "⚠️  Terraform init failed, proceeding with manual cleanup..."
        return 1
    }
    
    echo "✅ Terraform initialized"
    return 0
}

destroy_terraform_resources() {
    echo "🗑️  Destroying Terraform-managed resources..."
    
    cd "$SCRIPT_DIR"
    
    if terraform destroy -auto-approve \
        -var="environment=${ENVIRONMENT}" \
        -var="app_version=cleanup" \
        -var="db_password=temporary"; then
        echo "✅ Resources destroyed successfully"
    else
        echo "⚠️  Some resources may not have been destroyed"
        echo "💡 Manual cleanup of AWS resources may be required"
    fi
}

cleanup_state_backend() {
    echo "🧹 Cleaning up Terraform state backend..."
    
    local state_bucket="${TERRAFORM_STATE_BUCKET}"
    local state_key="${ENVIRONMENT}/terraform.tfstate"
    local lock_table="${TERRAFORM_LOCK_TABLE}"
    local aws_cmd=$(get_aws_command)
    
    if [[ -z "$state_bucket" ]]; then
        echo "⚠️  TERRAFORM_STATE_BUCKET not set, skipping S3 cleanup"
        echo "💡 To cleanup manually:"
        echo "   export TERRAFORM_STATE_BUCKET=your-bucket-name"
        echo "   export TERRAFORM_LOCK_TABLE=your-lock-table"
    else
        echo "🗑️  Removing state file from S3: s3://${state_bucket}/${state_key}"
        $aws_cmd s3 rm "s3://${state_bucket}/${state_key}" 2>/dev/null || echo "ℹ️  State file not found in S3"
        
        echo "🗑️  Removing backup state file from S3"
        $aws_cmd s3 rm "s3://${state_bucket}/${state_key}.backup" 2>/dev/null || echo "ℹ️  Backup state file not found"
    fi
    
    if [[ -z "$lock_table" ]]; then
        echo "⚠️  TERRAFORM_LOCK_TABLE not set, skipping DynamoDB cleanup"
    else
        echo "🔓 Removing state lock from DynamoDB"
        $aws_cmd dynamodb delete-item \
            --table-name "$lock_table" \
            --key "{\"LockID\": {\"S\": \"${state_key}\"}}" 2>/dev/null || echo "ℹ️  No lock found in DynamoDB"
    fi
    
    echo "✅ Backend cleanup completed"
}

cleanup_local_terraform_files() {
    echo "🧹 Cleaning up local Terraform files..."
    
    cd "$SCRIPT_DIR"
    
    local cleanup_items=(
        ".terraform"
        ".terraform.lock.hcl"
        "terraform.tfstate"
        "terraform.tfstate.backup"
        "tfplan"
        "*.tfplan"
    )
    
    for item in "${cleanup_items[@]}"; do
        if [[ -e "$item" ]] || ls $item > /dev/null 2>&1; then
            echo "🗑️  Removing: $item"
            rm -rf $item
        fi
    done
    
    echo "✅ Local files cleaned"
}

verify_cleanup() {
    echo "🔍 Verifying cleanup completion..."
    
    cd "$SCRIPT_DIR"
    local aws_cmd=$(get_aws_command)
    
    # Check for remaining local files
    if [[ -d ".terraform" ]] || [[ -f "terraform.tfstate" ]]; then
        echo "⚠️  Some local Terraform files still exist"
    else
        echo "✅ Local cleanup verified"
    fi
    
    # Verify S3 state removal
    if [[ -n "$TERRAFORM_STATE_BUCKET" ]]; then
        if $aws_cmd s3 ls "s3://${TERRAFORM_STATE_BUCKET}/${ENVIRONMENT}/terraform.tfstate" > /dev/null 2>&1; then
            echo "⚠️  State file still exists in S3"
        else
            echo "✅ S3 state cleanup verified"
        fi
    fi
    
    echo "✅ Cleanup verification completed"
}

display_next_steps() {
    echo ""
    echo "🎉 Terraform state reset completed!"
    echo ""
    echo "📋 Next steps:"
    
    if [[ -n "$AWS_PROFILE" ]]; then
        echo "   1. Ensure SSO login: aws sso login --profile $AWS_PROFILE"
        echo "   2. Export profile: export AWS_PROFILE=$AWS_PROFILE"
    else
        echo "   1. Set AWS profile: export AWS_PROFILE=Team-Account-Standard-365309403645"
        echo "   2. Login to SSO: aws sso login --profile \$AWS_PROFILE"
    fi
    
    echo "   3. Set backend variables:"
    echo "      export TERRAFORM_STATE_BUCKET=$TERRAFORM_STATE_BUCKET"
    echo "      export TERRAFORM_LOCK_TABLE=$TERRAFORM_LOCK_TABLE"
    echo "   4. Run 'terraform init' to reinitialize"
    echo "   5. Run 'terraform plan' to see fresh infrastructure plan"
    echo "   6. Run 'terraform apply' to deploy from scratch"
    echo ""
    echo "💡 Quick start command:"
    if [[ -n "$AWS_PROFILE" ]]; then
        echo "   AWS_PROFILE=$AWS_PROFILE terraform init"
    else
        echo "   AWS_PROFILE=Team-Account-Standard-365309403645 terraform init"
    fi
    echo ""
    echo "🔧 Alternative: Use the GitHub Actions workflow with 'force_unlock: true'"
}

main() {
    validate_environment
    check_prerequisites
    confirm_reset_operation
    
    echo "🔄 Starting Terraform state reset..."
    echo ""
    
    # Try to destroy resources first (if Terraform is functional)
    if initialize_terraform; then
        destroy_terraform_resources
        echo ""
    fi
    
    cleanup_state_backend
    echo ""
    
    cleanup_local_terraform_files
    echo ""
    
    verify_cleanup
    
    display_next_steps
}

# Execute main function with all arguments
main "$@"
