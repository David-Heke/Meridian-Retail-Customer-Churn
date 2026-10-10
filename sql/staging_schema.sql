-- ============================================================================
-- STAGING SCHEMA — mirrors the raw CSV files exactly (permissive TEXT columns,
-- no constraints). This is where you load the raw data AS-IS.
-- Your job in Phase 4/6 is to clean this into the constrained schema in
-- schema.sql (the "clean" / analytics-ready tables).
-- ============================================================================

DROP TABLE IF EXISTS stg_support_tickets;
DROP TABLE IF EXISTS stg_order_items;
DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_customers;

CREATE TABLE stg_customers (
    customer_id TEXT, first_name TEXT, last_name TEXT, email TEXT, phone TEXT,
    gender TEXT, date_of_birth TEXT, signup_date TEXT, state TEXT, city TEXT,
    membership_tier TEXT, preferred_channel TEXT, marketing_opt_in TEXT, referral_source TEXT
);

CREATE TABLE stg_products (
    product_id TEXT, product_name TEXT, category TEXT, sub_category TEXT, brand TEXT,
    unit_cost TEXT, unit_price TEXT, launch_date TEXT, is_active TEXT
);

CREATE TABLE stg_orders (
    order_id TEXT, customer_id TEXT, order_date TEXT, channel TEXT, order_status TEXT,
    payment_method TEXT, shipping_cost TEXT, discount_pct TEXT, total_amount TEXT
);

CREATE TABLE stg_order_items (
    order_item_id TEXT, order_id TEXT, product_id TEXT, quantity TEXT, unit_price_at_purchase TEXT
);

CREATE TABLE stg_support_tickets (
    ticket_id TEXT, customer_id TEXT, ticket_date TEXT, issue_category TEXT, channel TEXT,
    resolution_time_hours TEXT, satisfaction_score TEXT, ticket_text TEXT
);
