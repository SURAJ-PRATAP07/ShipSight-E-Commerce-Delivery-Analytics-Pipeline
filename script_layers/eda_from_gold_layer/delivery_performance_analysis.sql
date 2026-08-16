-- Delivery performance by state — average delivery time and delay rate.
-- This analysis is only possible because Olist orders carry delivery
-- timestamps; there's no equivalent in a grocery-reorder dataset like
-- Instacart, so this is a genuinely different insight than a market-
-- basket-style project can produce.
USE gold;

SELECT
    c.state,
    COUNT(DISTINCT f.order_id)                AS total_orders,
    ROUND(AVG(f.delivery_days), 1)              AS avg_delivery_days,
    ROUND(100 * SUM(f.is_delayed) / COUNT(DISTINCT f.order_id), 2) AS pct_orders_delayed
FROM fact_order_items f
JOIN dim_customers c ON f.customer_unique_id = c.customer_unique_id
WHERE f.delivery_days IS NOT NULL
GROUP BY c.state
ORDER BY pct_orders_delayed DESC;
