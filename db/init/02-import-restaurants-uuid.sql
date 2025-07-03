-- Auto-generated SQL file for importing restaurant data (UUID version)
-- Generated on: 2025-07-03T11:10:06.673Z
-- Source: server/data/restaurants.json

-- Clear existing data (in dependency order)
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE menu_items CASCADE;
TRUNCATE TABLE restaurants CASCADE;
TRUNCATE TABLE customers CASCADE;

BEGIN;

-- Restaurant 1: Esther's German Saloon
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'esthers',
    'Esther''s German Saloon',
    'German home-cooked meals and fifty-eight different beers on tap. To get more authentic, you''d need to be wearing lederhosen.',
    'german',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4034897f-2ca8-4d27-881d-17ca96d84601',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Bockwurst Würstchen',
    NULL,
    4.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c4ac299f-f4e2-4b87-8ec5-f8cffc763e82',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Bratwurst mit Brötchen und Sauerkraut',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '75127a24-8c84-445b-86f9-2f16d0a5cbf3',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Currywurst mit Brötchen',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a8f01092-571f-4312-8f78-d8c0c8ba3761',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Das Hausmannskost',
    NULL,
    11.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '12708173-f7e4-4a1b-8580-53ae5f8c0c58',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Fleishkas mit Kartoffelsalat',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1898bcd8-97f8-4905-88b6-1405723a3b7c',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Frankfurter Würstchen',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bf863e30-11da-40cb-8c79-7169cb7c203a',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Französische Zwiebelsuppe mit Käse',
    NULL,
    10.45,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a01be991-8592-413a-864b-d777c5ebc616',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Frikadelle mit Brötchen',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f78319aa-3ba2-4fb3-810c-34bf86384873',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Gebackener Camenbert',
    NULL,
    7.55,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e948ffd6-2a96-4a8c-8d9e-ba1a59860fc5',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Gemischter Salat',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1f9caabf-3d17-4829-8497-eac46bdf1e73',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Haus Salatteller',
    NULL,
    11.45,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd5d5fdcd-f99a-4136-8bd6-441d10a3af23',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Jaegerschnitzel',
    NULL,
    9.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '487054d7-0023-4677-8201-ba0518f1bc5b',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Kaesepaetzle',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5aab84f9-6828-4f9d-8697-5da0620d24ca',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Kartoffel Reibekuchen mit Apfelmus',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '73a875c7-94bd-429b-8e4e-ce5d38d8d26d',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Maultaschen mit Käse',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a868565c-9cae-459d-8abb-8d649838cf54',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Sauerbraten',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c10f37ad-9887-4f03-8c46-d094447c254d',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Ungarische Gulaschsuppe mit Brötchen',
    NULL,
    3.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '53ae8d23-d1f9-4e11-8044-b3d6c6e3414e',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Wienerschnitzel',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '875dcf2e-6fce-4bf0-872d-b347ed5c4eb0',
    'a8f2fbf5-4acc-48b3-8d17-d2d96a1c4990',
    'Wurstsalad mit Bauernbrot',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 2: Robatayaki Hachi
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'robatayaki',
    'Robatayaki Hachi',
    'Japanese food the way you like it. Fast, fresh, grilled.',
    'japanese',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '105cf0ee-dc15-4b09-8946-b614cf440ef7',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'California roll',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4c55ffb4-eb16-42fc-8bfd-edd2ff486069',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Chicken teriyaki',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4fd9c9f3-2063-461a-8889-1bbfe6dfbe9b',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Edamame',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8645486f-96c6-4a10-897e-b02ec1c088f0',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Green tea ice cream',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fa2cb47d-51a4-4d03-8333-421ab1dbe956',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Kitsune Udon',
    NULL,
    9.5,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '618f0a6c-cb90-4f37-8a84-4ac743c6c5a5',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Miso soup',
    NULL,
    5.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '843b9c0b-9dad-4ce5-88a0-6f667f486644',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Pork Katsu',
    NULL,
    5.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e4f656ce-a7ed-4532-86f5-64af08d90935',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Salmon teriyaki',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '24820cac-d6e8-46ea-8faf-0798c058a86e',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Sashimi combo',
    NULL,
    6.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '80cfa6a0-d9a9-4ab9-8fd8-ec43555a3d47',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Spicy Yellowtail roll',
    NULL,
    7.55,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8966182f-3499-46cc-879f-92277b4751dc',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Sushi combo',
    NULL,
    4.55,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '618bbecf-9acf-4158-866b-685e3c65b487',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Teppa Maki',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '11151e5f-68c3-419f-8611-2b37bca46d0c',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Unagi Don',
    NULL,
    7.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c2e3e94c-bc22-4743-8e0a-d755a407e98c',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Vegetable tempura',
    NULL,
    3.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4d6372f0-34c4-4704-8029-726693cc0f0d',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Vegetarian sushi plate',
    NULL,
    6.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd848be16-a57c-406e-8e9e-a6cea581e902',
    'd054d9fc-ec06-43bf-8c63-b9327e762329',
    'Wakame salad',
    NULL,
    4.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 3: BBQ Tofu Paradise
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'tofuparadise',
    'BBQ Tofu Paradise',
    'Vegetarians, we have your BBQ needs covered. Our home-made tofu skewers and secret BBQ sauce will have you licking your fingers.',
    'vegetarian',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '67da7294-4a8a-4132-8d63-ef0d6a984308',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'bean and cheese burrito',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c6ce8acc-8e5a-4abd-8c14-0fc118e760a6',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'cheese tortellini in tomato sauce',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b5001e13-90df-4ff6-8e27-6d1e04bfcf2e',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'coffee',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f34d8ae7-9b90-4c84-87ed-1c94a8e8e2ae',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'falafel wrap with tabbouleh',
    NULL,
    4.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b0bdd4ba-ca3a-422b-8396-6a49c4bde35b',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'flourless chocolate cake',
    NULL,
    8.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '916b0cb8-e266-4585-8403-43a2e08b46b6',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'garden fresh salad',
    NULL,
    6.5,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7a555e7c-7da3-4498-8f0a-d35cef2c0568',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'happy buddha stir fry',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4178f8d7-c469-4b77-8caa-f07fb409dc27',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'hummus appetizer plate',
    NULL,
    8,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '16ce83f0-9682-4d73-82b8-db48f9008f42',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'lentil burger',
    NULL,
    6,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ae241ee7-2dff-4e6c-8b27-5d16bbf390d4',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'lentil soup',
    NULL,
    4.5,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '74cb16e8-3788-4306-8929-23b6b31635a1',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'pasta with olives and marinated lemon',
    NULL,
    6.95,
    'Pasta',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ae45b927-f789-48a2-85df-65ccd4d04c1d',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'spinach and cheese wrap',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '582c5e63-a34f-45cd-8a32-967a6ca14393',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'tea',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '324bfe03-02eb-4514-8fb7-caab761e6f15',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'toasted sandwich with grilled eggplant',
    NULL,
    8.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1897f94b-023a-4416-8c61-ed6d2e371e42',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'tofu chicken wrap',
    NULL,
    9.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '13eb54be-df93-4c49-8801-1fafa0d03c0b',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'tomato and cheese sandwich',
    NULL,
    11.45,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '67e87b6d-32c1-49c0-836f-5d46632f04d5',
    '9c8b2e99-fcf2-439e-82fe-ee8fe731232b',
    'vegetable stew',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 4: Le Bateau Rouge
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'bateaurouge',
    'Le Bateau Rouge',
    'Fine French dining in a romantic setting. From soupe à l''oignon to coq au vin, let our chef delight you with a local take on authentic favorites.',
    'french',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7410927f-38b7-41de-8308-25b4c00ab389',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'bavette dans son jus',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ab832e57-e91a-4c8a-8956-63cdc8e13ccf',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'bœuf bourguignon ',
    NULL,
    18,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '93304a4d-d95b-46d1-8467-125f856abc7c',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'bouillabaisse',
    NULL,
    17.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8a6a7e54-ec28-4aa3-8357-822b1e36bccd',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'coq au vin',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2e62ea90-2e48-4aa5-8035-d08a251741ff',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'moules et frites',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd20f1201-a78f-4d9c-86e4-8c2e38f70e3e',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'poulet au riesling',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8492beb2-44c4-4e12-89bc-31fdb35ee222',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'quiche lorraine',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b1807bbb-d52a-4aa5-8531-c77dd7708cb5',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'salade de chèvre chaud',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a4a2146b-8b03-47d3-856f-beeb98bc5b8c',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'salade du midi',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '56468ac7-88ac-4066-86b2-4a78604707d8',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'salade niçoise',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '28257567-904a-4d3e-8a60-c51f47b12996',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'sandwich croque-madame',
    NULL,
    3.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '820fc193-40b9-42ac-8f62-c2f8cad83f21',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'sandwich croque-monsieur',
    NULL,
    4.55,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '77858e61-62f2-44a9-88f3-5c146ddc10ad',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'soupe à l''oignon',
    NULL,
    9.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd870d329-c71d-4a49-878d-59bdbe46ddbd',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'steak frites',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0f3c3815-4316-4312-8626-818521e9f26b',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'tarte pissaladière ',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '89bec83a-894e-4871-8ef2-feb7fb2a889a',
    '28285c68-aa2b-41cf-8397-5c7a5dcddc5e',
    'tarte tatin',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 5: Khartoum Khartoum
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'khartoum',
    'Khartoum Khartoum',
    'African homestyle cuisine, cooked fresh daily.',
    'african',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f67ba0d4-1593-45fb-856c-801f85baa8d1',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Dibi Lamb',
    NULL,
    8.25,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2b99689e-d508-4c7f-84d4-895124dbf45e',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Doro Wat',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '05debedd-78cb-4cc2-82da-354934a15e74',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Grilled Chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a5cb6499-61bc-4480-8322-1085197ade93',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Grilled Fish',
    NULL,
    6.95,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '67b4da7c-7c80-4bc9-895b-6f88fd865f9c',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Grilled Plantains in Spicy Peanut Sauce',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'da25c962-4cbd-4a9d-8d7c-ad36660ba32e',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Lamb Mafe (Peanut Butter Stew)',
    NULL,
    8.75,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '10d459be-47a5-4c81-8c43-9cad54d9ba75',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Meat Pie',
    NULL,
    6,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'dd0b6fb5-3094-418c-840c-555a5c458223',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Mechoui with Plantains',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3f939883-926c-4afc-80f1-7e29717ca06c',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Pepper Soup',
    NULL,
    9.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '72f846fd-e53e-4ebb-8505-2cbdeb78b4be',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Piri-Piri Shrimp',
    NULL,
    11.45,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3ce3808d-3c25-46db-8d9a-6823029aa2af',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Suppa Kandja',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c6de28aa-b25f-4f51-837f-c750382fcc74',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Thiou Boulette',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a543965e-2855-4f52-8e46-3d1babab6e22',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Thiou Curry with Chicken',
    NULL,
    7.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd9b91b77-e7e6-4015-8509-465bd5b2b72a',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Thu Okra',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6c972298-28d9-4cfd-8aa0-41ca2ad16d99',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Yassa Chicken',
    NULL,
    8.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'dd2f36fe-5de8-4ef2-823d-ea127d8cb1cc',
    'edb075da-8973-4c35-8d6d-cc1e343b914e',
    'Yassa Lamb',
    NULL,
    8.25,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 6: Sally's Diner
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'sallys',
    'Sally''s Diner',
    'Food like mom cooked, if you grew up in Iowa and mom ran a diner. Try our blue plate special!',
    'american',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1e5895a0-6b28-4fbc-8715-30da90fee6a2',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Buffalo wings',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c75489af-0a5f-4ac7-865a-c2f6eb75d6ba',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'California-style baked Tilapia with rice',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ba31f5da-a594-4f9f-86bf-11f4f62a80fb',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Cheeseburger and fries',
    NULL,
    4.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8bb95f4f-c6b3-4877-811a-91d82f3fbec0',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Cherry pie a la mode',
    NULL,
    4.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e802adca-4d53-44eb-82f5-177f9219e7eb',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Chocolate milkshake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a3a6901e-a4d1-4ab2-8fa3-f293434da309',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Cobb salad',
    NULL,
    4.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd184747a-96a1-473f-8170-ab597474ef8d',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Famous BLT on a kaiser roll with fries',
    NULL,
    4.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e2c96527-8d91-43fa-82b2-cc39e153f1f1',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Firehouse chili',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2b5cbe54-c7c5-4219-892a-9a6bb21e67f9',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Goat cheese and eggplant wrap (vegetarian)',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f42936d8-79f3-4468-872e-93f8f6fb5a86',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Greek salad',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7f0e1b13-926a-4610-85b5-7f902e3136a6',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Grilled chicken sandwich',
    NULL,
    4.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a130a427-8183-4a66-88f5-4c9592cfce98',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Grilled sausage on a bun',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a0b924cd-34c3-409e-8639-85e6fc2e2e9a',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Housemade pot roast with seasonal vegetable',
    NULL,
    16.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b1ff9b5f-3f82-490e-8ae0-793431cb3a98',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Roast beef dip',
    NULL,
    11.45,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '98877294-8eba-49d3-8d4b-cf0f131073df',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Roast chicken and mashed potatoes',
    NULL,
    7.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b56064e0-eb9f-4fdb-8f43-e05c77bcc795',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Soup of the day',
    NULL,
    8.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '34274581-b9ec-4153-8b0e-f1c8655b3837',
    'e7e9bd8c-e9a7-4691-8161-bf6f40cf9fb4',
    'Spaghetti and meatballs',
    NULL,
    11.45,
    'Pasta',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 7: Saucy Piggy
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '05ec2808-0374-483e-85ef-525efedbe410',
    'saucy',
    'Saucy Piggy',
    'Pork. We know how to cook it. Award-winning BBQ sauce, and meat with all the trimmings.',
    'barbecue',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2cc46166-de12-47d3-81e5-abeec888f46f',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'BBQ chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3e776aea-99f5-4e62-89f1-364226f530bb',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Beef ribs (full)',
    NULL,
    9.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e08ff2d4-9033-49b8-8e2d-cd10f181e5cc',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Beef ribs (delux)',
    NULL,
    10.45,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'baf42fd3-9c9a-4585-88a9-3ec4cb4119b7',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Beef ribs (half)',
    NULL,
    6.45,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ac172246-43a0-4497-85ff-03a7fdc14797',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Beer',
    NULL,
    7.55,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '972960d9-991f-4e1b-8e64-f3748512a356',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Coleslaw',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '45098b17-de1c-4b1c-8a96-7ee86f9fb84a',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Collards',
    NULL,
    9.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a2d6d6a6-9255-4131-83ac-96cf0eb3ff22',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Cornbread',
    NULL,
    11.45,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '64fb20b3-4768-4794-838f-eadbfeaa395c',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Devilled eggs',
    NULL,
    4,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f1ad71b8-5519-468d-840f-16f499aaed0c',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'German chocolate cake',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '85de0f4f-8b3a-468f-88d0-a33001f80fdd',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Housemade chips',
    NULL,
    4,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2fcaa257-8cfc-4316-8065-164b014dd328',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Hushpuppies',
    NULL,
    3.25,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b6c1ca9f-6b0f-47a8-847c-c8dd6b7e9afe',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Mac and cheese',
    NULL,
    6,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2ca253a1-3bae-489b-89cb-40368633d49e',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Pork ribs (half)',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '390b821c-3e34-4604-8542-9dcdb1a24805',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Potato salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '12f2164c-959f-401c-87e7-0bec75830082',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Pulled pork sandwich on a soft roll',
    NULL,
    4.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd3e44ab0-ff24-49c9-80e0-4429c1676fba',
    '05ec2808-0374-483e-85ef-525efedbe410',
    'Riblets',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 8: Czech Point
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd3245431-7f00-484e-8152-df548662b01b',
    'czechpoint',
    'Czech Point',
    'Make a point of trying our knedlíky and homemade soups. We have free wifi and the best desserts and coffee. ',
    'czech/slovak',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1f560509-8094-4f87-8c1a-73654a2d2e6e',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Apple strudel',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '737d2801-97c1-4fa6-8073-cdb3cf0a4ab1',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Apricot dumpling with yogurt topping ',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6b9d2e35-e310-45e8-8b53-3b06f8e109ce',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Balkánský Salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2b398d15-7f25-4f8c-8a4e-675486a90922',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Beef goulash',
    NULL,
    8.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8cf148c4-d0da-443c-83f9-d18f894993c9',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Chicken breast fillet schnitzel ',
    NULL,
    10.45,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5924137a-ebd4-4911-8f84-ea56cc1d3019',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Cucumber Salad',
    NULL,
    7.55,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5f79af1f-2265-48df-8fa9-11001238df95',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Dumplings',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c49ee96c-fe2d-4cd0-80dd-eeda474704d5',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Fried goose liver with onion and bread',
    NULL,
    7.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c7def430-a485-4ef9-8ca7-0f3087c34ce2',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Halusky with sauerkraut and belly bacon ',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fb5f32e5-9873-408c-8fe1-89e339d12b37',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Lentil soup',
    NULL,
    4.5,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7fe11be8-2db2-44f5-8d8f-e179e56e79d6',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Pickles with cabbage and cheddar',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0d16c7fe-f67e-46bf-830d-9427c1cfc819',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Pork schnitzel',
    NULL,
    3.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8da00f54-9496-4774-857b-be97c3cf4c6e',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Potato pancake with bacon',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9ce95ba0-b7fe-45c6-8843-2945ee503012',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Potato Salad',
    NULL,
    4.55,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '48a8aa13-4cff-48b3-829e-d353d4c7ac08',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Segedínský gulash and dumplings',
    NULL,
    6.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b70ca1c9-b573-4fda-86d3-f6a216c96367',
    'd3245431-7f00-484e-8152-df548662b01b',
    'Sour cabbage soup',
    NULL,
    10.45,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 9: Der Speisewagen
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'speisewagen',
    'Der Speisewagen',
    'Award-winning schnitzel and other favorites. Look for our restored food truck in the NE corner of the College St lot.',
    'german',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1d6a3087-e735-470e-8795-7a0f10e1c28a',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Bockwurst Würstchen',
    NULL,
    4.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '733bfb94-f6a6-40f3-8032-780433fa61f5',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Bratwurst mit Brötchen und Sauerkraut',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2f8cf137-60ab-4f96-8d05-f5e4622db5d9',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Currywurst mit Brötchen',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cc1e2607-641a-423e-8b5e-41b44c070cde',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Das Hausmannskost',
    NULL,
    11.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e53d8958-24f7-4740-80a7-672448d9d926',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Fleishkas mit Kartoffelsalat',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd6815c35-7c4c-4f8d-8139-01ddad89af9c',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Frankfurter Würstchen',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3259e5b3-8159-4405-8eca-7d3952bc8332',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Französische Zwiebelsuppe mit Käse',
    NULL,
    10.45,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd8ac56f8-9ca1-4e4a-8e2e-b4d55573541f',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Frikadelle mit Brötchen',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '25bd4237-4aff-4627-800a-fb628a07bd1a',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Gebackener Camenbert',
    NULL,
    7.55,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '044061d1-6f19-4251-8b12-fdb7e6a0a11f',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Gemischter Salat',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'db2655d2-5b2e-44f1-8556-f53c1f99baa2',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Haus Salatteller',
    NULL,
    11.45,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b7ba713b-ccf4-4226-8e1a-6719c22a1b62',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Jaegerschnitzel',
    NULL,
    9.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '438625c7-7e9e-4b3d-827e-1c783f14f501',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Kaesepaetzle',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b68cffcf-cc9f-472a-8418-81c4c3294f89',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Kartoffel Reibekuchen mit Apfelmus',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd88825c8-e677-4d2c-8a76-24b1f85f32af',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Maultaschen mit Käse',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7489c2c1-8ab6-4f68-8b27-15e32beddb32',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Sauerbraten',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5d2fb683-e3e2-4977-8ea7-59274a9263cf',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Ungarische Gulaschsuppe mit Brötchen',
    NULL,
    3.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2352fa27-befe-44a0-8ed4-a36aedaaab96',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Wienerschnitzel',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fede0b78-45ae-4ebe-8cd9-7427c0f9d9c2',
    'db5a9b06-1fc4-4330-8db5-c68ebaed92fc',
    'Wurstsalad mit Bauernbrot',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 10: Beijing Express
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'beijing',
    'Beijing Express',
    'Fast, healthy, Chinese food. Family specials for takeout or delivery. Try our Peking Duck!',
    'chinese',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3eba3fbc-92ad-4c16-8d40-ad28ad7af5fe',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Almond cookie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f4984119-6d6b-4501-8e26-542dd489b930',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Chicken and broccoli',
    NULL,
    9.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fc8daa4e-0f00-42b1-8e6c-630a00cc95b8',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Chow mein',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6ba75cf0-07d1-4eec-8fd6-fcffc851b873',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Egg rolls (4)',
    NULL,
    3.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0537c0f1-0f56-4e19-831a-520761446bc7',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'General Tao''s chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '92887c29-dc42-40fc-8e58-1405a18cc298',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Hot and Sour Soup',
    NULL,
    7.55,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2ce5dc0d-3ca0-4e13-8cbb-9f24bc9c0e26',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Hunan dumplings',
    NULL,
    6.5,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '011afc6d-1775-4111-8252-ff8d84b78a6f',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Mongolian beef',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd241615f-9fd4-43a0-87ba-08b44c7c6244',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Pan-fried beef noodle',
    NULL,
    7.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '467a0181-5e6b-42c1-8e7a-06f447ebbca0',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Pea shoots with garlic',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9c76fcae-1e64-413d-860d-0b000dbc6ba8',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Potstickers (6)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '115a7bbd-da54-4e1b-8308-f7a190122f19',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Seafood hotpot',
    NULL,
    4.95,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '94b83f9c-c3ee-4452-8fa9-a81b11b22571',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Steamed rice',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c81874c1-8972-4aa6-8b53-6df7b5cad8b9',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Sweet and sour pork',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '63cbad2f-c825-4011-876f-7fc7e98ffc96',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Walnut prawns',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '93533a59-9eb2-4989-88f4-e2867f70d4b2',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Wonton Soup',
    NULL,
    6.25,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '92e27156-7bce-4cba-8548-6974f96fd1bb',
    'cc495deb-c1aa-4188-8a09-7446d16918ac',
    'Young Chow fried rice',
    NULL,
    6.45,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 11: Satay Village
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'satay',
    'Satay Village',
    'Fine dining Thai-style. Wide selection of vegetarian entrées. We also deliver.',
    'thai',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c5c95feb-0b91-4fc6-83c1-5de8cbab026d',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Basil duck with rice',
    NULL,
    4.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6624252b-6dce-4a0e-8573-d022a38973a2',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Curry salmon',
    NULL,
    12.45,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5d7ca3d1-d60a-4b40-8c68-3417a1dbeaf3',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Egg rolls (4)',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3ef3fb6b-a5c0-480b-8125-52db1016fb06',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Fried banana and ice cream',
    NULL,
    11.45,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b5a0c1ce-086b-4eae-86a9-b163fce579f6',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Green curry with chicken',
    NULL,
    3.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ab42d92f-b327-4053-8ba1-b29ec96aed59',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Green curry with pork',
    NULL,
    4.55,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '55777144-a39e-4016-8251-e7d10247b2c4',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Hot tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '985714ce-1cfe-441b-8977-b3a5f78129ee',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Onion pancake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b0b60d5e-2e08-4610-8dea-71fe11d53b74',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Pad See Ew',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6e1d3828-69ec-4005-84c6-faa117784c93',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Pad Thai',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fa50f4c8-a915-4586-8f69-50d3adeacce0',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Pumpkin curry',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1c881a56-44b5-440c-8f76-3df66adeedef',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Red curry with chicken',
    NULL,
    8.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '257165dd-5165-4797-87ea-27b409e4488c',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Red curry with pork',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e8991c33-a5c3-44de-8967-78c58fadedf1',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Sticky rice with mango',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fcee594d-386f-42fc-8c0d-1a24decb6105',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Thai iced coffee',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd5261baf-c759-423c-8827-ce95898b199d',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Thai iced tea',
    NULL,
    3.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '06a7857b-1d71-4f4d-89f1-cce535aa3c7d',
    '1fee6dc1-c020-4152-8aff-67fe6b622f56',
    'Tofu salad rolls',
    NULL,
    10.45,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 12: Cancun
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'cancun',
    'Cancun',
    'Tacos, tortas, burritos, just the way you like them. Our hot sauce and guacamole are the best in town.',
    'mexican',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cbc3f451-6391-44fd-8b82-143854c2e13d',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Beans and rice',
    NULL,
    7.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c2ee5d76-4a55-46c3-8cd4-1e3f90d355f2',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Beef burrito',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '61d37d21-1fbf-4aff-802b-9c365baaec18',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Birria',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '960e0595-1f8b-4cfc-8223-55051503e5d4',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Chicken burrito',
    NULL,
    11.45,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7c8bf7ff-ef94-468e-8892-d0b667250d86',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Chicken mole platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e3790e3f-fab2-49f2-844c-89144adf9f6a',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Chile relleno (meat)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0410f982-9e28-480c-83f7-3a7060c480d5',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Chile relleno (vegetarian)',
    NULL,
    3.95,
    'Vegetarian',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '201dc356-918c-4271-8ba1-94a98579fe82',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Chips and guacamole',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '84221818-8ea2-4bf7-889b-4da2ea10eec9',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Enchiladas',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '56c198e7-1fbc-4b1b-8ca7-290be2b2313e',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Flan',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '776f458a-a9c7-4e8a-89f2-85144c97a558',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Jamaica Aqua Fresca',
    NULL,
    2.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8292efcf-4ff2-4cad-89ac-25c9301626fe',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Pork al pastor platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5a0f129a-e34f-4d14-8650-fb987b969eb4',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Sopa de albondigas',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cdf2845c-a8bb-42db-8ed6-97f5eadc68b8',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Sopa de pollo',
    NULL,
    6.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bcbd81d3-b06c-4573-8048-758501c8e3ee',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Strawberry Aqua Fresca',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f8cc79e6-4c90-4d77-84fe-ff294b3d14b4',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Super nachos with carne asada',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7d31130e-b374-4116-864d-504d2bb5fa20',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Tacos de la casa (3)',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ecb4f726-6495-476d-8780-f2a272eb4a9b',
    'f2e89c09-3680-49fb-85ea-f86ac58eaaca',
    'Vegetarian platter',
    NULL,
    4.55,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 13: Curry Up
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'curryup',
    'Curry Up',
    'Indian food with a modern twist. We use all-natural ingredients and the finest spices to delight and tempt your palate.',
    'indian',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '47981d44-d94c-4247-8f5d-ab1bb0eacf69',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Aloo Gobi',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '923c0df3-9caa-4c41-8ec5-c6b74836957e',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Basmati rice',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'acb273f9-a15e-4163-8e89-8283a539d150',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Butter Chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '96e21276-b91c-4d0e-89c9-2b805b1c3997',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Chicken Korma',
    NULL,
    7.55,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5307dd07-01d8-4222-831f-6f255216cca5',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Chicken Tikka Masala',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4cd7900f-caad-4320-8f8f-6e9fecd4c7b8',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Gulab Jamun',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fc65dd80-b215-4bef-8737-24205cf4923b',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Kheer',
    NULL,
    4.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c376ec78-8952-4760-8964-53b5878f1fa2',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Lamb Asparagus',
    NULL,
    9.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4e112738-e408-41a5-8024-ac87751f0f65',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Lamb Vindaloo',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7530c333-dc86-4b2b-84bc-e80d368d19b6',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Mix Grill Bombay',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '91a632de-da14-472f-8a8a-1fa05ff2fb78',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Mulligatawny soup',
    NULL,
    5.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e6d827a9-6691-44a4-8f9c-53f554288b75',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Murgh Chicken',
    NULL,
    3.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4a97000a-b90b-48ea-8e9e-97326d8f8367',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Naan stuffed with spinach and lamb',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '28620a5a-dc12-43aa-8f17-6eaaab8ff8f1',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Plain naan',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'afbfdf5b-27c1-437f-8ebf-cd94c45f5e72',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Rogan Josh',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c57598a3-2783-432f-8990-2f9c035317db',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Saag Paneer',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5d44787a-276a-48e9-82b5-ee078a59c6e3',
    '269b6db3-6a99-438c-8646-58d98bf7f22c',
    'Tandoori Chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 14: Carthage
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'carthage',
    'Carthage',
    'Wholesome food and all the rich flavor of Africa. Try our famous lentil soup.',
    'african',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6fe3504c-be4e-49d4-898c-fbe604b0e04b',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Dibi Lamb',
    NULL,
    8.25,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ae00c627-cf2a-4ca5-87e9-896becbbb94c',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Doro Wat',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b2cc2034-5370-437c-89d3-b6706a9b2582',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Grilled Chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a0fcbefd-7d87-42c9-8bc6-5d5278fbbe96',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Grilled Fish',
    NULL,
    6.95,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f03f8383-ab51-4c29-8bb0-c3a0f25c20d2',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Grilled Plantains in Spicy Peanut Sauce',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '090effc1-f304-4be9-8aa5-26741b22a61d',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Lamb Mafe (Peanut Butter Stew)',
    NULL,
    8.75,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5e566a21-c304-4f9b-8af7-1c7a3c0c28dc',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Meat Pie',
    NULL,
    6,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7de337a2-a0f4-4d11-8218-aa326eccf671',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Mechoui with Plantains',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4a2a8095-b9af-4dec-8a74-8ae140861279',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Pepper Soup',
    NULL,
    9.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd205ac45-246c-4f5d-8838-848097fac25b',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Piri-Piri Shrimp',
    NULL,
    11.45,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b8070545-a469-407f-867d-e96439f6d718',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Suppa Kandja',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e14a8624-30f2-4249-8288-33a8f940274e',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Thiou Boulette',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4ef606c5-0ddf-4503-8359-226560098074',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Thiou Curry with Chicken',
    NULL,
    7.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4b53368f-bf45-40fd-8f0a-d61d25653093',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Thu Okra',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '43916302-1ebf-4f3d-88c0-687e6a8372f4',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Yassa Chicken',
    NULL,
    8.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bd062c48-00fa-46b5-85c7-d0df9b9464ea',
    'ba2e5f12-8525-4306-8e92-86dc4234c7de',
    'Yassa Lamb',
    NULL,
    8.25,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 15: Burgerama
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'burgerama',
    'Burgerama',
    'Grade A beef, freshly ground every day, hand-cut fries, and home-made milkshakes. We make the best burgers in town. ',
    'american',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f12fe1c4-f745-4345-8fcb-df168b18c250',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Buffalo wings',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '151f0fec-0b62-481f-8ce6-944fefb430db',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'California-style baked Tilapia with rice',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a79928ec-a0d3-4345-8dba-d1c88cb819a5',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Cheeseburger and fries',
    NULL,
    4.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fbfab1a0-5026-4f85-81e9-73fdb644d122',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Cherry pie a la mode',
    NULL,
    4.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e97c04b2-3e4c-4e22-83e7-d91b5f0dff0b',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Chocolate milkshake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e5b72fed-6321-43ae-8412-f4fcaa74ef13',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Cobb salad',
    NULL,
    4.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '37941891-4ca4-4477-83f8-b079d99c9ce5',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Famous BLT on a kaiser roll with fries',
    NULL,
    4.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '18c5000e-6d85-477c-8429-88d684b06254',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Firehouse chili',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4374fe78-2a1f-4830-8fa5-5e40eb16010f',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Goat cheese and eggplant wrap (vegetarian)',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fc24c478-ac29-4bc2-8227-23f548b5392c',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Greek salad',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '602855d3-8309-4c3d-8546-87ccea95e453',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Grilled chicken sandwich',
    NULL,
    4.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '370cd0ce-cb33-4117-8159-c65b34d3afa7',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Grilled sausage on a bun',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fc6cef2f-b6c0-4d18-8fc4-35b6d532583d',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Housemade pot roast with seasonal vegetable',
    NULL,
    16.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fe71605e-406d-4fd2-89b2-33910c54fa8a',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Roast beef dip',
    NULL,
    11.45,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c62100e8-b77b-4332-811c-f79bea5ea1f4',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Roast chicken and mashed potatoes',
    NULL,
    7.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9aefa2fe-a28f-44f0-8065-74a0b2322f5f',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Soup of the day',
    NULL,
    8.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '46e1e7c0-cf47-45a5-8223-34d5e920a39b',
    'cd97c9b2-3552-48b1-823f-6a1db5c459bf',
    'Spaghetti and meatballs',
    NULL,
    11.45,
    'Pasta',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 16: Three Little Pigs
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'littlepigs',
    'Three Little Pigs',
    'Genuine East Texas barbecue. Accept no substitutes! ',
    'barbecue',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ae82e83c-246f-4833-831c-3a4ea129844e',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'BBQ chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e9d1cd87-1620-4dd0-8f16-0f83a9de5c77',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Beef ribs (full)',
    NULL,
    9.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '63dcb618-f954-46be-8c7f-d3bbe3083980',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Beef ribs (delux)',
    NULL,
    10.45,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '74676878-83cf-4a3d-8ed1-90542c1161c5',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Beef ribs (half)',
    NULL,
    6.45,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '899b025d-2cc2-4036-88f5-e0355f578312',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Beer',
    NULL,
    7.55,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd5a6e8b8-52c7-41d2-8b75-ec159dea8032',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Coleslaw',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '895a5d33-1b66-48c4-89a9-9f3357215075',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Collards',
    NULL,
    9.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '471e733e-37e0-4812-8fb4-959e1fb2da39',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Cornbread',
    NULL,
    11.45,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '66784682-164a-4d65-8d35-ede5f1af5303',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Devilled eggs',
    NULL,
    4,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '94aee0cc-944d-48dc-8f98-263822c9fd43',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'German chocolate cake',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'df89f540-7884-46e4-82a1-21fa515b6440',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Housemade chips',
    NULL,
    4,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '62048840-d334-4266-80f8-62a00d096f53',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Hushpuppies',
    NULL,
    3.25,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a3aef990-b74d-472d-821f-d6b4badd89f8',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Mac and cheese',
    NULL,
    6,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cbc2d8fe-ef02-4134-8c78-f8d2da3d877f',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Pork ribs (half)',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4417a40d-e6b9-420f-8b9d-44b8a1559518',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Potato salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'af0bfda9-6625-4e78-8e3d-0f67c4f3cc7e',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Pulled pork sandwich on a soft roll',
    NULL,
    4.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e1c21940-8b20-4d53-803f-51460bb7893b',
    '4be2b6c4-342d-40e0-8929-f01e162c5d37',
    'Riblets',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 17: Little Prague
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'littleprague',
    'Little Prague',
    'We''re famous for our housemade sausage and desserts. Come taste real European cooking.',
    'czech/slovak',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '961bd17b-410c-4d53-86a6-4e089118c24f',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Apple strudel',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cfbc7d9d-ae2a-4389-8b59-fdc7f0ded8ae',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Apricot dumpling with yogurt topping ',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '66aa75a7-5c09-48f1-877f-2a363d8614a8',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Balkánský Salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd5d2e9dd-b609-4a15-860c-2a374ad7c1b1',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Beef goulash',
    NULL,
    8.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '451ead22-7da0-41f4-8e6f-6e656a26007c',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Chicken breast fillet schnitzel ',
    NULL,
    10.45,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'da18174b-4533-428e-8aa9-a72a33b0bbf9',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Cucumber Salad',
    NULL,
    7.55,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '534b7681-77fb-4a1a-8afa-9f2df2a6d1ce',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Dumplings',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e2746f45-5005-46e4-8637-17a8e9e12b0e',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Fried goose liver with onion and bread',
    NULL,
    7.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'df05d20b-871d-4ed1-8830-da955cdd8e45',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Halusky with sauerkraut and belly bacon ',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6264eb27-9cc1-4885-8db9-5bd2aa3ebdb4',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Lentil soup',
    NULL,
    4.5,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'eb8e6f8d-25eb-44a5-868a-bcc08a747ca2',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Pickles with cabbage and cheddar',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '411cd33c-2ec5-4434-8e77-71f3b9acaead',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Pork schnitzel',
    NULL,
    3.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b5f85116-237c-48e4-8f60-27512c8ac454',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Potato pancake with bacon',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3d132d9d-d0ac-4e9d-87cf-4f18259bfc93',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Potato Salad',
    NULL,
    4.55,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '38ca020c-865e-4f0a-8a78-10d00b424c07',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Segedínský gulash and dumplings',
    NULL,
    6.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9c872b30-6d47-45d9-88e2-b007e9cfab9e',
    'fc207fd9-a620-469c-8667-2f0a143d8695',
    'Sour cabbage soup',
    NULL,
    10.45,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 18: Kohl Haus
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'kohlhaus',
    'Kohl Haus',
    'East German specialties, in a family-friendly setting. Come warm up with our delicious soups.',
    'german',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6175b131-ebf3-4773-8bd2-ef45e362827f',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Bockwurst Würstchen',
    NULL,
    4.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '67318439-f5dd-443f-88bc-623216f723b9',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Bratwurst mit Brötchen und Sauerkraut',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '44705ec9-9d8d-4f79-89be-48f2e0abb46e',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Currywurst mit Brötchen',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fbc4354f-e0ff-417b-8067-adae6b6d4782',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Das Hausmannskost',
    NULL,
    11.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'dc99591b-f9e1-4fbb-8afb-9d1c1aaa98f4',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Fleishkas mit Kartoffelsalat',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2080314b-f9c7-441c-8b1c-3cf257512cca',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Frankfurter Würstchen',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fb606bd4-fc13-45f5-8973-b0161c7d11c7',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Französische Zwiebelsuppe mit Käse',
    NULL,
    10.45,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '58d7f67e-5e87-4afb-86d2-ff6f3acde728',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Frikadelle mit Brötchen',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '02a415d9-2e0b-4999-8ef5-29ad676220cb',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Gebackener Camenbert',
    NULL,
    7.55,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd69b1a87-32da-4756-8638-983247f913fd',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Gemischter Salat',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'dab91b00-3203-4286-8c51-b5038047b140',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Haus Salatteller',
    NULL,
    11.45,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4dfe746a-de56-4905-8aa3-a3b2edd8b352',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Jaegerschnitzel',
    NULL,
    9.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd172aefb-9491-421f-85d8-04faf7faba52',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Kaesepaetzle',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2c12bbc9-3611-459a-8cf8-ced9d614f3fd',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Kartoffel Reibekuchen mit Apfelmus',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3b7c8a24-719e-4e89-8004-6e78c7a62927',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Maultaschen mit Käse',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3bd56c07-b8ef-424a-8079-45585e19a43c',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Sauerbraten',
    NULL,
    10.45,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f475913a-5145-471b-8188-27fcd73a18d3',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Ungarische Gulaschsuppe mit Brötchen',
    NULL,
    3.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8ed48374-d197-4706-8c8e-4d66f8d47cc7',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Wienerschnitzel',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2d95986f-6987-40fe-82bb-e86db81268cc',
    'd01b78ed-ac40-4408-88c5-cd8cb2b8e4bb',
    'Wurstsalad mit Bauernbrot',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 19: Dragon's Tail
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'dragon',
    'Dragon''s Tail',
    'Take-out or dine-in Chinese food. Open late. Delivery available',
    'chinese',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '91a0ab0d-b67f-4454-8270-5e49ec6188b0',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Almond cookie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1157cb03-1db1-4e07-8d86-bafdf6d1949d',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Chicken and broccoli',
    NULL,
    9.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4321950b-5b0b-4b97-8ca2-945d52bca3e9',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Chow mein',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c2ca0789-ccfd-42f0-8c42-8f1fc33e1436',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Egg rolls (4)',
    NULL,
    3.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b9e52ed5-6d69-4c09-8045-710aa3028b2a',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'General Tao''s chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a0e70cde-e107-4c0b-8f79-36dc2f205df4',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Hot and Sour Soup',
    NULL,
    7.55,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c824a4fd-0d6e-4c10-8572-9883cd6bb64a',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Hunan dumplings',
    NULL,
    6.5,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9d44327b-f58a-406f-89aa-36b94987df3d',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Mongolian beef',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd3e8a1fe-2d7d-40d9-891e-91a4aefd30ca',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Pan-fried beef noodle',
    NULL,
    7.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '09127ece-6e31-47ca-876a-58f38e4ac591',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Pea shoots with garlic',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b3fb93f3-1cd1-448c-8a43-734b74e6e46e',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Potstickers (6)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8c6b8b1e-f088-43dc-8859-686c596d3d80',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Seafood hotpot',
    NULL,
    4.95,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7a84147b-bdd8-4458-889d-5e414bbcdb18',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Steamed rice',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '39642cfe-a7ce-4e97-8a7a-0a2d31d01221',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Sweet and sour pork',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c688130c-37f0-4747-89ce-2f3f9da77382',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Walnut prawns',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a61bd2ff-016f-4bde-8bdb-39808d164773',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Wonton Soup',
    NULL,
    6.25,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4285c173-ce58-4d41-8714-2587afce584a',
    'a9c43be9-48c5-4abd-86ef-2bacffb77cda',
    'Young Chow fried rice',
    NULL,
    6.45,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 20: Hit Me Baby One More Thai
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'babythai',
    'Hit Me Baby One More Thai',
    'Thai food with a youthful bar scene. Try our tropical inspired cocktails, or tuck into a plate of our famous pad thai.',
    'thai',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bd26d94c-95c0-45e1-8dbd-bbac0e7a4c0a',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Basil duck with rice',
    NULL,
    4.55,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8a4a5e80-1ea3-4eaa-8dfa-ada339ca477f',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Curry salmon',
    NULL,
    12.45,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5567c48c-9e60-412b-8d2a-f1d185a1b696',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Egg rolls (4)',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'dcc0d393-a748-433d-8558-a100a15ffad4',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Fried banana and ice cream',
    NULL,
    11.45,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4faebc8b-1796-4838-8d3a-826b8cb454df',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Green curry with chicken',
    NULL,
    3.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ba68527e-e7a5-47e6-84c9-a29dc991ac21',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Green curry with pork',
    NULL,
    4.55,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2e163e14-9451-440d-8dd1-3a7c30258743',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Hot tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '255333a6-ead6-4281-846f-42e719c26a2e',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Onion pancake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8157994e-ab5f-4874-8b61-c5e2f0e802ae',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Pad See Ew',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd8316136-3287-4862-88cb-b32b4d8305e0',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Pad Thai',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '356fc7b1-668c-48b1-8509-cd90e302dfd4',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Pumpkin curry',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ee4a02b4-2bea-4ff1-8875-65d483f0ebc3',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Red curry with chicken',
    NULL,
    8.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5b485015-d95b-4088-81de-80b20b5e1dca',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Red curry with pork',
    NULL,
    9.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7030f71f-b29a-4040-82ef-f7787ba18902',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Sticky rice with mango',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '20f72e01-4552-477e-8812-3750f0fb63b5',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Thai iced coffee',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6a68b2db-a1f9-4502-8c5f-ffca9bd06cb8',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Thai iced tea',
    NULL,
    3.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4645a9e4-1ec7-4d13-80bf-dfb20a313230',
    '9442d6d0-0ca1-469b-8ba4-6fc57cc91830',
    'Tofu salad rolls',
    NULL,
    10.45,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 21: The Whole Tamale
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'wholetamale',
    'The Whole Tamale',
    'The tamale and hot sauce experts. Tamale special changes daily.',
    'mexican',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3336c48e-4a38-4f5f-8c2b-2faaac18f6fb',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Beans and rice',
    NULL,
    7.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e2ca85de-c059-4747-8a0c-6004b1089882',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Beef burrito',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a9c25da9-9717-4a45-8b27-cec31c67b243',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Birria',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4d7579ed-178c-498c-85ba-fa97b66ddc06',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Chicken burrito',
    NULL,
    11.45,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8fd4d245-146e-4ce9-8bf1-e4f71bc37bca',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Chicken mole platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '48cec3a2-3e6d-4ae0-8e7f-770ea8609f17',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Chile relleno (meat)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '657af5d3-d772-4356-8e64-63c4629c59df',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Chile relleno (vegetarian)',
    NULL,
    3.95,
    'Vegetarian',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b381dfa8-d322-4a5a-8e3c-0a4e4f8aa490',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Chips and guacamole',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cbea5ffb-99cd-4a5a-8002-5d3633e9195d',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Enchiladas',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '468df7d0-d547-4a19-89d8-545f3530a6e6',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Flan',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '33001d60-a037-4d24-850b-de780e8b9dc3',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Jamaica Aqua Fresca',
    NULL,
    2.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5e62d71e-02f9-4048-8efa-c73fb51d4a36',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Pork al pastor platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '85373c7f-0d35-468a-82b9-d9211ff43c13',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Sopa de albondigas',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e958485c-8a18-440a-8650-e9b999b22d74',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Sopa de pollo',
    NULL,
    6.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5694a21e-66a2-4adb-86ff-708aa1eafd31',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Strawberry Aqua Fresca',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '094c16fb-80a3-4e03-8a47-109083c761cd',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Super nachos with carne asada',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3a135df0-037b-4b29-8a0a-efbb5d5121cf',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Tacos de la casa (3)',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9957077b-99c0-46e7-8224-adbfe4c31d1a',
    '68767677-43b2-4d28-85cb-f08588c05b9e',
    'Vegetarian platter',
    NULL,
    4.55,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 22: Birmingham Bhangra
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'bhangra',
    'Birmingham Bhangra',
    'Curry with a metropolitan twist. Daily specials. Dine-in or takeaway, you choose.',
    'indian',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '016f4323-b357-469e-8a79-226c34524517',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Aloo Gobi',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c806f10c-f39b-411a-8168-6b9010d696a2',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Basmati rice',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '20d2133f-c964-40dd-8326-a62844845a5e',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Butter Chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '56b57eb8-3e97-4602-89bc-73860a60ab27',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Chicken Korma',
    NULL,
    7.55,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '88203d72-2992-44f8-8703-b0f2f17e84d8',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Chicken Tikka Masala',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd16602ff-b5cf-4416-8c67-c48507768953',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Gulab Jamun',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'eacf4077-9635-43d0-8c4c-bb7b9501eb92',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Kheer',
    NULL,
    4.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9db46fa0-3c06-438b-8b80-7ffc9682a303',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Lamb Asparagus',
    NULL,
    9.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0c1d644a-7f99-4354-847b-02b9710fc827',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Lamb Vindaloo',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9bca0afd-0ecf-406f-8699-23cd2241f45f',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Mix Grill Bombay',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '592b6022-cb58-41c9-8c6d-f938347fc477',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Mulligatawny soup',
    NULL,
    5.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a5600b8c-8654-4b5a-8fe9-068415540b91',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Murgh Chicken',
    NULL,
    3.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e1bf8358-b8eb-4d92-8b58-b9747610ece6',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Naan stuffed with spinach and lamb',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd8237161-e86e-4d0d-8401-e9f37244eda5',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Plain naan',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9554e20a-df85-40ac-87d1-f8428ef9cbbf',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Rogan Josh',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '61256ef6-0205-4588-85cf-dd1eeab8ecb6',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Saag Paneer',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c5438df8-70ca-47a5-8223-78c5c8b32217',
    'e82f8b81-abff-4a53-833a-617c33fafb13',
    'Tandoori Chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 23: Taqueria
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'taqueria',
    'Taqueria',
    'Taqueria y panaderia. Birria served on weekends.',
    'mexican',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '337e1a4b-bf35-40f2-842c-1f532bb6b980',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Beans and rice',
    NULL,
    7.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '12aaa469-7434-4c4e-8786-3c43bb70858a',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Beef burrito',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ec587c13-b5f2-45e3-8e24-a3f57b166183',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Birria',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '010df8c0-e241-4b62-80c9-d151504a568e',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Chicken burrito',
    NULL,
    11.45,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '792103cb-1a6c-46bb-8a6a-58b0c40ee126',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Chicken mole platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '92265212-e105-4189-89bd-ab4c2215c5b6',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Chile relleno (meat)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7a65eea2-710a-4f2f-8415-6281ed6d2743',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Chile relleno (vegetarian)',
    NULL,
    3.95,
    'Vegetarian',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '80162a74-a1f5-4e06-82f3-bcb329e7780f',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Chips and guacamole',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '942676b4-56e2-4007-85ce-ace73ba5cd26',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Enchiladas',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f7041652-efc0-4b8a-8b64-04801c9a2335',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Flan',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c188d6e4-d546-4d30-8476-dc9e0d54fc6f',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Jamaica Aqua Fresca',
    NULL,
    2.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ede09b4b-c6f8-4f9f-8bb6-d300bda8f1a3',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Pork al pastor platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b092f895-dbc7-4bb7-8075-36e6e8a6a47e',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Sopa de albondigas',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '63f477ca-a61f-43ce-89a5-780092175b10',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Sopa de pollo',
    NULL,
    6.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a2cc4a5e-aed6-4fce-8e50-cd3c7e9b3556',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Strawberry Aqua Fresca',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bf96e92d-0a8d-440d-8225-0b1c7fff0a86',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Super nachos with carne asada',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '216dc064-6350-4d78-815d-bc726ba57c3e',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Tacos de la casa (3)',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0e7d9c6d-78f8-4773-8404-8866f4d26bff',
    '6e0cb5b9-53b6-4fe9-8940-bf5a29865ca2',
    'Vegetarian platter',
    NULL,
    4.55,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 24: Pedro's
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'pedros',
    'Pedro''s',
    'Pedro''s has been an Alameda staple for thirty years. Our list of fine tequilas and slow-cooked carnitas will make you a regular.',
    'mexican',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cd093b2f-260a-4b62-8f0e-155262eb7585',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Beans and rice',
    NULL,
    7.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '856ceb92-9687-4029-8586-afb042e73645',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Beef burrito',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '23ce8f57-1f9b-4d4d-8c2e-593d324c5921',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Birria',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '345fe97b-cd07-4069-8094-d603645b8b09',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Chicken burrito',
    NULL,
    11.45,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fd81943b-fad3-4eb3-84ae-195e394a5a19',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Chicken mole platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3f0befc6-b14e-4201-8c43-e607f0ae23e4',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Chile relleno (meat)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '669307cb-4332-4181-841a-c483efea2224',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Chile relleno (vegetarian)',
    NULL,
    3.95,
    'Vegetarian',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '097b20cb-6aae-49d9-8144-d06fd7d77b63',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Chips and guacamole',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8988f99b-03a8-4724-8ea3-ad0154c01923',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Enchiladas',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'eb802256-bf08-42e2-84e8-1316acb8a012',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Flan',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0e10cacb-7b31-4665-83ea-86360f486a2e',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Jamaica Aqua Fresca',
    NULL,
    2.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '20097b38-663d-4e1c-8ba4-cad06dbf5462',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Pork al pastor platter',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '87d8e206-1914-4c59-8566-e83c980b8e23',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Sopa de albondigas',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cf8d2019-f592-4ac7-8a67-cbabdf62b8fa',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Sopa de pollo',
    NULL,
    6.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '215a76b4-e302-48b7-8c7b-2fc3c4e5ea35',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Strawberry Aqua Fresca',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '58260de9-815e-4df8-8d0b-3693cbe35f7d',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Super nachos with carne asada',
    NULL,
    5.95,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6eb1daeb-5843-4034-8913-c6c4c9229950',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Tacos de la casa (3)',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2bac6fa8-5384-47b0-8a3b-751f8231e6f9',
    'ceff8a27-cfac-43e7-8a74-dea15acc027a',
    'Vegetarian platter',
    NULL,
    4.55,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 25: Super Wonton Express
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'superwonton',
    'Super Wonton Express',
    'Soups, stir-fries, and more. We cook fast.',
    'chinese',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e2b79500-793c-44e8-8c03-18edcfd7ec4a',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Almond cookie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '93b39cd0-7329-46b2-88df-a4fbc6a3892c',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Chicken and broccoli',
    NULL,
    9.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a2a279f7-841a-4f43-8f1e-29117234b499',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Chow mein',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b1838f28-7689-44ab-8be4-84ee6ea58f8c',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Egg rolls (4)',
    NULL,
    3.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4aa94b90-3693-4c34-84d9-d7f2c25f6d41',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'General Tao''s chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd4d3cf2d-768d-44d0-8cd7-f613b5de4069',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Hot and Sour Soup',
    NULL,
    7.55,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '56b0a404-674c-4bf4-8d34-9c902b6cce19',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Hunan dumplings',
    NULL,
    6.5,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3f3da7cc-a962-433a-8277-d9b05631b326',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Mongolian beef',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c71126df-d1b2-45b1-8e55-786ff5e76b81',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Pan-fried beef noodle',
    NULL,
    7.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c96c6373-001c-470b-8a0c-98932921ae23',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Pea shoots with garlic',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2d8f8ab2-a650-4702-8a13-89c26273d23c',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Potstickers (6)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '40a74061-01d0-4a44-8672-aeedd75a6d7c',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Seafood hotpot',
    NULL,
    4.95,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '648ff5a4-ac25-40f5-83d3-080533b6ef8c',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Steamed rice',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1647c440-0f1c-4894-877f-ecf0643d6f19',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Sweet and sour pork',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bc843eff-3cf9-4ae5-844d-c2c8ab086a76',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Walnut prawns',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '697dab54-e71d-4960-833f-6d6689fd9dac',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Wonton Soup',
    NULL,
    6.25,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7fa87448-86f6-4e6e-835e-882e4c1968c6',
    'f31eff79-7dbb-4156-8e32-712cadedce7f',
    'Young Chow fried rice',
    NULL,
    6.45,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 26: Naan Sequitur
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'naansequitur',
    'Naan Sequitur',
    'Naan and tandoori specialties, from our clay oven. ',
    'indian',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '178e23b1-49d6-4e6f-8cca-66a858b3c7d2',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Aloo Gobi',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '753dd144-f876-4142-8726-0699c29dd256',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Basmati rice',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e4d3d9d8-dd56-44f8-8f24-28edca551a78',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Butter Chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd643cd6e-b5db-4028-8238-7c13a9c65f65',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Chicken Korma',
    NULL,
    7.55,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f56287c9-01f5-4839-876e-0053b30d2984',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Chicken Tikka Masala',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7097a0c5-999b-4720-80c8-859aff1bbeda',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Gulab Jamun',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bc0129b7-4be8-4727-8021-9eecbed27e0b',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Kheer',
    NULL,
    4.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '50db9534-8294-4593-882a-a438b158b040',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Lamb Asparagus',
    NULL,
    9.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5ee0abdf-15a7-4a92-816b-b9273e67c495',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Lamb Vindaloo',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c0baab7a-67d9-44d3-83ae-ae8759549e78',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Mix Grill Bombay',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '184a7b7c-3cf2-4875-800c-6c279c42344a',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Mulligatawny soup',
    NULL,
    5.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '83a32563-8be4-4da5-8292-b0957f61b300',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Murgh Chicken',
    NULL,
    3.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5bd03d3f-d992-4e39-8d79-3369de8d4d4a',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Naan stuffed with spinach and lamb',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7c738fb6-5abe-476c-8397-b1d3c67965a7',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Plain naan',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '20c514a7-36e6-435c-8f07-2d8fdfa63955',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Rogan Josh',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '48fe295e-659f-4ac2-89db-cff66a00cf95',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Saag Paneer',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '21586c71-1378-4ffa-8688-6148d3460892',
    '859a5823-c25d-4c9d-8151-df0829dc2731',
    'Tandoori Chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 27: Sakura
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'sakura',
    'Sakura',
    'Sushi specials daily. We serve fast, friendly, fresh Japanese cuisine.',
    'japanese',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd3461d69-6e31-4848-8876-cfbdb996b1b1',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'California roll',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7c572316-297e-4b44-828e-bdcd04a1a948',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Chicken teriyaki',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2944f05c-af71-4608-8870-9b9f5b1036af',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Edamame',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '699fc568-e57c-4b03-81e6-b6d088a66579',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Green tea ice cream',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7cb53e68-1e1e-44fc-87b3-0ac20647eb0b',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Kitsune Udon',
    NULL,
    9.5,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ddd26129-bafd-4c87-86fe-4deda2889d0a',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Miso soup',
    NULL,
    5.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0fbf6b28-bfa7-45b5-8304-09f4372945e1',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Pork Katsu',
    NULL,
    5.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '195d2b15-a8bf-4b36-82f2-7dc33e9ecc85',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Salmon teriyaki',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2e12e27c-f261-41ce-82bf-44b615338b9c',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Sashimi combo',
    NULL,
    6.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b35d1e02-847e-4a30-8142-438a3c0fb4e1',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Spicy Yellowtail roll',
    NULL,
    7.55,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8c735787-c2d3-49be-85e3-aac543a0552b',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Sushi combo',
    NULL,
    4.55,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '571bc86d-5c52-4ae1-8f57-11f8deddc2ac',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Teppa Maki',
    NULL,
    5.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c58fc31b-a243-43dc-8823-1312a85e0c01',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Unagi Don',
    NULL,
    7.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fe04984f-40b3-447e-853f-2e0b78d0e7b7',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Vegetable tempura',
    NULL,
    3.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6cc1ddfa-b4be-4f0e-865d-a6bb62153508',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Vegetarian sushi plate',
    NULL,
    6.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0ac2d420-2496-45b8-860a-3d8c57024655',
    'd41dc638-5e80-4fd6-86fe-049ecd56a3c1',
    'Wakame salad',
    NULL,
    4.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 28: Shandong Lu
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'shandong',
    'Shandong Lu',
    'Szechuan and Mandarin specialities with a fine dining ambiance. Our hot and sour soup is the best in town.',
    'chinese',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6d756798-713f-4b2c-8eec-4ed0e49a4452',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Almond cookie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '65514200-608c-414c-8797-0f76090f4e41',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Chicken and broccoli',
    NULL,
    9.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6d8f35bb-f7a9-4946-8470-82d45a51037d',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Chow mein',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '419efd17-80e6-4d24-8b80-f55309dcd9a1',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Egg rolls (4)',
    NULL,
    3.95,
    'Sushi & Japanese',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2fe9f137-84f9-491a-80fb-58b6174e8a65',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'General Tao''s chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3f6e2b11-88fe-4761-8ce3-5747b53efc56',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Hot and Sour Soup',
    NULL,
    7.55,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6784692a-c953-4661-8984-0052b4ca5bbe',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Hunan dumplings',
    NULL,
    6.5,
    'Appetizers',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f1226db9-4528-410e-877b-ca16816a749e',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Mongolian beef',
    NULL,
    6.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '544efcf7-630d-428f-84f2-18e48835fb1a',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Pan-fried beef noodle',
    NULL,
    7.95,
    'Beef',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f2ff5fcf-0433-438b-8822-bd96cffca5a0',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Pea shoots with garlic',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '19a0ecc6-6843-4a40-85f6-b9ee5833f7e6',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Potstickers (6)',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '31d9d7a2-1a27-44c2-85f8-266fd6a3c752',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Seafood hotpot',
    NULL,
    4.95,
    'Seafood',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2831993e-43f3-4b2e-8332-ecabd351732e',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Steamed rice',
    NULL,
    5.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0f9bddf9-a35a-425f-8a0a-ca64b57509b9',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Sweet and sour pork',
    NULL,
    6.95,
    'Pork',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '331da1cf-1afb-4304-8341-04185900e3cd',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Walnut prawns',
    NULL,
    4.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3f5f50e4-cf0a-41d1-827c-dd702000c4d1',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Wonton Soup',
    NULL,
    6.25,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4b921322-c3de-4e57-8d2e-ec910b799c2b',
    'c2f2d91c-2a31-454e-893f-e038488e1a41',
    'Young Chow fried rice',
    NULL,
    6.45,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 29: Curry Galore
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'currygalore',
    'Curry Galore',
    'Famous North Indian home cooking. Spicy or mild, as you like it. Delivery available.',
    'indian',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6ae0a450-24b6-4b46-84b5-220d082a08f8',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Aloo Gobi',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7335d5e2-f23a-473d-852d-1c44b727a75d',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Basmati rice',
    NULL,
    6.95,
    'Sides',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f3906ce0-a254-432c-81bd-48e7401c9267',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Butter Chicken',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c59d5f62-6c75-492d-806a-3fdefdef2046',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Chicken Korma',
    NULL,
    7.55,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '22ddfbc9-50e2-4ac3-8e7b-55abdb320a10',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Chicken Tikka Masala',
    NULL,
    5.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '31630c0d-bda2-4f4e-8a16-0ad3d8f671ae',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Gulab Jamun',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3b656f97-e04e-4a7d-860f-71ede4b832f3',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Kheer',
    NULL,
    4.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b1758d9a-a6e7-4d94-8fe4-3441d5e91e1c',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Lamb Asparagus',
    NULL,
    9.5,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '90e58a7a-c489-42c1-8c4c-a4dd26fa8218',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Lamb Vindaloo',
    NULL,
    7.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd241b855-aa32-4a38-88e1-06d87147dc08',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Mix Grill Bombay',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bba9c963-ac58-4479-844e-35ddecf56f44',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Mulligatawny soup',
    NULL,
    5.95,
    'Soups',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0c98c1ce-93b0-470c-8ae8-4e745225c745',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Murgh Chicken',
    NULL,
    3.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '27b5cec7-2777-4d92-8a7d-a47c3cad59f3',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Naan stuffed with spinach and lamb',
    NULL,
    4.55,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'da7b9ea2-398b-4e3c-807b-35134cffc8fc',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Plain naan',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f90cf892-f8f4-499d-8553-58d1b0821a14',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Rogan Josh',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0fabea07-1461-4ccd-8136-3dcac863be66',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Saag Paneer',
    NULL,
    5.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c741fd91-7584-42f0-83de-0dd63ae4001d',
    'f99cf7bc-e07d-4a83-8368-bb8fd4d74a45',
    'Tandoori Chicken',
    NULL,
    4.95,
    'Chicken',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 30: North by Northwest
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'north',
    'North by Northwest',
    'Great coffee and snacks. Free wifi. ',
    'cafe',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'db69a4c5-9cc3-4a97-87b7-5f4bea4c3361',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Apple pie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ab1a269d-da98-4adb-8037-fc71d4a57a27',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'B.L.T. and Avocado Sandwich',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '85da5168-b17b-43d6-8d9c-fd534652be14',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Caesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5b3a5c35-0edc-4e69-8ada-6a1077b5abdc',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Cappucino',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f1eda71e-93b3-46a7-8959-609708f60e42',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Cherry cheesecake',
    NULL,
    4.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3b941b26-67b2-47f7-8f2c-2c906353c2b2',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Chocolate chip cookie',
    NULL,
    4.55,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7a7a27db-9536-49ad-874a-ed39995816cd',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Cobb salad',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7fedb27e-9c53-44e1-8150-b4f67aaea553',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Drip coffee',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f5f77a22-69bc-4e95-8481-3a215b81ddb1',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Eggsalad Sandwich',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '09f4a509-5391-4c25-88ef-fe28792984ca',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Espresso',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2c804202-def3-43ec-8687-1e46e44f330a',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Greek salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2b341387-5396-4dac-80a4-2d5528cf7ab0',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Hot tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e91d6249-e690-4b55-8132-64e7b87105f6',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Iced tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e5e19621-2cd5-49ad-8115-a4aa20442277',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Latte',
    NULL,
    4,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7143566c-d97c-41e0-8be8-1a757e18df8d',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Mango and banana smoothie',
    NULL,
    3,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cacb9061-db70-43a7-8a86-7ec1083ed18d',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Orange juice',
    NULL,
    4.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f644cf41-3e5a-47e6-8a86-ca3ab4d83d79',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Quiche of the day',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd245abd5-37ea-4e4a-86d0-54482c62dc79',
    'dc365e79-d41c-4ae1-83c0-d969319ae621',
    'Turkey Sandwich',
    NULL,
    7.55,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 31: Full of Beans
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'beans',
    'Full of Beans',
    'We roast on premises to give you the best cup of coffee in town. ',
    'cafe',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3672920e-baa8-4b8a-8ea0-e7074998eda2',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Apple pie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2dce7b39-b184-474e-851e-62162ec209eb',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'B.L.T. and Avocado Sandwich',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f268b71e-be75-46b8-867e-8d83350e207e',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Caesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cbfb26c0-97bc-4b9a-8315-9e8d0b6bde33',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Cappucino',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c6da0396-7865-4521-8192-9c30b1fb837a',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Cherry cheesecake',
    NULL,
    4.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e553dbc6-e619-4c65-85eb-4845a31d4ed0',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Chocolate chip cookie',
    NULL,
    4.55,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8d7d002b-1452-4d65-8550-8ae8d78f839a',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Cobb salad',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ff823826-5d40-4498-864b-c2806110e512',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Drip coffee',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e6811973-17de-445d-879e-b969692deb64',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Eggsalad Sandwich',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'abf3ad19-0b70-4f54-8ce0-780d850be683',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Espresso',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e20ade41-3c8d-46dc-8de9-18749d6a9226',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Greek salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '58388018-fc96-48a9-8762-422bebed5210',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Hot tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '44e84f84-ab99-4a36-818d-fd81e3aa38b2',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Iced tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c908146b-93c7-4ab3-8ce2-5291331fcc6b',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Latte',
    NULL,
    4,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '87d03426-d31d-4f96-8357-c695a5905095',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Mango and banana smoothie',
    NULL,
    3,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0ec84802-d111-4ae6-82f5-27af4c45d5d3',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Orange juice',
    NULL,
    4.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0a5385c2-dd8b-47de-8412-d1339718a5f1',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Quiche of the day',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '918f39b9-7119-45a2-86eb-ddbce7247075',
    '6eb228fb-5b59-4b49-845a-48bdd9e5f0ed',
    'Turkey Sandwich',
    NULL,
    7.55,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 32: Tropical Jeeve's Cafe
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'jeeves',
    'Tropical Jeeve''s Cafe',
    'Hawaiian style coffee, fresh juices, and tropical fruit smoothies.',
    'cafe',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0e3d0b63-ca2f-41db-8944-a84fb559e91d',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Apple pie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '349620d2-43bc-4aa6-8dcc-dca7dadc9d77',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'B.L.T. and Avocado Sandwich',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1e21ce48-250d-45f6-8332-e58bc76358ab',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Caesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '25c59d69-a9f7-4adf-8375-2ce3925de34c',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Cappucino',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fd518843-8cb0-4a4a-810c-09119b3e4a7b',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Cherry cheesecake',
    NULL,
    4.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '17e9f4ff-d44b-463e-8386-c5460add99d4',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Chocolate chip cookie',
    NULL,
    4.55,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0e258288-b305-4cae-8c3b-99b6d55745b6',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Cobb salad',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b7ce28c6-e282-412f-8b94-4a8665dc0866',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Drip coffee',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9117c0c5-2c28-477a-8157-46c327e63a25',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Eggsalad Sandwich',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a22f15ba-5566-4879-8ca0-166e9604fb58',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Espresso',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '23e700bf-92a3-4ddb-8bc0-c754c6d75794',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Greek salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '86338e0d-2ecd-4ec6-8be9-40ad6e87dc27',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Hot tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4141232f-a5e0-40b4-8deb-cccdcc3caa15',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Iced tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd2be58c5-07b2-42e2-8a61-09df595a4231',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Latte',
    NULL,
    4,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '88c22bde-37a0-41d3-88d4-d4a2efc33c17',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Mango and banana smoothie',
    NULL,
    3,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0c2dcd3a-21c2-4331-878d-aced7a1307e9',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Orange juice',
    NULL,
    4.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2aee36d7-192c-469e-8e40-46a4f3870e3c',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Quiche of the day',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '86cbe82a-27eb-4502-861e-1235231e7566',
    '035adff2-ca08-480a-86ae-d2c1f631d1b2',
    'Turkey Sandwich',
    NULL,
    7.55,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 33: Zardoz Cafe
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'zardoz',
    'Zardoz Cafe',
    'Coffee bar and sci-fi bookshop. Come in for an espresso or a slice of our famous pie.',
    'cafe',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e67d22ac-3815-4843-85b0-1de210fca406',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Apple pie',
    NULL,
    5.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b6a3ba23-d1ea-4443-8045-cc54da3b9d6a',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'B.L.T. and Avocado Sandwich',
    NULL,
    5.95,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f9fb0188-f92b-4c22-88ec-808f0dbe71ea',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Caesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3a79ed35-f104-415c-867c-b97f60f361d1',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Cappucino',
    NULL,
    3.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3c3c63cd-b0a1-4cd7-8268-f5764dfaa334',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Cherry cheesecake',
    NULL,
    4.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '64641fe7-6bfe-4ac2-8835-f31d676eb276',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Chocolate chip cookie',
    NULL,
    4.55,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '35f1c98b-8bc0-4c62-8f37-c999558d6ed0',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Cobb salad',
    NULL,
    6.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c649aa73-d784-4a7a-86cb-f2e711bf185d',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Drip coffee',
    NULL,
    5.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '87f8d02b-f85c-4ef2-8bc9-3646cd0ad994',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Eggsalad Sandwich',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '37958454-0419-4897-8329-d54aa6358598',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Espresso',
    NULL,
    6.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '91851b9d-b4aa-4cf6-88d2-17b1023a1b69',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Greek salad',
    NULL,
    3.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '23235771-73a7-4f6f-8c16-45524f131ec4',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Hot tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0c3ae171-9556-492a-8533-839623f4ca3c',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Iced tea',
    NULL,
    2.5,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '26b0cc7a-4474-418e-8e46-1c9afa7f50bc',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Latte',
    NULL,
    4,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5f46dc81-b98b-4163-837c-8ec3f09a9451',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Mango and banana smoothie',
    NULL,
    3,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '8efca2e1-708a-48d8-88f0-288faf7e5987',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Orange juice',
    NULL,
    4.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6e017f82-4d5d-44c1-8724-0b6ec8fed664',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Quiche of the day',
    NULL,
    6.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ba31ee24-9928-4884-84f2-5d660229c5e7',
    '4bdb545f-6b04-4652-8589-2794bd5ac447',
    'Turkey Sandwich',
    NULL,
    7.55,
    'Burgers & Sandwiches',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 34: Angular Pizza
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'angular',
    'Angular Pizza',
    'Home of the superheroic pizza! ',
    'pizza',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7b647e5e-c95c-4530-89f0-cf0e62ad6e8d',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Cesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c672ad90-4c74-433e-863b-16248d13562a',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Cheesecake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f5c76ba9-72da-4f37-8d0f-db17120ff8fe',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Chicago-style deep dish chicken and spinach',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7930a7ea-4d9f-452a-8cd5-2e4306669c9f',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Chicago-style deep dish pepperoni and cheese',
    NULL,
    7.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ace8aa17-da8a-4baa-8fa2-574bb5c71ee7',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Chicago-style deep dish vegetarian',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '98cb1eb3-bf8c-4c5e-87c9-93e10fd60cd1',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Chicago-style meat lover''s',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7beefbb9-aec1-4a42-8242-456627f235ba',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Chocolate cake',
    NULL,
    3.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c6ad5281-d627-4475-8f2a-6d211b6b14a4',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Coffee',
    NULL,
    7.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '97074773-3424-401a-8fbe-7ac3710f68d8',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Greek salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3eef8ee4-d05a-40bb-8700-5ff3e3e56603',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Pizza of the day (slice)',
    NULL,
    7.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bd2561a0-6c85-41e2-800f-c3c9f03c28a3',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Thin crust anchovy and garlic and chili pepper',
    NULL,
    5.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b3508d11-e825-4e9f-8190-313d7dafdfd2',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Thin crust broccoli, chicken, and mozarella',
    NULL,
    3.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '65615f7a-2ff1-49ec-8ad4-ac29d8b60388',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Thin crust margherita',
    NULL,
    4.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f4da9eb8-35ed-4110-873b-d3fc3d611aba',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Thin crust pepperoni',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6f37834c-8e41-45a3-8766-e6a275d74e2d',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Thin crust quattro stagione',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cbb6995d-22a6-41a3-8a1a-d5849dbb7356',
    'a39f899a-db17-42b4-8435-d9759f925d89',
    'Thin crust sausage and guanciale bacon',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 35: Flavia
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '33970121-fb6e-414f-8706-4788ee407375',
    'flavia',
    'Flavia',
    'Roman-style pizza -- square, the way the gods intended.',
    'pizza',
    5,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6c59a813-fa90-4995-8786-d6b00639c716',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Cesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3746b4b7-3f5a-4ded-8d9e-d35efc6342c7',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Cheesecake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3fd18f87-cc28-4799-8e70-f727f990632c',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Chicago-style deep dish chicken and spinach',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '78c18280-d4c7-4cb8-8694-a3da1e8df18b',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Chicago-style deep dish pepperoni and cheese',
    NULL,
    7.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '92c44212-c798-4d9a-8d93-d4a3e3916c1c',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Chicago-style deep dish vegetarian',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c8aaccc8-840c-4dab-89ce-a50a27022ab0',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Chicago-style meat lover''s',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd9ffd107-2419-4010-8a0f-f4950608878c',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Chocolate cake',
    NULL,
    3.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '14ffc557-32d4-4171-8181-75167e554bfd',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Coffee',
    NULL,
    7.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '228c1f90-523c-4fdd-818c-59826d971f43',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Greek salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '98ee2111-828e-4033-8dbb-50fc68a3be26',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Pizza of the day (slice)',
    NULL,
    7.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd2fca0c4-ca85-4f05-8876-7e299334204d',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Thin crust anchovy and garlic and chili pepper',
    NULL,
    5.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3dac47a8-e003-4f60-8549-b627d42c92e2',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Thin crust broccoli, chicken, and mozarella',
    NULL,
    3.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bedf82a5-9022-4d81-8a91-adfcbdcc90d6',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Thin crust margherita',
    NULL,
    4.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f73c031c-a296-465c-8ca7-75d19feb241a',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Thin crust pepperoni',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ae74c29b-0f9c-478a-8022-1b82fefff86e',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Thin crust quattro stagione',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c7a003af-553a-43aa-8f7a-a743b7286286',
    '33970121-fb6e-414f-8706-4788ee407375',
    'Thin crust sausage and guanciale bacon',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 36: Luigi's House of Pies
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'luigis',
    'Luigi''s House of Pies',
    'Our secret pizza sauce makes our pizza better. We specialize in large groups.',
    'pizza',
    1,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '70ed2310-9358-4359-8ee5-2f447aae5143',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Cesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4aeb29db-edc4-4720-87bb-43601226a5c7',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Cheesecake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'cf3b3165-1afe-44b4-8497-5215a3811d79',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Chicago-style deep dish chicken and spinach',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5118268a-3332-4fb3-81b8-f0e322cc65b7',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Chicago-style deep dish pepperoni and cheese',
    NULL,
    7.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e4be5b05-6f3e-4e46-8916-e5b9944efcd0',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Chicago-style deep dish vegetarian',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '65734d15-4d60-4975-877a-4ebf46a2154a',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Chicago-style meat lover''s',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '20f5a6b0-3294-4a90-8310-58e4ee65f7bb',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Chocolate cake',
    NULL,
    3.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd018efab-c9ef-4e91-813a-3dec210a8669',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Coffee',
    NULL,
    7.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '73bf7250-c8ae-442e-8bdb-673de0abb645',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Greek salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b9a0aaba-d135-4526-8229-db33c96b76d6',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Pizza of the day (slice)',
    NULL,
    7.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'f440f629-348e-46d2-85a6-dfc388a969c2',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Thin crust anchovy and garlic and chili pepper',
    NULL,
    5.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1a5b62a2-a35d-446b-8d2a-64014cdef084',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Thin crust broccoli, chicken, and mozarella',
    NULL,
    3.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '30aa6654-a28c-4c8a-8995-2a75b8c2c05e',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Thin crust margherita',
    NULL,
    4.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '878e2fce-1f12-42fd-8e30-50ec83afb55b',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Thin crust pepperoni',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2eef094c-cf11-4bab-8f70-9c7a664fd7cf',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Thin crust quattro stagione',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd6ad3f24-5de9-43e0-8e85-6d14552cc4f6',
    '5130068d-73ee-43f4-81d7-de8b67ffdacb',
    'Thin crust sausage and guanciale bacon',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 37: Thick and Thin
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'thick',
    'Thick and Thin',
    'Whether you''re craving Chicago-style deep dish or thin as a wafer crust, we have you covered in toppings you''ll love.',
    'pizza',
    4,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd8ea96a5-e96b-4425-81e6-72021104a783',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Cesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '686eabcb-f933-4dee-809f-b4c4f40e17db',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Cheesecake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c6da473e-dcf8-4349-8c18-7bb0b9b87bda',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Chicago-style deep dish chicken and spinach',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5b6cd178-1feb-4810-8521-584843ad6889',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Chicago-style deep dish pepperoni and cheese',
    NULL,
    7.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '83fa6e63-e085-444b-833d-b0eeb841d929',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Chicago-style deep dish vegetarian',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '000e8bb6-3cf6-4cb4-8cab-c24fbc8b69ec',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Chicago-style meat lover''s',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '964ab267-8d7f-4ca1-88b1-16d652858d0b',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Chocolate cake',
    NULL,
    3.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a3dd8a5b-8961-4b99-80cb-4102c2422629',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Coffee',
    NULL,
    7.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c58d9abb-e703-4321-82ce-cc2b95d84ea3',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Greek salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9ebe419b-1cbf-46da-8b4c-b4b7099d54dd',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Pizza of the day (slice)',
    NULL,
    7.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'fd3715d6-1b8a-4cea-8cd8-3082cd3526f1',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thin crust anchovy and garlic and chili pepper',
    NULL,
    5.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c43e9ffe-6466-4ed3-894f-f636dfa15b65',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thin crust broccoli, chicken, and mozarella',
    NULL,
    3.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2916a1fb-5cc0-4220-87e0-3239db9982cf',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thin crust margherita',
    NULL,
    4.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '7bebd6d9-a7c3-4afa-875d-21d2ffc57670',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thin crust pepperoni',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd23d258d-e546-4f0b-8277-e4925e69b97e',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thin crust quattro stagione',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '15fadf09-1e99-4b63-8248-e45d7fec7d97',
    '7b1291e7-ed8a-4f3e-8aa8-2ce5a4176a5b',
    'Thin crust sausage and guanciale bacon',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 38: When in Rome
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'wheninrome',
    'When in Rome',
    'Authentic Italian pizza in a friendly neighborhood joint.',
    'pizza',
    2,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'ef1ef69e-6572-483a-8a52-a9704e47a8f4',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Cesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'd0bf5269-64ab-44c6-85cb-0520a39cc50d',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Cheesecake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '0d91124a-f34a-4949-839c-c9a202e4fdee',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Chicago-style deep dish chicken and spinach',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b26d6d41-bb10-4252-8862-db30db475338',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Chicago-style deep dish pepperoni and cheese',
    NULL,
    7.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3e8b2260-c842-4aaa-8eb9-b0a2c7081d8e',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Chicago-style deep dish vegetarian',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '2e4ac6e4-028f-47bb-8cca-6df64e95d14a',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Chicago-style meat lover''s',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b49c232a-359e-4f26-8ee8-7ea77b493c30',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Chocolate cake',
    NULL,
    3.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '9f8391e0-f067-44e2-824d-c655976abfad',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Coffee',
    NULL,
    7.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '69910a2f-bf10-480d-89c4-89d6055d7b4e',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Greek salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e451596c-cc3c-4e9a-8e54-433d1f59186d',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Pizza of the day (slice)',
    NULL,
    7.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '234029a2-8280-4025-8729-2416e7624d19',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Thin crust anchovy and garlic and chili pepper',
    NULL,
    5.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '148c0dd1-acaf-4add-8ee2-713a793bf49c',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Thin crust broccoli, chicken, and mozarella',
    NULL,
    3.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'a5b988b3-b20b-497e-822a-ead1015762c6',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Thin crust margherita',
    NULL,
    4.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6225aeb5-d7c6-448c-834c-c5523ffea109',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Thin crust pepperoni',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'c3bc514f-27c1-4069-8562-3e5996ca9536',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Thin crust quattro stagione',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '3f88923f-554f-4d59-8b53-7a817a782133',
    '687c9b7c-0acb-4a02-884a-c7ee48106f7d',
    'Thin crust sausage and guanciale bacon',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 39: Pizza 76
INSERT INTO restaurants (id, original_id, name, description, cuisine_type, rating, delivery_time, delivery_fee, min_order, is_active)
VALUES (
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'pizza76',
    'Pizza 76',
    'Wood-fired pizza with daily ingredients fresh from our farmer''s market. We make our own mozzarella in house.',
    'pizza',
    3,
    NULL,
    NULL,
    NULL,
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'bae86e3f-032d-4594-8a75-06f54a3e760b',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Cesar salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '74eaae29-fd70-4e76-8542-68780fd3bba3',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Cheesecake',
    NULL,
    6.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '4d1ab2e8-bed1-460d-8c7f-170fe1b65247',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Chicago-style deep dish chicken and spinach',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '73dfac6f-718b-4c9b-8287-a08bf8c300c0',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Chicago-style deep dish pepperoni and cheese',
    NULL,
    7.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'efec7077-31fa-4b25-85f4-4e3347289f2a',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Chicago-style deep dish vegetarian',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5c7498cb-4275-4072-86b6-de8a1cfcf81d',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Chicago-style meat lover''s',
    NULL,
    8.95,
    'Main Course',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '67be387f-9d0a-40eb-8003-0ba0056e5453',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Chocolate cake',
    NULL,
    3.95,
    'Desserts',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '11b19552-9e76-45f4-8eec-6b9f87a3cf4b',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Coffee',
    NULL,
    7.95,
    'Beverages',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '1a952cca-06e0-46c8-8d1f-fee0c7bf3789',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Greek salad',
    NULL,
    5.95,
    'Salads',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '03606ddc-8e8d-4ca3-834c-f557c2326e59',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Pizza of the day (slice)',
    NULL,
    7.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '57e580e3-1910-4f5e-8838-a03df28dca37',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Thin crust anchovy and garlic and chili pepper',
    NULL,
    5.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '5f19049a-eaaf-4174-83b7-22676488ea7d',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Thin crust broccoli, chicken, and mozarella',
    NULL,
    3.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'b560ccac-3fc2-4bcf-8649-2648dbb1946d',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Thin crust margherita',
    NULL,
    4.55,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '723497b4-93b8-4209-8535-07ea7beda142',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Thin crust pepperoni',
    NULL,
    6.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    '6ee2d722-2679-4f3e-88f0-325dc764e196',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Thin crust quattro stagione',
    NULL,
    4.95,
    'Pizza',
    true
) ON CONFLICT (id) DO NOTHING;
INSERT INTO menu_items (id, restaurant_id, name, description, price, category, is_available)
VALUES (
    'e77bdbd6-fb7c-42c0-8043-7277435acffb',
    '1d5aad3b-1acf-44cf-812a-95c92cd36db0',
    'Thin crust sausage and guanciale bacon',
    NULL,
    4.95,
    'Pizza',
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
