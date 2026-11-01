# Code Deployment Guide

This guide explains how to deploy only your application code (`/server` and `/angular-app` folders) to your existing EC2 infrastructure without recreating AWS resources.

## Overview

The code deployment process allows you to:
- **Update application code** without touching AWS infrastructure
- **Deploy frontend and backend** independently or together
- **Preserve environment configuration** and database state
- **Rollback quickly** if issues occur
- **Deploy in seconds** instead of minutes

## Quick Start

### 1. **Validate Your Environment**
Before deploying code, ensure your infrastructure is ready:

```bash
cd cloudformation
./validate-deployment.sh -e staging
```

This checks:
- CloudFormation stack status
- EC2 instance health
- SSM connectivity
- Application endpoints
- ALB target health

### 2. **Deploy Code Changes**

#### Deploy Both Frontend and Backend
```bash
./deploy-code.sh -e staging
```

#### Deploy Only Frontend (Angular)
```bash
./deploy-code.sh -e staging --frontend-only
```

#### Deploy Only Backend (Node.js)
```bash
./deploy-code.sh -e staging --backend-only
```

#### Deploy Without Restarting Services
```bash
./deploy-code.sh -e staging --no-restart
```

### 3. **Verify Deployment**
```bash
# Check application response
curl -s -o /dev/null -w '%{http_code}' http://YOUR_ALB_DNS

# Check API response
curl -s http://YOUR_ALB_DNS:3000/api/restaurant
```

## How It Works

### Deployment Process

1. **Package Code**: Creates ZIP files of `/server` and `/angular-app` folders
2. **Upload to S3**: Uploads packages to the same S3 bucket used by CloudFormation
3. **Connect to EC2**: Uses AWS Systems Manager (SSM) to execute commands
4. **Backup Current Code**: Creates backup of existing application
5. **Download New Code**: Downloads and extracts new packages from S3
6. **Install Dependencies**: Runs `npm install` if needed
7. **Build Frontend**: Compiles Angular application
8. **Restart Services**: Restarts backend service and nginx

### Architecture

```
Developer Machine → S3 Bucket → EC2 Instance
    ↓                 ↓            ↓
  ZIP Files     Upload Code   Download & Deploy
```

### File Locations on EC2

```
/opt/foodme/
├── backend/              # Node.js application
│   ├── *.js             # Server files
│   ├── package.json     # Dependencies
│   ├── .env            # Environment config (preserved)
│   └── node_modules/   # Dependencies
├── angular-app/         # Angular source
│   ├── src/            # Angular source files
│   ├── dist/           # Built application
│   └── node_modules/   # Dependencies
└── browser/            # Symlink to dist/browser
```

## Command Options

### Environment Selection
```bash
-e ENVIRONMENT    # Required: staging or production
-r AWS_REGION     # Optional: defaults to AWS CLI region
```

### Deployment Scope
```bash
--frontend-only   # Deploy only Angular application
--backend-only    # Deploy only Node.js server
--no-restart      # Skip restarting services
```

### Examples
```bash
# Production deployment
./deploy-code.sh -e production

# Specific region
./deploy-code.sh -e staging -r us-west-2

# Quick frontend fix
./deploy-code.sh -e staging --frontend-only

# Backend hotfix without restart
./deploy-code.sh -e staging --backend-only --no-restart
```

## Prerequisites

### AWS Requirements
- **AWS CLI** configured with appropriate credentials
- **CloudFormation stack** already deployed
- **SSM permissions** for EC2 access
- **S3 access** for code uploads

### Required AWS Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:DescribeStacks",
                "cloudformation:DescribeStackResources",
                "ec2:DescribeInstances",
                "ssm:SendCommand",
                "ssm:GetCommandInvocation",
                "ssm:DescribeInstanceInformation",
                "s3:PutObject",
                "s3:GetObject",
                "elbv2:DescribeTargetHealth"
            ],
            "Resource": "*"
        }
    ]
}
```

### EC2 Requirements
- **SSM Agent** installed and running
- **Instance role** with S3 access
- **Systemd services** configured for backend

## Troubleshooting

### Common Issues

#### 1. **SSM Connection Failed**
```bash
# Check SSM agent status
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-1234567890abcdef0"

# If agent is offline, restart it on EC2:
sudo systemctl restart amazon-ssm-agent
```

#### 2. **S3 Upload Failed**
```bash
# Check S3 bucket permissions
aws s3 ls s3://your-bucket-name

# Verify AWS credentials
aws sts get-caller-identity
```

#### 3. **Build Failures**
```bash
# Check build logs on EC2
ssh -i your-key.pem ec2-user@your-instance
sudo journalctl -u foodme-backend -n 50
```

#### 4. **Service Won't Start**
```bash
# Check service status
systemctl status foodme-backend nginx

# View service logs
journalctl -u foodme-backend --no-pager -n 20
```

### Error Recovery

#### Rollback to Previous Version
```bash
# SSH to EC2 instance
ssh -i your-key.pem ec2-user@your-instance

# Restore backend backup
cd /opt/foodme/backend
sudo systemctl stop foodme-backend
cp backup/* .
sudo systemctl start foodme-backend

# Restore frontend backup
cd /opt/foodme
rm -rf angular-app
mv angular-app-backup angular-app
sudo systemctl restart nginx
```

#### Force Redeploy
```bash
# If deployment fails, try again with verbose output
./deploy-code.sh -e staging --backend-only
```

## Performance Considerations

### Deployment Speed
- **Frontend Only**: ~30-60 seconds (includes build)
- **Backend Only**: ~15-30 seconds
- **Both**: ~60-90 seconds

### Zero-Downtime Deployment
The current setup has brief downtime during service restart. For zero-downtime:
1. Use multiple instances with Auto Scaling Group
2. Deploy to instances one at a time
3. Use blue-green deployment strategy

## Development Workflow

### Typical Development Cycle
```bash
# 1. Make code changes locally
vim server/index.js
vim angular-app/src/app/app.component.ts

# 2. Test locally (optional)
npm start  # in both server/ and angular-app/

# 3. Deploy to staging
./deploy-code.sh -e staging

# 4. Validate deployment
curl http://your-staging-url/api/restaurant

# 5. Deploy to production
./deploy-code.sh -e production
```

### Branch-Based Deployments
```bash
# Feature branch to staging
git checkout feature/new-feature
./deploy-code.sh -e staging

# Main branch to production
git checkout main
./deploy-code.sh -e production
```

## Monitoring and Validation

### Health Checks
```bash
# Application health
curl -f http://your-alb-dns/

# API health
curl -f http://your-alb-dns:3000/api/restaurant

# Service status
ssh ec2-user@your-instance 'systemctl is-active foodme-backend nginx'
```

### Log Monitoring
```bash
# Real-time logs
ssh ec2-user@your-instance 'sudo journalctl -u foodme-backend -f'

# Error logs
ssh ec2-user@your-instance 'sudo tail -f /var/log/nginx/error.log'
```

### Performance Monitoring
If New Relic is configured:
- **APM Dashboard**: Monitor application performance
- **Infrastructure**: Track server metrics
- **Alerts**: Get notified of issues

## Security Considerations

### Code Security
- **No secrets in code**: Environment variables used for sensitive data
- **Dependencies**: Only production dependencies installed
- **File permissions**: Proper ownership and permissions maintained

### Network Security
- **SSM Access**: No SSH required for deployments
- **S3 Security**: Bucket access restricted to instance role
- **ALB Protection**: EC2 not directly accessible from internet

## Advanced Usage

### Custom Deployment Scripts
You can extend the deployment process by modifying `/cloudformation/deploy-code.sh`:

```bash
# Add custom pre-deployment checks
# Add database migrations
# Add cache clearing
# Add custom health checks
```

### Environment-Specific Configurations
Different environments can have different deployment behaviors by modifying the script logic based on the `$ENVIRONMENT` variable.

### Integration with CI/CD
The scripts can be integrated into your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Deploy to Staging
  run: |
    ./cloudformation/deploy-code.sh -e staging
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

This deployment system provides a fast, reliable way to update your FoodMe application code while keeping your AWS infrastructure stable and unchanged!