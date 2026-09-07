-- ============================================================
-- Olist E-commerce Analytics
-- 02 - Typed Analytical Views
-- Database engine: MySQL 8.0+
-- ============================================================

USE olist_analytics;


-- ============================================================
-- 1. Typed order-level analytical view
-- ============================================================

CREATE OR REPLACE VIEW vw_order_analytics AS

SELECT
    NULLIF(TRIM(order_id), '') AS order_id,
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(order_status), '') AS order_status,

    CAST(
        NULLIF(order_purchase_timestamp, '')
        AS DATETIME
    ) AS order_purchase_timestamp,

    CAST(
        NULLIF(order_approved_at, '')
        AS DATETIME
    ) AS order_approved_at,

    CAST(
        NULLIF(order_delivered_carrier_date, '')
        AS DATETIME
    ) AS order_delivered_carrier_date,

    CAST(
        NULLIF(order_delivered_customer_date, '')
        AS DATETIME
    ) AS order_delivered_customer_date,

    CAST(
        NULLIF(order_estimated_delivery_date, '')
        AS DATETIME
    ) AS order_estimated_delivery_date,

    CASE LOWER(NULLIF(carrier_before_purchase, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS carrier_before_purchase,

    CASE LOWER(NULLIF(delivery_before_purchase, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS delivery_before_purchase,

    CASE LOWER(NULLIF(delivery_before_carrier, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS delivery_before_carrier,

    CASE LOWER(NULLIF(has_invalid_timestamp_sequence, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_invalid_timestamp_sequence,

    CASE LOWER(NULLIF(has_complete_delivery_timestamps, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_complete_delivery_timestamps,

    CASE LOWER(NULLIF(is_valid_for_delivery_analysis, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS is_valid_for_delivery_analysis,

    CASE LOWER(NULLIF(has_order_items, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_order_items,

    CASE LOWER(NULLIF(has_payment, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_payment,

    CASE LOWER(NULLIF(has_review, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_review,

    NULLIF(TRIM(customer_unique_id), '')
        AS customer_unique_id,

    NULLIF(TRIM(customer_zip_code_prefix), '')
        AS customer_zip_code_prefix,

    NULLIF(TRIM(customer_city), '')
        AS customer_city,

    NULLIF(TRIM(customer_state), '')
        AS customer_state,

    CAST(
        NULLIF(item_count, '')
        AS UNSIGNED
    ) AS item_count,

    CAST(
        NULLIF(distinct_product_count, '')
        AS UNSIGNED
    ) AS distinct_product_count,

    CAST(
        NULLIF(distinct_seller_count, '')
        AS UNSIGNED
    ) AS distinct_seller_count,

    CAST(
        NULLIF(product_value, '')
        AS DECIMAL(18, 2)
    ) AS product_value,

    CAST(
        NULLIF(freight_value, '')
        AS DECIMAL(18, 2)
    ) AS freight_value,

    CAST(
        NULLIF(average_item_price, '')
        AS DECIMAL(18, 2)
    ) AS average_item_price,

    CAST(
        NULLIF(maximum_shipping_limit, '')
        AS DATETIME
    ) AS maximum_shipping_limit,

    CAST(
        NULLIF(item_total_value, '')
        AS DECIMAL(18, 2)
    ) AS item_total_value,

    CAST(
        NULLIF(payment_record_count, '')
        AS UNSIGNED
    ) AS payment_record_count,

    CAST(
        NULLIF(payment_method_count, '')
        AS UNSIGNED
    ) AS payment_method_count,

    CAST(
        NULLIF(total_payment_value, '')
        AS DECIMAL(18, 2)
    ) AS total_payment_value,

    CAST(
        NULLIF(maximum_installments, '')
        AS UNSIGNED
    ) AS maximum_installments,

    CASE LOWER(NULLIF(has_zero_payment, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_zero_payment,

    CASE LOWER(NULLIF(has_payment_anomaly, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_payment_anomaly,

    NULLIF(TRIM(primary_payment_type), '')
        AS primary_payment_type,

    CAST(
        NULLIF(review_record_count, '')
        AS UNSIGNED
    ) AS review_record_count,

    CAST(
        NULLIF(average_review_score, '')
        AS DECIMAL(5, 2)
    ) AS average_review_score,

    CAST(
        NULLIF(minimum_review_score, '')
        AS DECIMAL(5, 2)
    ) AS minimum_review_score,

    CAST(
        NULLIF(maximum_review_score, '')
        AS DECIMAL(5, 2)
    ) AS maximum_review_score,

    CASE LOWER(NULLIF(has_written_feedback, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_written_feedback,

    CAST(
        NULLIF(written_feedback_count, '')
        AS UNSIGNED
    ) AS written_feedback_count,

    CAST(
        NULLIF(latest_review_score, '')
        AS DECIMAL(5, 2)
    ) AS latest_review_score,

    CAST(
        NULLIF(latest_review_date, '')
        AS DATE
    ) AS latest_review_date,

    CAST(
        NULLIF(latest_review_answer_timestamp, '')
        AS DATETIME
    ) AS latest_review_answer_timestamp,

    CAST(
        NULLIF(purchase_date, '')
        AS DATE
    ) AS purchase_date,

    CAST(
        NULLIF(purchase_year, '')
        AS UNSIGNED
    ) AS purchase_year,

    CAST(
        NULLIF(purchase_month, '')
        AS UNSIGNED
    ) AS purchase_month,

    NULLIF(TRIM(purchase_year_month), '')
        AS purchase_year_month,

    NULLIF(TRIM(purchase_quarter), '')
        AS purchase_quarter,

    CAST(
        NULLIF(delivery_days, '')
        AS DECIMAL(12, 4)
    ) AS delivery_days,

    CAST(
        NULLIF(carrier_to_customer_days, '')
        AS DECIMAL(12, 4)
    ) AS carrier_to_customer_days,

    CAST(
        NULLIF(delivery_delay_days, '')
        AS DECIMAL(12, 4)
    ) AS delivery_delay_days,

    CAST(
        NULLIF(days_late, '')
        AS DECIMAL(12, 4)
    ) AS days_late,

    CASE LOWER(NULLIF(is_late_delivery, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS is_late_delivery,

    CASE LOWER(NULLIF(is_on_time_delivery, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS is_on_time_delivery,

    CASE LOWER(NULLIF(is_delivered_order, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS is_delivered_order,

    CASE LOWER(NULLIF(has_valid_review_score, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_valid_review_score,

    CASE LOWER(NULLIF(has_valid_delivery_metric, ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_valid_delivery_metric,

    CAST(
        NULLIF(late_delivery_flag_numeric, '')
        AS UNSIGNED
    ) AS late_delivery_flag_numeric

FROM order_analytics;

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    MIN(order_purchase_timestamp) AS first_purchase,
    MAX(order_purchase_timestamp) AS last_purchase,
    SUM(total_payment_value) AS payment_value,
    SUM(product_value) AS product_value
FROM vw_order_analytics;

SELECT
    GROUP_CONCAT(
        column_name
        ORDER BY ordinal_position
        SEPARATOR ', '
    ) AS customer_columns
FROM information_schema.columns
WHERE table_schema = 'olist_analytics'
  AND table_name = 'customer_analytics';
  
  -- ============================================================
-- 2. Typed customer-level analytical view
-- ============================================================

USE olist_analytics;

CREATE OR REPLACE VIEW vw_customer_analytics AS

SELECT
    NULLIF(TRIM(customer_unique_id), '')
        AS customer_unique_id,

    CAST(
        NULLIF(TRIM(order_count), '')
        AS UNSIGNED
    ) AS order_count,

    STR_TO_DATE(
        NULLIF(TRIM(first_purchase_timestamp), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS first_purchase_timestamp,

    STR_TO_DATE(
        NULLIF(TRIM(last_purchase_timestamp), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS last_purchase_timestamp,

    CAST(
        NULLIF(TRIM(delivered_order_count), '')
        AS UNSIGNED
    ) AS delivered_order_count,

    CAST(
        NULLIF(TRIM(observed_product_value), '')
        AS DECIMAL(18, 2)
    ) AS observed_product_value,

    CAST(
        NULLIF(TRIM(observed_freight_value), '')
        AS DECIMAL(18, 2)
    ) AS observed_freight_value,

    CAST(
        NULLIF(TRIM(observed_payment_value), '')
        AS DECIMAL(18, 2)
    ) AS observed_payment_value,

    CAST(
        NULLIF(TRIM(average_order_payment_value), '')
        AS DECIMAL(18, 2)
    ) AS average_order_payment_value,

    CAST(
        NULLIF(TRIM(reviewed_order_count), '')
        AS UNSIGNED
    ) AS reviewed_order_count,

    CAST(
        NULLIF(TRIM(average_review_score), '')
        AS DECIMAL(5, 2)
    ) AS average_review_score,

    CAST(
        NULLIF(TRIM(valid_delivery_order_count), '')
        AS UNSIGNED
    ) AS valid_delivery_order_count,

    CAST(
        NULLIF(TRIM(late_delivery_count), '')
        AS UNSIGNED
    ) AS late_delivery_count,

    CAST(
        NULLIF(TRIM(average_delivery_days), '')
        AS DECIMAL(12, 4)
    ) AS average_delivery_days,

    CASE LOWER(NULLIF(TRIM(is_repeat_customer), ''))
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS is_repeat_customer,

    CAST(
        NULLIF(TRIM(observed_customer_tenure_days), '')
        AS DECIMAL(12, 4)
    ) AS observed_customer_tenure_days,

    CAST(
        NULLIF(TRIM(late_delivery_rate), '')
        AS DECIMAL(12, 6)
    ) AS late_delivery_rate,

    NULLIF(TRIM(latest_customer_zip_code_prefix), '')
        AS latest_customer_zip_code_prefix,

    NULLIF(TRIM(latest_customer_city), '')
        AS latest_customer_city,

    NULLIF(TRIM(latest_customer_state), '')
        AS latest_customer_state

FROM customer_analytics;


-- Validate the customer view.

SELECT
    COUNT(*) AS customers,
    SUM(
        first_purchase_timestamp IS NOT NULL
    ) AS customers_with_first_purchase,
    MIN(first_purchase_timestamp)
        AS first_observed_purchase,
    MAX(last_purchase_timestamp)
        AS last_observed_purchase
FROM vw_customer_analytics;

SELECT
    GROUP_CONCAT(
        column_name
        ORDER BY ordinal_position
        SEPARATOR ', '
    ) AS seller_columns
FROM information_schema.columns
WHERE table_schema = 'olist_analytics'
  AND table_name = 'seller_analytics';

-- ============================================================
-- 3. Typed seller-level analytical view
-- ============================================================

USE olist_analytics;

CREATE OR REPLACE VIEW vw_seller_analytics AS

SELECT
    NULLIF(TRIM(seller_id), '')
        AS seller_id,

    CAST(
        NULLIF(TRIM(order_count), '')
        AS UNSIGNED
    ) AS order_count,

    CAST(
        NULLIF(TRIM(item_count), '')
        AS UNSIGNED
    ) AS item_count,

    CAST(
        NULLIF(TRIM(distinct_customer_count), '')
        AS UNSIGNED
    ) AS distinct_customer_count,

    STR_TO_DATE(
        NULLIF(TRIM(first_order_timestamp), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS first_order_timestamp,

    STR_TO_DATE(
        NULLIF(TRIM(last_order_timestamp), ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS last_order_timestamp,

    CAST(
        NULLIF(TRIM(delivered_order_count), '')
        AS UNSIGNED
    ) AS delivered_order_count,

    CAST(
        NULLIF(TRIM(observed_product_value), '')
        AS DECIMAL(18, 2)
    ) AS observed_product_value,

    CAST(
        NULLIF(TRIM(observed_freight_value), '')
        AS DECIMAL(18, 2)
    ) AS observed_freight_value,

    CAST(
        NULLIF(TRIM(average_seller_order_value), '')
        AS DECIMAL(18, 2)
    ) AS average_seller_order_value,

    CAST(
        NULLIF(TRIM(reviewed_order_count), '')
        AS UNSIGNED
    ) AS reviewed_order_count,

    CAST(
        NULLIF(TRIM(average_review_score), '')
        AS DECIMAL(5, 2)
    ) AS average_review_score,

    CAST(
        NULLIF(TRIM(valid_delivery_order_count), '')
        AS UNSIGNED
    ) AS valid_delivery_order_count,

    CAST(
        NULLIF(TRIM(late_delivery_count), '')
        AS UNSIGNED
    ) AS late_delivery_count,

    CAST(
        NULLIF(TRIM(average_delivery_days), '')
        AS DECIMAL(12, 4)
    ) AS average_delivery_days,

    CAST(
        NULLIF(TRIM(average_delivery_delay_days), '')
        AS DECIMAL(12, 4)
    ) AS average_delivery_delay_days,

    NULLIF(TRIM(seller_zip_code_prefix), '')
        AS seller_zip_code_prefix,

    NULLIF(TRIM(seller_city), '')
        AS seller_city,

    NULLIF(TRIM(seller_state), '')
        AS seller_state,

    CAST(
        NULLIF(TRIM(late_delivery_rate), '')
        AS DECIMAL(12, 6)
    ) AS late_delivery_rate

FROM seller_analytics;

-- Validate the seller view.

SELECT
    COUNT(*) AS sellers,
    SUM(
        first_order_timestamp IS NOT NULL
    ) AS sellers_with_first_order,
    MIN(first_order_timestamp)
        AS first_observed_order,
    MAX(last_order_timestamp)
        AS last_observed_order
FROM vw_seller_analytics;

-- ============================================================
-- 4. Typed order-item analytical view
-- ============================================================

CREATE OR REPLACE VIEW vw_order_items AS

SELECT
    NULLIF(TRIM(order_id), '')
        AS order_id,

    CAST(
        NULLIF(order_item_id, '')
        AS UNSIGNED
    ) AS order_item_id,

    NULLIF(TRIM(product_id), '')
        AS product_id,

    NULLIF(TRIM(seller_id), '')
        AS seller_id,

    CAST(
        NULLIF(shipping_limit_date, '')
        AS DATETIME
    ) AS shipping_limit_date,

    CAST(
        NULLIF(price, '')
        AS DECIMAL(18, 2)
    ) AS price,

    CAST(
        NULLIF(freight_value, '')
        AS DECIMAL(18, 2)
    ) AS freight_value

FROM order_items_clean;


-- ============================================================
-- 5. Typed product analytical view
-- ============================================================

CREATE OR REPLACE VIEW vw_products AS

SELECT
    NULLIF(TRIM(product_id), '')
        AS product_id,

    NULLIF(TRIM(product_category_name), '')
        AS product_category_name,

    CAST(
        NULLIF(product_name_length, '')
        AS UNSIGNED
    ) AS product_name_length,

    CAST(
        NULLIF(product_description_length, '')
        AS UNSIGNED
    ) AS product_description_length,

    CAST(
        NULLIF(product_photos_qty, '')
        AS UNSIGNED
    ) AS product_photos_qty,

    CAST(
        NULLIF(product_weight_g, '')
        AS DECIMAL(12, 2)
    ) AS product_weight_g,

    CAST(
        NULLIF(product_length_cm, '')
        AS DECIMAL(12, 2)
    ) AS product_length_cm,

    CAST(
        NULLIF(product_height_cm, '')
        AS DECIMAL(12, 2)
    ) AS product_height_cm,

    CAST(
        NULLIF(product_width_cm, '')
        AS DECIMAL(12, 2)
    ) AS product_width_cm,

    CASE LOWER(
        NULLIF(
            has_complete_product_attributes,
            ''
        )
    )
        WHEN 'true' THEN 1
        WHEN 'false' THEN 0
        ELSE NULL
    END AS has_complete_product_attributes

FROM products_clean;


-- ============================================================
-- 6. Category-translation view
-- ============================================================

CREATE OR REPLACE VIEW vw_category_translation AS

SELECT
    NULLIF(TRIM(product_category_name), '')
        AS product_category_name,

    NULLIF(
        TRIM(product_category_name_english),
        ''
    ) AS product_category_name_english

FROM category_translation_clean;


-- ============================================================
-- 7. Validate the remaining typed views
-- ============================================================

SELECT
    'vw_order_items' AS view_name,
    COUNT(*) AS view_rows,
    COUNT(
        DISTINCT CONCAT(
            order_id,
            '-',
            order_item_id
        )
    ) AS unique_key_values,
    112650 AS expected_rows,
    CASE
        WHEN COUNT(*) = 112650
         AND COUNT(
             DISTINCT CONCAT(
                 order_id,
                 '-',
                 order_item_id
             )
         ) = 112650
        THEN 'Passed'
        ELSE 'Failed'
    END AS status
FROM vw_order_items

UNION ALL

SELECT
    'vw_products',
    COUNT(*),
    COUNT(DISTINCT product_id),
    32951,
    CASE
        WHEN COUNT(*) = 32951
         AND COUNT(DISTINCT product_id) = 32951
        THEN 'Passed'
        ELSE 'Failed'
    END
FROM vw_products

UNION ALL

SELECT
    'vw_category_translation',
    COUNT(*),
    COUNT(
        DISTINCT product_category_name
    ),
    74,
    CASE
        WHEN COUNT(*) = 74
         AND COUNT(
             DISTINCT product_category_name
         ) = 74
        THEN 'Passed'
        ELSE 'Failed'
    END
FROM vw_category_translation;


-- Confirm item-value reconciliation.

SELECT
    COUNT(*) AS item_records,
    SUM(price) AS product_value,
    SUM(freight_value) AS freight_value,
    SUM(price + freight_value)
        AS total_item_value
FROM vw_order_items;








































