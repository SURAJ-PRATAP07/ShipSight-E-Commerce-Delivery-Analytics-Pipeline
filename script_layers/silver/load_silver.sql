-- =====================================================================
-- OLIST MEDALLION ARCHITECTURE — SILVER LAYER
-- =====================================================================
-- Purpose : Transform raw bronze data into cleaned, typed, and
--           referentially-validated tables ready for the gold-layer
--           star schema and analytics.
--
-- Source  : bronze.* (raw, VARCHAR-typed, unvalidated tables)
-- Target  : silver.* (typed, constrained, deduplicated tables)
-- Key principles applied in this layer:
--   1. Type enforcement      -> cast VARCHAR to proper INT/DECIMAL/DATETIME
--   2. Deduplication         -> ROW_NUMBER() window function, keep rank 1
--   3. Null handling         -> NULLIF to convert blank strings to real NULLs
--   4. Referential integrity -> enforce FK relationships via WHERE filters
--   5. Quarantine            -> orphaned/invalid order_items rows go to a
--      quarantine table with a documented reason instead of being dropped
--   6. Derived fields        -> delivery_days / is_delayed computed here so
--      downstream gold queries never need to touch raw timestamp columns
-- =====================================================================

USE silver;

-- ---------------------------------------------------------------------
-- silver.categories
-- ---------------------------------------------------------------------
INSERT INTO categories
SELECT DISTINCT product_category_name, product_category_name_english
FROM bronze.product_category_translation
WHERE product_category_name IS NOT NULL
  AND TRIM(product_category_name) <> '';

-- ---------------------------------------------------------------------
-- silver.products
-- ---------------------------------------------------------------------
-- Casts numeric fields, deduplicates by product_id, only keeps products
-- whose category actually exists in the translation lookup (categories
-- missing a translation are dropped — a documented scope decision, since
-- there is no quarantine table for a dimension this small).
INSERT INTO products
SELECT product_id, product_category_name, photos_qty, weight_g, length_cm, height_cm, width_cm
FROM (
    SELECT
        b.product_id,
        b.product_category_name,
        CAST(NULLIF(b.product_photos_qty, '') AS SIGNED)  AS photos_qty,
        CAST(NULLIF(b.product_weight_g, '') AS DECIMAL(10,2)) AS weight_g,
        CAST(NULLIF(b.product_length_cm, '') AS DECIMAL(10,2)) AS length_cm,
        CAST(NULLIF(b.product_height_cm, '') AS DECIMAL(10,2)) AS height_cm,
        CAST(NULLIF(b.product_width_cm, '') AS DECIMAL(10,2))  AS width_cm,
        ROW_NUMBER() OVER (PARTITION BY b.product_id ORDER BY b.product_id) AS rn
    FROM bronze.products b
    WHERE b.product_category_name IN (SELECT product_category_name FROM categories)
) t
WHERE rn = 1;

-- ---------------------------------------------------------------------
-- silver.customers
-- ---------------------------------------------------------------------
INSERT INTO customers
SELECT customer_id, customer_unique_id, zip_code_prefix, city, state
FROM (
    SELECT
        b.customer_id,
        b.customer_unique_id,
        b.customer_zip_code_prefix AS zip_code_prefix,
        TRIM(b.customer_city)       AS city,
        UPPER(TRIM(b.customer_state)) AS state,
        ROW_NUMBER() OVER (PARTITION BY b.customer_id ORDER BY b.customer_id) AS rn
    FROM bronze.customers b
    WHERE b.customer_id IS NOT NULL AND b.customer_unique_id IS NOT NULL
) t
WHERE rn = 1;

-- ---------------------------------------------------------------------
-- silver.orders
-- ---------------------------------------------------------------------
-- Derives is_delivered / delivery_days / is_delayed directly from the raw
-- timestamp columns, so every downstream query gets consistent logic.
INSERT INTO orders
SELECT order_id, customer_id, order_status, purchase_ts, approved_ts,
       delivered_carrier_ts, delivered_customer_ts, estimated_delivery_date,
       delivery_days, is_delivered, is_delayed
FROM (
    SELECT
        b.order_id,
        b.customer_id,
        b.order_status,
        CAST(b.order_purchase_timestamp AS DATETIME)                       AS purchase_ts,
        CAST(NULLIF(b.order_approved_at, '') AS DATETIME)                  AS approved_ts,
        CAST(NULLIF(b.order_delivered_carrier_date, '') AS DATETIME)       AS delivered_carrier_ts,
        CAST(NULLIF(b.order_delivered_customer_date, '') AS DATETIME)      AS delivered_customer_ts,
        CAST(b.order_estimated_delivery_date AS DATE)                      AS estimated_delivery_date,
        CASE WHEN b.order_delivered_customer_date IS NOT NULL AND TRIM(b.order_delivered_customer_date) <> ''
             THEN DATEDIFF(CAST(b.order_delivered_customer_date AS DATETIME), CAST(b.order_purchase_timestamp AS DATETIME))
        END AS delivery_days,
        (b.order_delivered_customer_date IS NOT NULL AND TRIM(b.order_delivered_customer_date) <> '') AS is_delivered,
        CASE WHEN b.order_delivered_customer_date IS NOT NULL AND TRIM(b.order_delivered_customer_date) <> ''
             THEN CAST(b.order_delivered_customer_date AS DATETIME) > CAST(b.order_estimated_delivery_date AS DATETIME)
        END AS is_delayed,
        ROW_NUMBER() OVER (PARTITION BY b.order_id ORDER BY b.order_id) AS rn
    FROM bronze.orders b
    WHERE b.customer_id IN (SELECT customer_id FROM customers)
) t
WHERE rn = 1;

-- ---------------------------------------------------------------------
-- silver.order_items
-- ---------------------------------------------------------------------
-- Splits bronze.order_items into two destinations:
--   (a) rows whose order_id AND product_id both exist in silver
--       -> inserted into silver.order_items
--   (b) rows that fail either check, or fail numeric casting
--       -> inserted into silver.quarantine_order_items with a reason
-- This guarantees FK constraints on silver.order_items will never fail,
-- since every row inserted has already been validated.
-- ---------------------------------------------------------------------

-- (a) GOOD ROWS
INSERT INTO order_items
SELECT order_id, order_item_id, product_id, seller_id, price, freight_value
FROM (
    SELECT
        b.order_id,
        CAST(b.order_item_id AS SIGNED) AS order_item_id,
        b.product_id,
        b.seller_id,
        CAST(b.price AS DECIMAL(10,2))          AS price,
        CAST(b.freight_value AS DECIMAL(10,2))  AS freight_value,
        ROW_NUMBER() OVER (PARTITION BY b.order_id, b.order_item_id ORDER BY b.order_id) AS rn
    FROM bronze.order_items b
    WHERE b.order_id IN (SELECT order_id FROM orders)
      AND b.product_id IN (SELECT product_id FROM products)
      AND b.order_item_id REGEXP '^[0-9]+$'
      AND b.price REGEXP '^[0-9]+(\\.[0-9]+)?$'
      AND b.freight_value REGEXP '^[0-9]+(\\.[0-9]+)?$'
) t
WHERE rn = 1;

-- (b) QUARANTINED ROWS — order_id missing from silver.orders
INSERT INTO quarantine_order_items
SELECT order_id, order_item_id, product_id, seller_id, price, freight_value,
       'order_id not found in silver.orders'
FROM bronze.order_items b
WHERE b.order_id NOT IN (SELECT order_id FROM orders);

-- (b) QUARANTINED ROWS — product_id missing from silver.products
INSERT INTO quarantine_order_items
SELECT order_id, order_item_id, product_id, seller_id, price, freight_value,
       'product_id not found in silver.products'
FROM bronze.order_items b
WHERE b.order_id IN (SELECT order_id FROM orders)
  AND b.product_id NOT IN (SELECT product_id FROM products);

-- (b) QUARANTINED ROWS — numeric fields fail cast
INSERT INTO quarantine_order_items
SELECT order_id, order_item_id, product_id, seller_id, price, freight_value,
       'non-numeric price, freight_value, or order_item_id'
FROM bronze.order_items b
WHERE b.order_id IN (SELECT order_id FROM orders)
  AND b.product_id IN (SELECT product_id FROM products)
  AND NOT (
        b.order_item_id REGEXP '^[0-9]+$'
    AND b.price REGEXP '^[0-9]+(\\.[0-9]+)?$'
    AND b.freight_value REGEXP '^[0-9]+(\\.[0-9]+)?$'
  );
