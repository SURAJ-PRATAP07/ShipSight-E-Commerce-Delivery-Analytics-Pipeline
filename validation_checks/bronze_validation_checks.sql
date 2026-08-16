-- =====================================================================
-- BRONZE LAYER — DATA QUALITY CHECKS
-- =====================================================================
-- Bronze has no constraints yet, so these checks catch raw issues
-- early — before they get passed into silver transformations.
-- =====================================================================
USE bronze;

-- ---------------------------------------------------------------------
--  product_category_translation
-- ---------------------------------------------------------------------

-- Row count check (expectation ~71)
SELECT COUNT(*) AS total_categories FROM product_category_translation;

-- Null or blank values in key columns
SELECT * FROM product_category_translation
WHERE product_category_name IS NULL OR TRIM(product_category_name) = '';

-- Duplicate category names (no PK enforced yet at this layer)
SELECT product_category_name, COUNT(*)
FROM product_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;


-- ---------------------------------------------------------------------
--  products
-- ---------------------------------------------------------------------

-- Row count check (expectation ~32,951)
SELECT COUNT(*) AS total_products FROM products;

-- Null or blank product_id / category
SELECT * FROM products
WHERE product_id IS NULL OR TRIM(product_id) = '';

-- Duplicate product_id values
SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Categories present in products but missing from the translation lookup
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_translation t
       ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL AND p.product_category_name IS NOT NULL;

-- Values that can't be cast to numeric (would break the silver load)
SELECT * FROM products
WHERE product_weight_g NOT REGEXP '^[0-9]*\\.?[0-9]*$'
   OR product_length_cm NOT REGEXP '^[0-9]*\\.?[0-9]*$';


-- ---------------------------------------------------------------------
--  customers
-- ---------------------------------------------------------------------

-- Row count check (expectation ~99,441)
SELECT COUNT(*) AS total_customers FROM customers;

-- Null values in required fields
SELECT * FROM customers
WHERE customer_id IS NULL OR customer_unique_id IS NULL;

-- Duplicate customer_id (should be unique per order-relationship, not per person)
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ---------------------------------------------------------------------
--  orders
-- ---------------------------------------------------------------------

-- Row count check (expectation ~99,441)
SELECT COUNT(*) AS total_orders FROM orders;

-- Null values in required fields
SELECT * FROM orders
WHERE order_id IS NULL OR customer_id IS NULL OR order_purchase_timestamp IS NULL;

-- Confirm order_status only contains expected values
SELECT DISTINCT order_status FROM orders;

-- Orders marked delivered but missing a delivered_customer_date (logical inconsistency)
SELECT * FROM orders
WHERE order_status = 'delivered'
  AND (order_delivered_customer_date IS NULL OR TRIM(order_delivered_customer_date) = '');

-- Timestamps that can't be cast to DATETIME (would break the silver load)
SELECT * FROM orders
WHERE order_purchase_timestamp NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$';


-- ---------------------------------------------------------------------
--  order_items
-- ---------------------------------------------------------------------

-- Row count check (expectation ~112,650)
SELECT COUNT(*) AS total_order_items FROM order_items;

-- Null values in required fields
SELECT * FROM order_items
WHERE order_id IS NULL OR product_id IS NULL;

-- Duplicate (order_id, order_item_id) pairs at the raw level
SELECT order_id, order_item_id, COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Values that can't be cast to numeric (would break the silver load / get quarantined)
SELECT * FROM order_items
WHERE price NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
   OR freight_value NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';
