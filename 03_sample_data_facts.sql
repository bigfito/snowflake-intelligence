-- ============================================================
-- SNOWFLAKE INTELLIGENCE DEMO: PIZZERIA BELLA NAPOLI
-- Script 3: Fact Table Data (Orders, Reviews, Daily Sales)
-- ============================================================

USE DATABASE PIZZERIA_DEMO;
USE SCHEMA BELLA_NAPOLI;

-- ============================================================
-- GENERATE ORDERS (Last 12 months of order data)
-- ============================================================

-- Create a date spine for the last 365 days
CREATE OR REPLACE TEMPORARY TABLE DATE_SPINE AS
SELECT DATEADD(DAY, -SEQ4(), CURRENT_DATE()) AS order_date
FROM TABLE(GENERATOR(ROWCOUNT => 365));

-- Generate Orders
CREATE OR REPLACE TEMPORARY TABLE TEMP_ORDERS AS
WITH order_base AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY d.order_date, r.seq) AS order_id,
        d.order_date,
        -- More orders on weekends
        CASE 
            WHEN DAYOFWEEK(d.order_date) IN (0, 6) THEN UNIFORM(1, 100, RANDOM())
            ELSE UNIFORM(1, 100, RANDOM())
        END AS customer_id,
        -- Assign employees based on shift patterns
        CASE 
            WHEN HOUR(TIMEADD(HOUR, UNIFORM(11, 21, RANDOM()), d.order_date::TIMESTAMP)) < 15 
            THEN UNIFORM(1, 5, RANDOM())
            ELSE UNIFORM(6, 10, RANDOM())
        END AS employee_id,
        -- Location distribution
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN 2
            WHEN 2 THEN 2
            WHEN 3 THEN 3
            WHEN 4 THEN 3
            WHEN 5 THEN 3
            ELSE 1
        END AS location_id,
        -- Order timestamp with realistic hour distribution
        TIMESTAMPADD(
            MINUTE,
            UNIFORM(0, 59, RANDOM()),
            TIMESTAMPADD(
                HOUR,
                CASE 
                    WHEN UNIFORM(1, 100, RANDOM()) <= 10 THEN 11  -- 10% lunch early
                    WHEN UNIFORM(1, 100, RANDOM()) <= 30 THEN 12  -- 20% lunch peak
                    WHEN UNIFORM(1, 100, RANDOM()) <= 40 THEN 13  -- 10% lunch late
                    WHEN UNIFORM(1, 100, RANDOM()) <= 50 THEN 17  -- 10% dinner early
                    WHEN UNIFORM(1, 100, RANDOM()) <= 75 THEN 18  -- 25% dinner peak
                    WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 19  -- 15% dinner
                    ELSE 20  -- 10% late dinner
                END,
                d.order_date::TIMESTAMP
            )
        ) AS order_timestamp,
        -- Order type distribution
        CASE UNIFORM(1, 100, RANDOM())
            WHEN 1 THEN 'DINE_IN'
            WHEN 2 THEN 'DINE_IN'
            WHEN 3 THEN 'DINE_IN'
            ELSE CASE WHEN UNIFORM(1, 10, RANDOM()) <= 6 THEN 'DELIVERY' ELSE 'PICKUP' END
        END AS order_type,
        -- Payment method
        CASE UNIFORM(1, 100, RANDOM())
            WHEN 1 THEN 'CASH'
            WHEN 2 THEN 'CASH'
            ELSE CASE WHEN UNIFORM(1, 10, RANDOM()) <= 7 THEN 'CREDIT' ELSE 'MOBILE' END
        END AS payment_method
    FROM DATE_SPINE d,
    -- Generate multiple orders per day (more on weekends, Fridays)
    (SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 80))) r
    WHERE 
        -- Filter to create realistic daily order counts
        (DAYOFWEEK(d.order_date) IN (0, 6) AND r.seq <= UNIFORM(50, 80, RANDOM())) OR  -- Weekend: 50-80 orders
        (DAYOFWEEK(d.order_date) = 5 AND r.seq <= UNIFORM(45, 65, RANDOM())) OR         -- Friday: 45-65 orders
        (DAYOFWEEK(d.order_date) NOT IN (0, 5, 6) AND r.seq <= UNIFORM(30, 50, RANDOM())) -- Weekday: 30-50 orders
)
SELECT * FROM order_base;

-- Insert orders into fact table
INSERT INTO FACT_ORDER (
    order_id, customer_id, employee_id, location_id, order_timestamp,
    order_type, subtotal, tax_amount, tip_amount, discount_amount,
    total_amount, payment_method, order_status, delivery_address,
    estimated_ready_time, actual_ready_time, delivery_time, special_instructions
)
SELECT 
    o.order_id,
    o.customer_id,
    o.employee_id,
    o.location_id,
    o.order_timestamp,
    o.order_type,
    0 AS subtotal,  -- Will be updated after order items
    0 AS tax_amount,
    CASE WHEN o.order_type = 'DELIVERY' THEN ROUND(UNIFORM(3, 10, RANDOM()), 2) ELSE 0 END AS tip_amount,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 15 THEN ROUND(UNIFORM(2, 8, RANDOM()), 2) ELSE 0 END AS discount_amount,
    0 AS total_amount,
    o.payment_method,
    'COMPLETED' AS order_status,
    CASE WHEN o.order_type = 'DELIVERY' 
        THEN c.address || ', ' || c.city || ', ' || c.state || ' ' || c.zip_code 
        ELSE NULL 
    END AS delivery_address,
    TIMESTAMPADD(MINUTE, UNIFORM(20, 35, RANDOM()), o.order_timestamp) AS estimated_ready_time,
    TIMESTAMPADD(MINUTE, UNIFORM(18, 40, RANDOM()), o.order_timestamp) AS actual_ready_time,
    CASE WHEN o.order_type = 'DELIVERY' 
        THEN TIMESTAMPADD(MINUTE, UNIFORM(35, 55, RANDOM()), o.order_timestamp)
        ELSE NULL
    END AS delivery_time,
    CASE UNIFORM(1, 20, RANDOM())
        WHEN 1 THEN 'Extra cheese please'
        WHEN 2 THEN 'Light sauce'
        WHEN 3 THEN 'Well done'
        WHEN 4 THEN 'Cut into squares'
        WHEN 5 THEN 'No contact delivery'
        ELSE NULL
    END AS special_instructions
FROM TEMP_ORDERS o
LEFT JOIN DIM_CUSTOMER c ON o.customer_id = c.customer_id;

-- ============================================================
-- GENERATE ORDER ITEMS
-- ============================================================

INSERT INTO FACT_ORDER_ITEM (order_item_id, order_id, item_id, size_id, quantity, unit_price, line_total, special_requests)
WITH order_items_base AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY o.order_id, item_num) AS order_item_id,
        o.order_id,
        -- Pizza is most common, then appetizers, etc.
        CASE 
            WHEN item_num = 1 THEN UNIFORM(1, 14, RANDOM())  -- First item: pizza
            WHEN item_num = 2 AND UNIFORM(1, 10, RANDOM()) <= 7 THEN UNIFORM(1, 14, RANDOM())  -- 70% second pizza
            WHEN item_num = 2 THEN UNIFORM(15, 24, RANDOM())  -- 30% appetizer or salad
            WHEN item_num = 3 THEN 
                CASE UNIFORM(1, 4, RANDOM())
                    WHEN 1 THEN UNIFORM(15, 20, RANDOM())  -- Appetizer
                    WHEN 2 THEN UNIFORM(21, 24, RANDOM())  -- Salad
                    WHEN 3 THEN UNIFORM(35, 40, RANDOM())  -- Beverage
                    ELSE UNIFORM(30, 34, RANDOM())         -- Dessert
                END
            ELSE UNIFORM(35, 40, RANDOM())  -- Additional items: beverages
        END AS item_id,
        CASE 
            WHEN UNIFORM(1, 14, RANDOM()) <= 14 THEN  -- For pizzas
                CASE UNIFORM(1, 100, RANDOM())
                    WHEN 1 THEN 1  -- Personal: rare
                    WHEN 2 THEN 2  -- Small: rare
                    ELSE CASE WHEN UNIFORM(1, 10, RANDOM()) <= 4 THEN 3 ELSE 4 END  -- Medium or Large
                END
            ELSE 6  -- N/A for non-pizzas
        END AS size_id,
        CASE 
            WHEN item_num = 1 THEN UNIFORM(1, 2, RANDOM())  -- Usually 1-2 of main item
            ELSE 1
        END AS quantity
    FROM FACT_ORDER o,
    -- Generate 1-4 items per order
    (SELECT SEQ4() + 1 AS item_num FROM TABLE(GENERATOR(ROWCOUNT => 4))) items
    WHERE 
        (item_num = 1) OR
        (item_num = 2 AND UNIFORM(1, 100, RANDOM()) <= 75) OR  -- 75% have 2+ items
        (item_num = 3 AND UNIFORM(1, 100, RANDOM()) <= 40) OR  -- 40% have 3+ items
        (item_num = 4 AND UNIFORM(1, 100, RANDOM()) <= 15)     -- 15% have 4 items
)
SELECT 
    oi.order_item_id,
    oi.order_id,
    oi.item_id,
    CASE WHEN m.category_id = 1 THEN oi.size_id ELSE 6 END AS size_id,
    oi.quantity,
    ROUND(m.base_price * s.price_multiplier, 2) AS unit_price,
    ROUND(m.base_price * s.price_multiplier * oi.quantity, 2) AS line_total,
    CASE UNIFORM(1, 30, RANDOM())
        WHEN 1 THEN 'No onions'
        WHEN 2 THEN 'Extra pepperoni'
        WHEN 3 THEN 'Add jalapeños'
        WHEN 4 THEN 'Gluten allergy'
        WHEN 5 THEN 'Dairy free'
        ELSE NULL
    END AS special_requests
FROM order_items_base oi
JOIN DIM_MENU_ITEM m ON oi.item_id = m.item_id
JOIN DIM_SIZE s ON CASE WHEN m.category_id = 1 THEN oi.size_id ELSE 6 END = s.size_id;

-- Update order totals
UPDATE FACT_ORDER o
SET 
    subtotal = (SELECT SUM(line_total) FROM FACT_ORDER_ITEM oi WHERE oi.order_id = o.order_id),
    tax_amount = ROUND((SELECT SUM(line_total) FROM FACT_ORDER_ITEM oi WHERE oi.order_id = o.order_id) * 0.0825, 2),
    total_amount = ROUND(
        (SELECT SUM(line_total) FROM FACT_ORDER_ITEM oi WHERE oi.order_id = o.order_id) * 1.0825 
        + o.tip_amount - o.discount_amount, 
        2
    );

-- ============================================================
-- GENERATE REVIEWS (mix of positive, neutral, negative)
-- ============================================================

INSERT INTO FACT_REVIEW (review_id, order_id, customer_id, location_id, review_date, 
    overall_rating, food_rating, service_rating, delivery_rating, review_text, review_source)

/* STEP 1: CALCULATE RATINGS
   We filter the 25% of orders and generate the numeric ratings first. 
   This ensures the numbers are "frozen" before we generate text based on them.
*/
WITH RATED_ORDERS AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.location_id,
        o.order_timestamp,
        o.order_type,
        -- Generate Ratings
        CASE 
            WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN 5 
            WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 4 
            WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 3 
            ELSE UNIFORM(1, 2, RANDOM()) 
        END AS overall_rating,
        CASE 
            WHEN UNIFORM(1, 100, RANDOM()) <= 65 THEN 5
            WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 4
            ELSE UNIFORM(2, 3, RANDOM())
        END AS food_rating,
        CASE 
            WHEN UNIFORM(1, 100, RANDOM()) <= 55 THEN 5
            WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 4
            ELSE UNIFORM(2, 3, RANDOM())
        END AS service_rating,
        CASE 
            WHEN UNIFORM(1, 100, RANDOM()) <= 50 THEN 5
            WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 4
            ELSE UNIFORM(2, 3, RANDOM())
        END AS delivery_rating_raw
    FROM FACT_ORDER o
    WHERE UNIFORM(1, 100, RANDOM()) <= 25 -- Filter 25% here for performance
)
/* STEP 2: GENERATE METADATA & TEXT
   Now we map the fixed ratings to text and handle final formatting.
*/
SELECT 
    ROW_NUMBER() OVER (ORDER BY ro.order_id) AS review_id,
    ro.order_id,
    ro.customer_id,
    ro.location_id,
    TIMESTAMPADD(HOUR, UNIFORM(1, 48, RANDOM()), ro.order_timestamp) AS review_date,
    ro.overall_rating,
    ro.food_rating,
    ro.service_rating,
    CASE WHEN ro.order_type = 'DELIVERY' THEN ro.delivery_rating_raw ELSE NULL END AS delivery_rating,
    
    -- Text Generation (Based on the FIXED overall_rating from CTE)
    CASE 
        WHEN ro.overall_rating = 5 THEN 
            CASE UNIFORM(1, 15, RANDOM())
                WHEN 1 THEN 'Best pizza in Austin! The crust is perfectly crispy and the toppings are always fresh. Highly recommend the Margherita!'
                WHEN 2 THEN 'Amazing experience! The staff was super friendly and the food came out quickly. Will definitely be back!'
                WHEN 3 THEN 'Our go-to pizza place! Love the BBQ Chicken pizza - the flavors are incredible. Fast delivery too!'
                WHEN 4 THEN 'Fantastic pizza and great value. The Supreme is loaded with toppings. Kids loved it!'
                WHEN 5 THEN 'Exceeded expectations! Fresh ingredients, authentic Italian taste. The tiramisu is a must-try!'
                WHEN 6 THEN 'Perfect every single time. We order at least once a week. The Meat Lovers never disappoints.'
                WHEN 7 THEN 'The truffle mushroom pizza is absolutely divine! Such unique flavors you wont find anywhere else.'
                WHEN 8 THEN 'Ordered for a party and everyone was impressed. Great portion sizes and reasonable prices.'
                WHEN 9 THEN 'Love that they have gluten-free options! Finally a pizza place my whole family can enjoy.'
                WHEN 10 THEN 'Consistently delicious. The garlic knots are addictive and the pepperoni pizza is classic perfection.'
                WHEN 11 THEN 'My new favorite spot! The white pizza with ricotta is heavenly. Delivery was super fast.'
                WHEN 12 THEN 'Authentic Italian pizza right here in Austin. The San Marzano tomatoes make all the difference!'
                WHEN 13 THEN 'The vegan options are amazing - you cant even tell its vegan cheese! So grateful for inclusive menu.'
                WHEN 14 THEN 'Date night favorite! Great atmosphere, excellent wine selection, and of course incredible pizza.'
                ELSE 'Simply the best! Fresh, hot, and delicious every time. The four cheese pizza is out of this world!'
            END
        WHEN ro.overall_rating = 4 THEN 
            CASE UNIFORM(1, 10, RANDOM())
                WHEN 1 THEN 'Really good pizza, just wish they had more vegetarian specialty options. Service was great though!'
                WHEN 2 THEN 'Tasty food and friendly staff. Delivery took a bit longer than expected but pizza was still hot.'
                WHEN 3 THEN 'Great pizza for the price. The crust was a little thicker than I prefer but flavors were on point.'
                WHEN 4 THEN 'Good experience overall. Wings were excellent, pizza was good but sauce could use more seasoning.'
                WHEN 5 THEN 'Nice place for a casual dinner. Food quality is consistent. Would be 5 stars with faster service.'
                WHEN 6 THEN 'Solid pizza joint. The Hawaiian was tasty. Parking can be tricky during busy hours.'
                WHEN 7 THEN 'Pretty good! The Caesar salad is fresh and generous. Pizza arrived lukewarm but tasted great.'
                WHEN 8 THEN 'Good value for money. Kids menu would be nice addition. The mozzarella sticks were a hit!'
                WHEN 9 THEN 'Enjoyed our meal. The Four Cheese pizza was rich and flavorful. Just a bit too salty for my taste.'
                ELSE 'Nice neighborhood pizza spot. Food is reliably good. The app for ordering could use some improvements.'
            END
        WHEN ro.overall_rating = 3 THEN 
            CASE UNIFORM(1, 8, RANDOM())
                WHEN 1 THEN 'Average pizza experience. Nothing special but nothing bad either. Might try again.'
                WHEN 2 THEN 'Food was okay but took forever to arrive. Pizza was cold by the time we got it.'
                WHEN 3 THEN 'Decent pizza but overpriced for what you get. Other places nearby offer better value.'
                WHEN 4 THEN 'The pizza was fine but the service was slow and inattentive. Expected better.'
                WHEN 5 THEN 'Hit or miss. Some visits are great, others are disappointing. Consistency is an issue.'
                WHEN 6 THEN 'Toppings were sparse and crust was soggy. Had better experiences here before.'
                WHEN 7 THEN 'Not bad but not memorable. The pasta was better than the pizza surprisingly.'
                ELSE 'Middle of the road. Nothing wrong but nothing exciting either. Probably wouldnt go out of my way.'
            END
        WHEN ro.overall_rating = 2 THEN 
            CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'Disappointed with this visit. Pizza was undercooked and the order was wrong. No apology from staff.'
                WHEN 2 THEN 'Used to be good but quality has declined. Waited 45 minutes for lukewarm pizza. Wont return soon.'
                WHEN 3 THEN 'Very greasy and the cheese was not melted properly. Asked for remake but it was the same.'
                WHEN 4 THEN 'Delivery driver was rude and pizza box was crushed. Food was mediocre at best.'
                ELSE 'Not what it used to be. Small portions, slow service, and the pizza tasted like it sat under a heat lamp.'
            END
        ELSE -- Rating 1
            CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'Terrible experience. Found a hair in my pizza and manager was dismissive. Never again.'
                WHEN 2 THEN 'Worst pizza Ive had in Austin. Raw dough in the middle, burnt edges. Complete waste of money.'
                WHEN 3 THEN 'Food poisoning after eating here. Reported to health department. Stay away!'
                WHEN 4 THEN 'Order was completely wrong, waited over an hour, and the pizza was inedible. Absolutely awful.'
                ELSE 'Zero stars if I could. Rude staff, dirty tables, and the food was disgusting. How is this place still open?'
            END
    END AS review_text,

    -- Source Generation
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'GOOGLE'
        WHEN 2 THEN 'GOOGLE'
        WHEN 3 THEN 'YELP'
        WHEN 4 THEN 'YELP'
        WHEN 5 THEN 'DOORDASH'
        ELSE 'WEBSITE'
    END AS review_source
FROM RATED_ORDERS ro;

-- ============================================================
-- GENERATE DAILY SALES SUMMARY
-- ============================================================

INSERT INTO FACT_DAILY_SALES (
    sales_date, location_id, total_orders, total_revenue, avg_order_value,
    dine_in_orders, pickup_orders, delivery_orders, total_pizzas_sold,
    new_customers, weather_condition, is_weekend, is_holiday
)
/* CTE Step: Pre-aggregate items to the Order level.
   This prevents the "Fan-out" issue where joining items multiplies order revenue.
*/
WITH ITEM_METRICS AS (
    SELECT 
        o.order_id,
        SUM(CASE WHEN oi.item_id BETWEEN 1 AND 14 THEN oi.quantity ELSE 0 END) AS pizza_count
    FROM FACT_ORDER o
    JOIN FACT_ORDER_ITEM oi ON o.order_id = oi.order_id
    GROUP BY o.order_id
)
SELECT 
    DATE(o.order_timestamp) AS sales_date,
    o.location_id,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    
    -- Order Type Counts
    COUNT(CASE WHEN o.order_type = 'DINE_IN' THEN 1 END) AS dine_in_orders,
    COUNT(CASE WHEN o.order_type = 'PICKUP' THEN 1 END) AS pickup_orders,
    COUNT(CASE WHEN o.order_type = 'DELIVERY' THEN 1 END) AS delivery_orders,
    
    -- Sum the pre-calculated item metrics
    COALESCE(SUM(im.pizza_count), 0) AS total_pizzas_sold,
    
    -- Customer Logic
    COUNT(CASE WHEN c.registration_date = DATE(o.order_timestamp) THEN c.customer_id END) AS new_customers,
    
    -- Random Weather (Wrapped in ANY_VALUE or MAX to satisfy Group By)
    ANY_VALUE(
        CASE UNIFORM(1, 10, RANDOM())
            WHEN 1 THEN 'Rainy'
            WHEN 2 THEN 'Rainy'
            WHEN 3 THEN 'Cloudy'
            WHEN 4 THEN 'Cloudy'
            ELSE 'Sunny'
        END
    ) AS weather_condition,
    
    -- Date Logic (Wrapped in MAX to satisfy Group By)
    MAX(CASE WHEN DAYOFWEEK(o.order_timestamp) IN (0, 6) THEN TRUE ELSE FALSE END) AS is_weekend,
    MAX(CASE WHEN DATE(o.order_timestamp) IN ('2024-01-01', '2024-07-04', '2024-11-28', '2024-12-25', '2025-01-01') THEN TRUE ELSE FALSE END) AS is_holiday

FROM FACT_ORDER o
LEFT JOIN ITEM_METRICS im ON o.order_id = im.order_id
LEFT JOIN DIM_CUSTOMER c ON o.customer_id = c.customer_id
GROUP BY 1, 2;

-- ============================================================
-- GENERATE INVENTORY DATA
-- ============================================================

INSERT INTO FACT_INVENTORY (inventory_id, location_id, ingredient_id, record_date,
    quantity_on_hand, quantity_used, quantity_received, quantity_wasted, reorder_point, reorder_quantity)
SELECT 
    ROW_NUMBER() OVER (ORDER BY d.order_date, l.location_id, i.ingredient_id) AS inventory_id,
    l.location_id,
    i.ingredient_id,
    d.order_date AS record_date,
    -- Quantity on hand varies by ingredient type
    CASE 
        WHEN i.ingredient_name = 'Pizza Dough Ball' THEN UNIFORM(50, 200, RANDOM())
        WHEN i.ingredient_name LIKE '%Cheese%' THEN UNIFORM(20, 80, RANDOM())
        WHEN i.ingredient_name IN ('Pepperoni', 'Italian Sausage', 'Bacon') THEN UNIFORM(15, 50, RANDOM())
        WHEN i.ingredient_name IN ('Fresh Basil', 'Bell Peppers', 'Mushrooms') THEN UNIFORM(5, 25, RANDOM())
        ELSE UNIFORM(10, 100, RANDOM())
    END AS quantity_on_hand,
    -- Daily usage based on sales
    CASE 
        WHEN i.ingredient_name = 'Pizza Dough Ball' THEN UNIFORM(30, 80, RANDOM())
        WHEN i.ingredient_name LIKE '%Cheese%' THEN UNIFORM(10, 40, RANDOM())
        ELSE UNIFORM(5, 20, RANDOM())
    END AS quantity_used,
    -- Receiving every few days
    CASE WHEN MOD(DATEDIFF(DAY, '2024-01-01', d.order_date), 3) = 0 
        THEN UNIFORM(50, 150, RANDOM()) 
        ELSE 0 
    END AS quantity_received,
    -- Occasional waste (higher for perishables)
    CASE 
        WHEN i.is_perishable AND UNIFORM(1, 10, RANDOM()) <= 3 
        THEN UNIFORM(1, 5, RANDOM())
        ELSE 0
    END AS quantity_wasted,
    -- Reorder points
    CASE 
        WHEN i.ingredient_name = 'Pizza Dough Ball' THEN 75
        WHEN i.ingredient_name LIKE '%Cheese%' THEN 30
        ELSE 15
    END AS reorder_point,
    -- Reorder quantities
    CASE 
        WHEN i.ingredient_name = 'Pizza Dough Ball' THEN 150
        WHEN i.ingredient_name LIKE '%Cheese%' THEN 60
        ELSE 30
    END AS reorder_quantity
FROM DATE_SPINE d
CROSS JOIN DIM_LOCATION l
CROSS JOIN DIM_INGREDIENT i
WHERE d.order_date >= DATEADD(DAY, -90, CURRENT_DATE());  -- Last 90 days of inventory

-- Cleanup
DROP TABLE IF EXISTS TEMP_ORDERS;
DROP TABLE IF EXISTS DATE_SPINE;

COMMIT;
