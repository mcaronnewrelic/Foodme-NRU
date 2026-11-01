#!/bin/bash

# New Relic Deployment Marker Script with Entity Search
# This script searches for the FoodMe APM entity and creates a deployment marker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Creating New Relic deployment marker with entity search...${NC}"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Save any existing environment variables before loading .env
EXISTING_APP_NAME="$NEW_RELIC_APP_NAME"

# Load .env file if it exists
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${YELLOW}📋 Loading environment variables from .env file...${NC}"
    set -a  # Automatically export all variables
    source "$PROJECT_ROOT/.env"
    set +a  # Stop automatically exporting
fi

# Restore environment variable if it was set before (command line takes precedence)
if [ -n "$EXISTING_APP_NAME" ]; then
    NEW_RELIC_APP_NAME="$EXISTING_APP_NAME"
fi

# Check if NEW_RELIC_API_KEY is set
if [ -z "$NEW_RELIC_API_KEY" ]; then
    echo -e "${RED}❌ Error: NEW_RELIC_API_KEY environment variable is not set${NC}"
    echo -e "${YELLOW}💡 Please set your New Relic API key:${NC}"
    echo "   export NEW_RELIC_API_KEY='your-api-key-here'"
    echo "   Or add it to your .env file"
    exit 1
fi

# Set default app name if not provided
APP_NAME=${NEW_RELIC_APP_NAME:-"FoodMe"}
echo -e "${YELLOW}🔍 Searching for entity: $APP_NAME${NC}"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Get git information
USER=$(git config user.name || echo "Unknown User")
CHANGELOG=$(git log --oneline -1 || echo "No commit message")
COMMIT=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo -e "${YELLOW}📊 Deployment Details:${NC}"
echo "   User: $USER"
echo "   Commit: $COMMIT"
echo "   Changelog: $CHANGELOG"
echo "   Timestamp: $TIMESTAMP"

# Create the GraphQL query to search for the entity using APP_NAME
ENTITY_SEARCH_QUERY=$(cat <<EOF
{
  "query": "{ actor { entitySearch(query: \"name LIKE '$APP_NAME' AND type = 'APPLICATION'\") { results { entities { guid name type } } } } }"
}
EOF
)

# First, search for the APM entity
echo -e "${YELLOW}🔍 Searching for $APP_NAME APM entity...${NC}"

ENTITY_RESPONSE=$(curl -s -X POST "https://api.newrelic.com/graphql" \
  -H "Content-Type: application/json" \
  -H "API-Key: $NEW_RELIC_API_KEY" \
  -d "$ENTITY_SEARCH_QUERY")

# Check if the response contains errors
if echo "$ENTITY_RESPONSE" | grep -q '"errors"'; then
    echo -e "${RED}❌ Entity search error:${NC}"
    echo "$ENTITY_RESPONSE" | jq '.' 2>/dev/null || echo "$ENTITY_RESPONSE"
    exit 1
fi

# Extract the entity GUID
ENTITY_GUID=$(echo "$ENTITY_RESPONSE" | jq -r '.data.actor.entitySearch.results.entities[0].guid' 2>/dev/null)

if [ "$ENTITY_GUID" = "null" ] || [ -z "$ENTITY_GUID" ]; then
    echo -e "${YELLOW}⚠️  No $APP_NAME entity found. Available entities:${NC}"
    echo "$ENTITY_RESPONSE" | jq '.data.actor.entitySearch.results.entities[] | {name, type, guid}' 2>/dev/null || echo "No entities found"
    
    # Try a broader search
    echo -e "${YELLOW}🔍 Trying broader search for any APPLICATION entities...${NC}"
    BROAD_SEARCH_QUERY=$(cat <<'EOF'
{
  "query": "{ actor { entitySearch(query: \"type = 'APPLICATION'\") { results { entities { guid name type } } } } }"
}
EOF
)
    
    BROAD_RESPONSE=$(curl -s -X POST "https://api.newrelic.com/graphql" \
      -H "Content-Type: application/json" \
      -H "API-Key: $NEW_RELIC_API_KEY" \
      -d "$BROAD_SEARCH_QUERY")
    
    echo -e "${YELLOW}📋 Available APPLICATION entities:${NC}"
    echo "$BROAD_RESPONSE" | jq '.data.actor.entitySearch.results.entities[] | {name, type, guid}' 2>/dev/null || echo "No entities found"
    
    echo -e "${YELLOW}💡 Please ensure your $APP_NAME application is reporting to New Relic APM${NC}"
    echo -e "${YELLOW}   or update NEW_RELIC_APP_NAME in your .env file to match your entity name${NC}"
    exit 1
else
    ENTITY_NAME=$(echo "$ENTITY_RESPONSE" | jq -r '.data.actor.entitySearch.results.entities[0].name' 2>/dev/null)
    echo -e "${GREEN}✅ Found entity: $ENTITY_NAME${NC}"
    echo -e "${GREEN}📋 Entity GUID: $ENTITY_GUID${NC}"
fi

# Create the deployment tracking mutation with the entity GUID
DEPLOYMENT_QUERY=$(cat <<EOF
{
  "query": "mutation { changeTrackingCreateDeployment(deployment: { entityGuid: \"$ENTITY_GUID\", version: \"v1.0.0-${COMMIT:0:8}\", user: \"$USER\", description: \"$APP_NAME Node.js Server Deployment\", changelog: \"$CHANGELOG\", commit: \"$COMMIT\", timestamp: $(date +%s)000, deploymentType: BASIC }) { deploymentId entityGuid } }"
}
EOF
)

# Make the deployment API call
echo -e "${YELLOW}🌐 Creating deployment marker in New Relic...${NC}"

DEPLOYMENT_RESPONSE=$(curl -s -X POST "https://api.newrelic.com/graphql" \
  -H "Content-Type: application/json" \
  -H "API-Key: $NEW_RELIC_API_KEY" \
  -d "$DEPLOYMENT_QUERY")

# Check if the deployment was successful
if echo "$DEPLOYMENT_RESPONSE" | grep -q '"errors"'; then
    echo -e "${RED}❌ Error creating deployment marker:${NC}"
    echo "$DEPLOYMENT_RESPONSE" | jq '.' 2>/dev/null || echo "$DEPLOYMENT_RESPONSE"
    exit 1
elif echo "$DEPLOYMENT_RESPONSE" | grep -q '"deploymentId"'; then
    DEPLOYMENT_ID=$(echo "$DEPLOYMENT_RESPONSE" | jq -r '.data.changeTrackingCreateDeployment.deploymentId' 2>/dev/null)
    echo -e "${GREEN}✅ Deployment marker created successfully!${NC}"
    echo -e "${GREEN}📋 Deployment ID: $DEPLOYMENT_ID${NC}"
    echo -e "${GREEN}🔗 Entity GUID: $ENTITY_GUID${NC}"
else
    echo -e "${YELLOW}⚠️  Unexpected response:${NC}"
    echo "$DEPLOYMENT_RESPONSE" | jq '.' 2>/dev/null || echo "$DEPLOYMENT_RESPONSE"
fi

echo -e "${GREEN}🎉 New Relic deployment marker process completed!${NC}"