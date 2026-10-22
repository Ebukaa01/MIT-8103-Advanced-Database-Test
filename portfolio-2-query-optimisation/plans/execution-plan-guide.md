# Execution Plan Capture Guide
## Portfolio 2 – Query Optimisation | MIT 8103 Advanced Databases

> **Objective**: Capture full `EXPLAIN (ANALYZE, BUFFERS)` plans for queries Q1–Q8  
> **Before**: no optimisation indexes exist  
> **After**: indexes from `03_create_indexes.sql` have been applied  
> Output files: `before.txt` and `after.txt` in this `plans/` directory

---

## Table of Contents

1. [Pre-flight Checks](#1-pre-flight-checks)
2. [Phase 1 – Capture BEFORE Plans](#2-phase-1--capture-before-plans)
3. [Phase 2 – Create Optimisation Indexes](#3-phase-2--create-optimisation-indexes)
4. [Phase 3 – Capture AFTER Plans](#4-phase-3--capture-after-plans)
5. [Phase 4 – Compare and Annotate](#5-phase-4--compare-and-annotate)
6. [Key Metrics Reference](#6-key-metrics-reference)
7. [Plan Node Glossary](#7-plan-node-glossary)
8. [Expected Before to After Changes Per Query](#8-expected-before-to-after-changes-per-query)

---

## 1. Pre-flight Checks

Run these checks **before starting** to verify the database is in a known clean state.

```sql
-- 1a. Confirm no optimisation indexes exist yet
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE indexname IN (
    'idx_ledger_account_created',
    'idx_accounts_customer',
    'idx_txn_completed_transfers_time',
    'idx_ledger_large_debits',
    'idx_txn_type_time_cover'
)
ORDER BY tablename;
-- Expected: 0 rows returned
```

```sql
-- 1b. Confirm statistics are fresh (auto-vacuum last ran recently)
SELECT relname, last_analyze, last_autoanalyze, n_live_tup
FROM pg_stat_user_tables
WHERE relname IN ('ledger_entries', 'transactions', 'accounts')
ORDER BY relname;
```

```sql
-- 1c. Record current planner cost settings for the write-up
SHOW seq_page_cost;        -- default 1.0
SHOW random_page_cost;     -- default 4.0
SHOW cpu_tuple_cost;       -- default 0.01
SHOW work_mem;
SHOW shared_buffers;
SELECT version();
```

> **Important**: If `1a` returns any rows, run `sql/04_drop_indexes.sql` first
> to return the database to the unindexed baseline before proceeding.

---

## 2. Phase 1 – Capture BEFORE Plans

### 2.1 Setup (psql CLI — recommended)

Open a terminal connected to `equity_db`:

```bash
psql -U postgres -d equity_db
```

Redirect all output to `before.txt`:

```psql
\o portfolio-2-query-optimisation/plans/before.txt
```

Now execute the full plan capture script:

```psql
\i portfolio-2-query-optimisation/sql/01_capture_plans.sql
```

Close the output file:

```psql
\o
```

### 2.2 Alternative — pgAdmin 4 Query Tool

1. Open **pgAdmin 4** and connect to `equity_db`
2. Open `sql/01_capture_plans.sql` in the Query Tool
3. Press **F5** to run all statements
4. Copy the entire **Messages** + **Data Output** pane content
5. Paste into `plans/before.txt` and save

> **Tip**: In pgAdmin, use **Shift+F7** to view the Visual Explain plan for
> individual queries — useful for annotating the report but not required here.

### 2.3 Confirm capture succeeded

```bash
# Should show a non-empty file with plan text
wc -l portfolio-2-query-optimisation/plans/before.txt
```

Expected minimum: **~250 lines** (8 query labels + 8 EXPLAIN outputs).

---

## 3. Phase 2 – Create Optimisation Indexes

Run the index creation script **only after** `before.txt` has been saved.

### 3.1 In psql

```psql
\i portfolio-2-query-optimisation/sql/03_create_indexes.sql
```

### 3.2 In pgAdmin

Open and run `sql/03_create_indexes.sql`. Verify the final `SELECT` at the
bottom of the script returns **5 rows** — one per index — with non-zero sizes:

| index_name                       | size  |
|----------------------------------|-------|
| idx_accounts_customer            | xx kB |
| idx_ledger_account_created       | xx kB |
| idx_ledger_large_debits          | xx kB |
| idx_txn_completed_transfers_time | xx kB |
| idx_txn_type_time_cover          | xx kB |

### 3.3 Post-index maintenance (critical)

Run the following two statements **separately** (not inside a multi-statement
block) to refresh the visibility map. Without this, Index Only Scans may still
report `Heap Fetches > 0`.

```sql
VACUUM (ANALYZE) transactions;
```

```sql
VACUUM (ANALYZE) ledger_entries;
```

> **Why this matters**: `VACUUM` sets the all-visible bits on heap pages.
> Once all pages are marked all-visible, PostgreSQL can satisfy an Index Only
> Scan without touching the heap, reducing `Heap Fetches` to 0.

---

## 4. Phase 3 – Capture AFTER Plans

### 4.1 In psql

```psql
\o portfolio-2-query-optimisation/plans/after.txt
\i portfolio-2-query-optimisation/sql/01_capture_plans.sql
\o
```

> **Use the identical script** (`01_capture_plans.sql`) as the BEFORE capture.
> This ensures every query is identical and differences are solely due to indexes.

### 4.2 Confirm capture succeeded

```bash
wc -l portfolio-2-query-optimisation/plans/after.txt
```

Expected minimum: **~250 lines**.

---

## 5. Phase 4 – Compare and Annotate

### 5.1 Side-by-side diff

```bash
# Quick diff of the two files
diff portfolio-2-query-optimisation/plans/before.txt \
     portfolio-2-query-optimisation/plans/after.txt
```

Or use a GUI diff tool:

```powershell
# Windows — opens VS Code diff
code --diff `
  "portfolio-2-query-optimisation/plans/before.txt" `
  "portfolio-2-query-optimisation/plans/after.txt"
```

### 5.2 Metrics to extract per query

For each query Q1–Q8, record the following from both files into `results.txt`:

| Metric                  | Where to find it in the plan                                           |
|-------------------------|------------------------------------------------------------------------|
| **Total cost**          | Top-level node: `cost=X..Y` — use the upper bound `Y`                 |
| **Actual time**         | Top-level node: `actual time=X..Y ms`                                 |
| **Rows returned**       | Top-level node: `rows=N`                                               |
| **Buffers shared hit**  | `Buffers: shared hit=N`                                                |
| **Buffers shared read** | `Buffers: shared read=N`                                               |
| **Planning time**       | Final line: `Planning Time: N ms`                                      |
| **Execution time**      | Final line: `Execution Time: N ms`                                     |
| **Scan node type**      | Bottom-most scan node (Seq Scan / Index Scan / Index Only Scan / Bitmap) |
| **Join strategy**       | Hash Join / Nested Loop / Merge Join                                   |

### 5.3 Populate results.txt

Use the following template for `results.txt`:

```
========================================================
 EXECUTION PLAN COMPARISON SUMMARY
 Portfolio 2 - Query Optimisation | MIT 8103
========================================================

Environment:
  PostgreSQL version :
  shared_buffers     :
  work_mem           :
  seq_page_cost      : 1.0
  random_page_cost   : 4.0
  Captured at        :

--------------------------------------------------------
Q1: account_statement
--------------------------------------------------------
BEFORE:
  Scan node       :
  Join strategy   :
  Total cost      :
  Execution time  : ms
  Buffers hit     :
  Buffers read    :

AFTER:
  Scan node       :
  Join strategy   :
  Total cost      :
  Execution time  : ms
  Buffers hit     :
  Buffers read    :

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q2: daily_transfer_totals
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q3: customer_largest_transfers
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q4: large_transfer_fraud
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q5: idempotency_lookup
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q6: balance_reconciliation
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q7: unbalanced_journals
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:

--------------------------------------------------------
Q8: net_movement_reversals
--------------------------------------------------------
BEFORE:
  Scan node       :
  Execution time  : ms

AFTER:
  Scan node       :
  Execution time  : ms

Speedup (exec time): X
Key change:
```

---

## 6. Key Metrics Reference

### Reading a Plan Node

```
-> Index Scan using idx_ledger_account_created on ledger_entries  (cost=0.43..12.10 rows=50 width=44)
   Index Cond: (account_id = $1)
   actual time=0.045..0.312 rows=50 loops=1
   Buffers: shared hit=8 read=0
```

| Field            | Meaning                                                                      |
|------------------|------------------------------------------------------------------------------|
| `cost=X..Y`      | Planner estimate: X = startup cost, Y = total cost (planner cost units)      |
| `rows=N`         | Planner row count estimate — compare with `actual rows` to spot bad estimates |
| `actual time=X..Y` | Wall-clock ms: X = first row, Y = last row                                |
| `loops=N`        | Node executed N times (multiply `actual time` by loops for true total)       |
| `shared hit=N`   | Pages served from PostgreSQL shared buffer cache (fast — no disk I/O)        |
| `shared read=N`  | Pages read from disk or OS page cache (slower than buffer hit)               |
| `Planning Time`  | Time PostgreSQL spent choosing the plan                                      |
| `Execution Time` | Total wall-clock time from start to last row                                 |

### Buffer Hit Ratio

```
hit_ratio = shared_hit / (shared_hit + shared_read)
```

A ratio above **95%** indicates the working set fits in `shared_buffers`.
Second runs of the same query typically show `read=0` due to the OS page cache.

---

## 7. Plan Node Glossary

| Node type              | When used                                                    | Index required?      |
|------------------------|--------------------------------------------------------------|----------------------|
| **Seq Scan**           | Full table scan; best when >~10% of rows qualify             | No                   |
| **Index Scan**         | Range or equality predicate on indexed column; low selectivity | Yes                |
| **Index Only Scan**    | All needed columns are in the index; no heap visit           | Yes (covering index) |
| **Bitmap Index Scan**  | Medium selectivity; batches heap access to reduce random I/O | Yes                  |
| **Bitmap Heap Scan**   | Reads heap pages flagged by Bitmap Index Scan                | Yes                  |
| **Nested Loop**        | Efficient when outer result set is small and inner has an index | Inner index helps |
| **Hash Join**          | Efficient for large equi-joins where one side fits in `work_mem` | No               |
| **Merge Join**         | Efficient when both sides are pre-sorted                     | Sort or index        |
| **Sort**               | Explicit sort node; disappears when an index provides order  | Yes (ordered index)  |
| **Aggregate**          | Groups or aggregates rows                                    | —                    |
| **Limit**              | Stops after N rows; enables early-exit optimisation          | —                    |

---

## 8. Expected Before to After Changes Per Query

The table below summarises what the planner is expected to do once the
five indexes from `03_create_indexes.sql` exist.

| Query | Index applied | Expected BEFORE node | Expected AFTER node | Why |
|---|---|---|---|---|
| **Q1** account_statement | `idx_ledger_account_created` (account_id, created_at DESC) | Seq Scan on ledger + Hash Join | Index Scan on ledger + Nested Loop | Composite index matches equality filter and ORDER BY; planner reads 50 rows in order and stops early |
| **Q2** daily_transfer_totals | `idx_txn_completed_transfers_time` (partial, INCLUDE amount) | Seq Scan on transactions | Index Only Scan | Partial index covers only TRANSFER/COMPLETED rows; INCLUDE(amount) makes it fully covering — no heap visit |
| **Q3** customer_largest_transfers | `idx_accounts_customer` + `idx_ledger_account_created` | Seq Scan on accounts + Seq Scan on ledger | Index Scan on accounts + Index Scan on ledger | FK column on accounts.customer_id was unindexed; ledger composite satisfies the direction filter |
| **Q4** large_transfer_fraud | `idx_ledger_large_debits` (partial, INCLUDE account_id, amount) | Seq Scan on ledger_entries | Bitmap Index Scan / Index Scan | Partial index covers only DEBIT >= 4000 rows (small fraction); INCLUDEd columns avoid heap fetch |
| **Q5** idempotency_lookup | Pre-existing unique index on `idempotency_key` | Index Scan (already fast) | Index Scan (unchanged) | Already optimal — no new index added |
| **Q6** balance_reconciliation | `idx_ledger_account_created` (covers DISTINCT ON order) | Explicit Sort node + Unique | Sort eliminated; Index Scan in order | Composite index supplies (account_id, created_at DESC) order that DISTINCT ON needs |
| **Q7** unbalanced_journals | No new index (full audit scan required) | Hash Join + Seq Scan | Hash Join + Seq Scan (unchanged) | All COMPLETED/REVERSED transactions must be checked; full scan is correct and expected |
| **Q8** net_movement_reversals | `idx_txn_type_time_cover` (txn_type, initiated_at INCLUDE status, amount) | Seq Scan on transactions | Index Only Scan | Covering index contains all four columns referenced; heap not visited |

---

## Checklist

- [ ] **1.** Pre-flight: confirmed 0 optimisation indexes exist (`pg_indexes` query)
- [ ] **2.** Captured `EXPLAIN (ANALYZE, BUFFERS)` output to `plans/before.txt`
- [ ] **3.** Verified `before.txt` is non-empty (at least 250 lines)
- [ ] **4.** Ran `sql/03_create_indexes.sql` — 5 indexes created and sizes verified
- [ ] **5.** Ran `VACUUM (ANALYZE) transactions` separately in pgAdmin/psql
- [ ] **6.** Ran `VACUUM (ANALYZE) ledger_entries` separately in pgAdmin/psql
- [ ] **7.** Captured `EXPLAIN (ANALYZE, BUFFERS)` output to `plans/after.txt`
- [ ] **8.** Verified `after.txt` is non-empty (at least 250 lines)
- [ ] **9.** Filled in `results.txt` with metrics from both files
- [ ] **10.** Noted scan-node type change per query in the comparison table
- [ ] **11.** Noted any queries where the plan did NOT change and explained why

---

*Generated for MIT 8103 Advanced Databases — Portfolio 2: Query Optimisation*
