-- Silver layer: cleaned, typed, constrained tables
USE silver;

-- Drop in reverse dependency order
DROP TABLE IF EXISTS quarantine_order_items;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;

-- Lookup table: category name -> English translation
CREATE TABLE categories (
    product_category_name          VARCHAR(100) PRIMARY KEY,
    product_category_name_english  VARCHAR(100) NOT NULL
);

-- Product catalog, linked to categories
CREATE TABLE products (
    product_id              VARCHAR(50) PRIMARY KEY,
    product_category_name   VARCHAR(100) REFERENCES categories(product_category_name),
    photos_qty                SMALLINT,
    weight_g                  DECIMAL(10,2),
    length_cm                 DECIMAL(10,2),
    height_cm                 DECIMAL(10,2),
    width_cm                  DECIMAL(10,2),
    FOREIGN KEY (product_category_name) REFERENCES categories(product_category_name)
);

-- One row per customer profile
CREATE TABLE customers (
    customer_id          VARCHAR(50) PRIMARY KEY,
    customer_unique_id    VARCHAR(50) NOT NULL,
    zip_code_prefix       VARCHAR(10),
    city                   VARCHAR(100),
    state                  VARCHAR(2)
);

-- One row per order, with delivery-performance fields derived here
CREATE TABLE orders (
    order_id                 VARCHAR(50) PRIMARY KEY,
    customer_id              VARCHAR(50) NOT NULL REFERENCES customers(customer_id),
    order_status              VARCHAR(30) NOT NULL,
    purchase_ts               DATETIME NOT NULL,
    approved_ts                DATETIME,
    delivered_carrier_ts       DATETIME,
    delivered_customer_ts      DATETIME,
    estimated_delivery_date    DATE,
    delivery_days              INT,        -- NULL until actually delivered
    is_delivered                BOOLEAN NOT NULL,
    is_delayed                  BOOLEAN,    -- NULL if not yet delivered
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Line items per order
CREATE TABLE order_items (
    order_id           VARCHAR(50),
    order_item_id       INT,
    product_id           VARCHAR(50) NOT NULL REFERENCES products(product_id),
    seller_id             VARCHAR(50) NOT NULL,
    price                  DECIMAL(10,2) NOT NULL,
    freight_value          DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Holds order_items rows that failed FK/type validation, with a reason
CREATE TABLE quarantine_order_items (
    order_id           VARCHAR(50),
    order_item_id       VARCHAR(10),
    product_id           VARCHAR(50),
    seller_id             VARCHAR(50),
    price                  VARCHAR(20),
    freight_value          VARCHAR(20),
    rejection_reason      VARCHAR(255)
);
