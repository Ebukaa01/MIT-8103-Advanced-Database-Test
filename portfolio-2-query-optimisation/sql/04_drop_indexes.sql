-- =====================================================================
-- Portfolio 2: remove the Portfolio 2 indexes to return to the baseline.
-- (Indexes created by PRIMARY KEY and UNIQUE constraints are not touched.)
-- Safe to re-run anytime.
-- =====================================================================

DROP INDEX IF EXISTS idx_ledger_account_created;
DROP INDEX IF EXISTS idx_accounts_customer;
DROP INDEX IF EXISTS idx_txn_completed_transfers_time;
DROP INDEX IF EXISTS idx_ledger_large_debits;
DROP INDEX IF EXISTS idx_txn_type_time_cover;

-- Refresh catalog statistics after index teardown
ANALYZE;
