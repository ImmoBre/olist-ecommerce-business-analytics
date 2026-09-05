-- ============================================================
-- 08_product_category_analysis.sql
-- Olist E-commerce Business Analytics
-- Product, category and market-basket analysis
-- MySQL 8+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. CREATE ITEM-CATEGORY ANALYTICS VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_order_item_categories AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,

    p.product_category_name,

    COALESCE(
        NULLIF(
            TRIM(ct.product_category_name_english),
            ''
        ),
        'unknown'
    ) AS product_category_name_english,

    CASE
        WHEN p.product_id IS NOT NULL THEN 1
        ELSE 0
    END AS has_product_match,

    CASE
        WHEN ct.product_category_name IS NOT NULL THEN 1
        ELSE 0
    END AS has_category_translation,

    oa.customer_id,
    oa.customer_unique_id,
    oa.customer_state,
    oa.order_status,
    oa.order_purchase_timestamp,
    oa.is_delivered_order,
    oa.has_valid_review_score,
    oa.average_review_score,
    oa.has_valid_delivery_metric,
    oa.is_late_delivery,
    oa.delivery_days,
    oa.delivery_delay_days

FROM vw_order_items AS oi

LEFT JOIN vw_products AS p
    ON oi.product_id = p.product_id

LEFT JOIN vw_category_translation AS ct
    ON p.product_category_name =
       ct.product_category_name

LEFT JOIN vw_order_analytics AS oa
    ON oi.order_id = oa.order_id;


-- ============================================================
-- 2. CREATE ORDER-CATEGORY VIEW
-- One row per order and product category
-- ============================================================

CREATE OR REPLACE VIEW vw_order_categories AS
SELECT
    order_id,
    product_category_name_english,

    COUNT(*) AS item_records,
    COUNT(DISTINCT product_id) AS distinct_product_count,

    ROUND(SUM(price), 2)
        AS category_product_value,

    ROUND(SUM(freight_value), 2)
        AS category_freight_value,

    MAX(customer_unique_id)
        AS customer_unique_id,

    MAX(customer_state)
        AS customer_state,

    MAX(order_status)
        AS order_status,

    MAX(order_purchase_timestamp)
        AS order_purchase_timestamp,

    MAX(is_delivered_order)
        AS is_delivered_order,

    MAX(has_valid_review_score)
        AS has_valid_review_score,

    MAX(average_review_score)
        AS average_review_score,

    MAX(has_valid_delivery_metric)
        AS has_valid_delivery_metric,

    MAX(is_late_delivery)
        AS is_late_delivery,

    MAX(delivery_days)
        AS delivery_days,

    MAX(delivery_delay_days)
        AS delivery_delay_days

FROM vw_order_item_categories

GROUP BY
    order_id,
    product_category_name_english;


-- ============================================================
-- 3. CREATE ORDER BASKET PROFILE
-- One row per order containing item records
-- ============================================================

CREATE OR REPLACE VIEW vw_order_basket_profile AS
SELECT
    order_id,

    COUNT(*) AS item_records,

    COUNT(DISTINCT product_id)
        AS distinct_product_count,

    COUNT(DISTINCT seller_id)
        AS distinct_seller_count,

    COUNT(
        DISTINCT product_category_name_english
    ) AS distinct_category_count,

    ROUND(SUM(price), 2)
        AS product_value,

    ROUND(SUM(freight_value), 2)
        AS freight_value,

    CASE
        WHEN COUNT(*) > 1 THEN 1
        ELSE 0
    END AS is_multi_item_order,

    CASE
        WHEN COUNT(DISTINCT product_id) > 1
            THEN 1
        ELSE 0
    END AS is_multi_product_order,

    CASE
        WHEN COUNT(DISTINCT seller_id) > 1
            THEN 1
        ELSE 0
    END AS is_multi_seller_order,

    CASE
        WHEN COUNT(
            DISTINCT product_category_name_english
        ) > 1
            THEN 1
        ELSE 0
    END AS is_multi_category_order

FROM vw_order_item_categories

GROUP BY order_id;


-- ============================================================
-- 4. ITEM-CATEGORY INTEGRATION CHECK
-- ============================================================

SELECT
    COUNT(*) AS item_records,
    COUNT(DISTINCT order_id)
        AS orders_represented,
    COUNT(DISTINCT product_id)
        AS products_represented,
    COUNT(
        DISTINCT product_category_name_english
    ) AS english_categories_represented,

    SUM(
        CASE
            WHEN has_product_match = 0 THEN 1
            ELSE 0
        END
    ) AS missing_product_matches,

    SUM(
        CASE
            WHEN product_category_name_english
                     IS NULL
                 OR TRIM(
                     product_category_name_english
                 ) = ''
                THEN 1
            ELSE 0
        END
    ) AS missing_english_categories,

    ROUND(SUM(price), 2)
        AS product_value_represented,

    ROUND(SUM(freight_value), 2)
        AS freight_value_represented

FROM vw_order_item_categories;


-- ============================================================
-- 5. CATEGORY PERFORMANCE
-- All orders containing item records
-- ============================================================

WITH category_performance AS
(
    SELECT
        product_category_name_english,

        COUNT(DISTINCT order_id)
            AS orders_containing_category,

        COUNT(*) AS item_records,

        ROUND(SUM(price), 2)
            AS product_value,

        ROUND(SUM(freight_value), 2)
            AS freight_value,

        ROUND(AVG(price), 2)
            AS average_item_price

    FROM vw_order_item_categories

    GROUP BY
        product_category_name_english
),

analysis_totals AS
(
    SELECT
        COUNT(DISTINCT order_id)
            AS total_orders,

        SUM(price)
            AS total_product_value

    FROM vw_order_item_categories
)

SELECT
    cp.product_category_name_english,
    cp.orders_containing_category,
    cp.item_records,
    cp.product_value,
    cp.freight_value,
    cp.average_item_price,

    ROUND(
        100.0 *
        cp.orders_containing_category /
        NULLIF(at.total_orders, 0),
        2
    ) AS category_support_pct,

    ROUND(
        100.0 *
        cp.product_value /
        NULLIF(at.total_product_value, 0),
        2
    ) AS product_value_share_pct

FROM category_performance AS cp

CROSS JOIN analysis_totals AS at

ORDER BY
    cp.orders_containing_category DESC,
    cp.product_value DESC

LIMIT 15;


-- ============================================================
-- 6. CATEGORY COVERAGE SUMMARY
-- ============================================================

WITH category_counts AS
(
    SELECT
        product_category_name_english,
        COUNT(DISTINCT order_id)
            AS category_orders

    FROM vw_order_item_categories

    GROUP BY
        product_category_name_english
)

SELECT
    COUNT(*) AS categories_represented,

    SUM(
        CASE
            WHEN category_orders >= 100 THEN 1
            ELSE 0
        END
    ) AS categories_with_at_least_100_orders,

    SUM(
        CASE
            WHEN category_orders >= 500 THEN 1
            ELSE 0
        END
    ) AS categories_with_at_least_500_orders

FROM category_counts;


-- ============================================================
-- 7. DELIVERED CATEGORY VALUE PERFORMANCE
-- ============================================================

WITH delivered_category_performance AS
(
    SELECT
        product_category_name_english,

        COUNT(DISTINCT order_id)
            AS delivered_orders,

        SUM(item_records)
            AS delivered_item_records,

        ROUND(
            SUM(category_product_value),
            2
        ) AS delivered_product_value,

        ROUND(
            SUM(category_freight_value),
            2
        ) AS delivered_freight_value

    FROM vw_order_categories

    WHERE is_delivered_order = 1

    GROUP BY
        product_category_name_english
),

delivered_totals AS
(
    SELECT
        SUM(price)
            AS delivered_product_value

    FROM vw_order_item_categories

    WHERE is_delivered_order = 1
)

SELECT
    dcp.product_category_name_english,
    dcp.delivered_orders,
    dcp.delivered_item_records,
    dcp.delivered_product_value,
    dcp.delivered_freight_value,

    ROUND(
        100.0 *
        dcp.delivered_product_value /
        NULLIF(
            dt.delivered_product_value,
            0
        ),
        2
    ) AS delivered_product_value_share_pct

FROM delivered_category_performance AS dcp

CROSS JOIN delivered_totals AS dt

ORDER BY
    dcp.delivered_product_value DESC

LIMIT 15;


-- ============================================================
-- 8. CATEGORY DELIVERY AND SATISFACTION PERFORMANCE
-- Reliability threshold:
-- At least 500 valid delivery orders
-- and at least 500 reviewed delivered orders
-- ============================================================

WITH category_service_performance AS
(
    SELECT
        product_category_name_english,

        SUM(
            CASE
                WHEN is_delivered_order = 1
                    THEN 1
                ELSE 0
            END
        ) AS delivered_orders,

        SUM(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_review_score = 1
                    THEN 1
                ELSE 0
            END
        ) AS reviewed_delivered_orders,

        ROUND(
            AVG(
                CASE
                    WHEN is_delivered_order = 1
                     AND has_valid_review_score = 1
                        THEN average_review_score
                END
            ),
            2
        ) AS average_review_score,

        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN is_delivered_order = 1
                     AND has_valid_review_score = 1
                     AND average_review_score <= 2
                        THEN 1
                    ELSE 0
                END
            ) /
            NULLIF(
                SUM(
                    CASE
                        WHEN is_delivered_order = 1
                         AND has_valid_review_score = 1
                            THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS low_satisfaction_rate_pct,

        SUM(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_delivery_metric = 1
                    THEN 1
                ELSE 0
            END
        ) AS valid_delivery_orders,

        SUM(
            CASE
                WHEN is_delivered_order = 1
                 AND has_valid_delivery_metric = 1
                 AND is_late_delivery = 1
                    THEN 1
                ELSE 0
            END
        ) AS late_deliveries,

        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN is_delivered_order = 1
                     AND has_valid_delivery_metric = 1
                     AND is_late_delivery = 1
                        THEN 1
                    ELSE 0
                END
            ) /
            NULLIF(
                SUM(
                    CASE
                        WHEN is_delivered_order = 1
                         AND has_valid_delivery_metric = 1
                            THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS late_delivery_rate_pct,

        ROUND(
            AVG(
                CASE
                    WHEN is_delivered_order = 1
                     AND has_valid_delivery_metric = 1
                        THEN delivery_days
                END
            ),
            2
        ) AS average_delivery_days,

        ROUND(
            SUM(
                CASE
                    WHEN is_delivered_order = 1
                        THEN category_product_value
                    ELSE 0
                END
            ),
            2
        ) AS delivered_product_value

    FROM vw_order_categories

    GROUP BY
        product_category_name_english
)

SELECT
    product_category_name_english,
    delivered_orders,
    reviewed_delivered_orders,
    average_review_score,
    low_satisfaction_rate_pct,
    valid_delivery_orders,
    late_deliveries,
    late_delivery_rate_pct,
    average_delivery_days,
    delivered_product_value

FROM category_service_performance

WHERE valid_delivery_orders >= 500
  AND reviewed_delivered_orders >= 500

ORDER BY
    delivered_product_value DESC;


-- ============================================================
-- 9. BASKET STRUCTURE OVERVIEW
-- ============================================================

SELECT
    COUNT(*) AS orders_with_item_records,

    SUM(is_multi_item_order)
        AS orders_with_multiple_item_records,

    SUM(is_multi_product_order)
        AS orders_with_multiple_distinct_products,

    SUM(is_multi_category_order)
        AS orders_with_multiple_distinct_categories,

    ROUND(
        100.0 *
        SUM(is_multi_category_order) /
        NULLIF(COUNT(*), 0),
        2
    ) AS multi_category_order_rate_pct,

    MAX(item_records)
        AS maximum_items_in_one_order,

    MAX(distinct_product_count)
        AS maximum_distinct_products_in_one_order,

    MAX(distinct_category_count)
        AS maximum_distinct_categories_in_one_order

FROM vw_order_basket_profile;


-- ============================================================
-- 10. CATEGORY COUNT PER ORDER DISTRIBUTION
-- ============================================================

SELECT
    distinct_category_count
        AS distinct_categories,

    COUNT(*) AS orders,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_order_basket_profile

GROUP BY
    distinct_category_count

ORDER BY
    distinct_category_count;


-- ============================================================
-- 11. CREATE CATEGORY-PAIR METRICS VIEW
-- Each pair is stored once in alphabetical order
-- ============================================================

CREATE OR REPLACE VIEW vw_category_pair_metrics AS

WITH category_counts AS
(
    SELECT
        product_category_name_english,
        COUNT(*) AS category_orders

    FROM vw_order_categories

    GROUP BY
        product_category_name_english
),

category_pairs AS
(
    SELECT
        category_a.product_category_name_english
            AS category_a,

        category_b.product_category_name_english
            AS category_b,

        COUNT(*) AS pair_order_count

    FROM vw_order_categories AS category_a

    INNER JOIN vw_order_categories AS category_b
        ON category_a.order_id =
           category_b.order_id

       AND category_a.product_category_name_english
           <
           category_b.product_category_name_english

    GROUP BY
        category_a.product_category_name_english,
        category_b.product_category_name_english
),

basket_totals AS
(
    SELECT
        COUNT(*) AS total_orders

    FROM vw_order_basket_profile
)

SELECT
    cp.category_a,
    cp.category_b,
    cp.pair_order_count,

    category_a_count.category_orders
        AS category_a_orders,

    category_b_count.category_orders
        AS category_b_orders,

    bt.total_orders,

    cp.pair_order_count /
        NULLIF(bt.total_orders, 0)
        AS pair_support,

    category_a_count.category_orders /
        NULLIF(bt.total_orders, 0)
        AS category_a_support,

    category_b_count.category_orders /
        NULLIF(bt.total_orders, 0)
        AS category_b_support,

    cp.pair_order_count /
        NULLIF(
            category_a_count.category_orders,
            0
        ) AS confidence_a_to_b,

    cp.pair_order_count /
        NULLIF(
            category_b_count.category_orders,
            0
        ) AS confidence_b_to_a,

    (
        cp.pair_order_count * bt.total_orders
    ) /
    NULLIF(
        category_a_count.category_orders *
        category_b_count.category_orders,
        0
    ) AS lift

FROM category_pairs AS cp

INNER JOIN category_counts
    AS category_a_count
    ON cp.category_a =
       category_a_count.product_category_name_english

INNER JOIN category_counts
    AS category_b_count
    ON cp.category_b =
       category_b_count.product_category_name_english

CROSS JOIN basket_totals AS bt;


-- ============================================================
-- 12. MOST FREQUENT CATEGORY PAIRS
-- ============================================================

SELECT
    category_a,
    category_b,
    pair_order_count,
    category_a_orders,
    category_b_orders,

    ROUND(
        pair_support * 100,
        4
    ) AS pair_support_pct,

    ROUND(
        category_a_support * 100,
        2
    ) AS category_a_support_pct,

    ROUND(
        category_b_support * 100,
        2
    ) AS category_b_support_pct,

    ROUND(
        confidence_a_to_b * 100,
        2
    ) AS confidence_a_to_b_pct,

    ROUND(
        confidence_b_to_a * 100,
        2
    ) AS confidence_b_to_a_pct,

    ROUND(lift, 2) AS lift

FROM vw_category_pair_metrics

ORDER BY
    pair_order_count DESC,
    category_a,
    category_b

LIMIT 15;


-- ============================================================
-- 13. RELIABLE CATEGORY-PAIR ASSOCIATIONS
-- Minimum 100 orders for each category
-- Minimum 5 orders containing the pair
-- ============================================================

SELECT
    category_a,
    category_b,
    pair_order_count,
    category_a_orders,
    category_b_orders,

    ROUND(
        pair_support * 100,
        4
    ) AS pair_support_pct,

    ROUND(
        category_a_support * 100,
        2
    ) AS category_a_support_pct,

    ROUND(
        category_b_support * 100,
        2
    ) AS category_b_support_pct,

    ROUND(
        confidence_a_to_b * 100,
        2
    ) AS confidence_a_to_b_pct,

    ROUND(
        confidence_b_to_a * 100,
        2
    ) AS confidence_b_to_a_pct,

    ROUND(lift, 2) AS lift

FROM vw_category_pair_metrics

WHERE category_a_orders >= 100
  AND category_b_orders >= 100
  AND pair_order_count >= 5

ORDER BY
    pair_order_count DESC,
    lift DESC,
    category_a,
    category_b

LIMIT 15;


-- ============================================================
-- 14. DIRECTIONAL RULES WITH LIFT ABOVE 1
-- ============================================================

WITH reliable_pairs AS
(
    SELECT *

    FROM vw_category_pair_metrics

    WHERE category_a_orders >= 100
      AND category_b_orders >= 100
      AND pair_order_count >= 5
),

directional_rules AS
(
    SELECT
        category_a AS antecedent,
        category_b AS consequent,
        pair_order_count,
        category_a_orders AS antecedent_orders,
        category_b_orders AS consequent_orders,
        pair_support AS support,
        confidence_a_to_b AS confidence,
        lift

    FROM reliable_pairs

    UNION ALL

    SELECT
        category_b AS antecedent,
        category_a AS consequent,
        pair_order_count,
        category_b_orders AS antecedent_orders,
        category_a_orders AS consequent_orders,
        pair_support AS support,
        confidence_b_to_a AS confidence,
        lift

    FROM reliable_pairs
)

SELECT
    antecedent,
    consequent,
    pair_order_count,
    antecedent_orders,
    consequent_orders,

    ROUND(
        support * 100,
        4
    ) AS support_pct,

    ROUND(
        confidence * 100,
        2
    ) AS confidence_pct,

    ROUND(lift, 2) AS lift

FROM directional_rules

WHERE lift > 1

ORDER BY
    lift DESC,
    confidence DESC,
    antecedent,
    consequent;


-- ============================================================
-- 15. CATEGORY-PAIR FILTER SUMMARY
-- ============================================================

WITH reliable_pairs AS
(
    SELECT *

    FROM vw_category_pair_metrics

    WHERE category_a_orders >= 100
      AND category_b_orders >= 100
      AND pair_order_count >= 5
)

SELECT
    (
        SELECT COUNT(*)
        FROM vw_category_pair_metrics
    ) AS all_observed_category_pairs,

    COUNT(*) AS pairs_meeting_reliability_filters,

    COUNT(*) * 2
        AS directional_rules_after_filtering,

    SUM(
        CASE
            WHEN lift > 1 THEN 2
            ELSE 0
        END
    ) AS directional_rules_with_lift_above_1,

    ROUND(
        MAX(lift),
        2
    ) AS maximum_observed_lift

FROM reliable_pairs;


-- ============================================================
-- 16. PAIR-THRESHOLD SENSITIVITY ANALYSIS
-- ============================================================

WITH category_order_thresholds AS
(
    SELECT 50 AS minimum_category_orders
    UNION ALL
    SELECT 100
    UNION ALL
    SELECT 500
),

pair_order_thresholds AS
(
    SELECT 3 AS minimum_pair_orders
    UNION ALL
    SELECT 5
    UNION ALL
    SELECT 10
),

threshold_combinations AS
(
    SELECT
        category_threshold.minimum_category_orders,
        pair_threshold.minimum_pair_orders

    FROM category_order_thresholds
        AS category_threshold

    CROSS JOIN pair_order_thresholds
        AS pair_threshold
)

SELECT
    tc.minimum_category_orders,
    tc.minimum_pair_orders,

    COUNT(pm.category_a)
        AS retained_unordered_pairs,

    SUM(
        CASE
            WHEN pm.lift > 1 THEN 1
            ELSE 0
        END
    ) AS pairs_with_lift_above_1,

    ROUND(
        MAX(pm.lift),
        2
    ) AS maximum_lift,

    ROUND(
        MAX(pm.pair_support) * 100,
        4
    ) AS maximum_pair_support_pct

FROM threshold_combinations AS tc

LEFT JOIN vw_category_pair_metrics AS pm
    ON pm.category_a_orders >=
       tc.minimum_category_orders

   AND pm.category_b_orders >=
       tc.minimum_category_orders

   AND pm.pair_order_count >=
       tc.minimum_pair_orders

GROUP BY
    tc.minimum_category_orders,
    tc.minimum_pair_orders

ORDER BY
    tc.minimum_category_orders,
    tc.minimum_pair_orders;

-- ============================================================
-- 17. FINAL VALIDATION — OPTIMIZED VERSION
-- ============================================================

USE olist_analytics;

FLUSH TABLES;


-- ------------------------------------------------------------
-- 17.1 ITEM AND CATEGORY VALIDATION
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS item_records,
    112650 AS expected_item_records,

    CASE
        WHEN COUNT(*) = 112650 THEN 'Passed'
        ELSE 'Failed'
    END AS item_records_status,

    COUNT(*) -
    COUNT(
        DISTINCT CONCAT_WS(
            '|',
            order_id,
            order_item_id
        )
    ) AS duplicate_order_item_keys,

    CASE
        WHEN COUNT(*) -
             COUNT(
                 DISTINCT CONCAT_WS(
                     '|',
                     order_id,
                     order_item_id
                 )
             ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS duplicate_keys_status,

    SUM(
        CASE
            WHEN has_product_match = 0 THEN 1
            ELSE 0
        END
    ) AS missing_product_matches,

    CASE
        WHEN SUM(
            CASE
                WHEN has_product_match = 0 THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS product_match_status,

    SUM(
        CASE
            WHEN product_category_name_english IS NULL
              OR TRIM(product_category_name_english) = ''
                THEN 1
            ELSE 0
        END
    ) AS missing_category_labels,

    CASE
        WHEN SUM(
            CASE
                WHEN product_category_name_english IS NULL
                  OR TRIM(product_category_name_english) = ''
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS category_label_status,

    ROUND(SUM(price), 2) AS product_value,
    13591643.70 AS expected_product_value,

    CASE
        WHEN ABS(
            ROUND(SUM(price), 2) -
            13591643.70
        ) <= 0.01
            THEN 'Passed'
        ELSE 'Failed'
    END AS product_value_status,

    ROUND(SUM(freight_value), 2) AS freight_value,
    2251909.54 AS expected_freight_value,

    CASE
        WHEN ABS(
            ROUND(SUM(freight_value), 2) -
            2251909.54
        ) <= 0.01
            THEN 'Passed'
        ELSE 'Failed'
    END AS freight_value_status

FROM vw_order_item_categories;

-- ------------------------------------------------------------
-- 17.2 BASKET-PROFILE VALIDATION
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS basket_profile_orders,
    98666 AS expected_basket_profile_orders,

    CASE
        WHEN COUNT(*) = 98666 THEN 'Passed'
        ELSE 'Failed'
    END AS basket_profile_status,

    COUNT(*) -
    COUNT(DISTINCT order_id)
        AS duplicate_basket_order_ids,

    CASE
        WHEN COUNT(*) -
             COUNT(DISTINCT order_id) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS duplicate_basket_status,

    SUM(is_multi_category_order)
        AS multi_category_orders,

    786 AS expected_multi_category_orders,

    CASE
        WHEN SUM(is_multi_category_order) = 786
            THEN 'Passed'
        ELSE 'Failed'
    END AS multi_category_status

FROM vw_order_basket_profile;

-- ------------------------------------------------------------
-- 17.3 CATEGORY-PAIR VALIDATION
-- ------------------------------------------------------------

SELECT
    SUM(pair_order_count)
        AS category_pair_occurrences,

    822 AS expected_pair_occurrences,

    CASE
        WHEN SUM(pair_order_count) = 822
            THEN 'Passed'
        ELSE 'Failed'
    END AS pair_occurrence_status,

    COUNT(*) AS observed_unordered_pairs,
    262 AS expected_unordered_pairs,

    CASE
        WHEN COUNT(*) = 262
            THEN 'Passed'
        ELSE 'Failed'
    END AS unordered_pair_status,

    COUNT(*) -
    COUNT(
        DISTINCT CONCAT_WS(
            '|',
            category_a,
            category_b
        )
    ) AS duplicate_unordered_pairs,

    CASE
        WHEN COUNT(*) -
             COUNT(
                 DISTINCT CONCAT_WS(
                     '|',
                     category_a,
                     category_b
                 )
             ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS duplicate_pair_status,

    SUM(
        CASE
            WHEN category_a_orders >= 100
             AND category_b_orders >= 100
             AND pair_order_count >= 5
                THEN 1
            ELSE 0
        END
    ) AS filtered_unordered_pairs,

    41 AS expected_filtered_pairs,

    CASE
        WHEN SUM(
            CASE
                WHEN category_a_orders >= 100
                 AND category_b_orders >= 100
                 AND pair_order_count >= 5
                    THEN 1
                ELSE 0
            END
        ) = 41
            THEN 'Passed'
        ELSE 'Failed'
    END AS filtered_pair_status,

    2 * SUM(
        CASE
            WHEN category_a_orders >= 100
             AND category_b_orders >= 100
             AND pair_order_count >= 5
                THEN 1
            ELSE 0
        END
    ) AS directional_rules,

    82 AS expected_directional_rules,

    CASE
        WHEN 2 * SUM(
            CASE
                WHEN category_a_orders >= 100
                 AND category_b_orders >= 100
                 AND pair_order_count >= 5
                    THEN 1
                ELSE 0
            END
        ) = 82
            THEN 'Passed'
        ELSE 'Failed'
    END AS directional_rule_status,

    SUM(
        CASE
            WHEN pair_support < 0
              OR pair_support > 1
              OR category_a_support < 0
              OR category_a_support > 1
              OR category_b_support < 0
              OR category_b_support > 1
              OR confidence_a_to_b < 0
              OR confidence_a_to_b > 1
              OR confidence_b_to_a < 0
              OR confidence_b_to_a > 1
              OR lift < 0
              OR lift IS NULL
                THEN 1
            ELSE 0
        END
    ) AS invalid_pair_metrics,

    CASE
        WHEN SUM(
            CASE
                WHEN pair_support < 0
                  OR pair_support > 1
                  OR category_a_support < 0
                  OR category_a_support > 1
                  OR category_b_support < 0
                  OR category_b_support > 1
                  OR confidence_a_to_b < 0
                  OR confidence_a_to_b > 1
                  OR confidence_b_to_a < 0
                  OR confidence_b_to_a > 1
                  OR lift < 0
                  OR lift IS NULL
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS pair_metric_status

FROM vw_category_pair_metrics;















