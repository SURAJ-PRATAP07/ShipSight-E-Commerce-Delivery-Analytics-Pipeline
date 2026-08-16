-- Segment customers into spend tiers based on total_spent
USE gold;

SELECT
    CASE
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent >= 300  THEN 'Mid Value'
        ELSE 'Low Value'
    END AS spend_segment,
    COUNT(*)                    AS num_customers,
    ROUND(AVG(total_spent), 2)   AS avg_spent_in_segment,
    ROUND(AVG(total_orders), 2)   AS avg_orders_in_segment
FROM dim_customers
GROUP BY spend_segment
ORDER BY avg_spent_in_segment DESC;
