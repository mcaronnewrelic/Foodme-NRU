#!/usr/bin/env node

/**
 * New Relic Deployment Marker Script
 * Creates a deployment marker in New Relic using the GraphQL API
 */

const { execSync } = require('child_process');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Load .env file if it exists
function loadEnvFile() {
  const envPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(envPath)) {
    log('📋 Loading environment variables from .env file...', 'yellow');
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

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function createDeploymentMarker() {
  try {
    log('🚀 Creating New Relic deployment marker...', 'yellow');

    // Load environment variables
    loadEnvFile();

    // Check for API key
    const apiKey = process.env.NEW_RELIC_API_KEY;
    if (!apiKey) {
      log('❌ Error: NEW_RELIC_API_KEY environment variable is not set', 'red');
      log('💡 Please set your New Relic API key:', 'yellow');
      log('   export NEW_RELIC_API_KEY=\'your-api-key-here\'');
      log('   Or add it to your .env file');
      process.exit(1);
    }

    // Get app name from environment or use default
    const appName = process.env.NEW_RELIC_APP_NAME || 'FoodMe';
    log(`🔍 Searching for entity: ${appName}`, 'yellow');

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

    const timestamp = Date.now();
    const version = `v1.0.0-${commit.substring(0, 8)}`;

    log('📊 Deployment Details:', 'yellow');
    log(`   User: ${user}`);
    log(`   Commit: ${commit}`);
    log(`   Version: ${version}`);
    log(`   Changelog: ${changelog}`);

    // First, search for the APM entity
    log(`🔍 Searching for ${appName} APM entity...`, 'yellow');
    
    const entitySearchQuery = {
      query: `{ 
        actor { 
          entitySearch(query: "name LIKE '${appName}' AND type = 'APPLICATION'") { 
            results { 
              entities { 
                guid 
                name 
                type 
              } 
            } 
          } 
        } 
      }`
    };

    const entityResponse = await makeGraphQLRequest(apiKey, entitySearchQuery);

    if (entityResponse.errors) {
      log('❌ Entity search error:', 'red');
      console.log(JSON.stringify(entityResponse.errors, null, 2));
      process.exit(1);
    }

    const entities = entityResponse.data?.actor?.entitySearch?.results?.entities || [];
    
    if (entities.length === 0) {
      log(`⚠️  No ${appName} entity found. Trying broader search...`, 'yellow');
      
      // Try broader search
      const broadSearchQuery = {
        query: `{ 
          actor { 
            entitySearch(query: "type = 'APPLICATION'") { 
              results { 
                entities { 
                  guid 
                  name 
                  type 
                } 
              } 
            } 
          } 
        }`
      };

      const broadResponse = await makeGraphQLRequest(apiKey, broadSearchQuery);
      const allEntities = broadResponse.data?.actor?.entitySearch?.results?.entities || [];
      
      log('📋 Available APPLICATION entities:', 'yellow');
      allEntities.forEach(entity => {
        log(`   - ${entity.name} (${entity.type}) - ${entity.guid}`);
      });
      
      log('💡 Please ensure your application is reporting to New Relic APM', 'yellow');
      log('   and NEW_RELIC_APP_NAME in .env matches your entity name', 'yellow');
      process.exit(1);
    }

    const entity = entities[0];
    log(`✅ Found entity: ${entity.name}`, 'green');
    log(`📋 Entity GUID: ${entity.guid}`, 'green');

    // Create deployment tracking mutation
    const deploymentMutation = {
      query: `mutation {
        changeTrackingCreateDeployment(
          deployment: {
            entityGuid: "${entity.guid}"
            version: "${version}"
            user: "${user.replace(/"/g, '\\"')}"
            description: "${appName} Node.js Server Deployment"
            changelog: "${changelog.replace(/"/g, '\\"')}"
            commit: "${commit}"
            timestamp: ${timestamp}
            deploymentType: BASIC
          }
        ) {
          deploymentId
          entityGuid
        }
      }`
    };

    log('🌐 Creating deployment marker in New Relic...', 'yellow');

    const deploymentResponse = await makeGraphQLRequest(apiKey, deploymentMutation);

    if (deploymentResponse.errors) {
      log('❌ Error creating deployment marker:', 'red');
      console.log(JSON.stringify(deploymentResponse.errors, null, 2));
      process.exit(1);
    } else if (deploymentResponse.data?.changeTrackingCreateDeployment) {
      const deploymentId = deploymentResponse.data.changeTrackingCreateDeployment.deploymentId;
      log('✅ Deployment marker created successfully!', 'green');
      log(`📋 Deployment ID: ${deploymentId}`, 'green');
      log(`� Entity GUID: ${entity.guid}`, 'green');
    } else {
      log('⚠️  Unexpected response:', 'yellow');
      console.log(JSON.stringify(deploymentResponse, null, 2));
    }

    log('🎉 New Relic deployment marker process completed!', 'green');

  } catch (error) {
    log(`❌ Error: ${error.message}`, 'red');
    process.exit(1);
  }
}

function makeRESTRequest(apiKey, deploymentData) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(deploymentData);
    
    const options = {
      hostname: 'api.newrelic.com',
      port: 443,
      path: '/v2/applications.json', // First, let's get the application ID
      method: 'GET',
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json'
      }
    };

    // First, get the application list to find our app
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = JSON.parse(responseData);
          
          if (parsedData.applications && parsedData.applications.length > 0) {
            // Find the FoodMe application
            const app = parsedData.applications.find(app => 
              app.name === 'FoodMe' || app.name.includes('FoodMe')
            ) || parsedData.applications[0]; // Fallback to first app
            
            // Now create deployment for this app
            createDeploymentForApp(apiKey, app.id, deploymentData.deployment)
              .then(resolve)
              .catch(reject);
          } else {
            resolve({ error: 'No applications found' });
          }
        } catch (error) {
          reject(new Error(`Failed to parse response: ${responseData}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

function createDeploymentForApp(apiKey, appId, deploymentData) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ deployment: deploymentData });
    
    const options = {
      hostname: 'api.newrelic.com',
      port: 443,
      path: `/v2/applications/${appId}/deployments.json`,
      method: 'POST',
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = JSON.parse(responseData);
          resolve(parsedData);
        } catch (error) {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ success: true, raw: responseData });
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
          }
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

function makeGraphQLRequest(apiKey, query) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(query);
    
    const options = {
      hostname: 'api.newrelic.com',
      port: 443,
      path: '/graphql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'API-Key': apiKey,
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = JSON.parse(responseData);
          resolve(parsedData);
        } catch (error) {
          reject(new Error(`Failed to parse response: ${responseData}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

// Run the script
if (require.main === module) {
  createDeploymentMarker();
}

module.exports = { createDeploymentMarker };