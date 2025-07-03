-- Auto-generated SQL file for importing restaurant data (UUID version)
-- Generated on: 2025-07-03T09:55:13.523Z
-- Source: server/data/restaurants.json

-- Clear existing data (in dependency order)
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE menu_items CASCADE;
TRUNCATE TABLE restaurants CASCADE;
TRUNCATE TABLE customers CASCADE;

BEGIN;

-- Restaurant 1: Esther's German Saloon
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Esther''s German Saloon',
    'German home-cooked meals and fifty-eight different beers on tap. To get more authentic, you''d need to be wearing lederhosen.',
    'german',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 2: Robatayaki Hachi
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Robatayaki Hachi',
    'Japanese food the way you like it. Fast, fresh, grilled.',
    'japanese',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 3: BBQ Tofu Paradise
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'BBQ Tofu Paradise',
    'Vegetarians, we have your BBQ needs covered. Our home-made tofu skewers and secret BBQ sauce will have you licking your fingers.',
    'vegetarian',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 4: Le Bateau Rouge
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'Le Bateau Rouge',
    'Fine French dining in a romantic setting. From soupe à l''oignon to coq au vin, let our chef delight you with a local take on authentic favorites.',
    'french',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 5: Khartoum Khartoum
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Khartoum Khartoum',
    'African homestyle cuisine, cooked fresh daily.',
    'african',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 6: Sally's Diner
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Sally''s Diner',
    'Food like mom cooked, if you grew up in Iowa and mom ran a diner. Try our blue plate special!',
    'american',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 7: Saucy Piggy
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Saucy Piggy',
    'Pork. We know how to cook it. Award-winning BBQ sauce, and meat with all the trimmings.',
    'barbecue',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 8: Czech Point
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd3245431-7f00-484e-8152-df548662b01b',
    'Czech Point',
    'Make a point of trying our knedlíky and homemade soups. We have free wifi and the best desserts and coffee. ',
    'czech/slovak',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 9: Der Speisewagen
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Der Speisewagen',
    'Award-winning schnitzel and other favorites. Look for our restored food truck in the NE corner of the College St lot.',
    'german',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 10: Beijing Express
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Beijing Express',
    'Fast, healthy, Chinese food. Family specials for takeout or delivery. Try our Peking Duck!',
    'chinese',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 11: Satay Village
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Satay Village',
    'Fine dining Thai-style. Wide selection of vegetarian entrées. We also deliver.',
    'thai',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 12: Cancun
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Cancun',
    'Tacos, tortas, burritos, just the way you like them. Our hot sauce and guacamole are the best in town.',
    'mexican',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 13: Curry Up
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Curry Up',
    'Indian food with a modern twist. We use all-natural ingredients and the finest spices to delight and tempt your palate.',
    'indian',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 14: Carthage
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Carthage',
    'Wholesome food and all the rich flavor of Africa. Try our famous lentil soup.',
    'african',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 15: Burgerama
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Burgerama',
    'Grade A beef, freshly ground every day, hand-cut fries, and home-made milkshakes. We make the best burgers in town. ',
    'american',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 16: Three Little Pigs
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Three Little Pigs',
    'Genuine East Texas barbecue. Accept no substitutes! ',
    'barbecue',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 17: Little Prague
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Little Prague',
    'We''re famous for our housemade sausage and desserts. Come taste real European cooking.',
    'czech/slovak',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 18: Kohl Haus
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Kohl Haus',
    'East German specialties, in a family-friendly setting. Come warm up with our delicious soups.',
    'german',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 19: Dragon's Tail
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Dragon''s Tail',
    'Take-out or dine-in Chinese food. Open late. Delivery available',
    'chinese',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 20: Hit Me Baby One More Thai
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Hit Me Baby One More Thai',
    'Thai food with a youthful bar scene. Try our tropical inspired cocktails, or tuck into a plate of our famous pad thai.',
    'thai',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 21: The Whole Tamale
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'The Whole Tamale',
    'The tamale and hot sauce experts. Tamale special changes daily.',
    'mexican',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 22: Birmingham Bhangra
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Birmingham Bhangra',
    'Curry with a metropolitan twist. Daily specials. Dine-in or takeaway, you choose.',
    'indian',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 23: Taqueria
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Taqueria',
    'Taqueria y panaderia. Birria served on weekends.',
    'mexican',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 24: Pedro's
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Pedro''s',
    'Pedro''s has been an Alameda staple for thirty years. Our list of fine tequilas and slow-cooked carnitas will make you a regular.',
    'mexican',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 25: Super Wonton Express
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Super Wonton Express',
    'Soups, stir-fries, and more. We cook fast.',
    'chinese',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 26: Naan Sequitur
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Naan Sequitur',
    'Naan and tandoori specialties, from our clay oven. ',
    'indian',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 27: Sakura
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Sakura',
    'Sushi specials daily. We serve fast, friendly, fresh Japanese cuisine.',
    'japanese',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 28: Shandong Lu
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Shandong Lu',
    'Szechuan and Mandarin specialities with a fine dining ambiance. Our hot and sour soup is the best in town.',
    'chinese',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 29: Curry Galore
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Curry Galore',
    'Famous North Indian home cooking. Spicy or mild, as you like it. Delivery available.',
    'indian',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 30: North by Northwest
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'North by Northwest',
    'Great coffee and snacks. Free wifi. ',
    'cafe',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 31: Full of Beans
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Full of Beans',
    'We roast on premises to give you the best cup of coffee in town. ',
    'cafe',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 32: Tropical Jeeve's Cafe
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Tropical Jeeve''s Cafe',
    'Hawaiian style coffee, fresh juices, and tropical fruit smoothies.',
    'cafe',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 33: Zardoz Cafe
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Zardoz Cafe',
    'Coffee bar and sci-fi bookshop. Come in for an espresso or a slice of our famous pie.',
    'cafe',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 34: Angular Pizza
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Angular Pizza',
    'Home of the superheroic pizza! ',
    'pizza',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 35: Flavia
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '33970121-fb6e-414f-8706-4788ee407375',
    'Flavia',
    'Roman-style pizza -- square, the way the gods intended.',
    'pizza',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 36: Luigi's House of Pies
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Luigi''s House of Pies',
    'Our secret pizza sauce makes our pizza better. We specialize in large groups.',
    'pizza',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 37: Thick and Thin
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thick and Thin',
    'Whether you''re craving Chicago-style deep dish or thin as a wafer crust, we have you covered in toppings you''ll love.',
    'pizza',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 38: When in Rome
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'When in Rome',
    'Authentic Italian pizza in a friendly neighborhood joint.',
    'pizza',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 39: Pizza 76
INSERT INTO restaurants (id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Pizza 76',
    'Wood-fired pizza with daily ingredients fresh from our farmer''s market. We make our own mozzarella in house.',
    'pizza',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

COMMIT;

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
