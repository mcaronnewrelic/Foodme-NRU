#!/bin/bash

# Build script with different secret handling methods

echo "Choose your deployment method:"
echo "1. Development (with .env file) - RECOMMENDED"
echo "2. Production (with environment variables)"
echo "3. Production (with Docker secrets)"
echo "4. Production (with docker-compose)"
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Building for development..."
        docker build -f docker/Dockerfile -t foodme:dev .
        echo "Running with .env file..."
        docker run -p 3000:3000 --env-file .env foodme:dev
        ;;
    2)
        echo "Building for production..."
        docker build -f docker/Dockerfile -t foodme:prod .
        echo "Running with environment variables..."
        echo "Make sure to set NEW_RELIC_LICENSE_KEY and NEW_RELIC_API_KEY in your environment"
        docker run -p 3000:3000 \
            -e NODE_ENV=production \
            -e NEW_RELIC_LICENSE_KEY="${NEW_RELIC_LICENSE_KEY}" \
            -e NEW_RELIC_API_KEY="${NEW_RELIC_API_KEY}" \
            -e NEW_RELIC_APP_NAME="${NEW_RELIC_APP_NAME:-FoodMe-App}" \
            foodme:prod
        ;;
    3)
        echo "Using Docker Compose with secrets..."
        docker-compose -f docker/docker-compose.yml up --build foodme-with-secrets
        ;;
    4)
        echo "Using Docker Compose (standard)..."
        docker-compose -f docker/docker-compose.yml up --build
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
