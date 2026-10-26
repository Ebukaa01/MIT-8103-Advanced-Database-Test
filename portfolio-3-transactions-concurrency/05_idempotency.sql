-- =====================================================================
-- EquityPay Financial Services Ltd. - PostgreSQL 18
-- Portfolio 3: Network Idempotency & Duplicate Billing Prevention Demo
-- Fully compatible with BOTH pgAdmin 4 Query Tool and psql CLI.
--
-- How to run:
--   Option A (pgAdmin 4): Open this file and press F5.
--   Option B (psql CLI):
--     psql -U postgres -d EquityPay_db -f portfolio-3-transactions-concurrency/idempotency.sql
--
-- Purpose:
--   Demonstrates network idempotency. In mobile banking and payment gateways,
--   network timeouts often cause clients to retry a payment request.
--   transfer_funds() enforces unique idempotency keys:
--     1. The first call executes the transfer and moves money.
--     2. Retried calls with the same key detect the existing transaction,
--        return the existing transaction_id, and move NO additional money.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Step 1: Clean Reset for Demo Idempotency Key (Safe to Re-Run)
-- ---------------------------------------------------------------------
DELETE FROM ledger_entries 
WHERE transaction_id IN (
    SELECT transaction_id FROM transactions WHERE idempotency_key = 'demo-idempotent-payment-key'
);
DELETE FROM transactions WHERE idempotency_key = 'demo-idempotent-payment-key';


-- ---------------------------------------------------------------------
-- Step 2: Pre-State Balances
-- ---------------------------------------------------------------------
SELECT '=== 1. Starting Balances Before Idempotent Transfer ===' AS demo_step;

SELECT account_number, balance 
FROM accounts
WHERE account_number IN ('9000000001', '9000000002')
ORDER BY account_number;


-- ---------------------------------------------------------------------
-- Step 3: First API Call (Executes Transfer of 25.00)
-- ---------------------------------------------------------------------
SELECT '=== 2. First Call: Executes Transfer and Generates Transaction ID ===' AS demo_step;

SELECT transfer_funds(
    '9000000001', 
    '9000000002', 
    25.00, 
    'demo-idempotent-payment-key', 
    'Payment for invoice #1042'
) AS first_call_txn_id;


-- ---------------------------------------------------------------------
-- Step 4: Second API Call (Simulated Network Retry with Identical Key)
-- ---------------------------------------------------------------------
SELECT '=== 3. Second Call (Network Retry): Must Return Same ID Without Moving Money ===' AS demo_step;

SELECT transfer_funds(
    '9000000001', 
    '9000000002', 
    25.00, 
    'demo-idempotent-payment-key', 
    'Payment for invoice #1042'
) AS retry_call_txn_id;


-- ---------------------------------------------------------------------
-- Step 5: Verification of Idempotency Invariants
-- ---------------------------------------------------------------------
SELECT '=== 4. Idempotency Invariant Verification ===' AS demo_step;

-- Invariant A: Exactly ONE row in transactions table (no duplicate charges)
SELECT count(*) AS total_transactions_with_this_key,
       CASE WHEN count(*) = 1 THEN 'PASSED: No duplicate billing' ELSE 'FAILED: Duplicated!' END AS status
FROM transactions
WHERE idempotency_key = 'demo-idempotent-payment-key';

-- Invariant B: Exactly TWO ledger entries (1 DEBIT, 1 CREDIT)
SELECT l.direction, l.amount, l.balance_after, l.created_at
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE t.idempotency_key = 'demo-idempotent-payment-key'
ORDER BY l.direction DESC;

-- Invariant C: Ending balances (Alice debited exactly 25.00 once, Bob credited 25.00 once)
SELECT account_number, balance 
FROM accounts
WHERE account_number IN ('9000000001', '9000000002')
ORDER BY account_number;
