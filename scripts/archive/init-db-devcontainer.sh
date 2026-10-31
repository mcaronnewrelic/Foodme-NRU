#!/bin/bash

# Database initialization script for dev container environments
# This script manually initializes the database when volume mounts don't work

set -e

echo "🔍 Checking if database is running..."

# Wait for database to be ready
until docker compose -f docker/docker-compose.yml -f docker/docker-compose.devcontainer.yml exec db pg_isready -U foodme_user -d foodme; do
  echo "⏳ Waiting for database to be ready..."
  sleep 2
done

echo "✅ Database is ready!"

# Check if tables already exist
TABLE_COUNT=$(docker compose -f docker/docker-compose.yml -f docker/docker-compose.devcontainer.yml exec db psql -U foodme_user -d foodme -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")

if [ "$TABLE_COUNT" -gt 0 ]; then
  echo "✅ Database already initialized (found $TABLE_COUNT tables)"
  exit 0
fi

echo "🚀 Initializing database schema..."

# Copy and execute init scripts
docker compose -f docker/docker-compose.yml -f docker/docker-compose.devcontainer.yml exec -T db psql -U foodme_user -d foodme < db/init/01-init-schema.sql

echo "📊 Importing restaurant data..."
docker compose -f docker/docker-compose.yml -f docker/docker-compose.devcontainer.yml exec -T db psql -U foodme_user -d foodme < db/init/02-import-restaurants-uuid.sql

echo "✅ Database initialization complete!"

# Verify the setup
RESTAURANT_COUNT=$(docker compose -f docker/docker-compose.yml -f docker/docker-compose.devcontainer.yml exec db psql -U foodme_user -d foodme -t -c "SELECT COUNT(*) FROM restaurants;" 2>/dev/null | tr -d ' ' || echo "0")
echo "📈 Restaurant count: $RESTAURANT_COUNT"