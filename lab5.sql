

-- LabWork5
-- Name: Арсен Бекешов
-- Student ID: 24B030092


-- Part 1: CHECK Constraints

-- Task 1.1: employees table with CHECK constraints for age and salary
CREATE TABLE IF NOT EXISTS employees (
    employee_id    INTEGER,
    first_name     TEXT,
    last_name      TEXT,
    age            INTEGER CHECK (age BETWEEN 18 AND 65), -- ensures age is 18..65
    salary         NUMERIC CHECK (salary > 0)             -- salary must be positive
);

-- Valid inserts (should succeed)
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Ivan', 'Petrov', 25, 3000.00),
(2, 'Aida', 'Kassym', 45, 5000.50);

-- Invalid inserts (should violate CHECK constraints) - commented out
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES (3, 'TooYoung', 'User', 16, 1000.00);
--  -> Fails because age < 18 (violates age CHECK)
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES (4, 'NegativeSalary', 'User', 30, -50.00);
--  -> Fails because salary <= 0 (violates salary CHECK)

-- Task 1.2: products_catalog with named CHECK constraint valid_discount
CREATE TABLE IF NOT EXISTS products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
    )
);

-- Valid inserts
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(10, 'Notebook', 100.00, 80.00),
(11, 'Pen', 2.00, 1.50);

-- Invalid inserts (commented out)
-- INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES (12, 'Bad1', 0.00, 0.00);
--  -> Fails: regular_price > 0 violated.
-- INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES (13, 'Bad2', 10.00, 15.00);
--  -> Fails: discount_price < regular_price violated.

-- Task 1.3: bookings with multi-column CHECK (checkout after checkin) and num_guests
CREATE TABLE IF NOT EXISTS bookings (
    booking_id     INTEGER,
    check_in_date  DATE,
    check_out_date DATE,
    num_guests     INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date) -- ensures check-out is after check-in
);

-- Valid inserts
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(100, '2025-05-01', '2025-05-05', 2),
(101, '2025-06-10', '2025-06-11', 1);

-- Invalid inserts (commented out)
-- INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES (102, '2025-07-10', '2025-07-09', 2);
--  -> Fails: check_out_date > check_in_date violated.
-- INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES (103, '2025-08-01', '2025-08-02', 0);
--  -> Fails: num_guests BETWEEN 1 AND 10 violated.

-- Part 2: NOT NULL Constraints

-- Task 2.1: customers table with NOT NULLs
CREATE TABLE IF NOT EXISTS customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT NOT NULL,
    phone             TEXT,                -- nullable
    registration_date DATE NOT NULL
);

-- Valid inserts
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(1, 'ivan@example.com', '77001234567', '2025-01-10'),
(2, 'aida@example.kz', NULL, '2025-03-05'); -- phone can be NULL

-- Invalid inserts (commented out)
-- INSERT INTO customers (customer_id, email, phone, registration_date) VALUES (3, NULL, '77009998877', '2025-04-01');
--  -> Fails: email NOT NULL violated.
-- INSERT INTO customers (customer_id, email, phone, registration_date) VALUES (NULL, 'x@example.com', '77001112233', '2025-04-01');
--  -> Fails: customer_id NOT NULL violated.

-- Task 2.2: inventory combining constraints
CREATE TABLE IF NOT EXISTS inventory (
    item_id      INTEGER NOT NULL,
    item_name    TEXT    NOT NULL,
    quantity     INTEGER NOT NULL CHECK (quantity >= 0), -- quantity >= 0
    unit_price   NUMERIC NOT NULL CHECK (unit_price > 0), -- price > 0
    last_updated TIMESTAMP NOT NULL
);

-- Valid inserts
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(1, 'Screwdriver', 50, 5.50, NOW()),
(2, 'Hammer', 20, 10.00, NOW());

-- Invalid inserts (commented out)
-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES (3, 'BadQty', -5, 2.00, NOW());
--  -> Fails: quantity >= 0 violated.
-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES (4, 'Free', 10, 0.00, NOW());
--  -> Fails: unit_price > 0 violated.

-- Task 2.3: Testing NOT NULL
-- (Examples already provided above: successful complete records; commented invalid attempts try to insert NULLs.)

-- Part 3: UNIQUE Constraints

-- Task 3.1: users table with UNIQUE on username and email
CREATE TABLE IF NOT EXISTS users (
    user_id    INTEGER,
    username   TEXT UNIQUE,  -- single-column UNIQUE
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Valid inserts
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'ivan_p', 'ivan.p@example.com', NOW()),
(2, 'aida_k', 'aida.k@example.com', NOW());

-- Task 3.2: course_enrollments with multi-column UNIQUE (student_id, course_code, semester)
CREATE TABLE IF NOT EXISTS course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- Valid inserts
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 101, 'CS101', '2025S'),
(2, 102, 'CS101', '2025S');

-- Invalid insert (commented out) - duplicate combination
-- INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES (3, 101, 'CS101', '2025S');
--  -> Fails: UNIQUE(student_id, course_code, semester) violated.

-- Task 3.3: Named UNIQUE constraints on users
-- Recreate users table with named constraints (drop & recreate for demonstration)
DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    user_id    INTEGER,
    username   TEXT,
    email      TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

-- Insert initial rows
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'ivan_p', 'ivan.p@example.com', NOW()),
(2, 'aida_k', 'aida.k@example.com', NOW());

-- Invalid tests (commented out)
-- INSERT INTO users (user_id, username, email, created_at) VALUES (3, 'ivan_p', 'new@example.com', NOW());
--  -> Fails: unique_username violated (duplicate username).
-- INSERT INTO users (user_id, username, email, created_at) VALUES (4, 'new_user', 'aida.k@example.com', NOW());
--  -> Fails: unique_email violated (duplicate email).

-- Part 4: PRIMARY KEY Constraints

-- Task 4.1: departments with single-column PRIMARY KEY
CREATE TABLE IF NOT EXISTS departments (
    dept_id  INTEGER PRIMARY KEY, -- single-column PK
    dept_name TEXT NOT NULL,
    location  TEXT
);

-- Valid inserts
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'HR', 'Almaty'),
(2, 'IT', 'Astana'),
(3, 'Logistics', 'Uralsk');

-- Invalid attempts (commented out)
-- INSERT INTO departments (dept_id, dept_name, location) VALUES (2, 'Duplicate', 'City');
--  -> Fails: duplicate dept_id violates PRIMARY KEY uniqueness.
-- INSERT INTO departments (dept_id, dept_name, location) VALUES (NULL, 'NoID', 'City');
--  -> Fails: PRIMARY KEY cannot be NULL.

-- Task 4.2: Composite PRIMARY KEY for student_courses
CREATE TABLE IF NOT EXISTS student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id) -- composite PK
);

-- Valid inserts
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
(201, 301, '2025-02-01', 'A'),
(201, 302, '2025-02-01', 'B'),
(202, 301, '2025-02-02', 'A-');

-- Attempt duplicate composite PK (commented out)
-- INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES (201, 301, '2025-03-01', 'C');
--  -> Fails: duplicate (student_id, course_id) pair violates composite PRIMARY KEY.

-- Task 4.3: Comparison Exercise (documented as SQL comment)
-- 1. Difference between UNIQUE and PRIMARY KEY:
--    - PRIMARY KEY enforces uniqueness and NOT NULL (implicitly). UNIQUE enforces uniqueness but allows NULLs (unless NOT NULL also set).
--    - A table may have multiple UNIQUE constraints, but only one PRIMARY KEY.
-- 2. Single-column vs composite PRIMARY KEY:
--    - Use single-column when a single attribute uniquely identifies a row (e.g., dept_id).
--    - Use composite when uniqueness requires multiple attributes together (e.g., student_id + course_id in enrollments).
-- 3. Why only one PRIMARY KEY but multiple UNIQUE:
--    - PRIMARY KEY represents the main identifier for table rows (singular concept). UNIQUE constraints are additional uniqueness rules and one table can have many.

-- Part 5: FOREIGN KEY Constraints

-- Task 5.1: Basic foreign key - employees_dept referencing departments
CREATE TABLE IF NOT EXISTS employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Valid insert: dept_id exists
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(1, 'Sergey', 2, '2024-10-01'),
(2, 'Mariya', 1, '2025-02-15');

-- Invalid insert (commented out): non-existent dept_id
-- INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES (3, 'Ghost', 999, '2025-05-01');
--  -> Fails: foreign key violation (no department with dept_id = 999).

-- Task 5.2: Library schema with multiple foreign keys
CREATE TABLE IF NOT EXISTS authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE IF NOT EXISTS publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

CREATE TABLE IF NOT EXISTS books (
    book_id         INTEGER PRIMARY KEY,
    title           TEXT NOT NULL,
    author_id       INTEGER REFERENCES authors(author_id),
    publisher_id    INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn            TEXT UNIQUE
);

-- Sample data for authors
INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'Gabriel Garcia Marquez', 'Colombia'),
(2, 'Fyodor Dostoevsky', 'Russia'),
(3, 'Aynur S.', 'Kazakhstan');

-- Sample data for publishers
INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'ClassicPub', 'Almaty'),
(2, 'Novella', 'Moscow');

-- Sample data for books
INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(1, 'One Hundred Years of Solitude', 1, 1, 1967, '978-0-06-088328-7'),
(2, 'Crime and Punishment', 2, 2, 1866, '978-0-14-044913-6'),
(3, 'Local Tales', 3, 1, 2020, 'ISBN-LOCAL-0001');

-- Task 5.3: ON DELETE options demonstration
CREATE TABLE IF NOT EXISTS categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
    -- ON DELETE RESTRICT: prevents deletion of referenced category if products exist
);

CREATE TABLE IF NOT EXISTS orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity   INTEGER CHECK (quantity > 0)
    -- ON DELETE CASCADE on order_id: deleting order removes its items
);

-- Insert sample category and product
INSERT INTO categories (category_id, category_name) VALUES (10, 'Electronics');
INSERT INTO products_fk (product_id, product_name, category_id) VALUES (1000, 'Power Bank', 10);

-- Test scenarios (comments describe expected behavior)
-- 1) Try to delete category that has products -> should fail due to RESTRICT
--    Example (commented): DELETE FROM categories WHERE category_id = 10;
--    -> Fails: ON DELETE RESTRICT prevents deletion because products_fk references category.
-- 2) Insert order and order_items, then delete order -> order_items should be deleted (CASCADE)
INSERT INTO orders (order_id, order_date) VALUES (500, '2025-09-01');
INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES (1, 500, 1000, 2);

-- Verify cascade:
-- DELETE FROM orders WHERE order_id = 500;
-- After deletion, SELECT * FROM order_items WHERE order_id = 500; should return 0 rows because of CASCADE.

-- Part 6: Practical Application (E-commerce)

-- Design and implement complete e-commerce schema per requirements.

-- customers (customer_id, name, email, phone, registration_date)
DROP TABLE IF EXISTS ecommerce_order_details;
DROP TABLE IF EXISTS ecommerce_orders;
DROP TABLE IF EXISTS ecommerce_products;
DROP TABLE IF EXISTS ecommerce_customers;

CREATE TABLE IF NOT EXISTS ecommerce_customers (
    customer_id       SERIAL PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE, -- UNIQUE constraint on customer email
    phone             TEXT,
    registration_date DATE NOT NULL
);

-- products (product_id, name, description, price, stock_quantity)
CREATE TABLE IF NOT EXISTS ecommerce_products (
    product_id     SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    price          NUMERIC NOT NULL CHECK (price >= 0),         -- non-negative price
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0) -- non-negative stock
);

-- orders (order_id, customer_id, order_date, total_amount, status)
CREATE TABLE IF NOT EXISTS ecommerce_orders (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES ecommerce_customers(customer_id) ON DELETE RESTRICT,
    order_date   DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status       TEXT NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
    -- status restricted to allowed set
);

-- order_details (order_detail_id, order_id, product_id, quantity, unit_price)
CREATE TABLE IF NOT EXISTS ecommerce_order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES ecommerce_orders(order_id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES ecommerce_products(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0), -- quantity positive
    unit_price      NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Insert at least 5 sample records per table

-- ecommerce_customers (5 rows)
INSERT INTO ecommerce_customers (name, email, phone, registration_date) VALUES
('Ivan Petrov', 'ivan.petrov@example.com', '77001234567', '2025-01-10'),
('Aida Kassym', 'aida.kassym@example.com', '77007654321', '2025-02-14'),
('Nurbol N.', 'nurbol.n@example.com', NULL, '2025-03-01'),
('Dana A.', 'dana.a@example.com', '77009990011', '2025-04-20'),
('Olzhas T.', 'olzhas.t@example.com', '77001112233', '2025-05-15');

-- ecommerce_products (5 rows)
INSERT INTO ecommerce_products (name, description, price, stock_quantity) VALUES
('Wireless Mouse', 'Ergonomic wireless mouse', 15.99, 100),
('Mechanical Keyboard', 'RGB mechanical keyboard', 59.90, 50),
('USB-C Cable', '1m fast charge cable', 4.50, 200),
('Bluetooth Speaker', 'Portable speaker', 29.99, 30),
('Laptop Stand', 'Aluminum adjustable stand', 24.99, 25);

-- ecommerce_orders (5 rows)
-- For realistic totals, calculate manually. These customers are existing above.
INSERT INTO ecommerce_orders (customer_id, order_date, total_amount, status) VALUES
(1, '2025-09-01', 41.98, 'pending'),
(2, '2025-09-02', 59.90, 'processing'),
(3, '2025-09-03', 4.50, 'shipped'),
(4, '2025-09-04', 54.98, 'delivered'),
(5, '2025-09-05', 29.99, 'cancelled');

-- ecommerce_order_details (at least five details across orders)
INSERT INTO ecommerce_order_details (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 2, 15.99),  -- order 1: 2 x Wireless Mouse = 31.98 (total stored as 41.98 above intentionally maybe includes shipping)
(2, 2, 1, 59.90),  -- order 2: Mechanical Keyboard
(3, 3, 1, 4.50),   -- order 3: USB-C Cable
(4, 5, 2, 24.99),  -- order 4: 2 x Laptop Stand = 49.98
(5, 4, 1, 29.99);  -- order 5: Bluetooth Speaker (cancelled)

