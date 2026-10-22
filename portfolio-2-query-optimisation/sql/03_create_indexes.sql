-- =====================================================================
-- Portfolio 2: indexes chosen from the execution plans in 01_capture_plans.sql
-- Run on equity_db AFTER you have saved the "before" plans (before.txt).
-- Safe to re-run (each index is dropped first).
-- =====================================================================

-- Q1 and Q3: find one account's ledger lines in time order.
-- Composite index: equality column first (account_id), then the sort column.
-- The planner can read the newest entries directly and stop after 50.
DROP INDEX IF EXISTS idx_ledger_account_created;
CREATE INDEX idx_ledger_account_created
    ON ledger_entries (account_id, created_at DESC);

-- Q3: find all accounts that belong to one customer.
-- PostgreSQL does NOT automatically index foreign-key columns.
DROP INDEX IF EXISTS idx_accounts_customer;
CREATE INDEX idx_accounts_customer
    ON accounts (customer_id);

-- Q2: recent completed transfers.
-- Partial index: only completed transfers are indexed, so it is small.
-- INCLUDE (amount) stores the summed column in the index so the table
-- may not need to be visited at all.
DROP INDEX IF EXISTS idx_txn_completed_transfers_time;
CREATE INDEX idx_txn_completed_transfers_time
    ON transactions (initiated_at) INCLUDE (amount)
    WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED';

-- Q4: large outgoing transfers by date.
-- Partial index: only DEBIT lines of 4,000 NGN or more, which is a small
-- fraction of the table. INCLUDE avoids visiting the table for the join
-- column and the summed amount.
DROP INDEX IF EXISTS idx_ledger_large_debits;
CREATE INDEX idx_ledger_large_debits
    ON ledger_entries (created_at) INCLUDE (account_id, amount)
    WHERE direction = 'DEBIT' AND amount >= 4000;

-- Q8: net movement over the last 90 days (all statuses of one type).
-- The partial index above only holds COMPLETED rows, so Q8 cannot use it:
-- a partial index is used only when the query's WHERE clause implies the
-- index's WHERE clause. A covering index on (txn_type, initiated_at) that
-- INCLUDEs status and amount lets the planner answer Q8 from the index alone.
DROP INDEX IF EXISTS idx_txn_type_time_cover;
CREATE INDEX idx_txn_type_time_cover
    ON transactions (txn_type, initiated_at) INCLUDE (status, amount);

-- Refresh statistics so the planner knows about the new indexes.
ANALYZE;

-- Index sizes, for the write-up (indexes speed up reads but cost disk
-- space and slow down inserts).
SELECT indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_ledger_account_created', 'idx_accounts_customer',
                       'idx_txn_completed_transfers_time', 'idx_ledger_large_debits',
                       'idx_txn_type_time_cover')
ORDER BY indexrelname;

-- =====================================================================
-- POST-INDEXING MAINTENANCE:
-- Run these two statements separately in pgAdmin (one by one, outside a multi-statement block):
--   VACUUM (ANALYZE) transactions;
--   VACUUM (ANALYZE) ledger_entries;
-- Rationale: VACUUM refreshes the visibility map (all-visible bits).
-- Without it, an Index Only Scan must still visit the heap (Heap Fetches > 0).
-- Once pages are marked all-visible, Heap Fetches drops to 0.
-- =====================================================================
