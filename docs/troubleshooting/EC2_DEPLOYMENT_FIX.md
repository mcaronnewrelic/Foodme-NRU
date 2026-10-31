# EC2 Deployment Fix Guide

## Issue Summary
The systemd service was failing due to an `ExecStartPre` command that tried to run `npm install` with insufficient permissions.

## Quick Fix (Run on EC2 Instance)

### Option 1: Complete Fix (Recommended)
```bash
# Download and run the complete fix script
wget https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/fix-complete-deployment.sh
chmod +x fix-complete-deployment.sh
./fix-complete-deployment.sh
```

### Option 2: Just Fix Systemd Service
```bash
# Download and run the systemd-only fix
wget https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/fix-systemd-service.sh
chmod +x fix-systemd-service.sh
./fix-systemd-service.sh
```

### Option 3: Manual Fix
```bash
# Stop the failing service
sudo systemctl stop foodme

# Create corrected service file (without ExecStartPre)
sudo tee /etc/systemd/system/foodme.service > /dev/null << 'EOF'
[Unit]
Description=FoodMe Node.js Application
After=network.target postgresql.service

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme
ExecStart=/usr/bin/node server/start.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000
StandardOutput=journal
StandardError=journal
SyslogIdentifier=foodme

[Install]
WantedBy=multi-user.target
EOF

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl start foodme
```

## What Was Fixed

### 1. Systemd Service Issues
- **Problem**: `ExecStartPre=/bin/bash -c 'if [ -f package.json ]; then npm install --production; fi'` was causing permission errors
- **Solution**: Removed the `ExecStartPre` line entirely since dependencies are installed during deployment
- **File**: `/etc/systemd/system/foodme.service`

### 2. Nginx Configuration
- **Problem**: Location block order and health check routing
- **Solution**: Reordered location blocks with exact match for `/health` first
- **File**: `/etc/nginx/conf.d/foodme.conf`

### 3. Permissions
- **Problem**: Incorrect ownership of application files
- **Solution**: Ensured `ec2-user:ec2-user` ownership of `/var/www/foodme`

## Verification Steps

After running the fix, verify everything is working:

```bash
# Check service status
sudo systemctl status foodme
sudo systemctl status nginx

# Check recent logs
sudo journalctl -u foodme -n 20

# Test endpoints
curl http://localhost/health
curl http://localhost/api/health
curl http://localhost/api/restaurants

# Check if accessible from outside
curl http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health
```

## Expected Results

✅ **systemd service should show**: `Active: active (running)`  
✅ **nginx should show**: `Active: active (running)`  
✅ **Health check should return**: `{"status":"healthy","timestamp":"..."}`  
✅ **Application accessible at**: `http://YOUR_EC2_IP/`

## Troubleshooting

If issues persist:

1. **Check logs**:
   ```bash
   sudo journalctl -u foodme --no-pager -f
   sudo tail -f /var/log/nginx/error.log
   ```

2. **Verify database**:
   ```bash
   sudo -u postgres psql -c "SELECT version();"
   sudo -u postgres psql -d foodme -c "\dt"
   ```

3. **Check Node.js app manually**:
   ```bash
   cd /var/www/foodme
   node server/start.js
   ```

4. **Test nginx config**:
   ```bash
   sudo nginx -t
   ```

## Files Modified
- `terraform/configs/foodme.service` - Removed problematic ExecStartPre
- `fix-complete-deployment.sh` - Complete deployment fix script
- `fix-systemd-service.sh` - Systemd-only fix script

## Next Steps
1. Run the fix script on your EC2 instance
2. Verify the application is accessible at your EC2 public IP
3. Test all API endpoints work correctly
4. Monitor the application for stability
