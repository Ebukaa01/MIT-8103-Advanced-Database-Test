# MIT 8103 Advanced Database Systems — Continuous Assessment
## Final Project Documentation & Comprehensive Executive Summary

**Student Name**: Chukwuebuka Azuh  
**Student ID**: 301906536  
**Course Code**: MIT 8103  
**Course Title**: Advanced Database Systems  
**Academic Session**: 2026/2027 Academic Session (September Cohort)  
**Institution**: Miva Open University  
**Case Study Organisation**: EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)  
**GitHub Repository**: [https://github.com/Ebukaa01/MIT-8103-Advanced-Database-Test](https://github.com/Ebukaa01/MIT-8103-Advanced-Database-Test)  

---

## 1. Selected Organisation & Business Context

### 1.1 Enterprise Profile: EquityPay Financial Services Ltd.
**EquityPay Financial Services Ltd.** is a licensed commercial digital bank and fintech payments operator engineered to deliver real-time retail and commercial banking, peer-to-peer (P2P) transfers, merchant settlements, and cross-border remittances. Operating within the strict regulatory oversight of the **Central Bank of Nigeria (CBN)** and international standards (**PCI-DSS v4.0**, **IFRS-9**, **NDPA 2023**), the institution processes millions of daily monetary transactions alongside high-velocity security telemetry and identity verification requests.

### 1.2 The Core Engineering Dilemma
In modern digital finance, monolithic database architectures create an existential trade-off:
- **Ledger Invariance vs. Telemetry Throughput**: An immutable double-entry financial ledger demands zero-tolerance mathematical balance conservation ($\sum \text{Debits} - \sum \text{Credits} = 0$), absolute ACID serializability, and declarative referential integrity. Conversely, customer identity verification (KYC) documents are polymorphic (Tier 1 requires only a BVN; Tier 3 demands CAC corporate filings, international passports, and utility bills), and security telemetry (IP geolocation, device fingerprints, fraud flags) generates unbounded, high-velocity append streams.
- **Single Point of Failure & Contention**: Running high-frequency transfer transactions on the same database node that serves long-running regulatory audit reports and fraud scans leads to catastrophic buffer pool churn, lock contention, and operational downtime.

### 1.3 The Polyglot & Distributed Solution
To solve this dilemma, EquityPay implemented an enterprise **Polyglot & Distributed Database Architecture** governed by a strict architectural axiom:
> **"PostgreSQL owns the money; MongoDB owns the customer context."**

```
                                  EQUITYPAY FINANCIAL SERVICES LTD.
                             ENTERPRISE POLYGLOT & DISTRIBUTED TOPOLOGY

                                      +───────────────────────────+
                                      |    Client Applications    |
                                      |   (Mobile, Web, API GW)   |
                                      +─────────────┬─────────────+
                                                    │
                      ┌─────────────────────────────┴─────────────────────────────┐
                      │                                                           │
          [Financial Core Movements]                                    [Identity & Telemetry]
                      │                                                           │
                      ▼                                                           ▼
       +─────────────────────────────+                             +─────────────────────────────+
       |        PostgreSQL 18        |                             |      MongoDB Atlas 8.0      |
       |     (System of Record)      |                             |   (Operational Perimeter)   |
       +──────────────┬──────────────+                             +─────────────────────────────+
                      │                                            | • kyc_profiles (5,000 docs) |
        Physical WAL  │  Port 5433 (Primary)                       | • audit_events (100k docs)  |
          Streaming   │  Port 5434 (Standby)                       | • login_sessions (TTL cache)|
                      ▼                                            |                             |
       +─────────────────────────────+                             | BSON $jsonSchema Validation |
       |     PostgreSQL Standby      |                             | Rich Aggregation Pipelines  |
       |    (Read-Only Replica)      |                             | Compound B-Tree Indexes     |
       +─────────────────────────────+                             +─────────────────────────────+
       | • accounts (6,001)          |
       | • transactions (206,100+)   |
       | • ledger_entries (406,200+) |
       |                             |
       | Strict ACID & Foreign Keys  |
       | Exact NUMERIC(19,4) Math    |
       | Deterministic Row Locking   |
       +─────────────────────────────+
```

---

## 2. Multi-Portfolio Technical Synthesis (Portfolios 1 – 5)

### 2.1 Portfolio 1: Relational Schema Design, Normalisation & Financial Integrity
- **Core Technology**: PostgreSQL 18
- **Scale**: 5,001 customers, 6,001 accounts, ~206,100 transactions, ~406,200 double-entry ledger entries.
- **Architectural Highlights**:
  - **Immutable Double-Entry Ledger (`ledger_entries`)**: Enforces strict debit-credit balance preservation. For every monetary transfer, balanced credit and debit rows are atomically inserted; existing ledger lines are never updated or deleted.
  - **Fixed-Point Financial Precision**: All balances and journal movements use `NUMERIC(19,4)` to prevent IEEE 754 floating-point rounding errors.
  - **Network Idempotency**: A unique constraint on `idempotency_key` guarantees that network timeouts and client retries never cause duplicate debits.
  - **PCI-DSS Compliance**: Payment card numbers are masked (storing only first 6 and last 4 digits); CVVs and PINs are strictly prohibited from persistence.
  - **Relational Normalisation**: Rigorously decomposed into 3NF and BCNF, with exactly 4 documented, controlled denormalisations for read-latency optimization.

### 2.2 Portfolio 2: Query Optimisation & Cost-Based Performance Tuning
- **Core Technology**: PostgreSQL 18 Cost-Based Optimizer (`EXPLAIN (ANALYZE, BUFFERS)`)
- **Focus**: Eliminating expensive sequential scans (`Seq Scan`) and shared buffer thrashing across 8 mission-critical OLTP and analytical queries (Q1–Q8).
- **Architectural Highlights**:
  - **Targeted Composite B-Trees**: Engineered multi-column indexes aligned with query filter selectivity and sort order.
  - **Partial Indexing**: Created high-efficiency partial indexes targeting active, high-priority transaction subsets (e.g., `WHERE status = 'PENDING'`), keeping index sizes minimal.
  - **Covering Indexes (`INCLUDE`)**: Appended payload columns to index leaf nodes to enable pure Index-Only Scans (`Index Only Scan`), bypassing heap table reads entirely.
  - **Empirical Results**: Shared buffer page reads collapsed by over **95%**, reducing query latencies from hundreds of milliseconds to sub-millisecond execution times.

### 2.3 Portfolio 3: Transactions, Concurrency Control & Isolation Semantics
- **Core Technology**: PostgreSQL 18 Multi-Version Concurrency Control (MVCC) & Row-Level Locking
- **Focus**: Guaranteeing serializable money movement without race conditions, lost updates, or deadlocks during concurrent P2P transfers.
- **Architectural Highlights**:
  - **Deterministic Resource Ordering**: Solved cyclic transfer deadlocks mathematically. In inter-account transfers, accounts are consistently locked in ascending primary key order using `LEAST(sender_id, receiver_id)` and `GREATEST(sender_id, receiver_id)` in `SELECT ... FOR UPDATE` blocks.
  - **Isolation Level Benchmarking**: Conducted controlled experiments comparing `READ COMMITTED` and `REPEATABLE READ`. Proved that while `REPEATABLE READ` prevents non-repeatable reads, it generates first-committer serialization aborts under write contention.
  - **pgbench Stress Testing**: Under high-concurrency multi-client stress tests, uncoordinated locking suffered massive throughput collapse and high transaction rollback rates, while deterministic ordered locking achieved **zero deadlocks** and sustained full transaction throughput with 100% balance conservation.

### 2.4 Portfolio 4: NoSQL & Polyglot Persistence Architecture
- **Core Technology**: MongoDB Atlas 8.0 Cloud Cluster & PostgreSQL 18 Core
- **Focus**: Managing polymorphic KYC documents, security audit trails, and automated session life cycles.
- **Architectural Highlights**:
  - **Governed Flexibility (`$jsonSchema`)**: Implemented strict BSON JSON Schema validators on `kyc_profiles` and `audit_events`. Verified engine enforcement via negative tests, successfully rejecting malformed inputs with **`DocumentValidationFailure` (code `121`)**.
  - **Analytical Aggregation Pipelines**: Developed 4 operational pipelines, including a cross-collection polyglot join (`$lookup` $\rightarrow$ `$unwind` $\rightarrow$ `$project`) correlating failed login attempts with customer KYC verification tiers.
  - **Index Profiling & Performance**: Built compound B-Tree indexes (`idx_audit_customer_ts`, `idx_audit_type_ts`) and unique constraints (`uq_kyc_customer`). Converted full collection scans (`COLLSCAN`) across 100,000 documents into direct index lookups (`IXSCAN`), reducing latency from **50 ms to 1 ms (50x speedup)**.
  - **Automated Data Lifecycle**: Implemented a 3600-second TTL index on `login_sessions` for automated background token expiration.

### 2.5 Portfolio 5: Distributed & Cloud Database Architectures
- **Core Technology**: PostgreSQL 17 Physical Streaming Replication Cluster (Docker) & MongoDB Atlas Cloud
- **Focus**: High Availability (HA), physical streaming replication, synchronous vs. asynchronous commit modes, failover promotion, and read latency variance.
- **Architectural Highlights**:
  - **Physical Streaming Cluster**: Configured Primary (`Port 5433`) and Standby (`Port 5434`) nodes with dedicated replication slots (`equitypay_standby_slot`) and `pg_walreceiver`.
  - **Sync vs. Async Replication Modes**: Profiled transaction latency under asynchronous and synchronous commit (`synchronous_commit = on`). Dissected the physical `SyncRep` IPC wait event when the replica container was intentionally paused.
  - **Failover & Timeline Promotion**: Simulated primary node crashes and executed zero-data-loss standby promotion via `pg_promote()`, validating timeline progression (Timeline 1 $\rightarrow$ Timeline 2).
  - **Declarative Partitioning**: Implemented RANGE partitioning by calendar quarter and LIST partitioning by transaction type, verifying partition pruning via `EXPLAIN`.
  - **Statistical Read Latency Benchmark**: Built a multi-threaded Python harness measuring latency percentiles (p50, p90, p95, p99) between Primary and Replica under quiescent baseline and heavy write contention.

---

## 3. Key Quantitative Empirical Findings

| Evaluation Domain | Metric / Workload | Baseline (Unoptimized / Raw) | Optimized (Engineered) | Empirical Impact |
| :--- | :--- | :---: | :---: | :---: |
| **P2: Statement Query** | Buffer Reads / Execution Time | 1,420 buffer hits (14.2 ms) | 4 buffer hits (0.18 ms) | **99.7% buffer reduction; 78x speedup** |
| **P2: Pending Fraud Scan** | Scan Type / Execution Time | `Seq Scan` on 206k rows (38 ms) | `Bitmap Index Scan` (0.42 ms) | **Partial Index eliminated full table scan** |
| **P3: Transfer Concurrency** | Deadlock Abort Rate (`pgbench`) | 3.1% deadlocks (Throughput collapsed 93.7%) | 0.0% deadlocks (Zero transaction aborts) | **Deterministic ordering mathematically eliminated deadlocks** |
| **P4: Customer Audit Feed** | Docs Examined / Execution Time | 100,000 docs examined + In-Memory Sort (50 ms) | 20 docs examined / `IXSCAN` (1 ms) | **5,000x doc scan reduction; 50x speedup** |
| **P4: Fraud Flag Stream** | Docs Examined / Execution Time | 100,000 docs examined / `COLLSCAN` (43 ms) | 907 docs examined / `IXSCAN` (5 ms) | **8.6x lower latency; zero unindexed scans** |
| **P4: KYC Point Lookup** | Index Scan Stage | `COLLSCAN` across 5,000 docs (4 ms) | `EXPRESS_IXSCAN` (0 ms) | **Instantaneous B-tree leaf resolution** |
| **P5: Replication Transport** | Primary-Standby Lag | 0 bytes lag (Quiescent) | < 64 kB lag (Under heavy write stress) | **Near-zero RPO ($RPO \approx 0$) streaming** |
| **P5: Standby Promotion** | Failover Recovery Time ($RTO$) | Manual cluster reconfiguration (> 15 min) | `pg_promote()` execution (< 1.8 s) | **Sub-2-second recovery time ($RTO < 2\text{s}$)** |

---

## 4. Visual Verification Evidence & Screenshot Index

All test stages were captured as visual terminal and database GUI artifacts with the student identifier prefix `Chukwuebuka_Azuh_301906536_`:

### Portfolio 1: Design & Integrity Validation (8 Artifacts)
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_01-setup.png`: Environment setup and PostgreSQL 18 connection.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_02-tables-created.png`: Schema generation across all relational tables.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_03-constraint-tests.png`: Check constraint and foreign key validation.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_04-equity-pay-db_table.png`: Physical table catalog layout.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_05-equity-pay-db_verify.png`: Database integrity verification script results.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_06-equity-pay-db_seeddata.png`: Seeding 5,001 customers and 6,001 accounts.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_equity-pay-db_verifyseed.png`: Verification of 406,200+ ledger entries.
- `portfolio-1-database-design/Screenshots/Chukwuebuka_Azuh_301906536_er-diagram.png`: Full Entity-Relationship diagram in 3NF/BCNF.

### Portfolio 2: Query Optimisation (17 Artifacts)
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_01_capture_plans-sql.png`: `EXPLAIN (ANALYZE, BUFFERS)` execution on unindexed queries Q1–Q8.
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_02_query_results-sql.png`: Analytical query result outputs.
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_03_create_indexes-sql.png`: Index generation DDL script.
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_04_drop_indexes-sql.png`: Index teardown benchmark validation.
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_05_planner_experiments-sql.png`: Optimizer cost parameters (`random_page_cost`, `work_mem`).
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_06_write_cost-sql.png`: DML write overhead evaluation on indexes.
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_after_plan_query_account-statement_analysis-plan.png`: Post-index query analysis plan.
- `portfolio-2-query-optimisation/screenshots/Chukwuebuka_Azuh_301906536_after_plan_query_account-statement_graphical-plan.png`: Graphical explain visualization.
- Additional workload screenshots: `q01-account-statement.png` through `q09_join_fanout_trap.png`.

### Portfolio 3: Transactions & Concurrency (14 Artifacts)
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_01_function_test.png`: Stored procedure execution for atomic transfer.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_02_commit_rollback_output.png`: Rollback integrity on failure.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_03-demo-accounts_setup.png`: High-contention account initialisation.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_04-experiment-lost-update.png`: Lost update simulation.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_05-experiment-waiting.png`: Row lock acquisition wait state.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_06-experiment-unblocking.png`: Lock release and transaction commit.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_07-integrity check-sql.png`: Cross-table balance conservation test.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_08-experiment-read-committed.png`: Read Committed snapshot isolation behavior.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_09-experiment-repeatable_read.png`: Repeatable Read serialization failure.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_10-experiment-deadlock.png`: Deadlock graph and engine abort.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_11-stress-results.png`: Multi-client `pgbench` stress test results.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_12-integrity-check.png`: Post-stress reconciliation ($\sum \Delta = 0$).
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_13-insufficient funds.png`: Check constraint rejection on negative balance.
- `portfolio-3-transactions-concurrency/screenshots/Chukwuebuka_Azuh_301906536_14-idempotency.png`: Duplicate transaction rejection.

### Portfolio 4: NoSQL & Polyglot Persistence (6 Artifacts)
- `portfolio-4-nosql/screenshots/Chukwuebuka_Azuh_301906536_schema_validation.png`: Schema creation and negative validation test (code `121`).
- `portfolio-4-nosql/screenshots/Chukwuebuka_Azuh_301906536_seed_verification.png`: Seed verification (5,000 KYC profiles & 100,000 audit events).
- `portfolio-4-nosql/screenshots/Chukwuebuka_Azuh_301906536_CRUD.png`: CRUD operations, `$elemMatch` queries, and nested document updates.
- `portfolio-4-nosql/screenshots/Chukwuebuka_Azuh_301906536_aggregation.png`: Analytical pipelines (event breakdown, daily volume, `$lookup` join, document sizes).
- `portfolio-4-nosql/screenshots/Chukwuebuka_Azuh_301906536_explain metrics_session clearing.png`: `explain('executionStats')` before/after indexing, unique duplicate rejection (code `11000`), and TTL setup.
- `portfolio-4-nosql/screenshots/Chukwuebuka_Azuh_301906536_directory.png`: Complete directory structure and output logs.

### Portfolio 5: Distributed & Cloud Architectures (11 Artifacts)
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_30190653601_containers_running.png`: Primary and Standby Docker containers online.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_02_docker_ps_healthy.png`: Container healthcheck status.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_03_primary_checks.png`: Primary node replication slot and WAL sender query.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_04_replica_checks.png`: Standby node WAL receiver status (`pg_is_in_recovery = true`).
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_05_row_counts..png`: Row count parity between Primary and Replica.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_05_stale_read.png`: Asynchronous replication lag simulation.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_06_caught_up.png`: Standby catch-up to primary LSN.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_07_sync_hang.png`: Synchronous replication wait on stopped standby.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_08_sync_warning.png`: Cancellation warning on aborted sync commit.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_09_atlas_cluster.png`: MongoDB Atlas 3-node replica set cluster dashboard.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_10_failover.png`: Standby promotion execution (`pg_promote()`) and timeline branch.
- `portfolio-5-distributed-cloud/screenshots/Chukwuebuka_Azuh_301906536_12_atlas_check_output.png`: Live cloud audit output.

---

## 5. Individual Engineering Reflection

Conducting this five-phase Continuous Assessment has fundamentally reshaped my engineering perspective on enterprise database architecture. The most profound realization is that **there is no universal database engine**. The historical divide between relational purists and NoSQL advocates dissolves when confronted with the complex requirements of an enterprise digital bank:

1. **The Irreplaceable Rigidity of Relational Ledgers**:
   Before this project, I viewed strict schema definitions and declarative foreign keys as administrative overhead compared to the rapid prototyping agility of document stores. However, observing how PostgreSQL natively enforces `NUMERIC(19,4)` fixed-point arithmetic and declarative check constraints proved that in financial systems, rigidity is a virtue. In MongoDB, numbers coerced by JavaScript client drivers to IEEE 754 floating-point numbers (`Double`) introduce subtle rounding errors that violate CBN and IFRS-9 standards. Furthermore, enforcing double-entry invariants ($\sum \text{Debits} = \sum \text{Credits}$) across documents in MongoDB requires distributed two-phase commits that cripple write performance. PostgreSQL's row-level MVCC locking makes it the only defensible choice for the core ledger.

2. **The Non-Linear Cost of Lock Contention**:
   In Portfolio 3, benchmarking transaction concurrency under `pgbench` revealed that a modest 3.1% deadlock rate did not simply reduce throughput by 3.1%—it caused a catastrophic **93.7% throughput collapse**. Transaction aborts, rollback WAL writes, and deadlock detection graphs severely monopolize engine resources. Deriving the mathematical solution—enforcing global account lock acquisition order via `LEAST()` and `GREATEST()` primary keys—demonstrated that concurrency bugs cannot be solved through retry loops or application hope; they require mathematical discipline at the query boundary.

3. **The Physical Reality of the CAP Theorem**:
   In Portfolio 5, the CAP theorem transformed from an abstract textbook diagram into an observable operational event. Freezing the standby container while running under `synchronous_commit = on` physically halted client transactions on the primary node during the `SyncRep` IPC wait event. This demonstrated the true cost of strict linearizable consistency: when network partitions occur, consistency sacrifices availability.

4. **Strategic Recommendations for Enterprise Production**:
   If deploying EquityPay into commercial production, I would enhance this architecture by:
   - Implementing **Patroni** backed by an **etcd** consensus cluster to automate failover orchestration and eliminate manual `pg_promote()` execution.
   - Deploying **Pgpool-II** or **ProxySQL** to transparently route read-only queries to standbys while directing write traffic to the primary.
   - Establishing **partition lifecycle automation** via `pg_partman` to pre-create quarterly ledger tables ahead of transaction ingestion.

---

## 6. Academic References & AI-Use Declaration

### 6.1 Selected Academic References & Engineering Standards
1. **Codd, E. F. (1970)**. 'A Relational Model of Data for Large Shared Data Banks'. *Communications of the ACM*, 13(6), pp. 377–387.
2. **Gray, J. (1981)**. 'The Transaction Concept: Virtues and Limitations'. In: *Proceedings of the 7th International Conference on Very Large Data Bases (VLDB)*. Cannes, France, pp. 144–154.
3. **Bernstein, P. A. and Goodman, N. (1981)**. 'Concurrency Control in Distributed Database Systems'. *ACM Computing Surveys*, 13(2), pp. 185–221.
4. **Berenson, H. et al. (1995)**. 'A Critique of ANSI SQL Isolation Levels'. In: *ACM SIGMOD Record*, 24(2), pp. 1–10.
5. **Selinger, P. G. et al. (1979)**. 'Access Path Selection in a Relational Database Management System'. In: *ACM SIGMOD*, pp. 23–34.
6. **Brewer, E. A. (2000)**. 'Towards Robust Distributed Systems'. In: *ACM PODC*. Portland, OR.
7. **Gilbert, S. and Lynch, N. (2002)**. 'Brewer's Conjecture and the Feasibility of Consistent, Available, Partition-Tolerant Web Services'. *ACM SIGACT News*, 33(2), pp. 51–59.
8. **Stonebraker, M. and Çetintemel, U. (2005)**. '"One Size Fits All": An Idea Whose Time Has Come and Gone'. In: *IEEE ICDE*, pp. 2–11.
9. **Kleppmann, M. (2017)**. *Designing Data-Intensive Applications*. Sebastopol, CA: O'Reilly Media.
10. **Central Bank of Nigeria (CBN) (2018)**. *Guidelines on Electronic Payment Channels in Nigeria*. Abuja: Central Bank of Nigeria.
11. **PCI SSC (2022)**. *Payment Card Industry Data Security Standard (PCI-DSS), Version 4.0*. Wakefield, MA: PCI SSC.
12. **IFRS Foundation (2014)**. *IFRS 9: Financial Instruments*. London: IFRS Foundation.
13. **Nigeria Data Protection Commission (NDPC) (2023)**. *Nigeria Data Protection Act (NDPA) 2023*. Abuja: Federal Government of Nigeria.

*(Full extended 45-entry academic bibliography available in [`reference.md`](reference.md)).*

---

### 6.2 AI-Use Declaration
In compliance with the academic integrity guidelines and continuous assessment regulations of **Miva Open University**, this project done by Chukwuebuka Azuh (Student ID : 301906536) acknowledges the ethical use of artificial intelligence:

- **AI Pair Programming Partner**: Artificial intelligence assistance (Google DeepMind Antigravity / Gemini) was utilized as an intelligent pair-programming collaborator for:
  - Drafting PostgreSQL replication entrypoint scripts and Docker Compose healthchecks.
  - Formulating diagnostic queries on PostgreSQL catalog views (`pg_stat_replication`, `pg_stat_activity`, `pg_locks`).
  - Generating MongoDB aggregation pipeline syntax (`$lookup`, `$unwind`, `$dateToString`) and BSON JSON Schema structures.
  - Structuring Markdown documentation, ASCII architecture diagrams, and LaTeX mathematical notations.
- **Originality & Execution**: All database schemas, SQL functions, transaction simulations, index optimization strategies, failover drills, and statistical benchmark harnesses were designed, executed, and validated by the student on live local database engines and MongoDB Atlas cloud clusters. All reported metrics and visual evidence reflect authentic, verifiable experimental data.

