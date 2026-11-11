-- =====================================================================
-- Laboratory Work 7: SQL Views and Roles
-- Name:       Azimbekuly Nurdilda
-- Student ID: 25b031238
-- =====================================================================


-- =====================================================================
-- Part 1: Database Setup (Lab 6 tables)
-- =====================================================================
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
-- Part 2: Creating Basic Views
-- =====================================================================

-- Exercise 2.1: Simple View Creation
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;
-- Answer: 4 rows. Tom Brown does not appear because his dept_id is NULL;
-- INNER JOIN keeps only employees that match a department.

-- Exercise 2.2: View with Aggregation
-- LEFT JOIN keeps departments without employees; COUNT(e.emp_id) gives 0 for them
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id)          AS employee_count,
       ROUND(AVG(e.salary), 2)  AS avg_salary,
       MAX(e.salary)            AS max_salary,
       MIN(e.salary)            AS min_salary
FROM departments d
         LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;
-- Result: IT 2, HR 1, Finance 1, Marketing 0 (salary columns NULL)

-- Exercise 2.3: View with Multiple Joins
-- team_size is counted in a subquery to avoid duplicating project rows
CREATE VIEW project_overview AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = p.dept_id) AS team_size
FROM projects p
         LEFT JOIN departments d ON d.dept_id = p.dept_id;

SELECT * FROM project_overview;
-- Result: 5 projects; AI Research has no department (NULL) and team_size 0

-- Exercise 2.4: View with Filtering
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;
-- Answer: 2 rows - Jane Doe (60000) and Sarah Williams (65000).
-- Mike Johnson earns exactly 55000, which is not > 55000.
-- Because of the INNER JOIN, a high earner without a department would not be
-- shown; here all high earners have a department, so all of them are visible.


-- =====================================================================
-- Part 3: Modifying and Managing Views
-- =====================================================================

-- Exercise 3.1: Replace a View
-- CREATE OR REPLACE keeps the existing columns and adds salary_grade at the end
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
           END AS salary_grade
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- Exercise 3.2: Rename a View
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

-- Exercise 3.3: Drop a View
CREATE VIEW temp_view AS
SELECT emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;
-- Result: Tom Brown (45000)

DROP VIEW temp_view;


-- =====================================================================
-- Part 4: Updatable Views
-- =====================================================================

-- Exercise 4.1: Create an Updatable View
-- one table, no JOIN / GROUP BY / DISTINCT -> PostgreSQL makes it updatable automatically
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- Exercise 4.2: Update Through a View
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';
-- Answer: yes, the underlying employees table was updated (salary = 52000).
-- A view stores no data, so the UPDATE is applied to the base table.

-- Exercise 4.3: Insert Through a View
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees WHERE emp_id = 6;
-- Answer: the insert was successful; Alice Johnson is in the employees table.

-- Exercise 4.4: View with CHECK OPTION
-- LOCAL CHECK OPTION: rows inserted/updated through the view must satisfy its WHERE
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
        WITH LOCAL CHECK OPTION;

-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
-- VALUES (7, 'Bob Wilson', 103, 60000);
-- ERROR: new row violates check option for view "it_employees"
-- DETAIL: Failing row contains (7, Bob Wilson, 103, 60000.00).
-- Answer: dept_id 103 does not satisfy the view condition dept_id = 101.
-- Without CHECK OPTION the row would be inserted into employees but would be
-- invisible through the view; CHECK OPTION forbids that.


-- =====================================================================
-- Part 5: Materialized Views
-- =====================================================================

-- Exercise 5.1: Create a Materialized View
-- employees and projects are counted in separate subqueries:
-- joining both to departments at once would multiply rows (IT: 2 employees x 2 projects)
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(e.total_employees, 0) AS total_employees,
       COALESCE(e.total_salaries, 0)  AS total_salaries,
       COALESCE(p.total_projects, 0)  AS total_projects,
       COALESCE(p.total_budget, 0)    AS total_budget
FROM departments d
         LEFT JOIN (SELECT dept_id, COUNT(*) AS total_employees, SUM(salary) AS total_salaries
                    FROM employees
                    GROUP BY dept_id) e ON e.dept_id = d.dept_id
         LEFT JOIN (SELECT dept_id, COUNT(*) AS total_projects, SUM(budget) AS total_budget
                    FROM projects
                    GROUP BY dept_id) p ON p.dept_id = d.dept_id
    WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;
-- Result: IT 2 / 107000 / 2 / 250000, HR 2 / 118000 / 1 / 50000,
--         Finance 1 / 65000 / 1 / 75000, Marketing 0 / 0 / 0 / 0

-- Exercise 5.2: Refresh Materialized View
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- before refresh
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
-- Result: IT still shows 2 employees, 107000

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- after refresh
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
-- Result: IT shows 3 employees, 161000
-- Answer: a materialized view stores the result of the query at the moment it
-- was created/refreshed. New data appears only after REFRESH.

-- Exercise 5.3: Concurrent Refresh
CREATE UNIQUE INDEX dept_summary_mv_dept_id_idx ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Answer: a normal REFRESH locks the view, so SELECTs must wait until it ends.
-- CONCURRENTLY builds the new result separately and updates only changed rows,
-- so the view can be read during the refresh. It requires a UNIQUE index.

-- Exercise 5.4: Materialized View with NO DATA
-- Lab 6 has no assignments table, so assigned employees = employees of the project's department
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       COUNT(e.emp_id) AS assigned_employees
FROM projects p
         LEFT JOIN departments d ON d.dept_id = p.dept_id
         LEFT JOIN employees e   ON e.dept_id = p.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
    WITH NO DATA;

-- SELECT * FROM project_stats_mv;
-- ERROR: materialized view "project_stats_mv" has not been populated
-- HINT: Use the REFRESH MATERIALIZED VIEW command.
-- Answer: WITH NO DATA creates only the structure, no rows are loaded.
-- Fix: fill it with REFRESH.

REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;


-- =====================================================================
-- Part 6: Database Roles
-- =====================================================================

-- Exercise 6.1: Create Basic Roles
CREATE ROLE analyst;                                   -- NOLOGIN by default
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE USER report_user WITH PASSWORD 'report456';     -- CREATE USER = CREATE ROLE ... LOGIN

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- Exercise 6.2: Role with Specific Attributes
CREATE ROLE db_creator   WITH LOGIN CREATEDB   PASSWORD 'creator789';
CREATE ROLE user_manager WITH LOGIN CREATEROLE PASSWORD 'manager101';
CREATE ROLE admin_user   WITH LOGIN SUPERUSER  PASSWORD 'admin999';

-- Exercise 6.3: Grant Privileges to Roles
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- Exercise 6.4: Create Group Roles
-- 1. group roles (no login)
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

-- 2. individual users
CREATE USER hr_user1      WITH PASSWORD 'hr001';
CREATE USER hr_user2      WITH PASSWORD 'hr002';
CREATE USER finance_user1 WITH PASSWORD 'fin001';

-- 3-4. membership: members inherit the group's privileges
GRANT hr_team      TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

-- 5-6. privileges for the groups
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- Exercise 6.5: Revoke Privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- Exercise 6.6: Modify Role Attributes
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;


-- =====================================================================
-- Part 7: Advanced Role Management
-- =====================================================================

-- Exercise 7.1: Role Hierarchies
-- 1. parent role
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

-- 2. child roles
CREATE USER junior_analyst WITH PASSWORD 'junior123';
CREATE USER senior_analyst WITH PASSWORD 'senior123';

-- 3. both inherit SELECT from read_only
GRANT read_only TO junior_analyst, senior_analyst;

-- 4. extra privileges only for senior_analyst
GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- Exercise 7.2: Object Ownership
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';
-- Result: projects is owned by project_manager, the other tables by postgres
-- (views are listed in pg_views, not pg_tables)

-- Exercise 7.3: Reassign and Drop Roles
CREATE ROLE temp_owner WITH LOGIN;

CREATE TABLE temp_table (id INT);

ALTER TABLE temp_table OWNER TO temp_owner;

-- a role that owns objects cannot be dropped, so first move its objects away
REASSIGN OWNED BY temp_owner TO postgres;

-- removes anything still owned by the role and its granted privileges
DROP OWNED BY temp_owner;

DROP ROLE temp_owner;

-- Exercise 7.4: Row-Level Security with Views
-- the view shows only HR rows; hr_team gets access to the view, not the table
CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

-- finance_team sees only three columns of all employees
CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- =====================================================================
-- Part 8: Practical Scenarios
-- =====================================================================

-- Exercise 8.1: Department Dashboard View
-- The Lab 6 projects table has no status column, so every project is counted
-- as active. Employees and projects are aggregated separately to avoid fan-out.
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       COALESCE(e.employee_count, 0)  AS employee_count,
       ROUND(e.avg_salary, 2)         AS avg_salary,
       COALESCE(p.active_projects, 0) AS active_projects,
       COALESCE(p.total_budget, 0)    AS total_project_budget,
       ROUND(COALESCE(p.total_budget, 0)
                 / NULLIF(COALESCE(e.employee_count, 0), 0), 2) AS budget_per_employee
FROM departments d
         LEFT JOIN (SELECT dept_id, COUNT(*) AS employee_count, AVG(salary) AS avg_salary
                    FROM employees
                    GROUP BY dept_id) e ON e.dept_id = d.dept_id
         LEFT JOIN (SELECT dept_id, COUNT(*) AS active_projects, SUM(budget) AS total_budget
                    FROM projects
                    GROUP BY dept_id) p ON p.dept_id = d.dept_id;
-- NULLIF(x, 0) turns 0 into NULL, so a department with 0 employees gives
-- NULL instead of a division-by-zero error.

SELECT * FROM dept_dashboard;

-- Exercise 8.2: Audit View
ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
           END AS approval_status
FROM projects p
         LEFT JOIN departments d ON d.dept_id = p.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;
-- Result: Website Redesign (Standard Process), Cloud Migration (Management
-- Approval Needed), AI Research (Critical Review Required, no department)

-- Exercise 8.3: Create Access Control System
-- each level inherits the privileges of the level below it

-- Level 1 - Viewer Role
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;   -- includes views

-- Level 2 - Entry Role
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3 - Analyst Role
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4 - Manager Role
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Users
CREATE USER alice   WITH PASSWORD 'alice123';
CREATE USER bob     WITH PASSWORD 'bob123';
CREATE USER charlie WITH PASSWORD 'charlie123';

GRANT viewer_role  TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
-- alice: SELECT; bob: SELECT, INSERT, UPDATE; charlie: SELECT, INSERT, UPDATE, DELETE