# MIT8103: Advanced Database Systems

**Case Study**: EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)

Student Name: Chukwuebuka Azuh

Student ID: 301906536

Course: MIT 8103 Advanced Database Systems

Session: 2026/2027 Academic Session (September Cohort)

Programme: Master of Information Technology (MIT)

Institution: Miva Open University — School of Post Graduate Studies

Assessment Type: Individual Practical Database Portfolio (40 Marks Continuous Assessment)

Case Study Organisation: EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)


---

## Portfolio Modules

| Module | Topic | Status | Link |
| :--- | :--- | :--- | :--- |
| **Portfolio 1** | **Database Design, Implementation & Integrity Validation** | **Completed** | [Portfolio 1 README](portfolio-1-database-design/README.md) |
| **Portfolio 2** | **Query Optimisation & Performance Tuning** | **Completed** | [Portfolio 2 README](portfolio-2-query-optimisation/README.md) |
| **Portfolio 3** | **Transactions, Concurrency Control & Isolation** | **Completed** | [Portfolio 3 README](portfolio-3-transactions-concurrency/README.md) |
| **Portfolio 4** | **NoSQL & Polyglot Persistence** | **Completed** | [Portfolio 4 README](portfolio-4-nosql/README.md) |
| **Portfolio 5** | **Distributed & Cloud Database Architectures** | **Completed** | [Portfolio 5 README](portfolio-5-distributed-cloud/README.md) |

---

## Portfolio 1 Overview

- **Core Engine**: PostgreSQL 18
- **Data Scale**: 5,001 customers, 6,001 accounts, ~206,100 transactions, ~406,200 double-entry ledger entries.
- **Key Engineering Highlights**:
  - Append-only immutable double-entry bookkeeping journal (`ledger_entries`).
  - Fixed-point currency arithmetic (`NUMERIC(19,4)`).
  - Schema-enforced network idempotency (`idempotency_key UNIQUE`).
  - Defensive referential integrity (`ON DELETE RESTRICT` vs `ON DELETE CASCADE`).
  - PCI-DSS card data minimization (masked PAN, no CVVs/PINs).
  - Formal normalisation through 3NF/BCNF with 4 controlled, documented denormalisations.
- **Full Documentation & Verification Suite**: See [portfolio-1-database-design/README.md](portfolio-1-database-design/README.md).
