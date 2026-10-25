# MIT 8103: Advanced Database Systems
## Portfolio 3: Transactions, Concurrency Control & ACID Guarantees
### Technical Analysis & Empirical Report

**Author / Candidate**: Ebuka  
**Case Study**: EquityPay Financial Services Ltd.  
**Database**: `EquityPay_db` on PostgreSQL 18  

---

## 1. Environment Specification

All empirical tests, concurrency experiments, and high-contention benchmarks were executed in the following local hardware and database runtime environment:

- **Database Engine**: PostgreSQL 18.6 on `x86_64-windows`, compiled by Visual C++ (`msvc-19.44.35229`), 64-bit.
- **Host Workstation**: 
  - **Operating System**: Microsoft Windows 11 Enterprise (64-bit), Build 22631.
  - **Processor**: 13th Gen Intel(R) Core(TM) i5-1345U (10 physical cores / 12 logical execution threads, base clock 1.6 GHz up to 4.7 GHz Turbo).
  - **System Memory**: 16 GB DDR5 RAM (16,125,592 KB visible).
  - **Storage Subsystem**: NVMe M.2 Solid State Drive (PCIe 4.0 x4).
- **Default Transaction Isolation Level**: `READ COMMITTED` (`SHOW default_transaction_isolation;`).
- **Target Database Scale (`EquityPay_db`)**:
  - `customers`: **5,003** rows
  - `accounts`: **6,003** rows (including settlement account `1000000000` and demo wallets)
  - `transactions`: **210,039** rows
  - `ledger_entries`: **412,048** rows (immutable double-entry journal)
  - `beneficiaries`: **15,000** rows
  - `cards`: **2,993** rows
  - `fraud_flags`: **468** rows
  - `kyc_records`: **5,100** rows

---

## 2. The Transfer Function (`transfer_funds`)

The core banking engine implements the stored procedure `transfer_funds(p_from_account, p_to_account, p_amount, p_key, p_reference)` inside [01_transfer_function.sql](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-3-transactions-concurrency/01_transfer_function.sql). The function moves money as a single atomic unit through five strictly ordered phases.

### Phase 1: Input Validation & Idempotency Registration
- **What it does**: Validates that transfer amounts are strictly positive ($> 0$) and sender $\ne$ recipient. It immediately attempts an `INSERT` into the `transactions` table in `PENDING` state using `ON CONFLICT (idempotency_key) DO NOTHING`. If a conflict occurs, it retrieves the existing `transaction_id` and exits early without moving money.
- **Why order matters**: Registering the idempotency key *first* creates a transactional gate. If an identical network packet arrives concurrently from a timed-out mobile retry, it cannot bypass the duplicate check.
- **ACID Property Protected**: **Atomicity & Consistency** (prevents double-billing and ensures valid input boundaries).

### Phase 2: Global Resource Ordering & Deterministic Row Locking
- **What it does**: Computes canonical ordering between the two accounts using `v_first_id := LEAST(v_from_id, v_to_id)` and `v_second_id := GREATEST(v_from_id, v_to_id)`. It executes `SELECT 1 FROM accounts WHERE account_id = v_first_id FOR UPDATE`, followed by `v_second_id FOR UPDATE`.
- **Why order matters**: If locks were acquired in application order (sender first, receiver second), cross-transfers (A $\rightarrow$ B and B $\rightarrow$ A) would acquire locks in opposite order, creating circular lock dependencies and deadlocks. Strictly ascending primary key locking makes cyclic dependency graphs mathematically impossible.
- **ACID Property Protected**: **Isolation** (guarantees serializable row access and prevents concurrent writes from interleaving).

### Phase 3: Post-Lock Balance Validation
- **What it does**: Re-reads the sender's current balance *after* the exclusive row lock is held (`SELECT balance INTO v_from_bal FROM accounts WHERE account_id = v_from_id`), verifying that $v\_from\_bal \ge p\_amount$. If insufficient, it throws `RAISE EXCEPTION 'INSUFFICIENT_FUNDS'`.
- **Why order matters**: Reading balances *before* acquiring locks causes Time-of-Check/Time-of-Use (TOCTOU) race conditions, where a concurrent withdrawal could drain the balance after it was checked. Validation must occur strictly inside the lock perimeter.
- **ACID Property Protected**: **Consistency** (enforces the invariant that account balances never drop below zero, preventing unauthorized overdrafts).

### Phase 4: Atomic Balance Mutation & Double-Entry Journaling
- **What it does**: Debits the sender (`balance = balance - amount`) and credits the receiver (`balance = balance + amount`). It immediately inserts two immutable rows into `ledger_entries` (one `DEBIT`, one `CREDIT`) carrying the transaction ID, recorded amount, resulting balance, and `clock_timestamp()`.
- **Why order matters**: Balances and ledger lines must be updated simultaneously within the same transactional scope so that ledger history never diverges from account balances. Using `clock_timestamp()` instead of `now()` ensures real physical serialization of journal entries under concurrent execution.
- **ACID Property Protected**: **Atomicity, Consistency & Durability** (money is conserved; sum of debits equals sum of credits to four decimal places).

### Phase 5: Transaction Status Finalization
- **What it does**: Updates the parent transaction record in `transactions` from `PENDING` to `COMPLETED` and stamps `completed_at = clock_timestamp()`, then returns `v_txn_id`.
- **Why order matters**: Changing status to `COMPLETED` is the final seal on the transaction unit. If any error had occurred in steps 1 to 4, the entire transaction would roll back, leaving zero pending or orphaned rows.
- **ACID Property Protected**: **Atomicity & Durability** (guarantees state consistency and auditability).

---

## 3. Commit and Rollback Verification (Demos 1 to 5)

The empirical validation in [03_commit_rollback_output.txt](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-3-transactions-concurrency/output/03_commit_rollback_output.txt) confirms transactional boundary behavior across five distinct banking scenarios:

### Demo 1: Explicit COMMIT
Transferred 100.00 from Account `2200001001` to `2200001002` (Transaction ID `206104`). Inside the transaction block, the sender balance dropped from `1003223.2700` to `1003123.2700`, visible only to the active session. Upon `COMMIT`, changes were flushed to disk:
> *"--- after COMMIT (permanent on disk)"*  
> `2200001001 | 1003123.2700`  
> `2200001002 | 1026072.1600`

### Demo 2: Explicit ROLLBACK
Transferred 100.00 under Transaction ID `206105`. The transfer was applied to the transaction buffer, and then an explicit `ROLLBACK` was issued. Balances were immediately restored to their pre-transaction values:
> *"--- after ROLLBACK (balances restored to pre-transaction state)"*  
> `2200001001 | 1003123.2700`  
> `2200001002 | 1026072.1600`  
> *"--- verify zero trace of aborted transaction remains in transactions table"*  
> `rows_for_rolled_back_key | 0`

### Demo 3: Automatic Rollback on Exception
Attempted a 999,999,999.00 transfer exceeding available funds. PL/pgSQL triggered an unhandled exception (`INSUFFICIENT_FUNDS`). PostgreSQL automatically aborted the entire transaction block:
> *"--- balances remain completely unchanged after error"*  
> `rows_for_failed_key | 0`

### Demo 4: Network Idempotency
Submitted two identical fund transfer calls using idempotency key `'demo-idempotent-seed-key'`:
> `first_call_txn_id | 206100`  
> `retry_call_txn_id | 206100`  
> `transactions_with_this_key | 1`  
The second call recognized the existing key, returned the original transaction ID, and prevented duplicate debiting.

### Demo 5: SAVEPOINT Partial Rollback
Executed a valid 10.00 transfer (Txn `206109`), established `SAVEPOINT transfer_one_ok;`, and then attempted an invalid secondary transfer. The exception was caught, and `ROLLBACK TO SAVEPOINT` was executed:
> *"--- first transfer of 10.00 is still active and protected in transaction"*  
> `2200001001 | 1003113.2700`  
> `2200001002 | 1026082.1600`  
After `COMMIT`, the first transfer remained permanently applied, while the failed secondary transfer left no trace.

---

## 4. Concurrency Experiments (Experiments 1 to 4)

### Experiment 1: The Lost Update Anomaly
- **The Problem**: Two concurrent sessions read Alice's balance (500.00). Both intend to withdraw 100.00. Each computes `500 - 100 = 400` in application memory and writes `UPDATE accounts SET balance = 400`.
- **What Was Seen on Screen**: Terminal A committed `balance = 400`. Terminal B unblocked and also committed `balance = 400`. The final balance was **400.00** despite **200.00** total cash being withdrawn ($500 - 100 - 100 = 300$). Terminal A's deduction was overwritten and destroyed.
- **The Fix**: 
  1. Atomic relative DML: `UPDATE accounts SET balance = balance - 100 WHERE account_number = ...;`
  2. Pessimistic row locking: `SELECT balance FROM accounts WHERE ... FOR UPDATE;` to serialize the read-modify-write cycle.

### Experiment 2: Non-Repeatable Read (Fuzzy Read)
- **The Problem**: In default `READ COMMITTED`, every SQL query takes a new MVCC snapshot. Terminal A queries Alice's balance twice within the same open transaction while Terminal B commits an update in between.
- **What Was Seen on Screen**: Terminal A queried Alice and received `500.00`. Terminal B executed `UPDATE accounts SET balance = 200` and committed. Terminal A ran the identical query again inside its original transaction and received `200.00`. The balance changed non-deterministically mid-transaction.
- **The Fix**: Switch to `REPEATABLE READ` (`BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;`). PostgreSQL pins the snapshot to transaction start time; Terminal A's second query continues to return `500.00`.

### Experiment 3: Serialization Failure (`40001`)
- **The Problem**: Under `REPEATABLE READ`, transactions cannot overwrite data that was modified after their snapshot was taken.
- **What Was Seen on Screen**: Terminal A started in `REPEATABLE READ` and read Alice's balance (500.00). Terminal B updated Alice to 400.00 and committed. Terminal A then executed `UPDATE accounts SET balance = balance - 50`. PostgreSQL immediately aborted Terminal A:
  ```text
  ERROR: could not serialize access due to concurrent update
  SQLSTATE: 40001
  ```
- **The Fix**: Client application retry framework. When catching SQLSTATE `40001`, the client must re-run the entire transaction block with exponential backoff and jitter.

### Experiment 4: Deadlock (`40P01`)
- **The Problem**: Terminal A executed Alice $\rightarrow$ Bob (locks Alice, waits for Bob). Simultaneously, Terminal B executed Bob $\rightarrow$ Alice (locks Bob, waits for Alice). Both sessions held one lock while waiting for the other.
- **What Was Seen on Screen**: Both terminals froze completely. After exactly 1,000ms (`deadlock_timeout`), PostgreSQL's deadlock detector detected the cycle and aborted Terminal B:
  ```text
  ERROR: deadlock detected
  DETAIL: Process 23916 waits for ExclusiveLock on tuple ... blocked by process 21376.
  HINT: See server log for query details.
  SQLSTATE: 40P01
  ```
- **The Fix**: Canonical Global Resource Ordering (`transfer_funds()`). Sorting target account IDs via `LEAST()` and `GREATEST()` forces both sessions to acquire locks in identical primary key order, mathematically preventing circular waits.

---

## 5. Stress Benchmark Analysis & Financial Invariant Audit

To evaluate concurrency under extreme contention, `pgbench` was executed across 20 hot accounts with **10 concurrent clients** attempting **200 transfers each** (2,000 intended transactions per run):

### 5.1 Benchmark Comparison Table

| Metric | Safe Ordered Locking (`05_stress_ordered.pgbench`) | Flawed Unordered Locking (`06_stress_unordered.pgbench`) | Performance Variance |
| :--- | :---: | :---: | :---: |
| **Algorithm** | Canonical Ordering (`LEAST` / `GREATEST`) | Directional Locking (Sender then Receiver) | -- |
| **Transactions Attempted** | 2,000 | 2,000 | Baseline |
| **Transactions Completed** | **2,000 / 2,000 (100.0%)** | **1,938 / 2,000 (96.9%)** | -62 failed transfers |
| **Deadlock Failures (`40P01`)** | **0 (0.000%)** | **62 (3.100%)** | $\infty$ reduction |
| **Throughput (TPS)** | **732.98 TPS** | **46.30 TPS** | **-93.7% throughput collapse** |
| **Average Latency** | **13.64 ms** | **209.28 ms** | **15.3x latency inflation** |

### 5.2 Financial Invariant Audit (`07_integrity_check.sql`)

The 5-part verification suite was executed across all three operational milestones:

| Audit Invariant | Baseline (Pre-Stress) | Post-Ordered Stress | Post-Unordered Stress | Integrity Status |
| :--- | :---: | :---: | :---: | :---: |
| `total_money_in_system` | ₦1,000,000,000,000.0000 | ₦1,000,000,000,000.0000 | ₦1,000,000,000,000.0000 | **CONSERVED** |
| `stress_ledger_lines` | 0 | 4,000 ($2 \times 2000$) | 7,876 ($2 \times 3938$) | **PERFECT 2:1 RATIO** |
| `unbalanced_transactions` | 0 | 0 | 0 | **ZERO DISCREPANCY** |
| `mismatched_accounts` | 0 | 0 | 0 | **RECONCILED** |
| `stuck_pending_transactions`| 0 | 0 | 0 | **CLEAN** |

### Why the Ledger Stayed Intact Even in the Failing Run
Although 62 transactions aborted in the unordered run, not a single penny was lost. This highlights the absolute power of **ACID Atomicity (`A`)**:
- When PostgreSQL encounters a deadlock (`40P01`), it immediately issues an internal `ABORT TRANSACTION`.
- Every memory buffer change—the partial balance update, the `transactions` entry, and any ledger lines—is instantly discarded via the write-ahead log (WAL) rollback mechanics.
- Because transactions are all-or-nothing, partial money movement cannot commit to disk.

---

## 6. Step 8 Original Experiment: Lock Timeout Fail-Fast Architecture

In high-volume fintech gateways, unbounded lock waits cause thread pool exhaustion, cascade timeouts to upstream API gateways, and degrade entire microservice clusters. 

### Experiment Design
We tested PostgreSQL's `lock_timeout` parameter to implement a fail-fast pattern instead of allowing client connections to hang indefinitely.

```sql
-- Terminal A: Holds Alice's lock without committing
BEGIN;
UPDATE accounts SET balance = balance - 10 WHERE account_number = '9000000001';

-- Terminal B: Configures strict lock timeout and attempts transfer
BEGIN;
SET LOCAL lock_timeout = '2000ms';
UPDATE accounts SET balance = balance + 10 WHERE account_number = '9000000001';
```

### Empirical Observation
After exactly 2,000 milliseconds, Terminal B did not remain hung. Instead, PostgreSQL cleanly aborted the locked statement:
```text
ERROR: canceling statement due to lock timeout
CONTEXT: while updating tuple (0,15) in relation "accounts"
SQLSTATE: 55P03 (lock_not_available)
```

### Architectural Takeaway
In production banking APIs, setting `lock_timeout = '2s'` combined with application-level exponential retry logic ensures that momentary contention bursts never lock up HTTP connection pools.

---

## 7. Limitations & Production Considerations

### 7.1 What a Single-Laptop Test Cannot Prove
1. **Network Partitioning & Jitter**: Running `pgbench` locally over localhost IPC/loopback eliminates network latency, packet loss, TCP retransmission, and TLS handshake overhead.
2. **True Hardware Failure Domains**: A single NVMe SSD and unified memory bus cannot replicate distributed storage replication lag, write-stall spikes, or split-brain network partitions.
3. **Hyper-Contention Scale**: While 10 clients on 20 accounts proves deadlock immunity, enterprise systems experience 50,000+ concurrent payment webhooks contending on global settlement liquidity pools.

### 7.2 Key Production Enhancements
- **Client-Side Retry Middleware**: Implement Poly/resilience retry decorators on API endpoints catching `40P01` (deadlock) and `40001` (serialization failure) with randomized exponential jitter ($T_{\text{wait}} = 2^{\text{attempt}} \times 50\text{ms} + \text{rand}(0, 25\text{ms})$).
- **Connection Pooling & Multi-Tenancy**: Deploy PgBouncer in transaction pooling mode to multiplex thousands of microservice clients into a bounded set of PostgreSQL backend workers.

---

## 8. Reflection

### What Surprised Me
The sheer severity of the deadlock penalty was astonishing. A failure rate of only **3.1%** caused overall system throughput to collapse by **93.7%** (from 732.98 TPS down to 46.30 TPS) while latency inflated by **15.3x**. Deadlocks do not simply fail individual requests; the internal lock table thrashing, deadlock detector graph traversals, and abort/rollback I/O devastate the entire database engine.

### What I Would Do Differently
In a production redeployment of EquityPay, I would implement **partitioned settlement sub-accounts** to parallelize the central liquidity pool. Rather than forcing all peer-to-peer transfers to touch a single central settlement row, incoming and outgoing transactions could be sharded across 10 virtual settlement buckets, eliminating hot-spot contention entirely.
