# EC2 Key Pair Setup Guide

This guide helps you resolve the "InvalidKeyPair.NotFound" error in your GitHub Actions deployment.

## Quick Fix

### Option 1: Create a New Key Pair (Recommended)

1. **Run the key pair creation script:**
   ```bash
   cd terraform
   ./create-keypair.sh
   ```

2. **Add GitHub Secrets:**
   Go to your GitHub repository → Settings → Secrets and variables → Actions
   
   Add these secrets:
   - `EC2_KEY_NAME`: `foodme-deploy-key`
   - `EC2_PRIVATE_KEY`: Copy the content from `~/.ssh/foodme-deploy-key.pem`

3. **Get the private key content:**
   ```bash
   cat ~/.ssh/foodme-deploy-key.pem
   ```
   Copy this entire content (including BEGIN/END lines) into the `EC2_PRIVATE_KEY` secret.

### Option 2: Use Existing Key Pair

If you already have a key pair in AWS:

1. **List existing key pairs:**
   ```bash
   aws ec2 describe-key-pairs --region us-west-2
   ```

2. **Update GitHub secrets:**
   - `EC2_KEY_NAME`: Use the name of your existing key pair
   - `EC2_PRIVATE_KEY`: The private key content for that key pair

### Option 3: Deploy Without SSH Access

If you don't need SSH access, the Terraform configuration has been updated to make the key pair optional:

1. **Remove or leave empty the GitHub secret:**
   - `EC2_KEY_NAME`: (leave empty or don't set)

2. **Update the workflow** to skip SSH-related deployment steps if needed.

## Troubleshooting

### Check AWS CLI Configuration
```bash
aws sts get-caller-identity
aws ec2 describe-key-pairs --region us-west-2
```

### Verify GitHub Secrets
Ensure these secrets are set in your repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_KEY_NAME`
- `EC2_PRIVATE_KEY` (if using SSH)
- `ALLOWED_CIDR_BLOCKS`

### Test Key Pair Creation Manually
```bash
# Create key pair
aws ec2 create-key-pair \
    --key-name foodme-deploy-key \
    --region us-west-2 \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/foodme-deploy-key.pem

# Set permissions
chmod 600 ~/.ssh/foodme-deploy-key.pem

# Verify it was created
aws ec2 describe-key-pairs --key-names foodme-deploy-key --region us-west-2
```

### Delete and Recreate Key Pair
```bash
# Delete existing key pair (if needed)
aws ec2 delete-key-pair --key-name foodme-deploy-key --region us-west-2

# Then run the creation script again
./create-keypair.sh
```

## Security Notes

- The private key file should never be committed to git
- Keep the private key secure and only share through GitHub secrets
- Use restrictive CIDR blocks for SSH access when possible
- Consider using AWS Systems Manager Session Manager instead of SSH for production

## Alternative: AWS Systems Manager

For production deployments, consider using AWS Systems Manager Session Manager instead of SSH:

1. No need for key pairs
2. Better audit logging
3. No need to open SSH ports
4. Works through IAM permissions

This would require modifying the deployment strategy to use `aws ssm start-session` instead of SSH.
