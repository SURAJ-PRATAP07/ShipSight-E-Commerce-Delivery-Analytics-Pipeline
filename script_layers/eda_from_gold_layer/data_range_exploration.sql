-- Understand the boundaries of the dataset before drawing conclusions
USE gold;

-- Date range covered
SELECT MIN(purchase_ts) AS earliest_order, MAX(purchase_ts) AS latest_order
FROM fact_order_items;

-- Price range
SELECT MIN(price) AS min_price, MAX(price) AS max_price, ROUND(AVG(price), 2) AS avg_price
FROM fact_order_items;

-- Delivery time range (excluding undelivered orders)
SELECT MIN(delivery_days) AS fastest_delivery, MAX(delivery_days) AS slowest_delivery
FROM fact_order_items
WHERE delivery_days IS NOT NULL;
