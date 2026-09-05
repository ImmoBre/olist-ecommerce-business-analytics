-- ============================================================
-- Olist E-commerce Analytics
-- 07 - Seller Performance
-- Database engine: MySQL 8.0+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. Create a seller-order bridge
-- One row per seller and order
-- ============================================================

CREATE OR REPLACE VIEW vw_seller_order_performance AS

SELECT
    items.seller_id,
    items.order_id,

    COUNT(*) AS seller_order_item_count,

    COUNT(DISTINCT items.product_id)
        AS seller_order_product_count,

    ROUND(
        SUM(items.price),
        2
    ) AS seller_order_product_value,

    ROUND(
        SUM(items.freight_value),
        2
    ) AS seller_order_freight_value,

    ROUND(
        SUM(
            items.price
            + items.freight_value
        ),
        2
    ) AS seller_order_total_value,

    MAX(orders.is_delivered_order)
        AS is_delivered_order,

    MAX(orders.has_valid_review_score)
        AS has_valid_review_score,

    MAX(orders.latest_review_score)
        AS latest_review_score,

    MAX(orders.is_valid_for_delivery_analysis)
        AS has_valid_delivery_metric,

    MAX(orders.is_late_delivery)
        AS is_late_delivery,

    MAX(orders.delivery_days)
        AS delivery_days

FROM vw_order_items AS items

INNER JOIN vw_order_analytics AS orders
    ON items.order_id = orders.order_id

GROUP BY
    items.seller_id,
    items.order_id;


-- ============================================================
-- 2. Create the seller-performance view
-- ============================================================

CREATE OR REPLACE VIEW vw_sql_seller_performance AS

SELECT
    sellers.seller_id,
    sellers.seller_city,
    sellers.seller_state,

    COUNT(bridge.order_id)
        AS recorded_orders,

    SUM(
        CASE
            WHEN bridge.is_delivered_order = 1
            THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    COALESCE(
        SUM(bridge.seller_order_item_count),
        0
    ) AS item_records,

    ROUND(
        COALESCE(
            SUM(
                bridge.seller_order_product_value
            ),
            0
        ),
        2
    ) AS product_value,

    ROUND(
        COALESCE(
            SUM(
                bridge.seller_order_freight_value
            ),
            0
        ),
        2
    ) AS freight_value,

    ROUND(
        COALESCE(
            SUM(
                CASE
                    WHEN bridge.is_delivered_order = 1
                    THEN bridge.seller_order_product_value
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS delivered_product_value,

    SUM(
        CASE
            WHEN bridge.is_delivered_order = 1
             AND bridge.has_valid_review_score = 1
            THEN 1
            ELSE 0
        END
    ) AS reviewed_delivered_orders,

    ROUND(
        AVG(
            CASE
                WHEN bridge.is_delivered_order = 1
                 AND bridge.has_valid_review_score = 1
                THEN bridge.latest_review_score
            END
        ),
        4
    ) AS average_review_score,

    ROUND(
        AVG(
            CASE
                WHEN bridge.is_delivered_order = 1
                 AND bridge.has_valid_review_score = 1
                THEN bridge.latest_review_score <= 2
            END
        ),
        6
    ) AS low_satisfaction_rate,

    SUM(
        CASE
            WHEN bridge.has_valid_delivery_metric = 1
            THEN 1
            ELSE 0
        END
    ) AS valid_delivery_orders,

    ROUND(
        AVG(
            CASE
                WHEN bridge.has_valid_delivery_metric = 1
                THEN bridge.is_late_delivery
            END
        ),
        6
    ) AS late_delivery_rate,

    ROUND(
        AVG(
            CASE
                WHEN bridge.has_valid_delivery_metric = 1
                THEN bridge.delivery_days
            END
        ),
        4
    ) AS average_delivery_days

FROM vw_seller_analytics AS sellers

LEFT JOIN vw_seller_order_performance AS bridge
    ON sellers.seller_id = bridge.seller_id

GROUP BY
    sellers.seller_id,
    sellers.seller_city,
    sellers.seller_state;


-- ============================================================
-- 3. Seller-performance overview
-- ============================================================

SELECT
    COUNT(*) AS sellers,

    SUM(recorded_orders)
        AS seller_order_associations,

    SUM(delivered_orders)
        AS delivered_seller_order_associations,

    SUM(item_records)
        AS item_records,

    ROUND(
        SUM(product_value),
        2
    ) AS product_value,

    ROUND(
        SUM(freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(delivered_product_value),
        2
    ) AS delivered_product_value,

    SUM(delivered_orders > 0)
        AS sellers_with_delivered_orders,

    ROUND(
        AVG(recorded_orders),
        2
    ) AS average_orders_per_seller,

    MAX(recorded_orders)
        AS maximum_orders_per_seller,

    ROUND(
        AVG(average_review_score),
        2
    ) AS average_seller_review_score

FROM vw_sql_seller_performance;


-- ============================================================
-- 4. Delivered product-value concentration
-- ============================================================

WITH ranked_sellers AS (

    SELECT
        seller_id,
        delivered_orders,
        delivered_product_value,

        ROW_NUMBER() OVER (
            ORDER BY
                delivered_product_value DESC,
                seller_id
        ) AS seller_rank,

        COUNT(*) OVER ()
            AS total_sellers,

        SUM(delivered_orders) OVER ()
            AS total_delivered_orders,

        SUM(delivered_product_value) OVER ()
            AS total_delivered_product_value

    FROM vw_sql_seller_performance
),

seller_groups AS (

    SELECT
        'Top 1%' AS seller_group,
        1 AS group_order,
        0.01 AS group_threshold

    UNION ALL
    SELECT 'Top 5%', 2, 0.05

    UNION ALL
    SELECT 'Top 10%', 3, 0.10

    UNION ALL
    SELECT 'Top 20%', 4, 0.20

    UNION ALL
    SELECT 'Top 50%', 5, 0.50
)

SELECT
    seller_group_table.seller_group,

    COUNT(*) AS sellers,

    ROUND(
        100.0
        * COUNT(*)
        / MAX(ranked.total_sellers),
        2
    ) AS seller_share_pct,

    ROUND(
        MIN(
            ranked.delivered_product_value
        ),
        2
    ) AS minimum_delivered_product_value,

    ROUND(
        SUM(
            ranked.delivered_product_value
        ),
        2
    ) AS delivered_product_value,

    ROUND(
        100.0
        * SUM(
            ranked.delivered_product_value
        )
        / MAX(
            ranked.total_delivered_product_value
        ),
        2
    ) AS product_value_share_pct,

    SUM(ranked.delivered_orders)
        AS delivered_orders,

    ROUND(
        100.0
        * SUM(ranked.delivered_orders)
        / MAX(ranked.total_delivered_orders),
        2
    ) AS seller_order_share_pct

FROM seller_groups AS seller_group_table

INNER JOIN ranked_sellers AS ranked
    ON ranked.seller_rank
       <= CEIL(
           ranked.total_sellers
           * seller_group_table.group_threshold
       )

GROUP BY
    seller_group_table.seller_group,
    seller_group_table.group_order

ORDER BY
    seller_group_table.group_order;


-- ============================================================
-- 5. Reliable-seller performance groups
-- Reliability thresholds:
-- At least 50 reviewed delivered orders
-- At least 50 valid delivery orders
-- ============================================================

WITH benchmarks AS (

    SELECT
        AVG(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_review_score = 1
                THEN latest_review_score
            END
        ) AS overall_review_score,

        AVG(
            CASE
                WHEN is_valid_for_delivery_analysis = 1
                THEN is_late_delivery
            END
        ) AS overall_late_delivery_rate

    FROM vw_order_analytics
),

reliable_sellers AS (

    SELECT
        performance.*,

        CASE
            WHEN performance.late_delivery_rate
                     > benchmarks.overall_late_delivery_rate
             AND performance.average_review_score
                     < benchmarks.overall_review_score
            THEN
                'Higher late rate and lower review score'

            WHEN performance.late_delivery_rate
                     <= benchmarks.overall_late_delivery_rate
             AND performance.average_review_score
                     >= benchmarks.overall_review_score
            THEN
                'Lower late rate and higher review score'

            ELSE
                'Mixed performance'
        END AS performance_group

    FROM vw_sql_seller_performance AS performance

    CROSS JOIN benchmarks

    WHERE performance.reviewed_delivered_orders >= 50
      AND performance.valid_delivery_orders >= 50
)

SELECT
    performance_group,

    COUNT(*) AS sellers,

    SUM(delivered_orders)
        AS delivered_orders,

    ROUND(
        SUM(delivered_product_value),
        2
    ) AS delivered_product_value,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS reliable_seller_share_pct

FROM reliable_sellers

GROUP BY performance_group

ORDER BY
    CASE performance_group
        WHEN
            'Higher late rate and lower review score'
            THEN 1
        WHEN
            'Lower late rate and higher review score'
            THEN 2
        ELSE 3
    END;


-- ============================================================
-- 6. Priority investigation candidates
-- ============================================================

WITH benchmarks AS (

    SELECT
        AVG(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_review_score = 1
                THEN latest_review_score
            END
        ) AS overall_review_score,

        AVG(
            CASE
                WHEN is_valid_for_delivery_analysis = 1
                THEN is_late_delivery
            END
        ) AS overall_late_delivery_rate

    FROM vw_order_analytics
),

priority_candidates AS (

    SELECT
        performance.*

    FROM vw_sql_seller_performance AS performance

    CROSS JOIN benchmarks

    WHERE performance.reviewed_delivered_orders >= 50
      AND performance.valid_delivery_orders >= 50
      AND performance.average_review_score
            < benchmarks.overall_review_score
      AND performance.late_delivery_rate
            > benchmarks.overall_late_delivery_rate
)

SELECT
    seller_id,
    seller_city,
    seller_state,
    delivered_orders,
    delivered_product_value,
    average_review_score,

    ROUND(
        100.0 * low_satisfaction_rate,
        2
    ) AS low_satisfaction_rate_pct,

    ROUND(
        100.0 * late_delivery_rate,
        2
    ) AS late_delivery_rate_pct,

    average_delivery_days,

    ROUND(
        100.0
        * delivered_product_value
        / SUM(delivered_product_value) OVER (),
        2
    ) AS candidate_value_share_pct,

    DENSE_RANK() OVER (
        ORDER BY delivered_product_value DESC
    ) AS candidate_value_rank

FROM priority_candidates

ORDER BY
    delivered_product_value DESC,
    seller_id

LIMIT 20;


-- ============================================================
-- 7. Seller performance by state
-- ============================================================

WITH state_performance AS (

    SELECT
        seller_state,

        COUNT(*) AS sellers,

        SUM(recorded_orders)
            AS seller_order_associations,

        SUM(delivered_orders)
            AS delivered_seller_order_associations,

        SUM(item_records)
            AS item_records,

        ROUND(
            SUM(delivered_product_value),
            2
        ) AS delivered_product_value,

        SUM(reviewed_delivered_orders)
            AS reviewed_delivered_orders,

        ROUND(
            SUM(
                average_review_score
                * reviewed_delivered_orders
            )
            / NULLIF(
                SUM(reviewed_delivered_orders),
                0
            ),
            2
        ) AS average_review_score,

        ROUND(
            100.0
            * SUM(
                low_satisfaction_rate
                * reviewed_delivered_orders
            )
            / NULLIF(
                SUM(reviewed_delivered_orders),
                0
            ),
            2
        ) AS low_satisfaction_rate_pct,

        SUM(valid_delivery_orders)
            AS valid_delivery_orders,

        ROUND(
            100.0
            * SUM(
                late_delivery_rate
                * valid_delivery_orders
            )
            / NULLIF(
                SUM(valid_delivery_orders),
                0
            ),
            2
        ) AS late_delivery_rate_pct

    FROM vw_sql_seller_performance

    GROUP BY seller_state
)

SELECT
    seller_state,
    sellers,
    seller_order_associations,
    delivered_seller_order_associations,
    item_records,
    delivered_product_value,
    reviewed_delivered_orders,
    average_review_score,
    low_satisfaction_rate_pct,
    valid_delivery_orders,
    late_delivery_rate_pct,

    ROUND(
        100.0
        * sellers
        / SUM(sellers) OVER (),
        2
    ) AS seller_share_pct,

    ROUND(
        100.0
        * delivered_product_value
        / SUM(delivered_product_value) OVER (),
        2
    ) AS product_value_share_pct

FROM state_performance

ORDER BY delivered_product_value DESC;


-- ============================================================
-- 8. Seller-analysis validation
-- ============================================================

WITH benchmarks AS (

    SELECT
        AVG(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_review_score = 1
                THEN latest_review_score
            END
        ) AS overall_review_score,

        AVG(
            CASE
                WHEN is_valid_for_delivery_analysis = 1
                THEN is_late_delivery
            END
        ) AS overall_late_delivery_rate

    FROM vw_order_analytics
),

reliable_sellers AS (

    SELECT
        performance.*,
        benchmarks.overall_review_score,
        benchmarks.overall_late_delivery_rate

    FROM vw_sql_seller_performance AS performance

    CROSS JOIN benchmarks

    WHERE performance.reviewed_delivered_orders >= 50
      AND performance.valid_delivery_orders >= 50
),

validation_checks AS (

    SELECT
        'Seller rows represented'
            AS validation_check,
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ) AS result,
        CAST(
            3095 AS DECIMAL(18, 2)
        ) AS expected
    FROM vw_sql_seller_performance

    UNION ALL

    SELECT
        'Duplicate seller IDs',
        CAST(
            COUNT(*)
            - COUNT(DISTINCT seller_id)
            AS DECIMAL(18, 2)
        ),
        CAST(
            0 AS DECIMAL(18, 2)
        )
    FROM vw_sql_seller_performance

    UNION ALL

    SELECT
        'Seller-order associations represented',
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ),
        CAST(
            100010 AS DECIMAL(18, 2)
        )
    FROM vw_seller_order_performance

    UNION ALL

    SELECT
        'Duplicate seller-order combinations',
        CAST(
            COUNT(*)
            - COUNT(
                DISTINCT CONCAT(
                    seller_id,
                    '-',
                    order_id
                )
            ) AS DECIMAL(18, 2)
        ),
        CAST(
            0 AS DECIMAL(18, 2)
        )
    FROM vw_seller_order_performance

    UNION ALL

    SELECT
        'Item records represented',
        CAST(
            SUM(seller_order_item_count)
            AS DECIMAL(18, 2)
        ),
        CAST(
            112650 AS DECIMAL(18, 2)
        )
    FROM vw_seller_order_performance

    UNION ALL

    SELECT
        'Product value represented',
        ROUND(
            SUM(seller_order_product_value),
            2
        ),
        CAST(
            13591643.70
            AS DECIMAL(18, 2)
        )
    FROM vw_seller_order_performance

    UNION ALL

    SELECT
        'Delivered product value represented',
        ROUND(
            SUM(delivered_product_value),
            2
        ),
        CAST(
            13221498.11
            AS DECIMAL(18, 2)
        )
    FROM vw_sql_seller_performance

    UNION ALL

    SELECT
        'Reliable sellers represented',
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ),
        CAST(
            417 AS DECIMAL(18, 2)
        )
    FROM reliable_sellers

    UNION ALL

    SELECT
        'Priority candidates represented',
        CAST(
            SUM(
                average_review_score
                    < overall_review_score
                AND late_delivery_rate
                    > overall_late_delivery_rate
            ) AS DECIMAL(18, 2)
        ),
        CAST(
            111 AS DECIMAL(18, 2)
        )
    FROM reliable_sellers

    UNION ALL

    SELECT
        'Missing seller locations',
        CAST(
            COUNT(*) AS DECIMAL(18, 2)
        ),
        CAST(
            0 AS DECIMAL(18, 2)
        )
    FROM vw_sql_seller_performance
    WHERE seller_city IS NULL
       OR seller_state IS NULL
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
-- End of 07_seller_performance.sql
-- ============================================================