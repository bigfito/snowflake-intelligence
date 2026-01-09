-- ============================================================
-- SNOWFLAKE INTELLIGENCE DEMO: PIZZERIA BELLA NAPOLI
-- Script 2: Sample Data
-- ============================================================

USE DATABASE PIZZERIA_DEMO;
USE SCHEMA BELLA_NAPOLI;

-- ============================================================
-- DIMENSION DATA
-- ============================================================

-- Categories
INSERT INTO DIM_CATEGORY VALUES
(1, 'Pizzas', 'Our signature hand-tossed pizzas', 1),
(2, 'Appetizers', 'Start your meal right', 2),
(3, 'Salads', 'Fresh and healthy options', 3),
(4, 'Pasta', 'Traditional Italian pasta dishes', 4),
(5, 'Desserts', 'Sweet endings', 5),
(6, 'Beverages', 'Drinks and refreshments', 6);

-- Sizes
INSERT INTO DIM_SIZE VALUES
(1, 'Personal', 8, 0.70),
(2, 'Small', 10, 0.85),
(3, 'Medium', 12, 1.00),
(4, 'Large', 14, 1.25),
(5, 'X-Large', 16, 1.50),
(6, 'N/A', NULL, 1.00);

-- Menu Items
INSERT INTO DIM_MENU_ITEM VALUES
-- Pizzas
(1, 1, 'Margherita', 'Fresh mozzarella, San Marzano tomatoes, basil, extra virgin olive oil', 14.99, 4.50, 15, 850, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(2, 1, 'Pepperoni', 'Classic pepperoni with mozzarella and our signature tomato sauce', 16.99, 5.00, 15, 1100, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(3, 1, 'Supreme', 'Pepperoni, sausage, bell peppers, onions, mushrooms, olives', 19.99, 7.50, 18, 1350, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(4, 1, 'BBQ Chicken', 'Grilled chicken, BBQ sauce, red onions, cilantro, smoked gouda', 18.99, 6.50, 18, 1200, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(5, 1, 'Meat Lovers', 'Pepperoni, sausage, bacon, ham, ground beef', 21.99, 8.50, 20, 1500, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(6, 1, 'Veggie Delight', 'Mushrooms, bell peppers, onions, tomatoes, olives, spinach', 17.99, 5.50, 16, 750, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(7, 1, 'Hawaiian', 'Ham, pineapple, bacon, mozzarella', 17.99, 5.50, 15, 1050, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(8, 1, 'Buffalo Chicken', 'Spicy buffalo chicken, blue cheese crumbles, celery, ranch drizzle', 18.99, 6.50, 18, 1150, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(9, 1, 'White Pizza', 'Ricotta, mozzarella, parmesan, garlic, olive oil (no red sauce)', 16.99, 5.50, 15, 950, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(10, 1, 'Four Cheese', 'Mozzarella, provolone, parmesan, gorgonzola', 17.99, 6.00, 15, 1000, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(11, 1, 'Truffle Mushroom', 'Wild mushrooms, truffle oil, fontina, fresh thyme', 22.99, 9.00, 18, 900, TRUE, FALSE, FALSE, TRUE, '2023-06-01'),
(12, 1, 'Spicy Italian', 'Spicy sausage, hot peppers, jalapeños, red pepper flakes', 18.99, 6.00, 16, 1100, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(13, 1, 'Gluten-Free Margherita', 'Classic margherita on gluten-free crust', 17.99, 6.00, 18, 700, TRUE, FALSE, TRUE, TRUE, '2023-03-01'),
(14, 1, 'Vegan Supreme', 'Vegan cheese, mushrooms, peppers, onions, olives on cauliflower crust', 19.99, 8.00, 20, 650, TRUE, TRUE, TRUE, TRUE, '2023-06-01'),

-- Appetizers
(15, 2, 'Garlic Knots', 'Fresh baked knots with garlic butter and parmesan (8 pieces)', 6.99, 1.50, 8, 450, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(16, 2, 'Mozzarella Sticks', 'Hand-breaded mozzarella with marinara (6 pieces)', 8.99, 2.50, 10, 550, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(17, 2, 'Wings', 'Crispy wings with choice of sauce (10 pieces)', 12.99, 4.50, 15, 800, FALSE, FALSE, TRUE, TRUE, '2023-01-01'),
(18, 2, 'Bruschetta', 'Grilled bread with tomatoes, basil, garlic, balsamic glaze', 8.99, 2.00, 8, 320, TRUE, TRUE, FALSE, TRUE, '2023-01-01'),
(19, 2, 'Stuffed Mushrooms', 'Mushrooms stuffed with Italian sausage and cheese', 10.99, 3.50, 12, 420, FALSE, FALSE, TRUE, TRUE, '2023-01-01'),
(20, 2, 'Calamari', 'Lightly fried calamari with spicy marinara', 13.99, 5.00, 12, 480, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),

-- Salads
(21, 3, 'Caesar Salad', 'Romaine, parmesan, croutons, house Caesar dressing', 9.99, 2.50, 5, 350, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(22, 3, 'Garden Salad', 'Mixed greens, tomatoes, cucumbers, carrots, choice of dressing', 8.99, 2.00, 5, 180, TRUE, TRUE, TRUE, TRUE, '2023-01-01'),
(23, 3, 'Antipasto Salad', 'Mixed greens, salami, ham, provolone, olives, pepperoncini', 13.99, 4.50, 8, 520, FALSE, FALSE, TRUE, TRUE, '2023-01-01'),
(24, 3, 'Caprese Salad', 'Fresh mozzarella, tomatoes, basil, balsamic reduction', 11.99, 3.50, 5, 380, TRUE, FALSE, TRUE, TRUE, '2023-01-01'),

-- Pasta
(25, 4, 'Spaghetti Marinara', 'Spaghetti with house marinara sauce', 12.99, 3.00, 12, 680, TRUE, TRUE, FALSE, TRUE, '2023-01-01'),
(26, 4, 'Fettuccine Alfredo', 'Fettuccine in creamy parmesan sauce', 14.99, 4.00, 14, 920, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(27, 4, 'Chicken Parmesan', 'Breaded chicken breast over spaghetti with marinara', 17.99, 6.00, 18, 1050, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(28, 4, 'Baked Ziti', 'Ziti with ricotta, mozzarella, and meat sauce', 15.99, 4.50, 20, 880, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),
(29, 4, 'Lasagna', 'Traditional layered lasagna with meat sauce', 16.99, 5.50, 25, 950, FALSE, FALSE, FALSE, TRUE, '2023-01-01'),

-- Desserts
(30, 5, 'Tiramisu', 'Classic Italian coffee-flavored dessert', 7.99, 2.50, 2, 450, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(31, 5, 'Cannoli', 'Crispy shell filled with sweet ricotta cream (2 pieces)', 6.99, 2.00, 2, 380, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(32, 5, 'Chocolate Lava Cake', 'Warm chocolate cake with molten center', 8.99, 2.50, 10, 520, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),
(33, 5, 'Gelato', 'Italian ice cream - ask for flavors', 5.99, 1.50, 2, 280, TRUE, FALSE, TRUE, TRUE, '2023-01-01'),
(34, 5, 'Zeppole', 'Fried dough balls dusted with powdered sugar (6 pieces)', 5.99, 1.00, 8, 420, TRUE, FALSE, FALSE, TRUE, '2023-01-01'),

-- Beverages
(35, 6, 'Fountain Drink', 'Coke, Diet Coke, Sprite, Lemonade', 2.99, 0.30, 1, 150, TRUE, TRUE, TRUE, TRUE, '2023-01-01'),
(36, 6, 'Bottled Water', 'Acqua Panna or San Pellegrino', 2.49, 0.75, 1, 0, TRUE, TRUE, TRUE, TRUE, '2023-01-01'),
(37, 6, 'Italian Soda', 'Flavored sparkling water with cream', 3.99, 0.80, 2, 180, TRUE, TRUE, TRUE, TRUE, '2023-01-01'),
(38, 6, 'House Wine (Glass)', 'Red or White', 7.99, 2.50, 1, 125, TRUE, TRUE, TRUE, TRUE, '2023-01-01'),
(39, 6, 'Craft Beer', 'Rotating selection of local craft beers', 6.99, 2.00, 1, 180, TRUE, TRUE, TRUE, TRUE, '2023-01-01'),
(40, 6, 'Espresso', 'Double shot of Italian espresso', 3.49, 0.50, 3, 5, TRUE, TRUE, TRUE, TRUE, '2023-01-01');

-- Locations
INSERT INTO DIM_LOCATION VALUES
(1, 'Downtown', '123 Main Street', 'Austin', 'TX', '78701', '512-555-0101', '11:00:00', '22:00:00', 60, TRUE),
(2, 'Westlake', '456 Bee Cave Road', 'Austin', 'TX', '78746', '512-555-0102', '11:00:00', '22:00:00', 45, TRUE),
(3, 'Round Rock', '789 IH-35 North', 'Round Rock', 'TX', '78681', '512-555-0103', '11:00:00', '23:00:00', 80, TRUE);

-- Employees
INSERT INTO DIM_EMPLOYEE VALUES
(1, 'Marco', 'Romano', 'MANAGER', 28.00, '2021-03-15', TRUE),
(2, 'Sofia', 'Ricci', 'CHEF', 22.00, '2021-06-01', TRUE),
(3, 'Luca', 'Bianchi', 'CHEF', 20.00, '2022-01-10', TRUE),
(4, 'Giulia', 'Rossi', 'CASHIER', 16.00, '2022-08-15', TRUE),
(5, 'Antonio', 'Esposito', 'DELIVERY_DRIVER', 14.00, '2022-09-01', TRUE),
(6, 'Maria', 'Costa', 'CASHIER', 15.00, '2023-02-01', TRUE),
(7, 'Giuseppe', 'Ferrari', 'CHEF', 21.00, '2021-09-15', TRUE),
(8, 'Francesca', 'Greco', 'DELIVERY_DRIVER', 14.00, '2023-04-01', TRUE),
(9, 'Roberto', 'Bruno', 'MANAGER', 26.00, '2022-03-01', TRUE),
(10, 'Elena', 'Gallo', 'CHEF', 19.00, '2023-06-01', TRUE);

-- Ingredients
INSERT INTO DIM_INGREDIENT VALUES
(1, 'Pizza Dough Ball', 'EACH', 0.75, 'Local Bakery', TRUE, 3),
(2, 'Mozzarella Cheese', 'LB', 4.50, 'Grande Cheese Co', TRUE, 14),
(3, 'Pepperoni', 'LB', 6.00, 'Hormel Foods', TRUE, 21),
(4, 'Italian Sausage', 'LB', 5.50, 'Local Farm', TRUE, 7),
(5, 'San Marzano Tomatoes', 'EACH', 3.50, 'Italian Imports', FALSE, 365),
(6, 'Fresh Basil', 'OZ', 0.80, 'Local Farm', TRUE, 5),
(7, 'Olive Oil', 'GAL', 28.00, 'Italian Imports', FALSE, 180),
(8, 'Flour', 'LB', 0.45, 'General Mills', FALSE, 180),
(9, 'Parmesan Cheese', 'LB', 12.00, 'Italian Imports', TRUE, 60),
(10, 'Bell Peppers', 'LB', 2.50, 'Local Farm', TRUE, 7),
(11, 'Onions', 'LB', 1.20, 'Local Farm', TRUE, 14),
(12, 'Mushrooms', 'LB', 4.00, 'Local Farm', TRUE, 5),
(13, 'Black Olives', 'LB', 5.00, 'Italian Imports', FALSE, 90),
(14, 'Chicken Breast', 'LB', 5.50, 'Tyson Foods', TRUE, 5),
(15, 'Bacon', 'LB', 7.00, 'Hormel Foods', TRUE, 14);

-- Customers (sample of 50 customers)
INSERT INTO DIM_CUSTOMER VALUES
(1, 'James', 'Smith', 'james.smith@email.com', '512-555-1001', '100 Oak Lane', 'Austin', 'TX', '78701', '2023-01-15', 450, 'DELIVERY', '1985-03-22'),
(2, 'Emily', 'Johnson', 'emily.j@email.com', '512-555-1002', '200 Pine Street', 'Austin', 'TX', '78702', '2023-02-20', 320, 'DINE_IN', '1990-07-14'),
(3, 'Michael', 'Williams', 'mike.w@email.com', '512-555-1003', '300 Cedar Ave', 'Austin', 'TX', '78703', '2023-01-05', 890, 'PICKUP', '1982-11-30'),
(4, 'Sarah', 'Brown', 'sarah.brown@email.com', '512-555-1004', '400 Elm Drive', 'Austin', 'TX', '78704', '2023-03-10', 210, 'DELIVERY', '1995-05-08'),
(5, 'David', 'Jones', 'david.jones@email.com', '512-555-1005', '500 Maple Court', 'Austin', 'TX', '78746', '2023-04-25', 560, 'DINE_IN', '1978-09-17'),
(6, 'Lisa', 'Garcia', 'lisa.g@email.com', '512-555-1006', '600 Birch Road', 'Round Rock', 'TX', '78681', '2023-02-14', 380, 'PICKUP', '1988-12-03'),
(7, 'Robert', 'Martinez', 'rob.martinez@email.com', '512-555-1007', '700 Willow Way', 'Austin', 'TX', '78701', '2023-05-01', 720, 'DELIVERY', '1992-04-25'),
(8, 'Jennifer', 'Davis', 'jen.davis@email.com', '512-555-1008', '800 Spruce Lane', 'Austin', 'TX', '78702', '2023-03-22', 150, 'DINE_IN', '1998-08-11'),
(9, 'William', 'Rodriguez', 'will.rod@email.com', '512-555-1009', '900 Ash Street', 'Austin', 'TX', '78746', '2023-01-30', 980, 'PICKUP', '1975-02-28'),
(10, 'Jessica', 'Wilson', 'jess.wilson@email.com', '512-555-1010', '1000 Hickory Blvd', 'Round Rock', 'TX', '78681', '2023-06-05', 290, 'DELIVERY', '1991-10-19'),
(11, 'Christopher', 'Anderson', 'chris.a@email.com', '512-555-1011', '110 Main St', 'Austin', 'TX', '78701', '2023-02-08', 670, 'DINE_IN', '1984-06-07'),
(12, 'Amanda', 'Thomas', 'amanda.t@email.com', '512-555-1012', '220 Congress Ave', 'Austin', 'TX', '78701', '2023-04-12', 430, 'PICKUP', '1993-01-23'),
(13, 'Daniel', 'Jackson', 'dan.jackson@email.com', '512-555-1013', '330 6th Street', 'Austin', 'TX', '78702', '2023-03-18', 550, 'DELIVERY', '1987-07-09'),
(14, 'Ashley', 'White', 'ashley.w@email.com', '512-555-1014', '440 Lamar Blvd', 'Austin', 'TX', '78703', '2023-05-25', 180, 'DINE_IN', '1996-11-14'),
(15, 'Matthew', 'Harris', 'matt.harris@email.com', '512-555-1015', '550 South 1st', 'Austin', 'TX', '78704', '2023-01-22', 820, 'PICKUP', '1980-03-31'),
(16, 'Stephanie', 'Martin', 'steph.m@email.com', '512-555-1016', '660 Barton Springs', 'Austin', 'TX', '78704', '2023-06-30', 95, 'DELIVERY', '1999-09-06'),
(17, 'Andrew', 'Thompson', 'andrew.t@email.com', '512-555-1017', '770 MoPac Expwy', 'Austin', 'TX', '78746', '2023-02-28', 640, 'DINE_IN', '1983-12-20'),
(18, 'Nicole', 'Moore', 'nicole.moore@email.com', '512-555-1018', '880 Bee Cave Rd', 'Austin', 'TX', '78746', '2023-04-05', 410, 'PICKUP', '1994-04-12'),
(19, 'Joshua', 'Taylor', 'josh.taylor@email.com', '512-555-1019', '990 Research Blvd', 'Austin', 'TX', '78759', '2023-03-14', 510, 'DELIVERY', '1986-08-28'),
(20, 'Rachel', 'Lee', 'rachel.lee@email.com', '512-555-1020', '1100 Parmer Lane', 'Round Rock', 'TX', '78681', '2023-05-08', 260, 'DINE_IN', '1997-02-15'),
(21, 'Kevin', 'Clark', 'kevin.c@email.com', '512-555-1021', '1210 IH-35', 'Round Rock', 'TX', '78681', '2023-07-01', 75, 'PICKUP', '1989-05-22'),
(22, 'Megan', 'Lewis', 'megan.l@email.com', '512-555-1022', '1320 McNeil Dr', 'Round Rock', 'TX', '78681', '2023-04-20', 340, 'DELIVERY', '1992-10-08'),
(23, 'Ryan', 'Walker', 'ryan.walker@email.com', '512-555-1023', '1430 Wells Branch', 'Austin', 'TX', '78728', '2023-02-12', 590, 'DINE_IN', '1981-07-16'),
(24, 'Lauren', 'Hall', 'lauren.h@email.com', '512-555-1024', '1540 Metric Blvd', 'Austin', 'TX', '78758', '2023-06-15', 200, 'PICKUP', '1995-12-29'),
(25, 'Brandon', 'Allen', 'brandon.a@email.com', '512-555-1025', '1650 Burnet Rd', 'Austin', 'TX', '78757', '2023-03-08', 760, 'DELIVERY', '1979-11-04');

-- Generate more customers dynamically
INSERT INTO DIM_CUSTOMER 
SELECT 
    25 + SEQ4() as customer_id,
    CASE MOD(SEQ4(), 10) 
        WHEN 0 THEN 'Alex' WHEN 1 THEN 'Jordan' WHEN 2 THEN 'Taylor' 
        WHEN 3 THEN 'Morgan' WHEN 4 THEN 'Casey' WHEN 5 THEN 'Riley'
        WHEN 6 THEN 'Quinn' WHEN 7 THEN 'Avery' WHEN 8 THEN 'Blake' ELSE 'Charlie'
    END as first_name,
    CASE MOD(SEQ4(), 8)
        WHEN 0 THEN 'Miller' WHEN 1 THEN 'Wilson' WHEN 2 THEN 'Moore'
        WHEN 3 THEN 'Taylor' WHEN 4 THEN 'Anderson' WHEN 5 THEN 'Thomas'
        WHEN 6 THEN 'Jackson' ELSE 'White'
    END as last_name,
    LOWER(CASE MOD(SEQ4(), 10) 
        WHEN 0 THEN 'Alex' WHEN 1 THEN 'Jordan' WHEN 2 THEN 'Taylor' 
        WHEN 3 THEN 'Morgan' WHEN 4 THEN 'Casey' WHEN 5 THEN 'Riley'
        WHEN 6 THEN 'Quinn' WHEN 7 THEN 'Avery' WHEN 8 THEN 'Blake' ELSE 'Charlie'
    END) || (25 + SEQ4()) || '@email.com' as email,
    '512-555-' || LPAD(1025 + SEQ4(), 4, '0') as phone,
    (1000 + SEQ4() * 100) || ' Random Street' as address,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Austin' WHEN 1 THEN 'Round Rock' ELSE 'Austin' END as city,
    'TX' as state,
    CASE MOD(SEQ4(), 5) 
        WHEN 0 THEN '78701' WHEN 1 THEN '78702' WHEN 2 THEN '78746' 
        WHEN 3 THEN '78681' ELSE '78704' 
    END as zip_code,
    DATEADD(DAY, -MOD(SEQ4() * 17, 365), CURRENT_DATE()) as registration_date,
    MOD(SEQ4() * 47, 1000) as loyalty_points,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'DELIVERY' WHEN 1 THEN 'PICKUP' ELSE 'DINE_IN' END as preferred_order_type,
    DATEADD(YEAR, -20 - MOD(SEQ4() * 7, 40), CURRENT_DATE()) as birthday
FROM TABLE(GENERATOR(ROWCOUNT => 75));

COMMIT;
