-- Part A: Database and Table Setup

-- 1. Create database and tables
CREATE DATABASE advanced_lab;

CREATE TABLE employees (
                           emp_id     SERIAL PRIMARY KEY,
                           first_name VARCHAR(50),
                           last_name  VARCHAR(50),
                           department VARCHAR(50),
                           salary     INTEGER,
                           hire_date  DATE,
                           status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
                             dept_id    SERIAL PRIMARY KEY,
                             dept_name  VARCHAR(50),
                             budget     INTEGER,
                             manager_id INTEGER
);

CREATE TABLE projects (
                          project_id   SERIAL PRIMARY KEY,
                          project_name VARCHAR(100),
                          dept_id      INTEGER,
                          start_date   DATE,
                          end_date     DATE,
                          budget       INTEGER
);

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

-- Part B: Advanced INSERT Operations

-- 2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (100, 'Samat', 'Iskakov', 'IT');

SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Alina', 'Mukhanova', 'Sales', DEFAULT, '2024-01-15', DEFAULT);

-- 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id) VALUES
                                                            ('IT',    150000, 1),
                                                            ('Sales',  90000, 6),
                                                            ('HR',     60000, 8);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
                                                                               ('Website Redesign', 1, '2022-01-10', '2022-12-31', 60000),
                                                                               ('CRM System',       1, '2023-02-01', '2024-06-30', 120000),
                                                                               ('Sales Campaign',   2, '2023-03-01', '2023-09-30', 40000),
                                                                               ('HR Portal',        3, '2021-05-01', '2022-11-30', 30000);

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Dias', 'Karimov', 'IT', 50000 * 1.1, CURRENT_DATE);

-- 6. INSERT from SELECT (subquery)
CREATE TEMP TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

-- Part C: Complex UPDATE Operations

-- 7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
                     WHEN salary > 80000                 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
    END;

-- 10. UPDATE with DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D: Advanced DELETE Operations

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < '2023-01-01'
    RETURNING *;

-- Part E: Operations with NULL Values

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bolat', 'Yessenov', NULL, NULL, '2024-03-01');

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- Part F: RETURNING Clause Operations

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanna', 'Abenova', 'IT', 58000, '2024-05-10')
    RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE with RETURNING
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

-- Part G: Advanced DML Patterns

-- 23. Conditional INSERT
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Arman', 'Tokayev', 'IT', 60000, CURRENT_DATE
    WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Arman'
      AND last_name  = 'Tokayev'
);

-- 24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget
                                FROM departments d
                                WHERE d.dept_name = e.department) > 100000
                              THEN 1.10
                          ELSE 1.05
    END;

-- 25. Bulk operations
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
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
                                                                                         ('Asel',  'Nurova',  'HR', 40000, '2022-04-01', 'Inactive'),
                                                                                         ('Daulet','Sarsenov','IT', 57000, '2021-10-12', 'Inactive');

CREATE TABLE employee_archive (LIKE employees);

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

-- 27. Complex business logic
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
    SELECT COUNT(*)
    FROM employees e
    JOIN departments d ON e.department = d.dept_name
    WHERE d.dept_id = p.dept_id
    ) > 3;