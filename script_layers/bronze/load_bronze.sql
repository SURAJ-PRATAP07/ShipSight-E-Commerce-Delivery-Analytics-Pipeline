/*
====================================================================================
Loading raw CSVs into the "bronze" layer.
====================================================================================
Download the Olist dataset from Kaggle:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Place these files in /datasets before running this script:
  - product_category_name_translation.csv
  - olist_products_dataset.csv
  - olist_customers_dataset.csv
  - olist_orders_dataset.csv
  - olist_order_items_dataset.csv

NOTE: LOAD DATA LOCAL INFILE requires the client and server to both allow
local_infile. If disabled, run:  SET GLOBAL local_infile = 1;
Adjust the file paths below to match your local /datasets directory.
====================================================================================
*/

USE bronze;

TRUNCATE TABLE product_category_translation;
LOAD DATA LOCAL INFILE '/datasets/product_category_name_translation.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, product_category_name_english)
SET _source_file = 'product_category_name_translation.csv';

TRUNCATE TABLE products;
LOAD DATA LOCAL INFILE '/datasets/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, product_name_lenght, product_description_lenght,
 product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
SET _source_file = 'olist_products_dataset.csv';

TRUNCATE TABLE customers;
LOAD DATA LOCAL INFILE '/datasets/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SET _source_file = 'olist_customers_dataset.csv';

TRUNCATE TABLE orders;
LOAD DATA LOCAL INFILE '/datasets/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at,
 order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
SET _source_file = 'olist_orders_dataset.csv';

TRUNCATE TABLE order_items;
LOAD DATA LOCAL INFILE '/datasets/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
SET _source_file = 'olist_order_items_dataset.csv';
