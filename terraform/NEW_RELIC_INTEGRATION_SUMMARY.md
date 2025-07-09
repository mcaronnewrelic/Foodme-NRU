# New Relic Infrastructure Agent Integration Summary

## Changes Made

### 1. Updated User Data Script (`terraform/user_data.sh`)
- **Added New Relic Infrastructure agent installation**
- **Added New Relic nginx integration configuration**
- **Added environment variables for APM integration**
- **Script size**: Increased from ~3.5KB to ~5.5KB (still well under 16KB limit)

#### New Features Added:
- New Relic Infrastructure agent installation and configuration
- Custom attributes for environment, application, instance type, region
- Nginx status endpoint for web server monitoring
- Environment variables for APM agent integration

### 2. Updated Terraform Configuration

#### Variables (`terraform/variables.tf`)
- Added `new_relic_license_key` variable (sensitive)

#### Infrastructure (`terraform/infrastructure.tf`)
- Updated `user_data` template to include `new_relic_license_key` parameter

### 3. Updated GitHub Actions Workflow (`.github/workflows/deploy.yml`)
- Added `TF_VAR_new_relic_license_key` environment variable to Terraform Plan step
- Added `TF_VAR_new_relic_license_key` environment variable to Terraform Apply step
- Uses `secrets.NEW_RELIC_LICENSE_KEY` from repository secrets

### 4. Updated Documentation (`NEW_RELIC_INFRA_SETUP.md`)
- Complete rewrite for EC2 deployment context
- Added setup instructions for GitHub secrets
- Added verification and troubleshooting sections
- Added configuration file examples

## Required Actions

### 1. Add GitHub Repository Secret
Add the following secret to your GitHub repository:
- **Name**: `NEW_RELIC_LICENSE_KEY`
- **Value**: Your New Relic license key

### 2. Get New Relic License Key
1. Log into New Relic One
2. Go to Account Settings → API Keys → License Key
3. Copy your license key

### 3. Deploy
Run your GitHub Actions workflow to deploy with New Relic monitoring

## What You'll Get

### Infrastructure Monitoring
- **Host Metrics**: CPU, memory, disk, network for your EC2 instance
- **Process Monitoring**: Node.js and nginx process monitoring
- **Custom Tagging**: Environment-specific labeling
- **Alert Conditions**: Set up alerts for resource thresholds

### APM Monitoring
- **Application Performance**: Transaction traces, throughput, response times
- **Error Tracking**: Application errors and exceptions
- **Database Monitoring**: PostgreSQL query performance (when database is used)
- **Custom Events**: Order tracking and business metrics

### Web Server Monitoring
- **Nginx Metrics**: Request rates, response codes, performance
- **Upstream Monitoring**: Backend application health
- **Error Tracking**: 4xx and 5xx error rates

## Files Modified
1. `terraform/user_data.sh` - Enhanced with New Relic Infrastructure agent
2. `terraform/variables.tf` - Added license key variable
3. `terraform/infrastructure.tf` - Updated template parameters
4. `.github/workflows/deploy.yml` - Added license key environment variables
5. `NEW_RELIC_INFRA_SETUP.md` - Updated documentation

## Verification Steps
After deployment, verify the integration:
1. Check Infrastructure dashboard in New Relic One
2. Look for your server: `FoodMe-EC2-{environment}-{instance-id}`
3. Verify APM data for application: `FoodMe-{environment}`
4. Check nginx integration metrics

## Rollback Plan
If needed, you can rollback by:
1. Removing the `TF_VAR_new_relic_license_key` from GitHub Actions
2. Setting the variable to "none" to skip installation
3. The original functionality remains unchanged when New Relic is disabled
