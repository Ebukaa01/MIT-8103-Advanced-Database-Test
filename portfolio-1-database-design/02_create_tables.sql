
BEGIN;

--- -------------------------------- 
--- customers: individuals and merchants who own wallets
--- -----------------------------------
CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20)  NOT NULL UNIQUE,
    customer_type VARCHAR(20) NOT NULL,
    CHECK (customer_type IN ('Individual', 'Merchant')),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

--- ---------------------------------------------------------------
--- kyc_records: identify verfication submissions.
--- One customer can resubmit, so this is one-to-many
--- -----------------------------------------------------------
CREATE TABLE kyc_records (
    kyc_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  BIGINT NOT NULL
                 REFERENCES customers(customer_id) ON DELETE CASCADE,
    id_type      VARCHAR(30) NOT NULL,
                 CHECK (id_type IN ('NIN', 'BVN', 'DRIVERS_LICENSE', 'PASSPORT')),
    id_number    VARCHAR(50) NOT NULL,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                 CHECK (verification_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),       
    verified_at  TIMESTAMPTZ,
    --- a record can only have a verification time once it is no longer pending
    CHECK  (verified_at IS NULL OR verification_status <> 'PENDING')
);

--- -----------------------------------------------------------------------
--- accounts: equity wallets, balance is a sum total of the ledger.
--- NUMERIC (never FLOAT) aviods rounding errors on money 
--- -----------------------------------------------
CREATE TABLE accounts (
    account_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     BIGINT NOT NULL
                    REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number  CHAR(10) NOT NULL UNIQUE
                    CHECK (account_number ~ '^[0-9]{10}$'),
    currency        CHAR(3) NOT NULL DEFAULT 'NGN'
    balance         NUMERIC(19, 4) NOT NULL DEFAULT 0,
                    CHECK (balance >= 0),
    status          VARCHAR(20) NOT NULL DEFAULT 'active',
                    CHECK (status IN ('active', 'inactive'))
);

--- -----------------------------------------------------------------------
--- transactions: money movement between accounts
--- -----------------------------------------------------------
CREATE TABLE transactions (
    transaction_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idempotency_key  VARCHAR(100) NOT NULL UNIQUE,
                     REFERENCES accounts(account_id) ON DELETE CASCADE,
    txn_type         VARCHAR(30) CHECK (txn_type IN ('PENDING', 'COMPLETED', 'FAILED')) NOT NULL,               
    status           VARCHAR(20) CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED')) NOT NULL,               
    amount           NUMERIC(19, 4) CHECK (amount >= 0) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL
    reversal_of      BIGINT REFERENCES transactions(transaction_id) ON DELETE RESTRICT ,
    created_at       TIMESTAMPTZ WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transaction_check CHECK (
        (txn_type = 'REVERSAL' AND reversal_of IS NOT NULL AND) OR
        (txn_type <> 'REVERSAL' AND reversal_of IS NULL))
    )

--- -----------------------------------------------------------------------
--- ledger_entries: savings


CREATE TABLE ledger_entries(
    entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id      BIGINT NOT NULL
                    REFERENCES accounts(account_id) ON DELETE RESTRICT,
    transaction_id  BIGINT NOT NULL
                    REFERENCES transactions(transaction_id) ON DELETE RESTRICT,
    amount          NUMERIC(19, 4) 
                    CHECK (amount >=0) NOT NULL,
    direction       VARCHAR(10)   
                    CHECK (direction IN ('DEBIT', 'CREDIT')) NOT NULL,
    balance_after   NUMERIC(19, 4) 
                    CHECK (balance_after >= 0) NOT NULL,                
    created_at      TIMESTAMPTZ WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE   (transaction_id, account_id , direction)
);


--- Fruad_flags: many to many relationships between transactions and flags

CREATE TABLE fraud_flags (
    flag_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id  BIGINT NOT NULL
                    REFERENCES transactions(transaction_id) ON DELETE RESTRICT,
    reason          TEXT NOT NULL,                
    status          VARCHAR(20) 
                    CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'FALSE_POSITIVE')) DEFAULT 'OPEN' NOT NULL,
created_at          TIMESTAMPTZ WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
);
COMMIT;