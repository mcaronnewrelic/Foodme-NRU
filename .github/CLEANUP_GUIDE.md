# AWS Resource Cleanup Guide

This guide explains how to clean up AWS resources when deployments fail or when you need to remove infrastructure.

## 🚨 Why Cleanup is Important

When GitHub Actions deployment fails, AWS resources (EC2 instances, VPC, security groups, etc.) may remain running and continue to incur costs. Clean them up promptly to avoid unnecessary charges.

## 🛠️ Cleanup Methods

### Method 1: Automatic Cleanup (Current Implementation)

The `deploy VM.yml` workflow includes automatic cleanup on failure:

1. **Triggers automatically** when `deploy-infrastructure` job fails
2. **Executes `terraform destroy`** to remove all created resources  
3. **Uses same backend state** to ensure complete cleanup

**How it works:**
```yaml
cleanup-failed-deployment:
  runs-on: ubuntu-latest
  needs: [deploy-infrastructure]
  if: failure() && needs.deploy-infrastructure.result == 'failure'
```

### Method 2: Manual Terraform Cleanup

Use Terraform directly for manual cleanup:

```bash
# Navigate to terraform directory
cd terraform

# Initialize with correct backend
terraform init \
  -backend-config="bucket=YOUR_STATE_BUCKET" \
  -backend-config="key=staging/terraform.tfstate" \
  -backend-config="dynamodb_table=YOUR_LOCK_TABLE" \
  -backend-config="region=us-west-2"

# Destroy resources
terraform destroy \
  -var="environment=staging" \
  -var="app_version=latest"
```

### Method 3: Manual AWS Console Cleanup

If Terraform cleanup fails, clean up manually:

1. **EC2 Instances:**
   - Go to EC2 Console → Instances
   - Filter by tag: `Environment = staging/production`
   - Select instances and terminate

2. **Security Groups:**
   - Go to EC2 Console → Security Groups  
   - Filter by name: `foodme-*`
   - Delete after terminating instances

3. **VPC Resources:**
   - Delete in order: Subnets → Route Tables → Internet Gateway → VPC
   - Look for resources tagged with `Project = FoodMe`

4. **IAM Resources:**
   - Go to IAM Console → Roles
   - Delete roles matching: `foodme-*-ec2-role`
   - Delete instance profiles: `foodme-*-ec2-profile`

## 🔍 Verification Commands

Verify cleanup completion:

```bash
# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=FoodMe" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key=='Environment'].Value|[0]]" \
  --output table

# Check security groups  
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=foodme-*" \
  --query "SecurityGroups[].[GroupId,GroupName]" \
  --output table

# Check IAM roles
aws iam list-roles \
  --query "Roles[?starts_with(RoleName, 'foodme-')].[RoleName,CreateDate]" \
  --output table

# Check VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=FoodMe" \
  --query "Vpcs[].[VpcId,State,Tags[?Key=='Environment'].Value|[0]]" \
  --output table
```

## 🔧 Troubleshooting Cleanup Issues

### Terraform State Lock Issues

**Symptoms:** "Error acquiring the state lock"

**Solution:**
```bash
# Check for existing locks
aws dynamodb scan \
  --table-name YOUR_LOCK_TABLE \
  --query "Items[].LockID.S"

# Force unlock if needed (use with caution)
terraform force-unlock LOCK_ID
```

### Dependency Errors

**Common issues:**
- Security groups attached to running instances
- Network interfaces preventing subnet deletion
- IAM roles attached to instance profiles

**Solution:** Follow dependency order in manual cleanup

### Permission Errors

**Symptoms:** Access denied during destroy

**Solution:**
- Verify AWS credentials have destroy permissions
- Check IAM policies include EC2, VPC, and IAM permissions
- Ensure correct AWS region (us-west-2)

## 💰 Cost Monitoring

Prevent unexpected costs:

1. **Monitor EC2 instances** - Most expensive resource
2. **Set up billing alerts** for unusual spending  
3. **Regular verification** after deployments
4. **Use AWS Cost Explorer** to track FoodMe-related costs

## 🚀 Prevention Best Practices

Minimize cleanup needs:

1. **Test in staging first** before production deployments
2. **Monitor deployment logs** for early failure detection
3. **Use infrastructure validation** before apply
4. **Set appropriate timeouts** to fail fast

## 📞 Emergency Cleanup

For immediate cost control:

1. **Terminate EC2 instances** via AWS Console (immediate cost savings)
2. **Run verification commands** to identify remaining resources
3. **Use manual console cleanup** for stubborn resources
4. **Check billing dashboard** to confirm cost reduction

## 🔄 Current Workflow Integration

The cleanup is integrated into:
- `deploy VM.yml` - Infrastructure deployment with automatic cleanup
- `deploy app.yml` - Application deployment (no infrastructure cleanup needed)

**Note:** Application deployment failures don't require infrastructure cleanup since they don't create AWS resources.
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
