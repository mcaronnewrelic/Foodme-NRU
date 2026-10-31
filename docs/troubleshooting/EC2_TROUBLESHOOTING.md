# EC2 and Terraform Troubleshooting

One guide for a deployment that fails, whether it fails while Terraform runs or after the instance is up.

## Where does it fail?

| What you see | Go to |
|---|---|
| `terraform plan`, `apply` or `init` prints an error | [Terraform errors](#terraform-errors) |
| `InvalidKeyPair.NotFound` | [EC2 Key Pair Setup](../../terraform/EC2_KEYPAIR_SETUP.md) |
| Terraform finished, but the site does not load or is wrong | [On the instance](#on-the-instance) |
| The New Relic infrastructure agent will not install on Amazon Linux 2023 | [New Relic on Amazon Linux 2023](../../terraform/NEW_RELIC_AL2023_FIX.md) |
| A failed deployment left AWS resources behind | [Cleanup Guide](../../.github/CLEANUP_GUIDE.md) |

## How the deployment is set up

This is what a Terraform deployment creates today, so you know what to compare a broken instance against:

- **nginx** (`terraform/configs/nginx.conf`) proxies every request, including `/`, `/health`, `/api/` and static files, to the Node app on port 3000. The one exception is `/nginx_status`, which nginx answers itself for monitoring.
- **The app** runs as the `foodme` systemd service (`terraform/configs/foodme.service`): user `ec2-user`, working directory `/var/www/foodme/dist/server`, command `/usr/bin/node start.js`. Restart is automatic after 10 seconds.
- **Angular routing** works because the Node app serves the Angular build and answers unknown paths with `index.html`.
- **PostgreSQL 16** runs on the instance as `postgresql-16`.
- The CloudFormation deployment lays files out differently (the server code refers to `/opt/foodme`). The commands below use the Terraform paths.

## Terraform errors

### 🚨 Template Syntax Errors

#### Issue: Invalid template control keyword

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

#### Issue: CloudFormation variables in EC2 user data

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

### 🔧 Backend Configuration Issues

#### Issue: S3 Backend Access Denied

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

#### Issue: Backend Initialization Failed

```
Error: Backend configuration changed
```

**Solution**: Re-initialize with new backend:
```bash
terraform init -reconfigure
```

### 🔑 AWS Credentials Issues

#### Issue: Expired Token

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

#### Issue: Access Denied

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

### 📝 Variable Configuration Issues

#### Issue: Key pair not found

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

#### Issue: Invalid CIDR blocks

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

#### Issue: Invalid CIDR block format

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

### 🔍 Validation and Testing

#### Pre-deployment Validation

Run the validation script:
```bash
cd terraform
./validate.sh
```

#### Manual Validation Steps

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

### 🛠️ Quick Fixes

#### Reset Terraform state

```bash
# Remove local state (use with caution)
rm terraform.tfstate*
rm -rf .terraform/

# Re-initialize
terraform init
```

#### Force resource recreation

```bash
# Force recreation of specific resource
terraform taint aws_instance.foodme
terraform apply
```

#### Clean deployment

```bash
# Destroy everything and start fresh
terraform destroy
terraform apply
```

### 📞 Getting Help

#### Terraform debugging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan

# Show detailed plan
terraform plan -detailed-exitcode

# Show current state
terraform show
```

#### AWS debugging

```bash
# List resources
aws ec2 describe-instances
aws ec2 describe-security-groups
aws ec2 describe-key-pairs

# Check logs
aws logs describe-log-groups
aws logs get-log-events --log-group-name foodme-application
```

#### Common validation commands

```bash
# Full validation pipeline
terraform fmt
terraform validate
terraform plan -detailed-exitcode
terraform apply -auto-approve
```

## On the instance

Connect with `ssh -i your-key.pem ec2-user@<instance-ip>`. `terraform output` shows the instance's address. (`terraform/get-ip.sh` finds *your* public IP, for `allowed_cidr_blocks`.)

### First checks

```bash
# Are the three services up?
sudo systemctl status foodme nginx postgresql-16

# Why did the app stop? (follow the log)
sudo journalctl -u foodme -f

# nginx errors
sudo tail -f /var/log/nginx/error.log

# Does the app answer directly, and through nginx?
curl http://localhost:3000/health
curl http://localhost/health

# What is listening?
sudo netstat -tlnp | grep -E ':80|:3000'
```

If the instance never finished setting up, read the user data output:

```bash
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/cloud-init.log
```

`terraform/debug-user-data.sh` checks the user data run, and `terraform/diagnose-ec2.sh <ip>` runs a set of checks against an instance. Open the scripts to see what each does before you run them. `scripts/archive/diagnose-deployment.sh` is an older diagnostic that runs on the instance.

### The `foodme` service fails to start

**Symptom:**
```
● foodme.service - FoodMe Node.js Application
   Active: failed (Result: exit-code)
```

**Cause on older instances:** the unit file had an `ExecStartPre` line that ran `npm install --production`, which fails for lack of permissions. The current unit does not have it, because dependencies are installed during deployment.

**Fix:** compare `/etc/systemd/system/foodme.service` with `terraform/configs/foodme.service`. If the old line is there, remove it, then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart foodme
sudo journalctl -u foodme -n 50
```
If it still fails, run the app by hand to see the real error: `cd /var/www/foodme/dist/server && node start.js`.

### Angular routes return 404, but `/` works

**Cause:** nginx is serving files from disk instead of proxying to the app, so it does not know the Angular routes. This is how earlier deployments were set up.

**Fix:** use the proxy configuration. Replace the server block with `terraform/configs/nginx.conf` (the older helper `scripts/archive/apply-nodejs-proxy-nginx.sh` applied the same change), then:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### 403 from nginx, or "Error loading application"

- **403:** nginx is looking for `index.html` on disk and cannot find it or cannot read it. With the proxy configuration this should not happen, so check that nginx is using it.
- **"Error loading application":** the Node app cannot find the Angular build. Check that `index.html` exists in the `dist/browser` folder beside the server, and that `ec2-user` can read it.

Ownership problems are fixed with:
```bash
sudo chown -R ec2-user:ec2-user /var/www/foodme
sudo chmod -R 755 /var/www/foodme
```

### Health checks fail

**Common causes:** the app is not running, the port is wrong, or a firewall or security group blocks access.

```bash
curl http://localhost:3000/health     # on the instance
sudo netstat -tlnp | grep :3000
```

If it works on the instance but not from outside, check that the security group allows inbound traffic on port 80, and that your address is in `allowed_cidr_blocks` (see the CIDR sections above).

### The database

```bash
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -d foodme -c "\dt"
sudo systemctl status postgresql-16
```

### After a fix

```bash
sudo systemctl status foodme nginx
sudo journalctl -u foodme -n 20
curl http://localhost/health
curl http://localhost/api/restaurant
```

The app should be `active (running)`, and `/health` should return a healthy status.

## If it still fails

1. Run the diagnostics above and read `journalctl -u foodme`.
2. Check the GitHub Actions logs for deployment errors.
3. Check CloudWatch logs for the instance.
4. If the deployment is beyond repair, remove it with the [Cleanup Guide](../../.github/CLEANUP_GUIDE.md) and start again.

## 📚 Additional Resources

- [Terraform Template Functions](https://www.terraform.io/docs/language/functions/templatefile.html)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EC2 User Data Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [GitHub Actions AWS Credentials](https://github.com/aws-actions/configure-aws-credentials)
