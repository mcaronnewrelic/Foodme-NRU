# SSH Setup Troubleshooting Guide

This guide helps you resolve SSH-related issues in the GitHub Actions deployment workflow.

## Common SSH Errors

### 1. "Process completed with exit code 1" during SSH setup

**Cause:** Usually indicates that the `EC2_PRIVATE_KEY` secret is not set or is empty.

**Solutions:**

#### Option A: Create and Setup SSH Key (Recommended)

1. **Create a new key pair:**
   ```bash
   cd terraform
   ./create-keypair.sh
   ```

2. **Add GitHub secrets:**
   - Go to your GitHub repository → Settings → Secrets and variables → Actions
   - Add these secrets:
     - `EC2_KEY_NAME`: `foodme-deploy-key`
     - `EC2_PRIVATE_KEY`: Copy the full content from `~/.ssh/foodme-deploy-key.pem`

3. **Get the private key content:**
   ```bash
   cat ~/.ssh/foodme-deploy-key.pem
   ```
   Copy the entire output (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines)

#### Option B: Deploy Without SSH (Alternative)

The workflow is now configured to work without SSH access:
- Don't set the `EC2_PRIVATE_KEY` secret
- The deployment will rely on the `user_data.sh` script
- Application files will be deployed via the EC2 user data script

### 2. SSH Connection Refused

**Error:** `ssh: connect to host X.X.X.X port 22: Connection refused`

**Solutions:**
- Check security group allows SSH (port 22) from GitHub Actions runner IPs
- Verify the EC2 instance is fully booted (wait longer)
- Ensure the key pair name matches what's configured in Terraform

### 3. SSH Permission Denied

**Error:** `Permission denied (publickey)`

**Solutions:**
- Verify the private key content is correct in GitHub secrets
- Check that the key pair exists in AWS and matches the secret
- Ensure the private key has correct format (begins with `-----BEGIN`)

## GitHub Secrets Required

### With SSH Deployment:
- `AWS_ACCESS_KEY_ID` ✅
- `AWS_SECRET_ACCESS_KEY` ✅  
- `EC2_KEY_NAME` ✅ (e.g., "foodme-deploy-key")
- `EC2_PRIVATE_KEY` ✅ (full private key content)
- `ALLOWED_CIDR_BLOCKS` ✅ (e.g., '["0.0.0.0/0"]')
- `NEW_RELIC_API_KEY` (optional)

### Without SSH Deployment:
- `AWS_ACCESS_KEY_ID` ✅
- `AWS_SECRET_ACCESS_KEY` ✅
- `ALLOWED_CIDR_BLOCKS` ✅
- `NEW_RELIC_API_KEY` (optional)

## Workflow Behavior

### With SSH Key Available:
1. ✅ Creates EC2 instance with key pair
2. ✅ Sets up SSH connection
3. ✅ Deploys application files via SCP/SSH
4. ✅ Runs health checks

### Without SSH Key:
1. ✅ Creates EC2 instance without key pair
2. ⏭️ Skips SSH setup (shows notice message)
3. ⏭️ Skips file upload (relies on user_data script)
4. ✅ Runs health checks (with longer wait time)

## Verification Steps

### Check GitHub Secrets:
1. Go to repository → Settings → Secrets and variables → Actions
2. Verify all required secrets are present
3. Check that `EC2_PRIVATE_KEY` contains the full key (if using SSH)

### Test Key Pair Locally:
```bash
# Test AWS CLI access
aws sts get-caller-identity

# Verify key pair exists
aws ec2 describe-key-pairs --region us-west-2

# Test SSH key format
ssh-keygen -l -f ~/.ssh/foodme-deploy-key.pem
```

### Debug EC2 Instance:
If health checks fail, check the instance logs:
```bash
# Get instance ID from Terraform output
cd terraform
terraform output instance_id

# View instance logs (requires AWS CLI)
aws ec2 get-console-output --instance-id i-1234567890abcdef0 --region us-west-2
```

## Alternative: AWS Systems Manager

For production deployments, consider using AWS Systems Manager Session Manager instead of SSH:

**Benefits:**
- No SSH keys required
- Better security and audit logging
- Works through IAM permissions
- No need to open SSH ports

**Implementation:**
This would require modifying the deployment strategy to use `aws ssm start-session` and the SSM agent instead of SSH.

## Quick Fixes

### Fix 1: Missing EC2_PRIVATE_KEY
```bash
cd terraform
./create-keypair.sh
# Follow the instructions to add secrets to GitHub
```

### Fix 2: Wrong Key Format
Make sure the GitHub secret includes the full key:
```
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...
-----END PRIVATE KEY-----
```

### Fix 3: Deploy Without SSH
Simply don't set the `EC2_PRIVATE_KEY` secret and the workflow will adapt automatically.

## Getting Help

If you continue to have issues:
1. Check the GitHub Actions logs for specific error messages
2. Verify all secrets are correctly set
3. Test the key pair creation script locally
4. Consider using the no-SSH deployment option for simpler setup
