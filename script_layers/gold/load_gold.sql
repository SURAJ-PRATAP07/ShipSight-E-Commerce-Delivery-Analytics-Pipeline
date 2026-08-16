/*
====================================================================================
Loading Tables within "gold" Layer.
Sources: silver.* tables. Applies final denormalization (joining the English
category name into products) and pre-aggregates customer behavior so BI tools
never need to run GROUP BY over the full fact table for basic customer stats.
====================================================================================
*/
USE gold;

-- Load dim_products: join in the English category name, no lookup needed at query time
INSERT INTO dim_products
SELECT
    p.product_id,
    c.product_category_name_english,
    p.weight_g,
    p.length_cm,
    p.height_cm,
    p.width_cm
FROM silver.products p
LEFT JOIN silver.categories c ON p.product_category_name = c.product_category_name;

-- Load dim_customers: aggregate order-level spend per unique customer
-- (customer_unique_id, not customer_id — Olist issues a new customer_id per
-- order, so customer_unique_id is the true "one row per person" grain)
INSERT INTO dim_customers
SELECT
    cu.customer_unique_id,
    MAX(cu.city)   AS city,
    MAX(cu.state)  AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spent,
    ROUND(AVG(oi.price + oi.freight_value), 2) AS avg_order_value
FROM silver.customers cu
JOIN silver.orders o ON cu.customer_id = o.customer_id
JOIN silver.order_items oi ON o.order_id = oi.order_id
GROUP BY cu.customer_unique_id;

-- Load fact_order_items: one row per order line item, joined to bring in
-- order-level and customer-level attributes
INSERT INTO fact_order_items
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    cu.customer_unique_id,
    oi.seller_id,
    o.order_status,
    o.purchase_ts,
    oi.price,
    oi.freight_value,
    o.delivery_days,
    o.is_delayed
FROM silver.order_items oi
JOIN silver.orders o ON oi.order_id = o.order_id
JOIN silver.customers cu ON o.customer_id = cu.customer_id;
