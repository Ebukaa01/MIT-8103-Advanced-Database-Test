- Initial Valid Data Setup
INSERT INTO customers (first_name, last_name, email, phone, customer_type)
VALUES ('Ada', 'Obi', 'ada@example.com', '08011111111', 'INDIVIDUAL'),
       ('Bola', 'Ade', 'bola@example.com', '08022222222', 'INDIVIDUAL');

INSERT INTO accounts (customer_id, account_number, balance)
VALUES (1, '2200000001', 5000), (2, '2200000002', 100);

INSERT INTO transactions (idempotency_key, txn_type, status, amount)
VALUES ('key-1', 'TRANSFER', 'COMPLETED', 100);

INSERT INTO ledger_entries (transaction_id, account_id, direction, amount, balance_after)
VALUES (1, 1, 'DEBIT', 100, 4900), (1, 2, 'CREDIT', 100, 200);

-- Constraint Tests (Run each statement individually to capture expected errors)

-- 1. Unique email violation
INSERT INTO customers (first_name, last_name, email, phone, customer_type) 
VALUES ('Chi', 'Eze', 'ada@example.com', '08033333333', 'INDIVIDUAL');

-- 2. Invalid customer type check
INSERT INTO customers (first_name, last_name, email, phone, customer_type) 
VALUES ('Chi', 'Eze', 'chi@example.com', '08033333333', 'ROBOT');

-- 3. Negative account balance check
INSERT INTO accounts (customer_id, account_number, balance) 
VALUES (1, '2200000003', -1);

-- 4. Invalid account number length/format
INSERT INTO accounts (customer_id, account_number) 
VALUES (1, '22ABC00004');

-- 5. Foreign key violation on customer lookup
INSERT INTO accounts (customer_id, account_number) 
VALUES (999, '2200000005');

-- 6. Zero or negative transaction amount check
INSERT INTO transactions (idempotency_key, txn_type, amount) 
VALUES ('key-2', 'DEPOSIT', 0);

-- 7. Invalid reversal constraint violation
INSERT INTO transactions (idempotency_key, txn_type, amount, reversal_of) 
VALUES ('key-3', 'TRANSFER', 50, 1);

-- 8. Duplicate idempotency key unique constraint violation
INSERT INTO transactions (idempotency_key, txn_type, amount) 
VALUES ('key-1', 'DEPOSIT', 50);

-- 9. Invalid direction check in ledger entries
INSERT INTO ledger_entries (transaction_id, account_id, direction, amount, balance_after) 
VALUES (1, 1, 'REFUND', 10, 10);

-- 10. Duplicate transaction-account-direction unique constraint violation
INSERT INTO ledger_entries (transaction_id, account_id, direction, amount, balance_after) 
VALUES (1, 1, 'DEBIT', 50, 4850);

-- 11. ON DELETE RESTRICT protection on customers
DELETE FROM customers WHERE customer_id = 1;

-- 12. Pending KYC record verification time constraint violation
INSERT INTO kyc_records (customer_id, id_type, id_number, verified_at) 
VALUES (1, 'NIN', '12345678901', now());

-- ON DELETE CASCADE Test for Beneficiaries
INSERT INTO customers (first_name, last_name, email, phone, customer_type)
VALUES ('Dayo', 'Kuti', 'dayo@example.com', '08044444444', 'INDIVIDUAL');

INSERT INTO beneficiaries (customer_id, bank_name, account_number, account_name)
SELECT customer_id, 'GTBank', '0123456789', 'Ada Obi'
FROM customers WHERE email = 'dayo@example.com';

SELECT count(*) FROM beneficiaries; -- Should return 1
DELETE FROM customers WHERE email = 'dayo@example.com';
SELECT count(*) FROM beneficiaries; -- Should return 0 due to cascade delete

-- Clean up data for subsequent portfolios
TRUNCATE customers, transactions RESTART IDENTITY CASCADE;