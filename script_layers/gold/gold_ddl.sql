/*
====================================================================================
Defining Tables within "gold" Layer using DDL.
Gold implements a star schema: dimension tables surround a central fact table,
denormalized for fast analytical queries with minimal joins. Sourced from silver.
====================================================================================
*/
USE gold;

-- Drop in reverse dependency order (fact before dimensions)
DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_customers;

-- Dimension: products, denormalized with English category name pre-joined
CREATE TABLE dim_products (
    product_id       VARCHAR(50) PRIMARY KEY,
    category_english   VARCHAR(100),   -- joined in, no need to hit silver.categories at query time
    weight_g            DECIMAL(10,2),
    length_cm            DECIMAL(10,2),
    height_cm             DECIMAL(10,2),
    width_cm               DECIMAL(10,2)
);

-- Dimension: customers, one row per unique customer with pre-aggregated behavioral stats
CREATE TABLE dim_customers (
    customer_unique_id   VARCHAR(50) PRIMARY KEY,
    city                   VARCHAR(100),
    state                   VARCHAR(2),
    total_orders             INT,
    total_spent               DECIMAL(12,2),
    avg_order_value            DECIMAL(10,2)
);

-- Fact: one row per order line item (grain = order_id + order_item_id)
CREATE TABLE fact_order_items (
    order_id             VARCHAR(50),
    order_item_id         INT,
    product_id             VARCHAR(50),
    customer_unique_id      VARCHAR(50),
    seller_id                VARCHAR(50),
    order_status               VARCHAR(30),
    purchase_ts                 DATETIME,
    price                         DECIMAL(10,2),
    freight_value                 DECIMAL(10,2),
    delivery_days                  INT,
    is_delayed                       BOOLEAN,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (customer_unique_id) REFERENCES dim_customers(customer_unique_id)
);
