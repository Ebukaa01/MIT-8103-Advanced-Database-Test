-- =====================================================================
-- EquityPay Financial Services Ltd. - PostgreSQL 18
-- Portfolio 3: Insufficient Funds Exception & Automatic Rollback Demo
--
-- How to run:
--   Option A (pgAdmin 4): Open this file and press F5.
--   Option B (psql CLI):
--     psql -U postgres -d EquityPay_db -f portfolio-3-transactions-concurrency/insufficient_funds.sql
--
-- Purpose:
--   Demonstrates ACID Atomicity (A) and Consistency (C). When an overdraft
--   is attempted, transfer_funds() throws an INSUFFICIENT_FUNDS exception.
--   PostgreSQL automatically rolls back the transaction, ensuring:
--     1. No money is deducted from the sender.
--     2. No money is credited to the receiver.
--     3. The initial PENDING transaction record is wiped out.
--     4. Zero ledger entries are written.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Step 1: Check Pre-Transfer Balances
-- ---------------------------------------------------------------------
SELECT '=== 1. Starting Balances Before Attempted Overdraft ===' AS demo_step;

SELECT account_number, balance, status 
FROM accounts
WHERE account_number IN ('9000000001', '9000000002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Step 2: Attempt Transfer Exceeding Available Balance
-- Alice has < 500.00, but we attempt to transfer 1,000,000.00
-- ---------------------------------------------------------------------
SELECT '=== 2. Attempting Overdraft of 1,000,000.00 ===' AS demo_step;

DO $$
DECLARE
    v_key VARCHAR := 'demo-insufficient-funds-' || substr(gen_random_uuid()::text, 1, 8);
BEGIN
    RAISE NOTICE 'Attempting to transfer 1,000,000.00 from Alice (9000000001) to Bob (9000000002)...';
    PERFORM transfer_funds('9000000001', '9000000002', 1000000.00, v_key);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '>>> CAUGHT EXPECTED ERROR: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
    RAISE NOTICE '>>> Transaction aborted and rolled back automatically by PostgreSQL.';
END $$;


-- ---------------------------------------------------------------------
-- Step 3: Verify Balances Remain Completely Unchanged
-- ---------------------------------------------------------------------
SELECT '=== 3. Post-Failure Balance Verification ===' AS demo_step;

SELECT account_number, balance 
FROM accounts
WHERE account_number IN ('9000000001', '9000000002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Step 4: Verify Zero Orphaned Transaction Records
-- ---------------------------------------------------------------------
SELECT '=== 4. Transaction Audit (Expected: 0 stuck pending rows) ===' AS demo_step;

SELECT count(*) AS stuck_pending_transactions
FROM transactions
WHERE status = 'PENDING';


-- ---------------------------------------------------------------------
-- Step 5: Direct Trigger (Uncaught Exception)
-- Uncomment the line below to view the raw interactive error in psql/pgAdmin:
-- ---------------------------------------------------------------------
-- SELECT transfer_funds('9000000001', '9000000002', 1000000.00, 'raw-error-demo');
