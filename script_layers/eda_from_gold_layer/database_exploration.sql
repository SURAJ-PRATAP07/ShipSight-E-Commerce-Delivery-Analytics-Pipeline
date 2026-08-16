-- Explore the gold-layer objects available for analysis
USE gold;

SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'gold';

-- Explore all product categories
SELECT DISTINCT category_english FROM dim_products ORDER BY 1;

-- Explore all customer states
SELECT DISTINCT state FROM dim_customers ORDER BY 1;
