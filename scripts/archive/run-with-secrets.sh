#!/bin/bash

# Simplified script to build and run with .env secrets

set -e  # Exit on any error

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "📝 Please create a .env file based on .env.example"
    echo "   cp .env.example .env"
    echo "   # Then edit .env with your actual values"
    exit 1
fi

echo "🔍 Found .env file"

# Validate required environment variables
source .env
REQUIRED_VARS=("NEW_RELIC_API_KEY" "NEW_RELIC_LICENSE_KEY")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ] || [ "${!var}" = "your_newrelic_api_key_here" ] || [ "${!var}" = "your_newrelic_license_key_here" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: Missing or placeholder values for required variables:"
    printf '   %s\n' "${MISSING_VARS[@]}"
    echo "📝 Please update your .env file with actual values"
    exit 1
fi

echo "✅ Environment variables validated"

# Choose method
echo ""
echo "Choose how to handle secrets:"
echo "1. 🔒 Runtime secrets (.env file loaded at runtime) - RECOMMENDED"
echo "2. 🐳 Docker Compose (with .env file)"
echo ""
read -p "Enter choice (1-2): " choice

case $choice in
    1)
        echo "🔨 Building Docker image..."
        docker build -t foodme:latest .
        
        echo "🚀 Running with .env file..."
        docker run -d \
            --name foodme-app \
            -p 3000:3000 \
            --env-file .env \
            foodme:latest
        
        echo "✅ Container started!"
        echo "📍 App running at: http://localhost:3000"
        echo "🔍 View logs: docker logs foodme-app"
        echo "🛑 Stop app: docker stop foodme-app && docker rm foodme-app"
        ;;
    2)
        echo "🐳 Using Docker Compose..."
        docker-compose up -d
        
        echo "✅ Services started!"
        echo "📍 App running at: http://localhost:3000"
        echo "🔍 View logs: docker-compose logs -f"
        echo "🛑 Stop services: docker-compose down"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
