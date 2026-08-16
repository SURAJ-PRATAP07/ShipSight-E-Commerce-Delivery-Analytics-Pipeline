-- Running total of revenue by month
USE gold;

SELECT
    order_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY order_month) AS running_total_revenue
FROM (
    SELECT
        DATE_FORMAT(purchase_ts, '%Y-%m') AS order_month,
        ROUND(SUM(price), 2)               AS monthly_revenue
    FROM fact_order_items
    GROUP BY order_month
) monthly
ORDER BY order_month;
