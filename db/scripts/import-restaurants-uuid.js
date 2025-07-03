#!/usr/bin/env node

/**
 * FoodMe Restaurant Data Importer (UUID Version)
 * ==============================================
 * This script reads the restaurants.json file and generates SQL INSERT statements
 * for populating the PostgreSQL database with UUID-based restaurant and menu item data.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Function to generate deterministic UUID from string
function generateUUID(str) {
    const hash = crypto.createHash('sha256').update(str).digest('hex');
    return [
        hash.substr(0, 8),
        hash.substr(8, 4),
        '4' + hash.substr(13, 3), // Version 4
        '8' + hash.substr(17, 3), // Variant bits
        hash.substr(20, 12)
    ].join('-');
}

// Read the restaurants JSON file
const restaurantsFile = path.join(__dirname, '../../server/data/restaurants.json');
const outputFile = path.join(__dirname, '../init/02-import-restaurants-uuid.sql');

try {
    // Read and parse the JSON data
    console.log('Reading restaurants data from:', restaurantsFile);
    const restaurantsData = JSON.parse(fs.readFileSync(restaurantsFile, 'utf8'));
    
    console.log(`Found ${restaurantsData.length} restaurants to import`);
    
    // Start building the SQL file
    let sql = `-- Auto-generated SQL file for importing restaurant data (UUID version)
-- Generated on: ${new Date().toISOString()}
-- Source: server/data/restaurants.json

-- Clear existing data (in dependency order)
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE menu_items CASCADE;
TRUNCATE TABLE restaurants CASCADE;
TRUNCATE TABLE customers CASCADE;

BEGIN;

`;

    // Process each restaurant
    restaurantsData.forEach((restaurant, index) => {
        // Generate deterministic UUID from restaurant ID
        const restaurantUUID = generateUUID(restaurant.id);
        
        // Clean and escape string values for SQL
        const cleanString = (str) => {
            if (!str) return 'NULL';
            return `'${str.replace(/'/g, "''").replace(/\\/g, '\\\\')}'`;
        };
        
        const cleanNumber = (num) => {
            return num !== null && num !== undefined ? num : 'NULL';
        };
        
        sql += `-- Restaurant ${index + 1}: ${restaurant.name}\n`;
        sql += `INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)\n`;
        sql += `VALUES (\n`;
        sql += `    '${restaurantUUID}',\n`;
        sql += `    ${cleanString(restaurant.id)},\n`;
        sql += `    ${cleanString(restaurant.name)},\n`;
        sql += `    ${cleanString(restaurant.description)},\n`;
        sql += `    ${cleanString(restaurant.cuisine)},\n`;
        sql += `    ${cleanNumber(restaurant.rating)},\n`;
        sql += `    ${cleanString(restaurant.delivery_time)},\n`;
        sql += `    ${cleanNumber(restaurant.delivery_fee)},\n`;
        sql += `    ${cleanNumber(restaurant.min_order)},\n`;
        sql += `    true\n`;
        sql += `) ON CONFLICT (id) DO NOTHING;\n\n`;
        
        // Add menu items if they exist
        if (restaurant.menuItems && Array.isArray(restaurant.menuItems)) {
            restaurant.menuItems.forEach((item, itemIndex) => {
                // Skip items with null or undefined prices
                if (item.price === null || item.price === undefined) {
                    return;
                }
                
                const itemUUID = generateUUID(`${restaurant.id}-${item.name}-${itemIndex}`);
                
                sql += `INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)\n`;
                sql += `VALUES (\n`;
                sql += `    '${itemUUID}',\n`;
                sql += `    '${restaurantUUID}',\n`;
                sql += `    ${cleanString(item.name)},\n`;
                sql += `    ${cleanString(item.description)},\n`;
                sql += `    ${cleanNumber(item.price)},\n`;
                sql += `    ${cleanString(item.category || 'Main')},\n`;
                sql += `    true\n`;
                sql += `) ON CONFLICT (id) DO NOTHING;\n`;
            });
            sql += '\n';
        }
    });

    sql += `COMMIT;

-- Summary
DO $$
DECLARE
    restaurant_count INTEGER;
    menu_item_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO restaurant_count FROM restaurants;
    SELECT COUNT(*) INTO menu_item_count FROM menu_items;
    
    RAISE NOTICE 'Import completed successfully!';
    RAISE NOTICE 'Restaurants loaded: %', restaurant_count;
    RAISE NOTICE 'Menu items loaded: %', menu_item_count;
END
$$;
`;

    // Write the SQL file
    fs.writeFileSync(outputFile, sql, 'utf8');
    
    console.log('SQL file generated successfully:', outputFile);
    console.log(`Generated ${sql.split('\n').length} lines of SQL`);
    console.log(`Created UUIDs for ${restaurantsData.length} restaurants`);
    
} catch (error) {
    console.error('Error generating SQL file:', error.message);
    process.exit(1);
}
