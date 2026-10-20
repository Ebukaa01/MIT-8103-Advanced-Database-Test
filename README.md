# MIT8103: Advanced Database Systems

**Case Study**: EquityPay Financial Services Ltd. (Simulated Digital Banking & Payments Infrastructure)

---

## Portfolio Modules

| Module | Topic | Status | Link |
| :--- | :--- | :--- | :--- |
| **Portfolio 1** | **Database Design, Implementation & Integrity Validation** | **Completed** | [Portfolio 1 README](portfolio-1-database-design/README.md) |
| **Portfolio 2** | Query Optimisation & Performance Tuning | Pending | [Portfolio 2](portfolio-2-query-optimisation/) |
| **Portfolio 3** | Transactions, Concurrency Control & Isolation | Pending | [Portfolio 3](portfolio-3-transactions-concurrency/) |
| **Portfolio 4** | NoSQL & Polyglot Persistence | Pending | [Portfolio 4](portfolio-4-nosql/) |
| **Portfolio 5** | Distributed & Cloud Database Architectures | Pending | [Portfolio 5](portfolio-5-distributed-cloud/) |

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
