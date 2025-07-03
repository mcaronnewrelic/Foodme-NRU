#!/bin/bash

# Docker Compose Configuration Selector for FoodMe
# =================================================
# This script helps you choose the right Docker Compose configuration for your environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 FoodMe Docker Compose Configuration Selector${NC}"
echo "=================================================="

# Function to detect environment
detect_environment() {
    if [ -n "$CODESPACES" ]; then
        echo "codespaces"
    elif [ -n "$DEVCONTAINER" ]; then
        echo "devcontainer"
    elif [ -f "/.dockerenv" ]; then
        echo "docker"
    elif [ "$(uname -s)" = "Darwin" ]; then
        echo "macos"
    elif [ "$(uname -s)" = "Linux" ]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Function to check if we have privileged access
check_privileged() {
    if docker run --rm --privileged alpine:latest echo "test" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Detect environment
ENV=$(detect_environment)
echo -e "${BLUE}🔍 Detected environment: ${ENV}${NC}"

# Check for privileged access
if check_privileged; then
    PRIVILEGED=true
    echo -e "${GREEN}✅ Privileged Docker access available${NC}"
else
    PRIVILEGED=false
    echo -e "${YELLOW}⚠️  Privileged Docker access not available${NC}"
fi

echo ""
echo -e "${BLUE}📋 Available configurations:${NC}"
echo "1. Main (Production) - Full monitoring with privileged access"
echo "2. DevContainer - Simplified monitoring for restricted environments"  
echo "3. Load Testing - Performance testing with Locust"
echo ""

# Recommend configuration
echo -e "${BLUE}💡 Recommended configuration:${NC}"

if [ "$ENV" = "codespaces" ] || [ "$ENV" = "devcontainer" ] || [ "$PRIVILEGED" = false ]; then
    RECOMMENDED="devcontainer"
    echo -e "${GREEN}DevContainer configuration${NC} (compatible with your environment)"
elif [ "$ENV" = "docker" ]; then
    RECOMMENDED="devcontainer"
    echo -e "${GREEN}DevContainer configuration${NC} (safer for container environments)"
else
    RECOMMENDED="main"
    echo -e "${GREEN}Main configuration${NC} (full monitoring capabilities)"
fi

echo ""
echo -e "${BLUE}🚀 Quick start commands:${NC}"

case $RECOMMENDED in
    "main")
        echo "# Start with full monitoring"
        echo "docker compose up -d"
        echo ""
        echo "# Or use npm script"
        echo "npm start"
        ;;
    "devcontainer")
        echo "# Start with dev container configuration"
        echo "docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d"
        echo ""
        echo "# Or use npm script"
        echo "npm run docker:compose:dev"
        ;;
esac

echo ""
echo -e "${BLUE}📊 For load testing:${NC}"
echo "docker compose -f docker-compose.loadtest.yml up"
echo "# Or: npm run docker:compose:loadtest"

echo ""
echo -e "${BLUE}📚 For more information:${NC}"
echo "• Main documentation: README.md"
echo "• DevContainer guide: DEVCONTAINER_SETUP.md"
echo "• Setup guide: SETUP_GUIDE.md"

echo ""
read -p "Would you like to start the recommended configuration now? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}🚀 Starting recommended configuration...${NC}"
    
    case $RECOMMENDED in
        "main")
            docker compose up -d
            ;;
        "devcontainer")
            docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
            ;;
    esac
    
    echo -e "${GREEN}✅ Services started successfully!${NC}"
    echo ""
    echo "View logs with:"
    case $RECOMMENDED in
        "main")
            echo "docker compose logs -f"
            ;;
        "devcontainer")
            echo "docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f"
            ;;
    esac
else
    echo -e "${BLUE}ℹ️  Configuration not started. Use the commands above when ready.${NC}"
fi
