# 🔧 EC2 Deployment Troubleshooting Guide

Your FoodMe application is deployed at **http://54.188.233.101/** but experiencing issues:
- **403 Error**: Nginx can't find the index.html file  
- **Port 3000 Error**: Node.js application may not be running properly
- **Systemd Service Failing**: ExecStartPre npm install permission issues
- **Angular Routing Issues**: Nginx serving static files instead of proxying to Node.js

## 🚀 Quick Fix (Latest - Recommended)

### Option 1: Complete Deployment Fix with Node.js Proxy
```bash
# Connect to EC2
ssh ec2-user@54.188.233.101

# Apply nginx configuration to proxy ALL requests to Node.js
curl -O https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/apply-nodejs-proxy-nginx.sh
chmod +x apply-nodejs-proxy-nginx.sh
sudo ./apply-nodejs-proxy-nginx.sh

# Then run the complete deployment fix
curl -O https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/fix-complete-deployment.sh
chmod +x fix-complete-deployment.sh
./fix-complete-deployment.sh
```

### Option 2: Legacy Complete Deployment Fix
```bash
# Download and run the complete fix (old static file serving)
curl -O https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/fix-complete-deployment.sh
chmod +x fix-complete-deployment.sh
./fix-complete-deployment.sh
```

### Option 3: Systemd Service Fix Only
```bash
# If you only need to fix the systemd service
curl -O https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/fix-systemd-service.sh
chmod +x fix-systemd-service.sh
./fix-systemd-service.sh
```

## 🔄 Important: Angular Routing Configuration

The FoodMe application uses Angular client-side routing. There are two approaches to handle this:

### Approach 1: Node.js Proxy (Recommended)
- **All requests** (including `/`) are proxied to Node.js on port 3000
- Node.js serves the Angular application and handles routing via catch-all handler
- Static assets are served through Node.js with caching headers
- Use: `./apply-nodejs-proxy-nginx.sh`

### Approach 2: Static File Serving (Legacy)
- Nginx serves static files directly from filesystem
- Angular routes handled by nginx `try_files` directive
- API requests proxied to Node.js
- Use: `./fix-nginx-config.sh`

**Current Configuration Status:**
- The terraform configuration uses **static file serving** by default
- For Angular routing to work properly with Node.js, apply the proxy configuration

## 🔍 Common Issues and Solutions

### Issue 1: Angular Routes Return 404
**Symptoms:**
- Direct navigation to Angular routes like `/restaurants` returns 404
- Only root path `/` works

**Root Cause:** Nginx is serving static files and doesn't know about Angular routes

**Solutions:**
1. **Use Node.js Proxy (Recommended):**
   ```bash
   sudo ./apply-nodejs-proxy-nginx.sh
   ```

2. **Or fix static file configuration:**
   ```bash
   sudo ./fix-nginx-config.sh
   ```

### Issue 2: Systemd Service Won't Start
**Symptoms:**
```
● foodme.service - FoodMe Node.js Application
   Loaded: loaded (/etc/systemd/system/foodme.service; enabled; vendor preset: enabled)
   Active: failed (Result: exit-code) since...
```

**Root Cause:** The service file has an `ExecStartPre` that tries to run `npm install` with insufficient permissions.

**Solution:** Use the systemd fix script above, or manually update the service file:
```bash
sudo systemctl stop foodme
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

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable foodme
sudo systemctl start foodme
```

### Issue 3: 403 Error (Previous Issue)
```bash
# 🔧 Creating index.html file...
sudo cat > /var/www/foodme/index.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoodMe - Restaurant Discovery App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0; padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
        }
        .container {
            text-align: center; max-width: 600px; padding: 2rem;
            background: rgba(255, 255, 255, 0.1); border-radius: 15px;
            backdrop-filter: blur(10px); box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3); }
        p { font-size: 1.2rem; margin-bottom: 1.5rem; opacity: 0.9; }
        .api-links a {
            color: #fff; text-decoration: none; margin: 0 1rem; padding: 0.5rem 1rem;
            background: rgba(255, 255, 255, 0.2); border-radius: 5px; transition: background 0.3s;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍕 FoodMe</h1>
        <p>Your favorite restaurant discovery app is now live!</p>
        <div class="api-links">
            <a href="/health">Health Check</a>
            <a href="/api/health">API Health</a>
            <a href="/api/restaurant">Restaurants</a>
        </div>
    </div>
</body>
</html>
HTML

echo "✅ Setting file permissions..."
sudo chown -R nginx:nginx /var/www/foodme
sudo chmod -R 755 /var/www/foodme

echo "🔄 Restarting services..."
sudo systemctl restart foodme nginx

echo "🎉 Fix complete! Test your application:"
echo "• Root: http://54.188.233.101/"
echo "• Health: http://54.188.233.101/health"
EOF

# Run the fix
sudo chmod +x fix-deployment.sh
sudo ./fix-deployment.sh
```

## 🔍 Manual Troubleshooting

If the automated fix doesn't work, check these manually:

### Check Service Status
```bash
sudo systemctl status foodme
sudo systemctl status nginx
sudo systemctl status postgresql-16
```

### Check Application Logs
```bash
sudo journalctl -u foodme -f
sudo tail -f /var/log/nginx/error.log
```

### Test Connectivity
```bash
# Test app directly
curl http://localhost:3000/health

# Test through Nginx
curl http://localhost/health

# Check listening ports
sudo netstat -tlnp | grep -E ':80|:3000'
```

### Restart Services (if needed)
```bash
sudo systemctl restart postgresql-16
sudo systemctl restart foodme  
sudo systemctl restart nginx
```

## 🚀 Expected Results

After running the fix, you should see:
- **http://54.188.233.101/** → Beautiful FoodMe landing page
- **http://54.188.233.101/health** → `{"status":"ok","timestamp":"...","uptime":...}`
- **http://54.188.233.101/api/health** → `{"status":"ok","api":"ready"}`

## 📞 If Issues Persist

1. **Run diagnostics**: `sudo ./diagnose-deployment.sh`
2. **Check GitHub Actions logs** for deployment errors
3. **Verify security group** allows inbound traffic on port 80
4. **Check AWS CloudWatch logs** for additional insights

The most common issue is the missing `index.html` file which causes the 403 error. The fix script creates this file and sets proper permissions.
