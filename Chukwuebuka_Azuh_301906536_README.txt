MIT 8103 Advanced Database Systems — Continuous Assessment
Student Name: Chukwuebuka Azuh
Student ID: 301906536
Course: MIT 8103 Advanced Database Systems
Session: 2026/2027 Academic Session (September Cohort)
Institution: Miva Open University
Case Study: EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)
GitHub Repository: Ebukaa01/MIT-8103-Advanced-Database-Test: MIT CA Advanced database Test

================================================================================
SUBMISSION OVERVIEW
================================================================================
This submission folder contains the complete deliverables and empirical evidence for:
- Portfolio 1: Database Design and Modelling (7 Marks)
- Portfolio 2: Query Processing and Optimisation (7 Marks)
- Portfolio 3: Transactions and Concurrency (7 Marks)
- Portfolio 4: NoSQL and Advanced Data Models (7 Marks)
- Portfolio 5: Distributed and Cloud Databases (6 Marks)
- Final Submission Deliverables: Executive Summary Synthesis Report, Academic AI Declaration, and Bibliography

All files follow the required naming format: Surname_Firstname_StudentID_DocumentType
No spaces are used in any file or folder names.
The surname and firstname and studentid are Chukwuebuka_Azuh_301906536

================================================================================
CONTINUOUS ASSESSMENT MARKS BREAKDOWN (40 MARKS TOTAL)
================================================================================
| Portfolio Milestone                                | Marks    | Status          |
|----------------------------------------------------+----------+-----------------|
| Portfolio 1: Database Design and Modelling         | 7 Marks  | Completed (100%)|
| Portfolio 2: Query Processing and Optimisation     | 7 Marks  | Completed (100%)|
| Portfolio 3: Transactions and Concurrency          | 7 Marks  | Completed (100%)|
| Portfolio 4: NoSQL and Advanced Data Models        | 7 Marks  | Completed (100%)|
| Portfolio 5: Distributed and Cloud Databases       | 6 Marks  | Completed (100%)|
| Final Deliverables (Synthesis, AI Dec, References) | 6 Marks  | Completed (100%)|
| TOTAL CONTINUOUS ASSESSMENT SCOPE                  | 40 Marks | 100% COMPLETED  |

================================================================================
PORTFOLIO SUMMARY & KEY DELIVERABLES
================================================================================

1. PORTFOLIO 1: DATABASE DESIGN & MODELLING (7 MARKS)
   - Core Engine: PostgreSQL 18 (Relational Core)
   - Scale: 5,001 customers, 6,001 accounts, ~206,100 transactions, ~406,200 ledger entries.
   - Deliverables:
     * Chukwuebuka_Azuh_301906536_00_create_database.sql
     * Chukwuebuka_Azuh_301906536_01_verify_setup.sql
     * Chukwuebuka_Azuh_301906536_02_create_tables.sql
     * Chukwuebuka_Azuh_301906536_03_constraint_tests.sql
     * Chukwuebuka_Azuh_301906536_04_seed_data.sql
     * Chukwuebuka_Azuh_301906536_05_verify_seed.sql
     * Chukwuebuka_Azuh_301906536_P1_README.md
   - Engineering Highlights: Immutable append-only double-entry ledger journal,
     fixed-point NUMERIC(19,4) financial arithmetic, network idempotency constraints,
     PCI-DSS card data masking, 3NF/BCNF normalisation proofs with 4 controlled denormalisations.

2. PORTFOLIO 2: QUERY PROCESSING & OPTIMISATION (7 MARKS)
   - Core Engine: PostgreSQL 18 Cost-Based Optimizer
   - Deliverables:
     * Queries: Chukwuebuka_Azuh_301906536_q01_account_statement.sql through q09_join_fanout_trap.sql
     * SQL Plans: Chukwuebuka_Azuh_301906536_01_capture_plans.sql through 06_write_cost.sql
     * Chukwuebuka_Azuh_301906536_P2_README.md
   - Engineering Highlights: EXPLAIN (ANALYZE, BUFFERS) benchmarks across 10 analytical/OLTP queries,
     composite B-Tree indexes, partial indexes targeting active status ('PENDING'),
     covering indexes (INCLUDE clause), 95%+ reduction in buffer reads, sub-millisecond execution.

3. PORTFOLIO 3: TRANSACTIONS & CONCURRENCY (7 MARKS)
   - Core Engine: PostgreSQL 18 MVCC & Row-Level Locking
   - Deliverables:
     * Chukwuebuka_Azuh_301906536_01_transfer_function.sql
     * Chukwuebuka_Azuh_301906536_02_demo_setup.sql
     * Chukwuebuka_Azuh_301906536_03_commit_rollback_demo.sql
     * Chukwuebuka_Azuh_301906536_04_integrity_check.sql
     * Chukwuebuka_Azuh_301906536_05_idempotency.sql
     * Chukwuebuka_Azuh_301906536_06_insufficient_funds.sql
     * Chukwuebuka_Azuh_301906536_P3_README.md
   - Engineering Highlights: Mathematical elimination of deadlocks via global account ID ordering
     (LEAST and GREATEST in SELECT ... FOR UPDATE), MVCC isolation experiments (READ COMMITTED vs
     REPEATABLE READ), pgbench concurrent stress tests proving zero deadlocks and 100% balance integrity.

4. PORTFOLIO 4: NOSQL & ADVANCED DATA MODELS (7 MARKS)
   - Core Engine: MongoDB Atlas 8.0 Cloud Cluster & PostgreSQL 18 Core
   - Deliverables:
     * Chukwuebuka_Azuh_301906536_01_schema_validation.js
     * Chukwuebuka_Azuh_301906536_02_seed_data.js
     * Chukwuebuka_Azuh_301906536_03_crud_and_aggregation.js
     * Chukwuebuka_Azuh_301906536_04_indexes_explain.js
     * Chukwuebuka_Azuh_301906536_P4_README.md
   - Engineering Highlights: BSON $jsonSchema validation rules rejecting malformed documents with code 121,
     4 analytical aggregation pipelines (including cross-collection $lookup join), compound B-Tree indexes
     reducing query scans from 100,000 docs to 20 keys (50x speedup), 1-hour automated TTL index on login_sessions.

5. PORTFOLIO 5: DISTRIBUTED & CLOUD DATABASES (6 MARKS)
   - Core Engine: PostgreSQL 17 Physical Streaming Replication Cluster (Docker) & MongoDB Atlas Cloud
   - Deliverables:
     * Chukwuebuka_Azuh_301906536_01_primary_checks.sql
     * Chukwuebuka_Azuh_301906536_02_replica_checks.sql
     * Chukwuebuka_Azuh_301906536_03_partitioning.sql
     * Chukwuebuka_Azuh_301906536_04_atlas_cloud_check.js
     * Chukwuebuka_Azuh_301906536_P5_README.md
   - Engineering Highlights: Physical streaming replication with dedicated replication slot (equitypay_standby_slot),
     asynchronous vs synchronous replication profiling (SyncRep IPC wait event analysis), zero-data-loss standby
     promotion (pg_promote), declarative RANGE and LIST table partitioning, multithreaded read latency benchmark harness.

6. FINAL SYNTHESIS & GOVERNANCE DELIVERABLES (6 MARKS)
   - FINAL_DOCUMENTATION.md / Chukwuebuka_Azuh_FINAL_DOCUMENTATION.md: Full 2-3 page executive summary synthesis.
   - reference.md / REFERENCES.md: 45-entry comprehensive academic references and engineering bibliography.
   - README.md: Master repository index and technical documentation.

================================================================================
EVIDENCE & SCREENSHOT DIRECTORY MAP (56 SCREENSHOTS TOTAL)
================================================================================
All screenshot evidence files are formatted with the Chukwuebuka_Azuh_301906536_ prefix:
- portfolio-1-database-design/Screenshots/ (8 verification screenshots)
- portfolio-2-query-optimisation/screenshots/ (17 execution & plan screenshots)
- portfolio-3-transactions-concurrency/screenshots/ (14 concurrency & stress screenshots)
- portfolio-4-nosql/screenshots/ (6 validation, seed & explain screenshots)
- portfolio-5-distributed-cloud/screenshots/ (11 container, replication & failover screenshots)

================================================================================
ACADEMIC INTEGRITY & AI-USE DECLARATION
================================================================================
In compliance with Miva Open University academic regulations:
1. Synthetic Data: All customer profiles, accounts, BVNs, NINs, and transaction histories
   for EquityPay Financial Services Ltd. are 100% synthetic. No real customer data was used.
2. Contributor Note: The alternate git contributor in earlier commit history occurred due to
   a hardware fault on the student's primary laptop, necessitating temporary migration to a
   secondary workstation to complete the milestones.
3. AI Assistance: Generative AI tools (Google DeepMind Antigravity / Gemini) were utilized as
   pair-programming assistants for syntax drafting, catalog queries, and markdown formatting.
   All database architectures, SQL DDL/DML, transaction locking designs, failover drills,
   and benchmark evaluations were designed, executed, and validated by Chukwuebuka Azuh.

