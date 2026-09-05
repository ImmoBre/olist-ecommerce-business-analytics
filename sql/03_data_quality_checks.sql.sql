-- ============================================================
-- Olist E-commerce Analytics
-- 03 - Data Quality Checks
-- Database engine: MySQL 8.0+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. Primary-key completeness and uniqueness
-- ============================================================

WITH key_checks AS (

    SELECT
        'Missing order IDs' AS validation_check,
        SUM(order_id IS NULL) AS result,
        0 AS expected
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Duplicate order IDs',
        COUNT(*) - COUNT(DISTINCT order_id),
        0
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Missing customer IDs',
        SUM(customer_unique_id IS NULL),
        0
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Duplicate customer IDs',
        COUNT(*)
        - COUNT(DISTINCT customer_unique_id),
        0
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Missing seller IDs',
        SUM(seller_id IS NULL),
        0
    FROM vw_seller_analytics

    UNION ALL

    SELECT
        'Duplicate seller IDs',
        COUNT(*) - COUNT(DISTINCT seller_id),
        0
    FROM vw_seller_analytics

    UNION ALL

    SELECT
        'Missing product IDs',
        SUM(product_id IS NULL),
        0
    FROM vw_products

    UNION ALL

    SELECT
        'Duplicate product IDs',
        COUNT(*) - COUNT(DISTINCT product_id),
        0
    FROM vw_products

    UNION ALL

    SELECT
        'Missing order-item keys',
        SUM(
            order_id IS NULL
            OR order_item_id IS NULL
        ),
        0
    FROM vw_order_items

    UNION ALL

    SELECT
        'Duplicate order-item keys',
        COUNT(*)
        - COUNT(
            DISTINCT CONCAT(
                order_id,
                '-',
                order_item_id
            )
        ),
        0
    FROM vw_order_items
)

SELECT
    validation_check,
    result,
    expected,
    CASE
        WHEN result = expected
        THEN 'Passed'
        ELSE 'Failed'
    END AS status
FROM key_checks
ORDER BY validation_check;

-- ============================================================
-- 2. Referential-integrity checks
-- ============================================================

WITH referential_checks AS (

    SELECT
        'Orders missing customer match'
            AS validation_check,
        COUNT(*) AS result,
        0 AS expected
    FROM vw_order_analytics AS orders
    LEFT JOIN vw_customer_analytics AS customers
        ON orders.customer_unique_id
           = customers.customer_unique_id
    WHERE customers.customer_unique_id IS NULL

    UNION ALL

    SELECT
        'Order items missing order match',
        COUNT(*),
        0
    FROM vw_order_items AS items
    LEFT JOIN vw_order_analytics AS orders
        ON items.order_id = orders.order_id
    WHERE orders.order_id IS NULL

    UNION ALL

    SELECT
        'Order items missing product match',
        COUNT(*),
        0
    FROM vw_order_items AS items
    LEFT JOIN vw_products AS products
        ON items.product_id = products.product_id
    WHERE products.product_id IS NULL

    UNION ALL

    SELECT
        'Order items missing seller match',
        COUNT(*),
        0
    FROM vw_order_items AS items
    LEFT JOIN vw_seller_analytics AS sellers
        ON items.seller_id = sellers.seller_id
    WHERE sellers.seller_id IS NULL

    UNION ALL

    SELECT
        'Products missing category translation',
        COUNT(*),
        0
    FROM vw_products AS products
    LEFT JOIN vw_category_translation AS translations
        ON products.product_category_name
           = translations.product_category_name
    WHERE translations.product_category_name IS NULL
)

SELECT
    validation_check,
    result,
    expected,
    CASE
        WHEN result = expected
        THEN 'Passed'
        ELSE 'Failed'
    END AS status
FROM referential_checks
ORDER BY validation_check;

-- ============================================================
-- 3. Monetary-value reconciliation
-- ============================================================

WITH value_checks AS (

    SELECT
        'Order-level product value'
            AS validation_check,
        SUM(product_value) AS result,
        CAST(
            13591643.70 AS DECIMAL(18, 2)
        ) AS expected
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Item-level product value',
        SUM(price),
        CAST(
            13591643.70 AS DECIMAL(18, 2)
        )
    FROM vw_order_items

    UNION ALL

    SELECT
        'Order-level freight value',
        SUM(freight_value),
        CAST(
            2251909.54 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Item-level freight value',
        SUM(freight_value),
        CAST(
            2251909.54 AS DECIMAL(18, 2)
        )
    FROM vw_order_items

    UNION ALL

    SELECT
        'Order-level item total value',
        SUM(item_total_value),
        CAST(
            15843553.24 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Order-level payment value',
        SUM(total_payment_value),
        CAST(
            16008872.12 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics
)

SELECT
    validation_check,
    result,
    expected,
    result - expected AS difference,
    CASE
        WHEN ABS(result - expected) < 0.01
        THEN 'Passed'
        ELSE 'Failed'
    END AS status
FROM value_checks
ORDER BY validation_check;

-- ============================================================
-- 4. Value-range validation
-- ============================================================

WITH range_checks AS (

    SELECT
        'Negative product values'
            AS validation_check,
        COUNT(*) AS result,
        0 AS expected
    FROM vw_order_analytics
    WHERE product_value < 0

    UNION ALL

    SELECT
        'Negative freight values',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE freight_value < 0

    UNION ALL

    SELECT
        'Negative payment values',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE total_payment_value < 0

    UNION ALL

    SELECT
        'Invalid latest review scores',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE latest_review_score IS NOT NULL
      AND latest_review_score NOT BETWEEN 1 AND 5

    UNION ALL

    SELECT
        'Invalid average review scores',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE average_review_score IS NOT NULL
      AND average_review_score NOT BETWEEN 1 AND 5

    UNION ALL

    SELECT
        'Negative delivery durations',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE is_valid_for_delivery_analysis = 1
      AND delivery_days < 0

    UNION ALL

    SELECT
        'Invalid customer-state codes',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE customer_state IS NOT NULL
      AND CHAR_LENGTH(customer_state) <> 2

    UNION ALL

    SELECT
        'Invalid seller-state codes',
        COUNT(*),
        0
    FROM vw_seller_analytics
    WHERE seller_state IS NOT NULL
      AND CHAR_LENGTH(seller_state) <> 2
)

SELECT
    validation_check,
    result,
    expected,
    CASE
        WHEN result = expected
        THEN 'Passed'
        ELSE 'Failed'
    END AS status
FROM range_checks
ORDER BY validation_check;


-- ============================================================
-- 5. Document known timestamp-quality flags
-- ============================================================

SELECT
    COUNT(*) AS recorded_orders,

    SUM(carrier_before_purchase)
        AS carrier_before_purchase,

    SUM(delivery_before_purchase)
        AS delivery_before_purchase,

    SUM(delivery_before_carrier)
        AS delivery_before_carrier,

    SUM(has_invalid_timestamp_sequence)
        AS orders_with_invalid_sequence,

    SUM(is_valid_for_delivery_analysis)
        AS valid_delivery_analysis_orders

FROM vw_order_analytics;


-- ============================================================
-- 6. Related-data coverage
-- ============================================================

SELECT
    COUNT(*) AS recorded_orders,

    SUM(has_order_items)
        AS orders_with_items,

    COUNT(*) - SUM(has_order_items)
        AS orders_without_items,

    SUM(has_payment)
        AS orders_with_payment,

    COUNT(*) - SUM(has_payment)
        AS orders_without_payment,

    SUM(has_review)
        AS orders_with_reviews,

    COUNT(*) - SUM(has_review)
        AS orders_without_reviews,

    SUM(is_delivered_order)
        AS delivered_orders,

    SUM(is_valid_for_delivery_analysis)
        AS valid_delivery_analysis_orders

FROM vw_order_analytics;





































