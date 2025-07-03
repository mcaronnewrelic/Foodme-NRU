# FoodMe Database Setup Guide

This guide explains how to set up and initialize the PostgreSQL database with restaurant data from the `restaurants.json` file.

## 🗄️ Database Overview

The FoodMe application uses PostgreSQL as its primary database with the following structure:

- **restaurants** - Restaurant information (name, cuisine, ratings, etc.)
- **menu_items** - Menu items for each restaurant
- **customers** - Customer information
- **orders** - Order history
- **order_items** - Individual items within orders

## 🔧 Recent Updates (July 2025)

**Database Initialization Improvements:**
- ✅ Removed legacy SQL files that caused UUID compatibility issues
- ✅ Streamlined initialization to use only 2 scripts (schema + data)
- ✅ Fixed deterministic UUID generation for consistent restaurant IDs
- ✅ Eliminated duplicate import scripts and manual data entries
- ✅ Improved error handling and logging during initialization


## 🚀 Quick Start

### 1. Start the Database

```bash
# Start PostgreSQL with Docker Compose
docker compose up -d db

# Check if database is running
docker compose ps
```

### 2. Initialize with Restaurant Data

**Option A: Fresh Database (Recommended)**
```bash
# Stop and remove existing database (if any)
docker compose down -v

# Generate UUID-compatible import SQL
npm run db:generate-import-uuid

# Start fresh database (will auto-run initialization scripts)
docker compose up -d db

# Wait for initialization to complete
sleep 10
```

**Option B: Import into Running Database**
```bash
# Generate UUID-compatible import SQL
npm run db:generate-import-uuid

# Import restaurant data manually
docker compose exec -T db psql -U foodme_user -d foodme < db/init/02-import-restaurants-uuid.sql
```

**Initialization Scripts (run alphabetically):**
1. **`01-init-schema.sql`** - Creates tables, indexes, and basic structure
2. **`02-import-restaurants-uuid.sql`** - Imports all restaurants with UUID compatibility (auto-generated)

**✨ Simplified Workflow:**
The database now initializes completely automatically with just:
```bash
docker compose up -d db
```
This will:
- Create the database schema
- Import all 39 restaurants with proper UUIDs
- Set up menu items and relationships
- Complete in under 30 seconds

### 3. Verify the Setup

```bash
# Test database connection and view data
npm run db:test

# Connect to database directly
npm run db:connect
```

## 📊 Database Commands

### Data Management

```bash
# Generate UUID-compatible import SQL
npm run db:generate-import-uuid

# Import restaurant data into running database
docker compose exec -T db psql -U foodme_user -d foodme < db/init/02-import-restaurants-uuid.sql

# Test database connection and show statistics
npm run db:test

# Connect to database (PostgreSQL CLI)
npm run db:connect

# Create database backup
npm run db:backup

# Restore from backup
npm run db:restore

# View database logs
npm run db:logs
```

### Docker Compose Commands

```bash
# Start just the database
docker compose up -d db

# Start all services (database + application)
docker compose up -d

# Stop the database
docker compose stop db

# View database logs
docker compose logs db

# Restart database (useful if it's not responding)
docker compose restart db

# Remove database (⚠️ deletes all data)
docker compose down -v

# Fresh start with clean database
docker compose down -v && npm run db:generate-import-uuid && docker compose up -d
```

## 🔧 Database Configuration

### Connection Settings

The database uses these default settings:

- **Host**: `localhost` (or `db` in Docker network)
- **Port**: `5432`
- **Database**: `foodme`
- **User**: `foodme_user`
- **Password**: Stored in `db/password.txt`

### Environment Variables

You can override settings in your `.env` file:

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=foodme
DB_USER=foodme_user
DB_PASSWORD=your_database_password_here
DB_SSL=false
```

## 📁 File Structure

```
db/
├── password.txt                    # Database password (gitignored)
├── scripts/                       # Database utility scripts
│   ├── import-restaurants-uuid.js # UUID-compatible import script
│   └── test-database.js          # Tests connection and shows data
└── init/                          # Initialization scripts (run alphabetically)
    ├── 01-init-schema.sql         # Database schema and tables
    └── 02-import-restaurants-uuid.sql # UUID-compatible import (auto-generated)

server/data/
└── restaurants.json               # Source restaurant data
```

## 🐳 Loading Data with Docker Compose

### Method 1: Fresh Start (Recommended)

This method ensures a clean database with proper initialization:

```bash
# 1. Stop and remove any existing database
docker compose down -v

# 2. Generate UUID-compatible import SQL
npm run db:generate-import-uuid

# 3. Start the database (auto-runs init scripts)
docker compose up -d db

# 4. Wait for initialization to complete
sleep 10

# 5. Verify data was loaded
docker compose exec db psql -U foodme_user -d foodme -c "SELECT COUNT(*) FROM restaurants;"
```

### Method 2: Import into Running Database

If you already have a running database:

```bash
# 1. Generate UUID-compatible import SQL
npm run db:generate-import-uuid

# 2. Clear existing data and import fresh
docker compose exec -T db psql -U foodme_user -d foodme < db/init/02-import-restaurants-uuid.sql

# 3. Verify the import
docker compose exec db psql -U foodme_user -d foodme -c "SELECT name, cuisine_type FROM restaurants LIMIT 5;"
```

### Method 3: One-Line Fresh Setup

For a complete fresh start in one command:

```bash
docker compose down -v && npm run db:generate-import-uuid && docker compose up -d && sleep 15 && npm run db:test
```

### Troubleshooting Import Issues

**If you see UUID errors:**
```bash
ERROR: invalid input syntax for type uuid: "esthers"
```

**Solution:** Make sure you're using the UUID-compatible script:
```bash
# Use this (UUID-compatible)
npm run db:generate-import-uuid
```

**Expected Results:**
- ✅ 39 restaurants imported
- ✅ No UUID format errors
- ✅ Foreign key constraints intact
- ✅ Deterministic UUIDs generated

## 🍽️ Restaurant Data

### Data Source

The restaurant data comes from `server/data/restaurants.json` which contains:

- **39 restaurants** with diverse cuisines
- **Menu items** with names and prices
- **Restaurant metadata** (ratings, cuisine types, descriptions)

### Data Processing

The `import-restaurants-uuid.js` script:

1. **Reads** `restaurants.json`
2. **Generates deterministic UUIDs** from restaurant string IDs
3. **Processes** restaurant and menu item data with proper UUID format
4. **Creates** PostgreSQL-compatible INSERT statements
5. **Generates** `02-import-restaurants-uuid.sql`

### Menu Item Categories

Menu items are automatically categorized based on keywords:

- **Soups** - Items containing "soup" or "suppe"
- **Salads** - Items containing "salad" or "salat"
- **Sushi** - Items containing "roll", "sushi", or "maki"
- **Desserts** - Items containing "ice cream", "dessert", or "cake"
- **Beverages** - Items containing "drink", "tea", "coffee", or "juice"
- **Appetizers** - Items containing "appetizer", "starter", "edamame", or "tempura"
- **Noodles** - Items containing "noodle", "udon", "pasta", or "spaghetti"
- **Pizza** - Items containing "pizza"
- **Sandwiches** - Items containing "burger" or "sandwich"
- **Mexican** - Items containing "taco", "burrito", or "quesadilla"
- **Main Dishes** - Default category for other items

## 🔍 Database Queries

### Common Queries

```sql
-- View all restaurants
SELECT name, cuisine_type, rating FROM restaurants ORDER BY rating DESC;

-- Restaurants by cuisine
SELECT cuisine_type, COUNT(*) as count 
FROM restaurants 
GROUP BY cuisine_type 
ORDER BY count DESC;

-- Menu items for a specific restaurant
SELECT name, price, category 
FROM menu_items 
WHERE restaurant_id = 'robatayaki'
ORDER BY price DESC;

-- Most expensive menu items
SELECT r.name as restaurant, mi.name as item, mi.price
FROM menu_items mi
JOIN restaurants r ON mi.restaurant_id = r.id
ORDER BY mi.price DESC
LIMIT 10;

-- Restaurants with highest ratings
SELECT name, cuisine_type, rating, delivery_time
FROM restaurants
WHERE rating >= 4.0
ORDER BY rating DESC;
```

### Performance

The database includes indexes on:

- Restaurant cuisine types and active status
- Menu item restaurant associations and categories
- Customer emails
- Order statuses and dates

## 🐛 Troubleshooting

### Database Won't Start

```bash
# Check if port 5432 is in use
sudo lsof -i :5432

# View database startup logs
docker compose logs db

# Remove and recreate database
docker compose down db
docker volume rm foodme_db-data
docker compose up -d db
```

### Connection Issues

```bash
# Test basic connectivity
docker compose exec db pg_isready -U foodme_user

# Check password file
cat db/password.txt

# Test manual connection
docker compose exec db psql -U foodme_user -d foodme -c "SELECT version();"
```

### Data Import Issues

```bash
# Use UUID-compatible import (recommended)
npm run db:generate-import-uuid

# Check import file syntax
head -50 db/init/02-import-restaurants-uuid.sql

# Manual import with UUID support
docker compose exec -T db psql -U foodme_user -d foodme < db/init/02-import-restaurants-uuid.sql

# If you get UUID errors, make sure you're using the UUID-compatible script
# Common error: "invalid input syntax for type uuid"
# Solution: Use npm run db:generate-import-uuid
```

### Reset Database

```bash
# Complete reset (⚠️ deletes all data)
docker compose down -v

# Generate fresh UUID-compatible import
npm run db:generate-import-uuid

# Start fresh database
docker compose up -d db

# Wait for initialization to complete
sleep 30

# Test the reset
npm run db:test
```

## 🔒 Security Notes

- Database password is stored in `db/password.txt` (gitignored)
- PostgreSQL runs in Docker container (not exposed to host by default)
- Database user has limited privileges (not superuser)
- SSL can be enabled by setting `DB_SSL=true` in production

## 🚀 Production Considerations

For production deployment:

1. **Use managed database** (AWS RDS, Google Cloud SQL, etc.)
2. **Enable SSL/TLS** connections
3. **Set up automated backups**
4. **Use connection pooling**
5. **Monitor performance** with tools like pgAdmin or DataDog
6. **Implement proper user management** with role-based access

The current setup is optimized for development and can be easily adapted for production use.
