-- =============================================================
-- Create Databases (MySQL uses DATABASE = SCHEMA)
-- =============================================================
-- Purpose:
-- This script sets up three separate databases representing the
-- three Medallion layers: 'bronze', 'silver', and 'gold'.
-- Cross-database joins are used throughout (e.g. silver.orders
-- joining bronze.orders) since all three live on the same server.

DROP DATABASE IF EXISTS bronze;
DROP DATABASE IF EXISTS silver;
DROP DATABASE IF EXISTS gold;

CREATE DATABASE bronze;
CREATE DATABASE silver;
CREATE DATABASE gold;
