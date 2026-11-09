# MIT 8103 Advanced Database Systems — Master Portfolio

**Student Name:** Chukwuebuka Azuh  
**Student ID:** 301906536  
**Course:** MIT 8103 Advanced Database Systems  
**Session:** 2026/2027 Academic Session (September Cohort)  
**Programme:** Master of Information Technology (MIT)  
**Institution:** Miva Open University — School of Post Graduate Studies  
**Assessment Type:** Individual Practical Database Portfolio (40 Marks Continuous Assessment)  
**Case Study Organisation:** EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)  
**GitHub Repository:** [https://github.com/Ebukaa01/MIT-8103-Advanced-Database-Test](https://github.com/Ebukaa01/MIT-8103-Advanced-Database-Test)  

---

## 1. Executive Summary & Case Study Overview

**EquityPay Financial Services Ltd. (EPFS)** is a simulated digital banking platform and payment service provider operating within the Nigerian financial ecosystem under the regulatory frameworks of the **Central Bank of Nigeria (CBN)**, **PCI-DSS v4.0**, **IFRS-9**, and the **Nigeria Data Protection Act (NDPA 2023)**. EquityPay handles retail customer deposits, peer-to-peer (P2P) transfers, merchant card settlements, interbank transaction clearing, and real-time fraud telemetry.

This repository serves as the comprehensive, five-part practical database engineering master portfolio for **MIT 8103 Advanced Database Systems**, demonstrating an enterprise **Polyglot & Distributed Database Architecture**:

* **Authoritative Relational Core:** PostgreSQL 18 enforcing an immutable double-entry ledger invariant ($\sum \text{Debits} - \sum \text{Credits} = 0.0000$), fixed-point currency representation (`NUMERIC(19,4)`), strict 3NF/BCNF normalisation with 4 documented denormalisations, network idempotency guards, and deterministic row locking (`SELECT ... FOR UPDATE`).
* **Targeted Indexing & CBO Tuning:** Composite B-Tree, partial, and covering indexes eliminating costly sequential scans across high-volume transaction workloads (~206,100 transactions and ~406,200 ledger entries), achieving a 95%+ buffer read reduction.
* **Concurrent Concurrency Control:** Strict lock-acquisition ordering mathematically preventing circular deadlocks, write-skew mitigation under `REPEATABLE READ`, and `pgbench` multi-client stress testing.
* **Polyglot Persistence Model:** MongoDB Atlas 8.0 managing polymorphic KYC identity tiers, append-only security telemetry audit logs, and automatic session purging via TTL indexes.
* **Distributed Cloud & Disaster Recovery:** PostgreSQL streaming replication with physical replication slots (`equitypay_standby_slot`), Sync/Async commit modes, declarative range/list partitioning, and sub-2-second failover promotion (`pg_promote`).

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

## 2. Portfolio Structure, Deliverables & Marks Matrix

All 5 core portfolios and university-mandated synthesis documents are 100% completed, empirically verified, and reproducible:

| Portfolio | Domain & Focus | Weight | Status | Primary Documentation & Code |
| :--- | :--- | :---: | :---: | :--- |
| **Portfolio 1** | Database Design, Implementation & Integrity Validation | 7 Marks | Completed (100%) ✅ | [Portfolio 1 README](./portfolio-1-database-design/README.md) · Schema DDL · Normalisation (3NF/BCNF) · ERD |
| **Portfolio 2** | Query Optimisation & Performance Tuning | 7 Marks | Completed (100%) ✅ | [Portfolio 2 README](./portfolio-2-query-optimisation/README.md) · EXPLAIN ANALYZE Metrics · 10 SQL Queries · Index Scripts |
| **Portfolio 3** | Transactions, Concurrency Control & Isolation | 7 Marks | Completed (100%) ✅ | [Portfolio 3 README](./portfolio-3-transactions-concurrency/README.md) · ACID SQL Scripts · Isolation Analysis · `pgbench` Stress Test |
| **Portfolio 4** | NoSQL & Polyglot Persistence | 7 Marks | Completed (100%) ✅ | [Portfolio 4 README](./portfolio-4-nosql/README.md) · JSON Schema Validation · Aggregation Pipelines · Explain Metrics |
| **Portfolio 5** | Distributed & Cloud Database Architectures | 6 Marks | Completed (100%) ✅ | [Portfolio 5 README](./portfolio-5-distributed-cloud/README.md) · Streaming Replication · Partitioning · HA & Failover Drill |
| **Synthesis** | Final Documentation, AI Declaration & References | 6 Marks | Completed (100%) ✅ | [Final Documentation](./FINAL_DOCUMENTATION.md) · [References & Bibliography](./reference.md) · AI-Use Statement |
| **Total Scope** | **Continuous Assessment Scope** | **40 Marks** | **ALL COMPLETED ✅** | **Full Academic Requirements Satisfied** |

---

## 3. High-Level Summary of Portfolio Modules

### 3.1 Portfolio 1: Relational Design, Normalisation & Integrity Validation
* **Core Engine & Scale:** PostgreSQL 18 hosting 5,001 customers, 6,001 accounts, ~206,100 transactions, and ~406,200 double-entry ledger entries.
* **Key Invariants:** Immutable append-only double-entry journal (`ledger_entries`) where every debit has an equal credit ($\sum \text{amount} = 0$). Uses `NUMERIC(19,4)` for exact financial calculations.
* **Security & Integrity:** PCI-DSS compliance via PAN masking (no raw CVVs/PINs), schema-enforced idempotency (`idempotency_key UNIQUE`), and defensive referential integrity (`ON DELETE RESTRICT`).
* **Evidence:** Complete DDL scripts, 3NF/BCNF formal decomposition proofs with 4 controlled denormalisations, ER diagram, and 11 constraint validation tests in [portfolio-1-database-design/README.md](./portfolio-1-database-design/README.md).

### 3.2 Portfolio 2: Query Optimisation & Performance Tuning
* **Core Engine:** PostgreSQL 18 Cost-Based Optimizer (`EXPLAIN (ANALYZE, BUFFERS)`).
* **Focus:** Profiling 10 queries (Q01–Q10) across unindexed and indexed states on the high-volume transaction ledger.
* **Key Achievements:** Deployed composite B-tree indexes, partial indexes targeting active pending transactions (`WHERE status = 'PENDING'`), and covering indexes (`INCLUDE`). Reduced shared buffer page hits by over **95%**, collapsing query latencies from hundreds of milliseconds to sub-millisecond execution times.
* **Evidence:** Detailed EXPLAIN plans, before-and-after benchmark tables, and graphical execution trees in [portfolio-2-query-optimisation/README.md](./portfolio-2-query-optimisation/README.md).

### 3.3 Portfolio 3: Transactions, Concurrency Control & Isolation
* **Core Engine:** PostgreSQL 18 Concurrency Control Manager.
* **Focus:** Preventing lost updates, dirty reads, and transaction deadlocks during concurrent P2P transfers.
* **Key Achievements:** Solved cyclic deadlock dependencies mathematically by enforcing global account lock acquisition order via `LEAST(sender_id, receiver_id)` and `GREATEST(sender_id, receiver_id)` in `SELECT ... FOR UPDATE` blocks. Benchmarked `READ COMMITTED` vs `REPEATABLE READ`, and executed multi-client `pgbench` stress tests proving zero deadlocks and 100% balance conservation.
* **Evidence:** Concurrency scripts, deadlock graphs, rollback verification, and stress test logs in [portfolio-3-transactions-concurrency/README.md](./portfolio-3-transactions-concurrency/README.md).

### 3.4 Portfolio 4: NoSQL & Polyglot Persistence Architecture
* **Core Engine:** MongoDB Atlas 8.0 Cloud Cluster & PostgreSQL 18 Core.
* **Focus:** Managing polymorphic KYC identity documents, security audit trails, and automated session lifecycles.
* **Key Achievements:** Enforced strict BSON `$jsonSchema` validators on `kyc_profiles` and `audit_events` (negative tests rejected with `code 121`). Built 4 analytical aggregation pipelines (including cross-collection `$lookup` join). Constructed compound indexes (`idx_audit_customer_ts`, `idx_audit_type_ts`) and unique constraints (`uq_kyc_customer`), converting full collection scans into direct index scans (`IXSCAN`, 50x speedup). Configured a 1-hour automated TTL index on `login_sessions`.
* **Evidence:** BSON schema definitions, aggregation scripts, explain plans, and live Atlas logs in [portfolio-4-nosql/README.md](./portfolio-4-nosql/README.md).

### 3.5 Portfolio 5: Distributed & Cloud Database Architectures
* **Core Engine:** PostgreSQL 17 Physical Streaming Replication Cluster (Docker) & MongoDB Atlas Cloud.
* **Focus:** High availability (HA), physical streaming replication, synchronous vs. asynchronous commit modes, failover promotion, and read latency variance.
* **Key Achievements:** Configured Primary (`Port 5433`) and Standby (`Port 5434`) nodes with dedicated replication slots (`equitypay_standby_slot`) and `pg_walreceiver`. Dissected the physical `SyncRep` IPC wait event. Simulated primary failure and executed zero-data-loss standby promotion via `pg_promote()`. Implemented declarative RANGE and LIST table partitioning. Built a multithreaded Python harness measuring p50, p90, p95, and p99 read latencies under write contention.
* **Evidence:** Replication configs, failover transcripts, partitioning plans, and latency graphs in [portfolio-5-distributed-cloud/README.md](./portfolio-5-distributed-cloud/README.md).

---

## 4. Architectural Data Divisions: Polyglot Matrix

The foundational engineering standard established in this master portfolio is:  
> **"PostgreSQL owns the money; MongoDB owns the customer context."**

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

- **Relational Engines:** PostgreSQL 18 (Local) & PostgreSQL 17 (Containerized Primary/Standby)
- **Document Engine:** MongoDB Atlas 8.0 Cloud Cluster (Managed 3-node Replica Set)
- **Containerization:** Docker & Docker Compose (v2.20+)
- **Client Tools:** `psql` (PostgreSQL CLI), `mongosh` (MongoDB Shell v2.14+)
- **Scripting & Benchmarking:** Python 3.10+ (`psycopg2-binary`, `numpy`, `tabulate`), Node.js (v20.x LTS), Bash / PowerShell 7+

---

## 6. Global Reproduction Guide

All portfolios are structured for independent verification from the repository root:

### 1. Database Design & Seeding (Portfolio 1)
```bash
psql -U equitypay -d equitypay_db -f portfolio-1-database-design/01_schema.sql
psql -U equitypay -d equitypay_db -f portfolio-1-database-design/02_seed_data.sql
psql -U equitypay -d equitypay_db -f portfolio-1-database-design/03_validation_suite.sql
```

### 2. Query Optimisation & Explain Plans (Portfolio 2)
```bash
psql -U equitypay -d equitypay_db -f portfolio-2-query-optimisation/01_capture_plans.sql
psql -U equitypay -d equitypay_db -f portfolio-2-query-optimisation/03_create_indexes.sql
```

### 3. Concurrency & Deadlock Stress Testing (Portfolio 3)
```bash
psql -U equitypay -d equitypay_db -f portfolio-3-transactions-concurrency/01_function_test.sql
psql -U equitypay -d equitypay_db -f portfolio-3-transactions-concurrency/02_isolation_experiments.sql
```

### 4. NoSQL & Document Perimeter (Portfolio 4)
```bash
export MONGODB_URI=$(cat portfolio-4-nosql/.env | grep MONGODB_URI | cut -d= -f2-)
mongosh "$MONGODB_URI" --file portfolio-4-nosql/01_schema_validation.js
mongosh "$MONGODB_URI" --file portfolio-4-nosql/02_seed_data.js
mongosh "$MONGODB_URI" --file portfolio-4-nosql/03_crud_and_aggregation.js
mongosh "$MONGODB_URI" --file portfolio-4-nosql/04_indexes_explain.js
```

### 5. Distributed Replication & Cloud Audit (Portfolio 5)
```bash
docker compose -f portfolio-5-distributed-cloud/docker-compose.yml up -d
psql -h localhost -p 5433 -U equitypay -d equitypay_db -f portfolio-5-distributed-cloud/01_primary_checks.sql
psql -h localhost -p 5434 -U equitypay -d equitypay_db -f portfolio-5-distributed-cloud/02_replica_checks.sql
mongosh "$MONGODB_URI" --file portfolio-5-distributed-cloud/04_atlas_cloud_check.js
python3 portfolio-5-distributed-cloud/05_read_latency_benchmark.py
```

---

## 7. Academic Integrity, Contributor Disclosure & AI-Use Declaration

All database schemas, queries, optimization indexes, benchmarking harnesses, and architectural documentation were designed and executed by **Chukwuebuka Azuh** (Student ID: 301906536) for **MIT 8103 Advanced Database Systems** at **Miva Open University**:

* **Synthetic Data:** All customer profiles, account numbers, BVNs, NINs, email addresses, and financial transaction records generated for EquityPay Financial Services Ltd. are 100% synthetic and fictitious. No real customer or banking data was used.
* **Workstation / Contributor Disclosure:** The alternative git contributor shown in earlier commits was as a result of the author's primary laptop encountering hardware faults during the project timeline, requiring a temporary workstation migration to finish up the portfolio deliverables.
* **AI Assistance:** Generative AI tools (Google DeepMind Antigravity / Gemini) were utilized as technical pair-programming assistants for drafting synthetic data generation scripts, catalog diagnostics, and markdown table formatting. All database designs, SQL constraints, transaction lock strategies, failover simulations, and benchmark evaluations were independently verified and executed by the author. A full academic bibliography and AI disclosure are provided in [`reference.md`](./reference.md) and [`FINAL_DOCUMENTATION.md`](./FINAL_DOCUMENTATION.md).
