/*
====================================================================================
Defining Tables within "bronze" Layer using DDL.
Every column is stored as VARCHAR/TEXT to guarantee raw source data loads without
truncation, type coercion errors, or silent data loss. Casting and validation
happen downstream in the silver layer.
====================================================================================
*/

USE bronze;

-- Lookup: maps Portuguese category names to their English translation
DROP TABLE IF EXISTS product_category_translation;
CREATE TABLE product_category_translation (
    product_category_name          VARCHAR(100),
    product_category_name_english  VARCHAR(100),
    _ingested_at                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- load timestamp
    _source_file                   VARCHAR(255)                          -- lineage: originating CSV
);

-- Raw product catalog
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id                  VARCHAR(50),
    product_category_name       VARCHAR(100),
    product_name_lenght         VARCHAR(20),
    product_description_lenght  VARCHAR(20),
    product_photos_qty          VARCHAR(20),
    product_weight_g            VARCHAR(20),
    product_length_cm           VARCHAR(20),
    product_height_cm           VARCHAR(20),
    product_width_cm            VARCHAR(20),
    _ingested_at                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _source_file                 VARCHAR(255)
);

-- Raw customers
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id               VARCHAR(50),
    customer_unique_id        VARCHAR(50),
    customer_zip_code_prefix  VARCHAR(20),
    customer_city             VARCHAR(100),
    customer_state            VARCHAR(10),
    _ingested_at                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _source_file                VARCHAR(255)
);

-- Raw orders
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id                        VARCHAR(50),
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(30),
    order_purchase_timestamp        VARCHAR(30),
    order_approved_at               VARCHAR(30),
    order_delivered_carrier_date    VARCHAR(30),
    order_delivered_customer_date   VARCHAR(30),
    order_estimated_delivery_date   VARCHAR(30),
    _ingested_at                     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _source_file                     VARCHAR(255)
);

-- Raw order line items
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id             VARCHAR(50),
    order_item_id        VARCHAR(10),
    product_id            VARCHAR(50),
    seller_id             VARCHAR(50),
    shipping_limit_date   VARCHAR(30),
    price                 VARCHAR(20),
    freight_value         VARCHAR(20),
    _ingested_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _source_file            VARCHAR(255)
);
