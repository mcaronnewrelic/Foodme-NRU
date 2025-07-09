# IAM Role Conflict Resolution Guide

This guide helps you resolve the "EntityAlreadyExists" error when deploying with Terraform.

## Error Description

```
Error: creating IAM Role (foodme-staging-ec2-role): operation error IAM: CreateRole, 
https response error StatusCode: 409, RequestID: ..., EntityAlreadyExists: 
Role with name foodme-staging-ec2-role already exists.
```

## Root Cause

This error occurs when:
1. An IAM role with the same name already exists in your AWS account
2. Terraform state doesn't know about the existing role (usually from previous failed deployments)
3. You're trying to create resources that conflict with existing ones

## Solutions

### Solution 1: Use Random Suffixes (Implemented)

The Terraform configuration has been updated to automatically append random suffixes to resource names to avoid conflicts:

- IAM Role: `foodme-staging-ec2-role-a1b2c3d4`
- IAM Policy: `foodme-staging-ec2-policy-a1b2c3d4`
- Instance Profile: `foodme-staging-ec2-profile-a1b2c3d4`

**Action Required:** Simply re-run your GitHub Actions workflow. The random suffixes will prevent naming conflicts.

### Solution 2: Clean Up Existing Resources

If you want to use the exact names without suffixes, clean up the existing resources:

```bash
cd terraform
./cleanup-iam.sh
```

This script will:
- List existing FoodMe IAM resources
- Ask for confirmation before deletion
- Remove conflicting resources in the correct order

### Solution 3: Manual AWS Console Cleanup

1. Go to AWS IAM Console
2. Delete in this order:
   - **Instance Profiles** → `foodme-staging-ec2-profile`
   - **Roles** → `foodme-staging-ec2-role` (delete attached policies first)

### Solution 4: Import Existing Resources

If you want to keep existing resources, import them into Terraform state:

```bash
# Import the role
terraform import aws_iam_role.foodme_ec2 foodme-staging-ec2-role

# Import the instance profile
terraform import aws_iam_instance_profile.foodme_ec2 foodme-staging-ec2-profile
```

## Prevention

To prevent this issue in the future:

1. **Use the random suffix approach** (already implemented)
2. **Always run `terraform destroy`** when testing is complete
3. **Use different environments** with unique names (dev, staging, prod)
4. **Store Terraform state remotely** (S3 + DynamoDB) for team collaboration

## Verification

After applying any solution, verify the deployment works:

```bash
# Check if resources were created successfully
aws iam list-roles --query "Roles[?contains(RoleName, 'foodme')]"
aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, 'foodme')]"
```

## Configuration Changes Made

The following files have been updated to resolve this issue:

1. **`infrastructure.tf`** - Added random ID resource and suffix to IAM resource names
2. **`cleanup-iam.sh`** - New script to clean up conflicting resources
3. **This guide** - Documentation for troubleshooting

The random suffix approach is the recommended solution as it allows multiple deployments without conflicts while maintaining clean resource management.
