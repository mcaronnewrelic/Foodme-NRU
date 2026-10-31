#!/bin/bash

# New Relic Infrastructure Setup Script
# =====================================
# This script sets up New Relic infrastructure monitoring for FoodMe

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 New Relic Infrastructure Setup for FoodMe${NC}"
echo "=================================================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found. Please create one from .env.example${NC}"
    echo "Run: cp .env.example .env"
    exit 1
fi

# Check if NEW_RELIC_LICENSE_KEY is set
if ! grep -q "NEW_RELIC_LICENSE_KEY" .env || grep -q "your_newrelic_license_key_here" .env; then
    echo -e "${YELLOW}⚠️  New Relic license key not properly configured${NC}"
    echo "Please update your .env file with a valid New Relic license key:"
    echo "NEW_RELIC_LICENSE_KEY=your_actual_license_key_here"
    echo ""
    echo "You can find your license key at: https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher"
    exit 1
fi

echo -e "${GREEN}✅ New Relic license key found in .env${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Stop existing containers
echo -e "${BLUE}🛑 Stopping existing containers...${NC}"
docker compose down

# Start services with New Relic infrastructure monitoring
echo -e "${BLUE}🚀 Starting FoodMe with New Relic infrastructure monitoring...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 10

# Check container status
echo -e "${BLUE}📊 Checking container status...${NC}"
docker compose ps

# Test New Relic integrations
echo -e "${BLUE}🔍 Testing New Relic integrations...${NC}"

# Check if New Relic Infrastructure Agent is running
if docker compose ps | grep -q "newrelic-infra.*Up"; then
    echo -e "${GREEN}✅ New Relic Infrastructure Agent is running${NC}"
else
    echo -e "${RED}❌ New Relic Infrastructure Agent is not running${NC}"
    echo "Check logs with: docker compose logs newrelic-infra"
fi

# Check if New Relic Nginx Integration is running
if docker compose ps | grep -q "newrelic-nginx.*Up"; then
    echo -e "${GREEN}✅ New Relic Nginx Integration is running${NC}"
else
    echo -e "${RED}❌ New Relic Nginx Integration is not running${NC}"
    echo "Check logs with: docker compose logs newrelic-nginx"
fi

# Check if New Relic PostgreSQL Integration is running
if docker compose ps | grep -q "newrelic-postgres.*Up"; then
    echo -e "${GREEN}✅ New Relic PostgreSQL Integration is running${NC}"
else
    echo -e "${RED}❌ New Relic PostgreSQL Integration is not running${NC}"
    echo "Check logs with: docker compose logs newrelic-postgres"
fi

# Test nginx status endpoint
echo -e "${BLUE}🌐 Testing nginx status endpoint...${NC}"
if curl -s http://localhost/nginx_status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Nginx status endpoint is accessible${NC}"
else
    echo -e "${RED}❌ Nginx status endpoint is not accessible${NC}"
    echo "This may be normal if nginx is not yet ready"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "📋 What's Been Set Up:"
echo "  • New Relic Infrastructure Agent - monitors host system and containers"
echo "  • New Relic Nginx Integration - monitors nginx reverse proxy"
echo "  • New Relic PostgreSQL Integration - monitors database performance"
echo ""
echo "📊 Monitor Your Application:"
echo "  • New Relic One: https://one.newrelic.com"
echo "  • Infrastructure: https://one.newrelic.com/launcher/infrastructure-ui.infrastructure-launcher"
echo ""
echo "🔧 Useful Commands:"
echo "  • View all logs: docker compose logs"
echo "  • View New Relic logs: docker compose logs newrelic-infra"
echo "  • Stop services: docker compose down"
echo "  • Test integrations: ./test-newrelic-integrations.sh"
echo ""
echo "⚠️  Note: It may take a few minutes for data to appear in New Relic"
