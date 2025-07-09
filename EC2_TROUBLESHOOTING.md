# 🔧 EC2 Deployment Troubleshooting Guide

Your FoodMe application is deployed at **http://54.188.233.101/** but experiencing issues:
- **403 Error**: Nginx can't find the index.html file  
- **Port 3000 Error**: Node.js application may not be running properly

## 🚀 Quick Fix (Recommended)

### Step 1: Connect to your EC2 instance
```bash
# If you have the SSH key file
ssh -i /path/to/your-key.pem ec2-user@54.188.233.101

# If using GitHub SSH key setup
ssh ec2-user@54.188.233.101
```

### Step 2: Run the automated fix
```bash
# Download and run the fix script
curl -O https://raw.githubusercontent.com/mcaronnewrelic/Foodme-NRU/main/fix-deployment.sh
sudo chmod +x fix-deployment.sh
sudo ./fix-deployment.sh
```

**OR** copy the fix script manually:

```bash
# Create the fix script
sudo tee fix-deployment.sh > /dev/null << 'EOF'
#!/bin/bash
echo "🔧 Creating index.html file..."
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
