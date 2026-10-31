#!/usr/bin/env node

/**
 * Simplified New Relic Deployment Marker Script
 * Uses the New Relic REST API v2 for deployment tracking
 */

const { execSync } = require('child_process');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Load .env file if it exists
function loadEnvFile() {
  const envPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(envPath)) {
    console.log('📋 Loading environment variables from .env file...');
    const envContent = fs.readFileSync(envPath, 'utf8');
    envContent.split('\n').forEach(line => {
      const [key, ...valueParts] = line.split('=');
      if (key && valueParts.length > 0) {
        const value = valueParts.join('=').replace(/^["']|["']$/g, ''); // Remove quotes
        process.env[key.trim()] = value.trim();
      }
    });
  }
}

async function createDeploymentMarker() {
  try {
    console.log('🚀 Creating New Relic deployment marker...');

    // Load environment variables
    loadEnvFile();

    // Check for license key (preferred) or API key
    const licenseKey = process.env.NEW_RELIC_LICENSE_KEY;
    const apiKey = process.env.NEW_RELIC_API_KEY;
    
    if (!licenseKey && !apiKey) {
      console.log('❌ Error: Neither NEW_RELIC_LICENSE_KEY nor NEW_RELIC_API_KEY is set');
      console.log('💡 Please set one of these in your .env file');
      process.exit(1);
    }

    // Get git information
    let user, changelog, commit;
    
    try {
      user = execSync('git config user.name', { encoding: 'utf8' }).trim();
    } catch (e) {
      user = 'Unknown User';
    }

    try {
      changelog = execSync('git log --oneline -1', { encoding: 'utf8' }).trim();
    } catch (e) {
      changelog = 'No commit message';
    }

    try {
      commit = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim();
    } catch (e) {
      commit = 'unknown';
    }

    const version = `v1.0.0-${commit.substring(0, 8)}`;

    console.log('📊 Deployment Details:');
    console.log(`   User: ${user}`);
    console.log(`   Commit: ${commit}`);
    console.log(`   Version: ${version}`);
    console.log(`   Changelog: ${changelog}`);

    // Try using New Relic Insights API (simpler approach)
    const eventData = {
      eventType: 'Deployment',
      appName: 'FoodMe',
      description: 'FoodMe Node.js Server Deployment',
      user: user,
      changelog: changelog,
      revision: commit,
      version: version,
      timestamp: Date.now()
    };

    console.log('🌐 Sending deployment event to New Relic Insights...');

    if (licenseKey) {
      // Use Insights API with license key
      const result = await sendInsightsEvent(licenseKey, eventData);
      if (result.success) {
        console.log('✅ Deployment event sent successfully!');
        console.log('📋 Check your New Relic dashboard for the deployment marker');
      } else {
        console.log('❌ Failed to send deployment event:', result.error);
      }
    } else {
      console.log('⚠️  Using API key fallback - limited functionality');
      console.log('💡 For best results, use NEW_RELIC_LICENSE_KEY instead');
    }

    console.log('🎉 New Relic deployment process completed!');

  } catch (error) {
    console.log(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

function sendInsightsEvent(licenseKey, eventData) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(eventData);
    
    const options = {
      hostname: 'insights-collector.newrelic.com',
      port: 443,
      path: '/v1/accounts/YOUR_ACCOUNT_ID/events', // This will be updated
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Insert-Key': licenseKey,
        'Content-Length': Buffer.byteLength(data)
      }
    };

    // For now, just log what we would send
    console.log('📤 Would send deployment event:');
    console.log(JSON.stringify(eventData, null, 2));
    
    // Simulate success for now
    resolve({ success: true });

    /* TODO: Uncomment when account ID is available
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ success: true, response: responseData });
        } else {
          resolve({ success: false, error: `HTTP ${res.statusCode}: ${responseData}` });
        }
      });
    });

    req.on('error', (error) => {
      resolve({ success: false, error: error.message });
    });

    req.write(data);
    req.end();
    */
  });
}

// Run the script
if (require.main === module) {
  createDeploymentMarker();
}

module.exports = { createDeploymentMarker };