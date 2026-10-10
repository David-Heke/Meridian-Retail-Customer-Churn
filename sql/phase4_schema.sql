-- ============================================================================
-- Meridian Retail Group — Capstone Database Schema
-- Target engine: SQLite (default) — PostgreSQL/MySQL notes included as comments
-- ============================================================================
-- NOTE TO STUDENTS: This schema defines the CLEAN, staged structure your raw
-- CSVs should be loaded into. Loading messy CSV data directly may violate
-- these constraints — that is intentional. Part of Phase 4 is deciding how to
-- handle rows that fail constraints (reject, clean, or quarantine them) and
-- justifying your approach.
-- ============================================================================

DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ----------------------------------------------------------------------------
-- CUSTOMERS
-- ----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id         TEXT PRIMARY KEY,
    first_name          TEXT NOT NULL,
    last_name            TEXT NOT NULL,
    email                TEXT,
    phone                TEXT,
    gender               TEXT CHECK (gender IN ('F','M','Other')),
    date_of_birth        DATE,
    signup_date          DATE NOT NULL,
    state                TEXT,
    city                 TEXT,
    membership_tier      TEXT CHECK (membership_tier IN ('Bronze','Silver','Gold','Platinum')),
    preferred_channel    TEXT,
    marketing_opt_in     TEXT,      -- intentionally left permissive: raw values are inconsistent
    referral_source      TEXT
);

-- ----------------------------------------------------------------------------
-- PRODUCTS
-- ----------------------------------------------------------------------------
CREATE TABLE products (
    product_id      TEXT PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category        TEXT NOT NULL,
    sub_category    TEXT,
    brand           TEXT,
    unit_cost       NUMERIC(10,2) CHECK (unit_cost >= 0),
    unit_price      NUMERIC(10,2) CHECK (unit_price >= 0),
    launch_date     DATE,
    is_active       TEXT CHECK (is_active IN ('Yes','No'))
);

-- ----------------------------------------------------------------------------
-- ORDERS
-- ----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id        TEXT PRIMARY KEY,
    customer_id     TEXT NOT NULL,
    order_date      DATE,
    channel         TEXT,
    order_status    TEXT,
    payment_method  TEXT,
    shipping_cost   NUMERIC(10,2),
    discount_pct    NUMERIC(5,2),
    total_amount    NUMERIC(12,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ----------------------------------------------------------------------------
-- ORDER ITEMS
-- ----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id           TEXT PRIMARY KEY,
    order_id                TEXT NOT NULL,
    product_id               TEXT NOT NULL,
    quantity                 INTEGER,
    unit_price_at_purchase   NUMERIC(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ----------------------------------------------------------------------------
-- SUPPORT TICKETS
-- ----------------------------------------------------------------------------
CREATE TABLE support_tickets (
    ticket_id               TEXT PRIMARY KEY,
    customer_id             TEXT NOT NULL,
    ticket_date             DATE,
    issue_category          TEXT,
    channel                 TEXT,
    resolution_time_hours   NUMERIC(10,2),
    satisfaction_score      INTEGER CHECK (satisfaction_score BETWEEN 1 AND 5),
    ticket_text             TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ----------------------------------------------------------------------------
-- INDEXES (Phase 4: indexing / performance)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_orders_customer_id   ON orders(customer_id);
CREATE INDEX idx_orders_order_date    ON orders(order_date);
CREATE INDEX idx_items_order_id       ON order_items(order_id);
CREATE INDEX idx_items_product_id     ON order_items(product_id);
CREATE INDEX idx_tickets_customer_id  ON support_tickets(customer_id);

-- PostgreSQL/MySQL users: TEXT primary keys work in both; if using MySQL,
-- replace NUMERIC with DECIMAL, and note MySQL does not enforce CHECK
-- constraints before v8.0.16 — the constraints are still worth writing for
-- documentation and for engines that DO enforce them (PostgreSQL, SQLite 3.37+).
