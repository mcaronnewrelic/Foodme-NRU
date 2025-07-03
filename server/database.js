/**
 * Database Service for FoodMe Application
 * ======================================
 * Handles database connections and restaurant data operations
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

class DatabaseService {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    /**
     * Initialize database connection
     */
    async connect() {
        if (this.isConnected) {
            return;
        }

        // Read database password from file
        const passwordFile = path.join(__dirname, '../db/password.txt');
        let dbPassword = process.env.DB_PASSWORD;
        
        // If no env password, try to read from file
        if (!dbPassword && fs.existsSync(passwordFile)) {
            try {
                dbPassword = fs.readFileSync(passwordFile, 'utf8').trim();
            } catch (error) {
                console.error('Error reading database password file:', error.message);
            }
        }
        
        // Fallback password
        if (!dbPassword) {
            dbPassword = 'foodme_secure_password_2025!';
        }

        this.client = new Client({
            host: process.env.DB_HOST || 'db', // Use 'db' for Docker Compose, 'localhost' for local
            port: process.env.DB_PORT || 5432,
            database: process.env.DB_NAME || 'foodme',
            user: process.env.DB_USER || 'foodme_user',
            password: dbPassword,
            ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
        });

        try {
            await this.client.connect();
            this.isConnected = true;
            console.log('✅ Database connected successfully');
        } catch (error) {
            console.error('❌ Database connection failed:', error.message);
            throw error;
        }
    }

    /**
     * Get all restaurants (equivalent to JSON file structure)
     */
    async getAllRestaurants() {
        await this.connect();
        
        try {
            const restaurantsQuery = `
                SELECT 
                    r.id,
                    r.name,
                    r.description,
                    r.cuisine_type as cuisine,
                    r.rating,
                    r.delivery_time,
                    r.delivery_fee,
                    r.min_order,
                    r.is_active
                FROM restaurants r
                WHERE r.is_active = true
                ORDER BY r.name
            `;
            
            const restaurantsResult = await this.client.query(restaurantsQuery);
            
            // For each restaurant, get menu items
            const restaurants = await Promise.all(restaurantsResult.rows.map(async (restaurant) => {
                const menuItemsQuery = `
                    SELECT name, price, category
                    FROM menu_items
                    WHERE restaurant_id = $1 AND is_available = true
                    ORDER BY category, name
                `;
                
                const menuItemsResult = await this.client.query(menuItemsQuery, [restaurant.id]);
                
                // Transform to match JSON structure
                return {
                    id: restaurant.id,
                    name: restaurant.name,
                    description: restaurant.description,
                    cuisine: restaurant.cuisine,
                    rating: parseFloat(restaurant.rating) || 0,
                    price: this.calculatePriceLevel(menuItemsResult.rows),
                    menuItems: menuItemsResult.rows.map(item => ({
                        name: item.name,
                        price: parseFloat(item.price)
                    })),
                    // Additional fields that might be used by the frontend
                    deliveryTime: restaurant.delivery_time,
                    deliveryFee: parseFloat(restaurant.delivery_fee),
                    minOrder: parseFloat(restaurant.min_order)
                };
            }));
            
            return restaurants;
        } catch (error) {
            console.error('Error fetching restaurants from database:', error);
            throw error;
        }
    }

    /**
     * Get a single restaurant by ID
     */
    async getRestaurantById(id) {
        await this.connect();
        
        try {
            const restaurantQuery = `
                SELECT 
                    r.id,
                    r.name,
                    r.description,
                    r.cuisine_type as cuisine,
                    r.rating,
                    r.delivery_time,
                    r.delivery_fee,
                    r.min_order,
                    r.is_active
                FROM restaurants r
                WHERE r.id = $1 AND r.is_active = true
            `;
            
            const restaurantResult = await this.client.query(restaurantQuery, [id]);
            
            if (restaurantResult.rows.length === 0) {
                return null;
            }
            
            const restaurant = restaurantResult.rows[0];
            
            // Get menu items
            const menuItemsQuery = `
                SELECT name, price, category
                FROM menu_items
                WHERE restaurant_id = $1 AND is_available = true
                ORDER BY category, name
            `;
            
            const menuItemsResult = await this.client.query(menuItemsQuery, [id]);
            
            return {
                id: restaurant.id,
                name: restaurant.name,
                description: restaurant.description,
                cuisine: restaurant.cuisine,
                rating: parseFloat(restaurant.rating) || 0,
                price: this.calculatePriceLevel(menuItemsResult.rows),
                menuItems: menuItemsResult.rows.map(item => ({
                    name: item.name,
                    price: parseFloat(item.price)
                })),
                deliveryTime: restaurant.delivery_time,
                deliveryFee: parseFloat(restaurant.delivery_fee),
                minOrder: parseFloat(restaurant.min_order)
            };
        } catch (error) {
            console.error('Error fetching restaurant by ID:', error);
            throw error;
        }
    }

    /**
     * Calculate price level based on menu items (1-5 scale)
     */
    calculatePriceLevel(menuItems) {
        if (!menuItems || menuItems.length === 0) {
            return 3; // Default middle price
        }
        
        const avgPrice = menuItems.reduce((sum, item) => sum + parseFloat(item.price), 0) / menuItems.length;
        
        // Map average price to 1-5 scale
        if (avgPrice < 8) return 1;
        if (avgPrice < 12) return 2;
        if (avgPrice < 16) return 3;
        if (avgPrice < 20) return 4;
        return 5;
    }

    /**
     * Add a new restaurant (for API compatibility)
     */
    async addRestaurant(restaurantData) {
        await this.connect();
        
        try {
            const insertQuery = `
                INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                RETURNING *
            `;
            
            const values = [
                restaurantData.id || this.generateId(restaurantData.name),
                restaurantData.name,
                restaurantData.description || '',
                restaurantData.cuisine || 'International',
                restaurantData.rating || 0,
                restaurantData.deliveryTime || '30-45 min',
                restaurantData.deliveryFee || 3.99,
                restaurantData.minOrder || 15.00
            ];
            
            const result = await this.client.query(insertQuery, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error adding restaurant:', error);
            throw error;
        }
    }

    /**
     * Update a restaurant
     */
    async updateRestaurant(id, restaurantData) {
        await this.connect();
        
        try {
            const updateQuery = `
                UPDATE restaurants 
                SET name = $2, description = $3, cuisine_type = $4, rating = $5, 
                    delivery_time = $6, delivery_fee = $7, min_order = $8, updated_at = CURRENT_TIMESTAMP
                WHERE id = $1
                RETURNING *
            `;
            
            const values = [
                id,
                restaurantData.name,
                restaurantData.description,
                restaurantData.cuisine,
                restaurantData.rating,
                restaurantData.deliveryTime,
                restaurantData.deliveryFee,
                restaurantData.minOrder
            ];
            
            const result = await this.client.query(updateQuery, values);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating restaurant:', error);
            throw error;
        }
    }

    /**
     * Delete a restaurant
     */
    async deleteRestaurant(id) {
        await this.connect();
        
        try {
            const deleteQuery = 'UPDATE restaurants SET is_active = false WHERE id = $1';
            await this.client.query(deleteQuery, [id]);
            return true;
        } catch (error) {
            console.error('Error deleting restaurant:', error);
            throw error;
        }
    }

    /**
     * Generate a simple ID from restaurant name
     */
    generateId(name) {
        return name.toLowerCase()
            .replace(/[^a-z0-9]/g, '')
            .substring(0, 20) + '_' + Date.now();
    }

    /**
     * Check if database is available
     */
    async isAvailable() {
        try {
            await this.connect();
            await this.client.query('SELECT 1');
            return true;
        } catch (error) {
            console.error('Database not available:', error.message);
            return false;
        }
    }

    /**
     * Close database connection
     */
    async close() {
        if (this.client && this.isConnected) {
            try {
                await this.client.end();
                this.isConnected = false;
                console.log('Database connection closed');
            } catch (error) {
                console.error('Error closing database connection:', error);
            }
        }
    }
}

module.exports = DatabaseService;
