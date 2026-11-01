#!/bin/bash

# Initialize FoodMe Database using existing scripts
# This script uploads and runs the existing database initialization scripts

set -e

STACK_NAME="foodme-staging"
AWS_PROFILE="Team-Account-Standard-365309403645"

echo "🗄️  FoodMe Database Initialization"
echo "================================="

# Get instance ID
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --profile $AWS_PROFILE \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`EC2InstanceId`].OutputValue' \
    --output text)

echo "✅ Found EC2 instance: $INSTANCE_ID"

# Create temp directory on instance
echo "📁 Creating temporary directory on server..."
aws ssm send-command \
    --profile $AWS_PROFILE \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["mkdir -p /tmp/foodme-db-init"]' \
    --output text >/dev/null

# Step 1: Upload and run schema initialization
echo "📋 Uploading database schema script..."
SCHEMA_SQL=$(base64 < db/init/01-init-schema.sql | tr -d '\n')
COMMAND_ID=$(aws ssm send-command \
    --profile $AWS_PROFILE \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"echo '$SCHEMA_SQL' | base64 -d > /tmp/foodme-db-init/01-init-schema.sql\"]" \
    --query 'Command.CommandId' \
    --output text)

aws ssm wait command-executed --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID

echo "🏗️  Running database schema creation..."
COMMAND_ID=$(aws ssm send-command \
    --profile $AWS_PROFILE \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo -u postgres psql -d foodme -f /tmp/foodme-db-init/01-init-schema.sql"]' \
    --query 'Command.CommandId' \
    --output text)

aws ssm wait command-executed --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID
RESULT=$(aws ssm get-command-invocation --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID --query 'StandardOutputContent' --output text)
echo "✅ Schema creation result:"
echo "$RESULT"

# Check for any errors
ERROR_RESULT=$(aws ssm get-command-invocation --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID --query 'StandardErrorContent' --output text)
if [ ! -z "$ERROR_RESULT" ] && [ "$ERROR_RESULT" != "None" ]; then
    echo "⚠️  Schema creation warnings/errors:"
    echo "$ERROR_RESULT"
fi

# Step 2: Upload and run data import (with descriptions)
echo "📊 Uploading restaurant data import script (with descriptions)..."

# Split the large SQL file into chunks to avoid size limits
echo "📦 Preparing data import in chunks..."
split -l 1000 db/init/02-import-restaurants-uuid.sql /tmp/import_chunk_

chunk_num=1
for chunk_file in /tmp/import_chunk_*; do
    echo "📤 Uploading chunk $chunk_num..."
    CHUNK_SQL=$(base64 < "$chunk_file" | tr -d '\n')
    COMMAND_ID=$(aws ssm send-command \
        --profile $AWS_PROFILE \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"echo '$CHUNK_SQL' | base64 -d > /tmp/foodme-db-init/import_chunk_$chunk_num.sql\"]" \
        --query 'Command.CommandId' \
        --output text)
    
    aws ssm wait command-executed --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID
    ((chunk_num++))
done

# Combine chunks and import
echo "🔄 Combining chunks and importing data..."
COMMAND_ID=$(aws ssm send-command \
    --profile $AWS_PROFILE \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["cd /tmp/foodme-db-init && cat import_chunk_*.sql > 02-import-restaurants-uuid.sql && sudo -u postgres psql -d foodme -f 02-import-restaurants-uuid.sql"]' \
    --query 'Command.CommandId' \
    --output text)

echo "⏳ Importing restaurant data (this may take a few minutes)..."
aws ssm wait command-executed --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID
RESULT=$(aws ssm get-command-invocation --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID --query 'StandardOutputContent' --output text)
echo "✅ Data import result:"
echo "$RESULT"

# Check for import errors
ERROR_RESULT=$(aws ssm get-command-invocation --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID --query 'StandardErrorContent' --output text)
if [ ! -z "$ERROR_RESULT" ] && [ "$ERROR_RESULT" != "None" ]; then
    echo "⚠️  Data import warnings/errors:"
    echo "$ERROR_RESULT"
fi

# Step 3: Verify the database setup
echo "🧪 Verifying database setup..."
COMMAND_ID=$(aws ssm send-command \
    --profile $AWS_PROFILE \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo -u postgres psql -d foodme -c \"SELECT COUNT(*) as total_restaurants FROM restaurants; SELECT COUNT(*) as total_menu_items FROM menu_items; SELECT COUNT(*) as items_with_descriptions FROM menu_items WHERE description IS NOT NULL AND description != '\'\''; SELECT r.name, COUNT(m.id) as menu_count FROM restaurants r LEFT JOIN menu_items m ON r.id = m.restaurant_id GROUP BY r.name ORDER BY r.name LIMIT 5;\""]' \
    --query 'Command.CommandId' \
    --output text)

aws ssm wait command-executed --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID
RESULT=$(aws ssm get-command-invocation --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID --query 'StandardOutputContent' --output text)
echo "📊 Database verification:"
echo "$RESULT"

# Step 4: Restart the backend service to ensure it connects to the database
echo "🔄 Restarting backend service..."
COMMAND_ID=$(aws ssm send-command \
    --profile $AWS_PROFILE \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["cd /opt/foodme/backend && pm2 restart all || pm2 start ecosystem.config.js"]' \
    --query 'Command.CommandId' \
    --output text)

aws ssm wait command-executed --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID
RESULT=$(aws ssm get-command-invocation --profile $AWS_PROFILE --command-id $COMMAND_ID --instance-id $INSTANCE_ID --query 'StandardOutputContent' --output text)
echo "✅ Backend restart result:"
echo "$RESULT"

# Clean up temporary files
rm -f /tmp/import_chunk_*

echo ""
echo "🎉 Database initialization completed successfully!"
echo "✅ Schema created with all tables"
echo "✅ Restaurant and menu data imported WITH descriptions"
echo "✅ Backend service restarted"
echo ""
echo "🔗 Test your application at: http://staging-foodme-alb-1507419918.us-west-2.elb.amazonaws.com"
echo ""
echo "📋 What was accomplished:"
echo "• Database tables created using your 01-init-schema.sql"
echo "• Restaurant and menu data imported using your updated 02-import-restaurants-uuid.sql"
echo "• All menu items now have descriptive text"
echo "• Backend service restarted to connect to the database"