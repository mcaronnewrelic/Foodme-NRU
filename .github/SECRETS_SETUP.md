# GitHub Secrets Setup for EC2 Deployment

This guide explains how to configure GitHub repository secrets for automated deployment to AWS EC2.

## 🔑 Required Secrets

Configure these secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

### AWS Credentials

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

### EC2 Configuration

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `EC2_KEY_NAME` | AWS key pair name | `my-foodme-keypair` |
| `EC2_PRIVATE_KEY` | Private key content | `-----BEGIN RSA PRIVATE KEY-----\n...` |
| `ALLOWED_CIDR_BLOCKS` | IP ranges allowed to access | `["123.456.789.0/32"]` |

### Application Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `NEW_RELIC_API_KEY` | New Relic User API Key | `NRAK-XXXXXXXXXXXXXXXX` |

## 🚀 Setup Instructions

### 1. Create AWS IAM User

Create an IAM user with the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "iam:GetRole",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:PassRole"
            ],
            "Resource": "*"
        }
    ]
}
```

### 2. Create EC2 Key Pair

#### Option A: Using AWS CLI
```bash
# Create a new key pair
aws ec2 create-key-pair --key-name my-foodme-keypair --output text --query 'KeyMaterial' > my-foodme-keypair.pem

# Set proper permissions
chmod 600 my-foodme-keypair.pem
```

#### Option B: Using our helper script (Recommended)
```bash
cd terraform
./create-keypair.sh
```

**⚠️ Important: EC2_PRIVATE_KEY Format**

When copying the private key to GitHub Secrets, ensure it's in this exact format:

```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7...
(multiple lines of base64-encoded key data)
...
-----END PRIVATE KEY-----
```

**Common Issues to Avoid:**
- ❌ No extra blank lines at the beginning or end
- ❌ No spaces or tabs before the key content
- ❌ No Windows line endings (CRLF) - use Unix line endings (LF)
- ❌ No additional text or comments
- ✅ Copy the entire key including BEGIN and END lines
- ✅ Ensure each line ends properly without extra characters

### 3. Configure GitHub Secrets

Go to your repository settings:

1. Navigate to `Settings` → `Secrets and variables` → `Actions`
2. Click `New repository secret`
3. Add each secret from the table above

### 4. Get Your IP Address

For security, restrict access to your IP:

```bash
# Get your public IP
curl -s https://checkip.amazonaws.com/

# Add to ALLOWED_CIDR_BLOCKS as ["YOUR_IP/32"]
```

## 🔒 Security Best Practices

### IAM User Permissions

- Create a dedicated IAM user for GitHub Actions
- Use the principle of least privilege
- Regularly rotate access keys
- Enable CloudTrail for audit logging

### Key Management

- Store private keys securely in GitHub Secrets
- Never commit private keys to the repository
- Use different key pairs for different environments
- Regularly rotate EC2 key pairs

### Network Security

- Limit `ALLOWED_CIDR_BLOCKS` to your IP ranges
- Use VPN or bastion hosts for production access
- Enable AWS VPC Flow Logs for monitoring
- Consider using AWS Systems Manager Session Manager

## 🧪 Testing the Setup

1. **Validate AWS credentials**:
   ```bash
   aws sts get-caller-identity
   ```

2. **Test key pair**:
   ```bash
   aws ec2 describe-key-pairs --key-names your-key-name
   ```

3. **Trigger deployment**:
   - Push to main branch
   - Or manually trigger workflow in GitHub Actions

## 🛠️ Troubleshooting

### Common Issues

#### Invalid AWS Credentials
```
Error: The security token included in the request is invalid
```
**Solution**: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct

#### Key Pair Not Found
```
Error: The key pair 'my-key' does not exist
```
**Solution**: Ensure `EC2_KEY_NAME` matches exactly with AWS key pair name

#### Permission Denied
```
Error: User is not authorized to perform ec2:CreateVpc
```
**Solution**: Review IAM permissions and ensure the user has required EC2 permissions

#### SSH Connection Failed
```
Error: Permission denied (publickey)
```
**Solution**: Verify `EC2_PRIVATE_KEY` contains the complete private key including headers

## 📊 Monitoring Deployment

### GitHub Actions Logs

Monitor deployment progress in the Actions tab:

1. **Build Job**: Application compilation and artifact creation
2. **Terraform Plan**: Infrastructure planning and validation
3. **Deploy Job**: Infrastructure provisioning and application deployment
4. **Health Check**: Application readiness verification

### AWS CloudWatch

View infrastructure and application metrics:

- EC2 instance metrics
- Application logs
- Nginx access logs
- CloudWatch alarms

### New Relic Dashboard

Monitor application performance:

- Response times
- Error rates
- Database queries
- Custom business metrics

## 🔗 Related Documentation

- [Main Deployment Guide](../DEPLOYMENT_GUIDE.md)
- [Terraform Configuration](../terraform/README.md)
- [Security Guide](../SECURITY.md)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
