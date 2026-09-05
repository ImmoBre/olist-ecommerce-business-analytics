-- ============================================================
-- 09_review_satisfaction.sql
-- Olist E-commerce Business Analytics
-- Review-score and customer-satisfaction analysis
-- MySQL 8+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. CREATE REVIEW-SATISFACTION VIEW
-- One row per order with a valid review score
--
-- average_review_score is used for order-level satisfaction.
-- latest_review_score is retained for the 1-5 distribution.
-- ============================================================

CREATE OR REPLACE VIEW vw_review_satisfaction AS
SELECT
    oa.order_id,
    oa.customer_id,
    oa.customer_unique_id,
    oa.customer_city,
    oa.customer_state,

    oa.order_status,
    oa.order_purchase_timestamp,
    oa.purchase_year,
    oa.purchase_month,
    oa.purchase_year_month,

    oa.review_record_count,

    oa.average_review_score
        AS review_score,

    oa.minimum_review_score,
    oa.maximum_review_score,
    oa.latest_review_score,
    oa.latest_review_date,
    oa.latest_review_answer_timestamp,

    oa.has_written_feedback,
    oa.written_feedback_count,

    oa.is_delivered_order,
    oa.has_valid_delivery_metric,
    oa.is_late_delivery,
    oa.is_on_time_delivery,
    oa.delivery_days,
    oa.delivery_delay_days,
    oa.days_late,

    oa.item_count,
    oa.product_value,
    oa.freight_value,
    oa.total_payment_value,

    CASE
        WHEN oa.average_review_score <= 2
            THEN 1
        ELSE 0
    END AS low_review_flag,

    CASE
        WHEN oa.average_review_score <= 2
            THEN 'Low satisfaction (1-2)'

        WHEN oa.average_review_score < 4
            THEN 'Neutral (3)'

        WHEN oa.average_review_score <= 5
            THEN 'High satisfaction (4-5)'

        ELSE 'Invalid or missing'
    END AS satisfaction_group,

    CASE
        WHEN oa.average_review_score <= 2 THEN 1
        WHEN oa.average_review_score < 4 THEN 2
        WHEN oa.average_review_score <= 5 THEN 3
        ELSE 4
    END AS satisfaction_group_rank,

    CASE
        WHEN oa.has_written_feedback = 1
            THEN 'Written feedback'
        ELSE 'Rating only'
    END AS feedback_group,

    CASE
        WHEN oa.is_delivered_order <> 1
            THEN 'Not delivered'

        WHEN oa.has_valid_delivery_metric <> 1
            THEN 'Delivery metric unavailable'

        WHEN oa.is_late_delivery = 1
            THEN 'Late delivery'

        ELSE 'On-time or early delivery'
    END AS delivery_performance_group

FROM vw_order_analytics AS oa

WHERE oa.has_valid_review_score = 1;


-- ============================================================
-- 2. REVIEW-SATISFACTION OVERVIEW
-- ============================================================

SELECT
    COUNT(*) AS reviewed_orders,

    SUM(review_record_count)
        AS review_records,

    SUM(is_delivered_order)
        AS reviewed_delivered_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    SUM(
        CASE
            WHEN has_written_feedback = 1
                THEN 1
            ELSE 0
        END
    ) AS orders_with_written_feedback,

    SUM(written_feedback_count)
        AS written_feedback_records,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN has_written_feedback = 1
                    THEN 1
                ELSE 0
            END
        ) /
        NULLIF(COUNT(*), 0),
        2
    ) AS written_feedback_order_rate_pct

FROM vw_review_satisfaction;


-- ============================================================
-- 3. LATEST REVIEW-SCORE DISTRIBUTION
-- latest_review_score is an individual 1-5 score.
-- ============================================================

SELECT
    latest_review_score AS review_score,

    COUNT(*) AS orders,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_review_satisfaction

WHERE latest_review_score BETWEEN 1 AND 5

GROUP BY
    latest_review_score

ORDER BY
    latest_review_score;


-- ============================================================
-- 4. SATISFACTION-GROUP SUMMARY
-- ============================================================

SELECT
    satisfaction_group,

    COUNT(*) AS reviewed_orders,

    SUM(is_delivered_order)
        AS delivered_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(
        CASE
            WHEN has_written_feedback = 1
                THEN 1
            ELSE 0
        END
    ) AS orders_with_written_feedback,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN has_written_feedback = 1
                    THEN 1
                ELSE 0
            END
        ) /
        NULLIF(COUNT(*), 0),
        2
    ) AS written_feedback_rate_pct,

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
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS reviewed_order_share_pct

FROM vw_review_satisfaction

GROUP BY
    satisfaction_group,
    satisfaction_group_rank

ORDER BY
    satisfaction_group_rank;


-- ============================================================
-- 5. SINGLE-REVIEW VS MULTIPLE-REVIEW ORDERS
-- ============================================================

SELECT
    CASE
        WHEN review_record_count = 1
            THEN 'One review record'
        ELSE 'Multiple review records'
    END AS review_record_group,

    COUNT(*) AS orders,

    SUM(review_record_count)
        AS review_records,

    ROUND(
        AVG(review_record_count),
        2
    ) AS average_reviews_per_order,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS reviewed_order_share_pct

FROM vw_review_satisfaction

GROUP BY
    CASE
        WHEN review_record_count = 1
            THEN 'One review record'
        ELSE 'Multiple review records'
    END

ORDER BY
    MIN(review_record_count);


-- ============================================================
-- 6. WRITTEN FEEDBACK VS RATING-ONLY REVIEWS
-- ============================================================

SELECT
    feedback_group,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

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
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS reviewed_order_share_pct

FROM vw_review_satisfaction

GROUP BY
    feedback_group

ORDER BY
    CASE
        WHEN feedback_group = 'Written feedback'
            THEN 1
        ELSE 2
    END;


-- ============================================================
-- 7. REVIEW PERFORMANCE BY ORDER STATUS
-- ============================================================

SELECT
    order_status,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    SUM(
        CASE
            WHEN is_delivered_order = 1
             AND has_valid_delivery_metric = 1
                THEN 1
            ELSE 0
        END
    ) AS valid_delivery_records,

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
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS review_share_pct

FROM vw_review_satisfaction

GROUP BY
    order_status

ORDER BY
    reviewed_orders DESC;


-- ============================================================
-- 8. SATISFACTION BY DELIVERY PERFORMANCE
--
-- These are descriptive associations and should not be
-- interpreted as proof that delivery timing caused the review.
-- ============================================================

SELECT
    delivery_performance_group,

    COUNT(*) AS reviewed_delivered_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    ROUND(
        AVG(
            CASE
                WHEN has_valid_delivery_metric = 1
                    THEN delivery_days
            END
        ),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN has_valid_delivery_metric = 1
                    THEN delivery_delay_days
            END
        ),
        2
    ) AS average_delivery_delay_days,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS reviewed_delivered_order_share_pct

FROM vw_review_satisfaction

WHERE is_delivered_order = 1

GROUP BY
    delivery_performance_group

ORDER BY
    CASE
        WHEN delivery_performance_group =
             'On-time or early delivery'
            THEN 1

        WHEN delivery_performance_group =
             'Late delivery'
            THEN 2

        ELSE 3
    END;


-- ============================================================
-- 9. REVIEW PERFORMANCE BY DELAY SEVERITY
-- Only reviewed delivered orders with valid delivery metrics
-- ============================================================

WITH delay_severity AS
(
    SELECT
        *,

        CASE
            WHEN delivery_delay_days <= 0
                THEN 'On time or early'

            WHEN delivery_delay_days <= 3
                THEN '1-3 days late'

            WHEN delivery_delay_days <= 7
                THEN '4-7 days late'

            WHEN delivery_delay_days <= 14
                THEN '8-14 days late'

            ELSE 'More than 14 days late'
        END AS delay_group,

        CASE
            WHEN delivery_delay_days <= 0 THEN 1
            WHEN delivery_delay_days <= 3 THEN 2
            WHEN delivery_delay_days <= 7 THEN 3
            WHEN delivery_delay_days <= 14 THEN 4
            ELSE 5
        END AS delay_group_rank

    FROM vw_review_satisfaction

    WHERE is_delivered_order = 1
      AND has_valid_delivery_metric = 1
)

SELECT
    delay_group,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(delivery_delay_days),
        2
    ) AS average_delivery_delay_days,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS reviewed_order_share_pct

FROM delay_severity

GROUP BY
    delay_group,
    delay_group_rank

ORDER BY
    delay_group_rank;


-- ============================================================
-- 10. MONTHLY SATISFACTION TREND
-- Complete period: January 2017-August 2018
-- ============================================================

WITH monthly_satisfaction AS
(
    SELECT
        STR_TO_DATE(
            CONCAT(
                purchase_year,
                '-',
                LPAD(purchase_month, 2, '0'),
                '-01'
            ),
            '%Y-%m-%d'
        ) AS purchase_month_start,

        COUNT(*) AS reviewed_orders,

        SUM(review_score)
            AS review_score_total,

        SUM(low_review_flag)
            AS low_review_orders,

        SUM(
            CASE
                WHEN has_written_feedback = 1
                    THEN 1
                ELSE 0
            END
        ) AS orders_with_written_feedback

    FROM vw_review_satisfaction

    WHERE purchase_year = 2017

       OR (
            purchase_year = 2018
            AND purchase_month BETWEEN 1 AND 8
       )

    GROUP BY
        purchase_year,
        purchase_month
)

SELECT
    purchase_month_start,
    reviewed_orders,
    low_review_orders,

    ROUND(
        review_score_total /
        NULLIF(reviewed_orders, 0),
        2
    ) AS average_review_score,

    ROUND(
        100.0 *
        low_review_orders /
        NULLIF(reviewed_orders, 0),
        2
    ) AS low_review_rate_pct,

    ROUND(
        100.0 *
        orders_with_written_feedback /
        NULLIF(reviewed_orders, 0),
        2
    ) AS written_feedback_rate_pct,

    ROUND(
        SUM(review_score_total) OVER
        (
            ORDER BY purchase_month_start
            ROWS BETWEEN 2 PRECEDING
                     AND CURRENT ROW
        ) /
        NULLIF(
            SUM(reviewed_orders) OVER
            (
                ORDER BY purchase_month_start
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW
            ),
            0
        ),
        2
    ) AS rolling_3_month_average_review_score,

    ROUND(
        100.0 *
        SUM(low_review_orders) OVER
        (
            ORDER BY purchase_month_start
            ROWS BETWEEN 2 PRECEDING
                     AND CURRENT ROW
        ) /
        NULLIF(
            SUM(reviewed_orders) OVER
            (
                ORDER BY purchase_month_start
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW
            ),
            0
        ),
        2
    ) AS rolling_3_month_low_review_rate_pct

FROM monthly_satisfaction

ORDER BY
    purchase_month_start;
-- ============================================================
-- 11. CUSTOMER-STATE SATISFACTION PERFORMANCE
-- Reliability threshold: at least 500 reviewed delivered orders
-- ============================================================

SELECT
    customer_state,

    COUNT(*) AS reviewed_delivered_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    SUM(
        CASE
            WHEN has_valid_delivery_metric = 1
                THEN 1
            ELSE 0
        END
    ) AS valid_delivery_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN has_valid_delivery_metric = 1
                 AND is_late_delivery = 1
                    THEN 1
                ELSE 0
            END
        ) /
        NULLIF(
            SUM(
                CASE
                    WHEN has_valid_delivery_metric = 1
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
                WHEN has_valid_delivery_metric = 1
                    THEN delivery_days
            END
        ),
        2
    ) AS average_delivery_days,

    ROUND(
        SUM(product_value),
        2
    ) AS delivered_product_value,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS reviewed_delivered_order_share_pct

FROM vw_review_satisfaction

WHERE is_delivered_order = 1
  AND customer_state IS NOT NULL
  AND TRIM(customer_state) <> ''

GROUP BY
    customer_state

HAVING COUNT(*) >= 500

ORDER BY
    reviewed_delivered_orders DESC;


-- ============================================================
-- 12. LOW-REVIEW AND LATE-DELIVERY OVERLAP
-- Only orders with valid delivery metrics
-- ============================================================

WITH review_delivery_matrix AS
(
    SELECT
        CASE
            WHEN low_review_flag = 1
             AND is_late_delivery = 1
                THEN 'Low review and late delivery'

            WHEN low_review_flag = 1
             AND is_late_delivery = 0
                THEN 'Low review without late delivery'

            WHEN low_review_flag = 0
             AND is_late_delivery = 1
                THEN 'Review 3-5 and late delivery'

            ELSE 'Review 3-5 without late delivery'
        END AS outcome_group,

        CASE
            WHEN low_review_flag = 1
             AND is_late_delivery = 1
                THEN 1

            WHEN low_review_flag = 1
             AND is_late_delivery = 0
                THEN 2

            WHEN low_review_flag = 0
             AND is_late_delivery = 1
                THEN 3

            ELSE 4
        END AS outcome_group_rank

    FROM vw_review_satisfaction

    WHERE is_delivered_order = 1
      AND has_valid_delivery_metric = 1
)

SELECT
    outcome_group,

    COUNT(*) AS orders,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM review_delivery_matrix

GROUP BY
    outcome_group,
    outcome_group_rank

ORDER BY
    outcome_group_rank;


-- ============================================================
-- 13. LATE VS ON-TIME REVIEW COMPARISON
-- ============================================================

SELECT
    CASE
        WHEN is_late_delivery = 1
            THEN 'Late delivery'
        ELSE 'On-time or early delivery'
    END AS delivery_group,

    COUNT(*) AS reviewed_orders,

    SUM(low_review_flag)
        AS low_review_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,

    ROUND(
        100.0 *
        SUM(low_review_flag) /
        NULLIF(COUNT(*), 0),
        2
    ) AS low_review_rate_pct,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(delivery_delay_days),
        2
    ) AS average_delivery_delay_days

FROM vw_review_satisfaction

WHERE is_delivered_order = 1
  AND has_valid_delivery_metric = 1

GROUP BY
    is_late_delivery

ORDER BY
    is_late_delivery;


-- ============================================================
-- 14. FINAL VALIDATION — CORRECTED
-- ============================================================

SELECT
    COUNT(*) AS reviewed_orders,
    98673 AS expected_reviewed_orders,

    CASE
        WHEN COUNT(*) = 98673
            THEN 'Passed'
        ELSE 'Failed'
    END AS reviewed_orders_status,

    SUM(review_record_count)
        AS review_records,

    99224 AS expected_review_records,

    CASE
        WHEN SUM(review_record_count) = 99224
            THEN 'Passed'
        ELSE 'Failed'
    END AS review_records_status,

    SUM(is_delivered_order)
        AS reviewed_delivered_orders,

    95832 AS expected_reviewed_delivered_orders,

    CASE
        WHEN SUM(is_delivered_order) = 95832
            THEN 'Passed'
        ELSE 'Failed'
    END AS reviewed_delivered_status,

    SUM(
        CASE
            WHEN is_delivered_order = 1
             AND low_review_flag = 1
                THEN 1
            ELSE 0
        END
    ) AS low_review_delivered_orders,

    12273 AS expected_low_review_delivered_orders,

    CASE
        WHEN SUM(
            CASE
                WHEN is_delivered_order = 1
                 AND low_review_flag = 1
                    THEN 1
                ELSE 0
            END
        ) = 12273
            THEN 'Passed'
        ELSE 'Failed'
    END AS low_review_delivered_status,

    SUM(written_feedback_count)
        AS written_feedback_records,

    42706 AS expected_written_feedback_records,

    CASE
        WHEN SUM(written_feedback_count) = 42706
            THEN 'Passed'
        ELSE 'Failed'
    END AS written_feedback_status,

    COUNT(*) -
    COUNT(DISTINCT order_id)
        AS duplicate_order_ids,

    CASE
        WHEN COUNT(*) -
             COUNT(DISTINCT order_id) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS duplicate_order_status,

    SUM(
        CASE
            WHEN review_score IS NULL
              OR review_score < 1
              OR review_score > 5
                THEN 1
            ELSE 0
        END
    ) AS invalid_average_review_scores,

    CASE
        WHEN SUM(
            CASE
                WHEN review_score IS NULL
                  OR review_score < 1
                  OR review_score > 5
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS average_review_score_status,

    SUM(
        CASE
            WHEN latest_review_score IS NULL
              OR latest_review_score < 1
              OR latest_review_score > 5
                THEN 1
            ELSE 0
        END
    ) AS invalid_latest_review_scores,

    CASE
        WHEN SUM(
            CASE
                WHEN latest_review_score IS NULL
                  OR latest_review_score < 1
                  OR latest_review_score > 5
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS latest_review_score_status,

    SUM(
        CASE
            WHEN satisfaction_group =
                 'Invalid or missing'
                THEN 1
            ELSE 0
        END
    ) AS missing_satisfaction_groups,

    CASE
        WHEN SUM(
            CASE
                WHEN satisfaction_group =
                     'Invalid or missing'
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS satisfaction_group_status,

    SUM(
        CASE
            WHEN review_record_count < 1
                THEN 1
            ELSE 0
        END
    ) AS invalid_review_record_counts,

    CASE
        WHEN SUM(
            CASE
                WHEN review_record_count < 1
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS review_record_count_status,

    SUM(
        CASE
            WHEN minimum_review_score > review_score
              OR maximum_review_score < review_score
              OR minimum_review_score >
                 maximum_review_score
                THEN 1
            ELSE 0
        END
    ) AS inconsistent_review_score_ranges,

    CASE
        WHEN SUM(
            CASE
                WHEN minimum_review_score > review_score
                  OR maximum_review_score < review_score
                  OR minimum_review_score >
                     maximum_review_score
                    THEN 1
                ELSE 0
            END
        ) = 0
            THEN 'Passed'
        ELSE 'Failed'
    END AS review_score_range_status

FROM vw_review_satisfaction;














