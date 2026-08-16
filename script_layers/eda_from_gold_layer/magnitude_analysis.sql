-- Total revenue and order count by customer state
USE gold;

SELECT
    c.state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.price), 2)      AS total_revenue
FROM fact_order_items f
JOIN dim_customers c ON f.customer_unique_id = c.customer_unique_id
GROUP BY c.state
ORDER BY total_revenue DESC;
