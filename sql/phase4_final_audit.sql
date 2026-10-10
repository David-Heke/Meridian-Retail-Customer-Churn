-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 1
-- VERIFY DATABASE TABLE STRUCTURE
-- ============================================================================
-- Purpose:
-- Confirm that the database contains:
--
--   1. The five RAW staging tables provided by the project:
--        stg_customers
--        stg_products
--        stg_orders
--        stg_order_items
--        stg_support_tickets
--
--   2. The five CLEAN target tables created during Phase 4:
--        customers
--        products
--        orders
--        order_items
--        support_tickets
--
-- This confirms that the raw staging layer has been preserved while the
-- cleaned analytical layer has also been created.
-- ============================================================================

SELECT
    name AS table_name
FROM sqlite_master
WHERE type = 'table'
ORDER BY
    CASE
        WHEN name LIKE 'stg_%' THEN 1
        ELSE 2
    END,
    name;
    
-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 2
-- VERIFY CLEAN TABLE ROW COUNTS
-- ============================================================================
-- Purpose:
-- Confirm that each clean table contains the expected number of records
-- after the Phase 4 cleaning, deduplication and referential-integrity steps.
--
-- Expected clean counts:
--   customers       = 6,090
--   products        = 220
--   orders          = 27,821
--   order_items     = 72,213
--   support_tickets = 5,194
--
-- These counts provide a final check that our cleaning operations produced
-- the intended database population.
-- ============================================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'support_tickets', COUNT(*)
FROM support_tickets;

-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 3
-- VERIFY PRIMARY KEYS AND DUPLICATE RECORDS
-- ============================================================================
-- Purpose:
-- Confirm that the primary-key columns in all five clean tables contain:
--
--   1. No missing values
--   2. No duplicate values
--
-- This is important because duplicate identifiers were found in the raw
-- staging data for orders and order_items and were removed during cleaning.
-- ============================================================================

SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS non_null_keys,
    COUNT(DISTINCT customer_id) AS unique_keys,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_key_rows
FROM customers

UNION ALL

SELECT
    'products',
    COUNT(*),
    COUNT(product_id),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id)
FROM products

UNION ALL

SELECT
    'orders',
    COUNT(*),
    COUNT(order_id),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id)
FROM orders

UNION ALL

SELECT
    'order_items',
    COUNT(*),
    COUNT(order_item_id),
    COUNT(DISTINCT order_item_id),
    COUNT(*) - COUNT(DISTINCT order_item_id)
FROM order_items

UNION ALL

SELECT
    'support_tickets',
    COUNT(*),
    COUNT(ticket_id),
    COUNT(DISTINCT ticket_id),
    COUNT(*) - COUNT(DISTINCT ticket_id)
FROM support_tickets;

-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 4
-- VERIFY FOREIGN-KEY / REFERENTIAL INTEGRITY
-- ============================================================================
-- Purpose:
-- Confirm that every foreign-key value in the clean database has a matching
-- primary-key value in its parent table.
--
-- Expected result:
-- All orphan counts should be 0.
--
-- This confirms that the clean database does not contain broken
-- customer-order, order-item-order, order-item-product, or
-- support-ticket-customer relationships.
-- ============================================================================

-- Check 1: Every order must belong to an existing customer.
SELECT
    'orders → customers' AS relationship,
    COUNT(*) AS orphan_count
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

-- Check 2: Every order item must belong to an existing order.
SELECT
    'order_items → orders',
    COUNT(*)
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

-- Check 3: Every order item must reference an existing product.
SELECT
    'order_items → products',
    COUNT(*)
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

-- Check 4: Every support ticket must belong to an existing customer.
SELECT
    'support_tickets → customers',
    COUNT(*)
FROM support_tickets st
LEFT JOIN customers c
    ON st.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 5
-- VERIFY BUSINESS AND DATA-QUALITY RULES
-- ============================================================================
-- Purpose:
-- Confirm that the clean tables contain no values that violate the main
-- business/data-quality rules identified during our Phase 4 investigation.
--
-- A result of 0 for each check means that no violating records remain.
-- ============================================================================


-- 1. Orders should not contain negative shipping costs.
SELECT
    'Negative shipping costs' AS validation_check,
    COUNT(*) AS invalid_count
FROM orders
WHERE shipping_cost < 0

UNION ALL

-- 2. Discount percentage should be within the observed valid range of 0–25%.
SELECT
    'Invalid discount percentage',
    COUNT(*)
FROM orders
WHERE discount_pct < 0
   OR discount_pct > 25

UNION ALL

-- 3. Order-item quantities must be positive.
SELECT
    'Invalid order-item quantity',
    COUNT(*)
FROM order_items
WHERE quantity <= 0

UNION ALL

-- 4. Purchase prices should not be negative.
SELECT
    'Negative purchase prices',
    COUNT(*)
FROM order_items
WHERE unit_price_at_purchase < 0

UNION ALL

-- 5. Product unit costs should not be negative.
SELECT
    'Negative product unit costs',
    COUNT(*)
FROM products
WHERE unit_cost < 0

UNION ALL

-- 6. Product unit prices should not be negative.
SELECT
    'Negative product unit prices',
    COUNT(*)
FROM products
WHERE unit_price < 0

UNION ALL

-- 7. Support-ticket resolution time cannot be negative.
SELECT
    'Negative resolution times',
    COUNT(*)
FROM support_tickets
WHERE resolution_time_hours < 0

UNION ALL

-- 8. Satisfaction scores must be NULL or within the valid 1–5 range.
-- NULL is intentionally allowed because 592 satisfaction scores were
-- missing in the raw data and we did not invent replacement values.
SELECT
    'Invalid satisfaction scores',
    COUNT(*)
FROM support_tickets
WHERE satisfaction_score IS NOT NULL
  AND (
      satisfaction_score < 1
      OR satisfaction_score > 5
  );
  
-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 6
-- VERIFY STANDARDIZED CATEGORICAL VALUES
-- ============================================================================
-- Purpose:
-- Confirm that categorical fields in the clean tables contain only the
-- standardized values expected by the clean database design.
--
-- We previously identified inconsistent capitalization in the raw data,
-- particularly for membership tiers and order statuses.
--
-- This audit confirms that those inconsistencies were successfully handled.
-- ============================================================================


-- 1. Check customer membership tiers.
SELECT
    'Customer membership tiers' AS validation_check,
    membership_tier AS value_found,
    COUNT(*) AS row_count
FROM customers
GROUP BY membership_tier

UNION ALL

-- 2. Check order statuses.
SELECT
    'Order statuses',
    order_status,
    COUNT(*)
FROM orders
GROUP BY order_status

UNION ALL

-- 3. Check product active-status values.
SELECT
    'Product active status',
    is_active,
    COUNT(*)
FROM products
GROUP BY is_active

ORDER BY validation_check, value_found;

-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 7
-- VERIFY NUMERIC DATA TYPES AND RANGES
-- ============================================================================
-- Purpose:
-- Confirm that important numeric fields in the clean tables contain numeric
-- values and that their ranges are sensible.
--
-- This is especially important for products.unit_price, which was originally
-- stored as TEXT and contained currency symbols such as '$100.91'.
--
-- We converted that field to a numeric value during the clean-table load.
-- ============================================================================

SELECT
    'products.unit_cost' AS field_name,
    typeof(unit_cost) AS data_type,
    MIN(unit_cost) AS minimum_value,
    MAX(unit_cost) AS maximum_value
FROM products

UNION ALL

SELECT
    'products.unit_price',
    typeof(unit_price),
    MIN(unit_price),
    MAX(unit_price)
FROM products

UNION ALL

SELECT
    'orders.shipping_cost',
    typeof(shipping_cost),
    MIN(shipping_cost),
    MAX(shipping_cost)
FROM orders

UNION ALL

SELECT
    'orders.discount_pct',
    typeof(discount_pct),
    MIN(discount_pct),
    MAX(discount_pct)
FROM orders

UNION ALL

SELECT
    'orders.total_amount',
    typeof(total_amount),
    MIN(total_amount),
    MAX(total_amount)
FROM orders

UNION ALL

SELECT
    'order_items.quantity',
    typeof(quantity),
    MIN(quantity),
    MAX(quantity)
FROM order_items

UNION ALL

SELECT
    'order_items.unit_price_at_purchase',
    typeof(unit_price_at_purchase),
    MIN(unit_price_at_purchase),
    MAX(unit_price_at_purchase)
FROM order_items

UNION ALL

SELECT
    'support_tickets.resolution_time_hours',
    typeof(resolution_time_hours),
    MIN(resolution_time_hours),
    MAX(resolution_time_hours)
FROM support_tickets

UNION ALL

SELECT
    'support_tickets.satisfaction_score',
    typeof(satisfaction_score),
    MIN(satisfaction_score),
    MAX(satisfaction_score)
FROM support_tickets;

-- ============================================================================
-- PHASE 4 FINAL DATABASE AUDIT — STEP 8
-- VERIFY INTENTIONAL MISSING VALUES
-- ============================================================================
-- Purpose:
-- Confirm the presence of important NULL values that were intentionally
-- retained during cleaning because replacing them with invented values would
-- introduce unsupported assumptions.
--
-- NULL values are not automatically errors. Their treatment depends on the
-- meaning of the field and whether a reliable replacement value exists.
-- ============================================================================

SELECT
    'customers.referral_source' AS field_name,
    COUNT(*) AS missing_count
FROM customers
WHERE referral_source IS NULL

UNION ALL

SELECT
    'customers.marketing_opt_in',
    COUNT(*)
FROM customers
WHERE marketing_opt_in IS NULL

UNION ALL

SELECT
    'customers.email',
    COUNT(*)
FROM customers
WHERE email IS NULL

UNION ALL

SELECT
    'customers.phone',
    COUNT(*)
FROM customers
WHERE phone IS NULL

UNION ALL

SELECT
    'customers.date_of_birth',
    COUNT(*)
FROM customers
WHERE date_of_birth IS NULL

UNION ALL

SELECT
    'customers.city',
    COUNT(*)
FROM customers
WHERE city IS NULL

UNION ALL

SELECT
    'products.sub_category',
    COUNT(*)
FROM products
WHERE sub_category IS NULL

UNION ALL

SELECT
    'support_tickets.satisfaction_score',
    COUNT(*)
FROM support_tickets
WHERE satisfaction_score IS NULL;

-- ============================================================
-- PHASE 4 FINAL AUDIT — STEP 9
-- Verify that the required performance indexes exist.
-- ============================================================

SELECT
    name AS index_name,
    tbl_name AS table_name
FROM sqlite_master
WHERE type = 'index'
  AND name NOT LIKE 'sqlite_autoindex%'
ORDER BY tbl_name, name;

-- ============================================================
-- PHASE 4 FINAL AUDIT — STEP 10
-- Check the entire SQLite database for structural corruption.
--
-- Expected result:
-- integrity_check
-- ok
-- ============================================================

PRAGMA integrity_check;