#!/bin/bash
set -e

# Install packages
dnf update -y && dnf install -y git nginx nodejs npm amazon-cloudwatch-agent --allowerasing
npm install -g pm2

# Setup directories
mkdir -p /var/www/foodme/{server,logs} && chown -R ec2-user:ec2-user /var/www/foodme

# Nginx config
cat > /etc/nginx/conf.d/foodme.conf << 'EOF'
server {
    listen 80;
    server_name _;
    location /api/ { proxy_pass http://localhost:3000; }
    location /health { proxy_pass http://localhost:3000/health; access_log off; }
    location / { root /var/www/foodme; try_files $uri $uri/ /index.html; }
}
EOF

# Systemd service
cat > /etc/systemd/system/foodme.service << 'EOF'
[Unit]
Description=FoodMe App
After=network.target
[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/foodme
ExecStart=/usr/bin/node server/start.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=3000
[Install]
WantedBy=multi-user.target
EOF

# Minimal app
cat > /var/www/foodme/package.json << 'EOF'
{"name":"foodme","version":"1.0.0","main":"server/start.js","dependencies":{"express":"^4.18.2"}}
EOF

cat > /var/www/foodme/server/start.js << 'EOF'
const express = require('express');
const app = express();
app.use(express.json());
app.get('/health', (req, res) => res.json({status: 'ok', timestamp: new Date().toISOString(), uptime: process.uptime()}));
app.get('/api/health', (req, res) => res.json({status: 'ok', api: 'ready'}));
app.get('/api/restaurant', (req, res) => res.json({restaurants: []}));
app.get('*', (req, res) => res.send('<!DOCTYPE html><html><head><title>FoodMe</title><style>body{font-family:Arial;text-align:center;padding:50px;background:#667eea}</style></head><body><h1>🍕 FoodMe</h1><p>Application is ready!</p></body></html>'));
app.listen(3000, () => console.log('FoodMe running on port 3000'));
EOF

# Health check script
cat > /var/www/foodme/health-check.sh << 'EOF'
#!/bin/bash
for i in {1..3}; do
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ Health check passed"
        exit 0
    fi
    sleep 2
done
echo "❌ Health check failed"
exit 1
EOF
chmod +x /var/www/foodme/health-check.sh

# Deploy script
cat > /var/www/foodme/deploy.sh << 'EOF'
#!/bin/bash
set -e
echo "Deploying FoodMe..."
if [ -f "package.json" ] && grep -q '"name": "foodme"' package.json; then
    npm install --production
    [ -d "angular-app" ] && cd angular-app && npm install && npm run build && cd .. && cp -r angular-app/dist/* . 2>/dev/null || true
fi
sudo systemctl restart foodme
sleep 10
/var/www/foodme/health-check.sh && echo "✅ Deploy success" || (echo "❌ Deploy failed" && exit 1)
EOF
chmod +x /var/www/foodme/deploy.sh

# CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{"metrics":{"namespace":"FoodMe","metrics_collected":{"cpu":{"measurement":["cpu_usage_user"],"metrics_collection_interval":300},"mem":{"measurement":["mem_used_percent"],"metrics_collection_interval":300}}},"logs":{"logs_collected":{"files":{"collect_list":[{"file_path":"/var/log/foodme/*.log","log_group_name":"foodme-logs","log_stream_name":"{instance_id}"}]}}}}
EOF

# Install and start
sudo -u ec2-user bash -c 'cd /var/www/foodme && npm install'
systemctl enable nginx foodme && systemctl start nginx foodme

# Start CloudWatch
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Test
sleep 5 && curl -f http://localhost:3000/health && echo "✅ Setup complete"
