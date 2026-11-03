-- =====================================================================
-- Laboratory Work 6: SQL JOINs
-- Name:       Azimbekuly Nurdilda
-- Student ID: 25b031238
-- =====================================================================

-- =====================================================================
-- Part 1: Database Setup
-- =====================================================================

-- Step 1.1: Create Sample Tables
CREATE TABLE employees (
                           emp_id   INT PRIMARY KEY,
                           emp_name VARCHAR(50),
                           dept_id  INT,
                           salary   DECIMAL(10, 2)
);

CREATE TABLE departments (
                             dept_id   INT PRIMARY KEY,
                             dept_name VARCHAR(50),
                             location  VARCHAR(50)
);

CREATE TABLE projects (
                          project_id   INT PRIMARY KEY,
                          project_name VARCHAR(50),
                          dept_id      INT,
                          budget       DECIMAL(10, 2)
);

-- Step 1.2: Insert Sample Data
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
                                                              (1, 'John Smith',     101,  50000),
                                                              (2, 'Jane Doe',       102,  60000),
                                                              (3, 'Mike Johnson',   101,  55000),
                                                              (4, 'Sarah Williams', 103,  65000),
                                                              (5, 'Tom Brown',      NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
                                                           (101, 'IT',        'Building A'),
                                                           (102, 'HR',        'Building B'),
                                                           (103, 'Finance',   'Building C'),
                                                           (104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
                                                                     (1, 'Website Redesign',  101,  100000),
                                                                     (2, 'Employee Training', 102,   50000),
                                                                     (3, 'Budget Analysis',   103,   75000),
                                                                     (4, 'Cloud Migration',   101,  150000),
                                                                     (5, 'AI Research',       NULL, 200000);


-- =====================================================================
-- Part 2: CROSS JOIN Exercises
-- =====================================================================

-- Exercise 2.1: Basic CROSS JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
         CROSS JOIN departments d;
-- Answer: 5 employees x 4 departments = 20 rows

-- Exercise 2.2: Alternative CROSS JOIN Syntax
-- a) Comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- b) INNER JOIN with TRUE condition
SELECT e.emp_name, d.dept_name
FROM employees e
         INNER JOIN departments d ON TRUE;
-- Both return the same 20 rows as 2.1

-- Exercise 2.3: Practical CROSS JOIN
-- availability matrix: every employee paired with every project
SELECT e.emp_name, p.project_name
FROM employees e
         CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
-- Result: 5 x 5 = 25 rows


-- =====================================================================
-- Part 3: INNER JOIN Exercises
-- =====================================================================

-- Exercise 3.1: Basic INNER JOIN with ON
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: 4 rows. Tom Brown is not included because his dept_id is NULL,
-- and NULL = 101 is never TRUE, so he has no matching department.

-- Exercise 3.2: INNER JOIN with USING
SELECT emp_name, dept_name, location
FROM employees
         INNER JOIN departments USING (dept_id);
-- Answer: with USING the join column dept_id appears only once in SELECT *,
-- with ON it appears twice (e.dept_id and d.dept_id).

-- Exercise 3.3: NATURAL INNER JOIN
-- joins automatically on all columns with the same name (here only dept_id)
SELECT emp_name, dept_name, location
FROM employees
         NATURAL INNER JOIN departments;

-- Exercise 3.4: Multi-table INNER JOIN
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
         INNER JOIN projects p    ON d.dept_id = p.dept_id;
-- Result: 6 rows (IT has 2 employees x 2 projects = 4, HR 1, Finance 1)


-- =====================================================================
-- Part 4: LEFT JOIN Exercises
-- =====================================================================

-- Exercise 4.1: Basic LEFT JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: Tom Brown is shown with NULL in emp_dept, dept_dept and dept_name.

-- Exercise 4.2: LEFT JOIN with USING
SELECT emp_name, dept_id, dept_name
FROM employees
         LEFT JOIN departments USING (dept_id);

-- Exercise 4.3: Find Unmatched Records
-- after LEFT JOIN, rows without a match have NULL on the right side
SELECT e.emp_name, e.dept_id
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
-- Result: Tom Brown

-- Exercise 4.4: LEFT JOIN with Aggregation
-- COUNT(e.emp_id) ignores NULL, so Marketing gets 0 (COUNT(*) would give 1)
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
-- Result: IT 2, HR 1, Finance 1, Marketing 0


-- =====================================================================
-- Part 5: RIGHT JOIN Exercises
-- =====================================================================

-- Exercise 5.1: Basic RIGHT JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
         RIGHT JOIN departments d ON e.dept_id = d.dept_id;
-- Result: Marketing is shown with emp_name = NULL; Tom Brown is not shown

-- Exercise 5.2: Convert to LEFT JOIN
SELECT e.emp_name, d.dept_name
FROM departments d
         LEFT JOIN employees e ON e.dept_id = d.dept_id;
-- Same result as 5.1

-- Exercise 5.3: Find Departments Without Employees
SELECT d.dept_name, d.location
FROM employees e
         RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
-- Result: Marketing, Building D


-- =====================================================================
-- Part 6: FULL JOIN Exercises
-- =====================================================================

-- Exercise 6.1: Basic FULL JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: NULL on the left side (employee columns): Marketing - no employees.
--         NULL on the right side (department columns): Tom Brown - no department.

-- Exercise 6.2: FULL JOIN with Projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
         FULL JOIN projects p ON d.dept_id = p.dept_id;
-- Result: Marketing has no project (project NULL),
--         AI Research has no department (dept_name NULL)

-- Exercise 6.3: Find Orphaned Records
SELECT
    CASE
        WHEN e.emp_id IS NULL  THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
        END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL
   OR d.dept_id IS NULL;
-- Result: Tom Brown (Employee without department),
--         Marketing (Department without employees)


-- =====================================================================
-- Part 7: ON vs WHERE Clause
-- =====================================================================

-- Exercise 7.1: Filtering in ON Clause (Outer Join)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
    AND d.location = 'Building A';
-- Result: 5 rows - all employees; only John Smith and Mike Johnson
--         get dept_name 'IT', the others have NULL

-- Exercise 7.2: Filtering in WHERE Clause (Outer Join)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Result: 2 rows - John Smith and Mike Johnson
-- Difference:
--   ON:    the filter is applied DURING the join - all employees stay,
--          only departments in Building A are matched.
--   WHERE: the filter is applied AFTER the join - rows whose department
--          is not in Building A (or NULL) are removed.

-- Exercise 7.3: ON vs WHERE with INNER JOIN
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
    AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Answer: no difference, both return 2 rows. INNER JOIN keeps only rows
-- where the whole ON condition is TRUE, so filtering in ON or in WHERE
-- removes exactly the same rows.


-- =====================================================================
-- Part 8: Complex JOIN Scenarios
-- =====================================================================

-- Exercise 8.1: Multiple Joins with Different Types
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
         LEFT JOIN projects p  ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
-- Result: 7 rows; Marketing appears with NULL employee and NULL project

-- Exercise 8.2: Self Join
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3    WHERE emp_id = 1;
UPDATE employees SET manager_id = 3    WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3    WHERE emp_id = 4;
UPDATE employees SET manager_id = 3    WHERE emp_id = 5;

-- the same table is used twice: e = employee, m = manager
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
         LEFT JOIN employees m ON e.manager_id = m.emp_id;
-- Result: everyone's manager is Mike Johnson; Mike Johnson has NULL (no manager)

-- Exercise 8.3: Join with Subquery
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
         INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
-- Result: IT 52500, HR 60000, Finance 65000


-- =====================================================================
-- Lab Questions
-- =====================================================================
-- 1. INNER JOIN returns only rows that have a match in both tables.
--    LEFT JOIN returns all rows from the left table; if there is no match,
--    the right table's columns are NULL.
--
-- 2. CROSS JOIN is used when every combination is needed: an availability
--    matrix (employees x projects), schedules (groups x time slots),
--    product variants (sizes x colors), generating test data.
--
-- 3. In an outer join, a condition in ON only decides which rows are matched;
--    unmatched rows from the preserved table are still returned with NULLs.
--    A condition in WHERE runs after the join and removes those rows.
--    In an inner join, unmatched rows are dropped anyway, so ON and WHERE
--    give the same result.
--
-- 4. 5 x 10 = 50
--
-- 5. NATURAL JOIN joins on all columns that have the same name in both tables.
--
-- 6. Risks of NATURAL JOIN:
--    - if a column with the same name is added later (e.g. "name",
--      "created_at"), the join condition changes silently and results become wrong;
--    - columns with the same name may mean different things;
--    - the join condition is not visible in the query, so it is hard to read;
--    - if there are no common columns, it turns into a CROSS JOIN.
--
-- 7. SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
--
-- 8. FULL OUTER JOIN is used when unmatched rows from BOTH tables are needed:
--    comparing two data sets, data reconciliation/migration checks,
--    finding orphaned records on both sides (like Exercise 6.3).


-- =====================================================================
-- Additional Challenges (Optional)
-- =====================================================================

-- Challenge 1: FULL OUTER JOIN simulated with UNION of LEFT and RIGHT joins
-- UNION removes the duplicated matched rows
SELECT e.emp_name, d.dept_name
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.emp_name, d.dept_name
FROM employees e
         RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Challenge 2: employees in departments that have more than one project
SELECT e.emp_name, d.dept_name
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.dept_id IN (
    SELECT dept_id
    FROM projects
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);
-- Result: John Smith, Mike Johnson (IT has 2 projects)

-- Challenge 3: organizational structure (employee -> manager -> manager's manager)
SELECT
    e.emp_name  AS employee,
    m1.emp_name AS manager,
    m2.emp_name AS managers_manager
FROM employees e
         LEFT JOIN employees m1 ON e.manager_id  = m1.emp_id
         LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id
ORDER BY e.emp_id;

-- Challenge 4: all pairs of employees in the same department
-- e1.emp_id < e2.emp_id removes self-pairs and duplicate pairs (A-B and B-A)
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    d.dept_name
FROM employees e1
         INNER JOIN employees e2  ON e1.dept_id = e2.dept_id
    AND e1.emp_id < e2.emp_id
         INNER JOIN departments d ON e1.dept_id = d.dept_id;
-- Result: John Smith - Mike Johnson (IT)