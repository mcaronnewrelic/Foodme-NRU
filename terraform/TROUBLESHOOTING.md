# Terraform Troubleshooting Guide

This guide helps resolve common issues when deploying FoodMe with Terraform.

## 🚨 Template Syntax Errors

### Issue: Invalid template control keyword

```
Error: Call to function "templatefile" failed: ./user_data.sh:145,39-48: Invalid
template control keyword; "http_code" is not a valid template control keyword.
```

**Cause**: Terraform interprets `%{...}` as template directives. Curl's `%{http_code}` conflicts with this.

**Solution**: Escape the `%` character in user_data.sh:
```bash
# Wrong
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

# Correct  
response=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:3000/health)
```

### Issue: CloudFormation variables in EC2 user data

```
Error: Invalid template interpolation value; The given value is not a string.
```

**Cause**: CloudFormation-style variables like `${AWS::StackName}` are not valid in Terraform templates.

**Solution**: Remove or replace CloudFormation-specific code:
```bash
# Wrong (CloudFormation style)
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}

# Correct (Terraform style)
echo "User data script completed successfully"
```

## 🔧 Backend Configuration Issues

### Issue: S3 Backend Access Denied

```
Error: error configuring S3 Backend: error validating provider credentials
```

**Solution 1**: Comment out backend for initial testing:
```hcl
# backend "s3" {
#   bucket = "your-terraform-state-bucket"
#   key    = "foodme/terraform.tfstate"
#   region = "us-east-1"
# }
```

**Solution 2**: Create S3 bucket for state storage:
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
```

### Issue: Backend Initialization Failed

```
Error: Backend configuration changed
```

**Solution**: Re-initialize with new backend:
```bash
terraform init -reconfigure
```

## 🔑 AWS Credentials Issues

### Issue: Expired Token

```
Error: ExpiredToken: The security token included in the request is expired
```

**Solution**: Refresh AWS credentials:
```bash
# For AWS CLI profiles
aws configure

# For temporary credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_SESSION_TOKEN="your-token"  # if using temporary credentials
```

### Issue: Access Denied

```
Error: User is not authorized to perform ec2:CreateVpc
```

**Solution**: Ensure IAM user has required permissions:
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

## 📝 Variable Configuration Issues

### Issue: Key pair not found

```
Error: The key pair 'my-key' does not exist
```

**Solution**: Create key pair or update variable:
```bash
# Create new key pair
aws ec2 create-key-pair --key-name foodme-keypair --output text --query 'KeyMaterial' > foodme-keypair.pem

# Update terraform.tfvars
key_name = "foodme-keypair"
```

### Issue: Invalid CIDR blocks

```
Error: Invalid CIDR format
```

**Solution**: Use proper CIDR notation:
```hcl
# Wrong
allowed_cidr_blocks = ["192.168.1.1"]

# Correct
allowed_cidr_blocks = ["192.168.1.1/32"]  # Single IP
allowed_cidr_blocks = ["0.0.0.0/0"]       # All IPs (not recommended for production)
```

### Issue: Invalid CIDR block format

```
Error: "97.120.85.138/0" is not a valid IPv4 CIDR block; did you mean "0.0.0.0/0"?
```

**Cause**: Incorrect CIDR notation in `allowed_cidr_blocks` variable.

**Common Mistakes**:
- Using `/0` instead of `/32` for single IP
- Forgetting the subnet mask entirely
- Using invalid IP addresses

**Solutions**:
```hcl
# Wrong formats
allowed_cidr_blocks = ["192.168.1.1"]        # Missing subnet mask
allowed_cidr_blocks = ["192.168.1.1/0"]      # Invalid subnet mask
allowed_cidr_blocks = ["256.1.1.1/32"]       # Invalid IP address

# Correct formats
allowed_cidr_blocks = ["192.168.1.1/32"]     # Single IP address
allowed_cidr_blocks = ["192.168.1.0/24"]     # Subnet (256 addresses)
allowed_cidr_blocks = ["10.0.0.0/8"]         # Large network
allowed_cidr_blocks = ["0.0.0.0/0"]          # All IPs (not recommended)

# Multiple ranges
allowed_cidr_blocks = [
  "192.168.1.1/32",    # Your home IP
  "10.0.0.0/24",       # Office network
  "172.16.0.0/16"      # VPN range
]
```

**Quick IP Detection**:
```bash
# Get your current public IP
curl -s https://checkip.amazonaws.com/

# Use in terraform.tfvars
allowed_cidr_blocks = ["$(curl -s https://checkip.amazonaws.com/)/32"]
```

## 🔍 Validation and Testing

### Pre-deployment Validation

Run the validation script:
```bash
cd terraform
./validate.sh
```

### Manual Validation Steps

1. **Check Terraform syntax**:
   ```bash
   terraform fmt -check
   terraform validate
   ```

2. **Test template files**:
   ```bash
   terraform console <<< 'templatefile("user_data.sh", {app_port=3000, environment="test", app_version="1.0.0"})'
   ```

3. **Verify AWS access**:
   ```bash
   aws sts get-caller-identity
   aws ec2 describe-regions
   ```

## 🐛 Runtime Issues

### Issue: Instance fails to start

**Check user data logs**:
```bash
# SSH into instance
ssh -i your-key.pem ec2-user@instance-ip

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/cloud-init.log
```

### Issue: Application not accessible

**Debug steps**:
```bash
# Check if application is running
sudo systemctl status foodme

# Check nginx status
sudo systemctl status nginx

# Check application logs
sudo journalctl -u foodme -f

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Issue: Health check failures

**Common causes**:
- Application not started
- Wrong port configuration
- Firewall/security group blocking access

**Debug**:
```bash
# Test locally on instance
curl http://localhost:3000/health

# Check which processes are listening
sudo netstat -tlnp | grep :3000
```

## 🛠️ Quick Fixes

### Reset Terraform state

```bash
# Remove local state (use with caution)
rm terraform.tfstate*
rm -rf .terraform/

# Re-initialize
terraform init
```

### Force resource recreation

```bash
# Force recreation of specific resource
terraform taint aws_instance.foodme
terraform apply
```

### Clean deployment

```bash
# Destroy everything and start fresh
terraform destroy
terraform apply
```

## 📞 Getting Help

### Terraform debugging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan

# Show detailed plan
terraform plan -detailed-exitcode

# Show current state
terraform show
```

### AWS debugging

```bash
# List resources
aws ec2 describe-instances
aws ec2 describe-security-groups
aws ec2 describe-key-pairs

# Check logs
aws logs describe-log-groups
aws logs get-log-events --log-group-name foodme-application
```

### Common validation commands

```bash
# Full validation pipeline
terraform fmt
terraform validate
terraform plan -detailed-exitcode
terraform apply -auto-approve
```

## 📚 Additional Resources

- [Terraform Template Functions](https://www.terraform.io/docs/language/functions/templatefile.html)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EC2 User Data Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [GitHub Actions AWS Credentials](https://github.com/aws-actions/configure-aws-credentials)
