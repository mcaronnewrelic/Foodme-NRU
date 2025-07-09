# FoodMe EC2 Deployment with Terraform

This directory contains Terraform configurations to deploy the FoodMe application to AWS EC2 instances.

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (version >= 1.0)
3. **AWS CLI** configured
4. **SSH key pair** created in AWS

## 🚀 Quick Start

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

**Quick IP Setup** (recommended):
```bash
# Automatically get your IP and create terraform.tfvars
./get-ip.sh
```

**Manual Setup**:
Edit `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "staging"

# EC2 Configuration
instance_type = "t3.small"
key_name = "your-key-pair-name"

# Security Configuration
allowed_cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP

# Application Configuration
app_port = 3000
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

### 5. Access Your Application

After deployment, get the instance IP:

```bash
terraform output instance_public_ip
```

Access your application at: `http://INSTANCE_IP:3000`

## 🔧 Configuration Options

### Basic Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `environment` | Environment name | `staging` |
| `instance_type` | EC2 instance type | `t3.small` |
| `key_name` | SSH key pair name | **Required** |
| `app_port` | Application port | `3000` |

### Advanced Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `create_alb` | Create Application Load Balancer | `false` |
| `ssl_certificate_arn` | SSL certificate ARN | `""` |
| `domain_name` | Domain name | `""` |
| `allowed_cidr_blocks` | Allowed IP ranges | `["0.0.0.0/0"]` |

## 🏗️ Architecture

The Terraform configuration creates:

- **VPC** with public and private subnets
- **EC2 instance** with security groups
- **Internet Gateway** and routing
- **IAM roles** for EC2 permissions
- **Application Load Balancer** (optional)
- **CloudWatch** monitoring setup

## 🔐 Security Features

### Network Security
- VPC with isolated subnets
- Security groups with minimal required access
- Optional IP whitelisting

### Instance Security
- IAM roles with least privilege
- Encrypted EBS volumes
- CloudWatch monitoring
- Automated security updates

### Application Security
- Nginx reverse proxy
- SSL/TLS support (optional)
- Security headers configured
- Health check endpoints

## 📊 Monitoring

### CloudWatch Integration
- System metrics (CPU, memory, disk)
- Application logs
- Nginx access/error logs
- Custom business metrics

### New Relic Integration
- Application performance monitoring
- Infrastructure monitoring
- Error tracking
- Deployment markers

## 🚀 Deployment Process

### GitHub Actions Integration

The deployment happens automatically via GitHub Actions:

1. **Build** - Compiles the Angular app and Node.js server
2. **Plan** - Creates Terraform execution plan
3. **Deploy** - Applies infrastructure changes
4. **Upload** - Transfers application files to EC2
5. **Health Check** - Verifies deployment success
6. **Notify** - Sends deployment marker to New Relic

### Manual Deployment

You can also deploy manually:

```bash
# Build the application
npm run build

# Apply Terraform changes
terraform apply

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Upload application files
scp -r dist/* ec2-user@$INSTANCE_IP:/var/www/foodme/

# Restart application
ssh ec2-user@$INSTANCE_IP "sudo systemctl restart foodme"
```

## 🛠️ Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify key pair exists
aws ec2 describe-key-pairs --key-names your-key-name
```

#### Instance Not Accessible
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx

# Verify instance is running
aws ec2 describe-instances --instance-ids i-xxxxxxxx
```

#### Application Not Starting
```bash
# SSH into instance
ssh -i ~/.ssh/your-key.pem ec2-user@INSTANCE_IP

# Check application logs
sudo journalctl -u foodme -f

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Useful Commands

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_public_ip

# SSH into instance
terraform output ssh_command

# View logs
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw instance_public_ip) \
  "sudo journalctl -u foodme -f"

# Restart application
ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw instance_public_ip) \
  "sudo systemctl restart foodme"
```

## 🔄 Updates and Maintenance

### Application Updates

Updates are handled automatically by GitHub Actions, but you can also update manually:

```bash
# Build new version
npm run build

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Upload new files
scp -r dist/* ec2-user@$INSTANCE_IP:/var/www/foodme/

# Deploy update
ssh ec2-user@$INSTANCE_IP "/var/www/foodme/deploy.sh"
```

### Infrastructure Updates

```bash
# Check for changes
terraform plan

# Apply changes
terraform apply

# Refresh outputs
terraform refresh
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources created by Terraform.

## 📝 State Management

For production use, configure remote state storage:

```hcl
# In main.tf
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "foodme/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## 🆘 Support

For help with this deployment:

1. Check the [troubleshooting section](#troubleshooting)
2. Review AWS CloudWatch logs
3. Check the [main deployment guide](../DEPLOYMENT_GUIDE.md)
4. Verify your [environment setup](../SETUP_GUIDE.md)

## 🔗 Related Documentation

- [Main Setup Guide](../SETUP_GUIDE.md)
- [Deployment Guide](../DEPLOYMENT_GUIDE.md)
- [DevContainer Setup](../DEVCONTAINER_SETUP.md)
- [Security Guide](../SECURITY.md)
