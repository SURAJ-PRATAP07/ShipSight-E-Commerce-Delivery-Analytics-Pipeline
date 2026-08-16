-- Monthly revenue and order volume trend
USE gold;

SELECT
    DATE_FORMAT(purchase_ts, '%Y-%m') AS order_month,
    COUNT(DISTINCT order_id)           AS total_orders,
    ROUND(SUM(price), 2)                AS total_revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM fact_order_items
GROUP BY order_month
ORDER BY order_month;
