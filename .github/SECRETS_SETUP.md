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

| Secret Name | Description | Example | Required |
|-------------|-------------|---------|----------|
| `NEW_RELIC_LICENSE_KEY` | New Relic License Key for infrastructure monitoring | `eu01xxXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL` | Optional* |
| `NEW_RELIC_API_KEY` | New Relic User API Key | `NRAK-XXXXXXXXXXXXXXXX` | Optional |

**Note**: `NEW_RELIC_LICENSE_KEY` is optional but **highly recommended** for production monitoring. When provided, it enables comprehensive infrastructure and database monitoring.

### Database Configuration

| Secret Name | Description | Example | Required |
|-------------|-------------|---------|----------|
| `DB_NAME` | PostgreSQL database name | `foodme` | Optional* |
| `DB_USER` | PostgreSQL database user | `foodme_user` | Optional* |
| `DB_PASSWORD` | PostgreSQL database password | `my_secure_password_2025!` | Optional* |
| `DB_PORT` | PostgreSQL database port | `5432` | Optional* |

**Note**: Database secrets are optional because default values are provided in Terraform variables. However, it's **strongly recommended** to set custom values for production deployments for security purposes.

**Auto-Configuration**: When database secrets are provided, they are automatically passed to the EC2 instance during deployment and used to configure PostgreSQL and the application connection.

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

### 3. Setup New Relic License Key (Optional but Recommended)

#### Getting Your New Relic License Key

1. **Sign up for New Relic** (if you don't have an account):
   - Go to [https://newrelic.com/signup](https://newrelic.com/signup)
   - Create a free account (includes generous free tier)

2. **Find your License Key**:
   - Log into your New Relic account
   - Go to **Account Settings** → **API Keys**
   - Look for your **License Key** (starts with letters like `eu01xx` or similar)
   - **Format**: 40-character string ending with `NRAL`

3. **License Key Examples**:
   ```
   # US region example
   us01xxXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL
   
   # EU region example  
   eu01xxXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL
   ```

#### What New Relic Monitoring Includes

When `NEW_RELIC_LICENSE_KEY` is provided, the deployment automatically configures:

- ✅ **Infrastructure Monitoring**: CPU, memory, disk, network metrics
- ✅ **Application Performance Monitoring**: Response times, throughput, errors
- ✅ **PostgreSQL Database Monitoring**: Query performance, connections, locks
- ✅ **Nginx Web Server Monitoring**: Request rates, response times, status codes
- ✅ **Custom Dashboards**: Pre-configured views for the FoodMe application

#### Adding to GitHub Secrets

1. Copy your 40-character New Relic License Key
2. In GitHub: `Settings` → `Secrets and variables` → `Actions`
3. Click `New repository secret`
4. **Name**: `NEW_RELIC_LICENSE_KEY`
5. **Value**: Paste your license key (no quotes or extra characters)

**⚠️ Important Notes:**
- ❌ Don't include quotes around the license key
- ❌ Don't add extra spaces or line breaks
- ✅ Just paste the raw 40-character key
- ✅ Keep it secure - never commit to code

### 4. Configure GitHub Secrets

Go to your repository settings:

1. Navigate to `Settings` → `Secrets and variables` → `Actions`
2. Click `New repository secret`
3. Add each secret from the table above

#### Required Secrets for Basic Deployment:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_KEY_NAME` (if using SSH deployment)
- `EC2_PRIVATE_KEY` (if using SSH deployment)
- `ALLOWED_CIDR_BLOCKS`

#### Optional but Recommended Secrets:
- `NEW_RELIC_LICENSE_KEY` (for comprehensive infrastructure and database monitoring)
- `NEW_RELIC_API_KEY` (for additional New Relic integrations)
- `DB_PASSWORD` (for custom database password)
- `DB_NAME`, `DB_USER`, `DB_PORT` (if different from defaults)

**Database Security Note**: While database secrets have defaults, it's **highly recommended** to set a custom `DB_PASSWORD` for production deployments.

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

### Database Security

- **Default Configuration**: PostgreSQL 16 with basic security settings
- **Custom Password**: Always set `DB_PASSWORD` secret for production
- **Database Access**: PostgreSQL is configured for local access only (localhost)
- **Data Initialization**: Database is automatically initialized from `./db/init/*.sql` files
- **Monitoring**: New Relic PostgreSQL integration included when license key provided

## 🗄️ Database Configuration Details

### Default Values
The deployment uses these default database settings (can be overridden with secrets):

```bash
DB_NAME=foodme
DB_USER=foodme_user
DB_PASSWORD=foodme_secure_password_2025!  # ⚠️ Change this for production!
DB_PORT=5432
```

### Setting Custom Database Configuration

1. **For Production (Recommended)**:
   ```bash
   # Set these as GitHub Secrets
   DB_PASSWORD=your_very_secure_password_here
   # Optional: customize other values
   DB_NAME=foodme_prod
   DB_USER=foodme_prod_user
   DB_PORT=5432
   ```

2. **For Staging/Development**:
   ```bash
   # Minimum recommended change
   DB_PASSWORD=staging_secure_password_2025
   ```

### Database Features Included

- ✅ **PostgreSQL 16** server installation and configuration
- ✅ **Automatic initialization** from `./db/init/*.sql` files
- ✅ **Local-only access** (127.0.0.1) for security
- ✅ **MD5 password authentication** 
- ✅ **New Relic monitoring** integration
- ✅ **Health checks** and status monitoring
- ✅ **Service dependencies** (app waits for database)

### Database File Structure
```
db/
├── init/
│   ├── 01-init-schema.sql      # Table definitions
│   ├── 02-import-restaurants-uuid.sql  # Sample data
│   └── ...                     # Additional SQL files
└── scripts/                    # Management scripts
```

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

4. **Validate New Relic setup** (if using monitoring):
   ```bash
   # Check if your license key format is correct (should be 40 characters)
   echo "YOUR_LICENSE_KEY" | wc -c
   
   # Should output: 41 (40 characters + newline)
   ```

5. **Verify secrets in GitHub**:
   - Go to repository `Settings` → `Secrets and variables` → `Actions`
   - Ensure all required secrets are listed (but values are hidden)
   - Check secret names match exactly (case-sensitive)

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

#### Database Connection Issues
```
Error: FATAL: password authentication failed for user "foodme_user"
```
**Solution**: Check that `DB_PASSWORD` secret matches the configured password

#### Database Initialization Failed
```
Error: could not connect to server: Connection refused
```
**Solution**: 
- Ensure PostgreSQL service is running on the EC2 instance
- Check that database variables (`DB_HOST`, `DB_PORT`) are correct
- Verify security group allows internal PostgreSQL access

#### New Relic Database Monitoring Issues
```
Error: connection to server at "localhost" (127.0.0.1), port 5432 failed
```
**Solution**: 
- Verify `NEW_RELIC_LICENSE_KEY` is provided
- Check PostgreSQL service is running
- Ensure database credentials in New Relic config match `DB_*` secrets

#### New Relic License Key Issues
```
Error: Invalid license key or New Relic agent failed to start
```
**Solution**: 
- Verify `NEW_RELIC_LICENSE_KEY` is exactly 40 characters
- Check there are no extra spaces or quotes around the license key
- Ensure the license key is valid and not expired in your New Relic account
- Verify the license key matches your New Relic account region (US/EU)

#### New Relic Agent Not Reporting Data
```
Warning: New Relic infrastructure agent not sending data
```
**Solution**:
- Check that `NEW_RELIC_LICENSE_KEY` secret is set in GitHub
- Verify the license key is active in your New Relic account
- Allow 2-3 minutes for data to appear in New Relic dashboards
- Check EC2 instance can reach New Relic endpoints (outbound HTTPS)

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
- PostgreSQL logs
- CloudWatch alarms

### New Relic Dashboard

Monitor application performance:

- Response times
- Error rates
- Database queries and performance
- PostgreSQL metrics (connections, queries/sec, locks)
- Custom business metrics
- Infrastructure monitoring

### Database Monitoring

When `NEW_RELIC_LICENSE_KEY` is provided, the deployment includes:

- **PostgreSQL Integration**: Monitors database performance, connections, and queries
- **Database Health Checks**: Automatic monitoring of database availability
- **Query Performance**: Tracks slow queries and database locks
- **Connection Metrics**: Monitors active connections and connection pools

## 🔗 Related Documentation

- [Main Deployment Guide](../DEPLOYMENT_GUIDE.md)
- [Terraform Configuration](../terraform/README.md)
- [Security Guide](../SECURITY.md)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
