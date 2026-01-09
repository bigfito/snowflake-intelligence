-- ============================================================
-- SNOWFLAKE INTELLIGENCE DEMO: PIZZERIA BELLA NAPOLI
-- Script 5: Demo Queries - Snowflake Intelligence Features
-- ============================================================

USE DATABASE PIZZERIA_DEMO;
USE SCHEMA BELLA_NAPOLI;

-- ============================================================
-- PART 1: CORTEX LLM FUNCTIONS
-- ============================================================

-- --------------------------------------------------------
-- 1.1 SENTIMENT ANALYSIS ON REVIEWS
-- Automatically classify customer feedback sentiment
-- --------------------------------------------------------

-- Analyze sentiment of recent reviews
SELECT 
    r.review_id,
    r.overall_rating,
    r.review_text,
    SNOWFLAKE.CORTEX.SENTIMENT(r.review_text) AS sentiment_score,
    CASE 
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(r.review_text) >= 0.3 THEN 'Positive'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(r.review_text) <= -0.3 THEN 'Negative'
        ELSE 'Neutral'
    END AS sentiment_category
FROM FACT_REVIEW r
WHERE r.review_text IS NOT NULL
ORDER BY r.review_date DESC
LIMIT 20;

-- Find mismatched ratings vs sentiment (potential review gaming)
SELECT 
    r.review_id,
    r.overall_rating,
    SNOWFLAKE.CORTEX.SENTIMENT(r.review_text) AS sentiment_score,
    r.review_text,
    CASE 
        WHEN r.overall_rating >= 4 AND SNOWFLAKE.CORTEX.SENTIMENT(r.review_text) < -0.2 
            THEN 'High rating but negative text'
        WHEN r.overall_rating <= 2 AND SNOWFLAKE.CORTEX.SENTIMENT(r.review_text) > 0.2 
            THEN 'Low rating but positive text'
        ELSE 'Consistent'
    END AS rating_sentiment_match
FROM FACT_REVIEW r
WHERE r.review_text IS NOT NULL
HAVING rating_sentiment_match != 'Consistent'
ORDER BY r.review_date DESC;

-- --------------------------------------------------------
-- 1.2 TEXT SUMMARIZATION
-- Summarize customer feedback themes
-- --------------------------------------------------------

-- Summarize negative reviews for management action
WITH negative_reviews AS (
    SELECT LISTAGG(review_text, ' | ') WITHIN GROUP (ORDER BY review_date DESC) AS all_reviews
    FROM FACT_REVIEW
    WHERE overall_rating <= 2
    AND review_text IS NOT NULL
    LIMIT 10
)
SELECT SNOWFLAKE.CORTEX.SUMMARIZE(all_reviews) AS negative_feedback_summary
FROM negative_reviews;

-- Summarize positive reviews for marketing
WITH positive_reviews AS (
    SELECT LISTAGG(review_text, ' | ') WITHIN GROUP (ORDER BY review_date DESC) AS all_reviews
    FROM FACT_REVIEW
    WHERE overall_rating = 5
    AND review_text IS NOT NULL
    LIMIT 15
)
SELECT SNOWFLAKE.CORTEX.SUMMARIZE(all_reviews) AS positive_feedback_summary
FROM positive_reviews;

-- --------------------------------------------------------
-- 1.3 TEXT CLASSIFICATION
-- Classify review topics automatically
-- --------------------------------------------------------

-- Classify reviews by topic
SELECT 
    r.review_id,
    r.review_text,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        r.review_text,
        ['Food Quality', 'Service', 'Delivery', 'Price', 'Ambiance', 'Cleanliness']
    ):label::STRING AS primary_topic,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        r.review_text,
        ['Food Quality', 'Service', 'Delivery', 'Price', 'Ambiance', 'Cleanliness']
    ):probability::FLOAT AS confidence
FROM FACT_REVIEW r
WHERE r.review_text IS NOT NULL
ORDER BY r.review_date DESC
LIMIT 25;

-- --------------------------------------------------------
-- 1.4 ENTITY EXTRACTION
-- Extract menu items mentioned in reviews
-- --------------------------------------------------------

SELECT 
    r.review_id,
    r.review_text,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        r.review_text,
        'What food items or dishes are mentioned?'
    ) AS mentioned_items
FROM FACT_REVIEW r
WHERE r.review_text IS NOT NULL
AND LENGTH(r.review_text) > 50
ORDER BY r.review_date DESC
LIMIT 15;

-- --------------------------------------------------------
-- 1.5 COMPLETE - Custom LLM Prompts
-- Generate insights and recommendations
-- --------------------------------------------------------

-- Generate menu item descriptions
SELECT 
    item_name,
    description AS current_description,
    SNOWFLAKE.CORTEX.COMPLETE(
        'claude-3-5-sonnet',
        'Write a compelling, appetizing 2-sentence menu description for this Italian restaurant pizza: ' 
        || item_name || '. Current description: ' || description
    ) AS enhanced_description
FROM DIM_MENU_ITEM
WHERE category_id = 1
LIMIT 5;

-- Generate personalized email for top customers
WITH top_customers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS lifetime_value,
        MAX(o.order_timestamp) AS last_order
    FROM DIM_CUSTOMER c
    JOIN FACT_ORDER o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
    ORDER BY lifetime_value DESC
    LIMIT 3
)
SELECT 
    first_name,
    total_orders,
    lifetime_value,
    SNOWFLAKE.CORTEX.COMPLETE(
        'claude-3-5-sonnet',
        'Write a short, friendly loyalty reward email (3-4 sentences) for a pizza restaurant customer named ' 
        || first_name || ' who has ordered ' || total_orders || ' times and spent $' || lifetime_value 
        || '. Thank them and offer them a special deal.'
    ) AS personalized_email
FROM top_customers;

-- Generate response to negative review
SELECT 
    r.review_id,
    r.review_text,
    SNOWFLAKE.CORTEX.COMPLETE(
        'claude-3-5-sonnet',
        'Write a professional, empathetic response (3-4 sentences) from a restaurant manager to this negative review. '
        || 'Apologize, address concerns, and invite them back: ' || r.review_text
    ) AS manager_response
FROM FACT_REVIEW r
WHERE r.overall_rating <= 2
AND r.review_text IS NOT NULL
ORDER BY r.review_date DESC
LIMIT 3;

-- ============================================================
-- PART 2: ML FUNCTIONS - FORECASTING
-- ============================================================

-- --------------------------------------------------------
-- 2.1 SALES FORECASTING
-- Predict future daily sales using ML
-- --------------------------------------------------------

-- Create forecasting model for daily revenue
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST pizza_sales_forecast(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'FACT_DAILY_SALES'),
    TIMESTAMP_COLNAME => 'SALES_DATE',
    TARGET_COLNAME => 'TOTAL_REVENUE',
    SERIES_COLNAME => 'LOCATION_ID'
);

-- Generate 14-day forecast
CALL pizza_sales_forecast!FORECAST(
    FORECASTING_PERIODS => 14,
    CONFIG_OBJECT => {'prediction_interval': 0.95}
);

-- View forecast results
SELECT 
    l.location_name,
    f.ts AS forecast_date,
    ROUND(f.forecast, 2) AS predicted_revenue,
    ROUND(f.lower_bound, 2) AS lower_bound,
    ROUND(f.upper_bound, 2) AS upper_bound
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) f
JOIN DIM_LOCATION l ON f.series::INT = l.location_id
ORDER BY l.location_name, f.ts;

-- --------------------------------------------------------
-- 2.2 ORDER VOLUME FORECASTING
-- Predict daily order counts for staffing
-- --------------------------------------------------------

CREATE OR REPLACE SNOWFLAKE.ML.FORECAST order_volume_forecast(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'FACT_DAILY_SALES'),
    TIMESTAMP_COLNAME => 'SALES_DATE',
    TARGET_COLNAME => 'TOTAL_ORDERS',
    SERIES_COLNAME => 'LOCATION_ID'
);

CALL order_volume_forecast!FORECAST(FORECASTING_PERIODS => 7);

SELECT 
    l.location_name,
    f.ts AS forecast_date,
    DAYNAME(f.ts) AS day_of_week,
    ROUND(f.forecast) AS predicted_orders,
    -- Staffing recommendation based on forecast
    CASE 
        WHEN ROUND(f.forecast) >= 70 THEN 'Full Staff + Extra'
        WHEN ROUND(f.forecast) >= 50 THEN 'Full Staff'
        WHEN ROUND(f.forecast) >= 30 THEN 'Regular Staff'
        ELSE 'Minimum Staff'
    END AS staffing_recommendation
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) f
JOIN DIM_LOCATION l ON f.series::INT = l.location_id
ORDER BY l.location_name, f.ts;

-- ============================================================
-- PART 3: ML FUNCTIONS - ANOMALY DETECTION
-- ============================================================

-- --------------------------------------------------------
-- 3.1 DETECT UNUSUAL SALES PATTERNS
-- Find days with abnormally high/low sales
-- --------------------------------------------------------

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION sales_anomaly_detector(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'FACT_DAILY_SALES'),
    TIMESTAMP_COLNAME => 'SALES_DATE',
    TARGET_COLNAME => 'TOTAL_REVENUE',
    SERIES_COLNAME => 'LOCATION_ID'
);

-- Detect anomalies
CALL sales_anomaly_detector!DETECT_ANOMALIES(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'FACT_DAILY_SALES'),
    TIMESTAMP_COLNAME => 'SALES_DATE',
    TARGET_COLNAME => 'TOTAL_REVENUE',
    SERIES_COLNAME => 'LOCATION_ID',
    CONFIG_OBJECT => {'prediction_interval': 0.99}
);

-- View anomalies with context
SELECT 
    l.location_name,
    a.ts AS anomaly_date,
    DAYNAME(a.ts) AS day_of_week,
    ROUND(a.y, 2) AS actual_revenue,
    ROUND(a.forecast, 2) AS expected_revenue,
    ROUND(a.y - a.forecast, 2) AS deviation,
    a.is_anomaly,
    CASE 
        WHEN a.y > a.upper_bound THEN 'Unusually High'
        WHEN a.y < a.lower_bound THEN 'Unusually Low'
        ELSE 'Normal'
    END AS anomaly_type,
    ds.weather_condition,
    ds.is_holiday
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) a
JOIN DIM_LOCATION l ON a.series::INT = l.location_id
JOIN FACT_DAILY_SALES ds ON a.ts = ds.sales_date AND a.series::INT = ds.location_id
WHERE a.is_anomaly = TRUE
ORDER BY ABS(a.y - a.forecast) DESC;

-- ============================================================
-- PART 4: CORTEX ANALYST - NATURAL LANGUAGE QUERIES
-- ============================================================

-- --------------------------------------------------------
-- 4.1 Setup Cortex Analyst with Semantic Model
-- --------------------------------------------------------

-- Upload semantic model to stage
CREATE STAGE IF NOT EXISTS SEMANTIC_MODELS;
-- Run this in SnowSQL: PUT file://04_semantic_model.yaml @SEMANTIC_MODELS;

-- Example Cortex Analyst queries (run in Streamlit or via API)
/*
-- In a Streamlit app or API call:
response = SNOWFLAKE.CORTEX.ANALYST(
    '@PIZZERIA_DEMO.BELLA_NAPOLI.SEMANTIC_MODELS/04_semantic_model.yaml',
    'What were our top 5 selling pizzas last month?'
);

-- More example questions:
- "How does our weekend revenue compare to weekdays?"
- "Which location has the highest average order value?"
- "Show me the trend in daily orders over the last 30 days"
- "Who are our top 10 customers by lifetime spending?"
- "What percentage of orders are delivery vs pickup?"
- "What's our average rating by location?"
- "Which menu items have the best profit margin?"
*/

-- ============================================================
-- PART 5: ADVANCED ANALYTICS QUERIES
-- ============================================================

-- --------------------------------------------------------
-- 5.1 CUSTOMER SEGMENTATION
-- RFM Analysis (Recency, Frequency, Monetary)
-- --------------------------------------------------------

WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        DATEDIFF(DAY, MAX(o.order_timestamp), CURRENT_TIMESTAMP()) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.total_amount) AS monetary
    FROM DIM_CUSTOMER c
    JOIN FACT_ORDER o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM customer_rfm
)
SELECT 
    customer_name,
    email,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS lifetime_value,
    r_score || f_score || m_score AS rfm_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        ELSE 'Potential Loyalists'
    END AS customer_segment
FROM rfm_scores
ORDER BY monetary DESC
LIMIT 50;

-- --------------------------------------------------------
-- 5.2 MARKET BASKET ANALYSIS
-- What items are frequently ordered together?
-- --------------------------------------------------------

WITH item_pairs AS (
    SELECT 
        a.item_id AS item_a,
        b.item_id AS item_b,
        COUNT(DISTINCT a.order_id) AS pair_count
    FROM FACT_ORDER_ITEM a
    JOIN FACT_ORDER_ITEM b ON a.order_id = b.order_id AND a.item_id < b.item_id
    GROUP BY a.item_id, b.item_id
    HAVING COUNT(DISTINCT a.order_id) >= 10
)
SELECT 
    ma.item_name AS item_1,
    mb.item_name AS item_2,
    p.pair_count AS times_ordered_together,
    ROUND(p.pair_count * 100.0 / (SELECT COUNT(DISTINCT order_id) FROM FACT_ORDER), 2) AS pct_of_orders
FROM item_pairs p
JOIN DIM_MENU_ITEM ma ON p.item_a = ma.item_id
JOIN DIM_MENU_ITEM mb ON p.item_b = mb.item_id
ORDER BY pair_count DESC
LIMIT 20;

-- --------------------------------------------------------
-- 5.3 PEAK HOURS ANALYSIS
-- Identify busiest times for staffing
-- --------------------------------------------------------

SELECT 
    HOUR(order_timestamp) AS hour_of_day,
    CASE 
        WHEN HOUR(order_timestamp) BETWEEN 11 AND 13 THEN 'Lunch'
        WHEN HOUR(order_timestamp) BETWEEN 17 AND 20 THEN 'Dinner'
        ELSE 'Off-Peak'
    END AS meal_period,
    COUNT(*) AS total_orders,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    REPEAT('█', ROUND(COUNT(*) / 100)) AS volume_bar
FROM FACT_ORDER
GROUP BY HOUR(order_timestamp)
ORDER BY hour_of_day;

-- --------------------------------------------------------
-- 5.4 LOCATION COMPARISON DASHBOARD
-- --------------------------------------------------------

SELECT 
    l.location_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    ROUND(AVG(r.overall_rating), 2) AS avg_rating,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(CASE WHEN o.order_type = 'DELIVERY' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delivery_pct,
    ROUND(SUM(CASE WHEN o.order_type = 'DINE_IN' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS dine_in_pct
FROM DIM_LOCATION l
LEFT JOIN FACT_ORDER o ON l.location_id = o.location_id
LEFT JOIN FACT_REVIEW r ON l.location_id = r.location_id
GROUP BY l.location_id, l.location_name
ORDER BY total_revenue DESC;

-- ============================================================
-- PART 6: REAL-TIME OPERATIONS QUERIES
-- ============================================================

-- --------------------------------------------------------
-- 6.1 TODAY'S PERFORMANCE (Live Dashboard)
-- --------------------------------------------------------

SELECT 
    l.location_name,
    COUNT(DISTINCT o.order_id) AS orders_today,
    ROUND(SUM(o.total_amount), 2) AS revenue_today,
    ROUND(AVG(o.total_amount), 2) AS avg_order_today,
    COUNT(DISTINCT CASE WHEN o.order_status = 'PENDING' THEN o.order_id END) AS pending_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'PREPARING' THEN o.order_id END) AS in_kitchen
FROM FACT_ORDER o
JOIN DIM_LOCATION l ON o.location_id = l.location_id
WHERE DATE(o.order_timestamp) = CURRENT_DATE()
GROUP BY l.location_name;

-- --------------------------------------------------------
-- 6.2 INVENTORY ALERTS
-- Items below reorder point
-- --------------------------------------------------------

SELECT 
    l.location_name,
    i.ingredient_name,
    inv.quantity_on_hand,
    inv.reorder_point,
    inv.reorder_quantity,
    CASE 
        WHEN inv.quantity_on_hand <= inv.reorder_point * 0.5 THEN '🔴 CRITICAL'
        WHEN inv.quantity_on_hand <= inv.reorder_point THEN '🟡 REORDER'
        ELSE '🟢 OK'
    END AS stock_status
FROM FACT_INVENTORY inv
JOIN DIM_LOCATION l ON inv.location_id = l.location_id
JOIN DIM_INGREDIENT i ON inv.ingredient_id = i.ingredient_id
WHERE inv.record_date = (SELECT MAX(record_date) FROM FACT_INVENTORY)
AND inv.quantity_on_hand <= inv.reorder_point
ORDER BY stock_status, l.location_name;

COMMIT;
