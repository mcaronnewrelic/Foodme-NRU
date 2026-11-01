/**
 * Database Service for FoodMe Application
 * ======================================
 * Handles database connections and restaurant data operations
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
const logger = require('pino')();

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

        // Use DATABASE_URL if available (production), otherwise use individual env vars (development)
        if (process.env.DATABASE_URL) {
            this.client = new Client({
                connectionString: process.env.DATABASE_URL,
                ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
            });
        } else {
            // Fallback to individual environment variables for development
            // Read database password from file
            const passwordFile = path.join(__dirname, '../db/password.txt');
            let dbPassword = process.env.DB_PASSWORD;
            
            // If no env password, try to read from file
            if (!dbPassword && fs.existsSync(passwordFile)) {
                try {
                    dbPassword = fs.readFileSync(passwordFile, 'utf8').trim();
                } catch (error) {
                    logger.error({ err: error }, 'Error reading database password file');
                }
            }
            
            // Fallback password
            if (!dbPassword) {
                dbPassword = 'foodme_secure_password_2025!';
            }

            this.client = new Client({
                host: process.env.DB_HOST || 'localhost',
                port: process.env.DB_PORT || 5432,
                database: process.env.DB_NAME || 'foodme',
                user: process.env.DB_USER || 'foodme_user',
                password: dbPassword,
                ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
            });
        }

        try {
            await this.client.connect();
            this.isConnected = true;
            logger.info({
                host: this.client.host,
                database: this.client.database,
                user: this.client.user
            }, '✅ Database connected successfully');
        } catch (error) {
            logger.error({ err: error }, '❌ Database connection failed');
            throw error;
        }
    }

    /**
     * Get all restaurants (basic info only, no menu items)
     */
    async getAllRestaurants() {
        const startTime = Date.now();
        logger.debug({ operation: 'getAllRestaurants' }, 'Starting restaurant query');
        
        await this.connect();
        
        try {
            const queryStartTime = Date.now();
            const restaurantsQuery = `
                SELECT 
                    r.id,
                    r.original_id,
                    r.name,
                    r.description,
                    r.cuisine_type as cuisine,
                    r.rating,
                    r.delivery_time,
                    r.delivery_fee,
                    r.min_order,
                    r.is_active,
                    -- Calculate average price from menu items without fetching all items
                    CASE 
                        WHEN AVG(mi.price) IS NULL THEN 3
                        WHEN AVG(mi.price) < 8 THEN 1
                        WHEN AVG(mi.price) < 12 THEN 2
                        WHEN AVG(mi.price) < 16 THEN 3
                        WHEN AVG(mi.price) < 20 THEN 4
                        ELSE 5
                    END as price_level
                FROM restaurants r
                LEFT JOIN menu_items mi ON r.id = mi.restaurant_id AND mi.is_available = true
                WHERE r.is_active = true
                GROUP BY r.id, r.original_id, r.name, r.description, r.cuisine_type, 
                         r.rating, r.delivery_time, r.delivery_fee, r.min_order, r.is_active
                ORDER BY r.name
            `;
            
            const restaurantsResult = await this.client.query(restaurantsQuery);
            const queryDuration = Date.now() - queryStartTime;
            
            logger.debug({
                operation: 'getAllRestaurants',
                queryDuration,
                rowCount: restaurantsResult.rows.length
            }, 'Database query completed');
            
            // Transform to match expected frontend structure
            const restaurants = restaurantsResult.rows.map(restaurant => ({
                id: restaurant.id,
                original_id: restaurant.original_id,
                name: restaurant.name,
                description: restaurant.description,
                cuisine: restaurant.cuisine,
                rating: parseFloat(restaurant.rating) || 0,
                price: parseInt(restaurant.price_level) || 3,
                // No menuItems - these are fetched separately when needed
                deliveryTime: restaurant.delivery_time,
                deliveryFee: parseFloat(restaurant.delivery_fee),
                minOrder: parseFloat(restaurant.min_order)
            }));
            
            const totalDuration = Date.now() - startTime;
            logger.info({
                operation: 'getAllRestaurants',
                resultCount: restaurants.length,
                totalDuration,
                queryDuration
            }, 'Successfully retrieved all restaurants');
            
            return restaurants;
        } catch (error) {
            logger.error({ err: error, operation: 'getAllRestaurants' }, 'Error fetching restaurants from database');
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
                    r.original_id,
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
                SELECT name, price, category, description
                FROM menu_items
                WHERE restaurant_id = $1 AND is_available = true
                ORDER BY category, name
            `;
            
            const menuItemsResult = await this.client.query(menuItemsQuery, [id]);
            
            return {
                id: restaurant.id,
                original_id: restaurant.original_id,
                name: restaurant.name,
                description: restaurant.description,
                cuisine: restaurant.cuisine,
                rating: parseFloat(restaurant.rating) || 0,
                price: this.calculatePriceLevel(menuItemsResult.rows),
                menuItems: menuItemsResult.rows.map(item => ({
                    name: item.name,
                    price: parseFloat(item.price),
                    category: item.category,
                    description: item.description
                })),
                deliveryTime: restaurant.delivery_time,
                deliveryFee: parseFloat(restaurant.delivery_fee),
                minOrder: parseFloat(restaurant.min_order)
            };
        } catch (error) {
            logger.error({ err: error, operation: 'getRestaurantById', restaurantId: id }, 'Error fetching restaurant by ID');
            throw error;
        }
    }

    /**
     * Get a single restaurant by name slug
     */
    async getRestaurantByName(nameSlug) {
        // Mirrors nameToSlug() in url-utils.js (minus the underscores), so names with punctuation still match
        const NAME_AS_SLUG_TEXT = `btrim(regexp_replace(regexp_replace(LOWER(r.name), '[^a-z0-9 ]', '', 'g'), ' +', ' ', 'g'))`;
        await this.connect();
        
        const { slugToSearchPattern } = require('./url-utils');
        const searchPattern = slugToSearchPattern(nameSlug);
        
        try {
            // First try exact match (case-insensitive)
            const exactQuery = `
                SELECT 
                    r.id,
                    r.original_id,
                    r.name,
                    r.description,
                    r.cuisine_type as cuisine,
                    r.rating,
                    r.delivery_time,
                    r.delivery_fee,
                    r.min_order,
                    r.is_active
                FROM restaurants r
                WHERE ${NAME_AS_SLUG_TEXT} = $1 AND r.is_active = true
            `;
            
            let restaurantResult = await this.client.query(exactQuery, [searchPattern.replace(/_/g, ' ')]);
            
            // If no exact match, try fuzzy search with LIKE
            if (restaurantResult.rows.length === 0) {
                const fuzzyQuery = `
                    SELECT 
                        r.id,
                        r.original_id,
                        r.name,
                        r.description,
                        r.cuisine_type as cuisine,
                        r.rating,
                        r.delivery_time,
                        r.delivery_fee,
                        r.min_order,
                        r.is_active
                    FROM restaurants r
                    WHERE ${NAME_AS_SLUG_TEXT} LIKE $1 AND r.is_active = true
                    LIMIT 1
                `;
                
                restaurantResult = await this.client.query(fuzzyQuery, [`%${searchPattern.replace(/_/g, ' ')}%`]);
            }
            
            if (restaurantResult.rows.length === 0) {
                return null;
            }
            
            const restaurant = restaurantResult.rows[0];
            
            // Get menu items
            const menuItemsQuery = `
                SELECT name, price, category, description
                FROM menu_items
                WHERE restaurant_id = $1 AND is_available = true
                ORDER BY category, name
            `;
            
            const menuItemsResult = await this.client.query(menuItemsQuery, [restaurant.id]);
            
            return {
                id: restaurant.id,
                original_id: restaurant.original_id,
                name: restaurant.name,
                description: restaurant.description,
                cuisine: restaurant.cuisine,
                rating: parseFloat(restaurant.rating) || 0,
                price: this.calculatePriceLevel(menuItemsResult.rows),
                menuItems: menuItemsResult.rows.map(item => ({
                    name: item.name,
                    price: parseFloat(item.price),
                    category: item.category,
                    description: item.description
                })),
                deliveryTime: restaurant.delivery_time,
                deliveryFee: parseFloat(restaurant.delivery_fee),
                minOrder: parseFloat(restaurant.min_order)
            };
        } catch (error) {
            logger.error({ err: error, operation: 'getRestaurantByName', restaurantName: nameSlug }, 'Error fetching restaurant by name');
            throw error;
        }
    }

    /**
     * Calculate price level based on menu items (1-5 scale)
     * Used by getRestaurantById when menu items are already loaded
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
            logger.error({ err: error, operation: 'addRestaurant', restaurantName: restaurantData.name }, 'Error adding restaurant');
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
            logger.error({ err: error, operation: 'updateRestaurant', restaurantId: id }, 'Error updating restaurant');
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
            logger.error({ err: error, operation: 'deleteRestaurant', restaurantId: id }, 'Error deleting restaurant');
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
            logger.warn({ err: error }, 'Database not available during health check');
            return false;
        }
    }

    /**
     * Create or get customer by email
     */
    async createOrGetCustomer(customerData) {
        await this.connect();
        
        try {
            // First check if customer exists by email
            const existingCustomerQuery = 'SELECT * FROM customers WHERE email = $1';
            const existingResult = await this.client.query(existingCustomerQuery, [customerData.email]);
            
            if (existingResult.rows.length > 0) {
                // Update existing customer with latest info
                const updateQuery = `
                    UPDATE customers 
                    SET name = $2, phone = $3, address = $4, updated_at = CURRENT_TIMESTAMP
                    WHERE email = $1
                    RETURNING *
                `;
                const updateValues = [
                    customerData.email,
                    customerData.name,
                    customerData.phone || null,
                    customerData.address || null
                ];
                const updateResult = await this.client.query(updateQuery, updateValues);
                return updateResult.rows[0];
            } else {
                // Create new customer
                const insertQuery = `
                    INSERT INTO customers (name, email, phone, address)
                    VALUES ($1, $2, $3, $4)
                    RETURNING *
                `;
                const insertValues = [
                    customerData.name,
                    customerData.email,
                    customerData.phone || null,
                    customerData.address || null
                ];
                const insertResult = await this.client.query(insertQuery, insertValues);
                return insertResult.rows[0];
            }
        } catch (error) {
            logger.error({ err: error, operation: 'createOrGetCustomer' }, 'Error creating/getting customer');
            throw error;
        }
    }

    /**
     * Create a new order with items
     */
    async createOrder(orderData) {
        await this.connect();
        
        try {
            // Start transaction
            await this.client.query('BEGIN');

            // Handle both old format (deliverTo) and new format (customer)
            const customerData = orderData.customer || orderData.deliverTo;
            if (!customerData) {
                throw new Error('Customer data is required');
            }

            // Create or get customer
            const customer = await this.createOrGetCustomer(customerData);

            // Handle both old format (restaurant.id) and new format (restaurant_id)
            const restaurantId = orderData.restaurant_id || orderData.restaurant?.id;
            if (!restaurantId) {
                throw new Error('Restaurant ID is required');
            }

            // Generate order number
            const orderNumber = `ORDER-${Date.now()}-${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

            // Calculate totals - handle both old format (price, qty) and new format (unit_price, quantity)
            let subtotal = 0;
            orderData.items.forEach(item => {
                const price = item.unit_price || item.price || 0;
                const qty = item.quantity || item.qty || 1;
                subtotal += price * qty;
            });

            const totalAmount = orderData.total_amount || orderData.total || subtotal;
            const deliveryFee = orderData.delivery_fee || 0;
            const taxAmount = orderData.tax_amount || 0;
            const deliveryAddress = orderData.delivery_address || customerData.address || '';
            const specialInstructions = orderData.special_instructions || '';

            // Create order
            const orderQuery = `
                INSERT INTO orders (
                    customer_id, restaurant_id, order_number, status, 
                    total_amount, delivery_address, delivery_fee, tax_amount, special_instructions
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                RETURNING *
            `;
            
            const orderValues = [
                customer.id,
                restaurantId,
                orderNumber,
                'pending',
                totalAmount,
                deliveryAddress,
                deliveryFee,
                taxAmount,
                specialInstructions
            ];

            const orderResult = await this.client.query(orderQuery, orderValues);
            const order = orderResult.rows[0];

            // Create order items
            for (const item of orderData.items) {
                // Handle both old format (name) and new format (menu_item_id)
                let menuItemId = null;
                const itemName = item.item_name || item.name;
                const itemPrice = item.unit_price || item.price || 0;
                const itemQuantity = item.quantity || item.qty || 1;
                const itemInstructions = item.special_instructions || '';

                if (item.menu_item_id) {
                    // New format: use provided menu_item_id
                    menuItemId = item.menu_item_id;
                } else {
                    // Old format: look up by name or create new menu item
                    const menuItemQuery = `
                        SELECT id FROM menu_items 
                        WHERE restaurant_id = $1 AND LOWER(name) = LOWER($2)
                        LIMIT 1
                    `;
                    const menuItemResult = await this.client.query(menuItemQuery, [restaurantId, itemName]);
                    
                    if (menuItemResult.rows.length > 0) {
                        menuItemId = menuItemResult.rows[0].id;
                    } else {
                        // If menu item doesn't exist, create a temporary one
                        const createMenuItemQuery = `
                            INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
                            VALUES ($1, $2, $3, $4, $5)
                            RETURNING id
                        `;
                        const createMenuItemResult = await this.client.query(createMenuItemQuery, [
                            restaurantId,
                            itemName,
                            itemPrice,
                            'Other',
                            true
                        ]);
                        menuItemId = createMenuItemResult.rows[0].id;
                    }
                }

                // Insert order item
                const orderItemQuery = `
                    INSERT INTO order_items (order_id, menu_item_id, item_name, quantity, unit_price, special_instructions)
                    VALUES ($1, $2, $3, $4, $5, $6)
                `;
                await this.client.query(orderItemQuery, [
                    order.id,
                    menuItemId,
                    itemName,
                    itemQuantity,
                    itemPrice,
                    itemInstructions
                ]);
            }

            // Commit transaction
            await this.client.query('COMMIT');

            // Return order with additional details
            return {
                orderId: order.id,
                orderNumber: order.order_number,
                customerId: customer.id,
                restaurantId: restaurantId,
                status: order.status,
                total: order.total_amount,
                timestamp: order.created_at
            };

        } catch (error) {
            // Rollback transaction on error
            await this.client.query('ROLLBACK');
            logger.error({ err: error, operation: 'createOrder' }, 'Error creating order');
            throw error;
        }
    }

    /**
     * Get order by ID with items and customer details
     */
    async getOrderById(orderId) {
        await this.connect();
        
        try {
            const orderQuery = `
                SELECT 
                    o.*,
                    c.name as customer_name,
                    c.email as customer_email,
                    c.phone as customer_phone,
                    r.name as restaurant_name,
                    r.original_id as restaurant_original_id
                FROM orders o
                JOIN customers c ON o.customer_id = c.id
                JOIN restaurants r ON o.restaurant_id = r.id
                WHERE o.id = $1
            `;
            
            const orderResult = await this.client.query(orderQuery, [orderId]);
            
            if (orderResult.rows.length === 0) {
                return null;
            }
            
            const order = orderResult.rows[0];
            
            // Get order items
            const itemsQuery = `
                SELECT 
                    oi.*,
                    mi.name as item_name,
                    mi.description as item_description
                FROM order_items oi
                JOIN menu_items mi ON oi.menu_item_id = mi.id
                WHERE oi.order_id = $1
            `;
            
            const itemsResult = await this.client.query(itemsQuery, [orderId]);
            order.items = itemsResult.rows;
            
            return order;
        } catch (error) {
            logger.error({ err: error, operation: 'getOrder', orderId: id }, 'Error getting order');
            throw error;
        }
    }

    /**
     * Close database connection
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
    /**
     * Get orders for a customer by email
     */
    async getOrdersByCustomerEmail(email) {
        await this.connect();
        
        try {
            const query = `
                SELECT 
                    o.id,
                    o.order_number,
                    o.restaurant_id,
                    r.name as restaurant_name,
                    o.status,
                    o.total_amount,
                    o.delivery_address,
                    o.delivery_fee,
                    o.tax_amount,
                    o.special_instructions,
                    o.estimated_delivery_time,
                    o.created_at,
                    o.updated_at
                FROM orders o
                JOIN restaurants r ON o.restaurant_id = r.id
                JOIN customers c ON o.customer_id = c.id
                WHERE LOWER(c.email) = LOWER($1)
                ORDER BY o.created_at DESC
            `;
            
            const ordersResult = await this.client.query(query, [email]);
            
            // Get order items for each order
            const orders = [];
            for (const order of ordersResult.rows) {
                const itemsQuery = `
                    SELECT 
                        oi.id,
                        oi.menu_item_id,
                        oi.item_name,
                        oi.quantity,
                        oi.unit_price,
                        oi.special_instructions
                    FROM order_items oi
                    WHERE oi.order_id = $1
                    ORDER BY oi.created_at
                `;
                
                const itemsResult = await this.client.query(itemsQuery, [order.id]);
                
                orders.push({
                    id: order.id,
                    orderNumber: order.order_number,
                    restaurantId: order.restaurant_id,
                    restaurantName: order.restaurant_name,
                    status: order.status,
                    totalAmount: parseFloat(order.total_amount),
                    deliveryAddress: order.delivery_address,
                    deliveryFee: parseFloat(order.delivery_fee) || 0,
                    taxAmount: parseFloat(order.tax_amount) || 0,
                    specialInstructions: order.special_instructions,
                    estimatedDeliveryTime: order.estimated_delivery_time,
                    createdAt: order.created_at,
                    updatedAt: order.updated_at,
                    items: itemsResult.rows.map(item => ({
                        id: item.id,
                        menuItemId: item.menu_item_id,
                        itemName: item.item_name,
                        quantity: parseInt(item.quantity),
                        unitPrice: parseFloat(item.unit_price),
                        specialInstructions: item.special_instructions
                    }))
                });
            }
            
            return orders;
        } catch (error) {
            logger.error({ err: error, operation: 'getOrdersByCustomerEmail', customerEmail: email }, 'Error fetching orders by customer email');
            throw error;
        }
    }

    /**
     * Get orders for a customer by phone number
     */
    async getOrdersByCustomerPhone(phone) {
        await this.connect();
        
        try {
            const query = `
                SELECT 
                    o.id,
                    o.order_number,
                    o.restaurant_id,
                    r.name as restaurant_name,
                    o.status,
                    o.total_amount,
                    o.delivery_address,
                    o.delivery_fee,
                    o.tax_amount,
                    o.special_instructions,
                    o.estimated_delivery_time,
                    o.created_at,
                    o.updated_at
                FROM orders o
                JOIN restaurants r ON o.restaurant_id = r.id
                JOIN customers c ON o.customer_id = c.id
                WHERE c.phone = $1
                ORDER BY o.created_at DESC
            `;
            
            const ordersResult = await this.client.query(query, [phone]);
            
            // Get order items for each order
            const orders = [];
            for (const order of ordersResult.rows) {
                const itemsQuery = `
                    SELECT 
                        oi.id,
                        oi.menu_item_id,
                        oi.item_name,
                        oi.quantity,
                        oi.unit_price,
                        oi.special_instructions
                    FROM order_items oi
                    WHERE oi.order_id = $1
                    ORDER BY oi.created_at
                `;
                
                const itemsResult = await this.client.query(itemsQuery, [order.id]);
                
                orders.push({
                    id: order.id,
                    orderNumber: order.order_number,
                    restaurantId: order.restaurant_id,
                    restaurantName: order.restaurant_name,
                    status: order.status,
                    totalAmount: parseFloat(order.total_amount),
                    deliveryAddress: order.delivery_address,
                    deliveryFee: parseFloat(order.delivery_fee) || 0,
                    taxAmount: parseFloat(order.tax_amount) || 0,
                    specialInstructions: order.special_instructions,
                    estimatedDeliveryTime: order.estimated_delivery_time,
                    createdAt: order.created_at,
                    updatedAt: order.updated_at,
                    items: itemsResult.rows.map(item => ({
                        id: item.id,
                        menuItemId: item.menu_item_id,
                        itemName: item.item_name,
                        quantity: parseInt(item.quantity),
                        unitPrice: parseFloat(item.unit_price),
                        specialInstructions: item.special_instructions
                    }))
                });
            }
            
            return orders;
        } catch (error) {
            logger.error({ err: error, operation: 'getOrdersByCustomerPhone', customerPhone: phone }, 'Error fetching orders by customer phone');
            throw error;
        }
    }

    /**
     * Get a specific order by ID
     */
    async getOrderById(orderId) {
        await this.connect();
        
        try {
            const query = `
                SELECT 
                    o.id,
                    o.order_number,
                    o.restaurant_id,
                    r.name as restaurant_name,
                    o.status,
                    o.total_amount,
                    o.delivery_address,
                    o.delivery_fee,
                    o.tax_amount,
                    o.special_instructions,
                    o.estimated_delivery_time,
                    o.created_at,
                    o.updated_at
                FROM orders o
                JOIN restaurants r ON o.restaurant_id = r.id
                WHERE o.id = $1
            `;
            
            const orderResult = await this.client.query(query, [orderId]);
            
            if (orderResult.rows.length === 0) {
                return null;
            }
            
            const order = orderResult.rows[0];
            
            // Get order items
            const itemsQuery = `
                SELECT 
                    oi.id,
                    oi.menu_item_id,
                    oi.item_name,
                    oi.quantity,
                    oi.unit_price,
                    oi.special_instructions
                FROM order_items oi
                WHERE oi.order_id = $1
                ORDER BY oi.created_at
            `;
            
            const itemsResult = await this.client.query(itemsQuery, [orderId]);
            
            return {
                id: order.id,
                orderNumber: order.order_number,
                restaurantId: order.restaurant_id,
                restaurantName: order.restaurant_name,
                status: order.status,
                totalAmount: parseFloat(order.total_amount),
                deliveryAddress: order.delivery_address,
                deliveryFee: parseFloat(order.delivery_fee) || 0,
                taxAmount: parseFloat(order.tax_amount) || 0,
                specialInstructions: order.special_instructions,
                estimatedDeliveryTime: order.estimated_delivery_time,
                createdAt: order.created_at,
                updatedAt: order.updated_at,
                items: itemsResult.rows.map(item => ({
                    id: item.id,
                    menuItemId: item.menu_item_id,
                    itemName: item.item_name,
                    quantity: parseInt(item.quantity),
                    unitPrice: parseFloat(item.unit_price),
                    specialInstructions: item.special_instructions
                }))
            };
        } catch (error) {
            logger.error({ err: error, operation: 'getOrderById', orderId: id }, 'Error fetching order by ID');
            throw error;
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
                logger.info('Database connection closed successfully');
            } catch (error) {
                logger.error({ err: error }, 'Error closing database connection');
            }
        }
    }
}

module.exports = DatabaseService;
