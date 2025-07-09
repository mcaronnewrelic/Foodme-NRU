# VPC Limit Exceeded Resolution Guide

This guide helps you resolve the "VpcLimitExceeded" error in your AWS EC2 deployment.

## Error Description

```
Error: creating EC2 VPC: operation error EC2: CreateVpc, https response error 
StatusCode: 400, RequestID: ..., api error VpcLimitExceeded: 
The maximum number of VPCs has been reached.
```

## Root Cause

AWS has a default limit of **5 VPCs per region**. This error occurs when:
1. You already have 5 VPCs in the region
2. Previous Terraform deployments created VPCs but didn't clean them up properly
3. You have other projects using VPCs in the same region

## Quick Solutions

### Solution 1: Use Default VPC (Recommended for Testing)

**Fastest fix - takes 30 seconds:**

```bash
cd terraform
./use-default-vpc.sh
```

This script will:
- Configure Terraform to use your default VPC instead of creating a new one
- Generate a `terraform.tfvars` file with the correct settings
- Allow deployment to proceed immediately

### Solution 2: Clean Up Unused VPCs

**If you want to create a new VPC:**

```bash
cd terraform
./cleanup-vpcs.sh
```

This script will:
- List all VPCs in your region
- Identify unused FoodMe VPCs
- Safely delete VPCs and their dependencies
- Free up space for new VPC creation

### Solution 3: Manual VPC Cleanup

1. **List current VPCs:**
   ```bash
   aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[*].{VpcId:VpcId,Name:Tags[?Key==`Name`].Value|[0],IsDefault:IsDefault}' --output table
   ```

2. **Find unused FoodMe VPCs:**
   ```bash
   aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=*foodme*" --query 'Vpcs[*].VpcId' --output text
   ```

3. **Delete VPC via AWS Console:**
   - Go to AWS VPC Console
   - Select unused VPC
   - Delete associated resources first (subnets, internet gateways, route tables)
   - Delete the VPC

## Implementation Details

### Using Default VPC

The Terraform configuration now supports using existing VPCs via these variables:

```hcl
use_existing_vpc = true
existing_vpc_id = "vpc-xxxxxxxxx"
existing_public_subnet_id = "subnet-xxxxxxxxx"
existing_private_subnet_id = "subnet-yyyyyyyyy"  # optional
```

**Benefits:**
- ✅ No VPC limit issues
- ✅ Faster deployment
- ✅ Uses AWS-managed infrastructure
- ✅ Good for testing/staging

**Considerations:**
- ⚠️ Shares VPC with other default resources
- ⚠️ Less network isolation
- ⚠️ Default security group rules apply

### Creating New VPC

When `use_existing_vpc = false` (default), Terraform creates:
- New VPC with random suffix (`foodme-staging-vpc-a1b2c3d4`)
- Public and private subnets
- Internet gateway and route tables
- Custom security groups

**Benefits:**
- ✅ Complete network isolation
- ✅ Custom CIDR blocks
- ✅ Full control over networking
- ✅ Better for production

## Alternative Solutions

### Option A: Request VPC Limit Increase

1. Go to AWS Support Center
2. Create a new case
3. Request VPC limit increase for your region
4. Usually approved within 24-48 hours

### Option B: Use Different Region

Change the region in your workflow:

```yaml
env:
  AWS_REGION: us-west-2  # Instead of us-east-1
```

Update Terraform variables:

```hcl
aws_region = "us-west-2"
```

### Option C: Use Existing Infrastructure

If you have existing VPCs from other projects:

```bash
# List all VPCs
aws ec2 describe-vpcs --region us-east-1

# Use an existing VPC ID
echo 'use_existing_vpc = true' >> terraform.tfvars
echo 'existing_vpc_id = "vpc-your-existing-id"' >> terraform.tfvars
echo 'existing_public_subnet_id = "subnet-your-subnet-id"' >> terraform.tfvars
```

## Verification

After applying any solution, verify it works:

```bash
# Check VPC count
aws ec2 describe-vpcs --region us-east-1 --query 'length(Vpcs)'

# Test Terraform plan
cd terraform
terraform plan

# Verify default VPC configuration
aws ec2 describe-vpcs --region us-east-1 --filters "Name=isDefault,Values=true"
```

## Prevention

To avoid this issue in the future:

1. **Always run `terraform destroy`** after testing
2. **Use different environments** with unique names
3. **Monitor VPC usage** regularly
4. **Consider using default VPC** for non-production workloads
5. **Set up remote state** to prevent state file conflicts

## Configuration Files

### Generated terraform.tfvars (Default VPC)
```hcl
use_existing_vpc = true
existing_vpc_id = "vpc-default-id"
existing_public_subnet_id = "subnet-default-id"
aws_region = "us-east-1"
environment = "staging"
```

### Manual terraform.tfvars (New VPC)
```hcl
use_existing_vpc = false
aws_region = "us-east-1"
environment = "staging"
# Will create new VPC with random suffix
```

## Troubleshooting

### Still getting VPC limit errors?
- Verify you have fewer than 5 VPCs: `aws ec2 describe-vpcs --region us-east-1 --query 'length(Vpcs)'`
- Check if cleanup scripts removed VPCs successfully
- Ensure you're using the correct region

### Default VPC not found?
- Some regions don't have default VPCs
- Create one: `aws ec2 create-default-vpc --region us-east-1`
- Or use an existing VPC from another project

### Terraform still creating new VPC?
- Verify `terraform.tfvars` exists and contains correct settings
- Check `use_existing_vpc = true` is set
- Run `terraform plan` to see what will be created

## Getting Help

If none of these solutions work:
1. Check AWS Service Health Dashboard
2. Verify your AWS CLI credentials and region
3. Contact AWS Support for account-specific issues
4. Consider using Infrastructure as Code best practices for better resource management
