-- FoodMe Database Initialization Script
-- This script creates the necessary tables and imports initial data

-- Create restaurants table
CREATE TABLE IF NOT EXISTS restaurants (
    id VARCHAR(50) PRIMARY KEY,
    original_id VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    cuisine VARCHAR(100),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    price INTEGER CHECK (price >= 1 AND price <= 4),
    delivery_time INTEGER,
    delivery_fee DECIMAL(10,2),
    min_order DECIMAL(10,2),
    image VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create menu_items table
CREATE TABLE IF NOT EXISTS menu_items (
    id SERIAL PRIMARY KEY,
    restaurant_id VARCHAR(50) REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    image VARCHAR(255),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine ON restaurants(cuisine);
CREATE INDEX IF NOT EXISTS idx_restaurants_rating ON restaurants(rating);
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id ON menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category);

-- Create a view for restaurants with menu item counts
CREATE OR REPLACE VIEW restaurants_with_menu_counts AS
SELECT 
    r.*,
    COALESCE(m.menu_item_count, 0) as menu_item_count
FROM restaurants r
LEFT JOIN (
    SELECT 
        restaurant_id, 
        COUNT(*) as menu_item_count 
    FROM menu_items 
    WHERE is_available = TRUE 
    GROUP BY restaurant_id
) m ON r.id = m.restaurant_id;

-- Grant permissions (for postgres user)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;