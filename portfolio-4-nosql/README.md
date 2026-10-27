# MIT 8103: Advanced Database Systems
## Portfolio 4: NoSQL & Polyglot Persistence Architecture
### Case Study: EquityPay Financial Services Ltd.

**Candidate**: Ebuka  
**Database Systems**: PostgreSQL 18 (Relational Core) & MongoDB Atlas (Document Perimeter)  

---

## 1. Executive Overview

In enterprise financial technology, modern digital banking platforms cannot be architected as monolithic single-database systems. A single storage paradigm cannot simultaneously optimize for the mathematically rigid, zero-tolerance guarantees of a double-entry financial ledger and the high-velocity, polymorphic demands of customer identity verification and real-time audit logging.

**Portfolio 4** explores **Polyglot Persistence** within **EquityPay Financial Services Ltd.**, establishing a complementary architecture between:

1. **PostgreSQL 18 (The System of Record / Ledger Core)**:
   - Manages customers, accounts, double-entry bookkeeping journals (`ledger_entries`), and transactional money movement.
   - Prioritizes strict ACID compliance, declarative referential integrity, and mathematical balance conservation.
2. **MongoDB Atlas (The Operational & Telemetry Perimeter)**:
   - Manages tiered KYC identity document portfolios (`kyc_profiles`), append-only security telemetry (`audit_events`), and ephemeral token caches (`login_sessions`).
   - Prioritizes schema polymorphism, nested document modeling, high-throughput time-series ingestion, and automated data lifecycle management via TTL indexes.

---

## 2. Directory Structure

```
portfolio-4-nosql/
├── 01_schema_validation.js      # Collection creation & BSON JSON Schema validation rules
├── 02_seed_data.js              # High-performance batch seeding (5,000 KYC profiles & 100,000 audit events)
├── 03_crud_and_aggregation.js   # Rich CRUD queries, nested document updates, and 4 aggregation pipelines
├── 04_indexes_explain.js        # Compound, unique, and TTL indexes with explain('executionStats') evaluation
├── README.md                    # In-depth architectural analysis (SQL vs. NoSQL) and execution guide
├── output/                      # Raw execution evidence logs
│   ├── 03_crud_and_aggregation.txt
│   └── 04_indexes_explain.txt
└── screenshots/                 # Atlas and terminal execution captures
```

---

## 3. Deep Architectural Analysis: SQL (PostgreSQL) vs. Document NoSQL (MongoDB)

| Architectural Dimension | PostgreSQL 18 (Relational) | MongoDB Atlas (Document NoSQL) | Optimal Role in EquityPay |
| :--- | :--- | :--- | :--- |
| **Data Model** | Normalized tabular relations (3NF/BCNF) | Hierarchical JSON/BSON documents | Core Ledger vs. Customer Perimeter |
| **Consistency Model** | Immediate Consistency (ACID) | Tunable Consistency (ACID $\leftrightarrow$ BASE) | Balance Integrity vs. High-Volume Audit |
| **Transaction Scope** | Multi-table atomic transactions by default | Single-document atomic; multi-document via sessions | Monetary transfers vs. Telemetry ingestion |
| **Schema Governance** | Strict, compile-time catalog DDL | Dynamic schema with optional `$jsonSchema` | Fixed currency fields vs. Polymorphic KYC |
| **Relationships** | Declarative foreign keys (`ON DELETE RESTRICT`) | Application-level `$lookup` or embedding | Audited entity graphs vs. Self-contained docs |
| **Scaling Strategy** | Vertical scaling + read replication | Horizontal sharding across replica sets | Bounded ledger rows vs. Unbounded event logs |

---

### 3.1 ACID Guarantees & Multi-Document Transactions

- **PostgreSQL**:
  - ACID is the foundational engine assumption. Every `BEGIN ... COMMIT` block guarantees that mutations across multiple tables (`accounts`, `transactions`, `ledger_entries`) either commit in whole or cleanly roll back.
  - Concurrency is governed by multi-version concurrency control (MVCC) and deterministic pessimistic row locking (`SELECT ... FOR UPDATE`).
  - Cross-account transfers maintain global resource ordering (`LEAST()` and `GREATEST()` primary keys), eliminating deadlocks mathematically.

- **MongoDB**:
  - Single-document writes are always atomic (even when modifying deeply nested arrays like `documents: []`).
  - While MongoDB introduced multi-document transactions in version 4.0, distributed transactions across shards incur significant latency penalties, require multi-phase commit coordination across WiredTiger storage engines, consume heavy write cache memory, and enforce a strict 60-second transaction lifetime limit.
  - In a fintech ledger, relying on distributed MongoDB transactions for high-frequency peer-to-peer transfers introduces severe lock escalation risks and unpredictable abort rates during shard rebalancing.

---

### 3.2 Joins vs. Embedding & Denormalization

- **Relational Joins (PostgreSQL)**:
  - Relations are fully normalized to eliminate data redundancy and update anomalies.
  - The database engine optimizes joins using sophisticated cost-based algorithms (Hash Joins, Merge Joins, Index Nested Loops).
  - Referential integrity is declaratively enforced by the database engine: you cannot delete a customer who has open accounts (`ON DELETE RESTRICT`).

- **Embedding & `$lookup` (MongoDB)**:
  - In MongoDB, relationships that are retrieved together are stored together. A customer's KYC profile embeds their verification documents (BVN, NIN, Passport, Utility Bill) directly inside an array of subdocuments.
  - Fetching a customer profile requires a single seek (`_id: 1` or `customer_id: 1`), eliminating expensive relational joins completely.
  - While `$lookup` provides left-outer-join functionality (as demonstrated in `03_crud_and_aggregation.js`), it performs join resolution at the query execution level without declarative constraints: MongoDB cannot natively prevent orphaned audit events if a customer document is deleted.

---

### 3.3 Schema Rigidity vs. Schema Flexibility

- **PostgreSQL (Strict Rigidity)**:
  - Requires predefined schemas, data types, and check constraints (`CHECK (balance >= 0)`, `CHECK (account_number ~ '^[0-9]{10}$')`).
  - Altering tables in high-volume production requires careful lock management, migration scripts, and downtime planning.
  - **Fintech Benefit**: Mathematical precision (`NUMERIC(19,4)`) ensures rounding errors and invalid monetary states are rejected at the database driver level.

- **MongoDB (Governed Flexibility)**:
  - Accommodates polymorphic data without schema alterations. For example, Tier 1 customers submit only a BVN, whereas Tier 3 corporate customers submit international passports, business registration numbers, and utility bills.
  - Through `$jsonSchema` validation (implemented in `01_schema_validation.js`), EquityPay enforces strict regulatory compliance at the database level—rejecting invalid document types (`status: 'MAYBE'`) with `DocumentValidationFailure (code 121)` while retaining field-level extensibility for new identity document types.

---

### 3.4 Scalability & Performance Under Load

- **PostgreSQL**:
  - Excels at complex queries, sub-queries, and transactional writes within a single node or active-passive cluster.
  - High write throughput on a single ledger table eventually hits I/O write limits on disk serialization (WAL writer and checkpointing bottlenecks).

- **MongoDB**:
  - Architected natively for horizontal scale-out through replica sets and shard clusters.
  - For EquityPay’s `audit_events` collection (which ingests millions of authentication attempts, GPS locations, and payment telemetry per day), MongoDB's scale-out architecture allows writes to be partitioned across shards using a hashed shard key on `customer_id` or time-based chunking.

---

### 3.5 The Consistency Model: ACID vs. BASE

- **ACID (PostgreSQL)**:
  - **Atomicity**: All or nothing.
  - **Consistency**: Immediate transitions from one valid state to another.
  - **Isolation**: Serial execution guarantees without dirty reads or phantom writes.
  - **Durability**: Committed write-ahead logs (WAL) survive operating system or hardware crashes.

- **BASE (MongoDB)**:
  - **Basically Available**: High availability via replica sets with automated primary election.
  - **Soft State**: Nodes may experience replication lag before synchronization.
  - **Eventual Consistency**: Replicas converge on the primary's state over time.
  - While MongoDB supports `w: "majority"` and `readConcern: "linearizable"`, enabling full strong consistency across distributed nodes degrades write latency significantly, nullifying its raw throughput advantages.

---

## 4. Why You Would NOT Move the Ledger to MongoDB

A common architectural temptation is to unify the tech stack by moving the entire relational database into a document store. In an enterprise financial institution like EquityPay, **moving the double-entry accounting ledger to MongoDB would be an engineering and regulatory disaster**:

### 1. Inability to Enforce Cross-Collection Mathematical Invariants
In PostgreSQL, double-entry bookkeeping relies on multi-table check constraints and database-level triggers to guarantee that for every transaction:
$$\sum \text{Debits} - \sum \text{Credits} = 0.0000$$
MongoDB cannot enforce multi-document integrity constraints declaratively. If an application service crashes mid-transfer while writing to separate document collections, the database engine cannot natively guarantee that unbalanced money movement is prevented without complex, latency-heavy distributed two-phase commits.

### 2. Lack of Fixed-Point Monetary Arithmetic Guarantees
PostgreSQL natively enforces `NUMERIC(19,4)` with exact decimal arithmetic. While MongoDB supports the BSON `Decimal128` data type, JavaScript and standard client drivers frequently coerce numbers to IEEE 754 floating-point numbers (`Double`), introducing subtle rounding discrepancies that violate Central Bank of Nigeria (CBN) and IFRS-9 banking audit standards.

### 3. Vulnerability to Distributed Isolation Anomalies
In a sharded MongoDB cluster, accounts located on different shards require distributed transactions managed across multiple replica set primaries. Under high contention (such as flash sales or payroll runs hitting hot merchant accounts), distributed transactions suffer from write conflicts, lock wait timeouts, and transaction aborts, crippling transactional throughput compared to local PostgreSQL row-level locks.

### 4. Regulatory Auditability and Compliance (PCI-DSS & CBN)
Financial regulators mandate strict non-repudiation, tamper-evident write-ahead logging, and point-in-time recovery (PITR) with zero transaction loss. PostgreSQL’s write-ahead log (WAL) and linearizable transaction history provide an unimpeachable audit trail that document stores with eventual consistency cannot legally satisfy.

> **Architectural Conclusion**:  
> **PostgreSQL owns the money; MongoDB owns the customer context.**  
> Moving the ledger to MongoDB compromises the financial foundation of the bank. Conversely, forcing polymorphic KYC documents and multi-gigabyte audit event streams into PostgreSQL bloats the relational engine and degrades query planning. Polyglot persistence is the correct engineering standard.

---

## 5. How to Reproduce

All commands are executed from the repository root directory in PowerShell:

### Step 1: Deploy Collections & Schema Validation
```powershell
mongosh "$env:MONGODB_URI" --file portfolio-4-nosql/01_schema_validation.js
```
*Expected: Creates `kyc_profiles`, `audit_events`, `login_sessions` with JSON schema validation. Rejects invalid documents with `DocumentValidationFailure` (code 121).*

### Step 2: Batch Seed Data
```powershell
mongosh "$env:MONGODB_URI" --file portfolio-4-nosql/02_seed_data.js
```
*Expected: Seeds 5,000 KYC profiles and 100,000 audit events in structured memory batches.*

### Step 3: Execute CRUD Operations & Aggregation Pipelines
```powershell
mongosh "$env:MONGODB_URI" --file portfolio-4-nosql/03_crud_and_aggregation.js | Tee-Object portfolio-4-nosql/output/03_crud_and_aggregation.txt
```
*Expected: Demonstrates document insertion, nested `$elemMatch` array queries, `$push` updates, and 4 aggregation pipelines (including `$lookup` join).*

### Step 4: Index Optimization, Explain Plans & TTL
```powershell
mongosh "$env:MONGODB_URI" --file portfolio-4-nosql/04_indexes_explain.js | Tee-Object portfolio-4-nosql/output/04_indexes_explain.txt
```
*Expected: Benchmarks queries before and after compound indexing, validates unique index duplicate rejection, and configures a 1-hour TTL index on `login_sessions`.*

---

## 6. Key Empirical Findings

### 6.1 Index Optimization Analysis (`explain('executionStats')`)

| Query | Target Field(s) | Before Indexing (COLLSCAN) | After Indexing (IXSCAN) | Performance Improvement |
| :--- | :--- | :---: | :---: | :---: |
| **Q1 (Customer Audit Feed)** | `customer_id: 1, ts: -1` | 100,000 docs examined + In-Memory `SORT` | 20 keys examined (`IXSCAN > FETCH > LIMIT`) | **5,000x reduction in docs examined**; 0ms latency |
| **Q2 (Fraud Monitoring)** | `event_type: 1, ts: -1` | 100,000 docs examined | Exact matching fraud keys scanned | **Zero full collection scans** |
| **Q3 (KYC Profile Lookup)** | `customer_id: 1` (Unique) | 5,000 docs examined | Exactly 1 key examined | **5,000x faster point lookup** |

### 6.2 Data Lifecycle Automation
- **Time-To-Live (TTL) Index**: Enforcing `{ created_at: 1 }, { expireAfterSeconds: 3600 }` on `login_sessions` automates session expiration at the database engine level, removing the need for cron-based cleanup jobs while guaranteeing that permanent audit logs in `audit_events` remain untouched.
