\echo '====================================================================='
\echo 'PORTFOLIO 5: DECLARATIVE PARTITIONING & HORIZONTAL SHARDING SUITE'
\echo 'Case Study: EquityPay Financial Services Ltd.'
\echo '====================================================================='

BEGIN;

-- ---------------------------------------------------------------------
-- 1. Declarative RANGE Partitioning on Transactions (Time-Series Tiering)
-- ---------------------------------------------------------------------
\echo '--- 1. Creating Declarative RANGE Partitioned Table: transactions_partitioned ---'

DROP TABLE IF EXISTS transactions_partitioned CASCADE;

CREATE TABLE transactions_partitioned (
    transaction_id  BIGINT GENERATED ALWAYS AS IDENTITY,
    idempotency_key VARCHAR(64)   NOT NULL,
    txn_type        VARCHAR(20)   NOT NULL
                    CHECK (txn_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BILL_PAYMENT', 'REVERSAL')),
    status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
    amount          NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    reference       VARCHAR(100),
    reversal_of     BIGINT,
    initiated_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    PRIMARY KEY (transaction_id, initiated_at),
    UNIQUE (idempotency_key, initiated_at)
) PARTITION BY RANGE (initiated_at);

-- Partition 1: Historical Archive (2024)
CREATE TABLE transactions_2024 PARTITION OF transactions_partitioned
    FOR VALUES FROM ('2024-01-01 00:00:00+00') TO ('2025-01-01 00:00:00+00');

-- Partition 2: Previous Fiscal Year (2025)
CREATE TABLE transactions_2025 PARTITION OF transactions_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

-- Partition 3: Active Production Year (2026)
CREATE TABLE transactions_2026 PARTITION OF transactions_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

-- Partition 4: Default Catch-All Partition
CREATE TABLE transactions_default PARTITION OF transactions_partitioned DEFAULT;

-- Partitioned Indexes (Inherited automatically across all partition slices)
CREATE INDEX idx_txn_part_type_status ON transactions_partitioned (txn_type, status);
CREATE INDEX idx_txn_part_initiated_at ON transactions_partitioned (initiated_at);

-- Populate partitioned table from monolithic transactions table
INSERT INTO transactions_partitioned (
    transaction_id, idempotency_key, txn_type, status, amount, reference, reversal_of, initiated_at, completed_at
)
OVERRIDING SYSTEM VALUE
SELECT 
    transaction_id, idempotency_key, txn_type, status, amount, reference, reversal_of, initiated_at, completed_at
FROM transactions;

COMMIT;

-- Analyze to ensure optimizer statistics are refreshed
ANALYZE transactions_partitioned;

-- ---------------------------------------------------------------------
-- 2. Range Partition Storage & Distribution Metrics
-- ---------------------------------------------------------------------
\echo '--- 2. Partition Inventory, Row Distribution & Physical Disk Footprint ---'

SELECT 
    inhrelid::regclass AS partition_name,
    pg_get_expr(c.relpartbound, c.oid) AS partition_expression,
    reltuples::bigint AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_inherits
JOIN pg_class c ON c.oid = inhrelid
WHERE inhparent = 'transactions_partitioned'::regclass
ORDER BY partition_name;

-- Exact row count validation per partition slice
SELECT 'transactions_2024' AS partition_slice, count(*) AS actual_rows FROM transactions_2024
UNION ALL SELECT 'transactions_2025', count(*) FROM transactions_2025
UNION ALL SELECT 'transactions_2026', count(*) FROM transactions_2026
UNION ALL SELECT 'transactions_default', count(*) FROM transactions_default
UNION ALL SELECT 'TOTAL (transactions_partitioned)', count(*) FROM transactions_partitioned
ORDER BY actual_rows;

-- ---------------------------------------------------------------------
-- 3. Query Execution Plan: Empirical Partition Pruning Demonstration
-- ---------------------------------------------------------------------
\echo '--- 3A. Query Execution Plan: Single Partition Pruning (2025 Only) ---'
EXPLAIN (ANALYZE, COSTS OFF)
SELECT count(*), sum(amount)
FROM transactions_partitioned
WHERE initiated_at >= '2025-06-01 00:00:00+00' AND initiated_at < '2025-07-01 00:00:00+00';

\echo '--- 3B. Query Execution Plan: Single Partition Pruning (2026 Active Production) ---'
EXPLAIN (ANALYZE, COSTS OFF)
SELECT txn_type, count(*), sum(amount)
FROM transactions_partitioned
WHERE initiated_at >= '2026-03-01 00:00:00+00' AND initiated_at < '2026-04-01 00:00:00+00'
GROUP BY txn_type;

-- ---------------------------------------------------------------------
-- 4. Declarative LIST Partitioning: Geographic Regional Sharding
-- ---------------------------------------------------------------------
\echo '--- 4. Creating Declarative LIST Partitioned Table: regional_customers ---'

BEGIN;

DROP TABLE IF EXISTS regional_customers CASCADE;

CREATE TABLE regional_customers (
    customer_id   BIGINT GENERATED ALWAYS AS IDENTITY,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    customer_type VARCHAR(20)  NOT NULL,
    status        VARCHAR(20)  NOT NULL,
    region        VARCHAR(30)  NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, region),
    UNIQUE (email, region)
) PARTITION BY LIST (region);

-- Regional Node 1: Lagos Commercial Hub
CREATE TABLE customers_lagos PARTITION OF regional_customers
    FOR VALUES IN ('LAGOS');

-- Regional Node 2: Abuja Federal Capital Territory
CREATE TABLE customers_abuja PARTITION OF regional_customers
    FOR VALUES IN ('ABUJA');

-- Regional Node 3: Northern Regional Hub (Kano)
CREATE TABLE customers_kano PARTITION OF regional_customers
    FOR VALUES IN ('KANO');

-- Regional Node 4: South-South Oil & Gas Hub (Port Harcourt)
CREATE TABLE customers_ph PARTITION OF regional_customers
    FOR VALUES IN ('PORT_HARCOURT');

-- Regional Node 5: International / Diaspora Catch-All
CREATE TABLE customers_diaspora PARTITION OF regional_customers DEFAULT;

-- Populate regional customers deterministically
INSERT INTO regional_customers (
    customer_id, first_name, last_name, email, phone, customer_type, status, region, created_at
)
OVERRIDING SYSTEM VALUE
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.customer_type,
    c.status,
    CASE 
        WHEN c.customer_id % 5 = 0 THEN 'LAGOS'
        WHEN c.customer_id % 5 = 1 THEN 'ABUJA'
        WHEN c.customer_id % 5 = 2 THEN 'KANO'
        WHEN c.customer_id % 5 = 3 THEN 'PORT_HARCOURT'
        ELSE 'DIASPORA'
    END AS region,
    c.created_at
FROM customers c;

COMMIT;

ANALYZE regional_customers;

\echo '--- 5. Regional Customer Distribution Across Geographic Nodes ---'

SELECT 
    inhrelid::regclass AS regional_shard,
    pg_get_expr(c.relpartbound, c.oid) AS routing_rule,
    reltuples::bigint AS customer_count,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS shard_disk_size
FROM pg_inherits
JOIN pg_class c ON c.oid = inhrelid
WHERE inhparent = 'regional_customers'::regclass
ORDER BY regional_shard;

\echo '--- 6. Geographic Partition Pruning Demonstration (Lagos Shard Only) ---'
EXPLAIN (ANALYZE, COSTS OFF)
SELECT customer_id, first_name, last_name, email, status
FROM regional_customers
WHERE region = 'LAGOS' AND status = 'ACTIVE';

-- ---------------------------------------------------------------------
-- 7. Mathematical Parity Audit: Monolithic vs Partitioned Datasets
-- ---------------------------------------------------------------------
\echo '--- 7. Data Parity & Conservation Audit ---'

SELECT 
    'transactions (monolithic)' AS dataset,
    count(*) AS total_rows,
    sum(amount) AS total_volume
FROM transactions
UNION ALL
SELECT 
    'transactions_partitioned' AS dataset,
    count(*) AS total_rows,
    sum(amount) AS total_volume
FROM transactions_partitioned;

