SELECT name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;

--Check the number of records
SELECT 'stg_customers' AS table_name, COUNT(*) AS row_count
FROM stg_customers

UNION ALL

SELECT 'stg_products', COUNT(*)
FROM stg_products

UNION ALL

SELECT 'stg_orders', COUNT(*)
FROM stg_orders

UNION ALL

SELECT 'stg_order_items', COUNT(*)
FROM stg_order_items

UNION ALL

SELECT 'stg_support_tickets', COUNT(*)
FROM stg_support_tickets;

--Inspect the Columns
PRAGMA table_info(stg_customers);

PRAGMA table_info(stg_products);

PRAGMA table_info(stg_orders);

PRAGMA table_info(stg_order_items);

PRAGMA table_info(stg_support_tickets);

--Check Duplicate customer IDs
-- PURPOSE:
-- Every customer_id should uniquely identify one customer.
-- Duplicate IDs would violate the PRIMARY KEY constraint
-- in the clean customers table.

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--Check missing required customer fields
-- PURPOSE:
-- The clean customers table requires these four fields.
-- We therefore check the staging data for NULL or blank values
-- before attempting to populate the clean table.

SELECT
    SUM(CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' THEN 1 ELSE 0 END)
        AS missing_customer_id,

    SUM(CASE WHEN first_name IS NULL OR TRIM(first_name) = '' THEN 1 ELSE 0 END)
        AS missing_first_name,

    SUM(CASE WHEN last_name IS NULL OR TRIM(last_name) = '' THEN 1 ELSE 0 END)
        AS missing_last_name,

    SUM(CASE WHEN signup_date IS NULL OR TRIM(signup_date) = '' THEN 1 ELSE 0 END)
        AS missing_signup_date
FROM stg_customers;

--Check invalid gender values
-- PURPOSE:
-- The clean schema restricts gender to F, M, or Other.
-- We first inspect all distinct values so that inconsistent
-- spellings/capitalization can be identified before cleaning.

SELECT
    gender,
    COUNT(*) AS record_count
FROM stg_customers
GROUP BY gender
ORDER BY record_count DESC;

--Check membership-tier values
-- PURPOSE:
-- The clean schema restricts membership_tier to four valid values.
-- This query identifies unexpected or inconsistent categories.

SELECT
    membership_tier,
    COUNT(*) AS record_count
FROM stg_customers
GROUP BY membership_tier
ORDER BY record_count DESC;

--Check suspicious signup dates
-- PURPOSE:
-- signup_date is required and should contain a valid date.
-- We first identify missing and unusual date values.
-- We are not correcting dates at this stage.

SELECT
    signup_date,
    COUNT(*) AS record_count
FROM stg_customers
GROUP BY signup_date
ORDER BY signup_date
LIMIT 30;

--Duplicate product IDs
-- PURPOSE:
-- product_id is the PRIMARY KEY of the clean products table.
-- Therefore, each product_id must occur only once.

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM stg_products
GROUP BY product_id
HAVING COUNT(*) > 1;

--Missing required product fields
-- PURPOSE:
-- Check fields that are declared NOT NULL in schema.sql.

SELECT
    SUM(CASE WHEN product_id IS NULL OR TRIM(product_id) = '' THEN 1 ELSE 0 END)
        AS missing_product_id,

    SUM(CASE WHEN product_name IS NULL OR TRIM(product_name) = '' THEN 1 ELSE 0 END)
        AS missing_product_name,

    SUM(CASE WHEN category IS NULL OR TRIM(category) = '' THEN 1 ELSE 0 END)
        AS missing_category
FROM stg_products;

--Identify non-numeric unit prices
-- PURPOSE:
-- unit_price should eventually become NUMERIC(10,2).
-- This query looks for values that cannot be interpreted
-- as numeric values.

SELECT
    product_id,
    product_name,
    unit_price
FROM stg_products
WHERE unit_price IS NOT NULL
  AND TRIM(unit_price) <> ''
  AND CAST(unit_price AS REAL) = 0
  AND TRIM(unit_price) NOT IN ('0', '0.0', '0.00');
  
--Check is_active
-- PURPOSE:
-- The clean products table restricts is_active to Yes or No.
-- We inspect all existing values before standardization.

SELECT
    is_active,
    COUNT(*) AS record_count
FROM stg_products
GROUP BY is_active
ORDER BY record_count DESC;

--Duplicate order IDs
-- PURPOSE:
-- order_id is the PRIMARY KEY of the clean orders table.
-- Duplicate order IDs must therefore be investigated before loading.

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

--Inspect the actual duplicate orders
-- PURPOSE:
-- Inspect the complete records behind duplicate order IDs.
-- This helps us determine whether they are exact duplicate rows
-- or genuinely different records sharing the same ID.

SELECT *
FROM stg_orders
WHERE order_id IN (
    SELECT order_id
    FROM stg_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;

--Check required order fields
-- PURPOSE:
-- Check fields that are mandatory in the clean orders table.

SELECT
    SUM(CASE WHEN order_id IS NULL OR TRIM(order_id) = '' THEN 1 ELSE 0 END)
        AS missing_order_id,

    SUM(CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' THEN 1 ELSE 0 END)
        AS missing_customer_id
FROM stg_orders;

--Check order status values
-- PURPOSE:
-- Inspect the different order-status categories.
-- Although schema.sql does not impose a CHECK constraint on order_status,
-- inconsistent values could affect churn and revenue analysis.

SELECT
    order_status,
    COUNT(*) AS record_count
FROM stg_orders
GROUP BY order_status
ORDER BY record_count DESC;

--Check order channels
-- PURPOSE:
-- Inspect channel categories for inconsistencies such as
-- different capitalization or spelling.

SELECT
    channel,
    COUNT(*) AS record_count
FROM stg_orders
GROUP BY channel
ORDER BY record_count DESC;

--Check negative financial values
-- PURPOSE:
-- Identify impossible negative shipping costs or order amounts.
-- These values could distort revenue and churn calculations.

SELECT
    SUM(CASE WHEN shipping_cost < 0 THEN 1 ELSE 0 END)
        AS negative_shipping_costs,

    SUM(CASE WHEN total_amount < 0 THEN 1 ELSE 0 END)
        AS negative_total_amounts,

    SUM(CASE WHEN discount_pct < 0 THEN 1 ELSE 0 END)
        AS negative_discounts
FROM stg_orders;

-- Check discount percentage
-- PURPOSE:
-- A discount percentage should normally fall between 0 and 100.
-- This identifies values outside that logical range.

SELECT
    order_id,
    discount_pct
FROM stg_orders
WHERE discount_pct < 0
   OR discount_pct > 100;
   
--Check orphan customer IDs
-- PURPOSE:
-- Every order should belong to an existing customer.
-- This query identifies orders whose customer_id does not
-- exist in the customer staging table.

SELECT
    o.order_id,
    o.customer_id
FROM stg_orders AS o
LEFT JOIN stg_customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--Duplicate order-item IDs
-- PURPOSE:
-- order_item_id is the PRIMARY KEY of the clean order_items table.
-- Duplicate values must therefore be investigated.

SELECT
    order_item_id,
    COUNT(*) AS duplicate_count
FROM stg_order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

--Inspect duplicate order-item records
-- PURPOSE:
-- Inspect the actual duplicate records to determine
-- whether they are exact duplicates or conflicting records.

SELECT *
FROM stg_order_items
WHERE order_item_id IN (
    SELECT order_item_id
    FROM stg_order_items
    GROUP BY order_item_id
    HAVING COUNT(*) > 1
)
ORDER BY order_item_id;

--Check required fields
-- PURPOSE:
-- order_id and product_id are mandatory in the clean schema.

SELECT
    SUM(CASE WHEN order_item_id IS NULL OR TRIM(order_item_id) = '' THEN 1 ELSE 0 END)
        AS missing_order_item_id,

    SUM(CASE WHEN order_id IS NULL OR TRIM(order_id) = '' THEN 1 ELSE 0 END)
        AS missing_order_id,

    SUM(CASE WHEN product_id IS NULL OR TRIM(product_id) = '' THEN 1 ELSE 0 END)
        AS missing_product_id
FROM stg_order_items;

--Check quantity
-- PURPOSE:
-- Quantity should not be negative or zero for a normal sale.
-- We identify suspicious quantities for further investigation.

SELECT
    order_item_id,
    quantity
FROM stg_order_items
WHERE quantity <= 0;

--Check unit price at purchase
-- PURPOSE:
-- Identify negative purchase prices, which would be
-- inconsistent with a normal product sale.

SELECT
    order_item_id,
    unit_price_at_purchase
FROM stg_order_items
WHERE unit_price_at_purchase < 0;

--Check orphan orders
-- PURPOSE:
-- Every order_item should reference an existing order.

SELECT
    oi.order_item_id,
    oi.order_id
FROM stg_order_items AS oi
LEFT JOIN stg_orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--Check orphan products
-- PURPOSE:
-- Every order_item should reference an existing product.

SELECT
    oi.order_item_id,
    oi.product_id
FROM stg_order_items AS oi
LEFT JOIN stg_products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

--Audit stg_support_tickets: Duplicate ticket IDs
-- PURPOSE:
-- ticket_id is the PRIMARY KEY of the clean support_tickets table.

SELECT
    ticket_id,
    COUNT(*) AS duplicate_count
FROM stg_support_tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;

--Check required fields
-- PURPOSE:
-- Check mandatory support-ticket fields before loading
-- into the constrained table.

SELECT
    SUM(CASE WHEN ticket_id IS NULL OR TRIM(ticket_id) = '' THEN 1 ELSE 0 END)
        AS missing_ticket_id,

    SUM(CASE WHEN customer_id IS NULL OR TRIM(customer_id) = '' THEN 1 ELSE 0 END)
        AS missing_customer_id
FROM stg_support_tickets;

--Check satisfaction scores
-- PURPOSE:
-- satisfaction_score has a CHECK constraint requiring
-- values between 1 and 5.

SELECT
    ticket_id,
    satisfaction_score
FROM stg_support_tickets
WHERE satisfaction_score IS NOT NULL
  AND (
      satisfaction_score < 1
      OR satisfaction_score > 5
  );
  
--Check issue categories
-- PURPOSE:
-- Inspect issue categories for missing or inconsistent values.
-- No fixed CHECK constraint is imposed by schema.sql.

SELECT
    issue_category,
    COUNT(*) AS record_count
FROM stg_support_tickets
GROUP BY issue_category
ORDER BY record_count DESC;

--Check negative resolution times
-- PURPOSE:
-- Resolution time cannot logically be negative.
-- We identify such records for investigation.

SELECT
    ticket_id,
    resolution_time_hours
FROM stg_support_tickets
WHERE resolution_time_hours < 0;

--Check orphan customers
-- PURPOSE:
-- Every support ticket should belong to an existing customer.

SELECT
    st.ticket_id,
    st.customer_id
FROM stg_support_tickets AS st
LEFT JOIN stg_customers AS c
    ON st.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--Check whether order items reference duplicate orders
-- PURPOSE:
-- Duplicate order IDs can affect downstream joins and revenue calculations.
-- This query identifies order-item records connected to orders whose
-- order_id appears more than once in the staging orders table.

SELECT
    oi.order_id,
    COUNT(*) AS order_item_count
FROM stg_order_items AS oi
WHERE oi.order_id IN (
    SELECT order_id
    FROM stg_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
GROUP BY oi.order_id
ORDER BY order_item_count DESC;

-- ============================================================================
-- MERIDIAN RETAIL GROUP
-- PHASE 4: CONSOLIDATED DIAGNOSTIC AUDIT
-- PURPOSE:
-- Summarize key data-quality issues across all five staging tables.
-- IMPORTANT:
-- This query only READS the data. It does not modify anything.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. CUSTOMER TABLE
-- ---------------------------------------------------------------------------

SELECT
    'CUSTOMERS' AS table_name,

    SUM(CASE
        WHEN customer_id IS NULL OR TRIM(customer_id) = ''
        THEN 1 ELSE 0
    END) AS missing_customer_id,

    SUM(CASE
        WHEN first_name IS NULL OR TRIM(first_name) = ''
        THEN 1 ELSE 0
    END) AS missing_first_name,

    SUM(CASE
        WHEN last_name IS NULL OR TRIM(last_name) = ''
        THEN 1 ELSE 0
    END) AS missing_last_name,

    SUM(CASE
        WHEN signup_date IS NULL OR TRIM(signup_date) = ''
        THEN 1 ELSE 0
    END) AS missing_signup_date

FROM stg_customers;


-- ---------------------------------------------------------------------------
-- 2. PRODUCT TABLE
-- ---------------------------------------------------------------------------

SELECT
    'PRODUCTS' AS table_name,

    SUM(CASE
        WHEN product_id IS NULL OR TRIM(product_id) = ''
        THEN 1 ELSE 0
    END) AS missing_product_id,

    SUM(CASE
        WHEN product_name IS NULL OR TRIM(product_name) = ''
        THEN 1 ELSE 0
    END) AS missing_product_name,

    SUM(CASE
        WHEN category IS NULL OR TRIM(category) = ''
        THEN 1 ELSE 0
    END) AS missing_category,

    SUM(CASE
        WHEN unit_cost < 0
        THEN 1 ELSE 0
    END) AS negative_unit_cost

FROM stg_products;


-- ---------------------------------------------------------------------------
-- 3. ORDER TABLE
-- ---------------------------------------------------------------------------

SELECT
    'ORDERS' AS table_name,

    SUM(CASE
        WHEN order_id IS NULL OR TRIM(order_id) = ''
        THEN 1 ELSE 0
    END) AS missing_order_id,

    SUM(CASE
        WHEN customer_id IS NULL OR TRIM(customer_id) = ''
        THEN 1 ELSE 0
    END) AS missing_customer_id,

    SUM(CASE
        WHEN shipping_cost < 0
        THEN 1 ELSE 0
    END) AS negative_shipping_cost,

    SUM(CASE
        WHEN total_amount < 0
        THEN 1 ELSE 0
    END) AS negative_total_amount,

    SUM(CASE
        WHEN discount_pct < 0 OR discount_pct > 100
        THEN 1 ELSE 0
    END) AS invalid_discount

FROM stg_orders;


-- ---------------------------------------------------------------------------
-- 4. ORDER ITEMS TABLE
-- ---------------------------------------------------------------------------

SELECT
    'ORDER_ITEMS' AS table_name,

    SUM(CASE
        WHEN order_item_id IS NULL OR TRIM(order_item_id) = ''
        THEN 1 ELSE 0
    END) AS missing_order_item_id,

    SUM(CASE
        WHEN order_id IS NULL OR TRIM(order_id) = ''
        THEN 1 ELSE 0
    END) AS missing_order_id,

    SUM(CASE
        WHEN product_id IS NULL OR TRIM(product_id) = ''
        THEN 1 ELSE 0
    END) AS missing_product_id,

    SUM(CASE
        WHEN quantity <= 0
        THEN 1 ELSE 0
    END) AS invalid_quantity,

    SUM(CASE
        WHEN unit_price_at_purchase < 0
        THEN 1 ELSE 0
    END) AS negative_purchase_price

FROM stg_order_items;


-- ---------------------------------------------------------------------------
-- 5. SUPPORT TICKETS TABLE
-- ---------------------------------------------------------------------------

SELECT
    'SUPPORT_TICKETS' AS table_name,

    SUM(CASE
        WHEN ticket_id IS NULL OR TRIM(ticket_id) = ''
        THEN 1 ELSE 0
    END) AS missing_ticket_id,

    SUM(CASE
        WHEN customer_id IS NULL OR TRIM(customer_id) = ''
        THEN 1 ELSE 0
    END) AS missing_customer_id,

    SUM(CASE
        WHEN satisfaction_score IS NOT NULL
             AND (
                 satisfaction_score < 1
                 OR satisfaction_score > 5
             )
        THEN 1 ELSE 0
    END) AS invalid_satisfaction,

    SUM(CASE
        WHEN resolution_time_hours < 0
        THEN 1 ELSE 0
    END) AS negative_resolution_time

FROM stg_support_tickets;

-- ============================================================================
-- STEP 7.7 — Inspect invalid discount percentages
-- PURPOSE:
-- The clean orders table defines discount_pct as NUMERIC(5,2).
-- We previously identified 6,131 potentially invalid records.
-- Before deciding how to clean them, we need to see the actual values.
-- ============================================================================

SELECT
    discount_pct,
    COUNT(*) AS record_count
FROM stg_orders
WHERE discount_pct IS NULL
   OR discount_pct < 0
   OR discount_pct > 100
GROUP BY discount_pct
ORDER BY record_count DESC;

-- ============================================================================
-- STEP 7.8 — Inspect negative shipping costs
-- PURPOSE:
-- Shipping cost should not normally be negative.
-- We identified 12 records with negative values.
-- We inspect the affected rows before deciding whether to correct,
-- quarantine, or exclude them.
-- ============================================================================

SELECT
    order_id,
    customer_id,
    order_date,
    shipping_cost,
    total_amount
FROM stg_orders
WHERE shipping_cost < 0
ORDER BY shipping_cost;

-- ============================================================================
-- STEP 7.9 — Inspect invalid order-item quantities
-- PURPOSE:
-- Quantity should represent the number of units purchased.
-- We identified 18 records with invalid quantities.
-- We inspect the actual values before deciding how to treat them.
-- ============================================================================

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase
FROM stg_order_items
WHERE quantity IS NULL
   OR quantity <= 0
ORDER BY quantity;

-- ============================================================================
-- STEP 7.10 — Inspect negative support-ticket resolution times
-- PURPOSE:
-- Resolution time cannot logically be negative.
-- We identified 6 records with negative values.
-- We inspect them before deciding how they should be handled.
-- ============================================================================

SELECT
    ticket_id,
    customer_id,
    ticket_date,
    issue_category,
    resolution_time_hours,
    satisfaction_score
FROM stg_support_tickets
WHERE resolution_time_hours < 0
ORDER BY resolution_time_hours;

-- ============================================================================
-- STEP 7.11 — Inspect invalid satisfaction scores
-- PURPOSE:
-- The clean schema allows satisfaction scores from 1 to 5 only.
-- We previously identified 1,763 potentially invalid records.
-- This query reveals the actual values causing the problem.
-- ============================================================================

SELECT
    satisfaction_score,
    COUNT(*) AS record_count
FROM stg_support_tickets
WHERE satisfaction_score IS NULL
   OR satisfaction_score < 1
   OR satisfaction_score > 5
GROUP BY satisfaction_score
ORDER BY record_count DESC;

-- ============================================================================
-- STEP 7.7A — Full distribution of discount percentages
-- PURPOSE:
-- We want to see every distinct discount_pct value in the staging orders
-- table and determine how frequently each value occurs.
-- This prevents us from incorrectly classifying legitimate values as errors.
-- ============================================================================

SELECT
    discount_pct,
    COUNT(*) AS record_count
FROM stg_orders
GROUP BY discount_pct
ORDER BY discount_pct;

-- ============================================================================
-- STEP 7.7B — Check for discount percentages outside the valid 0–100 range
-- PURPOSE:
-- A percentage below 0 or above 100 would be logically invalid.
-- NULL values are also reported separately as missing data.
-- ============================================================================

SELECT
    COUNT(*) AS invalid_discount_count
FROM stg_orders
WHERE discount_pct < 0
   OR discount_pct > 100;
   
-- ============================================================================
-- STEP 7.7C — Check for missing discount percentages
-- PURPOSE:
-- NULL represents a missing discount value.
-- We check it separately from mathematically invalid percentages.
-- ============================================================================

SELECT
    COUNT(*) AS missing_discount_count
FROM stg_orders
WHERE discount_pct IS NULL;

-- ============================================================================
-- STEP 7.7D — Overall discount summary
-- PURPOSE:
-- This provides the total number of orders, number of discounted orders,
-- and number of orders without a discount.
-- ============================================================================

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN discount_pct > 0 THEN 1
            ELSE 0
        END
    ) AS orders_with_discount,

    SUM(
        CASE
            WHEN discount_pct = 0 THEN 1
            ELSE 0
        END
    ) AS orders_without_discount,

    SUM(
        CASE
            WHEN discount_pct IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_discount
FROM stg_orders;

-- ============================================================================
-- STEP 7.7E — Inspect the SQLite storage type of discount_pct
-- PURPOSE:
-- The staging table is intentionally permissive.
-- SQLite may therefore be storing discount_pct as TEXT rather than NUMERIC.
-- This check helps explain why a numeric comparison may produce misleading
-- results.
-- ============================================================================

SELECT
    typeof(discount_pct) AS sqlite_data_type,
    COUNT(*) AS record_count
FROM stg_orders
GROUP BY typeof(discount_pct)
ORDER BY record_count DESC;

-- ============================================================================
-- STEP 7.7F — Test discount percentages using explicit numeric conversion
-- PURPOSE:
-- CAST() forces SQLite to interpret discount_pct as a numeric value.
-- This gives us a reliable test for values outside the valid 0–100 range.
-- ============================================================================

SELECT
    COUNT(*) AS invalid_discount_count
FROM stg_orders
WHERE CAST(discount_pct AS REAL) < 0
   OR CAST(discount_pct AS REAL) > 100;

-- ============================================================================
-- STEP 7.7G — Identify any genuinely invalid discount values
-- PURPOSE:
-- If invalid values exist, display the actual values and their frequencies.
-- ============================================================================

SELECT
    discount_pct,
    COUNT(*) AS record_count
FROM stg_orders
WHERE CAST(discount_pct AS REAL) < 0
   OR CAST(discount_pct AS REAL) > 100
GROUP BY discount_pct
ORDER BY record_count DESC;

-- STEP 7.8
-- Purpose:
-- Identify all orders whose order_id appears more than once.
-- We are investigating duplicates before deciding whether they should
-- be removed, retained, or otherwise handled during the cleaning phase.

SELECT
    order_id,
    COUNT(*) AS record_count
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, order_id;

-- STEP 7.9
-- Purpose:
-- Display every duplicated order record so we can determine whether
-- the duplicate order IDs represent exact duplicate rows or whether
-- the two records contain different information.
--
-- We do NOT delete anything at this stage.

SELECT
    order_id,
    customer_id,
    order_date,
    channel,
    order_status,
    payment_method,
    shipping_cost,
    discount_pct,
    total_amount
FROM stg_orders
WHERE order_id IN (
    SELECT order_id
    FROM stg_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;

-- STEP 7.10
-- Purpose:
-- Identify order-item IDs that occur more than once.
-- We will inspect these records before deciding whether they are
-- exact duplicates or contain conflicting information.

SELECT
    order_item_id,
    COUNT(*) AS record_count
FROM stg_order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, order_item_id;

-- STEP 7.11
-- Purpose:
-- Inspect every duplicated order-item record.
-- We need to confirm whether each duplicate pair is identical
-- before deciding how it should be handled.

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase
FROM stg_order_items
WHERE order_item_id IN (
    SELECT order_item_id
    FROM stg_order_items
    GROUP BY order_item_id
    HAVING COUNT(*) > 1
)
ORDER BY order_item_id;

-- STEP 7.12
-- Purpose:
-- Identify order-item records with zero or negative quantities.
-- Valid product quantities should represent an actual number of units
-- purchased, so zero or negative values require investigation.

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase
FROM stg_order_items
WHERE CAST(quantity AS INTEGER) <= 0
ORDER BY quantity, order_item_id;

-- STEP 7.13
-- Purpose:
-- Separate missing satisfaction scores from genuinely invalid scores.
-- Valid satisfaction scores should fall between 1 and 5.
-- NULL values are missing data, not invalid numeric values.

SELECT
    satisfaction_score,
    COUNT(*) AS record_count
FROM stg_support_tickets
WHERE satisfaction_score IS NULL
   OR CAST(satisfaction_score AS REAL) < 1
   OR CAST(satisfaction_score AS REAL) > 5
GROUP BY satisfaction_score
ORDER BY satisfaction_score;

-- STEP 7.14
-- Purpose:
-- Identify support tickets with negative resolution times.
-- Resolution time represents elapsed time required to resolve a ticket,
-- so negative values are logically invalid.

SELECT
    ticket_id,
    customer_id,
    ticket_date,
    issue_category,
    channel,
    resolution_time_hours,
    satisfaction_score
FROM stg_support_tickets
WHERE CAST(resolution_time_hours AS REAL) < 0
ORDER BY resolution_time_hours, ticket_id;

--Step 7.15 — Foreign-key integrity check
-- STEP 7.15A
-- Purpose:
-- Check whether every order belongs to a customer that exists
-- in the customers staging table.

SELECT
    COUNT(*) AS orphan_order_count
FROM stg_orders o
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- STEP 7.15B
-- Purpose:
-- Check whether every order item refers to an existing order.

SELECT
    COUNT(*) AS orphan_order_item_order_count
FROM stg_order_items oi
LEFT JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- STEP 7.15C
-- Purpose:
-- Check whether every order item refers to an existing product.

SELECT
    COUNT(*) AS orphan_order_item_product_count
FROM stg_order_items oi
LEFT JOIN stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- STEP 7.15D
-- Purpose:
-- Check whether every support ticket belongs to an existing customer.

SELECT
    COUNT(*) AS orphan_ticket_count
FROM stg_support_tickets st
LEFT JOIN stg_customers c
    ON st.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--Step 7.16 — Identify the 20 orphan orders
-- STEP 7.16
-- Purpose:
-- Display the orders whose customer_id does not exist
-- in the customers table.
--
-- These records cannot satisfy the customer foreign-key constraint
-- in the clean orders table until an appropriate treatment is decided.

SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.channel,
    o.order_status,
    o.payment_method,
    o.shipping_cost,
    o.discount_pct,
    o.total_amount
FROM stg_orders o
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
ORDER BY o.order_id;

-- ============================================================================
-- STEP 7.17: CHECK ORDER ITEMS BELONGING TO ORPHAN ORDERS
-- ============================================================================
-- Purpose:
-- Check whether any order_items are linked to the 20 orders whose
-- customer_id does not exist in the customers table.
--
-- Why this matters:
-- If we remove an orphan order, its related order_items may also need
-- to be excluded to preserve referential integrity.
-- ============================================================================

SELECT
    oi.order_id,
    COUNT(*) AS order_item_count
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
GROUP BY oi.order_id
ORDER BY oi.order_id;

-- ============================================================================
-- STEP 7.18: FINAL CHECK OF CHECK-CONSTRAINT CATEGORIES
-- ============================================================================
-- Purpose:
-- Identify the exact categorical values currently present in the raw
-- staging tables before we load the clean constrained tables.
--
-- Why this matters:
-- The clean schema contains CHECK constraints. We must standardize
-- inconsistent representations before inserting the data.
-- ============================================================================

-- 1. Customer gender values
SELECT
    'gender' AS field_name,
    gender AS raw_value,
    COUNT(*) AS record_count
FROM stg_customers
GROUP BY gender

UNION ALL

-- 2. Customer membership tier values
SELECT
    'membership_tier' AS field_name,
    membership_tier AS raw_value,
    COUNT(*) AS record_count
FROM stg_customers
GROUP BY membership_tier

UNION ALL

-- 3. Product active-status values
SELECT
    'is_active' AS field_name,
    is_active AS raw_value,
    COUNT(*) AS record_count
FROM stg_products
GROUP BY is_active

ORDER BY field_name, raw_value;



