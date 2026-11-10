\echo '====================================================='
\echo 'EQUITYPAY DISTRIBUTED DATABASE: READ REPLICA AUDIT'
\echo '====================================================='

-- 1. Engine & Environment Identification
SELECT version();
SELECT current_database() AS database, current_user AS "user", inet_server_addr() AS server_ip, inet_server_port() AS server_port;

-- 2. Recovery / Standby Mode Check (Expected: t = Read-Only Standby)
SELECT pg_is_in_recovery() AS is_replica;

-- 3. WAL Receiver Status (Standby link to Primary)
SELECT 
    status,
    sender_host,
    sender_port,
    slot_name,
    latest_end_lsn,
    last_msg_send_time,
    last_msg_receipt_time
FROM pg_stat_wal_receiver;

-- 4. Table Inventory & Row Counts (Should match Primary identically)
SELECT 'customers' AS table_name, count(*) AS row_count FROM customers
UNION ALL SELECT 'kyc_records', count(*) FROM kyc_records
UNION ALL SELECT 'accounts', count(*) FROM accounts
UNION ALL SELECT 'beneficiaries', count(*) FROM beneficiaries
UNION ALL SELECT 'cards', count(*) FROM cards
UNION ALL SELECT 'transactions', count(*) FROM transactions
UNION ALL SELECT 'ledger_entries', count(*) FROM ledger_entries
UNION ALL SELECT 'fraud_flags', count(*) FROM fraud_flags
ORDER BY table_name;

-- 5. Double-Entry Parity Audit on Replica (Expected: 0)
SELECT count(*) AS unbalanced_transactions
FROM (
   SELECT transaction_id
   FROM ledger_entries
   GROUP BY transaction_id
   HAVING SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE -amount END) <> 0
) x;

-- 6. Read-Only Transaction Enforcement Proof
-- Standby replica must strictly reject any DML/DDL write operations
\echo '--- Testing Read-Only Enforcement (Expected Error) ---'
UPDATE customers SET status = 'ACTIVE' WHERE customer_id = 1;

