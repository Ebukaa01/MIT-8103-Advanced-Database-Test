# MIT 8103 Advanced Database Systems — Master Portfolio

**Student Name:** Chukwuebuka Azuh  
**Student ID:** 301906536  
**Course:** MIT 8103 Advanced Database Systems  
**Session:** 2026/2027 Academic Session (September Cohort)  
**Programme:** Master of Information Technology (MIT)  
**Institution:** Miva Open University — School of Post Graduate Studies  
**Assessment Type:** Individual Practical Database Portfolio (40 Marks Continuous Assessment)  
**Case Study Organisation:** EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)  
**GitHub Repository:** https://github.com/Ebukaa01/MIT-8103-Advanced-Database-Test  

---

## 1. Executive Summary & Case Study Overview

**EquityPay Financial Services Ltd. (EPFS)** is a simulated digital banking platform and payment service provider operating within the Nigerian financial ecosystem. EquityPay handles retail customer deposits, peer-to-peer (P2P) transfers, merchant card settlements, and interbank transaction clearing.

This repository serves as the comprehensive, five-part practical database engineering master portfolio for **MIT 8103 Advanced Database Systems**. It demonstrates relational database design, cost-based query optimization, transactional ACID guarantees, polyglot persistence, and high-availability distributed architecture:

* **Authoritative Relational Core:** PostgreSQL 18 enforcing an append-only double-entry ledger invariant ($\sum \text{amount} = 0$), fixed-point currency representation (`NUMERIC(19,4)`), strict BCNF normalisation with documented denormalisations, network idempotency guards, and pessimistic row locking (`FOR UPDATE`).
* **Targeted Indexing & CBO Tuning:** Composite B-Tree, GIN, and partial indexes eliminating costly sequential scans across high-volume transaction workloads (~206,100 transactions and ~406,200 ledger entries).
* **Concurrent Concurrency Control:** Strict lock-acquisition ordering preventing circular deadlocks, write-skew anomaly mitigation under `SERIALIZABLE` isolation, and `pgbench` stress testing under multi-client concurrency.
* **Polyglot Persistence Model:** MongoDB document store managing polymorphic identity tiers, unstructured audit logs, and automatic session purging via TTL indexes, integrated with PostgreSQL using the Transactional Outbox Pattern.
* **Distributed Cloud & Disaster Recovery:** PostgreSQL streaming replication with physical replication slots, connection-level read-routing, declarative range/hash partitioning, and automated backup/restore drills validating RTO $< 5$ minutes and RPO $= 0$.

---

## 2. Portfolio Structure & Deliverables

All 5 core portfolios and university-mandated synthesis documents are 100% completed, empirically verified, and reproducible:

| Portfolio | Domain & Focus | Weight | Status | Primary Documentation & Code |
| :--- | :--- | :---: | :---: | :--- |
| **Portfolio 1** | Database Design, Implementation & Integrity Validation | 7 Marks | Completed ✅ | [Portfolio 1 README](./portfolio-1-database-design/README.md) · Schema DDL · Normalisation (3NF/BCNF) · ERD |
| **Portfolio 2** | Query Optimisation & Performance Tuning | 7 Marks | Completed ✅ | [Portfolio 2 README](./portfolio-2-query-optimisation/README.md) · EXPLAIN ANALYZE Metrics · 10 SQL Queries · Index Scripts |
| **Portfolio 3** | Transactions, Concurrency Control & Isolation | 7 Marks | Completed ✅ | [Portfolio 3 README](./portfolio-3-transactions-concurrency/README.md) · ACID SQL Scripts · Isolation Analysis · `pgbench` Stress Test |
| **Portfolio 4** | NoSQL & Polyglot Persistence | 7 Marks | Completed ✅ | [Portfolio 4 README](./portfolio-4-nosql/README.md) · JSON Schema Validation · Transactional Outbox · `mongosh` Scripts |
| **Portfolio 5** | Distributed & Cloud Database Architectures | 6 Marks | Completed ✅ | [Portfolio 5 README](./portfolio-5-distributed-cloud/README.md) · Streaming Replication · Partitioning · HA & Recovery Drill |
| **Synthesis** | Governance, Ethics & Synthesis Report | 6 Marks | Completed ✅ | Executive Synthesis · Academic AI Declaration · References · Edge Case Matrix |

---

## 3. Detailed Portfolio Overview

### Portfolio 1: Database Design and Modelling (Completed ✅)
* **Core Engine & Scale:** PostgreSQL 18 hosting 5,001 customers, 6,001 accounts, ~206,100 transactions, and ~406,200 double-entry ledger entries.
* **Key Invariants:** Immutable append-only double-entry journal (`ledger_entries`) where every debit has an equal credit. Uses `NUMERIC(19,4)` for exact financial calculations.
* **Security & Integrity:** PCI-DSS compliance via PAN masking (no raw CVVs/PINs), schema-enforced idempotency (`idempotency_key UNIQUE`), and defensive referential integrity (`ON DELETE RESTRICT`).
* **Evidence:** Complete DDL scripts, 3NF/BCNF formal decomposition proofs with 4 controlled denormalisations, and rendered ERD diagrams.

### Portfolio 2: Query Processing and Optimisation (Completed ✅)
* **Workload:** 10 production SQL queries profiling account statements, balance summaries, audit tracking, and financial reconciliation.
* **Cost-Based Optimisation:** Full `EXPLAIN (ANALYZE, BUFFERS)` benchmarking captured before and after introducing B-Tree, partial, and composite indexes.
* **Quantified Results:** Drastic reduction in query execution latencies and aggregate query planner costs across all 10 production query families.

### Portfolio 3: Transactions and Concurrency Control (Completed ✅)
* **ACID Guarantees:** Multi-statement atomic transfers with automated rollback on insufficient funds and idempotency replay prevention.
* **Concurrency & Deadlock Prevention:** Enforced primary key lock acquisition ordering (`ORDER BY account_id`) preventing cyclic deadlocks during concurrent inter-account transfers.
* **Stress Validation:** Multi-client `pgbench` stress test executing hundreds of concurrent transactions with zero deadlocks and 100% ledger balance verification.

### Portfolio 4: NoSQL and Advanced Data Models (Completed ✅)
* **Polyglot Strategy:** MongoDB integrated alongside PostgreSQL using the Transactional Outbox Pattern for microservice decoupled events.
* **Document Collections:** Strict `$jsonSchema` validation for Tier 1–3 KYC profiles (`kyc_profiles`), polymorphic event logs (`audit_events`), and session tokens auto-purged via TTL indexes (`login_sessions`).
* **Aggregations:** Evaluated multi-stage aggregation pipelines for customer analytics and audited execution performance using `explain("executionStats")`.

### Portfolio 5: Distributed and Cloud Databases (Completed ✅)
* **High Availability Topology:** PostgreSQL 16/18 streaming replication utilizing physical replication slots with zero WAL byte lag.
* **Failover & Read Routing:** Automated standby promotion via `pg_ctl promote` paired with a Node.js connection router enforcing sub-second replication lag SLOs.
* **Partitioning & Recovery:** Declarative date-range and hash partitioning on high-volume tables, backed by automated point-in-time recovery (PITR) scripts confirming RTO $< 5$ minutes and RPO $= 0$.

---


## 4. Technology Stack

* **Relational Database Management System:** PostgreSQL 18 / PostgreSQL 16
* **Document / NoSQL Database Management System:** MongoDB 7.0 Community Edition / MongoDB Atlas
* **Query Languages:** SQL (PostgreSQL Dialect: CTEs, Window Functions, DDL, DML), MongoDB Query Language (MQL)
* **Benchmarking & Performance Tuning:** `pgbench`, PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)`
* **Scripting & Automation:** Bash (`/bin/bash`), Node.js (ES6 Modules)
* **Data Modelling & Visualisation:** diagrams.net / draw.io, Mermaid.js
* **Version Control:** Git, GitHub



## 5. Repository Directory Layout

```text
mit-8103-advanced-database-portfolio/
├── README.md                                     # Root repository navigation and executive summary
├── Azuh_Chukwuebuka_README.txt                   # LMS submission manifest and index file
├── docs/                                         # Portfolio governance, cross-cutting specs & synthesis
│   ├── final-executive-summary.md                # Final synthesis executive report
│   ├── ai-use-declaration.md                     # Academic AI assistance declaration & ethical disclosure
│   ├── references.md                             # Academic bibliography (IEEE / Harvard style)
│   ├── edge-case-test-matrix.md                  # Scenario edge-case constraint verification matrix
│   └── business-rules.md                         # Core banking system business rules
├── diagrams/                                     # Architecture & Entity Relationship Diagrams
│   ├── Azuh_Chukwuebuka_301906536_ERD.png        # Exported high-resolution ERD image
│   └── Azuh_Chukwuebuka_301906536_ERD.drawio     # Editable vector source ERD
├── portfolio-1-database-design/                  # Portfolio 1: Relational Design, Normalisation & Schema
│   ├── README.md                                 # Portfolio 1 specification and guide
│   ├── sql/                                      # DDL, seed data, and constraint test scripts
│   └── evidence/                                 # Schema dictionary & execution outputs
├── portfolio-2-query-optimisation/               # Portfolio 2: Query Processing & CBO Optimisation
│   ├── README.md                                 # Portfolio 2 execution overview
│   ├── performance-results.md                    # Detailed EXPLAIN plan metrics before & after indexes
│   ├── queries/                                  # 10 production SQL query files (Q01 - Q10)
│   └── sql/                                      # Index creation scripts
├── portfolio-3-transactions-concurrency/         # Portfolio 3: Transactions, ACID & Concurrency Control
│   ├── README.md                                 # Portfolio 3 guide and prerequisites
│   ├── concurrency-analysis.md                   # Anomaly analysis & deadlock prevention proofs
│   ├── sql/                                      # Transaction SQL scripts (Exercises A–G)
│   └── scripts/                                  # pgbench stress test harness
├── portfolio-4-nosql/                            # Portfolio 4: NoSQL, Document Models & Schema Validation
│   ├── README.md                                 # Portfolio 4 architecture and execution order
│   ├── nosql-model-design.md                     # JSON Schema rules & collection designs
│   └── scripts/                                  # mongosh validation, seed, and query scripts
└── portfolio-5-distributed-cloud/                # Portfolio 5: Distributed, High-Availability & Cloud
    ├── README.md                                 # Portfolio 5 replication & failover guide
    ├── replication-and-failover.md               # Streaming replication setup & promotion playbook
    ├── sharding-partitioning.md                  # Partitioning & sharding architecture design
    └── scripts/                                  # Connection router simulator & backup/restore drill

```


 ## 6. Academic Integrity & AI Use Declaration
 
 All database schemas, queries, optimization indexes, benchmarking harnesses, and architectural documentation were designed and executed by Chukwuebuka Azuh (Student ID: 301906536) for MIT 8103 Advanced Database Systems at Miva Open University.Synthetic Data: 
All customer profiles, account numbers, BVNs, NINs, email addresses, and financial transaction records generated for Equity Pay Financial Services Ltd. are 100% synthetic and fictitious. No real customer data was used. AI Assistance: Generative AI tools were utilized as technical pair-programming assistants for drafting synthetic data generation scripts and markdown table formatting. All database designs, SQL constraints, transaction lock strategies, and benchmark evaluations were independently verified and executed by the author. A full disclosure is provided in docs/ai-use-declaration.md.

---

## 7. Current Project Status

Portfolio Milestone	Target Marks	|Completion Status	Evidence & Test Verification
Portfolio 1: Database Design and Modelling	7 Marks	Completed (100%) ✅	All 6 tables created; 11 constraint tests passing; 3NF/BCNF proven; ERD exported.
Portfolio 2: Query Processing and Optimisation	7 Marks	Completed (100%) ✅	10 queries profiled; B-tree/partial indexes created; EXPLAIN ANALYZE benchmarks recorded.
Portfolio 3: Transactions and Concurrency Control	7 Marks	Completed (100%) ✅	ACID exercises A–G verified; deadlock-free lock ordering; 10-client pgbench test (500 txns).
Portfolio 4: NoSQL and Advanced Data Models	7 Marks	Completed (100%) ✅	3 collections validated; 30,000 synthetic documents; 4 aggregation pipelines; TTL index active.
Portfolio 5: Distributed and Cloud Databases	6 Marks	Completed (100%) ✅	Streaming replication active; failover drill passed; read-routing simulator; RTO < 5m backup drill.
Synthesis & Submission Deliverables	6 Marks	Completed (100%) ✅	Final Executive Report, AI Declaration, Bibliography, and LMS submission folder ready.
Total Continuous Assessment Scope	40 Marks	ALL COMPLETED (100%) ✅	Full Academic Requirements Satisfied
