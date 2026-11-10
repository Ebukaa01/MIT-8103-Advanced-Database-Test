-- =====================================================================
-- Portfolio 2: the RESULTS of all nine queries (no EXPLAIN).
-- Fully compatible with pgAdmin Query Tool and psql CLI.
--
-- Invariants:
--   Q6 and Q7 must return 0 rows.
--   Q9: fan_out_total must be exactly 2 x correct_total.
-- =====================================================================

-- === Q1: account_statement ===
SELECT '=== Q1: account_statement ===' AS query_label;
SELECT l.created_at, l.direction, l.amount, l.balance_after,
       t.txn_type, t.reference
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE l.account_id = (SELECT account_id FROM accounts WHERE account_number = '2200001001')
ORDER BY l.created_at DESC
LIMIT 50;

-- === Q2: daily_transfer_totals ===
SELECT '=== Q2: daily_transfer_totals ===' AS query_label;
SELECT date_trunc('day', initiated_at) AS day,
       count(*)    AS transfers,
       sum(amount) AS total_amount
FROM transactions
WHERE txn_type = 'TRANSFER'
  AND status = 'COMPLETED'
  AND initiated_at >= now() - interval '30 days'
GROUP BY 1
ORDER BY 1;

-- === Q3: customer_largest_transfers ===
SELECT '=== Q3: customer_largest_transfers ===' AS query_label;
SELECT t.transaction_id, t.amount, t.initiated_at, t.reference
FROM accounts a
JOIN ledger_entries l ON l.account_id = a.account_id AND l.direction = 'DEBIT'
JOIN transactions t   ON t.transaction_id = l.transaction_id
WHERE a.customer_id = 1001
  AND t.txn_type = 'TRANSFER'
ORDER BY t.amount DESC
LIMIT 10;

-- === Q4: large_transfer_fraud ===
SELECT '=== Q4: large_transfer_fraud ===' AS query_label;
SELECT a.customer_id,
       count(*)      AS large_transfers,
       sum(l.amount) AS total_sent
FROM ledger_entries l
JOIN accounts a ON a.account_id = l.account_id
WHERE l.direction = 'DEBIT'
  AND l.amount >= 4000
  AND l.created_at >= now() - interval '90 days'
GROUP BY a.customer_id
ORDER BY large_transfers DESC, total_sent DESC
LIMIT 10;

-- === Q5: idempotency_lookup ===
SELECT '=== Q5: idempotency_lookup ===' AS query_label;
SELECT *
FROM transactions
WHERE idempotency_key = 'seed-xfer-12345';

-- === Q6: balance_reconciliation ===
SELECT '=== Q6: balance_reconciliation ===' AS query_label;
SELECT a.account_number,
       a.balance        AS cached_balance,
       l.balance_after  AS ledger_balance,
       a.balance - l.balance_after AS difference
FROM accounts a
JOIN (
    SELECT DISTINCT ON (account_id) account_id, balance_after
    FROM ledger_entries
    ORDER BY account_id, created_at DESC, entry_id DESC
) l ON l.account_id = a.account_id
WHERE a.balance <> l.balance_after;

-- === Q7: unbalanced_journals ===
SELECT '=== Q7: unbalanced_journals ===' AS query_label;
SELECT t.transaction_id,
       t.txn_type,
       t.amount,
       count(l.entry_id) AS entry_count,
       coalesce(sum(l.amount) FILTER (WHERE l.direction = 'DEBIT'), 0)  AS total_debits,
       coalesce(sum(l.amount) FILTER (WHERE l.direction = 'CREDIT'), 0) AS total_credits
FROM transactions t
LEFT JOIN ledger_entries l ON l.transaction_id = t.transaction_id
WHERE t.status IN ('COMPLETED', 'REVERSED')
GROUP BY t.transaction_id, t.txn_type, t.amount
HAVING count(l.entry_id) = 0
    OR coalesce(sum(l.amount) FILTER (WHERE l.direction = 'DEBIT'), 0)
    <> coalesce(sum(l.amount) FILTER (WHERE l.direction = 'CREDIT'), 0);

-- === Q8: net_movement_reversals ===
SELECT '=== Q8: net_movement_reversals ===' AS query_label;
SELECT count(*) FILTER (WHERE status = 'COMPLETED')    AS net_transfers,
       sum(amount) FILTER (WHERE status = 'COMPLETED') AS net_amount,
       count(*) FILTER (WHERE status = 'REVERSED')     AS reversed_transfers,
       sum(amount) FILTER (WHERE status = 'REVERSED')  AS reversed_amount,
       count(*) FILTER (WHERE status = 'FAILED')       AS failed_transfers
FROM transactions
WHERE txn_type = 'TRANSFER'
  AND initiated_at >= now() - interval '90 days';

-- === Q9: join_fanout_trap ===
SELECT '=== Q9: join_fanout_trap ===' AS query_label;
SELECT
    (SELECT sum(t.amount)
       FROM transactions t
       JOIN ledger_entries l ON l.transaction_id = t.transaction_id
      WHERE t.txn_type = 'TRANSFER' AND t.status = 'COMPLETED'
        AND t.initiated_at >= now() - interval '30 days') AS fan_out_total,
    (SELECT sum(t.amount)
       FROM transactions t
      WHERE t.txn_type = 'TRANSFER' AND t.status = 'COMPLETED'
        AND t.initiated_at >= now() - interval '30 days') AS correct_total;
