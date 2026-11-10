-- =====================================================================
-- Portfolio 3: COMMIT, ROLLBACK, failure and idempotency demos
-- Fully compatible with BOTH pgAdmin 4 Query Tool and psql CLI.
--
-- How to run:
--   Option A (pgAdmin 4): Open this file and press F5 (or run blocks).
--   Option B (psql CLI):
--     & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d EquityPay_db -a -f portfolio-3-transactions-concurrency/03_commit_rollback_demo.sql -o portfolio-3-transactions-concurrency/output/03_commit_rollback_output.txt
--
-- Requires: 01_transfer_function.sql already executed on the database.
-- Accounts used: Seeded accounts 2200001001 and 2200001002.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Baseline: Starting Balances
-- ---------------------------------------------------------------------
SELECT '=== Starting balances' AS demo_step;

SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Demo 1: COMMIT. Transfer 100.00 and persist permanently.
-- ---------------------------------------------------------------------
SELECT '=== Demo 1: COMMIT. Transfer 100.00 and keep it' AS demo_step;

BEGIN;

SELECT transfer_funds('2200001001', '2200001002', 100.00, 'demo-commit-' || substr(gen_random_uuid()::text, 1, 8)) AS transaction_id;

SELECT '--- inside transaction (uncommitted, visible only to this session)' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;

COMMIT;

SELECT '--- after COMMIT (permanent on disk)' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Demo 2: ROLLBACK. Transfer 100.00, then abort the transaction.
-- ---------------------------------------------------------------------
SELECT '=== Demo 2: ROLLBACK. Transfer 100.00, then undo changes' AS demo_step;

BEGIN;

SELECT transfer_funds('2200001001', '2200001002', 100.00, 'demo-rollback-test-key') AS transaction_id;

SELECT '--- inside transaction (money has moved in transaction buffer)' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;

ROLLBACK;

SELECT '--- after ROLLBACK (balances restored to pre-transaction state)' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;

SELECT '--- verify zero trace of aborted transaction remains in transactions table' AS audit_check;
SELECT count(*) AS rows_for_rolled_back_key
FROM transactions
WHERE idempotency_key = 'demo-rollback-test-key';


-- ---------------------------------------------------------------------
-- Demo 3: Automatic Rollback on Failure (Insufficient Funds).
-- ---------------------------------------------------------------------
SELECT '=== Demo 3: Automatic rollback on failure (insufficient funds)' AS demo_step;

DO $$
BEGIN
    PERFORM transfer_funds('2200001001', '2200001002', 999999999.00, 'demo-insufficient-funds-key');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Caught expected exception: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END $$;

SELECT '--- balances remain completely unchanged after error' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;

SELECT count(*) AS rows_for_failed_key
FROM transactions
WHERE idempotency_key = 'demo-insufficient-funds-key';


-- ---------------------------------------------------------------------
-- Demo 4: Idempotency. Repeated API requests produce exactly one transfer.
-- ---------------------------------------------------------------------
SELECT '=== Demo 4: Idempotency. Same request sent twice is applied only once' AS demo_step;

-- 1st call: executes and moves money
SELECT transfer_funds('2200001001', '2200001002', 25.00, 'demo-idem-key-stable') AS first_call_txn_id;

-- 2nd call (retry with identical key): returns existing transaction_id, moves NO money
SELECT transfer_funds('2200001001', '2200001002', 25.00, 'demo-idem-key-stable') AS retry_call_txn_id;

SELECT count(*) AS transactions_with_this_key
FROM transactions
WHERE idempotency_key = 'demo-idem-key-stable';

SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Demo 5: SAVEPOINT. Partial rollback of a failed step without losing prior work.
-- ---------------------------------------------------------------------
SELECT '=== Demo 5: SAVEPOINT. Undo failed secondary transfer while keeping first' AS demo_step;

BEGIN;

-- Valid transfer of 10.00
SELECT transfer_funds('2200001001', '2200001002', 10.00, 'demo-sp-valid-' || substr(gen_random_uuid()::text, 1, 8)) AS first_transfer_id;

SAVEPOINT before_second_transfer;

-- Attempting an invalid transfer inside sub-transaction block
DO $$
BEGIN
    PERFORM transfer_funds('2200001001', '2200001002', 999999999.00, 'demo-sp-failing-step');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Step 2 failed as expected: %', SQLERRM;
END $$;

-- Roll back to savepoint to ensure clean state
ROLLBACK TO SAVEPOINT before_second_transfer;

SELECT '--- first transfer of 10.00 is still active and protected in transaction' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;

COMMIT;

SELECT '--- after COMMIT: first transfer permanently applied' AS state;
SELECT account_number, balance FROM accounts
WHERE account_number IN ('2200001001', '2200001002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Verification: Double-Entry Audit Trail
-- ---------------------------------------------------------------------
SELECT '=== Double-entry audit trail: latest ledger entries for demo wallets' AS demo_step;

SELECT l.transaction_id, a.account_number, l.direction, l.amount, l.balance_after, l.created_at
FROM ledger_entries l
JOIN accounts a ON a.account_id = l.account_id
WHERE a.account_number IN ('2200001001', '2200001002')
ORDER BY l.created_at DESC, l.entry_id DESC
LIMIT 8;
