# Olist Medallion Analytics

An end-to-end SQL data pipeline that transforms raw Brazilian e-commerce order
data into an analytics-ready star schema, using the **Medallion Architecture**
(Bronze → Silver → Gold) on **MySQL**.

## Project Overview

This project simulates how a data team would take messy, real-world order
data and progressively refine it into a trustworthy analytical layer:

- **Bronze** — raw data loaded as-is, no transformation, full lineage tracking
- **Silver** — cleaned, typed, deduplicated, and referentially validated
- **Gold** — a business-ready star schema (fact + dimension tables) built
  for reporting

On top of the gold layer sits a set of exploratory SQL analyses answering
real business questions: revenue trends, customer value segmentation, and
delivery performance by region.

**Dataset:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(~100k orders, 2016–2018)

---

## Architecture

```
Raw CSVs (Kaggle)
      │
      ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   BRONZE    │────▶│    SILVER    │────▶│    GOLD     │
│  raw, typed │     │ cleaned,     │     │ star schema │
│  as VARCHAR │     │ typed, FK-   │     │ fact + dims │
│  + lineage  │     │ validated    │     │             │
└─────────────┘     └──────────────┘     └─────────────┘
                            │
                            ▼
                   quarantine_order_items
                (bad rows kept + labeled,
                     never silently dropped)
```

## Repository Structure

```
Olist-Medallion-Analytics/
├── datasets/                     # place downloaded Olist CSVs here
├── script_layers/
│   ├── init_database.sql         # creates bronze / silver / gold databases
│   ├── bronze/
│   │   ├── bronze_ddl.sql
│   │   └── load_bronze.sql
│   ├── silver/
│   │   ├── silver_ddl.sql
│   │   └── load_silver.sql
│   ├── gold/
│   │   ├── gold_ddl.sql
│   │   └── load_gold.sql
│   └── eda_from_gold_layer/      # business-question SQL scripts on gold
│       ├── database_exploration.sql
│       ├── change_over_time_analysis.sql
│       ├── cumulative_analysis.sql
│       ├── customer_segmentation.sql
│       ├── delivery_performance_analysis.sql
│       ├── magnitude_analysis.sql
│       ├── ranking_analysis.sql
│       └── data_range_exploration.sql
├── validation_checks/
│   ├── bronze_validation_checks.sql
│   └── silver_validation_checks.sql
└── README.md
```

## Data Model (Gold Layer)

| Table | Grain | Description |
|---|---|---|
| `dim_products` | one row per product | product with English category name, dimensions, weight |
| `dim_customers` | one row per unique person | pre-aggregated total orders, total spend, avg order value |
| `fact_order_items` | one row per order line item | price, freight, delivery days, delay flag |

`customer_unique_id` (not `customer_id`) is used as the customer grain,
since Olist assigns a new `customer_id` per order — a data quirk that has
to be caught and handled deliberately, or customer-level metrics silently
inflate.

## Key Engineering Decisions

- **Quarantine over silent drop** — `order_items` rows that fail FK or type
  validation are routed to `silver.quarantine_order_items` with a documented
  `rejection_reason`, not discarded. The silver validation script cross-checks
  that `good_rows + quarantined_rows` reconciles back to the bronze row count.
- **Derived fields pushed upstream** — `delivery_days` and `is_delayed` are
  computed once in the silver layer, so every downstream gold query and BI
  report uses identical delivery-performance logic.
- **Lineage columns in bronze** — every bronze table carries `_ingested_at`
  and `_source_file`, so any row can be traced back to when and from which
  file it was loaded.

## How to Run

**Prerequisites:** MySQL 8.0+ (needed for window functions used in `load_silver.sql`)

1. Download the dataset from Kaggle and place these files in `/datasets`:
   - `product_category_name_translation.csv`
   - `olist_products_dataset.csv`
   - `olist_customers_dataset.csv`
   - `olist_orders_dataset.csv`
   - `olist_order_items_dataset.csv`

2. Run the scripts in order:
   ```sql
   SOURCE script_layers/init_database.sql;
   SOURCE script_layers/bronze/bronze_ddl.sql;
   SOURCE script_layers/bronze/load_bronze.sql;
   SOURCE script_layers/silver/silver_ddl.sql;
   SOURCE script_layers/silver/load_silver.sql;
   SOURCE script_layers/gold/gold_ddl.sql;
   SOURCE script_layers/gold/load_gold.sql;
   ```

3. Run the validation checks after each layer loads:
   ```sql
   SOURCE validation_checks/bronze_validation_checks.sql;
   SOURCE validation_checks/silver_validation_checks.sql;
   ```

4. Explore the gold layer:
   ```sql
   SOURCE script_layers/eda_from_gold_layer/ranking_analysis.sql;
   ```

> `LOAD DATA LOCAL INFILE` requires local_infile enabled on both client and
> server: `SET GLOBAL local_infile = 1;`

## Skills Demonstrated

- Data modeling: Medallion architecture (Bronze/Silver/Gold), star schema design
- SQL: window functions, CTEs, referential integrity, type casting, REGEXP validation
- Data quality: automated validation scripts with row-count expectations and reconciliation checks
- ELT design: quarantine pattern for invalid data instead of silent drops
- Analytics: cohort/segment analysis, time-series trend analysis, geographic performance analysis

## Future Enhancements

- Add `olist_order_reviews_dataset.csv` and `olist_sellers_dataset.csv` for
  review-sentiment and seller-performance analysis
- Orchestrate the layer sequence with Airflow or a simple Python runner
- Add a `dim_date` table for cleaner time-intelligence queries
- Connect the gold layer to Power BI / Tableau for a dashboard deliverable
- Add CI (GitHub Actions) to lint and dry-run the SQL on push
