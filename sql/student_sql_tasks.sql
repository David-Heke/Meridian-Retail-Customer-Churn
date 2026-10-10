-- ============================================================================
-- PHASE 4 — SQL ANALYSIS TASKS (Meridian Retail Group)
-- Run these against the CLEANED tables (customers, products, orders,
-- order_items, support_tickets) that you build from the staging tables.
-- Write your actual SQL under each question. Save this file as your submission.
-- ============================================================================

-- Q1 (Basic SELECT/WHERE/ORDER BY)
-- List the 20 most recent orders with status 'Completed', showing order_id,
-- customer_id, order_date and total_amount, most recent first.


-- Q2 (Aggregation/GROUP BY)
-- For each membership_tier, calculate the number of customers, total revenue
-- generated (completed orders only), and average order value.


-- Q3 (JOIN)
-- List the top 15 products by total revenue (quantity * unit_price_at_purchase),
-- including product_name, category, and brand.


-- Q4 (JOIN across 3+ tables)
-- For every customer in the 'Platinum' tier, show their total number of
-- orders, total spend, and total number of support tickets raised.


-- Q5 (Subquery)
-- Find all customers whose total spend (completed orders) is above the
-- overall average total spend per customer.


-- Q6 (Subquery / NOT IN or NOT EXISTS)
-- Find all customers who have never placed an order.


-- Q7 (CASE statement)
-- Categorize each order into a "value_band": 'Low' (<$50), 'Medium' ($50-$200),
-- 'High' (>$200). Report the count of orders and total revenue per band.


-- Q8 (Date logic / recency — this is your churn label!)
-- Using a snapshot date of '2026-07-01', label each customer as 'Churned'
-- (no completed order in the last 180 days, or never ordered) or 'Active'.
-- Report the count of customers in each label.


-- Q9 (Aggregation + HAVING)
-- Find product categories where average order item quantity exceeds 1.5.


-- Q10 (Data modification)
-- Write an UPDATE statement that corrects any order_items rows where
-- quantity is negative (assume it should be the absolute value).
-- Write a DELETE statement that removes exact duplicate rows from
-- order_items (same order_id, product_id, quantity, unit_price_at_purchase).


-- Q11 (Constraints / schema design question — answer in a comment, no SQL needed)
-- Explain what would go wrong if 'customer_id' in orders was NOT declared as
-- a foreign key referencing customers, given what you found in Q6 and the
-- orphaned customer_ids present in the raw orders data.


-- Q12 (Performance)
-- The query in Q1 filters on order_status and sorts by order_date. Which
-- index(es) would help this query, and why? (Answer in a comment; you may
-- also run EXPLAIN QUERY PLAN in SQLite to support your answer.)
