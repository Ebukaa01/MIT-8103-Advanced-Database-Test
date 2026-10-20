# Case Study: EquityPay (Simulated Financial Banking System)

## Organisation / Scenario
**EquityPay Financial Services Ltd.** is a simulated next-generation Nigerian digital banking and financial technology institution. Operating under a modern neo-banking framework, EquityPay is designed to bridge the gap between traditional banking infrastructure and digital-first consumers. The platform provides real-time retail banking, merchant checkout solutions, peer-to-peer (P2P) transfers, multi-account digital wallets, card issuance (virtual and physical debit), and automated commercial payment processing for individuals, freelancers, and small-to-medium enterprises (SMEs).

Operating in an increasingly regulated digital financial environment (aligned with Central Bank of Nigeria [CBN] regulations and Nigeria Uniform Bank Account Standards [NUBAN]), EquityPay must adhere to rigorous regulatory compliance standards, including tiered Know-Your-Customer (KYC) onboarding, Anti-Money Laundering and Combating the Financing of Terrorism (AML/CFT) directives, and real-time fraud mitigation. 

To maintain market trust and regulatory licensure, EquityPay requires an enterprise-grade, highly reliable, and fault-tolerant relational database architecture. This system must handle high-throughput concurrent monetary transactions, guarantee zero data loss, eliminate floating-point rounding errors, preserve strict mathematical double-entry accounting integrity, and provide an immutable audit trail for every kobo that moves through the platform.

---

## Nature of the System
The EquityPay database is a mission-critical, online transaction processing (OLTP) relational database management system designed with strict adherence to **ACID** (Atomicity, Consistency, Isolation, Durability) principles:

- **Immutable Double-Entry Ledger Architecture**: Rather than relying purely on destructive balance updates, the system utilizes an append-only double-entry bookkeeping ledger (`ledger_entries`). Financial movements are recorded as discrete debit and credit postings that must balance across accounts, guaranteeing that funds are neither created nor destroyed arbitrarily.
- **High-Precision Financial Arithmetic**: All financial values are modeled using fixed-point arbitrary precision numeric data types (`NUMERIC(19, 4)`), strictly eliminating the rounding artifacts and precision loss inherent in floating-point representations (`FLOAT` or `REAL`).
- **Idempotent Transaction Pipeline**: Network timeouts, mobile app retries, and duplicate requests are mitigated using unique client-provided idempotency keys (`idempotency_key`), guaranteeing that a single financial intention cannot be executed more than once.
- **Relational Integrity & Selective Cascading**: The data model implements defensive referential integrity. Transient or user-owned peripheral address book entries (`beneficiaries`) utilize cascading deletes (`ON DELETE CASCADE`), while core financial entities, customer profiles, KYC records, accounts, completed transactions, ledger entries, and fraud flags are protected with strict deletion restrictions (`ON DELETE RESTRICT`) to preserve historical accounting records and prevent regulatory audit log destruction.
- **Embedded Regulatory & Risk Controls**: The database enforces business invariants directly at the schema layer through `CHECK` constraints, ensuring non-negative balances (`balance >= 0`), strict account number formatting (10-digit NUBAN regex), PCI-DSS compliant card storage (4-digit regex), legitimate transaction state transitions, and synchronized fraud risk scoring (0 to 100).

---

## Users of the Database
The EquityPay database serves a diverse set of human and automated actors across operational, compliance, financial, and customer-facing domains:

### 1. Retail Customers (Individuals)
- **Interface**: iOS/Android Mobile Banking Applications, Responsive Web Portal.
- **Access Scope**: Least-privilege access restricted strictly to their own accounts, cards, beneficiaries, and transaction data.
- **Key Actions**:
  - Register personal profiles and upload KYC verification documents (NIN, BVN, Driver's Licence, International Passport).
  - Provision digital naira wallets and generate unique 10-digit NUBAN account numbers.
  - Link and manage virtual and physical debit cards (tracking status across `ACTIVE`, `BLOCKED`, `EXPIRED`).
  - Check real-time wallet balances and view detailed historical transaction statements.
  - Execute peer-to-peer (P2P) transfers, bill payments, and deposits.
  - Save, manage, and delete frequent transaction payees (beneficiaries).

### 2. Commercial Clients (Merchants)
- **Interface**: Merchant Web Dashboard, Payment Gateway APIs, POS Terminals.
- **Access Scope**: Access to corporate profile, settlement accounts, customer payment webhooks, and sub-account ledger reports.
- **Key Actions**:
  - Accept commercial payments and customer checkouts with real-time settlement tracking.
  - Process customer refunds and transaction dispute reconciliations via linked reversal transactions.
  - Execute bulk vendor disbursements and staff payroll transfers.
  - Export cryptographic, tamper-evident financial ledger statements for tax and corporate accounting.

### 3. Customer Support Staff (Tier 1 & Tier 2)
- **Interface**: Internal Customer Relationship Management (CRM) Portal.
- **Access Scope**: Read-only access to customer profiles, account statuses, card states, transaction progress states, and ledger receipts. Sensitive data (e.g., full BVN/NIN numbers, card details) is masked.
- **Key Actions**:
  - Lookup customer profiles using email, phone number, or 10-digit account number.
  - Trace transaction lifecycles across `PENDING`, `COMPLETED`, `FAILED`, and `REVERSED` states to resolve user inquiries.
  - Diagnose failed transfers, explain declined transactions, and initiate formal reversal escalation tickets.

### 4. Compliance & AML/CFT Officers
- **Interface**: Compliance & Regulatory Monitoring Dashboard.
- **Access Scope**: Read and update permissions on identity verification queues (`kyc_records`) and risk triage tables (`fraud_flags`).
- **Key Actions**:
  - Review pending KYC submissions, validate identity document numbers against national registries, and transition statuses (`PENDING -> VERIFIED / REJECTED`).
  - Monitor automated fraud alerts and investigate flagged high-risk transactions filtered by `risk_score` (0 to 100).
  - Manage fraud flag resolution lifecycles (`OPEN -> UNDER_REVIEW -> CLEARED / CONFIRMED`).
  - Generate suspicious activity reports (SARs) and compliance audit extracts for external regulatory authorities (CBN / NFIU).

### 5. Internal Auditors & Financial Controllers
- **Interface**: Financial Analytics & Enterprise Ledger Reporting Console.
- **Access Scope**: Read-only, cross-table access across all historical accounts, transactions, and double-entry ledger entries.
- **Key Actions**:
  - Perform automated mathematical reconciliations verifying that account balance snapshots equal the algebraic sum of historical ledger debits and credits:
    $$\text{Balance} = \sum(\text{Credits}) - \sum(\text{Debits})$$
  - Inspect ledger balance snapshots (`balance_after`) to identify anomalies, race conditions, or unjournaled transactions.
  - Review transaction reversal lineages to ensure complete auditability of reversed funds.

### 6. Automated Core Banking Services & Daemons
- **Interface**: Backend Microservices, Message Brokers, Scheduled Cron Workers, Core Payment Switches.
- **Access Scope**: Service-level database roles with restricted read/write permissions per operational boundary.
- **Key Actions**:
  - **Transaction Orchestration Engine**: Manages the atomic lifecycle of payments, idempotency verification, and ledger posting within database transactions.
  - **Real-Time Fraud Engine**: Evaluates transaction velocity, anomalous transfer amounts, and device fingerprints, inserting automated records into `fraud_flags` with computed `risk_score` values.
  - **Reconciliation & Settlement Daemon**: Executes end-of-day ledger balancing, inter-bank clearing adjustments, and automated system reversals.
  - **Notification Dispatcher**: Reads completed transaction events to send real-time push notifications, SMS receipts, and email transaction alerts.

---

## Major Data Stored
The database schema models core financial entities, identity verification pipelines, card instruments, transaction ledgers, and risk management records:

```
+---------------------------------------------------------------------------------------------------+
|                                     EQUITYPAY DATA ARCHITECTURE                                   |
+---------------------------------------------------------------------------------------------------+
|  [customers]             Master identity records for Individuals and Merchants                    |
|       |                                                                                           |
|       +---> [kyc_records]        Tiered identity documents (BVN, NIN, Passport) with verifications|
|       +---> [accounts]           Digital naira wallets with NUBAN numbers and high-precision balances|
|       |          |                                                                                |
|       |          +---> [cards]   Physical and virtual cards (PCI-DSS compliant last-four storage) |
|       |                                                                                           |
|       +---> [beneficiaries]      Saved recipient address book (cascades on customer deletion)     |
|                                                                                                   |
|  [transactions]          Stateful payment intents with unique idempotency keys & reversal lineage  |
|       |                                                                                           |
|       +---> [ledger_entries]     Double-entry bookkeeping journal (DEBIT/CREDIT balance snapshots)|
|       +---> [fraud_flags]        Risk and AML investigation flags with normalized risk scores     |
+---------------------------------------------------------------------------------------------------+
```

### 1. Customer Profiles (`customers`)
- **Key Attributes**: `customer_id` (PK, Identity), `first_name`, `last_name`, `email` (Unique), `phone` (Unique), `customer_type` (`'INDIVIDUAL'`, `'MERCHANT'`), `status` (`'ACTIVE'`, `'SUSPENDED'`, `'CLOSED'`), `created_at` (Timestamptz).
- **Business Rationale**: Serves as the root entity for all identity ownership. Unique constraints on `email` and `phone` prevent duplicate onboarding, while `customer_type` check constraints enforce distinct operational profiles for individuals and corporate merchants.

### 2. KYC & Identity Verification Records (`kyc_records`)
- **Key Attributes**: `kyc_id` (PK, Identity), `customer_id` (FK to `customers`, `ON DELETE RESTRICT`), `id_type` (`'NIN'`, `'BVN'`, `'PASSPORT'`, `'DRIVERS_LICENCE'`), `id_number`, `verification_status` (`'PENDING'`, `'VERIFIED'`, `'REJECTED'`), `submitted_at`, `verified_at`.
- **Business Rationale**: Supports progressive, tiered KYC verification. A 1:N relationship allows customers to resubmit documents upon rejection. A database check constraint enforces that a verification timestamp (`verified_at`) can only exist once a submission leaves the `'PENDING'` state. Referential integrity (`ON DELETE RESTRICT`) prevents customer profile deletion from purging regulatory compliance records.

### 3. Accounts & Digital Wallets (`accounts`)
- **Key Attributes**: `account_id` (PK, Identity), `customer_id` (FK to `customers`, `ON DELETE RESTRICT`), `account_number` (CHAR(10), Unique), `currency` (CHAR(3), Default `'NGN'`), `balance` (`NUMERIC(19, 4)`, Default `0`), `status` (`'ACTIVE'`, `'FROZEN'`, `'CLOSED'`), `opened_at` (Timestamptz).
- **Business Rationale**: Represents the customer's digital wallet. The `account_number` constraint enforces strict 10-digit NUBAN compliance via regex (`CHECK (account_number ~ '^[0-9]{10}$')`). The balance is held as `NUMERIC(19, 4)` to guarantee exact fractional monetary accounting without floating-point rounding errors. A critical domain invariant `CHECK (balance >= 0)` guarantees that accounts can never enter an uncollateralized negative balance or unauthorized overdraft.

### 4. Saved Beneficiaries (`beneficiaries`)
- **Key Attributes**: `beneficiary_id` (PK, Identity), `customer_id` (FK to `customers`, `ON DELETE CASCADE`), `bank_name`, `account_number` (CHAR(10), regex verified), `account_name`.
- **Business Rationale**: Stores frequent counterparty details for rapid user transfers. Cascades on customer profile deletion (`ON DELETE CASCADE`) to maintain zero orphaned records for non-ledger metadata. A composite unique constraint `UNIQUE (customer_id, bank_name, account_number)` prevents duplicate payee records.

### 5. Cards & Payment Instruments (`cards`)
- **Key Attributes**: `card_id` (PK, Identity), `account_id` (FK to `accounts`, `ON DELETE RESTRICT`), `last_four` (CHAR(4), regex `^[0-9]{4}$`), `card_type` (`'DEBIT'`, `'VIRTUAL'`), `expiry_date` (Date), `status` (`'ACTIVE'`, `'BLOCKED'`, `'EXPIRED'`).
- **Business Rationale**: Enables card-based settlements while adhering to PCI-DSS standards by strictly storing only the last four digits and excluding sensitive authentication data (PAN, CVV, PIN).

### 6. Transactions & Payment Movements (`transactions`)
- **Key Attributes**: `transaction_id` (PK, Identity), `idempotency_key` (VARCHAR(64), Unique), `txn_type` (`'DEPOSIT'`, `'WITHDRAWAL'`, `'TRANSFER'`, `'BILL_PAYMENT'`, `'REVERSAL'`), `status` (`'PENDING'`, `'COMPLETED'`, `'FAILED'`, `'REVERSED'`), `amount` (`NUMERIC(19, 4)`, `CHECK (amount > 0)`), `reference`, `reversal_of` (Self-referential FK to `transactions`, `ON DELETE RESTRICT`), `initiated_at`, `completed_at`.
- **Business Rationale**: Captures the operational intent and outcome of money movement. The unique `idempotency_key` protects against duplicate transaction submissions caused by mobile app retries or network drops. The self-referencing foreign key `reversal_of` linked with a conditional check constraint enforces transaction lineage: transactions marked as `'REVERSAL'` must reference the original transaction ID, whereas standard transactions cannot carry a reversal reference (`CHECK ((txn_type = 'REVERSAL') = (reversal_of IS NOT NULL))`). Deletions on referenced transactions are strictly prohibited via `ON DELETE RESTRICT`.

### 7. Double-Entry Accounting Ledger (`ledger_entries`)
- **Key Attributes**: `entry_id` (PK, Identity), `transaction_id` (FK to `transactions`, `ON DELETE RESTRICT`), `account_id` (FK to `accounts`, `ON DELETE RESTRICT`), `direction` (`'DEBIT'`, `'CREDIT'`), `amount` (`NUMERIC(19, 4)`, `CHECK (amount > 0)`), `balance_after` (`NUMERIC(19, 4)`, `CHECK (balance_after >= 0)`), `created_at`.
- **Business Rationale**: Acts as the immutable, authoritative journal of financial truth. Every financial transfer produces balanced debit and credit entries. The composite constraint `UNIQUE (transaction_id, account_id, direction)` strictly prevents duplicate ledger postings for the same transaction event. The `balance_after` field stores an unalterable snapshot of the account balance immediately following ledger posting, allowing point-in-time balance reconstruction and audit verification. Deletions are guarded by `ON DELETE RESTRICT`.

### 8. Fraud & Risk Incident Flags (`fraud_flags`)
- **Key Attributes**: `flag_id` (PK, Identity), `transaction_id` (FK to `transactions`, `ON DELETE RESTRICT`), `reason` (VARCHAR(200)), `risk_score` (SMALLINT, `CHECK (risk_score BETWEEN 0 AND 100)`), `status` (`'OPEN'`, `'UNDER_REVIEW'`, `'CLEARED'`, `'CONFIRMED'`), `flagged_at`.
- **Business Rationale**: Provides real-time transaction risk scoring and investigation tracking. Flagged transactions are permanently tied to investigative audit records with quantitative risk ratings. Referential integrity protects flagged transaction history against accidental deletion (`ON DELETE RESTRICT`).

---

## Key Operations Supported
The EquityPay database supports high-integrity transactional and analytical operations:

### 1. Customer Onboarding & Progressive KYC Lifecycle
- Atomically register customer profiles with verified email and phone number uniqueness.
- Record multi-tier identity document submissions (`NIN`, `BVN`, `PASSPORT`, `DRIVERS_LICENCE`).
- Transition KYC verification statuses (`PENDING -> VERIFIED / REJECTED`) while enforcing that `verified_at` timestamps are synchronously populated only when verification concludes.
- Provision default NGN wallets upon KYC milestone approval.

### 2. NUBAN-Compliant Account Provisioning & Card Issuance
- Generate and allocate unique 10-digit account numbers verified against the NUBAN regular expression format (`^[0-9]{10}$`).
- Support multi-account ownership per customer (e.g., primary wallet, savings vault, merchant operational account).
- Issue PCI-DSS compliant virtual or physical debit cards linked directly to funding accounts.
- Initialize accounts at zero balance with non-negative balance constraint enforcement (`CHECK (balance >= 0)`).

### 3. Idempotent Deposit & Inflow Processing
- Ingest external payment gateway webhooks or direct bank transfers using a client-supplied `idempotency_key`.
- Verify key uniqueness to guarantee that network retries or repeated webhooks do not double-credit customer wallets.
- Atomically record a `COMPLETED` deposit transaction, create a single `CREDIT` entry in `ledger_entries`, and increment the account `balance`.

### 4. Intra-Bank Peer-to-Peer (P2P) Fund Transfers
- Execute seamless, real-time fund transfers between two EquityPay accounts within a single atomic database transaction (`BEGIN ... COMMIT`):
  1. Validate sender account status (`ACTIVE`) and verify sufficient balance (`balance >= transfer_amount`).
  2. Verify recipient account status (`ACTIVE`).
  3. Insert a transaction record with status `'COMPLETED'` and unique `idempotency_key`.
  4. Post a `DEBIT` entry in `ledger_entries` for the sender, deducting balance and capturing `balance_after`.
  5. Post a `CREDIT` entry in `ledger_entries` for the recipient, adding balance and capturing `balance_after`.
  6. Atomically update the sender and recipient balances in the `accounts` table.
  7. If any step fails or violates constraints (e.g., negative balance violation), rollback the entire transaction to guarantee zero discrepancy.

### 5. Automated Transaction Reversals & Dispute Remediation
- Process customer refund claims and failed inter-bank transfers through a controlled reversal mechanism.
- Create a new transaction of type `'REVERSAL'` that explicitly references the disputed or failed original transaction ID via `reversal_of`.
- Validate bidirectional check constraint (`CHECK ((txn_type = 'REVERSAL') = (reversal_of IS NOT NULL))`), preventing untraceable reversals or standard transactions carrying extraneous reversal keys.
- Post opposite compensating ledger entries (crediting the original sender and debiting the recipient if funds are available), preserving complete historical traceability without mutating historical ledger rows.

### 6. Continuous Balance Reconciliation & Ledger Auditing
- Execute real-time and end-of-day mathematical invariant audits across the banking ledger:
  $$\text{Current Account Balance} \equiv \sum_{\text{all entries}} (\text{CREDIT amounts}) - \sum_{\text{all entries}} (\text{DEBIT amounts})$$
- Validate that the recorded snapshot `balance_after` in each ledger entry corresponds exactly to the historical progression of prior entries.
- Detect any divergence between high-level cached balances and bottom-up ledger entries.

### 7. Fraud Detection, Risk Triage & Dispute Handling
- Flag anomalous, rapid-fire (velocity breach), or high-value transactions by inserting records into `fraud_flags` with a quantitative risk score (0–100) and initial state `'OPEN'`.
- Enable compliance officers to claim flagged incidents, transitioning status to `'UNDER_REVIEW'`.
- Resolve investigations as `'CONFIRMED'` (confirmed fraudulent activity, triggering account freeze and reversal) or `'CLEARED'` (clearing the transaction for normal processing).

### 8. Historical Statement Generation & Audit Trail Protection
- Produce chronological, tamper-evident bank account statements for customers and tax authorities by joining `transactions` and `ledger_entries`.
- Enforce strict deletion barriers (`ON DELETE RESTRICT`) across all completed transactions, accounts, cards, and ledger rows, ensuring that no administrative error or malicious action can purge financial history.
