-- =====================================================================
-- Portfolio 2: Write-Cost Benchmark -- Index Overhead on INSERT
-- Measures the wall-clock and space cost of maintaining indexes during
-- bulk INSERT by comparing two temporary copies of ledger_entries:
--   1. le_no_index   -- plain table, no indexes
--   2. le_with_index -- same table structure + the two production indexes
--
-- How to run:
--   psql  : enable timing first with  \timing
--   pgAdmin: run time appears at the bottom of the Query Tool window
--
-- Safety:
--   - Uses TEMP tables; they are dropped at session end automatically.
--   - Does NOT touch any production table.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Step 1: Create the two temp tables
-- ---------------------------------------------------------------------

-- A copy of ledger_entries with NO indexes.
CREATE TEMP TABLE le_no_index (LIKE ledger_entries INCLUDING DEFAULTS);

-- A copy with the same two indexes we added to the real table.
CREATE TEMP TABLE le_with_index (LIKE ledger_entries INCLUDING DEFAULTS);

CREATE INDEX tmp_le_account_created ON le_with_index (account_id, created_at DESC);

CREATE INDEX tmp_le_large_debits    ON le_with_index (created_at)
    INCLUDE (account_id, amount) WHERE direction = 'DEBIT' AND amount >= 4000;

-- ---------------------------------------------------------------------
-- Step 2: Insert the same rows into each table.
--         Note the two "Time:" results reported by psql / pgAdmin.
--         The difference is the pure overhead of keeping indexes current.
-- ---------------------------------------------------------------------

INSERT INTO le_no_index   SELECT * FROM ledger_entries;
INSERT INTO le_with_index SELECT * FROM ledger_entries;

-- ---------------------------------------------------------------------
-- Step 3: Compare disk space consumed by each copy.
--         pg_total_relation_size includes table + all indexes + TOAST.
-- ---------------------------------------------------------------------
SELECT 'no indexes'   AS copy,
       pg_size_pretty(pg_total_relation_size('le_no_index'))   AS total_size
UNION ALL
SELECT 'with indexes',
       pg_size_pretty(pg_total_relation_size('le_with_index'));

-- ---------------------------------------------------------------------
-- Step 4: Clean up (TEMP tables also disappear at session end).
-- ---------------------------------------------------------------------
DROP TABLE le_no_index;
DROP TABLE le_with_index;
