# MIT 8103 Advanced Database Systems — Continuous Assessment

**Student Name**: Chukwuebuka Azuh  
**Student ID**: 301906536  
**Course**: MIT 8103 Advanced Database Systems  
**Session**: 2026/2027 Academic Session (September Cohort)  
**Institution**: Miva Open University  
**Case Study**: EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)  
**GitHub Repository**: [Ebukaa01/MIT-8103-Advanced-Database-Test: MIT CA Advanced database Test](https://github.com/Ebukaa01/MIT-8103-Advanced-Database-Test)  

---

## 1. Executive Overview

In enterprise financial technology, modern digital banking platforms cannot be architected as monolithic single-database deployments. A single storage paradigm cannot simultaneously optimize for the mathematically rigid, zero-tolerance guarantees of an immutable double-entry ledger, the extreme read/write throughput of interbank payments, high-availability disaster recovery, and the high-velocity, polymorphic demands of customer onboarding (KYC) and real-time fraud telemetry.

This repository represents the comprehensive, multi-phase Continuous Assessment (CA) submission for **MIT 8103: Advanced Database Systems** at **Miva Open University**. Built around **EquityPay Financial Services Ltd.**—a simulated commercial digital bank operating in compliance with Central Bank of Nigeria (CBN) regulations and global financial data standards (PCI-DSS, IFRS-9)—this project designs, implements, benchmarks, and mathematically validates an enterprise-grade **Polyglot & Distributed Database Architecture**.

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

## 2. Master Portfolio Directory & Status Matrix

| Portfolio Module | Engineering Domain | Core Database Technology | Status | Key Deliverables & Documentation |
| :--- | :--- | :--- | :---: | :--- |
| **[Portfolio 1](portfolio-1-database-design/README.md)** | **Database Design & Financial Integrity** | PostgreSQL 18 (Relational Core) | **Completed** | Normalized 3NF/BCNF Schema, Immutable Double-Entry Ledger, Network Idempotency, Card Tokenization. |
| **[Portfolio 2](portfolio-2-query-optimisation/README.md)** | **Query Optimisation & Index Tuning** | PostgreSQL 18 Cost-Based Optimizer | **Completed** | 8 Analytical/OLTP Queries Tuned with `EXPLAIN (ANALYZE, BUFFERS)`, Partial & Composite B-Tree Indexes, Buffer Optimization. |
| **[Portfolio 3](portfolio-3-transactions-concurrency/README.md)** | **Transactions & Concurrency Control** | PostgreSQL 18 MVCC & Row Locks | **Completed** | Deadlock Elimination via Ordered Resource Locking, MVCC Isolation Experiments, pgbench Stress Benchmarks. |
| **[Portfolio 4](portfolio-4-nosql/README.md)** | **NoSQL & Polyglot Persistence** | MongoDB Atlas 8.0 & PostgreSQL 18 | **Completed** | BSON `$jsonSchema` Validation, 4 Analytical Aggregation Pipelines, Explain Metrics (`COLLSCAN` $\rightarrow$ `IXSCAN`), TTL Automation. |
| **[Portfolio 5](portfolio-5-distributed-cloud/README.md)** | **Distributed & Cloud Architectures** | PostgreSQL 17 Physical Streaming & Atlas | **Completed** | Primary-Standby Replication Slot, Sync/Async Failover Simulation, Declarative Partitioning, Read Latency Harness (p50–p99). |

---

## 3. High-Level Summary of Portfolio Modules

### 3.1 Portfolio 1: Relational Design, Normalisation & Integrity Validation
- **Engine**: PostgreSQL 18
- **Data Scale**: 5,001 customers, 6,001 accounts, ~206,100 transactions, ~406,200 double-entry ledger entries.
- **Architectural Highlights**:
  - **Immutable Double-Entry Ledger**: Implements an append-only journal (`ledger_entries`) where money movement requires equal debit and credit balancing entries.
  - **Fixed-Point Financial Arithmetic**: Governed strictly by `NUMERIC(19,4)` to prevent IEEE 754 floating-point rounding anomalies.
  - **Network Idempotency**: Enforced by a unique constraint on `idempotency_key` to neutralize duplicate payment submissions from network retries.
  - **Defensive Referential Integrity**: Enforces `ON DELETE RESTRICT` across accounts and ledger lines, blocking cascading deletions of financial history.
  - **PCI-DSS Compliance**: Sanitizes payment card numbers to masked PANs (first 6, last 4 digits) with strict exclusion of CVVs and PINs.
- **Documentation**: Detailed design notes, entity-relationship diagrams, and normalisation proofs in [portfolio-1-database-design/README.md](portfolio-1-database-design/README.md).

---

### 3.2 Portfolio 2: Query Optimisation & Performance Tuning
- **Engine**: PostgreSQL 18 Query Planner (`EXPLAIN (ANALYZE, BUFFERS)`)
- **Focus**: Eliminating sequential scans (`Seq Scan`) across high-volume transaction history tables under heavy read workloads.
- **Key Empirical Results**:
  - **Q1–Q8 Benchmarks**: Evaluated 8 diverse queries ranging from point account balance lookups to complex multi-table analytical joins.
  - **Targeted Index Strategies**: Deployed composite B-tree indexes, partial indexes targeting active pending transactions (`WHERE status = 'PENDING'`), and covering indexes using the `INCLUDE` clause.
  - **Buffer Pool Efficiency**: Reduced shared buffer page hits by over **95%**, dropping query latencies from hundreds of milliseconds down to sub-millisecond execution times.
- **Documentation**: Complete before-and-after query plans and graphical analysis in [portfolio-2-query-optimisation/README.md](portfolio-2-query-optimisation/README.md).

---

### 3.3 Portfolio 3: Transactions, Concurrency Control & Isolation
- **Engine**: PostgreSQL 18 Concurrency Control Manager
- **Focus**: Preventing lost updates, dirty reads, and transaction deadlocks during concurrent peer-to-peer wallet transfers.
- **Key Empirical Results**:
  - **Deterministic Resource Locking**: Solved cyclic deadlock dependencies mathematically by enforcing account row-locking order via `LEAST(sender_id, receiver_id)` and `GREATEST(sender_id, receiver_id)` inside `SELECT ... FOR UPDATE` blocks.
  - **Isolation Level Benchmarking**: Contrasted `READ COMMITTED` against `REPEATABLE READ`, demonstrating serialization failure dynamics under write contention.
  - **Stress Test Findings**: Under extreme concurrent load (`pgbench`), uncoordinated transfer locking suffered severe throughput collapse due to deadlocks, whereas deterministic ordered locking maintained zero deadlocks and 100% financial balance conservation.
- **Documentation**: Concurrency scripts, deadlock graphs, and stress test logs in [portfolio-3-transactions-concurrency/README.md](portfolio-3-transactions-concurrency/README.md).

---

### 3.4 Portfolio 4: NoSQL & Polyglot Persistence Architecture
- **Engine**: MongoDB Atlas 8.0 Cloud Cluster paired with PostgreSQL 18
- **Focus**: Designing the operational perimeter for customer KYC documents, append-only security audit streams, and auto-expiring sessions.
- **Key Empirical Results**:
  - **Governed Flexibility (`$jsonSchema`)**: Enforces document schemas for `kyc_profiles` and `audit_events`. Validated negative rejection of malformed records with **`DocumentValidationFailure` (code `121`)**.
  - **Aggregation Pipelines**: Implemented 4 business pipelines including a cross-collection polyglot join (`$lookup` and `$unwind`) correlating failed customer logins with KYC tiers.
  - **Index Optimisation**: Built compound indexes (`idx_audit_customer_ts`, `idx_audit_type_ts`) and unique constraints (`uq_kyc_customer`). Converted full scans (`COLLSCAN`, 100,000 documents examined) into direct index scans (`IXSCAN`, 20 keys examined), achieving a **50x latency reduction (50 ms $\rightarrow$ 1 ms)**.
  - **Data Lifecycle Automation**: Configured a 3600-second TTL index on `login_sessions` for automated background token eviction.
- **Documentation**: Complete metrics table, aggregation code, and evidence screenshots in [portfolio-4-nosql/README.md](portfolio-4-nosql/README.md).

---

### 3.5 Portfolio 5: Distributed & Cloud Database Architectures
- **Engine**: PostgreSQL 17 Physical Streaming Replication Cluster (Docker) & MongoDB Atlas Cloud
- **Focus**: High availability (HA), read-scale distribution, declarative table partitioning, and replica latency variance.
- **Key Empirical Results**:
  - **Physical Streaming Replication**: Bootstrapped an active primary (`Port 5433`) and read-only standby replica (`Port 5434`) using dedicated replication slots (`equitypay_standby_slot`) and `pg_walreceiver`.
  - **Replication Mode Evaluation**: Profiled asynchronous vs synchronous replication modes (`synchronous_commit = on`). Dissected the physical `SyncRep` IPC wait event when the replica container was intentionally stopped.
  - **Failover & Timeline Promotion**: Simulated primary node failure and executed standby promotion using `pg_promote()`, validating timeline progression (Timeline 1 $\rightarrow$ Timeline 2).
  - **Declarative Partitioning**: Implemented RANGE partitioning by calendar quarter and LIST partitioning by transaction type, proving partition pruning via `EXPLAIN`.
  - **Statistical Read Latency Benchmark**: Built a multi-threaded Python benchmark measuring p50, p90, p95, and p99 read latencies under quiescent and heavy write contention workloads.
- **Documentation**: Replication configs, failover transcripts, and benchmark graphs in [portfolio-5-distributed-cloud/README.md](portfolio-5-distributed-cloud/README.md).

---

## 4. Architectural Data Divisions: Polyglot Matrix

The foundational design standard established in this continuous assessment is:  
> **PostgreSQL owns the money; MongoDB owns the customer context.**

| Architectural Dimension | PostgreSQL 18 (System of Record) | MongoDB Atlas 8.0 (Operational Perimeter) |
| :--- | :--- | :--- |
| **Data Role** | Ledger entries, accounts, customers, transactions | KYC identity documents, security telemetry, session tokens |
| **Data Model** | Fully normalized relational relations (3NF/BCNF) | Polymorphic hierarchical BSON documents |
| **Consistency Paradigm** | Immediate Consistency (Strict ACID) | Tunable Consistency (Eventual $\leftrightarrow$ Linearizable) |
| **Integrity Enforcement** | Declarative foreign keys (`ON DELETE RESTRICT`) | Application-level references & BSON `$jsonSchema` |
| **Concurrency Mechanism** | Multi-Version Concurrency Control (MVCC) & Row Locks | Single-document atomic mutations; WiredTiger write cache |
| **Scaling Model** | Vertical scaling + physical streaming read replicas | Horizontal sharding across replica sets & time-series chunks |
| **Mathematical Guarantees** | Exact decimal arithmetic (`NUMERIC(19,4)`) | BSON `Decimal128` (susceptible to driver floating-point coercion) |

---

## 5. Technology Stack & Prerequisites

- **Relational Engines**: PostgreSQL 18 (Local) & PostgreSQL 17 (Containerized Primary/Standby)
- **Document Engine**: MongoDB Atlas 8.0 Cloud Cluster (Managed 3-node Replica Set)
- **Containerization**: Docker & Docker Compose (v2.20+)
- **Client Tools**:
  - `psql` (PostgreSQL interactive terminal)
  - `mongosh` (MongoDB Shell v2.14+)
- **Scripting & Benchmarking**:
  - Python 3.10+ (`psycopg2-binary`, `numpy`, `tabulate`)
  - Node.js (v20.x LTS)
  - Bash / PowerShell 7+

---

## 6. Global Reproduction Guide

All portfolios are structured for independent verification. To reproduce the entire Continuous Assessment suite from the project root:

### 1. Database Design & Seeding (Portfolio 1)
```bash
# Connect to PostgreSQL and execute schema initialization
psql -U equitypay -d equitypay_db -f portfolio-1-database-design/01_schema.sql
psql -U equitypay -d equitypay_db -f portfolio-1-database-design/02_seed_data.sql
psql -U equitypay -d equitypay_db -f portfolio-1-database-design/03_validation_suite.sql
```

### 2. Query Optimisation & Explain Plans (Portfolio 2)
```bash
# Profile queries before and after index application
psql -U equitypay -d equitypay_db -f portfolio-2-query-optimisation/01_capture_plans.sql
psql -U equitypay -d equitypay_db -f portfolio-2-query-optimisation/03_create_indexes.sql
```

### 3. Concurrency & Deadlock Stress Testing (Portfolio 3)
```bash
# Execute concurrency verification and pgbench simulations
psql -U equitypay -d equitypay_db -f portfolio-3-transactions-concurrency/01_function_test.sql
psql -U equitypay -d equitypay_db -f portfolio-3-transactions-concurrency/02_isolation_experiments.sql
```

### 4. NoSQL & Document Perimeter (Portfolio 4)
```bash
# Export Atlas connection string
export MONGODB_URI=$(cat portfolio-4-nosql/.env | grep MONGODB_URI | cut -d= -f2-)

# Execute schema validation, seeding, CRUD/Aggregation, and Index Explain
mongosh "$MONGODB_URI" --file portfolio-4-nosql/01_schema_validation.js
mongosh "$MONGODB_URI" --file portfolio-4-nosql/02_seed_data.js
mongosh "$MONGODB_URI" --file portfolio-4-nosql/03_crud_and_aggregation.js
mongosh "$MONGODB_URI" --file portfolio-4-nosql/04_indexes_explain.js
```

### 5. Distributed Replication & Cloud Audit (Portfolio 5)
```bash
# Launch Primary and Standby PostgreSQL cluster
docker compose -f portfolio-5-distributed-cloud/docker-compose.yml up -d

# Execute primary and replica diagnostic checks
psql -h localhost -p 5433 -U equitypay -d equitypay_db -f portfolio-5-distributed-cloud/01_primary_checks.sql
psql -h localhost -p 5434 -U equitypay -d equitypay_db -f portfolio-5-distributed-cloud/02_replica_checks.sql

# Execute Atlas cloud infrastructure audit
mongosh "$MONGODB_URI" --file portfolio-5-distributed-cloud/04_atlas_cloud_check.js

# Execute multi-threaded read latency benchmark
python3 portfolio-5-distributed-cloud/05_read_latency_benchmark.py
```

---

## 7. Academic Integrity & AI-Use Declaration

In compliance with the academic integrity guidelines and continuous assessment regulations of **Miva Open University**, this project done by 
 for MIT Advanced Database Systems acknowledges the ethical use of artificial intelligence tools:

- **AI Collaboration**: Artificial intelligence assistance (Google DeepMind Antigravity / Gemini) was utilized as an intelligent pair-programming collaborator for syntax drafting, shell automation scripts, diagnostic catalog queries, and Markdown report formatting.
- **Originality & Authenticity**: All database schemas, SQL queries, BSON document models, mathematical proofs, deadlock-free locking strategies, and distributed cluster configurations were formulated, tested, and analyzed by the student.
- **Empirical Verifiability**: All reported execution plans, query metrics, replication logs, explain statistics, and benchmark percentiles represent authentic empirical results obtained from local PostgreSQL instances, Docker containers, and active MongoDB Atlas cloud clusters.
