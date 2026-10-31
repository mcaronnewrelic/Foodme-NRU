# Environment Variables for CloudFormation Deployment

## Overview
The deployment script now automatically reads New Relic configuration from your `.env` file, making deployments easier and more consistent.

## Usage Options

### Option 1: Using .env file (Recommended)
```bash
# The script will automatically read NEW_RELIC_LICENSE_KEY from .env
./cloudformation/deploy-stack.sh staging t3.small my-keypair MyPassword123
```

### Option 2: Override with command line parameter
```bash
# Pass New Relic license key as 5th parameter (overrides .env file)
./cloudformation/deploy-stack.sh staging t3.small my-keypair MyPassword123 your-license-key-here
```

### Option 3: Deploy without New Relic
```bash
# Pass empty string to disable New Relic (overrides .env file)
./cloudformation/deploy-stack.sh staging t3.small my-keypair MyPassword123 ""
```

## Environment Variables Loaded

The script loads these variables from `.env`:
- `NEW_RELIC_LICENSE_KEY` - Used for New Relic APM monitoring
- Any other environment variables you define

## Security Notes

1. **Keep .env file secure**: Never commit sensitive values to git
2. **Use .env.example**: Template for others to copy and fill in their values  
3. **Database passwords**: Still passed as command line arguments for security

## Example .env File

```bash
# New Relic Configuration
NEW_RELIC_LICENSE_KEY=your_actual_license_key_here
NEW_RELIC_APP_NAME=FoodMe

# Optional: AWS Configuration
AWS_DEFAULT_REGION=us-west-2
```

## What Happens During Deployment

1. Script loads environment variables from `.env` file
2. New Relic license key is passed to CloudFormation
3. EC2 instance is configured with proper environment variables
4. Application starts with New Relic monitoring enabled (if key provided)

## Troubleshooting

- **No .env file**: Script shows warning but continues (New Relic disabled)
- **Invalid license key**: Application starts but New Relic monitoring disabled
- **Empty license key**: New Relic monitoring automatically disabled