-- ============================================================
-- Olist E-commerce Analytics
-- 05 - Delivery Performance
-- Database engine: MySQL 8.0+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. Delivery-performance overview
-- ============================================================

SELECT
    COUNT(*) AS valid_deliveries,

    SUM(is_on_time_delivery)
        AS on_time_deliveries,

    SUM(is_late_delivery)
        AS late_deliveries,

    ROUND(
        100.0 * AVG(is_on_time_delivery),
        2
    ) AS on_time_delivery_rate_pct,

    ROUND(
        100.0 * AVG(is_late_delivery),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(days_late),
        2
    ) AS average_days_late_all_orders,

    ROUND(
        AVG(
            CASE
                WHEN is_late_delivery = 1
                THEN days_late
            END
        ),
        2
    ) AS average_days_late_when_delayed,

    ROUND(
        MAX(days_late),
        2
    ) AS maximum_days_late

FROM vw_order_analytics

WHERE is_valid_for_delivery_analysis = 1;

-- ============================================================
-- 2. Delivery-delay severity and customer satisfaction
-- ============================================================

WITH delay_groups AS (

    SELECT
        order_id,
        total_payment_value,
        delivery_days,
        days_late,
        latest_review_score,
        has_valid_review_score,

        CASE
            WHEN is_late_delivery = 0
                THEN 'On time'
            WHEN days_late <= 3
                THEN '1-3 days late'
            WHEN days_late <= 7
                THEN '4-7 days late'
            WHEN days_late <= 14
                THEN '8-14 days late'
            WHEN days_late <= 30
                THEN '15-30 days late'
            ELSE 'More than 30 days late'
        END AS delay_severity,

        CASE
            WHEN is_late_delivery = 0 THEN 1
            WHEN days_late <= 3 THEN 2
            WHEN days_late <= 7 THEN 3
            WHEN days_late <= 14 THEN 4
            WHEN days_late <= 30 THEN 5
            ELSE 6
        END AS severity_order

    FROM vw_order_analytics

    WHERE is_valid_for_delivery_analysis = 1
)

SELECT
    delay_severity,
    COUNT(*) AS orders,

    SUM(has_valid_review_score)
        AS reviewed_orders,

    ROUND(
        AVG(
            CASE
                WHEN has_valid_review_score = 1
                THEN latest_review_score
            END
        ),
        2
    ) AS average_review_score,

    ROUND(
        100.0 * AVG(
            CASE
                WHEN has_valid_review_score = 1
                THEN latest_review_score <= 2
            END
        ),
        2
    ) AS low_satisfaction_rate_pct,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN days_late > 0
                THEN days_late
                ELSE 0
            END
        ),
        2
    ) AS average_days_late,

    ROUND(
        SUM(total_payment_value),
        2
    ) AS delivered_payment_value,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM delay_groups

GROUP BY
    delay_severity,
    severity_order

ORDER BY severity_order;


-- ============================================================
-- 3. Monthly late-delivery trend
-- Comparable period: January 2017 to August 2018
-- ============================================================

WITH monthly_delivery AS (

    SELECT
        CAST(
            DATE_FORMAT(
                order_purchase_timestamp,
                '%Y-%m-01'
            ) AS DATE
        ) AS purchase_month,

        COUNT(*) AS valid_deliveries,

        SUM(is_late_delivery)
            AS late_deliveries,

        ROUND(
            AVG(delivery_days),
            2
        ) AS average_delivery_days,

        ROUND(
            AVG(
                CASE
                    WHEN has_valid_review_score = 1
                    THEN latest_review_score
                END
            ),
            2
        ) AS average_review_score,

        AVG(is_late_delivery)
            AS late_delivery_rate

    FROM vw_order_analytics

    WHERE is_valid_for_delivery_analysis = 1
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
)

SELECT
    purchase_month,
    valid_deliveries,
    late_deliveries,
    average_delivery_days,
    average_review_score,

    ROUND(
        100.0 * late_delivery_rate,
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        100.0 * AVG(late_delivery_rate) OVER (
            ORDER BY purchase_month
            ROWS BETWEEN 2 PRECEDING
                     AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_late_rate_pct

FROM monthly_delivery
ORDER BY purchase_month;

-- ============================================================
-- 4. State-level delivery performance
-- Minimum: 500 valid delivery orders
-- ============================================================

WITH state_delivery AS (

    SELECT
        customer_state,

        COUNT(*) AS valid_delivery_orders,

        SUM(is_late_delivery)
            AS late_deliveries,

        ROUND(
            AVG(delivery_days),
            2
        ) AS average_delivery_days,

        ROUND(
            100.0 * AVG(is_late_delivery),
            2
        ) AS late_delivery_rate_pct,

        ROUND(
            AVG(
                CASE
                    WHEN has_valid_review_score = 1
                    THEN latest_review_score
                END
            ),
            2
        ) AS average_review_score,

        ROUND(
            SUM(total_payment_value),
            2
        ) AS delivered_payment_value

    FROM vw_order_analytics

    WHERE is_valid_for_delivery_analysis = 1

    GROUP BY customer_state

    HAVING COUNT(*) >= 500
)

SELECT
    customer_state,
    valid_delivery_orders,
    late_deliveries,
    average_delivery_days,
    late_delivery_rate_pct,
    average_review_score,
    delivered_payment_value,

    RANK() OVER (
        ORDER BY late_delivery_rate_pct DESC
    ) AS late_rate_rank

FROM state_delivery
ORDER BY late_delivery_rate_pct DESC;

-- ============================================================
-- 5. Delivery-analysis validation
-- ============================================================

WITH validation_checks AS (

    SELECT
        'Valid deliveries represented'
            AS validation_check,
        COUNT(*) AS result,
        96281 AS expected
    FROM vw_order_analytics
    WHERE is_valid_for_delivery_analysis = 1

    UNION ALL

    SELECT
        'On-time deliveries represented',
        SUM(is_on_time_delivery),
        89750
    FROM vw_order_analytics
    WHERE is_valid_for_delivery_analysis = 1

    UNION ALL

    SELECT
        'Late deliveries represented',
        SUM(is_late_delivery),
        6531
    FROM vw_order_analytics
    WHERE is_valid_for_delivery_analysis = 1

    UNION ALL

    SELECT
        'Comparable monthly records',
        COUNT(
            DISTINCT DATE_FORMAT(
                order_purchase_timestamp,
                '%Y-%m'
            )
        ),
        20
    FROM vw_order_analytics
    WHERE is_valid_for_delivery_analysis = 1
      AND order_purchase_timestamp
          >= '2017-01-01'
      AND order_purchase_timestamp
          < '2018-09-01'

    UNION ALL

    SELECT
        'States meeting minimum volume',
        COUNT(*),
        17
    FROM (
        SELECT customer_state
        FROM vw_order_analytics
        WHERE is_valid_for_delivery_analysis = 1
        GROUP BY customer_state
        HAVING COUNT(*) >= 500
    ) AS eligible_states

    UNION ALL

    SELECT
        'Invalid delivery flags',
        COUNT(*),
        0
    FROM vw_order_analytics
    WHERE is_valid_for_delivery_analysis = 1
      AND (
          is_late_delivery NOT IN (0, 1)
          OR is_on_time_delivery NOT IN (0, 1)
          OR is_late_delivery
             + is_on_time_delivery <> 1
      )
)

SELECT
    validation_check,
    result,
    expected,
    result - expected AS difference,

    CASE
        WHEN result = expected
        THEN 'Passed'
        ELSE 'Failed'
    END AS status

FROM validation_checks
ORDER BY validation_check;



























































