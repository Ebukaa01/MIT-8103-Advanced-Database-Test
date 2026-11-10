-- =====================================================================
-- Portfolio 2: Query Planner Experiments
-- Demonstrates query optimization internals, cost models, and selectivity.
-- Run on equity_db AFTER indexes exist (after 03_create_indexes.sql).
--
-- Safety:
--   - Does NOT modify application data.
--   - SET parameters apply only to the active connection/session.
--   - Part D runs inside a transaction and is ROLLED BACK.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Part A: Environment and Planner Cost Settings
-- (Copy output into the "Environment" section of performance-analysis.md)
-- ---------------------------------------------------------------------
SELECT version();
SHOW block_size;           -- page size in bytes (normally 8192)
SHOW shared_buffers;
SHOW work_mem;
SHOW seq_page_cost;        -- cost of reading one page in order (default 1.0)
SHOW random_page_cost;     -- cost of reading one page at random (default 4.0)
SHOW cpu_tuple_cost;       -- cost of processing one row (default 0.01)

-- Size of each table and index, and estimated row counts (from pg_class)
SELECT c.relname,
       c.relkind,                                    -- r = table, i = index
       c.relpages                  AS pages_8kb,
       c.reltuples::bigint         AS estimated_rows,
       pg_size_pretty(pg_relation_size(c.oid)) AS size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind IN ('r', 'i')
ORDER BY pg_relation_size(c.oid) DESC
LIMIT 15;

-- Catalog statistical distribution learned by ANALYZE
SELECT attname, n_distinct, most_common_vals, correlation
FROM pg_stats
WHERE tablename = 'ledger_entries' AND attname IN ('account_id', 'direction');

-- ---------------------------------------------------------------------
-- Part B: Force the OLD Plan and Compare (Q1 Planner Decision)
-- Compares chosen Index Scan vs forced Sequential Scan on Q1
-- ---------------------------------------------------------------------
-- 1. As chosen by optimizer (Index Scan)
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.created_at, l.direction, l.amount, l.balance_after, t.txn_type
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE l.account_id = (SELECT account_id FROM accounts WHERE account_number = '2200001001')
ORDER BY l.created_at DESC
LIMIT 50;

-- 2. Forced Sequential Scan (switches off index paths)
SET enable_indexscan = off;
SET enable_bitmapscan = off;
SET enable_indexonlyscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT l.created_at, l.direction, l.amount, l.balance_after, t.txn_type
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE l.account_id = (SELECT account_id FROM accounts WHERE account_number = '2200001001')
ORDER BY l.created_at DESC
LIMIT 50;

RESET enable_indexscan;
RESET enable_bitmapscan;
RESET enable_indexonlyscan;

-- ---------------------------------------------------------------------
-- Part C: Selectivity & Cost Trade-Off on Q2 (~7% table selectivity)
-- Evaluates why a small partial covering index beats sequential scan
-- ---------------------------------------------------------------------
-- 1. Index-assisted execution
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('day', initiated_at) AS day, count(*), sum(amount)
FROM transactions
WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED'
  AND initiated_at >= now() - interval '30 days'
GROUP BY 1;

-- 2. Forced Sequential Scan
SET enable_indexscan = off;
SET enable_bitmapscan = off;
SET enable_indexonlyscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('day', initiated_at) AS day, count(*), sum(amount)
FROM transactions
WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED'
  AND initiated_at >= now() - interval '30 days'
GROUP BY 1;

RESET enable_indexscan;
RESET enable_bitmapscan;
RESET enable_indexonlyscan;

-- ---------------------------------------------------------------------
-- Part D: Selectivity Decides (The Selectivity Tipping Point)
-- Demonstrates that the optimizer uses an index for rare values (~1%)
-- but prefers a sequential scan for common values (~99%).
-- Leverages PostgreSQL transactional DDL (ROLLBACK leaves no artifacts).
-- ---------------------------------------------------------------------
BEGIN;

CREATE INDEX tmp_customers_status ON customers (status);
ANALYZE customers;

-- Rare predicate (~1% SUSPENDED) -> Optimizer chooses Bitmap Index Scan / Index Scan
EXPLAIN (ANALYZE) SELECT * FROM customers WHERE status = 'SUSPENDED';

-- Common predicate (~99% ACTIVE) -> Optimizer chooses Seq Scan (avoids random I/O)
EXPLAIN (ANALYZE) SELECT * FROM customers WHERE status = 'ACTIVE';

ROLLBACK;

ANALYZE customers;

