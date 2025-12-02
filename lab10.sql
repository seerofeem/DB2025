--3.2
-- a) Alice = 900.00, Bob = 600.00
-- b) For both operations to be atomic and to not violate the balance
-- c) Money should be taken from Alice, but Bob will not recieve it - data loss

--3.3
-- a) after update: 500.00
-- b) after rollback: 1000.00
-- c) user error, wrong data, system problems

--3.4
-- a)Alice = 900.00, Bob = 500.00, Wally = 850.00
-- b) Balance of Bob would be increased, but replaced with rollback to the savepoint
-- c) Gives the opportunity to rollback changes without restarting the transaction

-- 3.5
-- a) read committed: before commit: Coke + Pepsi ; after commit: only Fanta
-- b) Serializable: terminal 1 can see only output data; changes of terminal 2 will not be seen until the end of transaction
-- c) read commited able to see new commits of other transactions; serializable blocks the appearing of new versions of data

-- 3.6
-- a) No, REPEATABLE READ returns the same set of strings
-- b) New strings creation, that obeys to the same condition
-- c) SERIALIZABLE

-- 3.7
-- a) Yes, terminal 1 sees 99.99. Problem: you can see data that will be rollbacked
-- b) Reading of data that are not committed yet
-- c) Because it may lead to inconsistency of data

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);


--4.1
BEGIN;

SELECT balance INTO STRICT bob_balance
FROM accounts WHERE name = 'Bob'
FOR UPDATE;

IF bob_balance >= 200 THEN
    UPDATE accounts SET balance = balance - 200 WHERE name = 'Bob';
    UPDATE accounts SET balance = balance + 200 WHERE name = 'Wally';
    COMMIT;
ELSE
    ROLLBACK;
END IF;


--4.2
BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Test', 'TempItem', 10.00);

SAVEPOINT sp1;

UPDATE products SET price = 12.00
WHERE product = 'TempItem';

SAVEPOINT sp2;

DELETE FROM products WHERE product = 'TempItem';

ROLLBACK TO sp1;

COMMIT;


--4.3
--t1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;
--t2
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;

--4.4
--w/o transaction
SELECT MAX(price) FROM Sells WHERE shop='A';
-- concurrent DELETE or UPDATE
SELECT MIN(price) FROM Sells WHERE shop='A';
--w/ transaction
BEGIN;
SELECT MAX(price), MIN(price)
FROM Sells WHERE shop='A';
COMMIT;

--5. Self-Assessment Answers

--Atomicity: Either the entire purchase of the reservation goes through, or it doesn't.
--Consistency: the sum of all balances is saved.
--Isolation: The changes are not visible to others before the commit.
--Durability: Data will not disappear after a failure.

--COMMIT commits the changes, ROLLBACK cancels them.

--When you need to cancel only part of the transaction.

--READ UNCOMMITTED < READ COMMITTED < REPEATABLE READ < SERIALIZABLE.

--Dirty read — reading uncompressed data.
--Allows READ UNCOMMITTED.

--Non—repeatable reading - the values change during repeated reading.

--Phantom read — new lines appear.
--Prevents SERIALIZABLE.

--Because SERIALIZABLE greatly reduces performance.

--They ensure correctness with simultaneous changes.

--All uncomplicated changes are rolled back.
