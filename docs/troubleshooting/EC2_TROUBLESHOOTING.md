# EC2 Troubleshooting

For the CloudFormation deployment. The Terraform guides are in [archive/terraform](../../archive/terraform/).

## Where does it fail?

| What you see | Go to |
|---|---|
| The stack fails to create or update | [Stack problems](#stack-problems) |
| `InvalidKeyPair.NotFound` | [EC2 Key Pair Setup](../../archive/terraform/EC2_KEYPAIR_SETUP.md). The key pair named in the `EC2_KEY_NAME` secret must exist in the deployment region. |
| The stack is fine, but the site does not load or is wrong | [On the instance](#on-the-instance) |
| The code deployment workflow fails | [The code deployment fails](#the-code-deployment-fails) |
| The New Relic infrastructure agent will not install on Amazon Linux 2023 | [New Relic on Amazon Linux 2023](../../archive/terraform/NEW_RELIC_AL2023_FIX.md) |
| You want to remove a deployment | [Removing a deployment](../deployment/DEPLOYMENT_GUIDE.md#removing-a-deployment) |

## How the deployment is set up

Checked on a running staging instance on 2026-10-31.

- **Traffic:** an Application Load Balancer listens on port 80. Requests to `/api/*` go to the backend target group (port 3000, health check `/health`). Everything else goes to nginx on port 8080 (health check `/`).
- **nginx** listens on ports 80 and 8080 and proxies everything (pages, static files, `/api/` and `/health`) to the Node app on port 3000. Only `/nginx-health` and `/nginx_status` are answered by nginx itself.
- **The Node app** serves the Angular build from `/opt/foodme/dist/browser`, and answers unknown paths with `index.html` so Angular routes work.
- **The backend** runs under **PM2** as `ec2-user`, as the process `foodme-backend`. There is no systemd unit for it. Its code is in `/opt/foodme/backend`, with the settings in `.env` and `ecosystem.config.js`, and its logs are in `/opt/foodme/logs`.
- **PostgreSQL 16** runs as the systemd service **`postgresql`** (not `postgresql-16`).
- **The Angular source** is in `/opt/foodme/angular-app` and is built on the instance.
- **Installation** runs once, when the instance first boots, from `install-foodme.sh` in the deployment S3 bucket. Its output is in `/var/log/cloud-init-output.log`.

## Getting onto the instance

The instance ID is the `EC2InstanceId` output of the stack.

```bash
# No SSH needed (requires the Session Manager plugin for the AWS CLI)
aws ssm start-session --target <instance-id>

# Or with the key pair
ssh -i foodme-keypair.pem ec2-user@<public-ip>
```

You can also run a command without logging in: `aws ssm send-command --instance-ids <id> --document-name AWS-RunShellScript --parameters '{"commands":["pm2 list"]}'`.

## Stack problems

```bash
# What failed, and why
aws cloudformation describe-stack-events --stack-name foodme-staging \
  --query 'StackEvents[?contains(ResourceStatus, `FAILED`)].[LogicalResourceId,ResourceStatusReason]' --output table
```

- A stack in `ROLLBACK_COMPLETE` cannot be updated. Delete it (the `delete-stack` action in the workflow, or `aws cloudformation delete-stack`) and deploy again.
- The stack parameters are the environment, the instance type, a key pair that already exists, a database password of at least 8 characters, an optional New Relic license key, and the S3 bucket with the deployment packages.
- Changing the instance's user data in a template update does not reinstall anything: the install script only runs at first boot. To apply installation changes, replace the instance (delete and deploy the stack).

## On the instance

### First checks

```bash
sudo systemctl status nginx postgresql        # both should be active
sudo -u ec2-user pm2 list                      # foodme-backend should be "online"
sudo -u ec2-user pm2 logs foodme-backend --lines 50 --nostream

curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/health   # the app
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health   # through nginx

sudo tail -50 /var/log/nginx/error.log
sudo tail -100 /var/log/cloud-init-output.log   # the installation
```

### The backend is not running

If `pm2 list` shows `errored` or `stopped`, or `/health` fails:

```bash
cd /opt/foodme/backend
sudo -u ec2-user node start.js        # run it by hand and read the error (stop it with Ctrl-C)
sudo -u ec2-user pm2 restart foodme-backend --update-env
```

Common causes: a missing or wrong value in `.env` (the database password, the New Relic key), the database not running, or dependencies not installed after a code change (`sudo -u ec2-user npm install --omit=dev`).

### The load balancer returns 502 or 503

The targets are unhealthy. Check them, then fix whichever of nginx (8080) or the backend (3000) is down:

```bash
aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `foodme`)].[TargetGroupName,TargetGroupArn]' --output text
aws elbv2 describe-target-health --target-group-arn <arn>
```

### A blank page, "Error loading application", or Angular routes returning 404

The Node app cannot find the Angular build, which it serves itself. Check `ls /opt/foodme/dist/browser/index.html`. To rebuild it on the instance:

```bash
cd /opt/foodme/angular-app
sudo -u ec2-user npm install
sudo -u ec2-user npm run build        # writes to /opt/foodme/dist
```

Angular 22 needs Node 22.22.3 or later, or 24.15 or later.

### The database

```bash
sudo systemctl status postgresql
sudo -u postgres psql -d foodme -c '\dt'
pg_isready
```

### The installation stopped partway

Read `/var/log/cloud-init-output.log` to find the step that failed. Because installation only runs at first boot, the simplest fix is usually to delete the stack and deploy it again.

### The Node.js version

`node -v` should say 24. Instances built before 2026-10-31 have Node 22. See [Node.js version](../deployment/DEPLOYMENT_GUIDE.md#nodejs-version) for the upgrade.

## The code deployment fails

The workflow and `cloudformation/deploy-code.sh` send commands to the instance through AWS Systems Manager.

- **"Could not find EC2 instance":** the stack `foodme-<environment>` does not exist in that region.
- **The command never starts:** the instance must show as Online in Systems Manager. Its role needs `AmazonSSMManagedInstanceCore`, which the template adds.
- **A command fails:** the script prints the error output. For the full record, run `aws ssm list-command-invocations --instance-id <id> --details --max-items 1`.
- **The health check at the end fails:** the backend did not come up after the restart. Run the first checks above.

## If it still fails

1. Read the CloudFormation events and `/var/log/cloud-init-output.log`.
2. Check CloudWatch logs for the instance.
3. Delete the stack and deploy it again. It builds everything from scratch.
