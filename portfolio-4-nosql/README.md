# MIT 8103: Advanced Database Systems
## Portfolio 4: NoSQL & Polyglot Persistence Architecture
### Case Study: EquityPay Financial Services Ltd.

**Candidate**: Chukwuebuka Azuh  
**Student ID**: 301906536  
**Degree**: Master of Science in Information Technology (M.Sc. IT)  
**Database Systems**: PostgreSQL 18 (Relational Core) & MongoDB Atlas 8.0 (Document Perimeter)  

---

## 1. Executive Summary & Polyglot Architecture

Modern enterprise fintech platforms cannot survive on a monolithic single-database architecture. A single storage paradigm cannot simultaneously satisfy the mathematically rigid, zero-tolerance guarantees of a double-entry banking ledger and the high-velocity, polymorphic demands of customer onboarding (KYC), real-time fraud telemetry, and ephemeral session tracking.

**Portfolio 4** establishes and benchmarks a **Polyglot Persistence Architecture** for **EquityPay Financial Services Ltd.**, delegating responsibilities based on foundational engine strengths:

1. **PostgreSQL 18 (The System of Record / Ledger Core)**:
   - Manages customers, accounts, double-entry bookkeeping journals (`ledger_entries`), and transactional money movement.
   - Enforces strict ACID compliance, declarative referential integrity (`FOREIGN KEY ... ON DELETE RESTRICT`), and mathematical balance conservation ($\sum \text{Debits} - \sum \text{Credits} = 0.0000$).
2. **MongoDB Atlas 8.0 (The Operational & Telemetry Perimeter)**:
   - Manages tiered KYC identity document portfolios (`kyc_profiles`), append-only security telemetry (`audit_events`), and ephemeral token caches (`login_sessions`).
   - Prioritizes schema polymorphism, nested document modeling, high-throughput time-series ingestion, and automated data lifecycle management via TTL indexes.

```
                    +------------------------------------------------+
                    |             EquityPay API Gateway              |
                    +-----------------------+------------------------+
                                            |
                    +-----------------------+------------------------+
                    |                                                |
          [Financial Movements]                            [Identity & Telemetry]
                    |                                                |
                    v                                                v
    +-------------------------------+                +-------------------------------+
    |         PostgreSQL 18         |                |       MongoDB Atlas 8.0       |
    |      (System of Record)       |                |     (Perimeter & Streams)     |
    +-------------------------------+                +-------------------------------+
    | • accounts                    |                | • kyc_profiles                |
    | • transactions                |                | • audit_events                |
    | • ledger_entries              |                | • login_sessions              |
    |                               |                |                               |
    | Strict ACID & Foreign Keys    |                | Polymorphic BSON Documents    |
    | Exact NUMERIC(19,4) Math      |                | High-Throughput Ingestion     |
    | Row-Level MVCC Locking        |                | TTL Auto-Expiring Caches      |
    +-------------------------------+                +-------------------------------+
```

---

## 2. Architectural Data Divisions: PostgreSQL vs. MongoDB

The division of data between relational and document storage at EquityPay follows strict architectural boundaries:

| Data Entity | Primary Database | Storage Model | Justification & Architectural Boundary |
| :--- | :--- | :--- | :--- |
| **Accounts & Balances** | PostgreSQL 18 | Relational (3NF) | Zero tolerance for balance corruption. Requires database-level `CHECK (balance >= 0)` constraints and atomic serializability. |
| **Double-Entry Journal** | PostgreSQL 18 | Relational (3NF) | Strict mathematical invariant: $\sum \text{Debits} - \sum \text{Credits} = 0$. Enforced across multiple rows inside atomic `BEGIN ... COMMIT` blocks. |
| **Money Transfers** | PostgreSQL 18 | Relational (3NF) | Deterministic pessimistic row locks (`SELECT ... FOR UPDATE`) ordered by primary key (`LEAST()` / `GREATEST()`) to mathematically eliminate deadlocks. |
| **KYC Identity Profiles** | MongoDB Atlas | Document (`$jsonSchema`) | Polymorphic schema: Tier 1 customers provide only a BVN; Tier 3 customers submit passports, CAC business filings, and utility bills. Stored hierarchically without relational join bloat. |
| **Security Audit Events** | MongoDB Atlas | Append-Only Stream | High-ingestion telemetry (logins, IP geolocation, fraud triggers). Append-only design (`INSERT`, never `UPDATE` or `DELETE`) optimized for rapid writes and horizontal sharding. |
| **Session Cache** | MongoDB Atlas | Ephemeral Document | Short-lived auth tokens requiring automated time-based eviction via WiredTiger Time-To-Live (TTL) thread. |

---

## 3. Directory Structure & Execution Artifacts

```
portfolio-4-nosql/
├── 01_schema_validation.js      # Collection creation & BSON JSON Schema validation rules
├── 02_seed_data.js              # High-performance batch seeding (5,000 KYC profiles & 100,000 audit events)
├── 03_crud_and_aggregation.js   # Rich CRUD queries, nested document updates, and 4 aggregation pipelines
├── 04_indexes_explain.js        # Compound, unique, and TTL indexes with explain('executionStats') evaluation
├── docker-compose.yml           # Optional local containerized MongoDB 7 deployment configuration
├── .env.example                 # Environment configuration template
├── README.md                    # In-depth architectural analysis and empirical report
├── output/                      # Raw execution evidence logs
│   ├── 03_crud_and_aggregation.txt
│   └── 04_indexes_explain.txt
└── screenshots/                 # Terminal and Atlas verification evidence captures
    ├── Chukwuebuka_Azuh_301906536_schema_validation.png
    ├── Chukwuebuka_Azuh_301906536_seed_verification.png
    ├── Chukwuebuka_Azuh_301906536_CRUD.png
    ├── Chukwuebuka_Azuh_301906536_aggregation.png
    ├── Chukwuebuka_Azuh_301906536_explain metrics_session clearing.png
    └── Chukwuebuka_Azuh_301906536_directory.png
```

---

## 4. Collection Design & Schema Validation (`$jsonSchema`)

While MongoDB is inherently schema-flexible, financial identity data requires strict regulatory boundaries. In [`01_schema_validation.js`](01_schema_validation.js), EquityPay establishes governed flexibility using BSON `$jsonSchema` validators with `validationAction: 'error'`.

### 4.1 Schema Definitions

1. **`kyc_profiles`**:
   - **Fields**: `customer_id` (int, min 1), `tier` (int, 1–3), `status` (enum: `PENDING`, `VERIFIED`, `REJECTED`), `documents` (array of subdocuments), `created_at` (date).
   - **Document Structure**: Subdocuments require `type` (`BVN`, `NIN`, `PASSPORT`, `DRIVERS_LICENCE`, `UTILITY_BILL`) and `number` (string).
2. **`audit_events`**:
   - **Fields**: `customer_id` (int), `event_type` (enum: `LOGIN_SUCCESS`, `LOGIN_FAILED`, `PIN_CHANGED`, `TRANSFER_INITIATED`, `KYC_UPGRADED`, `FRAUD_FLAG`), `ts` (date), `details` (arbitrary JSON object).
3. **`login_sessions`**:
   - **Fields**: `customer_id` (int), `token` (string), `created_at` (date). Governed by a 3600-second TTL index.

### 4.2 Negative Validation Test
To verify that non-compliant documents cannot bypass the database perimeter, an intentionally invalid profile was submitted:

```javascript
nosql.kyc_profiles.insertOne({ customer_id: 1, status: 'MAYBE' });
```
- **Engine Response**: Immediately rejected with **`DocumentValidationFailure` (code `121`)**.
- **Security Implication**: Client-side validation bugs cannot compromise database integrity.

---

## 5. Aggregation Pipelines & Business Intelligence

In [`03_crud_and_aggregation.js`](03_crud_and_aggregation.js), four aggregation pipelines evaluate operational telemetry and link the document perimeter with customer relational identifiers:

### Pipeline 1: 30-Day Event Volume by Category
- **Business Intent**: Quantify platform activity and monitor authentication vs. money movement volume over the trailing 30 days.
- **Pipeline Architecture**:
  ```javascript
  [
    { $match: { ts: { $gte: new Date(Date.now() - 30 * 86400000) } } },
    { $group: { _id: '$event_type', events: { $sum: 1 } } },
    { $sort: { events: -1 } }
  ]
  ```
- **Live Output**:
  - `TRANSFER_INITIATED`: 8,294 events
  - `LOGIN_SUCCESS`: 8,190 events
  - `PIN_CHANGED`: 4,272 events
  - `KYC_UPGRADED`: 4,152 events
  - `FRAUD_FLAG`: 4,130 events
  - `LOGIN_FAILED`: 4,104 events

### Pipeline 2: Daily Transaction Volume Trend
- **Business Intent**: Calculate daily aggregate transfer counts and gross initiated volume in Naira (₦) for executive financial dashboards.
- **Pipeline Architecture**:
  ```javascript
  [
    { $match: { event_type: 'TRANSFER_INITIATED' } },
    { $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$ts' } },
        transfers: { $sum: 1 },
        total_amount: { $sum: '$details.amount' } } },
    { $sort: { _id: -1 } },
    { $limit: 5 }
  ]
  ```
- **Live Output**:
  - `2026-11-09`: 200 transfers, Total = ₦2,760,500
  - `2026-11-08`: 277 transfers, Total = ₦3,552,500
  - `2026-11-07`: 279 transfers, Total = ₦3,631,000
  - `2026-11-06`: 261 transfers, Total = ₦3,270,500
  - `2026-11-05`: 299 transfers, Total = ₦3,815,000

### Pipeline 3: Polyglot Left Outer Join (`$lookup`)
- **Business Intent**: Identify the top 5 customers experiencing repeated authentication failures and join their KYC profile to correlate fraud risk with verification status.
- **Pipeline Architecture**:
  ```javascript
  [
    { $match: { event_type: 'LOGIN_FAILED' } },
    { $group: { _id: '$customer_id', failed_logins: { $sum: 1 } } },
    { $sort: { failed_logins: -1, _id: 1 } },
    { $limit: 5 },
    { $lookup: { from: 'kyc_profiles', localField: '_id', foreignField: 'customer_id', as: 'kyc' } },
    { $unwind: '$kyc' },
    { $project: { _id: 0, customer_id: '$_id', failed_logins: 1, tier: '$kyc.tier', status: '$kyc.status' } }
  ]
  ```
- **Live Output**:
  ```json
  { "customer_id": 3,  "failed_logins": 20, "tier": 1, "status": "PENDING" }
  { "customer_id": 11, "failed_logins": 20, "tier": 1, "status": "VERIFIED" }
  { "customer_id": 19, "failed_logins": 20, "tier": 3, "status": "REJECTED" }
  { "customer_id": 27, "failed_logins": 20, "tier": 2, "status": "VERIFIED" }
  { "customer_id": 35, "failed_logins": 20, "tier": 2, "status": "VERIFIED" }
  ```

### Pipeline 4: Structural Document Density Analysis
- **Business Intent**: Evaluate regulatory onboarding completeness across tiers by computing average document submission count per tier.
- **Pipeline Architecture**:
  ```javascript
  [
    { $group: { _id: '$tier', customers: { $sum: 1 }, avg_documents: { $avg: { $size: '$documents' } } } },
    { $sort: { _id: 1 } }
  ]
  ```
- **Live Output**:
  - `Tier 1`: 2,500 customers | Average documents = **1.00** (BVN only)
  - `Tier 2`: 1,500 customers | Average documents = **2.00** (BVN + Passport / NIN)
  - `Tier 3`: 1,000 customers | Average documents = **3.00** (BVN + Passport + Utility Bill)

---

## 6. Empirical Index Optimization & Metrics Table

In [`04_indexes_explain.js`](04_indexes_explain.js), queries were profiled before and after index creation using MongoDB's `explain('executionStats')` on live datasets (100,000 `audit_events` and 5,000 `kyc_profiles`).

### 6.1 Before-and-After Metrics Table

| Query & Workload | Target Field(s) | Metric | Before Indexing | After Indexing | Optimization Factor |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Q1: Customer Audit Feed**<br>`audit_events.find({ customer_id: 1001 })`<br>`.sort({ ts: -1 }).limit(20)` | `customer_id: 1, ts: -1`<br>(Compound Index:<br>`idx_audit_customer_ts`) | **Plan Stages**<br>**Docs Examined**<br>**Keys Examined**<br>**Returned Docs**<br>**Execution Time** | `SORT > COLLSCAN`<br>100,000<br>0<br>20<br>**50 ms** | `LIMIT > FETCH > IXSCAN`<br>20<br>20<br>20<br>**1 ms** | **Eliminated in-memory sort**<br>**5,000x fewer docs examined**<br>0 wasted reads<br>**50x lower latency (98% reduction)** |
| **Q2: Fraud Monitoring**<br>`audit_events.find({ event_type: 'FRAUD_FLAG',`<br>`ts: { $gte: NOW - 7d } })` | `event_type: 1, ts: -1`<br>(Compound Index:<br>`idx_audit_type_ts`) | **Plan Stages**<br>**Docs Examined**<br>**Keys Examined**<br>**Returned Docs**<br>**Execution Time** | `COLLSCAN`<br>100,000<br>0<br>907<br>**43 ms** | `FETCH > IXSCAN`<br>907<br>907<br>907<br>**5 ms** | **Zero full collection scan**<br>**110x fewer docs examined**<br>1:1 key-to-doc precision<br>**8.6x lower latency (88% reduction)** |
| **Q3: KYC Profile Point Lookup**<br>`kyc_profiles.find({ customer_id: 2500 })` | `customer_id: 1`<br>(Unique Index:<br>`uq_kyc_customer`) | **Plan Stages**<br>**Docs Examined**<br>**Keys Examined**<br>**Returned Docs**<br>**Execution Time** | `COLLSCAN`<br>5,000<br>0<br>1<br>**4 ms** | `EXPRESS_IXSCAN`<br>1<br>1<br>1<br>**0 ms** | **Direct B-tree leaf lookup**<br>**5,000x fewer docs examined**<br>Sub-millisecond resolution<br>**Instantaneous lookup (< 1 ms)** |

### 6.2 Index Storage Footprint
Physical index overhead was extracted directly from WiredTiger engine statistics:
- **`audit_events`**: Data Size = **16.3 MB** | Total Index Size = **8.7 MB** across 3 indexes (`_id_`, `idx_audit_customer_ts`, `idx_audit_type_ts`).
- **`kyc_profiles`**: Data Size = **0.9 MB** | Total Index Size = **0.2 MB** across 2 indexes (`_id_`, `uq_kyc_customer`).

### 6.3 Unique Constraint Validation
To verify constraint enforcement on `uq_kyc_customer`:
```javascript
nosql.kyc_profiles.insertOne({ customer_id: 1, tier: 1, ... });
```
- **Engine Response**: Rejected with **`DuplicateKey` (code `11000`)**.
- **Significance**: Prevents duplicate customer profiles from corrupting the customer perimeter.

### 6.4 Automated Data Lifecycle: TTL Index on `login_sessions`
- **Configuration**: `{ created_at: 1 }, { expireAfterSeconds: 3600, name: 'ttl_session_1h' }`.
- **Engine Behavior**: WiredTiger's background TTL thread evaluates timestamps every 60 seconds, evicting expired tokens automatically without cron jobs or application-level housekeeping.
- **Architectural Distinction**: TTL indexes are strictly prohibited on `audit_events` because financial regulatory compliance (CBN & PCI-DSS) mandates permanent retention for forensic non-repudiation.

---

## 7. Deep Personal Analysis: Relational (SQL) vs. Document (NoSQL)

### 7.1 Concurrency Control & Isolation Semantics
In **PostgreSQL**, concurrency relies on Multi-Version Concurrency Control (MVCC) combined with deterministic row-level locks (`SELECT ... FOR UPDATE`). Every transaction operates within an explicit isolation boundary (`READ COMMITTED` or `REPEATABLE READ`). In EquityPay's ledger, double-entry journal entries must lock both the source and destination accounts simultaneously. By ordering account acquisitions using `LEAST()` and `GREATEST()` primary keys, PostgreSQL guarantees deadlock-free transfers under thousands of concurrent requests.

In **MongoDB**, single-document updates are atomic by default. Modifying nested arrays via `$push` or `$set` is thread-safe on a single document. However, cross-document operations rely on multi-document ACID transactions introduced in MongoDB 4.0. In a high-throughput financial system, multi-document transactions in MongoDB incur severe write-lock overhead across WiredTiger storage engines, consume significant cache memory, and enforce a strict 60-second execution window. Under high contention, MongoDB aborts conflicting transactions aggressively, creating unacceptable retry storms.

### 7.2 Why You Would NEVER Move the Ledger to MongoDB
A naive engineering temptation is to consolidate the technology stack into a single document database. In an enterprise financial institution like EquityPay, **migrating the double-entry accounting ledger to MongoDB would be an engineering and regulatory catastrophe**:

1. **Inability to Enforce Cross-Collection Mathematical Invariants**:
   In PostgreSQL, double-entry bookkeeping relies on multi-table check constraints and database-level triggers to guarantee that for every transaction:
   $$\sum \text{Debits} - \sum \text{Credits} = 0.0000$$
   MongoDB cannot enforce multi-document integrity constraints declaratively. If an application service crashes mid-transfer while writing to separate document collections, the database engine cannot natively guarantee that unbalanced money movement is prevented without complex, latency-heavy distributed two-phase commits.
2. **Lack of Fixed-Point Monetary Arithmetic Guarantees**:
   PostgreSQL natively enforces `NUMERIC(19,4)` with exact decimal arithmetic. While MongoDB supports the BSON `Decimal128` data type, JavaScript and standard client drivers frequently coerce numbers to IEEE 754 floating-point numbers (`Double`), introducing subtle rounding discrepancies that violate Central Bank of Nigeria (CBN) and IFRS-9 banking audit standards.
3. **Vulnerability to Distributed Isolation Anomalies**:
   In a sharded MongoDB cluster, accounts located on different shards require distributed transactions managed across multiple replica set primaries. Under high contention (such as flash sales or payroll runs hitting hot merchant accounts), distributed transactions suffer from write conflicts, lock wait timeouts, and transaction aborts, crippling transactional throughput compared to local PostgreSQL row-level locks.
4. **Regulatory Auditability and Compliance (PCI-DSS & CBN)**:
   Financial regulators mandate strict non-repudiation, tamper-evident write-ahead logging, and point-in-time recovery (PITR) with zero transaction loss. PostgreSQL’s write-ahead log (WAL) and linearizable transaction history provide an unimpeachable audit trail that document stores with eventual consistency cannot legally satisfy.

> **Architectural Standard**:  
> **PostgreSQL owns the money; MongoDB owns the customer context.**  
> Moving the ledger to MongoDB compromises the financial foundation of the bank. Conversely, forcing polymorphic KYC documents and multi-gigabyte audit event streams into PostgreSQL bloats the relational engine and degrades query planning. Polyglot persistence is the correct engineering standard.

---

## 8. Verification Evidence & Screenshot Index

All test stages were executed against MongoDB Atlas and captured as empirical visual evidence in [`portfolio-4-nosql/screenshots/`](screenshots/):

| Step | Evidence Artifact | Description |
| :---: | :--- | :--- |
| **01** | [`screenshots/Chukwuebuka_Azuh_301906536_schema_validation.png`](screenshots/Chukwuebuka_Azuh_301906536_schema_validation.png) | Successful deployment of JSON schema validators and rejection of invalid KYC documents with error code `121`. |
| **02** | [`screenshots/Chukwuebuka_Azuh_301906536_seed_verification.png`](screenshots/Chukwuebuka_Azuh_301906536_seed_verification.png) | Batch seeding verification displaying 5,000 `kyc_profiles` and 100,000 `audit_events` in MongoDB Atlas. |
| **03** | [`screenshots/Chukwuebuka_Azuh_301906536_CRUD.png`](screenshots/Chukwuebuka_Azuh_301906536_CRUD.png) | Execution of document creation, `$elemMatch` array queries, `$set`/`$push` updates, and clean demo deletions. |
| **04** | [`screenshots/Chukwuebuka_Azuh_301906536_aggregation.png`](screenshots/Chukwuebuka_Azuh_301906536_aggregation.png) | Terminal execution of all 4 analytical aggregation pipelines (event breakdown, daily volume, `$lookup` join, document sizes). |
| **05** | [`screenshots/Chukwuebuka_Azuh_301906536_explain metrics_session clearing.png`](screenshots/Chukwuebuka_Azuh_301906536_explain%20metrics_session%20clearing.png) | Detailed `explain('executionStats')` output before and after indexing, duplicate key rejection (code `11000`), and TTL setup. |
| **06** | [`screenshots/Chukwuebuka_Azuh_301906536_directory.png`](screenshots/Chukwuebuka_Azuh_301906536_directory.png) | Complete directory tree showing scripts, logs in `output/`, and screenshots. |

---

## 9. How to Reproduce

### Prerequisites
- Node.js (v20+) & `mongosh` installed.
- Valid MongoDB Atlas URI configured in `portfolio-4-nosql/.env`.

### Step-by-Step Execution

```bash
# 1. Export MongoDB Connection URI
export MONGODB_URI=$(cat portfolio-4-nosql/.env | grep MONGODB_URI | cut -d= -f2-)

# 2. Deploy Schema Validation Rules
mongosh "$MONGODB_URI" --file portfolio-4-nosql/01_schema_validation.js

# 3. Batch Seed Data (5,000 KYC Profiles & 100,000 Audit Events)
mongosh "$MONGODB_URI" --file portfolio-4-nosql/02_seed_data.js

# 4. Execute CRUD Operations & Aggregation Pipelines
mongosh "$MONGODB_URI" --file portfolio-4-nosql/03_crud_and_aggregation.js | tee portfolio-4-nosql/output/03_crud_and_aggregation.txt

# 5. Profile Indexes, Execution Plans & TTL Automation
mongosh "$MONGODB_URI" --file portfolio-4-nosql/04_indexes_explain.js | tee portfolio-4-nosql/output/04_indexes_explain.txt
```

*(On Windows PowerShell, use `$env:MONGODB_URI="mongodb+srv://..."` and pipe to `Tee-Object` as documented in step headers).*

---

## 10. Reflection & AI-Use Declaration

### 10.1 Engineering Reflection
Architecting and benchmarking Portfolio 4 has provided tangible clarity on the trade-offs of Polyglot Persistence. In classroom discussions, NoSQL is often presented either as a silver bullet that replaces "outdated" relational models or as an unprincipled store lacking integrity. Observing both engines operate side-by-side on EquityPay's data demonstrates that the two paradigms are complementary partners.

The most striking empirical lesson was observing the efficiency of compound B-Tree indexes in MongoDB. Prior to indexing, running a simple customer feed query scanned 100,000 documents and consumed 50 ms because the engine was forced to allocate an in-memory sort buffer. Constructing the compound index `{ customer_id: 1, ts: -1 }` enabled the engine to scan exactly 20 index keys and 20 documents, collapsing latency to 1 ms (a 50x speedup). Conversely, implementing `$lookup` revealed why document stores should not emulate relational databases: while functional, multi-stage `$lookup` queries require significant memory and lack the compile-time cost optimizations that PostgreSQL's Hash and Merge joins deliver natively.

### 10.2 AI-Use Declaration
In compliance with university academic integrity standards, AI assistance (Google DeepMind Antigravity / Gemini) was utilized as an intelligent pair-programming collaborator for:
- Formulating complex MongoDB aggregation pipeline syntax (`$lookup`, `$unwind`, `$dateToString`, `$size`).
- Drafting the compound index and explain plan analysis harness functions.
- Structuring Markdown documentation, comparative metrics tables, and LaTeX mathematical notations.

All MongoDB schemas, seeding operations, aggregation scripts, and index explain evaluations were executed live against an active MongoDB Atlas 8.0 cloud cluster. All empirical metrics, timing statistics, and screenshot captures represent authentic, verifiable experimental data.
