-- =====================================================================
-- Laboratory Work 5: Database Constraints
-- Name:       Azimbekuly Nurdilda
-- Student ID: 25b031238
-- =====================================================================


-- =====================================================================
-- Part 1: CHECK Constraints
-- =====================================================================

-- Task 1.1: Basic CHECK Constraint
-- age must be between 18 and 65, salary must be positive
CREATE TABLE employees (
    employee_id INTEGER,
    first_name  TEXT,
    last_name   TEXT,
    age         INTEGER CHECK (age BETWEEN 18 AND 65),
    salary      NUMERIC CHECK (salary > 0)
);

-- Task 1.2: Named CHECK Constraint
-- valid_discount: both prices positive and discount lower than regular price
CREATE TABLE products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Task 1.3: Multiple Column CHECK
-- num_guests between 1 and 10; check_out_date must be after check_in_date
-- (the second CHECK compares two columns, so it is a table-level constraint)
CREATE TABLE bookings (
    booking_id     INTEGER,
    check_in_date  DATE,
    check_out_date DATE,
    num_guests     INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Task 1.4: Testing CHECK Constraints

-- employees: valid data
INSERT INTO employees VALUES (1, 'Arman', 'Akhmetov', 25, 350000);
INSERT INTO employees VALUES (2, 'Dina',  'Kassymova', 40, 500000);

-- employees: invalid data
-- INSERT INTO employees VALUES (3, 'Timur', 'Ospanov', 17, 300000);
-- ERROR: new row for relation "employees" violates check constraint "employees_age_check"
-- Reason: age 17 is less than 18

-- INSERT INTO employees VALUES (4, 'Saule', 'Abenova', 70, 300000);
-- ERROR: new row for relation "employees" violates check constraint "employees_age_check"
-- Reason: age 70 is greater than 65

-- INSERT INTO employees VALUES (5, 'Marat', 'Zhumabek', 30, 0);
-- ERROR: new row for relation "employees" violates check constraint "employees_salary_check"
-- Reason: salary must be greater than 0

-- products_catalog: valid data
INSERT INTO products_catalog VALUES (1, 'Laptop', 450000, 399000);
INSERT INTO products_catalog VALUES (2, 'Mouse',    8000,   6500);

-- products_catalog: invalid data
-- INSERT INTO products_catalog VALUES (3, 'Keyboard', 0, 5000);
-- ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"
-- Reason: regular_price must be greater than 0

-- INSERT INTO products_catalog VALUES (4, 'Monitor', 90000, -100);
-- ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"
-- Reason: discount_price must be greater than 0

-- INSERT INTO products_catalog VALUES (5, 'Headphones', 20000, 25000);
-- ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"
-- Reason: discount_price (25000) is not less than regular_price (20000)

-- bookings: valid data
INSERT INTO bookings VALUES (1, '2026-10-01', '2026-10-05', 2);
INSERT INTO bookings VALUES (2, '2026-11-10', '2026-11-12', 4);

-- bookings: invalid data
-- INSERT INTO bookings VALUES (3, '2026-10-01', '2026-10-03', 0);
-- ERROR: new row for relation "bookings" violates check constraint "bookings_num_guests_check"
-- Reason: num_guests must be at least 1

-- INSERT INTO bookings VALUES (4, '2026-10-01', '2026-10-03', 11);
-- ERROR: new row for relation "bookings" violates check constraint "bookings_num_guests_check"
-- Reason: num_guests must be at most 10

-- INSERT INTO bookings VALUES (5, '2026-10-05', '2026-10-01', 2);
-- ERROR: new row for relation "bookings" violates check constraint "bookings_check"
-- Reason: check_out_date is before check_in_date


-- =====================================================================
-- Part 2: NOT NULL Constraints
-- =====================================================================

-- Task 2.1: NOT NULL Implementation
-- phone is the only column that may be empty
CREATE TABLE customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT    NOT NULL,
    phone             TEXT,
    registration_date DATE    NOT NULL
);

-- Task 2.2: Combining Constraints
-- every column is required; quantity can be 0 but not negative, price must be positive
CREATE TABLE inventory (
    item_id      INTEGER   NOT NULL,
    item_name    TEXT      NOT NULL,
    quantity     INTEGER   NOT NULL CHECK (quantity >= 0),
    unit_price   NUMERIC   NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3: Testing NOT NULL

-- 1. complete records
INSERT INTO customers VALUES (1, 'arman@mail.kz', '+77011112233', '2026-01-15');
INSERT INTO inventory VALUES (1, 'Notebook', 100, 500, NOW());
INSERT INTO inventory VALUES (2, 'Pen',        0, 150, NOW());

-- 2. NULL in NOT NULL columns
-- INSERT INTO customers VALUES (2, NULL, '+77052223344', '2026-02-01');
-- ERROR: null value in column "email" of relation "customers" violates not-null constraint
-- Reason: email is NOT NULL

-- INSERT INTO customers VALUES (3, 'dina@mail.kz', NULL, NULL);
-- ERROR: null value in column "registration_date" of relation "customers" violates not-null constraint
-- Reason: registration_date is NOT NULL

-- INSERT INTO inventory VALUES (3, NULL, 10, 200, NOW());
-- ERROR: null value in column "item_name" of relation "inventory" violates not-null constraint
-- Reason: item_name is NOT NULL

-- INSERT INTO inventory VALUES (4, 'Eraser', NULL, 100, NOW());
-- ERROR: null value in column "quantity" of relation "inventory" violates not-null constraint
-- Reason: quantity is NOT NULL (CHECK alone would accept NULL)

-- 3. NULL in nullable column (phone) - succeeds
INSERT INTO customers VALUES (4, 'timur@mail.kz', NULL, '2026-03-10');


-- =====================================================================
-- Part 3: UNIQUE Constraints
-- =====================================================================

-- Task 3.1: Single Column UNIQUE
CREATE TABLE users (
    user_id    INTEGER,
    username   TEXT UNIQUE,
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2: Multi-Column UNIQUE
-- a student can take the same course only once per semester,
-- but the same course in a different semester is allowed
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 101, 'CSCI2102', 'Fall 2026');
INSERT INTO course_enrollments VALUES (2, 101, 'CSCI2102', 'Spring 2027');
INSERT INTO course_enrollments VALUES (3, 102, 'CSCI2102', 'Fall 2026');

-- INSERT INTO course_enrollments VALUES (4, 101, 'CSCI2102', 'Fall 2026');
-- ERROR: duplicate key value violates unique constraint
--        "course_enrollments_student_id_course_code_semester_key"
-- Reason: student 101 is already enrolled in CSCI2102 for Fall 2026

-- Task 3.3: Named UNIQUE Constraints
-- replace the auto-named constraints from Task 3.1 with named ones
ALTER TABLE users
    DROP CONSTRAINT users_username_key,
    DROP CONSTRAINT users_email_key,
    ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email    UNIQUE (email);

INSERT INTO users VALUES (1, 'arman', 'arman@mail.kz', NOW());
INSERT INTO users VALUES (2, 'dina',  'dina@mail.kz',  NOW());

-- INSERT INTO users VALUES (3, 'arman', 'arman2@mail.kz', NOW());
-- ERROR: duplicate key value violates unique constraint "unique_username"
-- Reason: username 'arman' already exists

-- INSERT INTO users VALUES (4, 'dina2', 'dina@mail.kz', NOW());
-- ERROR: duplicate key value violates unique constraint "unique_email"
-- Reason: email 'dina@mail.kz' already exists


-- =====================================================================
-- Part 4: PRIMARY KEY Constraints
-- =====================================================================

-- Task 4.1: Single Column Primary Key
-- PRIMARY KEY = UNIQUE + NOT NULL
CREATE TABLE departments (
    dept_id   INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location  TEXT
);

INSERT INTO departments VALUES (1, 'IT',    'Almaty');
INSERT INTO departments VALUES (2, 'Sales', 'Astana');
INSERT INTO departments VALUES (3, 'HR',    'Almaty');

-- INSERT INTO departments VALUES (1, 'Finance', 'Shymkent');
-- ERROR: duplicate key value violates unique constraint "departments_pkey"
-- Reason: dept_id 1 already exists

-- INSERT INTO departments VALUES (NULL, 'Finance', 'Shymkent');
-- ERROR: null value in column "dept_id" of relation "departments" violates not-null constraint
-- Reason: a primary key column cannot be NULL

-- Task 4.2: Composite Primary Key
-- one row per (student, course) pair
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (101, 1, '2026-09-01', 'A');
INSERT INTO student_courses VALUES (101, 2, '2026-09-01', 'B+');
INSERT INTO student_courses VALUES (102, 1, '2026-09-01', 'A-');

-- INSERT INTO student_courses VALUES (101, 1, '2026-09-05', 'C');
-- ERROR: duplicate key value violates unique constraint "student_courses_pkey"
-- Reason: the pair (101, 1) already exists

-- Task 4.3: Comparison Exercise
--
-- 1. Difference between UNIQUE and PRIMARY KEY
--    - PRIMARY KEY = UNIQUE + NOT NULL. It is the main identifier of a row.
--    - UNIQUE only forbids duplicates; the column may contain NULL
--      (in PostgreSQL several NULLs are allowed, because NULL <> NULL).
--    - FOREIGN KEYs usually reference the PRIMARY KEY of a table.
--
-- 2. Single-column vs composite PRIMARY KEY
--    - Single-column: when one attribute identifies the row by itself
--      (dept_id, emp_id, an auto-generated id).
--    - Composite: when a row is identified only by a combination of columns,
--      typically in junction tables for many-to-many relationships
--      (student_courses: one student - many courses, one course - many students).
--
-- 3. Why only one PRIMARY KEY but many UNIQUE constraints
--    - The primary key is THE identifier of a row; a table has only one main
--      way to identify its rows, and other tables reference it.
--    - A table can have several other attributes that must not repeat
--      (username, email, isbn), so any number of UNIQUE constraints is allowed.


-- =====================================================================
-- Part 5: FOREIGN KEY Constraints
-- =====================================================================

-- Task 5.1: Basic Foreign Key
-- dept_id must exist in departments (or be NULL)
CREATE TABLE employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments,
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Arman Akhmetov',  1, '2024-03-10');
INSERT INTO employees_dept VALUES (2, 'Dina Kassymova',  2, '2025-01-20');

-- INSERT INTO employees_dept VALUES (3, 'Timur Ospanov', 99, '2026-02-01');
-- ERROR: insert or update on table "employees_dept" violates foreign key constraint
--        "employees_dept_dept_id_fkey"
-- DETAIL: Key (dept_id)=(99) is not present in table "departments".

-- Task 5.2: Multiple Foreign Keys (library system)
CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

-- each book references one author and one publisher; isbn cannot repeat
CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors,
    publisher_id     INTEGER REFERENCES publishers,
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);

INSERT INTO authors VALUES
    (1, 'Abai Kunanbayev',    'Kazakhstan'),
    (2, 'Mukhtar Auezov',     'Kazakhstan'),
    (3, 'Robert C. Martin',   'USA');

INSERT INTO publishers VALUES
    (1, 'Atamura',       'Almaty'),
    (2, 'Prentice Hall', 'New York');

INSERT INTO books VALUES
    (1, 'Words of Edification', 1, 1, 1918, '978-601-01-0001-1'),
    (2, 'The Path of Abai',     2, 1, 1942, '978-601-01-0002-8'),
    (3, 'Clean Code',           3, 2, 2008, '978-0-13-235088-4');

-- INSERT INTO books VALUES (4, 'Unknown Book', 10, 1, 2020, '978-0-00-000000-0');
-- ERROR: insert or update on table "books" violates foreign key constraint "books_author_id_fkey"
-- DETAIL: Key (author_id)=(10) is not present in table "authors".

-- INSERT INTO books VALUES (5, 'Copy of Clean Code', 3, 2, 2009, '978-0-13-235088-4');
-- ERROR: duplicate key value violates unique constraint "books_isbn_key"
-- Reason: isbn already exists

-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

-- RESTRICT: a category cannot be deleted while products use it
CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

-- CASCADE: deleting an order automatically deletes its items
CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity   INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk VALUES (1, 'Laptop', 1), (2, 'Phone', 1), (3, 'Novel', 2);
INSERT INTO orders VALUES (1, '2026-10-01'), (2, '2026-10-02');
INSERT INTO order_items VALUES
    (1, 1, 1, 1),
    (2, 1, 3, 2),
    (3, 2, 2, 1);

-- Scenario 1: delete a category that has products (RESTRICT)
-- DELETE FROM categories WHERE category_id = 1;
-- ERROR: update or delete on table "categories" violates foreign key constraint
--        "products_fk_category_id_fkey" on table "products_fk"
-- DETAIL: Key (category_id)=(1) is still referenced from table "products_fk".
-- Result: the category is NOT deleted, products stay linked to it.

-- Scenario 2: delete an order (CASCADE)
DELETE FROM orders WHERE order_id = 1;
SELECT * FROM order_items;
-- Result: order 1 is deleted and its items (item_id 1 and 2) are deleted
--         automatically; only item_id 3 (order 2) remains.


-- =====================================================================
-- Part 6: Practical Application
-- =====================================================================
-- Task 6.1: E-commerce Database Design
-- Created in a separate schema because tables named customers and orders
-- already exist in public from Parts 2 and 5.
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;

-- email must be unique; name, email and registration_date are required
CREATE TABLE customers (
    customer_id       INTEGER PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,
    phone             TEXT,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- price and stock cannot be negative
CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    name           TEXT    NOT NULL,
    description    TEXT,
    price          NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

-- ON DELETE RESTRICT: a customer with orders cannot be deleted (order history is kept)
-- status must be one of the 5 allowed values
CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers ON DELETE RESTRICT,
    order_date   DATE    NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status       TEXT    NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

-- ON DELETE CASCADE on order_id: order lines are deleted together with the order
-- ON DELETE RESTRICT on product_id: a product that was ordered cannot be deleted
CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders   ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES products ON DELETE RESTRICT,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES
    (1, 'Arman Akhmetov',  'arman@mail.kz',  '+77011112233', '2026-01-10'),
    (2, 'Dina Kassymova',  'dina@mail.kz',   '+77052223344', '2026-02-15'),
    (3, 'Yerzhan Nurlanov','yerzhan@mail.kz', NULL,          '2026-03-20'),
    (4, 'Saule Abenova',   'saule@mail.kz',  '+77773334455', '2026-04-05'),
    (5, 'Timur Ospanov',   'timur@mail.kz',  '+77014445566', '2026-05-12');

INSERT INTO products VALUES
    (1, 'Laptop',     '15-inch, 16GB RAM',    450000, 10),
    (2, 'Mouse',      'Wireless mouse',         8000, 50),
    (3, 'Keyboard',   'Mechanical keyboard',   25000, 30),
    (4, 'Monitor',    '27-inch IPS',           95000, 15),
    (5, 'Headphones', 'Noise cancelling',      60000,  0);

INSERT INTO orders VALUES
    (1, 1, '2026-09-01', 458000, 'delivered'),
    (2, 2, '2026-09-05',  25000, 'shipped'),
    (3, 3, '2026-09-10', 190000, 'processing'),
    (4, 1, '2026-09-15',  16000, 'pending'),
    (5, 4, '2026-09-20',  60000, 'cancelled');

INSERT INTO order_details VALUES
    (1, 1, 1, 1, 450000),
    (2, 1, 2, 1,   8000),
    (3, 2, 3, 1,  25000),
    (4, 3, 4, 2,  95000),
    (5, 4, 2, 2,   8000),
    (6, 5, 5, 1,  60000);

-- Test queries demonstrating constraints

-- UNIQUE email
-- INSERT INTO customers VALUES (6, 'Test User', 'arman@mail.kz', NULL, '2026-06-01');
-- ERROR: duplicate key value violates unique constraint "customers_email_key"

-- NOT NULL name
-- INSERT INTO customers VALUES (7, NULL, 'test@mail.kz', NULL, '2026-06-01');
-- ERROR: null value in column "name" of relation "customers" violates not-null constraint

-- negative price
-- INSERT INTO products VALUES (6, 'Cable', 'USB-C', -500, 10);
-- ERROR: new row for relation "products" violates check constraint "products_price_check"

-- negative stock
-- INSERT INTO products VALUES (7, 'Webcam', 'HD camera', 15000, -1);
-- ERROR: new row for relation "products" violates check constraint "products_stock_quantity_check"

-- invalid status
-- INSERT INTO orders VALUES (6, 2, '2026-10-01', 5000, 'lost');
-- ERROR: new row for relation "orders" violates check constraint "orders_status_check"

-- non-existent customer
-- INSERT INTO orders VALUES (7, 99, '2026-10-01', 5000, 'pending');
-- ERROR: insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
-- DETAIL: Key (customer_id)=(99) is not present in table "customers".

-- quantity must be positive
-- INSERT INTO order_details VALUES (7, 2, 1, 0, 450000);
-- ERROR: new row for relation "order_details" violates check constraint "order_details_quantity_check"

-- RESTRICT: customer with orders cannot be deleted
-- DELETE FROM customers WHERE customer_id = 1;
-- ERROR: update or delete on table "customers" violates foreign key constraint
--        "orders_customer_id_fkey" on table "orders"

-- RESTRICT: product that was ordered cannot be deleted
-- DELETE FROM products WHERE product_id = 2;
-- ERROR: update or delete on table "products" violates foreign key constraint
--        "order_details_product_id_fkey" on table "order_details"

-- CASCADE: deleting an order removes its order_details
DELETE FROM orders WHERE order_id = 5;
SELECT * FROM order_details WHERE order_id = 5;
-- Result: 0 rows - order_detail_id 6 was deleted automatically

SET search_path TO public;
