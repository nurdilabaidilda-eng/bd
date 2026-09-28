-- =====================================================================
-- Laboratory Work #3 - Advanced DML Operations
-- File: lab3_advanced_dml.sql
-- DBMS: PostgreSQL
-- =====================================================================


-- =====================================================================
-- Part A: Database and Table Setup
-- =====================================================================

-- 1. Create database and tables
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;

-- NOTE: switch the connection to 'advanced_lab' before running the rest
-- (DataGrip: choose advanced_lab in the schema/database selector;
--  psql: \c advanced_lab)

DROP TABLE IF EXISTS employees, departments, projects, employee_archive CASCADE;

-- Constraints:
--   * salary / department stay NULLable (tasks 3, 10, 17 need NULL values)
--   * CHECK on NULL passes, so CHECK (salary >= 0) does not block NULL salary
CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    department VARCHAR(50),          -- no explicit default -> DEFAULT = NULL
    salary     INTEGER CHECK (salary >= 0),   -- no explicit default -> DEFAULT = NULL
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
               CHECK (status IN ('Active', 'Inactive', 'Senior', 'Promoted', 'Terminated'))
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50) NOT NULL UNIQUE,
    budget     INTEGER CHECK (budget >= 0),
    manager_id INTEGER
);

-- dept_id references departments; ON DELETE SET NULL so that task 15
-- (deleting departments) does not fail because of existing projects
CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INTEGER REFERENCES departments (dept_id) ON DELETE SET NULL,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER CHECK (budget >= 0),
    CHECK (end_date >= start_date)
);


-- ---------------------------------------------------------------------
-- Sample data for testing
-- ---------------------------------------------------------------------
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
    ('Aibek',   'Nurlanov',   'IT',    75000, '2018-03-15', 'Active'),
    ('Dana',    'Sadykova',   'IT',    62000, '2019-07-01', 'Active'),
    ('Arman',   'Tokayev',    'IT',    55000, '2021-02-10', 'Active'),
    ('Aruzhan', 'Bekova',     'IT',    48000, '2022-09-05', 'Active'),
    ('Nurlan',  'Omarov',     'Sales', 45000, '2020-05-20', 'Active'),
    ('Madina',  'Kassymova',  'Sales', 52000, '2017-11-11', 'Active'),
    ('Yerlan',  'Zhakupov',   'HR',    39000, '2023-06-01', 'Inactive'),
    ('Aigerim', 'Serikova',   'HR',    41000, '2016-01-25', 'Terminated'),
    ('Timur',   'Akhmetov',   NULL,    35000, '2023-08-15', 'Active');



-- =====================================================================
-- Part B: Advanced INSERT Operations
-- =====================================================================

-- 2. INSERT with column specification (only 4 columns;
--    salary and hire_date become NULL, status becomes 'Active')
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (100, 'Samat', 'Iskakov', 'IT');

-- emp_id was given manually, so move the SERIAL sequence forward
-- to avoid duplicate key errors on future inserts
SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- 3. INSERT with DEFAULT values
--    salary has no explicit default -> DEFAULT puts NULL;
--    status DEFAULT -> 'Active'
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Alina', 'Mukhanova', 'Sales', DEFAULT, '2024-01-15', DEFAULT);

-- 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id) VALUES
    ('IT',    150000, 1),
    ('Sales',  90000, 6),
    ('HR',     60000, 8);

-- sample projects (inserted after departments because of the FOREIGN KEY)
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
    ('Website Redesign', 1, '2022-01-10', '2022-12-31', 60000),
    ('CRM System',       1, '2023-02-01', '2024-06-30', 120000),
    ('Sales Campaign',   2, '2023-03-01', '2023-09-30', 40000),
    ('HR Portal',        3, '2021-05-01', '2022-11-30', 30000);

-- 5. INSERT with expressions (hire_date = today, salary = 50000 * 1.1 = 55000)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Dias', 'Karimov', 'IT', 50000 * 1.1, CURRENT_DATE);

-- 6. INSERT from SELECT (subquery) into a temporary table
DROP TABLE IF EXISTS temp_employees;
CREATE TEMP TABLE temp_employees (LIKE employees);   -- same structure as employees

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

SELECT * FROM temp_employees;


-- =====================================================================
-- Part C: Complex UPDATE Operations
-- =====================================================================

-- 7. UPDATE with arithmetic expressions (+10% to everyone)
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
--    This statement overwrites real department names (IT, Sales, HR),
--    which the next tasks depend on. It is executed inside a transaction
--    and rolled back so that the remaining queries still have test data.
BEGIN;

UPDATE employees
SET department = CASE
                     WHEN salary > 80000                 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

SELECT emp_id, first_name, salary, department FROM employees;  -- check result

ROLLBACK;

-- 10. UPDATE with DEFAULT
--     department has no explicit default, so DEFAULT sets it to NULL
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
--     budget = average salary of the department's employees * 1.2
--     (departments and employees are linked by dept_name = department)
UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns in one statement
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';


-- =====================================================================
-- Part D: Advanced DELETE Operations
-- =====================================================================

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
--     employees.department stores the department NAME (text), not dept_id,
--     so the comparison is done by dept_name (dept_id INTEGER vs VARCHAR
--     would cause a type error).
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Marketing', 70000, NULL);        -- department without employees (test row)

DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL          -- important: NOT IN with NULL returns nothing
);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- =====================================================================
-- Part E: Operations with NULL Values
-- =====================================================================

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bolat', 'Yessenov', NULL, NULL, '2024-03-01');

-- 18. UPDATE NULL handling (use IS NULL, not = NULL)
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;


-- =====================================================================
-- Part F: RETURNING Clause Operations
-- =====================================================================

-- 20. INSERT with RETURNING (generated id + full name)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanna', 'Abenova', 'IT', 58000, '2024-05-10')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE with RETURNING
--     RETURNING shows values AFTER the update, so the old salary
--     is calculated back as (new salary - 5000)
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
          salary - 5000 AS old_salary,
          salary        AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


-- =====================================================================
-- Part G: Advanced DML Patterns
-- =====================================================================

-- 23. Conditional INSERT: add only if the same first + last name doesn't exist
--     (running it a second time inserts 0 rows)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Arman', 'Tokayev', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Arman'
      AND last_name  = 'Tokayev'
);

-- 24. UPDATE with JOIN logic using subqueries
--     budget > 100000 -> +10%, otherwise -> +5%
UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget
                                FROM departments d
                                WHERE d.dept_name = e.department) > 100000
                          THEN 1.10
                          ELSE 1.05
                      END
WHERE e.department IN (SELECT dept_name FROM departments);

-- 25. Bulk operations: 5 employees in one INSERT, then one UPDATE (+10%)
INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
    ('Ruslan',  'Bekov',     'IT',    50000, '2024-09-01'),
    ('Kamila',  'Ospanova',  'IT',    52000, '2024-09-01'),
    ('Erzhan',  'Tulegenov', 'Sales', 47000, '2024-09-01'),
    ('Saule',   'Dzhanova',  'Sales', 49000, '2024-09-01'),
    ('Marat',   'Kaliyev',   'HR',    43000, '2024-09-01');

UPDATE employees
SET salary = salary * 1.10
WHERE (first_name, last_name) IN (
    ('Ruslan', 'Bekov'), ('Kamila', 'Ospanova'), ('Erzhan', 'Tulegenov'),
    ('Saule', 'Dzhanova'), ('Marat', 'Kaliyev')
);

-- 26. Data migration simulation
--     test rows with status 'Inactive'
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
    ('Asel',  'Nurova',  'HR', 40000, '2022-04-01', 'Inactive'),
    ('Daulet','Sarsenov','IT', 57000, '2021-10-12', 'Inactive');

CREATE TABLE employee_archive (LIKE employees INCLUDING DEFAULTS);

-- copy + delete inside one transaction: either both happen or nothing
BEGIN;

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

COMMIT;

SELECT * FROM employee_archive;

-- 27. Complex business logic
--     +30 days to end_date for projects with budget > 50000
--     whose department has more than 3 employees
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
        SELECT COUNT(*)
        FROM employees e
        JOIN departments d ON e.department = d.dept_name
        WHERE d.dept_id = p.dept_id
      ) > 3;

-- final check
SELECT * FROM employees ORDER BY emp_id;
SELECT * FROM departments;
SELECT * FROM projects;
