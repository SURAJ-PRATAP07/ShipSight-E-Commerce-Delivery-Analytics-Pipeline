-- =====================================================================
-- SILVER LAYER — DATA QUALITY CHECKS
-- =====================================================================
-- Purpose: 1. Verify that every silver table is internally consistent
--             and correctly typed
--          2. Free of duplicates or logically impossible values
--             before building the gold layer on top
--          3. Data range mismatches
--          4. Data consistency between dependent tables
--          5. Quarantine reconciliation — every bronze row must be
--             accounted for as either "good" or "quarantined"
-- =====================================================================
USE silver;

-- ---------------------------------------------------------------------
--  silver.categories
-- ---------------------------------------------------------------------

-- Check 1: No duplicate category names (should be impossible due to PK)
SELECT product_category_name, COUNT(*)
FROM categories
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- Check 2: No blank English translations
SELECT * FROM categories
WHERE product_category_name_english IS NULL OR TRIM(product_category_name_english) = '';


-- ---------------------------------------------------------------------
--  silver.products
-- ---------------------------------------------------------------------

-- Check 1: No duplicate product_ids
SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check 2: Every product's category actually exists in silver.categories
-- (redundant with the FK constraint, kept explicit for readability)
SELECT p.product_id, p.product_category_name
FROM products p
LEFT JOIN categories c ON p.product_category_name = c.product_category_name
WHERE p.product_category_name IS NOT NULL AND c.product_category_name IS NULL;

-- Check 3: No negative dimensions/weights
SELECT * FROM products
WHERE weight_g < 0 OR length_cm < 0 OR height_cm < 0 OR width_cm < 0;


-- ---------------------------------------------------------------------
--  silver.customers
-- ---------------------------------------------------------------------

-- Check 1: No duplicate customer_ids
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check 2: state should always be a 2-letter Brazilian state code
SELECT DISTINCT state FROM customers WHERE LENGTH(state) <> 2;


-- ---------------------------------------------------------------------
--  silver.orders
-- ---------------------------------------------------------------------

-- Check 1: No duplicate order_ids
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check 2: delivery_days must be non-negative when present
SELECT * FROM orders WHERE delivery_days < 0;

-- Check 3: is_delivered must be perfectly consistent with delivery_days
-- being non-null — these two counts should match exactly
SELECT COUNT(*) AS delivered_true FROM orders WHERE is_delivered = TRUE;
SELECT COUNT(*) AS delivery_days_not_null FROM orders WHERE delivery_days IS NOT NULL;

-- Check 4: every customer_id here must exist in silver.customers
SELECT o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check 5: Row count sanity check (expect close to 99,441)
SELECT COUNT(*) AS total_orders FROM orders;


-- ---------------------------------------------------------------------
--  silver.order_items
-- ---------------------------------------------------------------------

-- Check 1: No duplicate (order_id, order_item_id) pairs
SELECT order_id, order_item_id, COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Check 2: price and freight_value must be non-negative
SELECT * FROM order_items WHERE price < 0 OR freight_value < 0;

-- Check 3: every order_id here must exist in silver.orders
SELECT oi.order_id
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check 4: every product_id here must exist in silver.products
SELECT oi.product_id
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check 5: Row count sanity check
SELECT COUNT(*) AS total_order_items FROM order_items;


-- ---------------------------------------------------------------------
--  silver.quarantine_order_items
-- ---------------------------------------------------------------------

-- Check 1: Total quarantined row count — should be a small fraction
-- of the original ~112,650 bronze rows, ideally close to 0
SELECT COUNT(*) AS total_quarantined FROM quarantine_order_items;

-- Check 2: Breakdown of rejection reasons
SELECT rejection_reason, COUNT(*)
FROM quarantine_order_items
GROUP BY rejection_reason;

-- Check 3: Reconciliation — good rows + quarantined rows should sum
-- close to the original bronze row count of ~112,650
SELECT
    (SELECT COUNT(*) FROM order_items) AS good_rows,
    (SELECT COUNT(*) FROM quarantine_order_items) AS quarantined_rows,
    (SELECT COUNT(*) FROM order_items)
        + (SELECT COUNT(*) FROM quarantine_order_items) AS total_accounted_for;
