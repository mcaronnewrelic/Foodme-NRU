# New Relic Deployment Scripts

This directory conta## Sample Output

```bash
🚀 Creating New Relic deployment marker with entity search...
📋 Loading environment variables from .env file...
🔍 Searching for entity: FoodMe
📊 Deployment Details:
   User: Michael Caron
   Commit: 8241e893afea21bdd06af53bce5466de779790d6
   Changelog: 8241e89 cloud formation template and orders inserted into db
   Timestamp: 2025-10-03T01:07:02Z
🔍 Searching for FoodMe APM entity...
✅ Found entity: "FoodMe"
📋 Entity GUID: MTM1MjgxMXxBUE18QVBQTElDQVRJT044MTAwMjU4MDIxNg
🌐 Creating deployment marker in New Relic...
✅ Deployment marker created successfully!
📋 Deployment ID: cae6c2b7-4cd0-4457-b2e4-1e25ad31f8ca
🔗 Entity GUID: MTM1MjgxMXxBUE18QVBQTElDQVRJT044MTAwMjU4MDIxNg
🎉 New Relic deployment marker process completed!
```ating deployment markers in New Relic with automatic entity discovery.

## Available Scripts

### 1. Entity-Based Script (Recommended)
```bash
npm run newrelic:deployment
```
- **File**: `scripts/newrelic-deployment-entity.sh`
- **Features**: 
  - Automatically searches for "FoodMe" APM entity
  - Uses entity GUID for proper change tracking
  - Creates official New Relic deployment markers
  - Fallback search for any APPLICATION entities
- **Requirements**: `jq`, `curl`

### 2. Node.js Entity Script
```bash
npm run newrelic:deployment:direct
```
- **File**: `scripts/newrelic-deployment.js`
- **Features**: 
  - Same entity search functionality as shell script
  - Full GraphQL API integration
  - Better error handling and JSON parsing
- **Requirements**: Node.js only

### 3. Legacy/Fallback Scripts
```bash
npm run newrelic:deployment:legacy    # Original shell script
npm run newrelic:deployment:simple    # Simple Node.js version
```

## How Entity Discovery Works

1. **Primary Search**: Searches for entities with name LIKE 'FoodMe' AND type = 'APPLICATION'
2. **Fallback Search**: If no FoodMe entity found, searches for all APPLICATION entities
3. **Entity Selection**: Uses the first matching entity or shows available options
4. **Deployment Creation**: Creates a change tracking deployment marker using the entity GUID

## What the Scripts Capture

- **Entity GUID**: Automatically discovered from New Relic APM
- **User**: Git user name
- **Commit**: Full commit hash
- **Version**: Generated as `v1.0.0-{short-commit}`
- **Changelog**: Latest commit message
- **Timestamp**: Deployment time (epoch milliseconds)
- **Description**: "FoodMe Node.js Server Deployment"

## Sample Output

```bash
🚀 Creating New Relic deployment marker with entity search...
📋 Loading environment variables from .env file...
📊 Deployment Details:
   User: Michael Caron
   Commit: 8241e893afea21bdd06af53bce5466de779790d6
   Changelog: 8241e89 cloud formation template and orders inserted into db
   Timestamp: 2025-10-03T00:57:06Z
🔍 Searching for FoodMe APM entity...
✅ Found entity: "FoodMe"
📋 Entity GUID: MTM1MjgxMXxBUE18QVBQTElDQVRJT058MTAwMjU4MDIxNg
🌐 Creating deployment marker in New Relic...
✅ Deployment marker created successfully!
📋 Deployment ID: ee3b85d8-7954-43ae-96ed-6b0e535d2bac
🔗 Entity GUID: MTM1MjgxMXxBUE18QVBQTElDQVRJT058MTAwMjU4MDIxNg
🎉 New Relic deployment marker process completed!
```

## Environment Variables Required

Add these to your `.env` file:

```bash
# Required: New Relic API Key
NEW_RELIC_API_KEY="NRAK-your-api-key-here"

# Required: Application Name (used for entity search)
NEW_RELIC_APP_NAME="FoodMe"

# Optional: License Key (for Insights API)
NEW_RELIC_LICENSE_KEY="your-license-key-here"
```

## How Entity Discovery Works

1. **App Name**: Uses `NEW_RELIC_APP_NAME` from .env (defaults to "FoodMe")
2. **Primary Search**: Searches for entities with `name LIKE '{APP_NAME}' AND type = 'APPLICATION'`
3. **Fallback Search**: If no entity found, searches for all APPLICATION entities
4. **Entity Selection**: Uses the first matching entity or shows available options
5. **Deployment Creation**: Creates a change tracking deployment marker using the entity GUID

## Customizing the App Name

You can override the app name in several ways:

1. **Via .env file** (recommended):
   ```bash
   NEW_RELIC_APP_NAME="Your-App-Name"
   ```

2. **Via command line**:
   ```bash
   NEW_RELIC_APP_NAME="Your-App-Name" npm run newrelic:deployment
   ```

3. **Direct script execution**:
   ```bash
   NEW_RELIC_APP_NAME="Your-App-Name" ./scripts/newrelic-deployment-entity.sh
   ```

## What the Scripts Do

1. **Load Environment Variables**: Automatically reads from `.env` file
2. **Gather Git Information**: Gets user, commit hash, and changelog
3. **Validate API Connection**: Tests New Relic API connectivity
4. **Create Deployment Record**: Sends deployment marker to New Relic

## Deployment Information Captured

- **User**: Git user name
- **Commit**: Full commit hash
- **Version**: Generated from commit (e.g., `v1.0.0-8241e893`)
- **Changelog**: Latest commit message
- **Timestamp**: Deployment time
- **Description**: "FoodMe Node.js Server Deployment"

## Troubleshooting

### Common Issues:

1. **"authentication required"**: Check your `NEW_RELIC_API_KEY` in `.env`
2. **"Invalid JSON"**: Use the shell script instead (handles escaping better)
3. **"entity GUID required"**: Use the simple version or get entity GUID from New Relic

### Getting Entity GUID:

```bash
# Using New Relic CLI (if installed)
newrelic entity search --name FoodMe

# Or check your New Relic dashboard under "Entities"
```

## Integration with CI/CD

Add this to your deployment pipeline:

```bash
# After successful deployment
npm run newrelic:deployment
```

This helps track deployments in New Relic APM and correlate performance changes with code deployments.