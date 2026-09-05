-- ============================================================
-- Olist E-commerce Analytics
-- 01 - Database Setup and Import Validation
-- Database engine: MySQL 8.0+
-- ============================================================


-- ============================================================
-- 1. Create and select the project database
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE olist_analytics;

SELECT
    DATABASE() AS active_database,
    VERSION() AS mysql_version;


-- ============================================================
-- 2. Source-table documentation
-- ============================================================

/*
The following processed CSV files were imported into MySQL:

1. order_analytics.csv
   -> order_analytics

2. customer_analytics.csv
   -> customer_analytics

3. seller_analytics.csv
   -> seller_analytics

4. order_items_clean.csv
   -> order_items_clean

5. products_clean.csv
   -> products_clean

6. category_translation_clean.csv
   -> category_translation_clean

The files were produced and validated during the Python
data-cleaning and integration workflow.

Tables containing nullable values were loaded through
LOAD DATA LOCAL INFILE into text-based staging columns.
Typed analytical views will be created separately.
*/


-- ============================================================
-- 3. Create the dataset manifest
-- ============================================================

DROP TABLE IF EXISTS sql_dataset_manifest;

CREATE TABLE sql_dataset_manifest (
    dataset_name VARCHAR(100) PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    expected_rows INT NOT NULL,
    key_definition VARCHAR(255) NOT NULL
);

INSERT INTO sql_dataset_manifest (
    dataset_name,
    table_name,
    expected_rows,
    key_definition
)
VALUES
    (
        'order_analytics',
        'order_analytics',
        99441,
        'order_id'
    ),
    (
        'customer_analytics',
        'customer_analytics',
        96096,
        'customer_unique_id'
    ),
    (
        'seller_analytics',
        'seller_analytics',
        3095,
        'seller_id'
    ),
    (
        'order_items_clean',
        'order_items_clean',
        112650,
        'order_id + order_item_id'
    ),
    (
        'products_clean',
        'products_clean',
        32951,
        'product_id'
    ),
    (
        'category_translation_clean',
        'category_translation_clean',
        74,
        'product_category_name'
    );

SELECT *
FROM sql_dataset_manifest
ORDER BY dataset_name;


-- ============================================================
-- 4. Validate imported row counts and key uniqueness
-- ============================================================

WITH import_validation AS (

    SELECT
        'order_analytics' AS dataset_name,
        COUNT(*) AS imported_rows,
        COUNT(DISTINCT order_id) AS unique_key_values
    FROM order_analytics

    UNION ALL

    SELECT
        'customer_analytics',
        COUNT(*),
        COUNT(DISTINCT customer_unique_id)
    FROM customer_analytics

    UNION ALL

    SELECT
        'seller_analytics',
        COUNT(*),
        COUNT(DISTINCT seller_id)
    FROM seller_analytics

    UNION ALL

    SELECT
        'order_items_clean',
        COUNT(*),
        COUNT(
            DISTINCT CONCAT(
                order_id,
                '-',
                order_item_id
            )
        )
    FROM order_items_clean

    UNION ALL

    SELECT
        'products_clean',
        COUNT(*),
        COUNT(DISTINCT product_id)
    FROM products_clean

    UNION ALL

    SELECT
        'category_translation_clean',
        COUNT(*),
        COUNT(
            DISTINCT product_category_name
        )
    FROM category_translation_clean

)

SELECT
    validation.dataset_name,
    validation.imported_rows,
    manifest.expected_rows,
    validation.unique_key_values,
    manifest.key_definition,
    CASE
        WHEN validation.imported_rows
             = manifest.expected_rows
         AND validation.unique_key_values
             = manifest.expected_rows
        THEN 'Passed'
        ELSE 'Failed'
    END AS validation_status
FROM import_validation AS validation
INNER JOIN sql_dataset_manifest AS manifest
    ON validation.dataset_name
       = manifest.dataset_name
ORDER BY validation.dataset_name;


-- ============================================================
-- 5. Confirm that every required table exists
-- ============================================================

SELECT
    manifest.table_name,
    CASE
        WHEN tables.table_name IS NOT NULL
        THEN 'Available'
        ELSE 'Missing'
    END AS table_status
FROM sql_dataset_manifest AS manifest
LEFT JOIN information_schema.tables AS tables
    ON tables.table_schema = DATABASE()
   AND tables.table_name = manifest.table_name
ORDER BY manifest.table_name;


-- ============================================================
-- 6. Review imported column data types
-- ============================================================

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name IN (
      'order_analytics',
      'customer_analytics',
      'seller_analytics',
      'order_items_clean',
      'products_clean',
      'category_translation_clean'
  )
ORDER BY
    table_name,
    ordinal_position;


-- ============================================================
-- End of 01_database_setup.sql
-- Expected result:
-- Six datasets available and all import validations passed.
-- ============================================================















