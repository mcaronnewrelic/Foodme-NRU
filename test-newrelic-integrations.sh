#!/bin/bash

# New Relic Integrations Test Script
# ==================================
# This script verifies that New Relic integrations are working correctly

echo "🔍 Testing New Relic Integrations for FoodMe"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if containers are running
echo -e "\n📦 Checking Docker Containers..."
if docker-compose ps | grep -q "newrelic-infra.*Up"; then
    echo -e "${GREEN}✅ New Relic Infrastructure Agent is running${NC}"
else
    echo -e "${RED}❌ New Relic Infrastructure Agent is not running${NC}"
fi

if docker-compose ps | grep -q "newrelic-nginx.*Up"; then
    echo -e "${GREEN}✅ New Relic Nginx Integration is running${NC}"
else
    echo -e "${RED}❌ New Relic Nginx Integration is not running${NC}"
fi

if docker-compose ps | grep -q "newrelic-postgres.*Up"; then
    echo -e "${GREEN}✅ New Relic PostgreSQL Integration is running${NC}"
else
    echo -e "${RED}❌ New Relic PostgreSQL Integration is not running${NC}"
fi

# Test Nginx status endpoint
echo -e "\n🌐 Testing Nginx Status Endpoint..."
if curl -s http://localhost/nginx_status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Nginx status endpoint is accessible${NC}"
    curl -s http://localhost/nginx_status | head -3
else
    echo -e "${RED}❌ Nginx status endpoint is not accessible${NC}"
fi

# Test PostgreSQL connection
echo -e "\n🗄️ Testing PostgreSQL Connection..."
if docker-compose exec -T db psql -U foodme_user -d foodme -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL connection is working${NC}"
    docker-compose exec -T db psql -U foodme_user -d foodme -c "SELECT 'Restaurants: ' || COUNT(*) FROM restaurants;"
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
fi

# Check integration logs for errors
echo -e "\n📋 Checking Integration Logs..."
echo -e "${YELLOW}Infrastructure Agent logs (last 5 lines):${NC}"
docker-compose logs --tail=5 newrelic-infra 2>/dev/null | grep -v "time=" | tail -5

echo -e "${YELLOW}Nginx Integration logs (last 5 lines):${NC}"
docker-compose logs --tail=5 newrelic-nginx 2>/dev/null | tail -5

echo -e "${YELLOW}PostgreSQL Integration logs (last 5 lines):${NC}"
docker-compose logs --tail=5 newrelic-postgres 2>/dev/null | tail -5

# Check environment variables
echo -e "\n🔐 Environment Configuration..."
if [ -n "$NEW_RELIC_LICENSE_KEY" ]; then
    echo -e "${GREEN}✅ NEW_RELIC_LICENSE_KEY is set${NC}"
else
    echo -e "${RED}❌ NEW_RELIC_LICENSE_KEY is not set${NC}"
fi

# Test custom metrics query
echo -e "\n📊 Testing Custom Metrics Query..."
if docker-compose exec -T db psql -U foodme_user -d foodme -c "
SELECT 
  'restaurants' as table_name,
  COUNT(*) as row_count
FROM restaurants
UNION ALL
SELECT 
  'menu_items' as table_name,
  COUNT(*) as row_count
FROM menu_items
UNION ALL
SELECT
  'orders' as table_name,
  COUNT(*) as row_count
FROM orders
UNION ALL
SELECT
  'customers' as table_name,
  COUNT(*) as row_count
FROM customers;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Custom metrics query is working${NC}"
    docker-compose exec -T db psql -U foodme_user -d foodme -c "
SELECT 
  'restaurants' as table_name,
  COUNT(*) as row_count
FROM restaurants
UNION ALL
SELECT 
  'menu_items' as table_name,
  COUNT(*) as row_count
FROM menu_items;"
else
    echo -e "${RED}❌ Custom metrics query failed${NC}"
fi

echo -e "\n🏁 Integration Test Complete!"
echo -e "💡 Check New Relic One for infrastructure data in 2-3 minutes"
echo -e "🔗 Navigate to: Infrastructure > Hosts and Infrastructure > Integrations"
