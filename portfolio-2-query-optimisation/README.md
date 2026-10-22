# MIT8103 Advanced Database Systems
## Portfolio 2: Query Optimisation, Cost Modeling & Execution Analysis
### Case Study: EquityPay Financial Services Ltd.

---

## 1. Executive Summary & Overview

**Portfolio 2** investigates query execution performance, cost-based optimizer (CBO) decision models, index design patterns, and write-overhead trade-offs within the **EquityPay Financial Banking System** on **PostgreSQL 18**.

Operating on real-scale tables (`ledger_entries`: 400,000 double-entry postings, `transactions`: 200,098 financial operations, `accounts`: 6,001 accounts, `customers`: 1,000 entities), nine mission-critical production queries (**Q1–Q9**) were systematically analyzed before and after strategic indexing.

```
+---------------------------------------------------------------------------------------------------+
|                                      PORTFOLIO 2 ARCHITECTURE                                     |
+---------------------------------------------------------------------------------------------------+
|  [01_capture_plans.sql]        Captures EXPLAIN (ANALYZE, BUFFERS) for Q1-Q8 (before & after)     |
|  [02_query_results.sql]        Executes raw analytical queries Q1-Q9 (no EXPLAIN)                 |
|  [03_create_indexes.sql]       Deploys 5 targeted B-Tree, composite, partial, and covering indexes|
|  [04_drop_indexes.sql]         Tears down optimization indexes to return to clean baseline        |
|  [05_planner_experiments.sql]  CBO cost parameter audits, forced plan tests & selectivity tests   |
|  [06_write_cost.sql]           Bulk INSERT latency & disk amplification benchmark                 |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Structure & Deliverables Index

All files and deliverables for Portfolio 2 are structured in accordance with course requirements:

| Deliverable | Type | Description |
|:---|:---:|:---|
| [performance-analysis.md](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/performance-analysis.md) | Technical Report | Comprehensive performance analysis report covering all 9 queries, optimizer internals, cost models, write costs, and strategic recommendations. |
| [plans/execution-plan-guide.md](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/plans/execution-plan-guide.md) | Workflow Guide | Step-by-step instructions for capturing, parsing, and comparing `EXPLAIN (ANALYZE, BUFFERS)` outputs. |
| [plans/before.txt](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/plans/before.txt) | Raw Capture | Baseline execution plans for Q1–Q8 prior to index creation. |
| [plans/after.txt](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/plans/after.txt) | Raw Capture | Optimized execution plans for Q1–Q8 following index creation and visibility map maintenance. |
| [plans/results.txt](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/plans/results.txt) | Comparative Summary | Structured before-and-after comparison of cost estimates, wall-clock latencies, buffer hits/reads, and scan nodes. |
| [plans/planner.txt](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/plans/planner.txt) | Experiment Log | Complete outputs from `05_planner_experiments.sql`, documenting cost parameters, forced plan comparisons, and the selectivity tipping point. |
| [sql/](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/sql/) | SQL Scripts | DDL and DML scripts for plan capture, query execution, indexing, teardown, cost experiments, and write benchmarking. |
| [queries/](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/queries/) | SQL Files | Modular SQL files for individual queries `q01` through `q09`. |
| [screenshots/](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/screenshots/) | Visual Proof | Execution screenshots verifying pgAdmin 4 execution, visual query plans, and optimizer outputs. |

---

## 3. High-Level Performance Comparison Summary

| Query | Description | Baseline Latency | Optimized Latency | Speedup | Primary Optimization Mechanism |
|:---:|:---|:---:|:---:|:---:|:---|
| **Q1** | Account Statement (Limit 50) | 48.401 ms | **0.349 ms** | **138.7x** | Composite index scan eliminates Sort; early exit on 50 rows |
| **Q2** | Daily Transfer Totals (30 Days) | 54.946 ms | **1.134 ms** | **48.5x** | Partial covering index; 93% table pruned; Index Only Scan |
| **Q3** | Customer Largest Transfers (AML) | 91.493 ms | **1.851 ms** | **49.4x** | Foreign key index on `accounts(customer_id)` enables Nested Loop |
| **Q4** | Large Transfer Fraud (≥ ₦4,000) | 73.891 ms | **4.251 ms** | **17.4x** | Partial covering index on rare debit events (~1.4% of table) |
| **Q5** | Idempotency Lookup (Gateway) | 0.058 ms | **0.055 ms** | **1.0x** | Baseline control; pre-existing UNIQUE B-Tree already optimal |
| **Q6** | Balance Reconciliation Audit | 105.489 ms | **12.503 ms** | **8.4x** | Ordered index scan eliminates 12.5 MB disk-spilling external merge sort |
| **Q7** | Unbalanced Journal Detection | 145.703 ms | **146.512 ms** | **1.0x** | Full audit scan; sequential streaming mathematically superior |
| **Q8** | Net Movement Reversals (90 Days) | 56.142 ms | **1.631 ms** | **34.4x** | Covering composite index includes status and amount |
| **Q9** | Join Fan-Out Trap | Inaccurate | Corrected | **Correctness** | Pre-aggregated CTEs prevent 2.0x cartesian product sum inflation |

---

## 4. Execution Workflow

To replicate the benchmarks and verify all query execution plans:

```bash
# 1. Connect to PostgreSQL
psql -U postgres -d EquityPay_db

# 2. Capture baseline execution plans (BEFORE indexes)
\o portfolio-2-query-optimisation/plans/before.txt
\i portfolio-2-query-optimisation/sql/01_capture_plans.sql
\o

# 3. Create the 5 optimization indexes
\i portfolio-2-query-optimisation/sql/03_create_indexes.sql

# 4. Perform critical visibility map maintenance
VACUUM (ANALYZE) transactions;
VACUUM (ANALYZE) ledger_entries;

# 5. Capture optimized execution plans (AFTER indexes)
\o portfolio-2-query-optimisation/plans/after.txt
\i portfolio-2-query-optimisation/sql/01_capture_plans.sql
\o

# 6. Run CBO planner experiments
\o portfolio-2-query-optimisation/plans/planner.txt
\i portfolio-2-query-optimisation/sql/05_planner_experiments.sql
\o

# 7. Run write-cost overhead benchmark
\i portfolio-2-query-optimisation/sql/06_write_cost.sql
```

For detailed architectural analysis, cost formulas, and recommendations, see [performance-analysis.md](file:///c:/Users/cazuh/OneDrive%20-%20EQUINIX/Documents/MIT8103--Advanced-Database-Test/portfolio-2-query-optimisation/performance-analysis.md).
