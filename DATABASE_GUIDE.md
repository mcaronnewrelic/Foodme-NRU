# FoodMe Database Setup Guide

This guide explains how to set up and initialize the PostgreSQL database with restaurant data from the `restaurants.json` file.

## 🗄️ Database Overview

The FoodMe application uses PostgreSQL as its primary database with the following structure:

- **restaurants** - Restaurant information (name, cuisine, ratings, etc.)
- **menu_items** - Menu items for each restaurant
- **customers** - Customer information
- **orders** - Order history
- **order_items** - Individual items within orders

## 🚀 Quick Start

### 1. Start the Database

```bash
# Start PostgreSQL with Docker Compose
docker compose up -d db

# Check if database is running
docker compose ps
```

### 2. Initialize with Restaurant Data

The database is automatically initialized when you start it for the first time. The initialization scripts are located in `db/init/` and run in alphabetical order:

1. **`01-init-schema.sql`** - Creates tables, indexes, and basic structure
2. **`02-load-restaurant-data.sql`** - Loads sample restaurant data (manual entries)
3. **`03-import-all-restaurants.sql`** - Imports all restaurants from `restaurants.json` (auto-generated)

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
# Generate fresh import SQL from restaurants.json
npm run db:generate-import

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

# Stop the database
docker compose stop db

# View database logs
docker compose logs db

# Restart database (useful if it's not responding)
docker compose restart db

# Remove database (⚠️ deletes all data)
docker compose down -v
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
└── init/                          # Initialization scripts (run alphabetically)
    ├── 01-init-schema.sql         # Database schema and tables
    ├── 02-load-restaurant-data.sql # Sample restaurant data
    └── 03-import-all-restaurants.sql # All restaurants from JSON (auto-generated)

scripts/
├── import-restaurants.js          # Generates SQL from restaurants.json
└── test-database.js              # Tests connection and shows data

server/data/
└── restaurants.json               # Source restaurant data
```

## 🍽️ Restaurant Data

### Data Source

The restaurant data comes from `server/data/restaurants.json` which contains:

- **39 restaurants** with diverse cuisines
- **Menu items** with names and prices
- **Restaurant metadata** (ratings, cuisine types, descriptions)

### Data Processing

The `import-restaurants.js` script:

1. **Reads** `restaurants.json`
2. **Processes** restaurant and menu item data
3. **Categorizes** menu items automatically
4. **Generates** SQL INSERT statements
5. **Creates** `03-import-all-restaurants.sql`

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
# Regenerate import file
npm run db:generate-import

# Check import file syntax
head -50 db/init/03-import-all-restaurants.sql

# Manual import (if needed)
docker compose exec -T db psql -U foodme_user -d foodme < db/init/03-import-all-restaurants.sql
```

### Reset Database

```bash
# Complete reset (⚠️ deletes all data)
docker compose down
docker volume rm foodme_db-data
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
