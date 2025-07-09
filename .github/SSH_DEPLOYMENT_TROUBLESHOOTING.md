# SSH Deployment Troubleshooting Guide

This guide helps troubleshoot SSH-related issues in the GitHub Actions CI/CD pipeline.

## Common SSH Issues and Solutions

### 1. SSH Key Setup Fails with Exit Code 1

**Symptoms:**
- GitHub Actions shows "❌ Failed to create SSH private key file" or similar
- SSH key validation fails
- Key content appears as `***` in logs

**Causes:**
- SSH private key secret is not properly formatted
- Key contains extra whitespace or characters
- Key is missing BEGIN/END markers

**Solutions:**

#### A. Verify Key Format in GitHub Secret
1. Your `EC2_PRIVATE_KEY` secret should look exactly like:
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7...
(multiple lines of base64 content)
...ending with the last line of base64
-----END PRIVATE KEY-----
```

2. **Do NOT include:**
   - Extra blank lines at the beginning or end
   - Windows line endings (use LF, not CRLF)
   - Spaces or tabs before/after the key content
   - Any additional text or comments

#### B. Recreate the Key Pair
```bash
cd terraform
./create-keypair.sh
```
This will create a properly formatted key and show you exactly what to copy.

#### C. Manual Key Verification
Test your key locally before adding to GitHub:
```bash
# Save your key to a test file
echo "YOUR_KEY_CONTENT" > test_key.pem
chmod 600 test_key.pem

# Verify it's valid
ssh-keygen -l -f test_key.pem

# Clean up
rm test_key.pem
```

### 2. SSH Connection Timeouts

**Symptoms:**
- "Connection timed out" errors
- SSH port checks fail
- Instance appears to be running but unreachable

**Causes:**
- Security group doesn't allow SSH (port 22)
- Instance is still starting up
- Network connectivity issues

**Solutions:**

#### A. Check Security Group Rules
```bash
# Get security group ID from Terraform output
cd terraform
terraform output security_group_id

# Check rules (replace sg-xxx with actual ID)
aws ec2 describe-security-groups --group-ids sg-xxx
```

#### B. Verify Instance Status
```bash
# Get instance ID from Terraform
cd terraform
INSTANCE_ID=$(terraform output -raw instance_id)

# Check instance status
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID

# Check system log for startup issues
aws ec2 get-console-output --instance-id $INSTANCE_ID
```

#### C. Manual SSH Test
```bash
# Get instance IP
cd terraform
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Test SSH connection
ssh -i path/to/your/key.pem ec2-user@$INSTANCE_IP
```

### 3. Permission Denied Errors

**Symptoms:**
- "Permission denied (publickey)" errors
- SSH connects but authentication fails

**Causes:**
- Wrong username (should be `ec2-user` for Amazon Linux)
- Key doesn't match the EC2 key pair
- Key permissions are incorrect

**Solutions:**

#### A. Verify Username
For Amazon Linux 2023, always use `ec2-user`:
```bash
ssh -i key.pem ec2-user@INSTANCE_IP
```

#### B. Check Key Pair Match
```bash
# Get the key name used by Terraform
cd terraform
terraform output key_pair_name

# Verify this matches your AWS key pair
aws ec2 describe-key-pairs --key-names "your-key-name"
```

#### C. Verify Key Permissions
```bash
chmod 600 ~/.ssh/id_rsa  # or your key file
```

### 4. File Transfer Issues

**Symptoms:**
- SCP commands fail
- Files don't upload correctly
- Permission errors during deployment

**Solutions:**

#### A. Test SCP Manually
```bash
# Test uploading a single file
scp -i key.pem test.txt ec2-user@INSTANCE_IP:/tmp/

# Test with verbose output for debugging
scp -v -i key.pem test.txt ec2-user@INSTANCE_IP:/tmp/
```

#### B. Check Disk Space
```bash
ssh -i key.pem ec2-user@INSTANCE_IP "df -h"
```

#### C. Verify Target Directory Permissions
```bash
ssh -i key.pem ec2-user@INSTANCE_IP "ls -la /var/www/"
```

## Debugging Steps

### 1. Enable Verbose SSH Output
Add `-v` or `-vv` to SSH commands for detailed debugging:
```bash
ssh -vv -i key.pem ec2-user@INSTANCE_IP
```

### 2. Check GitHub Actions Logs
Look for these specific error messages:
- Key format validation failures
- Connection timeout details
- Permission denied reasons

### 3. Verify AWS Resources
```bash
cd terraform

# Check all outputs
terraform output

# Verify security group allows SSH
terraform show | grep -A 10 -B 2 "port.*22"

# Check instance state
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

### 4. Test Without GitHub Actions
Run the deployment steps manually to isolate issues:
```bash
# 1. Get instance details
cd terraform
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# 2. Test SSH connection
ssh -i your-key.pem ec2-user@$INSTANCE_IP

# 3. Test file upload
scp -i your-key.pem some-file.txt ec2-user@$INSTANCE_IP:/tmp/

# 4. Test service restart
ssh -i your-key.pem ec2-user@$INSTANCE_IP "sudo systemctl status nginx"
```

## Alternative Deployment Methods

If SSH continues to fail, consider these alternatives:

### 1. Use AWS Systems Manager Session Manager
- No SSH keys required
- Works through AWS APIs
- Requires EC2 instance profile with proper permissions

### 2. Use CodeDeploy
- AWS native deployment service
- Integrates with GitHub Actions
- More complex setup but more robust

### 3. Use User Data Script Only
- Deploy application code via S3 and user data
- No SSH required during CI/CD
- Application updates require instance replacement

## Prevention Tips

1. **Always test SSH keys locally** before adding to GitHub Secrets
2. **Use the `create-keypair.sh` script** for consistent key generation
3. **Verify security group rules** in Terraform before applying
4. **Monitor instance startup logs** for early problem detection
5. **Test the complete deployment flow** in a development environment first

## Getting Help

If issues persist:

1. Check the [main troubleshooting guide](../TROUBLESHOOTING.md)
2. Review the [EC2 setup guide](../terraform/EC2_KEYPAIR_SETUP.md)
3. Examine AWS CloudWatch logs for the instance
4. Consider using the alternative deployment methods mentioned above
