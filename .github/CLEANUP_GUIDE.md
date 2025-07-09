# AWS Resource Cleanup Guide

This guide explains how to clean up AWS resources when deployments fail or when you need to remove infrastructure.

## 🚨 Why Cleanup is Important

When the GitHub Actions deployment fails, AWS resources (EC2 instances, VPC, security groups, etc.) may remain running and continue to incur costs. It's crucial to clean them up promptly.

## 🛠️ Cleanup Methods

### Method 1: Automatic Cleanup (Preferred)

The deployment workflow now includes automatic cleanup on failure:

1. **When deployment fails**, the `cleanup-on-failure` job automatically runs
2. **Executes `terraform destroy`** to remove all created resources
3. **Provides cleanup summary** in the GitHub Actions summary

**How it works:**
- Triggers only when the `deploy` job fails
- Uses the same Terraform state to ensure complete cleanup
- Runs with `continue-on-error: true` to handle partial failures

### Method 2: Manual GitHub Actions Cleanup

Use the manual cleanup workflow for interactive cleanup:

1. Go to **Actions** tab in your GitHub repository
2. Select **"Manual AWS Cleanup"** workflow
3. Click **"Run workflow"**
4. Choose the environment (`staging` or `production`)
5. Type **`DESTROY`** in the confirmation field
6. Click **"Run workflow"**

**Features:**
- Lists resources before cleanup
- Runs Terraform destroy
- Performs manual cleanup of remaining resources
- Verifies cleanup completion
- Provides detailed summary

### Method 3: Local Script Cleanup

Use the local cleanup script for command-line cleanup:

```bash
# Navigate to your project
cd /path/to/foodme

# Make script executable (if not already)
chmod +x .github/cleanup-failed-deployment.sh

# Run cleanup for staging
./.github/cleanup-failed-deployment.sh staging

# Run cleanup for production
./.github/cleanup-failed-deployment.sh production

# Show help
./.github/cleanup-failed-deployment.sh --help
```

**Script features:**
- Attempts Terraform cleanup first
- Falls back to manual AWS CLI cleanup
- Cleans up EC2, security groups, IAM roles, and key pairs
- Shows remaining resources after cleanup
- Detailed progress output

### Method 4: Manual AWS Console Cleanup

If automated methods fail, clean up manually:

1. **EC2 Instances:**
   - Go to EC2 Console → Instances
   - Filter by tag: `Application = FoodMe`
   - Select instances and terminate

2. **Security Groups:**
   - Go to EC2 Console → Security Groups
   - Filter by name: `foodme-*`
   - Delete security groups (after terminating instances)

3. **VPC Resources:**
   - Go to VPC Console
   - Check for FoodMe-related subnets, route tables, internet gateways
   - Delete in order: subnets → route tables → internet gateway → VPC

4. **IAM Resources:**
   - Go to IAM Console → Roles
   - Filter by name: `foodme-*`
   - Delete instance profiles and roles

5. **Key Pairs:**
   - Go to EC2 Console → Key Pairs
   - Filter by name: `foodme-*`
   - Delete key pairs

## 🔍 Troubleshooting Cleanup Issues

### Terraform Destroy Fails

**Symptoms:**
- Terraform destroy returns errors
- Some resources remain after cleanup

**Solutions:**
1. Check if resources have dependencies
2. Run cleanup script for manual AWS CLI cleanup
3. Use AWS console for stubborn resources

**Common dependency issues:**
- Security groups attached to running instances
- Subnets with network interfaces
- IAM roles attached to instance profiles

### Resources Still Showing After Cleanup

**Possible causes:**
- AWS eventual consistency delays
- Resources in different regions
- Manual resources not created by Terraform

**Solutions:**
1. Wait 5-10 minutes and check again
2. Verify you're checking the correct AWS region
3. Use the verification commands in cleanup script

### Permission Errors During Cleanup

**Symptoms:**
- "Access Denied" errors
- "User is not authorized" messages

**Solutions:**
1. Verify AWS credentials have proper permissions
2. Check IAM policies include destroy permissions
3. Ensure you're using the correct AWS profile/region

## 📊 Verification Commands

After cleanup, verify all resources are removed:

```bash
# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Application,Values=FoodMe" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]" \
  --output table

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=foodme-*" \
  --query "SecurityGroups[].[GroupId,GroupName]" \
  --output table

# Check VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=foodme-*" \
  --query "Vpcs[].[VpcId,Tags[?Key=='Name'].Value|[0]]" \
  --output table

# Check IAM roles
aws iam list-roles \
  --query "Roles[?starts_with(RoleName, 'foodme-')].[RoleName,Arn]" \
  --output table
```

## 💰 Cost Monitoring

To avoid unexpected costs:

1. **Set up AWS billing alerts**
2. **Monitor AWS Cost Explorer** for FoodMe-related costs
3. **Run cleanup verification** after each failed deployment
4. **Consider using AWS Budget alerts** for specific services

## 🔧 Prevention Tips

To minimize cleanup needs:

1. **Test deployments in staging** before production
2. **Monitor GitHub Actions** for early failure detection
3. **Use shorter timeout values** to fail fast
4. **Regular cleanup runs** as part of maintenance

## 📞 Emergency Cleanup

If you need immediate cleanup due to cost concerns:

1. **Terminate all EC2 instances** immediately via AWS console
2. **Run the manual cleanup script** to handle other resources
3. **Check billing dashboard** to confirm charges stop accumulating
4. **File AWS support ticket** if you see unexpected charges

## 🚀 Next Steps

After cleanup:

1. **Investigate the deployment failure** cause
2. **Fix the underlying issue** (networking, configuration, etc.)
3. **Test the fix** before running full deployment
4. **Monitor the next deployment** closely

## 📞 Getting Help

If cleanup issues persist:

1. Check the [main troubleshooting guide](../TROUBLESHOOTING.md)
2. Review the [EC2 setup guide](../terraform/EC2_KEYPAIR_SETUP.md)
3. Check [GitHub Actions permissions guide](./GITHUB_ACTIONS_PERMISSIONS.md) for workflow issues
4. Examine AWS CloudWatch logs for the instance
5. Consider using the alternative deployment methods mentioned above
