-- ============================================================
-- Olist E-commerce Analytics
-- 06 - Customer Analysis
-- Database engine: MySQL 8.0+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. Customer overview
-- ============================================================

SELECT
    COUNT(*) AS unique_customers,

    SUM(order_count)
        AS recorded_orders,

    ROUND(
        AVG(order_count),
        2
    ) AS average_orders_per_customer,

    SUM(is_repeat_customer)
        AS repeat_customers,

    COUNT(*) - SUM(is_repeat_customer)
        AS one_time_customers,

    ROUND(
        100.0 * AVG(is_repeat_customer),
        2
    ) AS repeat_customer_rate_pct,

    ROUND(
        SUM(observed_product_value),
        2
    ) AS observed_product_value,

    ROUND(
        SUM(observed_payment_value),
        2
    ) AS observed_payment_value,

    ROUND(
        AVG(observed_payment_value),
        2
    ) AS average_payment_per_customer,

    ROUND(
        AVG(average_review_score),
        2
    ) AS average_customer_review_score

FROM vw_customer_analytics;

-- ============================================================
-- 2. One-time versus repeat customers
-- ============================================================

WITH customer_types AS (

    SELECT
        CASE
            WHEN is_repeat_customer = 1
                THEN 'Repeat customer'
            ELSE 'One-time customer'
        END AS customer_type,

        COUNT(*) AS customers,

        SUM(order_count)
            AS recorded_orders,

        ROUND(
            SUM(observed_payment_value),
            2
        ) AS observed_payment_value,

        ROUND(
            AVG(order_count),
            2
        ) AS average_orders_per_customer,

        ROUND(
            AVG(observed_payment_value),
            2
        ) AS average_payment_per_customer,

        ROUND(
            AVG(observed_customer_tenure_days),
            2
        ) AS average_observed_tenure_days,

        ROUND(
            AVG(average_review_score),
            2
        ) AS average_customer_review_score

    FROM vw_customer_analytics

    GROUP BY
        CASE
            WHEN is_repeat_customer = 1
                THEN 'Repeat customer'
            ELSE 'One-time customer'
        END
)

SELECT
    customer_type,
    customers,
    recorded_orders,
    observed_payment_value,
    average_orders_per_customer,
    average_payment_per_customer,
    average_observed_tenure_days,
    average_customer_review_score,

    ROUND(
        100.0
        * customers
        / SUM(customers) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(
        100.0
        * recorded_orders
        / SUM(recorded_orders) OVER (),
        2
    ) AS order_share_pct,

    ROUND(
        100.0
        * observed_payment_value
        / SUM(observed_payment_value) OVER (),
        2
    ) AS payment_value_share_pct

FROM customer_types
ORDER BY customers DESC;

-- ============================================================
-- 3. Customer distribution by latest observed state
-- ============================================================

WITH state_customers AS (

    SELECT
        latest_customer_state
            AS customer_state,

        COUNT(*) AS customers,

        SUM(order_count)
            AS recorded_orders,

        SUM(delivered_order_count)
            AS delivered_orders,

        ROUND(
            SUM(observed_payment_value),
            2
        ) AS observed_payment_value,

        ROUND(
            AVG(observed_payment_value),
            2
        ) AS average_payment_per_customer,

        ROUND(
            AVG(average_review_score),
            2
        ) AS average_customer_review_score,

        ROUND(
            100.0
            * SUM(late_delivery_count)
            / NULLIF(
                SUM(valid_delivery_order_count),
                0
            ),
            2
        ) AS late_delivery_rate_pct

    FROM vw_customer_analytics

    GROUP BY latest_customer_state
)

SELECT
    customer_state,
    customers,
    recorded_orders,
    delivered_orders,
    observed_payment_value,
    average_payment_per_customer,
    average_customer_review_score,
    late_delivery_rate_pct,

    ROUND(
        100.0
        * customers
        / SUM(customers) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(
        100.0
        * observed_payment_value
        / SUM(observed_payment_value) OVER (),
        2
    ) AS payment_value_share_pct,

    RANK() OVER (
        ORDER BY observed_payment_value DESC
    ) AS payment_value_rank

FROM state_customers
ORDER BY observed_payment_value DESC;

-- ============================================================
-- 4. Customer payment-value concentration
-- ============================================================

WITH ranked_customers AS (

    SELECT
        customer_unique_id,
        observed_payment_value,

        ROW_NUMBER() OVER (
            ORDER BY
                observed_payment_value DESC,
                customer_unique_id
        ) AS customer_rank,

        COUNT(*) OVER ()
            AS total_customers,

        SUM(observed_payment_value) OVER ()
            AS total_payment_value

    FROM vw_customer_analytics
),

customer_groups AS (

    SELECT
        'Top 1%' AS customer_group,
        1 AS group_order,
        0.01 AS group_threshold

    UNION ALL

    SELECT
        'Top 5%',
        2,
        0.05

    UNION ALL

    SELECT
        'Top 10%',
        3,
        0.10

    UNION ALL

    SELECT
        'Top 20%',
        4,
        0.20

    UNION ALL

    SELECT
        'Top 50%',
        5,
        0.50
)

SELECT
    customer_groups_table.customer_group,

    COUNT(*) AS customers,

    ROUND(
        100.0
        * COUNT(*)
        / MAX(ranked.total_customers),
        2
    ) AS customer_share_pct,

    ROUND(
        MIN(ranked.observed_payment_value),
        2
    ) AS minimum_observed_payment,

    ROUND(
        SUM(ranked.observed_payment_value),
        2
    ) AS observed_payment_value,

    ROUND(
        100.0
        * SUM(ranked.observed_payment_value)
        / MAX(ranked.total_payment_value),
        2
    ) AS payment_value_share_pct

FROM customer_groups AS customer_groups_table

INNER JOIN ranked_customers AS ranked
    ON ranked.customer_rank
       <= CEIL(
           ranked.total_customers
           * customer_groups_table.group_threshold
       )

GROUP BY
    customer_groups_table.customer_group,
    customer_groups_table.group_order

ORDER BY
    customer_groups_table.group_order;

-- ============================================================
-- 5. Customer recency distribution
-- Snapshot: one day after the final recorded purchase
-- ============================================================

WITH analysis_parameters AS (

    SELECT
        STR_TO_DATE(
            '2018-10-18',
            '%Y-%m-%d'
        ) AS snapshot_date
),

customer_recency AS (

    SELECT
        customers.customer_unique_id,
        customers.order_count,
        customers.observed_payment_value,
        customers.is_repeat_customer,

        DATEDIFF(
            parameters.snapshot_date,
            DATE(customers.last_purchase_timestamp)
        ) AS recency_days

    FROM vw_customer_analytics AS customers

    CROSS JOIN analysis_parameters AS parameters
),

recency_groups AS (

    SELECT
        customer_unique_id,
        order_count,
        observed_payment_value,
        is_repeat_customer,
        recency_days,

        CASE
            WHEN recency_days <= 30
                THEN '1-30 days'
            WHEN recency_days <= 90
                THEN '31-90 days'
            WHEN recency_days <= 180
                THEN '91-180 days'
            WHEN recency_days <= 365
                THEN '181-365 days'
            ELSE 'More than 365 days'
        END AS recency_group,

        CASE
            WHEN recency_days <= 30 THEN 1
            WHEN recency_days <= 90 THEN 2
            WHEN recency_days <= 180 THEN 3
            WHEN recency_days <= 365 THEN 4
            ELSE 5
        END AS recency_order

    FROM customer_recency
)

SELECT
    recency_group,

    COUNT(*) AS customers,

    ROUND(
        AVG(recency_days),
        1
    ) AS average_recency_days,

    ROUND(
        AVG(order_count),
        2
    ) AS average_orders_per_customer,

    ROUND(
        100.0 * AVG(is_repeat_customer),
        2
    ) AS repeat_customer_rate_pct,

    ROUND(
        AVG(observed_payment_value),
        2
    ) AS average_payment_per_customer,

    ROUND(
        SUM(observed_payment_value),
        2
    ) AS observed_payment_value,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM recency_groups

GROUP BY
    recency_group,
    recency_order

ORDER BY recency_order;

-- ============================================================
-- 6. Highest-value repeat customers
-- Minimum: two recorded orders
-- ============================================================

SELECT
    customer_unique_id,
    order_count,
    delivered_order_count,
    first_purchase_timestamp,
    last_purchase_timestamp,
    observed_customer_tenure_days,
    observed_payment_value,
    average_order_payment_value,
    average_review_score,
    late_delivery_rate,
    latest_customer_city,
    latest_customer_state,

    DENSE_RANK() OVER (
        ORDER BY observed_payment_value DESC
    ) AS payment_value_rank

FROM vw_customer_analytics

WHERE is_repeat_customer = 1

ORDER BY
    observed_payment_value DESC,
    customer_unique_id

LIMIT 20;


-- ============================================================
-- 7. Customer-analysis validation
-- ============================================================

WITH validation_checks AS (

    SELECT
        'Customer rows represented'
            AS validation_check,
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ) AS result,
        CAST(
            96096 AS DECIMAL(18, 2)
        ) AS expected
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Duplicate customer IDs',
        CAST(
            COUNT(*)
            - COUNT(DISTINCT customer_unique_id)
            AS DECIMAL(18, 2)
        ),
        CAST(
            0 AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Orders represented by customers',
        CAST(
            SUM(order_count)
            AS DECIMAL(18, 2)
        ),
        CAST(
            99441 AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Observed product value represented',
        ROUND(
            SUM(observed_product_value),
            2
        ),
        CAST(
            13591643.70
            AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Observed payment value represented',
        ROUND(
            SUM(observed_payment_value),
            2
        ),
        CAST(
            16008872.12
            AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Repeat customers represented',
        CAST(
            SUM(is_repeat_customer)
            AS DECIMAL(18, 2)
        ),
        CAST(
            2997 AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Customers with purchase timestamps',
        CAST(
            SUM(
                first_purchase_timestamp IS NOT NULL
                AND last_purchase_timestamp IS NOT NULL
            ) AS DECIMAL(18, 2)
        ),
        CAST(
            96096 AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Customer states represented',
        CAST(
            COUNT(
                DISTINCT latest_customer_state
            ) AS DECIMAL(18, 2)
        ),
        CAST(
            27 AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics

    UNION ALL

    SELECT
        'Invalid repeat-customer flags',
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ),
        CAST(
            0 AS DECIMAL(18, 2)
        )
    FROM vw_customer_analytics
    WHERE is_repeat_customer NOT IN (0, 1)
       OR is_repeat_customer IS NULL
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


-- ============================================================
-- End of 06_customer_analysis.sql
-- ============================================================









