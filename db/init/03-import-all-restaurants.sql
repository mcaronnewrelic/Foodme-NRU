-- Auto-generated SQL file for importing all restaurant data
-- Generated on: 2025-07-03T09:19:29.008Z
-- Source: server/data/restaurants.json

-- Clear existing data
TRUNCATE TABLE order_items, orders, menu_items, restaurants, customers CASCADE;

-- Ensure ID column can handle string IDs
ALTER TABLE restaurants ALTER COLUMN id TYPE varchar(50);

BEGIN;

-- Restaurant 1: Esther's German Saloon
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'esthers',
    'Esther''s German Saloon',
    'German home-cooked meals and fifty-eight different beers on tap. To get more authentic, you''d need to be wearing lederhosen.',
    'German',
    3,
    '25-35 min',
    6.01,
    17.54,
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

-- Menu items for Esther's German Saloon
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Bockwurst Würstchen', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Bratwurst mit Brötchen und Sauerkraut', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Currywurst mit Brötchen', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Das Hausmannskost', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Fleishkas mit Kartoffelsalat', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Frankfurter Würstchen', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Französische Zwiebelsuppe mit Käse', 10.45, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Frikadelle mit Brötchen', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Gebackener Camenbert', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Gemischter Salat', 4.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Haus Salatteller', 11.45, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Jaegerschnitzel', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Kaesepaetzle', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Kartoffel Reibekuchen mit Apfelmus', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Maultaschen mit Käse', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Sauerbraten', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Ungarische Gulaschsuppe mit Brötchen', 3.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Wienerschnitzel', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('esthers', 'Wurstsalad mit Bauernbrot', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 2: Robatayaki Hachi
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'robatayaki',
    'Robatayaki Hachi',
    'Japanese food the way you like it. Fast, fresh, grilled.',
    'Japanese',
    5,
    '30-45 min',
    7.42,
    22.58,
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

-- Menu items for Robatayaki Hachi
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'California roll', 5.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Chicken teriyaki', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Edamame', 6.95, 'Appetizers', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Green tea ice cream', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Kitsune Udon', 9.5, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Miso soup', 5.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Pork Katsu', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Salmon teriyaki', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Sashimi combo', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Spicy Yellowtail roll', 7.55, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Sushi combo', 4.55, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Teppa Maki', 5.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Unagi Don', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Vegetable tempura', 3.95, 'Appetizers', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Vegetarian sushi plate', 6.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('robatayaki', 'Wakame salad', 4.95, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 3: BBQ Tofu Paradise
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'tofuparadise',
    'BBQ Tofu Paradise',
    'Vegetarians, we have your BBQ needs covered. Our home-made tofu skewers and secret BBQ sauce will have you licking your fingers.',
    'Vegetarian',
    1,
    '20-30 min',
    3.13,
    16.53,
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

-- Menu items for BBQ Tofu Paradise
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'bean and cheese burrito', 6.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'cheese tortellini in tomato sauce', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'coffee', 6.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'falafel wrap with tabbouleh', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'flourless chocolate cake', 8.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'garden fresh salad', 6.5, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'happy buddha stir fry', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'hummus appetizer plate', 8, 'Appetizers', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'lentil burger', 6, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'lentil soup', 4.5, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'pasta with olives and marinated lemon', 6.95, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'spinach and cheese wrap', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'tea', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'toasted sandwich with grilled eggplant', 8.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'tofu chicken wrap', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'tomato and cheese sandwich', 11.45, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('tofuparadise', 'vegetable stew', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 4: Le Bateau Rouge
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'bateaurouge',
    'Le Bateau Rouge',
    'Fine French dining in a romantic setting. From soupe à l''oignon to coq au vin, let our chef delight you with a local take on authentic favorites.',
    'French',
    4,
    '35-50 min',
    7.74,
    25.96,
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

-- Menu items for Le Bateau Rouge
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'bavette dans son jus', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'bœuf bourguignon ', 18, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'bouillabaisse', 17.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'coq au vin', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'moules et frites', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'poulet au riesling', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'quiche lorraine', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'salade de chèvre chaud', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'salade du midi', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'salade niçoise', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'sandwich croque-madame', 3.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'sandwich croque-monsieur', 4.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'soupe à l''oignon', 9.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'steak frites', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'tarte pissaladière ', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bateaurouge', 'tarte tatin', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 5: Khartoum Khartoum
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'khartoum',
    'Khartoum Khartoum',
    'African homestyle cuisine, cooked fresh daily.',
    'african',
    2,
    '25-35 min',
    4.65,
    16.93,
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

-- Menu items for Khartoum Khartoum
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Dibi Lamb', 8.25, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Doro Wat', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Grilled Chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Grilled Fish', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Grilled Plantains in Spicy Peanut Sauce', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Lamb Mafe (Peanut Butter Stew)', 8.75, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Meat Pie', 6, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Mechoui with Plantains', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Pepper Soup', 9.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Piri-Piri Shrimp', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Suppa Kandja', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Thiou Boulette', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Thiou Curry with Chicken', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Thu Okra', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Yassa Chicken', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('khartoum', 'Yassa Lamb', 8.25, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 6: Sally's Diner
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'sallys',
    'Sally''s Diner',
    'Food like mom cooked, if you grew up in Iowa and mom ran a diner. Try our blue plate special!',
    'American',
    3,
    '30-45 min',
    6.17,
    26.79,
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

-- Menu items for Sally's Diner
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Buffalo wings', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'California-style baked Tilapia with rice', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Cheeseburger and fries', 4.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Cherry pie a la mode', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Chocolate milkshake', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Cobb salad', 4.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Famous BLT on a kaiser roll with fries', 4.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Firehouse chili', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Goat cheese and eggplant wrap (vegetarian)', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Greek salad', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Grilled chicken sandwich', 4.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Grilled sausage on a bun', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Housemade pot roast with seasonal vegetable', 16.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Roast beef dip', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Roast chicken and mashed potatoes', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Soup of the day', 8.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sallys', 'Spaghetti and meatballs', 11.45, 'Noodles', true)
ON CONFLICT DO NOTHING;

-- Restaurant 7: Saucy Piggy
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'saucy',
    'Saucy Piggy',
    'Pork. We know how to cook it. Award-winning BBQ sauce, and meat with all the trimmings.',
    'barbecue',
    2,
    '25-35 min',
    5.61,
    15.86,
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

-- Menu items for Saucy Piggy
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'BBQ chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Beef ribs (full)', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Beef ribs (delux)', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Beef ribs (half)', 6.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Beer', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Coleslaw', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Collards', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Cornbread', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Devilled eggs', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'German chocolate cake', 5.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Housemade chips', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Hushpuppies', 3.25, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Mac and cheese', 6, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Pork ribs (half)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Potato salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Pulled pork sandwich on a soft roll', 4.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('saucy', 'Riblets', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 8: Czech Point
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'czechpoint',
    'Czech Point',
    'Make a point of trying our knedlíky and homemade soups. We have free wifi and the best desserts and coffee. ',
    'czech/slovak',
    4,
    '15-25 min',
    2.15,
    9.52,
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

-- Menu items for Czech Point
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Apple strudel', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Apricot dumpling with yogurt topping ', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Balkánský Salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Beef goulash', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Chicken breast fillet schnitzel ', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Cucumber Salad', 7.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Dumplings', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Fried goose liver with onion and bread', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Halusky with sauerkraut and belly bacon ', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Lentil soup', 4.5, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Pickles with cabbage and cheddar', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Pork schnitzel', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Potato pancake with bacon', 5.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Potato Salad', 4.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Segedínský gulash and dumplings', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('czechpoint', 'Sour cabbage soup', 10.45, 'Soups', true)
ON CONFLICT DO NOTHING;

-- Restaurant 9: Der Speisewagen
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'speisewagen',
    'Der Speisewagen',
    'Award-winning schnitzel and other favorites. Look for our restored food truck in the NE corner of the College St lot.',
    'German',
    5,
    '25-35 min',
    5.16,
    19.21,
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

-- Menu items for Der Speisewagen
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Bockwurst Würstchen', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Bratwurst mit Brötchen und Sauerkraut', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Currywurst mit Brötchen', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Das Hausmannskost', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Fleishkas mit Kartoffelsalat', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Frankfurter Würstchen', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Französische Zwiebelsuppe mit Käse', 10.45, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Frikadelle mit Brötchen', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Gebackener Camenbert', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Gemischter Salat', 4.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Haus Salatteller', 11.45, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Jaegerschnitzel', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Kaesepaetzle', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Kartoffel Reibekuchen mit Apfelmus', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Maultaschen mit Käse', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Sauerbraten', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Ungarische Gulaschsuppe mit Brötchen', 3.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Wienerschnitzel', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('speisewagen', 'Wurstsalad mit Bauernbrot', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 10: Beijing Express
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'beijing',
    'Beijing Express',
    'Fast, healthy, Chinese food. Family specials for takeout or delivery. Try our Peking Duck!',
    'Chinese',
    4,
    '20-30 min',
    4.54,
    19.95,
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

-- Menu items for Beijing Express
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Almond cookie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Chicken and broccoli', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Chow mein', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Egg rolls (4)', 3.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'General Tao''s chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Hot and Sour Soup', 7.55, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Hunan dumplings', 6.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Mongolian beef', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Pan-fried beef noodle', 7.95, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Pea shoots with garlic', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Potstickers (6)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Seafood hotpot', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Steamed rice', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Sweet and sour pork', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Walnut prawns', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Wonton Soup', 6.25, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beijing', 'Young Chow fried rice', 6.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 11: Satay Village
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'satay',
    'Satay Village',
    'Fine dining Thai-style. Wide selection of vegetarian entrées. We also deliver.',
    'Thai',
    2,
    '30-45 min',
    6.30,
    27.54,
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

-- Menu items for Satay Village
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Basil duck with rice', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Curry salmon', 12.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Egg rolls (4)', 5.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Fried banana and ice cream', 11.45, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Green curry with chicken', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Green curry with pork', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Hot tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Onion pancake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Pad See Ew', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Pad Thai', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Pumpkin curry', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Red curry with chicken', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Red curry with pork', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Sticky rice with mango', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Thai iced coffee', 6.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Thai iced tea', 3.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('satay', 'Tofu salad rolls', 10.45, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 12: Cancun
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'cancun',
    'Cancun',
    'Tacos, tortas, burritos, just the way you like them. Our hot sauce and guacamole are the best in town.',
    'Mexican',
    3,
    '25-35 min',
    5.84,
    15.17,
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

-- Menu items for Cancun
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Beans and rice', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Beef burrito', 6.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Birria', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Chicken burrito', 11.45, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Chicken mole platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Chile relleno (meat)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Chile relleno (vegetarian)', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Chips and guacamole', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Enchiladas', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Flan', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Jamaica Aqua Fresca', 2.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Pork al pastor platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Sopa de albondigas', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Sopa de pollo', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Strawberry Aqua Fresca', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Super nachos with carne asada', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Tacos de la casa (3)', 4.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('cancun', 'Vegetarian platter', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 13: Curry Up
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'curryup',
    'Curry Up',
    'Indian food with a modern twist. We use all-natural ingredients and the finest spices to delight and tempt your palate.',
    'Indian',
    5,
    '30-45 min',
    6.32,
    29.72,
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

-- Menu items for Curry Up
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Aloo Gobi', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Basmati rice', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Butter Chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Chicken Korma', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Chicken Tikka Masala', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Gulab Jamun', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Kheer', 4.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Lamb Asparagus', 9.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Lamb Vindaloo', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Mix Grill Bombay', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Mulligatawny soup', 5.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Murgh Chicken', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Naan stuffed with spinach and lamb', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Plain naan', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Rogan Josh', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Saag Paneer', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('curryup', 'Tandoori Chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 14: Carthage
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'carthage',
    'Carthage',
    'Wholesome food and all the rich flavor of Africa. Try our famous lentil soup.',
    'african',
    1,
    '20-30 min',
    4.21,
    11.08,
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

-- Menu items for Carthage
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Dibi Lamb', 8.25, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Doro Wat', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Grilled Chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Grilled Fish', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Grilled Plantains in Spicy Peanut Sauce', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Lamb Mafe (Peanut Butter Stew)', 8.75, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Meat Pie', 6, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Mechoui with Plantains', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Pepper Soup', 9.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Piri-Piri Shrimp', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Suppa Kandja', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Thiou Boulette', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Thiou Curry with Chicken', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Thu Okra', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Yassa Chicken', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('carthage', 'Yassa Lamb', 8.25, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 15: Burgerama
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'burgerama',
    'Burgerama',
    'Grade A beef, freshly ground every day, hand-cut fries, and home-made milkshakes. We make the best burgers in town. ',
    'American',
    4,
    '35-50 min',
    8.38,
    29.92,
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

-- Menu items for Burgerama
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Buffalo wings', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'California-style baked Tilapia with rice', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Cheeseburger and fries', 4.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Cherry pie a la mode', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Chocolate milkshake', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Cobb salad', 4.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Famous BLT on a kaiser roll with fries', 4.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Firehouse chili', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Goat cheese and eggplant wrap (vegetarian)', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Greek salad', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Grilled chicken sandwich', 4.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Grilled sausage on a bun', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Housemade pot roast with seasonal vegetable', 16.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Roast beef dip', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Roast chicken and mashed potatoes', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Soup of the day', 8.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('burgerama', 'Spaghetti and meatballs', 11.45, 'Noodles', true)
ON CONFLICT DO NOTHING;

-- Restaurant 16: Three Little Pigs
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'littlepigs',
    'Three Little Pigs',
    'Genuine East Texas barbecue. Accept no substitutes! ',
    'barbecue',
    2,
    '25-35 min',
    5.15,
    18.70,
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

-- Menu items for Three Little Pigs
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'BBQ chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Beef ribs (full)', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Beef ribs (delux)', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Beef ribs (half)', 6.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Beer', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Coleslaw', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Collards', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Cornbread', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Devilled eggs', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'German chocolate cake', 5.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Housemade chips', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Hushpuppies', 3.25, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Mac and cheese', 6, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Pork ribs (half)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Potato salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Pulled pork sandwich on a soft roll', 4.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littlepigs', 'Riblets', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 17: Little Prague
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'littleprague',
    'Little Prague',
    'We''re famous for our housemade sausage and desserts. Come taste real European cooking.',
    'czech/slovak',
    3,
    '30-45 min',
    6.47,
    21.56,
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

-- Menu items for Little Prague
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Apple strudel', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Apricot dumpling with yogurt topping ', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Balkánský Salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Beef goulash', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Chicken breast fillet schnitzel ', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Cucumber Salad', 7.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Dumplings', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Fried goose liver with onion and bread', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Halusky with sauerkraut and belly bacon ', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Lentil soup', 4.5, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Pickles with cabbage and cheddar', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Pork schnitzel', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Potato pancake with bacon', 5.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Potato Salad', 4.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Segedínský gulash and dumplings', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('littleprague', 'Sour cabbage soup', 10.45, 'Soups', true)
ON CONFLICT DO NOTHING;

-- Restaurant 18: Kohl Haus
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'kohlhaus',
    'Kohl Haus',
    'East German specialties, in a family-friendly setting. Come warm up with our delicious soups.',
    'German',
    2,
    '25-35 min',
    4.92,
    19.82,
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

-- Menu items for Kohl Haus
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Bockwurst Würstchen', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Bratwurst mit Brötchen und Sauerkraut', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Currywurst mit Brötchen', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Das Hausmannskost', 11.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Fleishkas mit Kartoffelsalat', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Frankfurter Würstchen', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Französische Zwiebelsuppe mit Käse', 10.45, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Frikadelle mit Brötchen', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Gebackener Camenbert', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Gemischter Salat', 4.55, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Haus Salatteller', 11.45, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Jaegerschnitzel', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Kaesepaetzle', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Kartoffel Reibekuchen mit Apfelmus', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Maultaschen mit Käse', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Sauerbraten', 10.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Ungarische Gulaschsuppe mit Brötchen', 3.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Wienerschnitzel', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('kohlhaus', 'Wurstsalad mit Bauernbrot', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 19: Dragon's Tail
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'dragon',
    'Dragon''s Tail',
    'Take-out or dine-in Chinese food. Open late. Delivery available',
    'Chinese',
    4,
    '15-25 min',
    3.45,
    6.72,
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

-- Menu items for Dragon's Tail
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Almond cookie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Chicken and broccoli', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Chow mein', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Egg rolls (4)', 3.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'General Tao''s chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Hot and Sour Soup', 7.55, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Hunan dumplings', 6.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Mongolian beef', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Pan-fried beef noodle', 7.95, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Pea shoots with garlic', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Potstickers (6)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Seafood hotpot', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Steamed rice', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Sweet and sour pork', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Walnut prawns', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Wonton Soup', 6.25, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('dragon', 'Young Chow fried rice', 6.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 20: Hit Me Baby One More Thai
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'babythai',
    'Hit Me Baby One More Thai',
    'Thai food with a youthful bar scene. Try our tropical inspired cocktails, or tuck into a plate of our famous pad thai.',
    'Thai',
    5,
    '25-35 min',
    4.58,
    17.96,
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

-- Menu items for Hit Me Baby One More Thai
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Basil duck with rice', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Curry salmon', 12.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Egg rolls (4)', 5.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Fried banana and ice cream', 11.45, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Green curry with chicken', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Green curry with pork', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Hot tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Onion pancake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Pad See Ew', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Pad Thai', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Pumpkin curry', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Red curry with chicken', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Red curry with pork', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Sticky rice with mango', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Thai iced coffee', 6.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Thai iced tea', 3.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('babythai', 'Tofu salad rolls', 10.45, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 21: The Whole Tamale
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'wholetamale',
    'The Whole Tamale',
    'The tamale and hot sauce experts. Tamale special changes daily.',
    'Mexican',
    4,
    '20-30 min',
    3.07,
    19.81,
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

-- Menu items for The Whole Tamale
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Beans and rice', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Beef burrito', 6.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Birria', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Chicken burrito', 11.45, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Chicken mole platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Chile relleno (meat)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Chile relleno (vegetarian)', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Chips and guacamole', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Enchiladas', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Flan', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Jamaica Aqua Fresca', 2.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Pork al pastor platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Sopa de albondigas', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Sopa de pollo', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Strawberry Aqua Fresca', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Super nachos with carne asada', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Tacos de la casa (3)', 4.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wholetamale', 'Vegetarian platter', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 22: Birmingham Bhangra
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'bhangra',
    'Birmingham Bhangra',
    'Curry with a metropolitan twist. Daily specials. Dine-in or takeaway, you choose.',
    'Indian',
    2,
    '30-45 min',
    7.62,
    23.10,
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

-- Menu items for Birmingham Bhangra
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Aloo Gobi', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Basmati rice', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Butter Chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Chicken Korma', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Chicken Tikka Masala', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Gulab Jamun', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Kheer', 4.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Lamb Asparagus', 9.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Lamb Vindaloo', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Mix Grill Bombay', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Mulligatawny soup', 5.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Murgh Chicken', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Naan stuffed with spinach and lamb', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Plain naan', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Rogan Josh', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Saag Paneer', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('bhangra', 'Tandoori Chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 23: Taqueria
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'taqueria',
    'Taqueria',
    'Taqueria y panaderia. Birria served on weekends.',
    'Mexican',
    3,
    '25-35 min',
    5.40,
    16.10,
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

-- Menu items for Taqueria
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Beans and rice', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Beef burrito', 6.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Birria', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Chicken burrito', 11.45, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Chicken mole platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Chile relleno (meat)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Chile relleno (vegetarian)', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Chips and guacamole', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Enchiladas', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Flan', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Jamaica Aqua Fresca', 2.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Pork al pastor platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Sopa de albondigas', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Sopa de pollo', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Strawberry Aqua Fresca', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Super nachos with carne asada', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Tacos de la casa (3)', 4.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('taqueria', 'Vegetarian platter', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 24: Pedro's
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'pedros',
    'Pedro''s',
    'Pedro''s has been an Alameda staple for thirty years. Our list of fine tequilas and slow-cooked carnitas will make you a regular.',
    'Mexican',
    5,
    '30-45 min',
    7.89,
    20.71,
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

-- Menu items for Pedro's
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Beans and rice', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Beef burrito', 6.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Birria', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Chicken burrito', 11.45, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Chicken mole platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Chile relleno (meat)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Chile relleno (vegetarian)', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Chips and guacamole', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Enchiladas', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Flan', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Jamaica Aqua Fresca', 2.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Pork al pastor platter', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Sopa de albondigas', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Sopa de pollo', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Strawberry Aqua Fresca', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Super nachos with carne asada', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Tacos de la casa (3)', 4.95, 'Mexican', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pedros', 'Vegetarian platter', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 25: Super Wonton Express
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'superwonton',
    'Super Wonton Express',
    'Soups, stir-fries, and more. We cook fast.',
    'Chinese',
    1,
    '20-30 min',
    3.79,
    15.64,
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

-- Menu items for Super Wonton Express
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Almond cookie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Chicken and broccoli', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Chow mein', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Egg rolls (4)', 3.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'General Tao''s chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Hot and Sour Soup', 7.55, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Hunan dumplings', 6.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Mongolian beef', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Pan-fried beef noodle', 7.95, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Pea shoots with garlic', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Potstickers (6)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Seafood hotpot', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Steamed rice', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Sweet and sour pork', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Walnut prawns', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Wonton Soup', 6.25, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('superwonton', 'Young Chow fried rice', 6.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 26: Naan Sequitur
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'naansequitur',
    'Naan Sequitur',
    'Naan and tandoori specialties, from our clay oven. ',
    'Indian',
    4,
    '35-50 min',
    7.95,
    32.79,
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

-- Menu items for Naan Sequitur
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Aloo Gobi', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Basmati rice', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Butter Chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Chicken Korma', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Chicken Tikka Masala', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Gulab Jamun', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Kheer', 4.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Lamb Asparagus', 9.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Lamb Vindaloo', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Mix Grill Bombay', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Mulligatawny soup', 5.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Murgh Chicken', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Naan stuffed with spinach and lamb', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Plain naan', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Rogan Josh', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Saag Paneer', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('naansequitur', 'Tandoori Chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 27: Sakura
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'sakura',
    'Sakura',
    'Sushi specials daily. We serve fast, friendly, fresh Japanese cuisine.',
    'Japanese',
    2,
    '25-35 min',
    5.90,
    19.69,
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

-- Menu items for Sakura
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'California roll', 5.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Chicken teriyaki', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Edamame', 6.95, 'Appetizers', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Green tea ice cream', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Kitsune Udon', 9.5, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Miso soup', 5.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Pork Katsu', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Salmon teriyaki', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Sashimi combo', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Spicy Yellowtail roll', 7.55, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Sushi combo', 4.55, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Teppa Maki', 5.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Unagi Don', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Vegetable tempura', 3.95, 'Appetizers', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Vegetarian sushi plate', 6.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('sakura', 'Wakame salad', 4.95, 'Salads', true)
ON CONFLICT DO NOTHING;

-- Restaurant 28: Shandong Lu
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'shandong',
    'Shandong Lu',
    'Szechuan and Mandarin specialities with a fine dining ambiance. Our hot and sour soup is the best in town.',
    'Chinese',
    3,
    '30-45 min',
    6.25,
    27.82,
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

-- Menu items for Shandong Lu
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Almond cookie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Chicken and broccoli', 9.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Chow mein', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Egg rolls (4)', 3.95, 'Sushi', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'General Tao''s chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Hot and Sour Soup', 7.55, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Hunan dumplings', 6.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Mongolian beef', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Pan-fried beef noodle', 7.95, 'Noodles', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Pea shoots with garlic', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Potstickers (6)', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Seafood hotpot', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Steamed rice', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Sweet and sour pork', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Walnut prawns', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Wonton Soup', 6.25, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('shandong', 'Young Chow fried rice', 6.45, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 29: Curry Galore
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'currygalore',
    'Curry Galore',
    'Famous North Indian home cooking. Spicy or mild, as you like it. Delivery available.',
    'Indian',
    2,
    '25-35 min',
    5.68,
    18.87,
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

-- Menu items for Curry Galore
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Aloo Gobi', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Basmati rice', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Butter Chicken', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Chicken Korma', 7.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Chicken Tikka Masala', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Gulab Jamun', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Kheer', 4.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Lamb Asparagus', 9.5, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Lamb Vindaloo', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Mix Grill Bombay', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Mulligatawny soup', 5.95, 'Soups', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Murgh Chicken', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Naan stuffed with spinach and lamb', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Plain naan', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Rogan Josh', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Saag Paneer', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('currygalore', 'Tandoori Chicken', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 30: North by Northwest
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'north',
    'North by Northwest',
    'Great coffee and snacks. Free wifi. ',
    'cafe',
    4,
    '15-25 min',
    2.71,
    12.36,
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

-- Menu items for North by Northwest
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Apple pie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'B.L.T. and Avocado Sandwich', 5.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Caesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Cappucino', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Cherry cheesecake', 4.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Chocolate chip cookie', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Cobb salad', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Drip coffee', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Eggsalad Sandwich', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Espresso', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Greek salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Hot tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Iced tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Latte', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Mango and banana smoothie', 3, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Orange juice', 4.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Quiche of the day', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('north', 'Turkey Sandwich', 7.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;

-- Restaurant 31: Full of Beans
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'beans',
    'Full of Beans',
    'We roast on premises to give you the best cup of coffee in town. ',
    'cafe',
    5,
    '25-35 min',
    6.16,
    24.39,
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

-- Menu items for Full of Beans
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Apple pie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'B.L.T. and Avocado Sandwich', 5.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Caesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Cappucino', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Cherry cheesecake', 4.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Chocolate chip cookie', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Cobb salad', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Drip coffee', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Eggsalad Sandwich', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Espresso', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Greek salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Hot tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Iced tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Latte', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Mango and banana smoothie', 3, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Orange juice', 4.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Quiche of the day', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('beans', 'Turkey Sandwich', 7.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;

-- Restaurant 32: Tropical Jeeve's Cafe
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'jeeves',
    'Tropical Jeeve''s Cafe',
    'Hawaiian style coffee, fresh juices, and tropical fruit smoothies.',
    'cafe',
    4,
    '20-30 min',
    4.59,
    15.09,
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

-- Menu items for Tropical Jeeve's Cafe
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Apple pie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'B.L.T. and Avocado Sandwich', 5.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Caesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Cappucino', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Cherry cheesecake', 4.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Chocolate chip cookie', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Cobb salad', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Drip coffee', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Eggsalad Sandwich', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Espresso', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Greek salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Hot tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Iced tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Latte', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Mango and banana smoothie', 3, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Orange juice', 4.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Quiche of the day', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('jeeves', 'Turkey Sandwich', 7.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;

-- Restaurant 33: Zardoz Cafe
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'zardoz',
    'Zardoz Cafe',
    'Coffee bar and sci-fi bookshop. Come in for an espresso or a slice of our famous pie.',
    'cafe',
    2,
    '30-45 min',
    6.25,
    28.95,
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

-- Menu items for Zardoz Cafe
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Apple pie', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'B.L.T. and Avocado Sandwich', 5.95, 'Sandwiches', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Caesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Cappucino', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Cherry cheesecake', 4.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Chocolate chip cookie', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Cobb salad', 6.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Drip coffee', 5.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Eggsalad Sandwich', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Espresso', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Greek salad', 3.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Hot tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Iced tea', 2.5, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Latte', 4, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Mango and banana smoothie', 3, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Orange juice', 4.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Quiche of the day', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('zardoz', 'Turkey Sandwich', 7.55, 'Sandwiches', true)
ON CONFLICT DO NOTHING;

-- Restaurant 34: Angular Pizza
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'angular',
    'Angular Pizza',
    'Home of the superheroic pizza! ',
    'pizza',
    5,
    '15-25 min',
    3.03,
    5.22,
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

-- Menu items for Angular Pizza
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Cesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Cheesecake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Chicago-style deep dish chicken and spinach', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Chicago-style deep dish pepperoni and cheese', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Chicago-style deep dish vegetarian', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Chicago-style meat lover''s', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Chocolate cake', 3.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Coffee', 7.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Greek salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Pizza of the day (slice)', 7.55, 'Pizza', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Thin crust anchovy and garlic and chili pepper', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Thin crust broccoli, chicken, and mozarella', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Thin crust margherita', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Thin crust pepperoni', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Thin crust quattro stagione', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('angular', 'Thin crust sausage and guanciale bacon', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 35: Flavia
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'flavia',
    'Flavia',
    'Roman-style pizza -- square, the way the gods intended.',
    'pizza',
    5,
    '30-45 min',
    6.17,
    21.71,
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

-- Menu items for Flavia
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Cesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Cheesecake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Chicago-style deep dish chicken and spinach', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Chicago-style deep dish pepperoni and cheese', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Chicago-style deep dish vegetarian', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Chicago-style meat lover''s', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Chocolate cake', 3.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Coffee', 7.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Greek salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Pizza of the day (slice)', 7.55, 'Pizza', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Thin crust anchovy and garlic and chili pepper', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Thin crust broccoli, chicken, and mozarella', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Thin crust margherita', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Thin crust pepperoni', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Thin crust quattro stagione', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('flavia', 'Thin crust sausage and guanciale bacon', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 36: Luigi's House of Pies
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'luigis',
    'Luigi''s House of Pies',
    'Our secret pizza sauce makes our pizza better. We specialize in large groups.',
    'pizza',
    1,
    '20-30 min',
    3.24,
    19.55,
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

-- Menu items for Luigi's House of Pies
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Cesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Cheesecake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Chicago-style deep dish chicken and spinach', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Chicago-style deep dish pepperoni and cheese', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Chicago-style deep dish vegetarian', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Chicago-style meat lover''s', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Chocolate cake', 3.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Coffee', 7.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Greek salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Pizza of the day (slice)', 7.55, 'Pizza', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Thin crust anchovy and garlic and chili pepper', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Thin crust broccoli, chicken, and mozarella', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Thin crust margherita', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Thin crust pepperoni', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Thin crust quattro stagione', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('luigis', 'Thin crust sausage and guanciale bacon', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 37: Thick and Thin
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'thick',
    'Thick and Thin',
    'Whether you''re craving Chicago-style deep dish or thin as a wafer crust, we have you covered in toppings you''ll love.',
    'pizza',
    4,
    '35-50 min',
    8.82,
    27.99,
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

-- Menu items for Thick and Thin
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Cesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Cheesecake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Chicago-style deep dish chicken and spinach', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Chicago-style deep dish pepperoni and cheese', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Chicago-style deep dish vegetarian', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Chicago-style meat lover''s', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Chocolate cake', 3.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Coffee', 7.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Greek salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Pizza of the day (slice)', 7.55, 'Pizza', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Thin crust anchovy and garlic and chili pepper', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Thin crust broccoli, chicken, and mozarella', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Thin crust margherita', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Thin crust pepperoni', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Thin crust quattro stagione', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('thick', 'Thin crust sausage and guanciale bacon', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 38: When in Rome
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'wheninrome',
    'When in Rome',
    'Authentic Italian pizza in a friendly neighborhood joint.',
    'pizza',
    2,
    '25-35 min',
    4.63,
    20.88,
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

-- Menu items for When in Rome
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Cesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Cheesecake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Chicago-style deep dish chicken and spinach', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Chicago-style deep dish pepperoni and cheese', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Chicago-style deep dish vegetarian', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Chicago-style meat lover''s', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Chocolate cake', 3.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Coffee', 7.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Greek salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Pizza of the day (slice)', 7.55, 'Pizza', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Thin crust anchovy and garlic and chili pepper', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Thin crust broccoli, chicken, and mozarella', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Thin crust margherita', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Thin crust pepperoni', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Thin crust quattro stagione', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('wheninrome', 'Thin crust sausage and guanciale bacon', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;

-- Restaurant 39: Pizza 76
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'pizza76',
    'Pizza 76',
    'Wood-fired pizza with daily ingredients fresh from our farmer''s market. We make our own mozzarella in house.',
    'pizza',
    3,
    '30-45 min',
    6.09,
    24.90,
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

-- Menu items for Pizza 76
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Cesar salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Cheesecake', 6.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Chicago-style deep dish chicken and spinach', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Chicago-style deep dish pepperoni and cheese', 7.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Chicago-style deep dish vegetarian', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Chicago-style meat lover''s', 8.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Chocolate cake', 3.95, 'Desserts', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Coffee', 7.95, 'Beverages', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Greek salad', 5.95, 'Salads', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Pizza of the day (slice)', 7.55, 'Pizza', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Thin crust anchovy and garlic and chili pepper', 5.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Thin crust broccoli, chicken, and mozarella', 3.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Thin crust margherita', 4.55, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Thin crust pepperoni', 6.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Thin crust quattro stagione', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;
INSERT INTO menu_items (restaurant_id, name, price, category, is_available)
VALUES ('pizza76', 'Thin crust sausage and guanciale bacon', 4.95, 'Main Dishes', true)
ON CONFLICT DO NOTHING;


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
