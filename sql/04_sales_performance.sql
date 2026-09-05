-- ============================================================
-- Olist E-commerce Analytics
-- 04 - Sales Performance
-- Database engine: MySQL 8.0+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. Executive sales overview
-- ============================================================

SELECT
    COUNT(*) AS recorded_orders,

    SUM(is_delivered_order)
        AS delivered_orders,

    ROUND(
    100.0 * SUM(is_delivered_order) / COUNT(*),
    2
) AS order_completion_rate_pct,

    COUNT(DISTINCT customer_unique_id)
        AS unique_customers,

    (
        SELECT COUNT(*)
        FROM vw_seller_analytics
    ) AS active_sellers,

    ROUND(
        SUM(
            CASE
                WHEN is_delivered_order = 1
                THEN product_value
                ELSE 0
            END
        ),
        2
    ) AS delivered_product_value,

    ROUND(
        SUM(
            CASE
                WHEN is_delivered_order = 1
                THEN total_payment_value
                ELSE 0
            END
        ),
        2
    ) AS delivered_payment_value,

    ROUND(
        AVG(
            CASE
                WHEN is_delivered_order = 1
                THEN total_payment_value
            END
        ),
        2
    ) AS average_delivered_order_payment,

    ROUND(
        AVG(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_review_score = 1
                THEN latest_review_score
            END
        ),
        2
    ) AS average_delivered_review_score,

    ROUND(
    100.0 * AVG(
        CASE
            WHEN is_valid_for_delivery_analysis = 1
            THEN is_on_time_delivery
        END
    ),
    2
) AS on_time_delivery_rate_pct

FROM vw_order_analytics;


-- ============================================================
-- 2. Order-status distribution
-- ============================================================

WITH status_summary AS (

    SELECT
        order_status,
        COUNT(*) AS order_count
    FROM vw_order_analytics
    GROUP BY order_status
)

SELECT
    order_status,
    order_count,

    ROUND(
        100.0
        * order_count
        / SUM(order_count) OVER (),
        2
    ) AS order_rate_pct,

    RANK() OVER (
        ORDER BY order_count DESC
    ) AS volume_rank

FROM status_summary
ORDER BY order_count DESC;


-- ============================================================
-- 3. Monthly delivered-sales trend
-- Comparable period: January 2017 to August 2018
-- ============================================================

WITH monthly_sales AS (

    SELECT
        CAST(
            DATE_FORMAT(
                order_purchase_timestamp,
                '%Y-%m-01'
            ) AS DATE
        ) AS purchase_month,

        COUNT(*) AS delivered_orders,

        ROUND(
            SUM(product_value),
            2
        ) AS delivered_product_value,

        ROUND(
            SUM(total_payment_value),
            2
        ) AS delivered_payment_value,

        ROUND(
            AVG(total_payment_value),
            2
        ) AS average_order_payment

    FROM vw_order_analytics

    WHERE is_delivered_order = 1
      AND order_purchase_timestamp
          >= '2017-01-01'
      AND order_purchase_timestamp
          < '2018-09-01'

    GROUP BY
        CAST(
            DATE_FORMAT(
                order_purchase_timestamp,
                '%Y-%m-01'
            ) AS DATE
        )
),

monthly_comparison AS (

    SELECT
        purchase_month,
        delivered_orders,
        delivered_product_value,
        delivered_payment_value,
        average_order_payment,

        LAG(delivered_payment_value) OVER (
            ORDER BY purchase_month
        ) AS previous_month_payment

    FROM monthly_sales
)

SELECT
    purchase_month,
    delivered_orders,
    delivered_product_value,
    delivered_payment_value,
    average_order_payment,
    previous_month_payment,

    ROUND(
        100.0
        * (
            delivered_payment_value
            - previous_month_payment
        )
        / NULLIF(previous_month_payment, 0),
        2
    ) AS payment_growth_pct

FROM monthly_comparison
ORDER BY purchase_month;

-- ============================================================
-- 4. Comparable January-August performance
-- ============================================================

WITH comparable_years AS (

    SELECT
        YEAR(order_purchase_timestamp)
            AS purchase_year,

        COUNT(*) AS delivered_orders,

        ROUND(
            SUM(product_value),
            2
        ) AS delivered_product_value,

        ROUND(
            SUM(total_payment_value),
            2
        ) AS delivered_payment_value,

        ROUND(
            AVG(total_payment_value),
            2
        ) AS average_order_payment

    FROM vw_order_analytics

    WHERE is_delivered_order = 1
      AND YEAR(order_purchase_timestamp)
          IN (2017, 2018)
      AND MONTH(order_purchase_timestamp)
          BETWEEN 1 AND 8

    GROUP BY
        YEAR(order_purchase_timestamp)
),

year_comparison AS (

    SELECT
        purchase_year,
        delivered_orders,
        delivered_product_value,
        delivered_payment_value,
        average_order_payment,

        LAG(delivered_orders) OVER (
            ORDER BY purchase_year
        ) AS previous_year_orders,

        LAG(delivered_payment_value) OVER (
            ORDER BY purchase_year
        ) AS previous_year_payment

    FROM comparable_years
)

SELECT
    purchase_year,
    delivered_orders,
    delivered_product_value,
    delivered_payment_value,
    average_order_payment,

    ROUND(
        100.0
        * (
            delivered_orders
            - previous_year_orders
        )
        / NULLIF(previous_year_orders, 0),
        2
    ) AS order_growth_pct,

    ROUND(
        100.0
        * (
            delivered_payment_value
            - previous_year_payment
        )
        / NULLIF(previous_year_payment, 0),
        2
    ) AS payment_growth_pct

FROM year_comparison
ORDER BY purchase_year;

-- ============================================================
-- 5. Delivered-order payment-method summary
-- Uses the primary payment method assigned to each order.
-- ============================================================

WITH payment_summary AS (

    SELECT
        COALESCE(
            primary_payment_type,
            'unknown'
        ) AS primary_payment_type,

        COUNT(*) AS delivered_orders,

        ROUND(
            SUM(total_payment_value),
            2
        ) AS delivered_payment_value,

        ROUND(
            AVG(total_payment_value),
            2
        ) AS average_order_payment

    FROM vw_order_analytics

    WHERE is_delivered_order = 1

    GROUP BY
        COALESCE(
            primary_payment_type,
            'unknown'
        )
)

SELECT
    primary_payment_type,
    delivered_orders,
    delivered_payment_value,
    average_order_payment,

    ROUND(
        100.0
        * delivered_orders
        / SUM(delivered_orders) OVER (),
        2
    ) AS delivered_order_share_pct,

    ROUND(
        100.0
        * delivered_payment_value
        / SUM(delivered_payment_value) OVER (),
        2
    ) AS payment_value_share_pct,

    RANK() OVER (
        ORDER BY delivered_payment_value DESC
    ) AS payment_value_rank

FROM payment_summary
ORDER BY delivered_payment_value DESC;

-- ============================================================
-- 6. Sales-analysis validation
-- ============================================================

WITH validation_checks AS (

    SELECT
        'Order-status records represented'
            AS validation_check,
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ) AS result,
        CAST(
            99441 AS DECIMAL(18, 2)
        ) AS expected
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Delivered orders represented',
        CAST(
            SUM(is_delivered_order)
            AS DECIMAL(18, 2)
        ),
        CAST(
            96478 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Delivered product value represented',
        ROUND(
            SUM(
                CASE
                    WHEN is_delivered_order = 1
                    THEN product_value
                    ELSE 0
                END
            ),
            2
        ),
        CAST(
            13221498.11
            AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Delivered payment value represented',
        ROUND(
            SUM(
                CASE
                    WHEN is_delivered_order = 1
                    THEN total_payment_value
                    ELSE 0
                END
            ),
            2
        ),
        CAST(
            15422461.77
            AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics

    UNION ALL

    SELECT
        'Comparable monthly records',
        CAST(
            COUNT(
                DISTINCT DATE_FORMAT(
                    order_purchase_timestamp,
                    '%Y-%m'
                )
            ) AS DECIMAL(18, 2)
        ),
        CAST(
            20 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics
    WHERE is_delivered_order = 1
      AND order_purchase_timestamp
          >= '2017-01-01'
      AND order_purchase_timestamp
          < '2018-09-01'

    UNION ALL

    SELECT
        'Monthly-trend delivered orders',
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ),
        CAST(
            96211 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics
    WHERE is_delivered_order = 1
      AND order_purchase_timestamp
          >= '2017-01-01'
      AND order_purchase_timestamp
          < '2018-09-01'

    UNION ALL

    SELECT
        'Comparable January-August delivered orders',
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ),
        CAST(
            74781 AS DECIMAL(18, 2)
        )
    FROM vw_order_analytics
    WHERE is_delivered_order = 1
      AND YEAR(order_purchase_timestamp)
          IN (2017, 2018)
      AND MONTH(order_purchase_timestamp)
          BETWEEN 1 AND 8
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

FROM validation_checks
ORDER BY validation_check;







































































































