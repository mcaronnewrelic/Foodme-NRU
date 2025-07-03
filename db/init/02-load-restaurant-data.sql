-- FoodMe Database Initialization with Restaurant Data
-- This script loads restaurant data from the restaurants.json file

-- First, let's clear any existing data
TRUNCATE TABLE order_items, orders, menu_items, restaurants, customers CASCADE;

-- Reset sequences
ALTER SEQUENCE IF EXISTS restaurants_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS menu_items_id_seq RESTART WITH 1;

-- Create a temporary function to parse and insert restaurant data
CREATE OR REPLACE FUNCTION load_restaurant_data()
RETURNS void AS $$
DECLARE
    restaurant_data jsonb;
    restaurant_record jsonb;
    menu_item_record jsonb;
    restaurant_uuid uuid;
BEGIN
    -- Read the restaurant data from the JSON file
    -- Note: This assumes the JSON content will be loaded via the application or separate script
    -- For now, we'll insert the data manually based on the restaurants.json structure
    
    -- Restaurant 1: Esther's German Saloon
    INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
    VALUES (
        'esthers',
        'Esther''s German Saloon',
        'German home-cooked meals and fifty-eight different beers on tap. To get more authentic, you''d need to be wearing lederhosen.',
        'German',
        3.0,
        '30-45 min',
        3.99,
        15.00,
        true
    ) ON CONFLICT (id) DO NOTHING;
    
    -- Menu items for Esther's German Saloon
    INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
    VALUES 
        ('esthers', 'Bockwurst Würstchen', 4.95, 'Sausages', true),
        ('esthers', 'Bratwurst mit Brötchen und Sauerkraut', 5.95, 'Sausages', true),
        ('esthers', 'Currywurst mit Brötchen', 5.95, 'Sausages', true),
        ('esthers', 'Das Hausmannskost', 11.45, 'Main Dishes', true),
        ('esthers', 'Fleishkas mit Kartoffelsalat', 6.95, 'Main Dishes', true),
        ('esthers', 'Frankfurter Würstchen', 9.95, 'Sausages', true),
        ('esthers', 'Französische Zwiebelsuppe mit Käse', 10.45, 'Soups', true),
        ('esthers', 'Frikadelle mit Brötchen', 6.95, 'Main Dishes', true),
        ('esthers', 'Gebackener Camenbert', 7.55, 'Appetizers', true),
        ('esthers', 'Gemischter Salat', 4.55, 'Salads', true),
        ('esthers', 'Haus Salatteller', 11.45, 'Salads', true),
        ('esthers', 'Jaegerschnitzel', 9.95, 'Main Dishes', true),
        ('esthers', 'Kaesepaetzle', 6.95, 'Main Dishes', true),
        ('esthers', 'Kartoffel Reibekuchen mit Apfelmus', 5.95, 'Sides', true),
        ('esthers', 'Maultaschen mit Käse', 7.95, 'Main Dishes', true),
        ('esthers', 'Sauerbraten', 10.45, 'Main Dishes', true),
        ('esthers', 'Ungarische Gulaschsuppe mit Brötchen', 3.95, 'Soups', true),
        ('esthers', 'Wienerschnitzel', 8.95, 'Main Dishes', true),
        ('esthers', 'Wurstsalad mit Bauernbrot', 6.95, 'Salads', true)
    ON CONFLICT DO NOTHING;

    -- Restaurant 2: Robatayaki Hachi
    INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
    VALUES (
        'robatayaki',
        'Robatayaki Hachi',
        'Japanese food the way you like it. Fast, fresh, grilled.',
        'Japanese',
        5.0,
        '25-35 min',
        4.99,
        20.00,
        true
    ) ON CONFLICT (id) DO NOTHING;
    
    -- Menu items for Robatayaki Hachi
    INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
    VALUES 
        ('robatayaki', 'California roll', 5.95, 'Sushi', true),
        ('robatayaki', 'Chicken teriyaki', 5.95, 'Main Dishes', true),
        ('robatayaki', 'Edamame', 6.95, 'Appetizers', true),
        ('robatayaki', 'Green tea ice cream', 6.95, 'Desserts', true),
        ('robatayaki', 'Kitsune Udon', 9.50, 'Noodles', true),
        ('robatayaki', 'Miso soup', 5.95, 'Soups', true),
        ('robatayaki', 'Pork Katsu', 5.95, 'Main Dishes', true),
        ('robatayaki', 'Salmon teriyaki', 5.95, 'Main Dishes', true),
        ('robatayaki', 'Sashimi combo', 6.95, 'Sashimi', true),
        ('robatayaki', 'Spicy Yellowtail roll', 7.55, 'Sushi', true),
        ('robatayaki', 'Sushi combo', 4.55, 'Sushi', true),
        ('robatayaki', 'Teppa Maki', 5.95, 'Sushi', true),
        ('robatayaki', 'Unagi Don', 7.55, 'Main Dishes', true),
        ('robatayaki', 'Vegetable tempura', 3.95, 'Appetizers', true),
        ('robatayaki', 'Vegetarian sushi plate', 6.95, 'Sushi', true),
        ('robatayaki', 'Wakame salad', 4.95, 'Salads', true)
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Sample restaurant data loaded successfully!';
END;
$$ LANGUAGE plpgsql;

-- Execute the function
SELECT load_restaurant_data();

-- Drop the temporary function
DROP FUNCTION load_restaurant_data();

-- Update the table structure to support the original JSON ID format
ALTER TABLE restaurants ALTER COLUMN id TYPE varchar(50);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'FoodMe database initialization with restaurant data completed!';
    RAISE NOTICE 'Loaded restaurants: %', (SELECT COUNT(*) FROM restaurants);
    RAISE NOTICE 'Loaded menu items: %', (SELECT COUNT(*) FROM menu_items);
END $$;
