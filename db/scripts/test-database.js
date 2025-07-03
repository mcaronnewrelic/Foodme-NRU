#!/usr/bin/env node

/**
 * Database Test Script
 * ===================
 * This script tests the database connection and shows imported restaurant data
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function testDatabase() {
    // Read database password
    const passwordFile = path.join(__dirname, '../password.txt');
    let dbPassword = 'foodme_secure_password_2025!'; // fallback
    
    try {
        if (fs.existsSync(passwordFile)) {
            dbPassword = fs.readFileSync(passwordFile, 'utf8').trim();
        }
    } catch (error) {
        console.log('Using fallback password');
    }

    // Database connection config
    const client = new Client({
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        database: process.env.DB_NAME || 'foodme',
        user: process.env.DB_USER || 'foodme_user',
        password: process.env.DB_PASSWORD || dbPassword,
    });

    try {
        console.log('🔌 Connecting to database...');
        await client.connect();
        console.log('✅ Database connection successful!');

        // Test basic queries
        console.log('\n📊 Database Statistics:');
        
        const restaurantCount = await client.query('SELECT COUNT(*) FROM restaurants');
        console.log(`   Restaurants: ${restaurantCount.rows[0].count}`);
        
        const menuItemCount = await client.query('SELECT COUNT(*) FROM menu_items');
        console.log(`   Menu Items: ${menuItemCount.rows[0].count}`);
        
        const customerCount = await client.query('SELECT COUNT(*) FROM customers');
        console.log(`   Customers: ${customerCount.rows[0].count}`);
        
        const orderCount = await client.query('SELECT COUNT(*) FROM orders');
        console.log(`   Orders: ${orderCount.rows[0].count}`);

        // Show cuisine breakdown
        console.log('\n🍽️ Restaurants by Cuisine:');
        const cuisineBreakdown = await client.query(`
            SELECT cuisine_type, COUNT(*) as count 
            FROM restaurants 
            GROUP BY cuisine_type 
            ORDER BY count DESC
        `);
        
        cuisineBreakdown.rows.forEach(row => {
            console.log(`   ${row.cuisine_type}: ${row.count}`);
        });

        // Show sample restaurants
        console.log('\n🏪 Sample Restaurants:');
        const sampleRestaurants = await client.query(`
            SELECT name, cuisine_type, rating, delivery_time 
            FROM restaurants 
            ORDER BY rating DESC 
            LIMIT 5
        `);
        
        sampleRestaurants.rows.forEach(restaurant => {
            console.log(`   ${restaurant.name} (${restaurant.cuisine_type}) - ⭐${restaurant.rating} - ${restaurant.delivery_time}`);
        });

        // Show menu items for a sample restaurant
        console.log('\n🍜 Sample Menu Items (Top Restaurant):');
        const menuItems = await client.query(`
            SELECT mi.name, mi.price, mi.category 
            FROM menu_items mi 
            JOIN restaurants r ON mi.restaurant_id = r.id 
            WHERE r.rating = (SELECT MAX(rating) FROM restaurants)
            ORDER BY mi.price DESC 
            LIMIT 5
        `);
        
        menuItems.rows.forEach(item => {
            console.log(`   ${item.name} - $${item.price} (${item.category})`);
        });

    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        console.log('\n💡 Troubleshooting:');
        console.log('   1. Make sure PostgreSQL is running: docker compose ps');
        console.log('   2. Check database logs: docker compose logs db');
        console.log('   3. Verify password file: cat db/password.txt');
        console.log('   4. Test connection: docker compose exec db psql -U foodme_user -d foodme');
        process.exit(1);
    } finally {
        await client.end();
    }
}

// Run the test
testDatabase().then(() => {
    console.log('\n✅ Database test completed successfully!');
}).catch((error) => {
    console.error('❌ Database test failed:', error);
    process.exit(1);
});
