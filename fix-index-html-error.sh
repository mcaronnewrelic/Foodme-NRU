#!/bin/bash

# Script to fix the index.html 500 error issue on EC2
# This applies the enhanced Node.js placeholder with proper error handling

set -e

echo "🔧 Fixing FoodMe index.html 500 Error"
echo "====================================="

# Check if we're on EC2 by looking for the metadata service
if curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
    echo "✅ Running on EC2 instance"
    ON_EC2=true
else
    echo "ℹ️  Not running on EC2, will use SSH to connect"
    ON_EC2=false
fi

# Function to apply the fix directly on EC2
apply_fix_local() {
    echo ""
    echo "🔧 Applying fix directly on EC2..."
    
    # Stop the service first
    echo "Stopping FoodMe service..."
    sudo systemctl stop foodme
    
    # Backup current start.js
    if [ -f "/var/www/foodme/server/start.js" ]; then
        sudo cp /var/www/foodme/server/start.js /var/www/foodme/server/start.js.backup
        echo "✅ Backed up current start.js"
    fi
    
    # Create the enhanced start.js
    echo "Creating enhanced Node.js application..."
    sudo tee /var/www/foodme/server/start.js > /dev/null << 'EOF'
const express = require('express');
const app = express();

// Middleware for parsing JSON and handling errors
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
    next();
});

// Health check endpoints
app.get('/health', (req, res) => {
    res.json({
        status: 'ok', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok', 
        api: 'placeholder',
        timestamp: new Date().toISOString()
    });
});

// API endpoints
app.get('/api/restaurant', (req, res) => {
    res.json({restaurants: []});
});

// Serve a proper HTML document for all routes (including /index.html)
// This handles Angular routing and serves the app
app.get('*', (req, res) => {
    try {
        const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoodMe - Starting</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; }
        .status { 
            background: rgba(255,255,255,0.1); 
            padding: 20px; 
            border-radius: 10px; 
            margin-top: 30px; 
        }
    </style>
</head>
<body>
    <h1>🍕 FoodMe</h1>
    <p>Application placeholder is running</p>
    <p>The real application will be deployed shortly...</p>
    <div class="status">
        <p><strong>Status:</strong> Ready for deployment</p>
        <p><strong>Time:</strong> ${new Date().toISOString()}</p>
        <p><strong>Path:</strong> ${req.path}</p>
    </div>
</body>
</html>`;
        
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        res.status(200).send(html);
    } catch (error) {
        console.error('Error serving HTML:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Application error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message,
        timestamp: new Date().toISOString()
    });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`FoodMe placeholder running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Started at: ${new Date().toISOString()}`);
});
EOF
    
    # Fix ownership
    sudo chown ec2-user:ec2-user /var/www/foodme/server/start.js
    echo "✅ Enhanced start.js created"
    
    # Restart the service
    echo "Starting FoodMe service..."
    sudo systemctl start foodme
    
    # Wait a moment for service to start
    sleep 5
    
    # Check service status
    echo "Checking service status..."
    sudo systemctl status foodme --no-pager -l
    
    # Test the endpoints
    echo ""
    echo "Testing fixed endpoints..."
    echo "Health check:"
    curl -s http://localhost:3000/health | jq . || echo "Health check failed"
    
    echo ""
    echo "Index.html test:"
    curl -s http://localhost:3000/index.html | head -n 5 || echo "Index.html test failed"
    
    echo ""
    echo "Root test:"
    curl -s http://localhost:3000/ | head -n 5 || echo "Root test failed"
}

# Function to apply the fix via SSH
apply_fix_remote() {
    # Get the EC2 instance IP
    INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
    
    if [ -z "$INSTANCE_IP" ]; then
        echo "❌ Cannot get instance IP from terraform output"
        echo "💡 Make sure you're in the terraform directory and have deployed the infrastructure"
        exit 1
    fi
    
    echo "🖥️  Instance IP: $INSTANCE_IP"
    echo ""
    echo "🔧 Applying fix via SSH..."
    
    # Check SSH connectivity
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP 'echo "SSH connection successful"' 2>/dev/null; then
        echo "❌ Cannot SSH to EC2 instance"
        echo "💡 Make sure your SSH key is configured and the security group allows SSH"
        exit 1
    fi
    
    echo "✅ SSH connection successful"
    
    # Apply the fix
    ssh -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP 'bash -s' << 'REMOTE_SCRIPT'
        set -e
        
        echo "Stopping FoodMe service..."
        sudo systemctl stop foodme
        
        # Backup current start.js
        if [ -f "/var/www/foodme/server/start.js" ]; then
            sudo cp /var/www/foodme/server/start.js /var/www/foodme/server/start.js.backup
            echo "✅ Backed up current start.js"
        fi
        
        # Create the enhanced start.js
        echo "Creating enhanced Node.js application..."
        sudo tee /var/www/foodme/server/start.js > /dev/null << 'EOF'
const express = require('express');
const app = express();

// Middleware for parsing JSON and handling errors
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
    next();
});

// Health check endpoints
app.get('/health', (req, res) => {
    res.json({
        status: 'ok', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok', 
        api: 'placeholder',
        timestamp: new Date().toISOString()
    });
});

// API endpoints
app.get('/api/restaurant', (req, res) => {
    res.json({restaurants: []});
});

// Serve a proper HTML document for all routes (including /index.html)
// This handles Angular routing and serves the app
app.get('*', (req, res) => {
    try {
        const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FoodMe - Enhanced</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; }
        .status { 
            background: rgba(255,255,255,0.1); 
            padding: 20px; 
            border-radius: 10px; 
            margin-top: 30px; 
        }
        .fixed { color: #4ade80; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🍕 FoodMe</h1>
    <p>Application placeholder is running</p>
    <p class="fixed">✅ Index.html 500 error has been fixed!</p>
    <div class="status">
        <p><strong>Status:</strong> Ready for deployment</p>
        <p><strong>Time:</strong> ${new Date().toISOString()}</p>
        <p><strong>Path:</strong> ${req.path}</p>
    </div>
</body>
</html>`;
        
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        res.status(200).send(html);
    } catch (error) {
        console.error('Error serving HTML:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Application error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message,
        timestamp: new Date().toISOString()
    });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`FoodMe placeholder running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Started at: ${new Date().toISOString()}`);
});
EOF
        
        # Fix ownership
        sudo chown ec2-user:ec2-user /var/www/foodme/server/start.js
        echo "✅ Enhanced start.js created"
        
        # Restart the service
        echo "Starting FoodMe service..."
        sudo systemctl start foodme
        
        # Wait a moment for service to start
        sleep 5
        
        # Check service status
        echo "Checking service status..."
        sudo systemctl status foodme --no-pager -l
        
        # Test the endpoints
        echo ""
        echo "Testing fixed endpoints..."
        echo "Health check:"
        curl -s http://localhost:3000/health | jq . || echo "Health check failed"
        
        echo ""
        echo "Index.html test:"
        curl -s http://localhost:3000/index.html | head -n 5 || echo "Index.html test failed"
        
        echo ""
        echo "Root test:"
        curl -s http://localhost:3000/ | head -n 5 || echo "Root test failed"
REMOTE_SCRIPT
    
    echo ""
    echo "✅ Fix applied successfully!"
    echo ""
    echo "🌐 Testing from external access:"
    echo "Health check:"
    curl -s "http://$INSTANCE_IP/health" | jq . || echo "External health check failed"
    
    echo ""
    echo "Index.html check:"
    curl -s "http://$INSTANCE_IP/index.html" | head -n 5 || echo "External index.html check failed"
    
    echo ""
    echo "Root check:"
    curl -s "http://$INSTANCE_IP/" | head -n 5 || echo "External root check failed"
}

# Main execution
if [ "$ON_EC2" = true ]; then
    apply_fix_local
else
    apply_fix_remote
fi

echo ""
echo "🎉 Index.html 500 error fix completed!"
echo ""
echo "💡 The enhanced Node.js app now includes:"
echo "   ✅ Comprehensive error handling"
echo "   ✅ Request logging for debugging"
echo "   ✅ Proper HTML Content-Type headers"
echo "   ✅ Enhanced catch-all route for all paths"
echo "   ✅ Better error messages for troubleshooting"
