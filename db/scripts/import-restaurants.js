#!/usr/bin/env node

/**
 * FoodMe Restaurant Data Importer
 * ===============================
 * This script reads the restaurants.json file and generates SQL INSERT statements
 * for populating the PostgreSQL database with all restaurant and menu item data.
 */

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Read the restaurants JSON file
const restaurantsFile = path.join(__dirname, '../../server/data/restaurants.json');
const outputFile = path.join(__dirname, '../init/03-import-all-restaurants.sql');

try {
    // Read and parse the JSON data
    console.log('Reading restaurants data from:', restaurantsFile);
    const restaurantsData = JSON.parse(fs.readFileSync(restaurantsFile, 'utf8'));
    
    console.log(`Found ${restaurantsData.length} restaurants to import`);
    
    // Start building the SQL file
    let sql = `-- Auto-generated SQL file for importing all restaurant data
-- Generated on: ${new Date().toISOString()}
-- Source: server/data/restaurants.json

-- Clear existing data
TRUNCATE TABLE order_items, orders, menu_items, restaurants, customers CASCADE;

-- Ensure ID column can handle string IDs
ALTER TABLE restaurants ALTER COLUMN id TYPE varchar(50);

BEGIN;

`;

    // Process each restaurant
    restaurantsData.forEach((restaurant, index) => {
        // Clean and escape string values for SQL
        const cleanString = (str) => {
            if (!str) return 'NULL';
            return `'${str.replace(/'/g, "''").replace(/\\/g, '\\\\')}'`;
        };
        
        const cleanNumber = (num) => {
            return num !== null && num !== undefined ? num : 'NULL';
        };
        
        // Map cuisine types to more standard names
        const cuisineMapping = {
            'german': 'German',
            'japanese': 'Japanese',
            'vegetarian': 'Vegetarian',
            'french': 'French',
            'sudanese': 'Sudanese',
            'american': 'American',
            'italian': 'Italian',
            'czech': 'Czech',
            'chinese': 'Chinese',
            'malaysian': 'Malaysian',
            'thai': 'Thai',
            'indian': 'Indian',
            'mexican': 'Mexican',
            'korean': 'Korean',
            'vietnamese': 'Vietnamese',
            'middle eastern': 'Middle Eastern',
            'greek': 'Greek',
            'spanish': 'Spanish',
            'ethiopian': 'Ethiopian'
        };
        
        const cuisineType = cuisineMapping[restaurant.cuisine] || restaurant.cuisine || 'International';
        
        // Calculate delivery time and fee based on price and rating
        const deliveryTimes = ['15-25 min', '20-30 min', '25-35 min', '30-45 min', '35-50 min'];
        const deliveryTime = deliveryTimes[Math.min(restaurant.price - 1, deliveryTimes.length - 1)] || '25-35 min';
        
        const deliveryFee = (restaurant.price * 1.5 + Math.random() * 2).toFixed(2);
        const minOrder = (restaurant.price * 5 + Math.random() * 10).toFixed(2);
        
        // Insert restaurant
        sql += `-- Restaurant ${index + 1}: ${restaurant.name}
INSERT INTO restaurants (restaurant_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    ${cleanString(restaurant.id)},
    ${cleanString(restaurant.name)},
    ${cleanString(restaurant.description)},
    ${cleanString(cuisineType)},
    ${cleanNumber(restaurant.rating)},
    ${cleanString(deliveryTime)},
    ${deliveryFee},
    ${minOrder},
    true
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    cuisine_type = EXCLUDED.cuisine_type,
    rating = EXCLUDED.rating,
    delivery_time = EXCLUDED.delivery_time,
    delivery_fee = EXCLUDED.delivery_fee,
    min_order = EXCLUDED.min_order,
    updated_at = CURRENT_TIMESTAMP;

`;

        // Insert menu items
        if (restaurant.menuItems && restaurant.menuItems.length > 0) {
            sql += `-- Menu items for ${restaurant.name}\n`;
            
            restaurant.menuItems.forEach((item, itemIndex) => {
                if (item.name && item.price !== null && item.price !== undefined) {
                    // Categorize menu items based on name keywords
                    const itemName = item.name.toLowerCase();
                    let category = 'Main Dishes'; // default
                    
                    if (itemName.includes('soup') || itemName.includes('suppe')) {
                        category = 'Soups';
                    } else if (itemName.includes('salad') || itemName.includes('salat')) {
                        category = 'Salads';
                    } else if (itemName.includes('roll') || itemName.includes('sushi') || itemName.includes('maki')) {
                        category = 'Sushi';
                    } else if (itemName.includes('ice cream') || itemName.includes('dessert') || itemName.includes('cake')) {
                        category = 'Desserts';
                    } else if (itemName.includes('drink') || itemName.includes('tea') || itemName.includes('coffee') || itemName.includes('juice')) {
                        category = 'Beverages';
                    } else if (itemName.includes('appetizer') || itemName.includes('starter') || itemName.includes('edamame') || itemName.includes('tempura')) {
                        category = 'Appetizers';
                    } else if (itemName.includes('noodle') || itemName.includes('udon') || itemName.includes('pasta') || itemName.includes('spaghetti')) {
                        category = 'Noodles';
                    } else if (itemName.includes('pizza')) {
                        category = 'Pizza';
                    } else if (itemName.includes('burger') || itemName.includes('sandwich')) {
                        category = 'Sandwiches';
                    } else if (itemName.includes('taco') || itemName.includes('burrito') || itemName.includes('quesadilla')) {
                        category = 'Mexican';
                    }
                    
                    sql += `INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES (${cleanString(restaurant.id)}, ${cleanString(item.name)}, ${cleanNumber(item.price)}, ${cleanString(category)}, true)
ON CONFLICT DO NOTHING;
`;
                }
            });
            
            sql += '\n';
        }
    });
    
    sql += `
COMMIT;

-- Final statistics
DO $$
BEGIN
    RAISE NOTICE 'Restaurant data import completed successfully!';
    RAISE NOTICE 'Total restaurants loaded: %', (SELECT COUNT(*) FROM restaurants);
    RAISE NOTICE 'Total menu items loaded: %', (SELECT COUNT(*) FROM menu_items);
    RAISE NOTICE 'Restaurants by cuisine:';
    
    -- Show breakdown by cuisine
    FOR rec IN 
        SELECT cuisine_type, COUNT(*) as count 
        FROM restaurants 
        GROUP BY cuisine_type 
        ORDER BY count DESC 
    LOOP
        RAISE NOTICE '  %: %', rec.cuisine_type, rec.count;
    END LOOP;
END $$;
`;

    // Write the SQL file
    fs.writeFileSync(outputFile, sql);
    console.log(`SQL file generated successfully: ${outputFile}`);
    console.log(`Generated ${sql.split('\n').length} lines of SQL`);
    
} catch (error) {
    console.error('Error processing restaurants data:', error);
    process.exit(1);
}
