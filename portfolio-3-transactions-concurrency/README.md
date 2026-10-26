# MIT 8103: Advanced Database Systems
## Portfolio 3: Transactions, Concurrency Control & ACID Guarantees
### Case Study: EquityPay Financial Services Ltd.

**Candidate**: Ebuka  
**Database**: `EquityPay_db` (PostgreSQL 18.6)  

---

## 1. Overview

**Portfolio 3** investigates the rigorous implementation, empirical stress-testing, and mathematical validation of **ACID transactional properties**, concurrency control mechanics, deadlock prevention algorithms, and double-entry consistency within the **EquityPay Financial Banking System** on **PostgreSQL 18**.

In financial ledger architectures, concurrent peer-to-peer fund transfers introduce catastrophic operational risks if uncoordinated:
- **Lost Updates**: Concurrent balance deductions overwriting each other, destroying withdrawal audits.
- **Deadlocks (`40P01`)**: Circular lock dependency chains between cross-transfers (A $\rightarrow$ B vs. B $\rightarrow$ A) triggering transaction aborts.
- **Non-Repeatable Reads & Inconsistent Snapshots**: Queries witnessing mutating state mid-transaction.
- **Double-Debit Failures**: Network timeouts causing duplicated payment processing.

This portfolio presents a production-grade stored procedure (`transfer_funds`), reproduces the foundational concurrency anomalies under controlled laboratory conditions, benchmarks system throughput under extreme contention using `pgbench`, and proves that global money supply is conserved to four decimal places across **3,938 high-concurrency transfers**.

---

## 2. Folder Structure

```
portfolio-3-transactions-concurrency/
├── 01_transfer_function.sql        # PL/pgSQL: transfer_funds() (safe) & transfer_funds_unordered() (flawed)
├── 02_demo_setup.sql               # Idempotent demo wallet setup (Alice: 9000000001, Bob: 9000000002)
├── 03_commit_rollback_demo.sql     # 5 ACID scenarios (COMMIT, ROLLBACK, exception abort, idempotency, SAVEPOINT)
├── 05_stress_ordered.pgbench       # pgbench harness: safe ordered locking across 20 hot accounts
├── 06_stress_unordered.pgbench     # pgbench harness: flawed reverse locking demonstrating deadlocks
├── 07_integrity_check.sql          # 5-part mathematical audit: money conservation & double-entry parity
├── analysis.md                     # Comprehensive technical analysis report & empirical evaluation
├── README.md                       # Portfolio overview, execution guide, benchmark findings, & reflection
├── output/                         # Raw empirical evidence logs from CLI execution
│   ├── 03_commit_rollback_output.txt
│   ├── integrity_before.txt
│   ├── stress_ordered.txt
│   ├── integrity_after_ordered.txt
│   ├── stress_unordered.txt
│   └── integrity_after_unordered.txt
└── screenshots/                    # Visual evidence captured from pgAdmin 4 & psql
    ├── 01_function_test.png
    ├── 02_commit_rollback_output.png
    ├── 03-demo_setup.png
    ├── 04-experiment-lost-update.png
    ├── 05-experiment-waiting.png
    ├── 06-experiment-unblocking.png
    ├── 07-integrity check.png
    ├── 08-experiment-read-committed.png
    ├── 09-experiment-repeatable_read.png
    ├── 10-experiment-deadlock.png
    ├── 11-stress-results.png
    └── 12-integrity-check.png
```

---

## 3. How to Reproduce

All commands should be executed from the **repository root directory** in PowerShell. Ensure PostgreSQL 18 tools (`psql`, `pgbench`) are in your session PATH:

```powershell
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"
```

### Step 1: Deploy Core Stored Procedures
```powershell
psql -U postgres -d EquityPay_db -f "portfolio-3-transactions-concurrency/01_transfer_function.sql"
```

### Step 2: Initialize Demo Wallets (Alice & Bob)
```powershell
psql -U postgres -d EquityPay_db -f "portfolio-3-transactions-concurrency/02_demo_setup.sql"
```

### Step 3: Run ACID Transaction Demonstration Suite
```powershell
psql -U postgres -d EquityPay_db -f "portfolio-3-transactions-concurrency/03_commit_rollback_demo.sql" -o "portfolio-3-transactions-concurrency/output/03_commit_rollback_output.txt"
```

### Step 4: Execute Baseline Financial Integrity Audit
```powershell
psql -U postgres -d EquityPay_db -f "portfolio-3-transactions-concurrency/07_integrity_check.sql" -o "portfolio-3-transactions-concurrency/output/integrity_before.txt"
```

### Step 5: Execute Ordered Stress Benchmark (Safe Locking)
Runs 10 concurrent worker threads over 4 CPU cores executing 200 transfers per client (2,000 total transfers):
```powershell
pgbench -U postgres -n -c 10 -j 4 -t 200 -f "portfolio-3-transactions-concurrency/05_stress_ordered.pgbench" EquityPay_db | Tee-Object "portfolio-3-transactions-concurrency/output/stress_ordered.txt"
```

### Step 6: Post-Ordered Integrity Check
Verify that exactly 2,000 transfers and 4,000 ledger lines were committed with zero imbalances:
```powershell
psql -U postgres -d EquityPay_db -f "portfolio-3-transactions-concurrency/07_integrity_check.sql" -o "portfolio-3-transactions-concurrency/output/integrity_after_ordered.txt"
```

### Step 7: Execute Unordered Stress Benchmark (Deadlock Demonstration)
Runs the same load using reverse-order locking to trigger contention and deadlocks:
```powershell
pgbench -U postgres -n -c 10 -j 4 -t 200 -f "portfolio-3-transactions-concurrency/06_stress_unordered.pgbench" EquityPay_db | Tee-Object "portfolio-3-transactions-concurrency/output/stress_unordered.txt"
```

### Step 8: Final Reconciled Integrity Audit
Verify that money supply remained 100% conserved despite transaction failures:
```powershell
psql -U postgres -d EquityPay_db -f "portfolio-3-transactions-concurrency/07_integrity_check.sql" -o "portfolio-3-transactions-concurrency/output/integrity_after_unordered.txt"
```

---

## 4. Key Findings with Empirical Numbers

### 4.1 Benchmark Comparison Table

| Metric | Safe Ordered Locking (`05_stress_ordered`) | Flawed Unordered Locking (`06_stress_unordered`) | Variance / Impact |
| :--- | :---: | :---: | :---: |
| **Locking Strategy** | Deterministic Sorting (`LEAST`/`GREATEST`) | Directional (Sender $\rightarrow$ Receiver) | Architectural |
| **Attempted Transfers** | 2,000 | 2,000 | Baseline |
| **Completed Transfers** | **2,000 (100.0%)** | **1,938 (96.9%)** | -62 failed |
| **Deadlock Aborts (`40P01`)** | **0 (0.000%)** | **62 (3.100%)** | Complete elimination |
| **Throughput (TPS)** | **732.98 TPS** | **46.30 TPS** | **-93.7% collapse** |
| **Average Latency** | **13.64 ms** | **209.28 ms** | **15.3x slower** |

> **Key Takeaway**: Deadlocks do not merely cause individual transaction failures. The cascading overhead of lock contention, operating system context switching, PostgreSQL deadlock detector graph evaluations, and abort/rollback I/O causes system throughput to collapse by **15.8x**.

### 4.2 Financial Integrity Audit Summary

Across all 3,938 combined stress-test transfers and ACID demonstrations, the 5-part verification suite in [07_integrity_check.sql](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-3-transactions-concurrency/07_integrity_check.sql) verified that:
1. **`total_money_in_system`**: Exactly **₦1,000,000,000,000.0000** was conserved across the entire banking platform.
2. **`stress_ledger_lines`**: Exactly **7,876** ledger lines were recorded for 3,938 transfers, maintaining a strict **2:1 ratio** (1 DEBIT and 1 CREDIT per transaction).
3. **`unbalanced_transactions`**: **0** transactions had unequal debit and credit sums.
4. **`mismatched_accounts`**: **0** accounts exhibited divergence between recorded balance and ledger journal history.
5. **`stuck_pending_transactions`**: **0** transactions remained orphaned or incomplete.

---

## 5. Visual Evidence Catalog

The `screenshots/` directory contains visual proof of all experiments and database states:

| Screenshot | File | Description & Technical Significance |
| :--- | :--- | :--- |
| **01** | [01_function_test.png](screenshots/01_function_test.png) | Compilation, installation, and smoke test of `transfer_funds()` and `transfer_funds_unordered()`. |
| **02** | [02_commit_rollback_output.png](screenshots/02_commit_rollback_output.png) | Full execution output of `03_commit_rollback_demo.sql` demonstrating all 5 ACID scenarios. |
| **03** | [03-demo-accounts_setup.png](screenshots/03-demo-accounts_setup.png) | Execution of `02_demo_setup.sql` establishing isolated 500.00 test wallets for Alice and Bob. |
| **04** | [04-experiment-lost-update.png](screenshots/04-experiment-lost-update.png) | Experiment 1: Terminal B overwriting Terminal A's deduction, leaving a 400.00 balance instead of 300.00. |
| **05** | [05-experiment-waiting.png](screenshots/05-experiment-waiting.png) | Concurrency lock wait: Terminal B hanging while awaiting the release of Alice's row lock held by Terminal A. |
| **06** | [06-experiment-unblocking.png](screenshots/06-experiment-unblocking.png) | Terminal C monitoring `pg_blocking_pids` showing PID `23916` blocked by `{21376}`, and instant unblocking on commit. |
| **07** | [07-integrity check-sql.png](screenshots/07-integrity%20check-sql.png) | Baseline financial audit confirming global money conservation and zero initial imbalances. |
| **08** | [08-experiment-read-committed.png](screenshots/08-experiment-read-committed.png) | Experiment 2: Non-Repeatable Read under `READ COMMITTED` returning 500.00 then 200.00 in the same transaction. |
| **09** | [09-experiment-repeatable_read.png](screenshots/09-experiment-repeatable_read.png) | Experiment 2 Fix: `REPEATABLE READ` snapshot isolation preserving balance consistency (500.00) despite concurrent commit. |
| **10** | [10-experiment-deadlock.png](screenshots/10-experiment-deadlock.png) | Experiment 4: PostgreSQL deadlock detector aborting transaction with `ERROR: deadlock detected (40P01)`. |
| **11** | [11-stress-results.png](screenshots/11-stress-results.png) | Terminal execution of `pgbench` displaying 732.98 TPS (ordered) vs. 46.30 TPS (unordered). |
| **12** | [12-integrity-check.png](screenshots/12-integrity-check.png) | Final audit verifying zero corrupted accounts and zero unbalanced ledger lines after 3,938 transfers. |
| **13** | [13-insufficient funds.png](screenshots/13-insufficient%20funds.png) | Demonstration of `INSUFFICIENT_FUNDS` exception catching and automatic transactional rollback. |

---

## 6. Reflection & AI-Use Declaration

### 6.1 Engineering Reflection
Working on Portfolio 3 reinforced the reality that database concurrency bugs cannot be solved through optimism or application-level hope. The difference between a stable financial ledger and a catastrophic accounting failure comes down to mathematically disciplined locking order and atomic boundary design.

The most enlightening discovery was the non-linear cost of lock contention. Before running the benchmarks, I expected that a 3.1% deadlock failure rate would reduce throughput by approximately 5% to 10%. Seeing throughput collapse by **93.7%** demonstrated how severely transaction aborts, rollback write-ahead logging, and deadlock detector graph inspections monopolize engine resources.

In future enterprise deployments, I would expand this architecture by implementing **partitioned liquidity buckets** for hot merchant settlement accounts and integrating **distributed tracing** (e.g., OpenTelemetry) to monitor lock wait times before they breach client SLA thresholds.

### 6.2 AI-Use Declaration
In compliance with academic integrity guidelines, AI assistance (Gemini / Antigravity) was utilized as an intelligent pair-programming partner for:
- Formulating diagnostic queries on PostgreSQL catalog views (`pg_stat_activity`, `pg_blocking_pids`, `pg_locks`).
- Generating boilerplate syntax for PL/pgSQL transaction handlers and PowerShell orchestration commands.
- Structuring Markdown documentation, comparative benchmark tables, and mathematical formulas.

All SQL functions, transaction simulations, pgbench stress tests, and financial integrity reconciliations were executed locally on the PostgreSQL 18 database engine, and all empirical metrics and findings reflect authentic local workstation observations.
