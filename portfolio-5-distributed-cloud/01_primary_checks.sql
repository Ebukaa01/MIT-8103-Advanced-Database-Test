\echo '====================================================='
\echo 'EQUITYPAY DISTRIBUTED DATABASE: PRIMARY NODE AUDIT'
\echo '====================================================='

-- 1. Engine & Environment Identification
SELECT version();
SELECT current_database() AS database, current_user AS "user", inet_server_addr() AS server_ip, inet_server_port() AS server_port;

-- 2. Recovery / Standby Mode Check (Expected: f = Writable Primary)
SELECT pg_is_in_recovery() AS is_replica;

-- 3. WAL & Replication Configuration Parameters
SHOW wal_level;
SHOW hot_standby;
SHOW max_wal_senders;
SHOW max_replication_slots;

-- 4. Active Streaming Replication Connections
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    client_port,
    state,
    sync_state,
    sync_priority
FROM pg_stat_replication;

-- 5. Physical Replication Slots
SELECT 
    slot_name,
    plugin,
    slot_type,
    active,
    wal_status
FROM pg_replication_slots;

-- 6. Real-time Replication Lag Metrics
SELECT 
    application_name,
    client_addr,
    pg_current_wal_lsn() AS primary_current_wal_lsn,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replication_lag_bytes
FROM pg_stat_replication;

-- 7. Table Inventory & Row Counts
SELECT 'customers' AS table_name, count(*) AS row_count FROM customers
UNION ALL SELECT 'kyc_records', count(*) FROM kyc_records
UNION ALL SELECT 'accounts', count(*) FROM accounts
UNION ALL SELECT 'beneficiaries', count(*) FROM beneficiaries
UNION ALL SELECT 'cards', count(*) FROM cards
UNION ALL SELECT 'transactions', count(*) FROM transactions
UNION ALL SELECT 'ledger_entries', count(*) FROM ledger_entries
UNION ALL SELECT 'fraud_flags', count(*) FROM fraud_flags
ORDER BY table_name;

