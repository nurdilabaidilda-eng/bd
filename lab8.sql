-- =====================================================================
-- Laboratory Work 8: SQL Indexes
-- Name:       Azimbekuly Nurdilda
-- Student ID: 25b031238
-- =====================================================================


-- =====================================================================
-- Part 1: Database Setup
-- =====================================================================

CREATE TABLE  departments (
                             dept_id   INT PRIMARY KEY,
                             dept_name VARCHAR(50),
                             location  VARCHAR(50)
);

CREATE TABLE  employees (
                           emp_id   INT PRIMARY KEY,
                           emp_name VARCHAR(100),
                           dept_id  INT,
                           salary   DECIMAL(10,2),
                           FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
                          proj_id   INT PRIMARY KEY,
                          proj_name VARCHAR(100),
                          budget    DECIMAL(12,2),
                          dept_id   INT,
                          FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
DROP TABLE departments cascade ;
DROP TABLE employees;
DROP table projects;
INSERT INTO departments VALUES
                            (101, 'IT',         'Building A'),
                            (102, 'HR',         'Building B'),
                            (103, 'Operations', 'Building C');

INSERT INTO employees VALUES
                          (1, 'John Smith',     101, 50000),
                          (2, 'Jane Doe',       101, 55000),
                          (3, 'Mike Johnson',   102, 48000),
                          (4, 'Sarah Williams', 102, 52000),
                          (5, 'Tom Brown',      103, 60000);

INSERT INTO projects VALUES
                         (201, 'Website Redesign',   75000,  101),
                         (202, 'Database Migration', 120000, 101),
                         (203, 'HR System Upgrade',  50000,  102);


-- =====================================================================
-- Part 2: Creating Basic Indexes
-- =====================================================================

-- Exercise 2.1: Create a Simple B-tree Index
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
-- Answer: 2 indexes - employees_pkey (created automatically by PRIMARY KEY)
-- and emp_salary_idx.

-- Exercise 2.2: Create an Index on a Foreign Key
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
-- Answer: FK columns are used in JOINs and WHERE filters (dept_id = 101).
-- An index lets PostgreSQL find matching rows without scanning the whole
-- table. It also speeds up DELETE/UPDATE on departments, because PostgreSQL
-- must check employees for rows that reference the deleted department.
-- PostgreSQL does not create FK indexes automatically.

-- Exercise 2.3: View Index Information
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Answer:
--   departments: departments_pkey                  (automatic, PRIMARY KEY)
--   employees:   emp_dept_idx, emp_salary_idx      (created by us)
--                employees_pkey                    (automatic, PRIMARY KEY)
--   projects:    projects_pkey                     (automatic, PRIMARY KEY)
-- The *_pkey indexes were created automatically.


-- =====================================================================
-- Part 3: Multicolumn Indexes
-- =====================================================================

-- Exercise 3.1: Create a Multicolumn Index
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
-- Answer: no, not efficiently. The index is sorted first by dept_id, then by
-- salary inside each dept_id. Salaries are spread across all dept_id groups,
-- so a query on salary alone cannot jump to the right place - it uses
-- emp_salary_idx or a sequential scan instead.

-- Exercise 3.2: Understanding Column Order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1: Filters by dept_id first
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2: Filters by salary first
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Answer: the order of conditions in WHERE does not matter - both queries
-- are the same for the planner. The order of columns in the INDEX does
-- matter: an index is used best when the leading (first) column is filtered.
-- Best is: equality column first, range column second -> (dept_id, salary).


-- =====================================================================
-- Part 4: Unique Indexes
-- =====================================================================

-- Exercise 4.1: Create a Unique Index
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com'     WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'       WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com'   WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'      WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
-- ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"
-- DETAIL: Key (email)=(john.smith@company.com) already exists.

-- Exercise 4.2: Unique Index vs UNIQUE Constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Answer: yes, PostgreSQL automatically created employees_phone_key,
-- a UNIQUE B-tree index. A UNIQUE constraint is always enforced by a
-- unique B-tree index.


-- =====================================================================
-- Part 5: Indexes and Sorting
-- =====================================================================

-- Exercise 5.1: Create an Index for Sorting
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
-- Answer: the index already stores salaries in descending order, so
-- PostgreSQL can read rows in index order and skip the separate sort step.
-- (A normal B-tree can also be read backwards, so DESC matters mostly for
-- multicolumn indexes with mixed order, e.g. (dept_id ASC, salary DESC).)

-- Exercise 5.2: Index with NULL Handling
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;
-- By default ASC puts NULLs last; this index stores NULLs first, matching
-- ORDER BY budget NULLS FIRST, so no extra sort is needed.


-- =====================================================================
-- Part 6: Indexes on Expressions
-- =====================================================================

-- Exercise 6.1: Create a Function-Based Index
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Answer: without it, PostgreSQL must do a sequential scan: compute
-- LOWER(emp_name) for every row and compare. A normal index on emp_name
-- cannot be used, because it stores the original values, not LOWER(...).

-- Exercise 6.2: Index on Calculated Values
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;
-- Result: John Smith, Sarah Williams


-- =====================================================================
-- Part 7: Managing Indexes
-- =====================================================================

-- Exercise 7.1: Rename an Index
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- Exercise 7.2: Drop Unused Indexes
DROP INDEX emp_salary_dept_idx;
-- Answer: every index slows down INSERT/UPDATE/DELETE (it must be updated
-- too) and takes disk space. An index that is never used or duplicates
-- another one (here emp_dept_salary_idx and emp_salary_idx already cover
-- these queries) only costs and gives nothing.

-- Exercise 7.3: Reindex
REINDEX INDEX employees_salary_index;
-- REINDEX rebuilds the index from scratch: useful after bulk changes or when
-- the index is bloated (many empty pages left after UPDATE/DELETE).


-- =====================================================================
-- Part 8: Practical Scenarios
-- =====================================================================

-- Exercise 8.1: Optimize a Slow Query
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- Index for the WHERE clause (partial index)
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- Index for the JOIN: emp_dept_idx (already created)
-- Index for ORDER BY: emp_salary_desc_idx (already created)

-- Exercise 8.2: Partial Index
CREATE INDEX proj_high_budget_idx ON projects(budget)
    WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
-- Answer: a partial index stores only the rows that match its WHERE
-- (here only budget > 80000), so it is smaller, faster to search, and
-- cheaper to maintain - rows outside the condition are never written to it.

-- Exercise 8.3: Analyze Index Usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Output:
--   Seq Scan on employees  (cost=0.00..1.06 rows=2 width=522)
--     Filter: (salary > '52000'::numeric)
-- Answer: Seq Scan. The table has only 5 rows (1 page), so reading it fully
-- is cheaper than going through an index. The planner chooses by cost;
-- indexes pay off on large tables or very selective conditions.


-- =====================================================================
-- Part 9: Index Types Comparison
-- =====================================================================

-- Exercise 9.1: Create a Hash Index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
-- Answer: HASH only supports equality (=). Use it when a column is searched
-- only with =, never with <, >, BETWEEN, LIKE 'abc%' or ORDER BY. For long
-- values (long strings) it can be smaller and a bit faster than B-tree.
-- B-tree supports all of these, so it is the default choice.

-- Exercise 9.2: Compare Index Types
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx  ON projects USING HASH (proj_name);

-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';

-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';


-- =====================================================================
-- Part 10: Cleanup and Best Practices
-- =====================================================================

-- Exercise 10.1: Review All Indexes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Answer: the HASH indexes are the largest (32 kB vs 16 kB for B-tree).
-- A hash index allocates several pages (metapage + bucket pages) right away,
-- while a B-tree on a tiny table needs only a metapage and one leaf page.
-- With so few rows, size depends on the index type, not on the data.

-- Exercise 10.2: Drop Unnecessary Indexes
DROP INDEX IF EXISTS proj_name_hash_idx;
-- proj_name_btree_idx already handles equality AND range searches,
-- so the hash index on the same column is a duplicate.

-- Exercise 10.3: Document Your Indexes
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;


-- =====================================================================
-- Summary Questions
-- =====================================================================
-- 1. B-tree.
--
-- 2. Create an index:
--    - on columns often used in WHERE (e.g. WHERE dept_id = 101);
--    - on foreign key / JOIN columns;
--    - on columns used in ORDER BY on large tables.
--
-- 3. Do NOT create an index:
--    - on small tables (a sequential scan is already fast);
--    - on tables with very frequent INSERT/UPDATE/DELETE and few reads;
--    - on columns with few distinct values (e.g. gender, boolean flags).
--
-- 4. Every INSERT, UPDATE and DELETE must also update all indexes of the
--    table, so writes become slower; deleted/updated rows leave dead entries
--    that can bloat the index (fixed by VACUUM / REINDEX).
--
-- 5. Put EXPLAIN (or EXPLAIN ANALYZE) before the query and look for
--    "Index Scan", "Index Only Scan" or "Bitmap Index Scan" instead of
--    "Seq Scan".


-- =====================================================================
-- Additional Challenges (Optional)
-- =====================================================================

-- Challenge 1: employees hired in a specific month
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(MONTH FROM hire_date) = 6;
-- Result: Jane Doe (2019-06-20)

-- Challenge 2: composite unique index on (dept_id, email)
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);
-- the same email may not repeat inside one department

-- Challenge 3: EXPLAIN ANALYZE with and without index usage
-- with the planner's normal choice (Seq Scan on a tiny table)
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000;

-- force index usage by disabling sequential scans
SET enable_seqscan = off;
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000;
RESET enable_seqscan;
-- Output 1: Seq Scan on employees ... Execution Time: 0.010 ms
-- Output 2: Index Scan using emp_salary_desc_idx on employees ... Execution Time: 0.022 ms
-- On 5 rows both take well under 1 ms; the index plan is not faster here.
-- The difference appears only on large tables.

-- Challenge 4: covering index
-- INCLUDE stores emp_name and salary in the index, so the query below can be
-- answered from the index alone (Index Only Scan) without reading the table
CREATE INDEX emp_dept_covering_idx ON employees(dept_id) INCLUDE (emp_name, salary);

SET enable_seqscan = off;
EXPLAIN SELECT emp_name, salary FROM employees WHERE dept_id = 101;
RESET enable_seqscan;
-- Output: Index Only Scan using emp_dept_covering_idx on employees
--           Index Cond: (dept_id = 101)


-- =====================================================================
-- Reflection: when to use indexes
-- =====================================================================
-- Indexes are worth creating on large tables for columns that are often
-- searched, joined or sorted: foreign keys, WHERE filters, ORDER BY columns.
-- They make reads faster but every write must update them, and they take
-- disk space, so a table should not have more indexes than its queries need.
-- On small tables PostgreSQL ignores them and uses a sequential scan, as seen
-- in Exercise 8.3. The best way to decide is to check the real plan with
-- EXPLAIN / EXPLAIN ANALYZE and drop indexes that are never used.