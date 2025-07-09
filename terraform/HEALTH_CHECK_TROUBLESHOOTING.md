# EC2 Deployment Troubleshooting Guide

## Health Check Failures

When your GitHub Actions health check fails with the error you showed, it means the application isn't responding at the expected endpoint. Here's how to diagnose and fix it:

### Quick Diagnosis

1. **Run the enhanced diagnostic script:**
   ```bash
   ./terraform/diagnose-ec2.sh 52.10.167.10
   ```

2. **Check specific endpoints manually:**
   ```bash
   curl -v http://52.10.167.10/health
   curl -v http://52.10.167.10:3000/health
   curl -v http://52.10.167.10/
   ```

### Common Causes & Solutions

#### 1. Application Not Started
**Symptoms:** All endpoints return connection refused or timeout
**Check:**
```bash
ssh -i your-key.pem ec2-user@52.10.167.10
sudo docker ps
sudo systemctl status docker
```
**Fix:** Restart Docker containers if they're not running

#### 2. User Data Script Failed
**Symptoms:** Instance running but no services
**Check:**
```bash
sudo cat /var/log/cloud-init-output.log
sudo journalctl -u cloud-final
```
**Fix:** Check for errors in the user data script execution

#### 3. Nginx Configuration Issue
**Symptoms:** Port 80 works but shows default page, port 3000 works
**Check:**
```bash
sudo nginx -t
sudo systemctl status nginx
sudo cat /etc/nginx/sites-available/foodme.conf
```
**Fix:** Verify nginx is proxying to the correct port

#### 4. Security Group Issues
**Symptoms:** Connection timeouts
**Check:** AWS Console -> EC2 -> Security Groups
**Fix:** Ensure inbound rules allow:
- Port 22 (SSH) from your IP
- Port 80 (HTTP) from 0.0.0.0/0
- Port 443 (HTTPS) from 0.0.0.0/0

#### 5. Docker Build Failures
**Symptoms:** Container not running or constantly restarting
**Check:**
```bash
sudo docker logs foodme-app
sudo docker ps -a
```
**Fix:** Check application logs for startup errors

### Enhanced Health Check

The enhanced health check script (`./terraform/enhanced-health-check.sh`) provides:
- Multiple endpoint testing (/, /health, :3000/, etc.)
- Detailed diagnostics every 3rd attempt
- Better error reporting
- Connectivity tests
- Troubleshooting suggestions

### Manual Testing Steps

1. **Test from GitHub Actions runner:**
   ```bash
   # Add this to your workflow for debugging
   - name: Debug health check
     run: |
       echo "Testing endpoints..."
       curl -v http://${{ steps.instance.outputs.ip }}/health || true
       curl -v http://${{ steps.instance.outputs.ip }}:3000/health || true
       curl -v http://${{ steps.instance.outputs.ip }}/ || true
       ./terraform/diagnose-ec2.sh ${{ steps.instance.outputs.ip }}
   ```

2. **SSH debugging:**
   ```bash
   # SSH to instance
   ssh -i your-key.pem ec2-user@52.10.167.10
   
   # Check services
   sudo systemctl status nginx
   sudo systemctl status docker
   sudo docker ps -a
   
   # Check application
   curl localhost:3000/health
   curl localhost/health
   
   # Check logs
   sudo docker logs foodme-app
   sudo tail -f /var/log/nginx/error.log
   ```

### GitHub Actions Improvements

Replace your current health check with:

```yaml
- name: Enhanced Health Check
  run: |
    ./terraform/enhanced-health-check.sh ${{ steps.instance.outputs.ip }} ${{ env.SKIP_SSH_DEPLOYMENT }}
```

### Expected Health Response

Your health endpoint should return:
```json
{
  "status": "healthy",
  "timestamp": "2025-07-09T...",
  "uptime": 123.456,
  "memory": {...},
  "pid": 1234,
  "version": "v18.x.x",
  "environment": "production",
  "dataSource": "PostgreSQL",
  "database": {
    "status": "connected",
    "type": "PostgreSQL"
  }
}
```

### Emergency Fixes

If deployment is stuck:

1. **Force restart services:**
   ```bash
   ssh -i your-key.pem ec2-user@52.10.167.10
   sudo systemctl restart nginx
   sudo docker restart $(sudo docker ps -q)
   ```

2. **Redeploy from scratch:**
   ```bash
   # In Terraform directory
   terraform destroy -auto-approve
   terraform apply -auto-approve
   ```

3. **Skip health check temporarily:**
   ```yaml
   # In GitHub Actions
   - name: Health Check
     run: echo "Skipping health check for debugging"
     # run: ./terraform/enhanced-health-check.sh ...
   ```

### Monitoring Commands

Add these to your deployment for better visibility:

```bash
# Pre-deployment checks
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].State.Name'

# Post-deployment monitoring  
watch -n 5 'curl -s http://52.10.167.10/health | jq .'
```
