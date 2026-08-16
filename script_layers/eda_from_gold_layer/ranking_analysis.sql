-- Top 10 products by revenue
USE gold;

SELECT
    f.product_id,
    p.category_english,
    ROUND(SUM(f.price), 2) AS total_revenue,
    COUNT(*)                 AS units_sold
FROM fact_order_items f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY f.product_id, p.category_english
ORDER BY total_revenue DESC
LIMIT 10;

-- Top 10 categories by revenue
SELECT
    p.category_english,
    ROUND(SUM(f.price), 2) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM fact_order_items f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category_english
ORDER BY total_revenue DESC
LIMIT 10;
