-- ============================================================================
-- STEP 7.20A
-- Purpose:
-- Confirm that the newly created clean customers table is currently empty.
-- ============================================================================

SELECT COUNT(*) AS customer_count
FROM customers;

-- ============================================================================
-- STEP 7.20B: LOAD CLEAN CUSTOMERS
-- ============================================================================
-- Purpose:
-- Transfer customer data from the raw staging table into the clean
-- customers table.
--
-- Cleaning performed here:
-- 1. Standardize membership_tier capitalization.
-- 2. Preserve valid NULL values in optional fields.
-- 3. Keep the original customer_id and required customer information.
--
-- We are NOT modifying the staging table. The raw data remains available
-- for auditing and reproducibility.
-- ============================================================================

INSERT INTO customers (
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    gender,
    date_of_birth,
    signup_date,
    state,
    city,
    membership_tier,
    preferred_channel,
    marketing_opt_in,
    referral_source
)
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    gender,
    date_of_birth,
    signup_date,
    state,
    city,

    -- Standardize Bronze/Silver/Gold/Platinum capitalization.
    CASE LOWER(TRIM(membership_tier))
        WHEN 'bronze' THEN 'Bronze'
        WHEN 'silver' THEN 'Silver'
        WHEN 'gold' THEN 'Gold'
        WHEN 'platinum' THEN 'Platinum'
        ELSE NULL
    END AS membership_tier,

    preferred_channel,
    marketing_opt_in,
    referral_source

FROM stg_customers;

-- ============================================================================
-- STEP 7.20C — VERIFY CUSTOMER RECORD COUNT
-- ============================================================================
-- Purpose:
-- Confirm that all 6,090 customer records were successfully loaded
-- from the staging table into the clean customers table.
-- ============================================================================

SELECT COUNT(*) AS clean_customer_count
FROM customers;

-- ============================================================================
-- STEP 7.20D — VERIFY MEMBERSHIP TIER STANDARDIZATION
-- ============================================================================
-- Purpose:
-- Confirm that inconsistent raw values such as 'bronze', 'BRONZE',
-- and 'Bronze' have been standardized into four clean categories.
-- ============================================================================

SELECT
    membership_tier,
    COUNT(*) AS customer_count
FROM customers
GROUP BY membership_tier
ORDER BY membership_tier;

-- ============================================================================
-- STEP 7.20E — CHECK FOR UNEXPECTED MEMBERSHIP TIER VALUES
-- ============================================================================
-- Purpose:
-- Confirm that our standardization did not accidentally create NULL values.
-- A NULL here could indicate an unexpected raw membership-tier value.
-- ============================================================================

SELECT
    COUNT(*) AS null_membership_tier_count
FROM customers
WHERE membership_tier IS NULL;

-- ============================================================================
-- STEP 7.21A — CHECK CLEAN PRODUCTS TABLE
-- ============================================================================
-- Purpose:
-- Confirm that the clean products table is currently empty before loading
-- the cleaned product records.
-- ============================================================================

SELECT COUNT(*) AS product_count
FROM products;

-- ============================================================================
-- STEP 7.21B — LOAD CLEAN PRODUCTS
-- ============================================================================
-- Purpose:
-- Transfer product data from the raw staging table into the clean products
-- table while correcting the identified formatting issue in unit_price.
--
-- Cleaning performed:
-- 1. Remove the '$' currency symbol from unit_price.
-- 2. Convert unit_price from TEXT to a numeric value.
-- 3. Preserve NULL values in optional fields such as sub_category.
-- 4. Keep the original product IDs and product information.
--
-- The staging table is NOT modified. This preserves the raw data for
-- auditing and reproducibility.
-- ============================================================================

INSERT INTO products (
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    unit_cost,
    unit_price,
    launch_date,
    is_active
)
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    unit_cost,

    -- Remove the '$' symbol and convert the text to a numeric value.
    CAST(REPLACE(unit_price, '$', '') AS NUMERIC) AS unit_price,

    launch_date,
    is_active
FROM stg_products;

-- ============================================================================
-- STEP 7.21C — VERIFY PRODUCT RECORD COUNT
-- ============================================================================
-- Purpose:
-- Confirm that all 220 product records were successfully loaded into
-- the clean products table.
-- ============================================================================

SELECT COUNT(*) AS clean_product_count
FROM products;

-- ============================================================================
-- STEP 7.21D — VERIFY UNIT PRICE CONVERSION
-- ============================================================================
-- Purpose:
-- Confirm that unit_price is now stored as a numeric value in the clean
-- products table rather than the original TEXT format from staging.
-- ============================================================================

SELECT
    typeof(unit_price) AS data_type,
    COUNT(*) AS product_count
FROM products
GROUP BY typeof(unit_price);

-- ============================================================================
-- STEP 7.21E — CHECK FOR NEGATIVE PRODUCT PRICES
-- ============================================================================
-- Purpose:
-- Confirm that no product has a negative unit cost or unit price.
-- Negative prices/costs would be logically invalid for this retail dataset.
-- ============================================================================

SELECT
    COUNT(*) AS invalid_price_count
FROM products
WHERE unit_cost < 0
   OR unit_price < 0;
   
-- ============================================================================
-- STEP 7.21F — VERIFY PRODUCT ACTIVE STATUS
-- ============================================================================
-- Purpose:
-- Confirm that the is_active field contains only the two values permitted
-- by the clean schema: 'Yes' and 'No'.
-- ============================================================================

SELECT
    is_active,
    COUNT(*) AS product_count
FROM products
GROUP BY is_active
ORDER BY is_active;

-- ============================================================================
-- STEP 7.21G — CHECK MISSING SUB-CATEGORIES
-- ============================================================================
-- Purpose:
-- Confirm that the 11 missing sub_category values identified during the
-- staging audit have been preserved as NULL in the clean products table.
--
-- Decision:
-- We retain these values as NULL rather than inventing a sub-category.
-- This preserves the original information accurately.
-- ============================================================================

SELECT
    COUNT(*) AS missing_subcategory_count
FROM products
WHERE sub_category IS NULL;

-- ============================================================================
-- STEP 7.22A — CHECK CLEAN ORDERS TABLE
-- ============================================================================
-- Purpose:
-- Confirm that the clean orders table is empty before we begin loading
-- validated order records.
-- ============================================================================

SELECT COUNT(*) AS order_count
FROM orders;

-- ============================================================================
-- STEP 7.22B — VERIFY DUPLICATE ORDERS
-- ============================================================================
-- Purpose:
-- Confirm the number of duplicate order IDs in the raw staging table.
--
-- Cleaning decision:
-- Each duplicated order ID represents an exact duplicate row.
-- During the clean load, we will retain one copy and exclude the duplicate.
--
-- We do NOT modify the staging table.
-- ============================================================================

SELECT
    COUNT(*) AS duplicate_order_ids
FROM (
    SELECT order_id
    FROM stg_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
);

-- ============================================================================
-- STEP 7.22C — CHECK NEGATIVE SHIPPING COSTS
-- ============================================================================
-- Purpose:
-- Identify orders with negative shipping costs.
--
-- Cleaning decision:
-- A shipping cost represents a charge/cost associated with delivery, so a
-- negative value is logically invalid. We will exclude these records from
-- the clean orders table because the correct value cannot be reliably inferred
-- from the raw data.
--
-- The staging table remains unchanged.
-- ============================================================================

SELECT
    COUNT(*) AS negative_shipping_costs
FROM stg_orders
WHERE CAST(shipping_cost AS REAL) < 0;

-- ============================================================================
-- STEP 7.22D — INSPECT NEGATIVE SHIPPING COSTS
-- ============================================================================
-- Purpose:
-- Display the actual orders with negative shipping costs so we can inspect
-- the affected records before deciding how to treat them.
--
-- We do not delete or modify anything at this stage.
-- ============================================================================

SELECT
    order_id,
    customer_id,
    order_date,
    shipping_cost,
    total_amount
FROM stg_orders
WHERE CAST(shipping_cost AS REAL) < 0
ORDER BY shipping_cost;

-- ============================================================================
-- STEP 7.22E — CHECK MISSING ORDER DATES
-- ============================================================================
-- Purpose:
-- Determine how many orders have no order date.
--
-- Cleaning consideration:
-- Order date is important for time-based analysis, customer recency,
-- churn definition, and revenue trends. We will therefore identify these
-- records before deciding how they should be handled.
--
-- The staging table is not modified.
-- ============================================================================

SELECT
    COUNT(*) AS missing_order_dates
FROM stg_orders
WHERE order_date IS NULL
   OR TRIM(order_date) = '';
   
-- ============================================================================
-- STEP 7.22F — CHECK DISCOUNT VALUES
-- ============================================================================
-- Purpose:
-- Identify any discount percentages that fall outside the expected range.
--
-- From the raw data, valid discounts are expected to be:
-- 0%, 5%, 10%, 15%, 20%, or 25%.
--
-- We are only auditing the staging table here.
-- No data is being changed.
-- ============================================================================

SELECT
    discount_pct,
    COUNT(*) AS order_count
FROM stg_orders
GROUP BY discount_pct
ORDER BY CAST(discount_pct AS REAL);

-- ============================================================================
-- STEP 7.22G — CHECK ORDER STATUS VALUES
-- ============================================================================
-- Purpose:
-- Identify all distinct order statuses and count how many orders
-- belong to each status.
--
-- This is important because later analyses such as RFM and churn
-- should distinguish completed orders from returned/cancelled orders.
--
-- We are only auditing the staging table.
-- No data is being changed.
-- ============================================================================

SELECT
    order_status,
    COUNT(*) AS order_count
FROM stg_orders
GROUP BY order_status
ORDER BY order_count DESC;

-- ============================================================================
-- STEP 7.22H — CHECK MISSING OR BLANK ORDER STATUS
-- ============================================================================
-- Purpose:
-- Investigate the 18 orders that were not included in the status
-- distribution from Step 7.22G.
--
-- A missing order status could affect:
--   1. Completed-order analysis
--   2. RFM calculations
--   3. Churn analysis
--   4. Revenue calculations
--
-- We will inspect the actual records before deciding how to handle them.
-- The staging table is not modified.
-- ============================================================================

SELECT
    order_id,
    customer_id,
    order_date,
    order_status,
    total_amount
FROM stg_orders
WHERE order_status IS NULL
   OR TRIM(order_status) = ''
ORDER BY order_id;

-- ============================================================================
-- STEP 7.22I — CHECK PAYMENT METHOD VALUES
-- ============================================================================
-- Purpose:
-- Identify the different payment methods recorded in the raw orders.
--
-- We are checking for inconsistent spelling, capitalization, or unexpected
-- categories before loading the clean orders table.
--
-- The staging table is not modified.
-- ============================================================================

SELECT
    payment_method,
    COUNT(*) AS order_count
FROM stg_orders
GROUP BY payment_method
ORDER BY order_count DESC;

-- ============================================================================
-- STEP 7.22J — CHECK ORDER CHANNEL VALUES
-- ============================================================================
-- Purpose:
-- Identify all channel values recorded for orders and check their frequency.
--
-- Channel will later be used for:
--   1. Churn analysis by channel
--   2. Customer behaviour analysis
--   3. Business recommendations
--
-- We are checking for inconsistent spelling/capitalization before cleaning.
-- The staging table is not modified.
-- ============================================================================

SELECT
    channel,
    COUNT(*) AS order_count
FROM stg_orders
GROUP BY channel
ORDER BY order_count DESC;

-- ============================================================================
-- STEP 7.22K — CHECK ORDER DATE FORMAT
-- ============================================================================
-- Purpose:
-- Examine the format of non-missing order dates.
--
-- We need consistent dates because order_date will later be used for:
--   1. Revenue trends
--   2. Customer recency
--   3. RFM analysis
--   4. Churn calculation
--
-- We are displaying a sample only; the staging table is not modified.
-- ============================================================================

SELECT
    order_date,
    COUNT(*) AS occurrence_count
FROM stg_orders
WHERE order_date IS NOT NULL
  AND TRIM(order_date) <> ''
GROUP BY order_date
ORDER BY order_date
LIMIT 20;

-- ============================================================================
-- STEP 7.22L — CHECK OVERLAP OF ORDER-LEVEL DATA QUALITY ISSUES
-- ============================================================================
-- Purpose:
-- Determine how many distinct orders are affected by one or more of the
-- following problems:
--   1. Duplicate order ID
--   2. Negative shipping cost
--   3. Missing order date
--   4. Missing/orphan customer ID
--
-- This prevents us from double-counting records when deciding the final
-- clean orders population.
--
-- The staging table is not modified.
-- ============================================================================

SELECT
    COUNT(*) AS affected_orders
FROM stg_orders o
WHERE
    o.order_id IN (
        SELECT order_id
        FROM stg_orders
        GROUP BY order_id
        HAVING COUNT(*) > 1
    )
    OR CAST(o.shipping_cost AS REAL) < 0
    OR o.order_date IS NULL
    OR TRIM(o.order_date) = ''
    OR o.customer_id NOT IN (
        SELECT customer_id
        FROM stg_customers
    );
    
-- ============================================================================
-- STEP 7.22M — CHECK MISSING ORDER TOTALS
-- ============================================================================
-- Purpose:
-- Determine whether any orders have a missing total_amount.
--
-- total_amount is important for:
--   1. Revenue analysis
--   2. Customer monetary value
--   3. RFM analysis
--   4. Revenue-at-risk calculations
--
-- We will inspect the result before deciding how to handle any missing values.
-- The staging table is not modified.
-- ============================================================================

SELECT
    COUNT(*) AS missing_total_amount
FROM stg_orders
WHERE total_amount IS NULL;

-- ============================================================================
-- STEP 7.22N — CHECK MISSING SHIPPING COSTS
-- ============================================================================
-- Purpose:
-- Determine whether any orders have a missing shipping_cost.
--
-- We already identified 8 negative shipping costs. Here we separately check
-- for NULL values so that missing and logically invalid values are not
-- treated as the same problem.
--
-- The staging table is not modified.
-- ============================================================================

SELECT
    COUNT(*) AS missing_shipping_cost
FROM stg_orders
WHERE shipping_cost IS NULL;

-- ============================================================================
-- STEP 7.23 — PREVIEW CLEAN ORDERS ROW COUNT
-- ============================================================================
-- Purpose:
-- Calculate how many orders will remain after applying our documented
-- cleaning rules.
--
-- Rules applied:
--   1. Keep only one row for each order_id.
--   2. Remove negative shipping costs.
--   3. Remove orders with missing order dates.
--   4. Remove orders whose customer_id does not exist in customers.
--
-- IMPORTANT:
-- This is only a preview. No data is inserted or deleted.
-- ============================================================================

SELECT
    COUNT(*) AS expected_clean_orders
FROM (
    SELECT
        order_id
    FROM stg_orders
    WHERE CAST(shipping_cost AS REAL) >= 0
      AND order_date IS NOT NULL
      AND TRIM(order_date) <> ''
      AND customer_id IN (
          SELECT customer_id
          FROM customers
      )
    GROUP BY order_id
);

-- ============================================================================
-- STEP 7.24 — LOAD CLEAN ORDERS TABLE
-- ============================================================================
-- Purpose:
-- Populate the clean orders table from the raw staging table while applying
-- the data-quality decisions documented during our audit.
--
-- Cleaning rules:
--   1. Remove negative shipping costs.
--   2. Remove orders with missing order dates.
--   3. Remove orders with customer IDs that do not exist in customers.
--   4. Remove duplicate order IDs by retaining one copy.
--   5. Convert discount_pct from TEXT to NUMERIC.
--   6. Standardize order_status capitalization.
--
-- The original stg_orders table is NOT modified.
-- ============================================================================

INSERT INTO orders (
    order_id,
    customer_id,
    order_date,
    channel,
    order_status,
    payment_method,
    shipping_cost,
    discount_pct,
    total_amount
)
SELECT
    order_id,
    customer_id,
    order_date,
    channel,

    -- Standardize inconsistent capitalization in order status
    CASE LOWER(TRIM(order_status))
        WHEN 'completed' THEN 'Completed'
        WHEN 'returned' THEN 'Returned'
        WHEN 'cancelled' THEN 'Cancelled'
        WHEN 'pending' THEN 'Pending'
        ELSE NULL
    END AS order_status,

    payment_method,

    -- Keep only valid non-negative shipping costs
    CAST(shipping_cost AS NUMERIC) AS shipping_cost,

    -- Convert discount from TEXT to numeric
    CAST(discount_pct AS NUMERIC) AS discount_pct,

    total_amount

FROM (
    -- ROW_NUMBER allows us to retain only one copy of duplicated order IDs.
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY rowid
        ) AS rn
    FROM stg_orders
) AS cleaned

WHERE rn = 1
  AND CAST(shipping_cost AS REAL) >= 0
  AND order_date IS NOT NULL
  AND TRIM(order_date) <> ''
  AND customer_id IN (
      SELECT customer_id
      FROM customers
  );
  
-- ============================================================================
-- STEP 7.24A — VERIFY CLEAN ORDERS COUNT
-- ============================================================================
-- Purpose:
-- Check how many records are actually present in the clean orders table.
--
-- Expected result:
-- 27,821
--
-- This query does not modify any data.
-- ============================================================================

SELECT
    COUNT(*) AS clean_order_count
FROM orders;

-- ============================================================================
-- STEP 7.25A — VALIDATE DUPLICATE ORDER IDs
-- ============================================================================
-- Purpose:
-- Confirm that duplicate order IDs were successfully removed from the
-- clean orders table.
--
-- Expected result:
-- 0
-- ============================================================================

SELECT
    COUNT(*) AS duplicate_order_ids
FROM (
    SELECT
        order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
);

-- ============================================================================
-- STEP 7.25B — VALIDATE NEGATIVE SHIPPING COSTS
-- ============================================================================
-- Purpose:
-- Confirm that all orders with negative shipping costs were excluded from
-- the clean orders table.
--
-- Expected result:
-- 0
-- ============================================================================

SELECT
    COUNT(*) AS negative_shipping_costs
FROM orders
WHERE shipping_cost < 0;

-- ============================================================================
-- STEP 7.25C — VALIDATE MISSING ORDER DATES
-- ============================================================================
-- Purpose:
-- Confirm that orders with missing order dates were excluded from the
-- clean orders table.
--
-- Expected result:
-- 0
--
-- This is important because order_date will later be used for:
--   - revenue trends
--   - customer recency
--   - RFM analysis
--   - churn calculation
-- ============================================================================

SELECT
    COUNT(*) AS missing_order_dates
FROM orders
WHERE order_date IS NULL
   OR TRIM(order_date) = '';
   
-- ============================================================================
-- STEP 7.25D — VALIDATE ORDERS → CUSTOMERS RELATIONSHIP
-- ============================================================================
-- Purpose:
-- Confirm that every customer_id in the clean orders table exists in the
-- clean customers table.
--
-- This validates the FOREIGN KEY relationship:
--     orders.customer_id → customers.customer_id
--
-- Expected result:
-- 0
-- ============================================================================

SELECT
    COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ============================================================================
-- STEP 7.25E — VALIDATE DISCOUNT DATA
-- ============================================================================
-- Purpose:
-- Confirm that discount_pct was successfully converted from TEXT to a
-- numeric value and that all values remain within the valid 0–25% range.
--
-- Expected:
--   - Numeric data types
--   - Minimum = 0
--   - Maximum = 25
--   - Invalid values = 0
-- ============================================================================

SELECT
    typeof(discount_pct) AS data_type,
    MIN(discount_pct) AS minimum_discount,
    MAX(discount_pct) AS maximum_discount,
    COUNT(*) AS order_count
FROM orders
GROUP BY typeof(discount_pct);

-- ============================================================================
-- STEP 7.25F — VALIDATE CLEAN ORDER STATUS
-- ============================================================================
-- Purpose:
-- Confirm that the inconsistent raw status values have been standardized
-- into the four approved business categories.
--
-- Expected clean values:
--   Completed
--   Returned
--   Cancelled
--   Pending
--
-- This is important because later churn and RFM analysis will rely on
-- correctly identifying completed orders.
-- ============================================================================

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- ============================================================================
-- STEP 7.25G — VALIDATE PAYMENT METHOD AND ORDER CHANNEL
-- ============================================================================
-- Purpose:
-- Confirm that the clean orders table contains only the valid payment
-- methods and sales channels identified during the staging audit.
--
-- No transformation was required for these fields, so this is a
-- preservation check.
-- ============================================================================

SELECT
    payment_method,
    channel,
    COUNT(*) AS order_count
FROM orders
GROUP BY payment_method, channel
ORDER BY payment_method, channel;

-- ============================================================================
-- STEP 7.25H — FINAL ORDERS NOT-NULL VALIDATION
-- ============================================================================
-- Purpose:
-- Confirm that all columns defined as NOT NULL in schema.sql contain values.
--
-- Required fields:
--   - order_id
--   - customer_id
--
-- Expected result:
--   missing_order_ids = 0
--   missing_customer_ids = 0
-- ============================================================================

SELECT
    SUM(
        CASE
            WHEN order_id IS NULL OR TRIM(order_id) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_order_ids,

    SUM(
        CASE
            WHEN customer_id IS NULL OR TRIM(customer_id) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_customer_ids

FROM orders;

-- ============================================================================
-- STEP 7.26 — PREVIEW EXPECTED CLEAN ORDER ITEMS
-- ============================================================================
-- Purpose:
-- Estimate how many order-item records can safely enter the clean table.
--
-- We will:
--   1. Remove duplicate order_item_id records.
--   2. Exclude invalid quantities (quantity <= 0).
--   3. Keep only items belonging to valid clean orders.
--   4. Keep only items referring to valid products.
--
-- We are only PREVIEWING the count here.
-- No data will be inserted or deleted.
-- ============================================================================

SELECT COUNT(*) AS expected_clean_order_items
FROM (
    SELECT
        order_item_id
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY order_item_id
                   ORDER BY rowid
               ) AS rn
        FROM stg_order_items
    ) deduplicated
    WHERE rn = 1
      AND quantity > 0
      AND order_id IN (
          SELECT order_id
          FROM orders
      )
      AND product_id IN (
          SELECT product_id
          FROM products
      )
);

-- ============================================================================
-- STEP 7.27 — LOAD CLEAN ORDER ITEMS
-- ============================================================================
-- Purpose:
-- Populate the clean order_items table while enforcing our documented
-- cleaning decisions.
--
-- Cleaning decisions:
--   1. Remove duplicate order_item_id records.
--      We keep the first occurrence.
--
--   2. Remove records where quantity <= 0.
--      These quantities are invalid and we do not invent a replacement value.
--
--   3. Remove items belonging to orders that were excluded from the clean
--      orders table (for example, orphan orders).
--
--   4. Keep only products that exist in the clean products table.
--
-- The raw staging table remains unchanged.
-- ============================================================================

INSERT INTO order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase
)
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_item_id
               ORDER BY rowid
           ) AS rn
    FROM stg_order_items
) deduplicated
WHERE rn = 1
  AND quantity > 0
  AND order_id IN (
      SELECT order_id
      FROM orders
  )
  AND product_id IN (
      SELECT product_id
      FROM products
  );
  
-- ============================================================================
-- STEP 7.28 — VERIFY CLEAN ORDER ITEMS ROW COUNT
-- ============================================================================
-- Purpose:
-- Confirm that the number of records inserted into the clean order_items
-- table matches the number we calculated during the preview.
--
-- Expected result:
--   clean_order_items = 72,213
-- ============================================================================

SELECT
    COUNT(*) AS clean_order_items
FROM order_items;

-- ============================================================================
-- STEP 7.29 — VALIDATE ORDER ITEMS PRIMARY KEY
-- ============================================================================
-- Purpose:
-- Confirm that every order_item_id is unique in the clean table.
--
-- This is important because order_item_id is defined as the PRIMARY KEY
-- in schema.sql.
--
-- Expected result:
--   duplicate_order_item_ids = 0
-- ============================================================================

SELECT
    COUNT(*) AS duplicate_order_item_ids
FROM (
    SELECT
        order_item_id
    FROM order_items
    GROUP BY order_item_id
    HAVING COUNT(*) > 1
);

-- ============================================================================
-- STEP 7.30 — VALIDATE ORDER ITEMS FOREIGN KEYS
-- ============================================================================
-- Purpose:
-- Confirm that every order_item is linked to:
--   1. A valid order in the clean orders table.
--   2. A valid product in the clean products table.
--
-- This protects the relationships defined in schema.sql:
--
--   orders 1 ----< order_items >---- 1 products
--
-- Expected result:
--   orphan_order_items = 0
--   orphan_product_items = 0
-- ============================================================================

SELECT
    SUM(
        CASE
            WHEN o.order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orphan_order_items,

    SUM(
        CASE
            WHEN p.product_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orphan_product_items

FROM order_items oi

LEFT JOIN orders o
    ON oi.order_id = o.order_id

LEFT JOIN products p
    ON oi.product_id = p.product_id;
    
-- ============================================================================
-- STEP 7.31 — VALIDATE ORDER ITEM QUANTITIES
-- ============================================================================
-- Purpose:
-- Confirm that no invalid quantities (zero or negative values) remain
-- in the clean order_items table.
--
-- Our cleaning rule was:
--   quantity > 0
--
-- Expected result:
--   invalid_quantities = 0
-- ============================================================================

SELECT
    COUNT(*) AS invalid_quantities
FROM order_items
WHERE quantity <= 0;

-- ============================================================================
-- STEP 7.32 — FINAL ORDER ITEMS REQUIRED-FIELD VALIDATION
-- ============================================================================
-- Purpose:
-- Confirm that the fields required by schema.sql contain no missing values.
--
-- Required fields:
--   - order_item_id
--   - order_id
--   - product_id
--
-- Expected result:
--   missing_order_item_ids = 0
--   missing_order_ids      = 0
--   missing_product_ids    = 0
-- ============================================================================

SELECT
    SUM(
        CASE
            WHEN order_item_id IS NULL OR TRIM(order_item_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_order_item_ids,

    SUM(
        CASE
            WHEN order_id IS NULL OR TRIM(order_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_order_ids,

    SUM(
        CASE
            WHEN product_id IS NULL OR TRIM(product_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_product_ids

FROM order_items;

-- ============================================================================
-- STEP 7.33A — PREVIEW EXPECTED CLEAN SUPPORT TICKETS
-- ============================================================================
-- Purpose:
-- Calculate how many support-ticket records can safely enter the clean table.
--
-- Cleaning rules:
--   1. Keep the unique ticket records.
--   2. Exclude records with negative resolution time.
--   3. Keep records with missing satisfaction scores because NULL is allowed
--      by the target schema and we should not invent customer ratings.
--   4. Keep only tickets belonging to valid customers.
--
-- We are ONLY calculating the expected count here.
-- No data is being inserted or deleted.
-- ============================================================================

SELECT
    COUNT(*) AS expected_clean_support_tickets
FROM stg_support_tickets
WHERE resolution_time_hours >= 0
  AND customer_id IN (
      SELECT customer_id
      FROM customers
  );
  
-- ============================================================================
-- STEP 7.33B — LOAD CLEAN SUPPORT TICKETS
-- ============================================================================
-- Purpose:
-- Populate the clean support_tickets table using the cleaning decisions
-- established during our data-quality audit.
--
-- Cleaning decisions:
--   1. Exclude tickets with negative resolution times because a resolution
--      time cannot logically be negative.
--
--   2. Keep missing satisfaction scores as NULL.
--      The target schema allows NULL, and we should not invent ratings.
--
--   3. Keep only tickets belonging to valid customers.
--
-- The raw staging table remains unchanged.
-- ============================================================================

INSERT INTO support_tickets (
    ticket_id,
    customer_id,
    ticket_date,
    issue_category,
    channel,
    resolution_time_hours,
    satisfaction_score,
    ticket_text
)
SELECT
    ticket_id,
    customer_id,
    ticket_date,
    issue_category,
    channel,
    resolution_time_hours,
    satisfaction_score,
    ticket_text
FROM stg_support_tickets
WHERE resolution_time_hours >= 0
  AND customer_id IN (
      SELECT customer_id
      FROM customers
  );
  
-- ============================================================================
-- STEP 7.34 — VERIFY CLEAN SUPPORT TICKET ROW COUNT
-- ============================================================================
-- Purpose:
-- Confirm that the number of records in the clean support_tickets table
-- matches our expected count of 5,194.
--
-- Expected result:
--   clean_support_tickets = 5,194
-- ============================================================================

SELECT
    COUNT(*) AS clean_support_tickets
FROM support_tickets;

-- ============================================================================
-- STEP 7.35 — VALIDATE SUPPORT TICKET PRIMARY KEY
-- ============================================================================
-- Purpose:
-- Confirm that no ticket_id appears more than once in the clean table.
--
-- Expected result:
--   duplicate_ticket_ids = 0
-- ============================================================================

SELECT
    COUNT(*) AS duplicate_ticket_ids
FROM (
    SELECT
        ticket_id
    FROM support_tickets
    GROUP BY ticket_id
    HAVING COUNT(*) > 1
);

-- ============================================================================
-- STEP 7.36 — VALIDATE SUPPORT TICKET CUSTOMER FOREIGN KEY
-- ============================================================================
-- Purpose:
-- Confirm that every support ticket is linked to an existing customer.
--
-- Relationship:
--   customers 1 ----< support_tickets
--
-- Expected result:
--   orphan_customer_tickets = 0
-- ============================================================================

SELECT
    COUNT(*) AS orphan_customer_tickets
FROM support_tickets st
LEFT JOIN customers c
    ON st.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ============================================================================
-- STEP 7.37 — VALIDATE SUPPORT TICKET RESOLUTION TIMES
-- ============================================================================
-- Purpose:
-- Confirm that no negative resolution times remain after cleaning.
--
-- Business logic:
-- A support-ticket resolution time represents elapsed time, so a negative
-- value is invalid.
--
-- Expected result:
--   negative_resolution_times = 0
-- ============================================================================

SELECT
    COUNT(*) AS negative_resolution_times
FROM support_tickets
WHERE resolution_time_hours < 0;

-- ============================================================================
-- STEP 7.38 — VALIDATE SUPPORT TICKET SATISFACTION SCORES
-- ============================================================================
-- Purpose:
-- Confirm that no invalid satisfaction scores exist in the clean table.
--
-- Valid range:
--   1 = lowest satisfaction
--   5 = highest satisfaction
--
-- NULL values are intentionally allowed because the target schema does not
-- declare satisfaction_score as NOT NULL.
--
-- Expected result:
--   invalid_satisfaction_scores = 0
-- ============================================================================

SELECT
    COUNT(*) AS invalid_satisfaction_scores
FROM support_tickets
WHERE satisfaction_score IS NOT NULL
  AND (
      satisfaction_score < 1
      OR satisfaction_score > 5
  );
  
-- ============================================================================
-- STEP 7.39 — FINAL SUPPORT TICKETS REQUIRED-FIELD VALIDATION
-- ============================================================================
-- Purpose:
-- Confirm that all columns defined as NOT NULL in schema.sql contain values.
--
-- Required fields:
--   - ticket_id
--   - customer_id
--
-- Expected result:
--   missing_ticket_ids   = 0
--   missing_customer_ids = 0
-- ============================================================================

SELECT
    SUM(
        CASE
            WHEN ticket_id IS NULL OR TRIM(ticket_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_ticket_ids,

    SUM(
        CASE
            WHEN customer_id IS NULL OR TRIM(customer_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_customer_ids

FROM support_tickets;

-- ============================================================================
-- STEP 7.40 — OVERALL DATABASE RELATIONSHIP VALIDATION
-- ============================================================================
-- Purpose:
-- Perform a final check of the relationships among the clean tables.
--
-- We verify:
--   1. Every order belongs to a customer.
--   2. Every order item belongs to an order.
--   3. Every order item belongs to a product.
--   4. Every support ticket belongs to a customer.
--
-- Expected result:
--   All four orphan counts should be 0.
-- ============================================================================

SELECT
    (
        SELECT COUNT(*)
        FROM orders o
        LEFT JOIN customers c
            ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    ) AS orphan_orders,

    (
        SELECT COUNT(*)
        FROM order_items oi
        LEFT JOIN orders o
            ON oi.order_id = o.order_id
        WHERE o.order_id IS NULL
    ) AS orphan_order_items,

    (
        SELECT COUNT(*)
        FROM order_items oi
        LEFT JOIN products p
            ON oi.product_id = p.product_id
        WHERE p.product_id IS NULL
    ) AS orphan_product_items,

    (
        SELECT COUNT(*)
        FROM support_tickets st
        LEFT JOIN customers c
            ON st.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    ) AS orphan_support_tickets;
    
-- PHASE 4 — SQL ANALYSIS TASKS (Meridian Retail Group)
-- Q1 (Basic SELECT/WHERE/ORDER BY)
-- List the 20 most recent orders with status 'Completed', showing order_id,
-- customer_id, order_date and total_amount, most recent first.

-- ============================================================================
-- Q1 — 20 MOST RECENT COMPLETED ORDERS
-- ============================================================================
-- Purpose:
-- List the 20 latest completed orders.
--
-- WHERE keeps only completed orders.
-- ORDER BY sorts by order date from newest to oldest.
-- LIMIT returns only the first 20 records.
-- ============================================================================

SELECT
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE order_status = 'Completed'
ORDER BY order_date DESC
LIMIT 20;


-- Q2 (Aggregation/GROUP BY)
-- For each membership_tier, calculate the number of customers, total revenue
-- generated (completed orders only), and average order value.

-- ============================================================================
-- Q2 — CUSTOMER COUNT, REVENUE AND AVERAGE ORDER VALUE BY MEMBERSHIP TIER
-- ============================================================================
-- Purpose:
-- Compare customer population and completed-order performance across
-- membership tiers.
--
-- COUNT(DISTINCT) ensures each customer is counted only once.
-- SUM calculates completed-order revenue.
-- AVG calculates the average completed order value.
-- LEFT JOIN keeps all membership tiers represented.
-- ============================================================================

SELECT
    c.membership_tier,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS average_order_value
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Completed'
GROUP BY c.membership_tier
ORDER BY c.membership_tier;


-- Q3 (JOIN)
-- List the top 15 products by total revenue (quantity * unit_price_at_purchase),
-- including product_name, category, and brand.

-- ============================================================================
-- Q3 — TOP 15 PRODUCTS BY TOTAL REVENUE
-- ============================================================================
-- Purpose:
-- Identify the 15 products with the highest revenue from order-item sales.
--
-- Revenue for each order item is:
--     quantity × unit_price_at_purchase
--
-- We join order_items to products to obtain product information.
-- GROUP BY aggregates the calculated revenue for each product.
-- ORDER BY places the highest-revenue products first.
-- LIMIT restricts the result to the top 15.
-- ============================================================================

SELECT
    p.product_name,
    p.category,
    p.brand,
    SUM(oi.quantity * oi.unit_price_at_purchase) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.brand
ORDER BY total_revenue DESC
LIMIT 15;


-- Q4 (JOIN across 3+ tables)
-- For every customer in the 'Platinum' tier, show their total number of
-- orders, total spend, and total number of support tickets raised.

-- ============================================================================
-- Q4 — PLATINUM CUSTOMERS: ORDERS, SPEND AND SUPPORT TICKETS
-- ============================================================================
-- Purpose:
-- For every Platinum customer, calculate:
--   1. Total number of orders (all order statuses)
--   2. Total spend from completed orders only
--   3. Total number of support tickets
--
-- We aggregate orders and support tickets separately before joining them.
-- This prevents a many-to-many join from multiplying counts and amounts.
--
-- COALESCE changes missing activity into 0.
-- ============================================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,

    -- Count ALL orders placed by the customer
    COALESCE(o.total_orders, 0) AS total_orders,

    -- Count only completed orders when calculating realized spend
    COALESCE(o.completed_spend, 0) AS total_spend,

    -- Count all support tickets raised by the customer
    COALESCE(s.total_support_tickets, 0) AS total_support_tickets

FROM customers c

-- Aggregate order activity separately
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN order_status = 'Completed'
                THEN total_amount
                ELSE 0
            END
        ) AS completed_spend
    FROM orders
    GROUP BY customer_id
) o
    ON c.customer_id = o.customer_id

-- Aggregate support activity separately
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS total_support_tickets
    FROM support_tickets
    GROUP BY customer_id
) s
    ON c.customer_id = s.customer_id

-- We only want Platinum customers
WHERE c.membership_tier = 'Platinum'

ORDER BY c.customer_id;


-- Q5 (Subquery)
-- Find all customers whose total spend (completed orders) is above the
-- overall average total spend per customer.

-- ============================================================================
-- Q5 — CUSTOMERS ABOVE THE OVERALL AVERAGE SPEND
-- ============================================================================
-- Purpose:
-- Find customers whose total spend from completed orders is greater than
-- the overall average total spend per customer.
--
-- IMPORTANT:
-- The average is calculated across ALL customers, including customers
-- with zero completed-order spend. This gives us a true customer-level
-- population average.
--
-- The inner subquery calculates each customer's total completed spend.
-- The outer query compares each customer's spend with the average.
-- ============================================================================

SELECT
    customer_id,
    first_name,
    last_name,
    total_spend

FROM (
    -- Calculate completed-order spend for every customer
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        COALESCE(SUM(o.total_amount), 0) AS total_spend

    FROM customers c

    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
        AND o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
) customer_spend

-- Keep only customers whose spend is above the overall customer average
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM (
        -- Recalculate total spend for all customers
        -- so customers with zero spend are included in the average.
        SELECT
            c2.customer_id,
            COALESCE(SUM(o2.total_amount), 0) AS total_spend

        FROM customers c2

        LEFT JOIN orders o2
            ON c2.customer_id = o2.customer_id
            AND o2.order_status = 'Completed'

        GROUP BY c2.customer_id
    ) overall_spend
)

ORDER BY total_spend DESC;


-- Q6 (Subquery / NOT IN or NOT EXISTS)
-- Find all customers who have never placed an order.

-- ============================================================================
-- Q6 — CUSTOMERS WHO HAVE NEVER PLACED AN ORDER
-- ============================================================================
-- Purpose:
-- Identify customers in the customers table for whom there is no
-- corresponding record in the orders table.
--
-- We use NOT EXISTS because it directly tests whether a matching order
-- exists for each customer.
--
-- This considers ALL order statuses (Completed, Returned, Cancelled,
-- and Pending), because the question asks who has NEVER placed an order.
-- ============================================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name

FROM customers c

-- Check whether this customer has at least one order
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
)

ORDER BY c.customer_id;

-- Q7 (CASE statement)
-- Categorize each order into a "value_band": 'Low' (<$50), 'Medium' ($50-$200),
-- 'High' (>$200). Report the count of orders and total revenue per band.

-- ============================================================================
-- Q7 — ORDER VALUE BANDS
-- ============================================================================
-- Purpose:
-- Categorize every clean order according to its total order value:
--
--   Low    = less than $50
--   Medium = $50 through $200
--   High   = greater than $200
--
-- CASE creates the value_band category.
-- COUNT(*) gives the number of orders in each band.
-- SUM(total_amount) gives the total revenue represented by each band.
--
-- Note:
-- We use all clean orders because the question says "each order" and does
-- not specify Completed orders only.
-- ============================================================================

SELECT
    CASE
        WHEN total_amount < 50 THEN 'Low'
        WHEN total_amount <= 200 THEN 'Medium'
        ELSE 'High'
    END AS value_band,

    COUNT(*) AS order_count,

    SUM(total_amount) AS total_revenue

FROM orders

GROUP BY value_band

ORDER BY
    CASE value_band
        WHEN 'Low' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'High' THEN 3
    END;


-- Q8 (Date logic / recency — this is your churn label!)
-- Using a snapshot date of '2026-07-01', label each customer as 'Churned'
-- (no completed order in the last 180 days, or never ordered) or 'Active'.
-- Report the count of customers in each label.

-- ============================================================================
-- Q8 — CUSTOMER CHURN LABEL AT THE 2026-07-01 SNAPSHOT
-- ============================================================================
-- Purpose:
-- Label every customer as either:
--
--   Churned = no completed order in the previous 180 days,
--             or the customer has never placed an order.
--
--   Active  = at least one completed order within the previous 180 days.
--
-- IMPORTANT:
-- We only consider Completed orders dated on or before the snapshot date.
-- This prevents orders occurring after 2026-07-01 from influencing the label.
--
-- The 180-day cutoff is calculated dynamically as:
-- 2026-07-01 minus 180 days.
-- ============================================================================

WITH customer_last_order AS (

    -- Find each customer's most recent completed order
    -- as of the snapshot date.
    SELECT
        c.customer_id,

        MAX(
            CASE
                WHEN o.order_status = 'Completed'
                 AND date(o.order_date) <= date('2026-07-01')
                THEN date(o.order_date)
            END
        ) AS last_completed_order

    FROM customers c

    LEFT JOIN orders o
        ON c.customer_id = o.customer_id

    GROUP BY c.customer_id
),

customer_labels AS (

    -- Apply the 180-day churn rule to each customer.
    SELECT
        customer_id,

        CASE
            WHEN last_completed_order IS NULL
                THEN 'Churned'

            WHEN last_completed_order < date('2026-07-01', '-180 days')
                THEN 'Churned'

            ELSE 'Active'
        END AS churn_label

    FROM customer_last_order
)

-- Count how many customers fall into each churn category.
SELECT
    churn_label,
    COUNT(*) AS customer_count

FROM customer_labels

GROUP BY churn_label

ORDER BY churn_label;


-- Q9 (Aggregation + HAVING)
-- Find product categories where average order item quantity exceeds 1.5.

-- ============================================================================
-- Q9 — PRODUCT CATEGORIES WITH AVERAGE ITEM QUANTITY > 1.5
-- ============================================================================
-- Purpose:
-- Calculate the average quantity purchased per order-item record for each
-- product category.
--
-- We JOIN order_items to products because the category information is stored
-- in the products table, while quantity is stored in order_items.
--
-- HAVING is used instead of WHERE because we are filtering on an aggregated
-- value (the average quantity).
-- ============================================================================

SELECT
    p.category,

    -- Calculate the average quantity purchased per order-item record.
    ROUND(AVG(oi.quantity), 2) AS average_item_quantity

FROM order_items oi

-- Connect each order item to its corresponding product.
JOIN products p
    ON oi.product_id = p.product_id

-- Calculate the average separately for each product category.
GROUP BY p.category

-- Keep only categories whose average quantity exceeds 1.5.
HAVING AVG(oi.quantity) > 1.5

-- Display the categories from the highest average quantity downward.
ORDER BY average_item_quantity DESC;


-- Q10 (Data modification)
-- Write an UPDATE statement that corrects any order_items rows where
-- quantity is negative (assume it should be the absolute value).
-- Write a DELETE statement that removes exact duplicate rows from
-- order_items (same order_id, product_id, quantity, unit_price_at_purchase).

-- ============================================================================
-- Q10 — DATA MODIFICATION
-- ============================================================================
-- Purpose:
-- Demonstrate how to correct negative quantities and remove exact duplicate
-- order-item combinations.
--
-- IMPORTANT:
-- Our clean order_items table has already been validated and currently has:
--   * 0 negative quantities
--   * 0 exact duplicate combinations
--
-- Therefore, these statements are expected to affect 0 rows.
--
-- We are working on the CLEAN order_items table, NOT the staging table.
-- The raw staging data must remain unchanged for audit purposes.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- STEP 1: Check for negative quantities before making any modification.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*) AS negative_quantity_rows
FROM order_items
WHERE quantity < 0;


-- ---------------------------------------------------------------------------
-- STEP 2: Correct negative quantities.
--
-- ABS(quantity) converts a negative quantity to its positive equivalent.
-- The WHERE clause ensures that only negative quantities are changed.
-- ---------------------------------------------------------------------------
UPDATE order_items
SET quantity = ABS(quantity)
WHERE quantity < 0;


-- ---------------------------------------------------------------------------
-- STEP 3: Check for exact duplicate combinations.
--
-- The assignment defines duplicates using:
-- order_id + product_id + quantity + unit_price_at_purchase
-- ---------------------------------------------------------------------------
SELECT
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase,
    COUNT(*) AS duplicate_count

FROM order_items

GROUP BY
    order_id,
    product_id,
    quantity,
    unit_price_at_purchase

HAVING COUNT(*) > 1;


-- ---------------------------------------------------------------------------
-- STEP 4: Remove duplicate combinations while retaining one copy.
--
-- SQLite's rowid identifies the physical row.
-- MIN(rowid) keeps the first physical occurrence of each duplicate group.
-- All other copies are deleted.
-- ---------------------------------------------------------------------------
DELETE FROM order_items

WHERE rowid NOT IN (
    SELECT MIN(rowid)

    FROM order_items

    GROUP BY
        order_id,
        product_id,
        quantity,
        unit_price_at_purchase
);


-- Q11 (Constraints / schema design question — answer in a comment, no SQL needed)
-- Explain what would go wrong if 'customer_id' in orders was NOT declared as
-- a foreign key referencing customers, given what you found in Q6 and the
-- orphaned customer_ids present in the raw orders data.

-- ============================================================================
-- Q11 — CONSTRAINT / SCHEMA DESIGN EXPLANATION
-- ============================================================================
-- Question:
-- What would go wrong if customer_id in orders was NOT declared as a
-- foreign key referencing customers?
-- ============================================================================

-- If customer_id in orders were not declared as a foreign key, the database
-- could accept an order containing a customer_id that does not exist in the
-- customers table.
--
-- This is important because our raw staging data contained 20 orphan orders
-- whose customer_id values did not match any customer in the customers table.
--
-- Without the foreign key constraint:
--
-- 1. Invalid customer-order relationships could remain in the database.
--
-- 2. Those orders could not be reliably linked to a real customer.
--
-- 3. Customer-level analysis such as total spend, order frequency and
--    customer revenue could become incomplete or misleading.
--
-- 4. The database would not automatically prevent new orphan orders from
--    being inserted.
--
-- The FOREIGN KEY constraint in the clean orders table enforces referential
-- integrity by requiring every orders.customer_id to correspond to an
-- existing customers.customer_id.
--
-- Therefore, during the clean-data loading process, the 20 orphan orders
-- were excluded because their customer IDs did not exist in customers.
--
-- IMPORTANT DISTINCTION:
--
-- A customer who "never placed an order" exists in the customers table but
-- has no matching order. This was the subject of Q6.
--
-- An orphan order is the opposite problem: an order exists, but its
-- customer_id does not correspond to a customer in the customers table.


-- Q12 (Performance)
-- The query in Q1 filters on order_status and sorts by order_date. Which
-- index(es) would help this query, and why? (Answer in a comment; you may
-- also run EXPLAIN QUERY PLAN in SQLite to support your answer.)

--Q12 — Performance / Index
--1. First: Q1 query being tested
SELECT
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE order_status = 'Completed'
ORDER BY order_date DESC
LIMIT 20;

--2. Second: Check the query plan BEFORE the new index
EXPLAIN QUERY PLAN
SELECT
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE order_status = 'Completed'
ORDER BY order_date DESC
LIMIT 20;

--3. Third: Create the composite index
CREATE INDEX idx_orders_status_order_date
ON orders(order_status, order_date DESC);

--4. Fourth: Check the query plan AFTER the new index
EXPLAIN QUERY PLAN
SELECT
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE order_status = 'Completed'
ORDER BY order_date DESC
LIMIT 20;

--5. Finally: Q12 answer/comment
-- ============================================================================
-- Q12 — PERFORMANCE / INDEX DESIGN
-- ============================================================================
-- Question:
-- The query in Q1 filters on order_status and sorts by order_date.
-- Which index(es) would help this query, and why?
-- ============================================================================

-- Q1 filters using:
--     WHERE order_status = 'Completed'
--
-- and sorts using:
--     ORDER BY order_date DESC
--
-- The original schema already contained:
--
--     CREATE INDEX idx_orders_order_date
--     ON orders(order_date);
--
-- This index helps with the ordering by order_date, but it does not
-- specifically organize the data around the order_status filter.
--
-- A composite index is more suitable for this query:
--
--     CREATE INDEX idx_orders_status_order_date
--     ON orders(order_status, order_date DESC);
--
-- order_status is placed first because the query uses it as an equality
-- filter in the WHERE clause.
--
-- order_date is placed second because the query sorts by this column.
--
-- EXPLAIN QUERY PLAN before the composite index showed:
--
--     SCAN orders USING INDEX idx_orders_order_date
--
-- After creating the composite index, the query plan showed:
--
--     SEARCH orders USING INDEX idx_orders_status_order_date (order_status=?)
--
-- This demonstrates that SQLite is using the new composite index to search
-- for the required order_status values.
--
-- Therefore, the composite index is appropriate for improving the access
-- pattern of Q1, particularly because the query both filters by
-- order_status and orders the results by order_date.
--
-- Note:
-- Indexes improve read/query performance but also require additional storage
-- and can add overhead to INSERT, UPDATE and DELETE operations.
-- ============================================================================






