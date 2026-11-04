-- =====================================================================
-- PostgreSQL JOINs - Lecture Tasks
-- Name:       Azimbekuly Nurdilda
-- Student ID: 25b031238
-- =====================================================================


-- =====================================================================
-- Shared schema
-- =====================================================================
CREATE TABLE departments (
                             dept_id serial PRIMARY KEY,
                             name    text NOT NULL UNIQUE,
                             budget  numeric(12,2)
);

CREATE TABLE instructors (
                             instr_id   serial PRIMARY KEY,
                             full_name  text NOT NULL,
                             dept_id    int REFERENCES departments,     -- may be NULL
                             manager_id int REFERENCES instructors,     -- self-reference
                             salary     numeric(10,2) NOT NULL
);

CREATE TABLE courses (
                         course_id serial PRIMARY KEY,
                         code      text NOT NULL UNIQUE,
                         title     text NOT NULL,
                         dept_id   int  NOT NULL REFERENCES departments,
                         credits   int  NOT NULL
);

CREATE TABLE prerequisites (
                               course_id int REFERENCES courses,
                               prereq_id int REFERENCES courses,
                               PRIMARY KEY (course_id, prereq_id)
);

CREATE TABLE students (
                          student_id serial PRIMARY KEY,
                          full_name  text NOT NULL,
                          advisor_id int REFERENCES instructors      -- may be NULL
);

CREATE TABLE sections (
                          section_id serial PRIMARY KEY,
                          course_id  int  NOT NULL REFERENCES courses,
                          instr_id   int  REFERENCES instructors,    -- NULL = not assigned yet
                          semester   text NOT NULL,
                          starts_on  date NOT NULL,
                          capacity   int  NOT NULL
);

CREATE TABLE enrollments (
                             student_id int REFERENCES students,
                             section_id int REFERENCES sections,
                             score      numeric(5,2),                   -- NULL = in progress
                             PRIMARY KEY (student_id, section_id)
);

CREATE TABLE grade_scale (
                             letter    text PRIMARY KEY,
                             min_score numeric(5,2) NOT NULL,
                             max_score numeric(5,2) NOT NULL
);


-- =====================================================================
-- Sample data (designed so that every task returns something to look at)
-- =====================================================================
INSERT INTO departments (name, budget) VALUES
                                           ('Computer Science', 5000000),     -- 1
                                           ('Mathematics',      3000000),     -- 2
                                           ('Physics',          2500000),     -- 3
                                           ('Philosophy',       1000000);     -- 4: offers no courses (I2)

INSERT INTO instructors (full_name, dept_id, manager_id, salary) VALUES
                                                                     ('Aibek Nurlanov',  1,    NULL, 900000),   -- 1: CS head
                                                                     ('Dana Seitova',    1,    1,    950000),   -- 2: earns more than manager (I3)
                                                                     ('Arman Kim',       1,    1,    700000),   -- 3
                                                                     ('Saule Abenova',   2,    NULL, 800000),   -- 4: Math head
                                                                     ('Timur Ospanov',   2,    4,    800000),   -- 5: salary tie with Saule (A6)
                                                                     ('Madina Zhaksy',   NULL, NULL, 600000),   -- 6: no department
                                                                     ('Yerlan Bek',      1,    1,    650000);   -- 7: CS, no sections at all (I7)

INSERT INTO courses (code, title, dept_id, credits) VALUES
                                                        ('CSE1101',  'Programming Basics', 1, 5),  -- 1
                                                        ('CSE2101',  'Data Structures',    1, 5),  -- 2
                                                        ('CSE3101',  'Databases',          1, 5),  -- 3
                                                        ('CSE4101',  'Machine Learning',   1, 6),  -- 4
                                                        ('MATH1101', 'Calculus',           2, 5),  -- 5
                                                        ('MATH2101', 'Linear Algebra',     2, 5),  -- 6
                                                        ('PHYS1101', 'Physics I',          3, 4);  -- 7

-- CSE4101 <- CSE3101 <- CSE2101 <- CSE1101, CSE4101 <- MATH2101 <- MATH1101,
-- CSE4101 <- CSE2101 directly (so CSE2101 is reachable at depth 1 and 2)
INSERT INTO prerequisites VALUES
                              (2, 1), (3, 2), (4, 3), (4, 2), (4, 6), (6, 5);

INSERT INTO students (full_name, advisor_id) VALUES
                                                 ('Aruzhan Bekova',  2),     -- 1
                                                 ('Dias Karimov',    2),     -- 2
                                                 ('Madi Serikov',    3),     -- 3
                                                 ('Zhanna Abenova',  NULL),  -- 4: no advisor
                                                 ('Alina Mukhanova', 2),     -- 5
                                                 ('Nurlan Omarov',   2),     -- 6  (Dana Seitova has 4 advisees -> A1)
                                                 ('Kamila Ospanova', 4);     -- 7

INSERT INTO sections (course_id, instr_id, semester, starts_on, capacity) VALUES
                                                                              (1, 1,    '2026-SPRING', '2026-01-15', 30),  -- 1
                                                                              (2, 2,    '2026-SPRING', '2026-01-15', 30),  -- 2
                                                                              (5, 4,    '2026-SPRING', '2026-01-15', 30),  -- 3
                                                                              (3, 3,    '2026-SPRING', '2026-01-15', 30),  -- 4
                                                                              (2, 2,    '2026-FALL',   '2026-09-01',  2),  -- 5: overbooked (I4)
                                                                              (3, 2,    '2026-FALL',   '2026-09-01', 30),  -- 6
                                                                              (4, 2,    '2026-FALL',   '2026-09-01', 25),  -- 7
                                                                              (6, 4,    '2026-FALL',   '2026-09-01', 20),  -- 8: empty section (I4)
                                                                              (1, NULL, '2026-FALL',   '2026-09-01', 20),  -- 9: no instructor -> 'TBA'
                                                                              (7, 6,    '2026-FALL',   '2026-09-01', 15),  -- 10
                                                                              (1, 1,    '2025-FALL',   '2025-09-01', 30),  -- 11
                                                                              (4, 1,    '2026-SPRING', '2026-01-15', 20);  -- 12

INSERT INTO enrollments VALUES
                            -- 2025-FALL
                            (6, 11, 75),
                            -- 2026-SPRING
                            (1, 1, 95), (2, 1, 45), (3, 1, 70), (5, 1, 88),
                            (1, 2, 92), (3, 2, 85), (5, 2, 40),
                            (6, 3, 90), (7, 3, 88),                        -- Saule's section avg 89 (A7)
                            (1, 4, 89.5),                                  -- falls in the 89-90 gap (I6)
                            (1, 12, 91),
                            -- 2026-FALL
                            (2, 5, NULL), (4, 5, 60), (6, 5, NULL),        -- 3 students, capacity 2
                            (1, 6, NULL), (3, 6, NULL),
                            (5, 7, NULL),
                            (4, 9, NULL), (7, 9, NULL),                    -- TBA section, in progress (A7)
                            (3, 10, 77);

INSERT INTO grade_scale VALUES
                            ('A', 90, 100),
                            ('B', 80,  89),
                            ('C', 70,  79),
                            ('D', 50,  69),
                            ('F',  0,  49);


-- =====================================================================
-- Intermediate tasks
-- =====================================================================

-- I1. Sections with an optional instructor
SELECT s.section_id, c.code, c.title,
       COALESCE(i.full_name, 'TBA') AS instructor
FROM sections s
         JOIN courses c          ON c.course_id = s.course_id
         LEFT JOIN instructors i ON i.instr_id  = s.instr_id
WHERE s.semester = '2026-FALL'
ORDER BY c.code;
-- Result: 6 sections; section 9 (CSE1101) shows 'TBA'.
-- courses uses INNER JOIN (every section has a course),
-- instructors uses LEFT JOIN (instr_id may be NULL).

-- I2. Departments with no courses (anti-join)
-- Way 1: LEFT JOIN + IS NULL
SELECT d.name
FROM departments d
         LEFT JOIN courses c ON c.dept_id = d.dept_id
WHERE c.course_id IS NULL;

-- Way 2: NOT EXISTS
SELECT d.name
FROM departments d
WHERE NOT EXISTS (SELECT 1 FROM courses c WHERE c.dept_id = d.dept_id);
-- Result (both): Philosophy.
-- We test c.course_id (the PK, never NULL in a real row): if it is NULL,
-- the row came from the LEFT JOIN with no match. Testing a nullable column
-- could also catch real rows that just have NULL there.

-- I3. Self-join
SELECT e.full_name AS instructor, m.full_name AS manager,
       e.salary, m.salary AS manager_salary
FROM instructors e
         LEFT JOIN instructors m ON m.instr_id = e.manager_id;

-- Earning more than the manager
SELECT e.full_name, e.salary, m.full_name AS manager, m.salary
FROM instructors e
         JOIN instructors m ON m.instr_id = e.manager_id
WHERE e.salary > m.salary;
-- Result: Dana Seitova (950000) > Aibek Nurlanov (900000).
-- Why INNER JOIN: an instructor without a manager has nothing to compare with;
-- with LEFT JOIN, m.salary would be NULL and "e.salary > NULL" is never TRUE,
-- so those rows would be removed anyway. INNER JOIN states this directly.

-- I4. Counting with outer joins
-- Full list (including empty sections)
SELECT s.section_id, c.code, COUNT(e.student_id) AS enrolled, s.capacity
FROM sections s
         JOIN courses c          ON c.course_id = s.course_id
         LEFT JOIN enrollments e ON e.section_id = s.section_id
WHERE s.semester = '2026-FALL'
GROUP BY s.section_id, c.code
ORDER BY s.section_id;
-- Result: section 8 (MATH2101) shows enrolled = 0.

-- Only overbooked sections
SELECT s.section_id, c.code, COUNT(e.student_id) AS enrolled, s.capacity
FROM sections s
         JOIN courses c          ON c.course_id = s.course_id
         LEFT JOIN enrollments e ON e.section_id = s.section_id
WHERE s.semester = '2026-FALL'
GROUP BY s.section_id, c.code
HAVING COUNT(e.student_id) > s.capacity;
-- Result: section 5 (CSE2101): 3 enrolled, capacity 2.
-- COUNT(*) would return 1 for an empty section (it counts the NULL row),
-- COUNT(e.student_id) skips NULL and returns 0.
-- s.capacity is not in GROUP BY: s.section_id is the PK, so capacity is
-- functionally dependent on it.

-- I5. The ON vs WHERE trap
-- Wrong: the WHERE filter turns the LEFT JOINs into INNER JOINs
SELECT st.full_name, e.score
FROM students st
         LEFT JOIN enrollments e ON e.student_id = st.student_id
         LEFT JOIN sections s    ON s.section_id = e.section_id
         LEFT JOIN courses c     ON c.course_id  = s.course_id
WHERE c.code = 'CSE2101' AND s.semester = '2026-FALL';
-- Result: only 3 students (those enrolled in CSE2101 FALL).

-- Correct: filter moved into a nested join
SELECT st.full_name, e.score
FROM students st
         LEFT JOIN (enrollments e
    JOIN sections s ON s.section_id = e.section_id
    JOIN courses c  ON c.course_id  = s.course_id)
                   ON e.student_id = st.student_id
                       AND c.code = 'CSE2101'
                       AND s.semester = '2026-FALL';
-- Result: all 7 students; those not enrolled have score NULL.

-- I6. Non-equi join
SELECT st.full_name, c.code, e.score, g.letter
FROM enrollments e
         JOIN students st USING (student_id)
         JOIN sections s  USING (section_id)
         JOIN courses c   USING (course_id)
         LEFT JOIN grade_scale g
                   ON e.score BETWEEN g.min_score AND g.max_score;
-- Score 89.5 (Aruzhan, CSE3101) gets letter NULL: it is above 89 (B max)
-- and below 90 (A min), so no range matches.
-- Fix with half-open ranges: score >= min_score AND score < next min_score.
-- Using the existing table: treat max_score of B as "below 90":
SELECT st.full_name, c.code, e.score, g.letter
FROM enrollments e
         JOIN students st USING (student_id)
         JOIN sections s  USING (section_id)
         JOIN courses c   USING (course_id)
         LEFT JOIN grade_scale g
                   ON e.score >= g.min_score
                       AND e.score <  COALESCE((SELECT MIN(g2.min_score)
                                                FROM grade_scale g2
                                                WHERE g2.min_score > g.min_score), 1000);
-- Result: 89.5 now gets 'B'.

-- I7. FULL OUTER JOIN reconciliation
SELECT i.full_name, s.section_id
FROM (SELECT * FROM instructors
      WHERE dept_id = (SELECT dept_id FROM departments
                       WHERE name = 'Computer Science')) i
         FULL JOIN (SELECT * FROM sections
                    WHERE semester = '2026-FALL') s
                   ON s.instr_id = i.instr_id
WHERE i.instr_id IS NULL OR s.section_id IS NULL;
-- Result: instructors without a FALL section: Aibek Nurlanov, Arman Kim, Yerlan Bek.
--         sections without a (CS) instructor: 8, 9, 10.
-- Note: sections 8 and 10 belong to Math/Physics; they appear because the
-- sections subquery is not limited to CS courses. Only section 9 is a CS
-- section that really has no instructor. Version limited to CS sections:
SELECT i.full_name, s.section_id
FROM (SELECT * FROM instructors
      WHERE dept_id = (SELECT dept_id FROM departments
                       WHERE name = 'Computer Science')) i
         FULL JOIN (SELECT s.*
                    FROM sections s
                             JOIN courses c ON c.course_id = s.course_id
                             JOIN departments d ON d.dept_id = c.dept_id
                    WHERE s.semester = '2026-FALL'
                      AND d.name = 'Computer Science') s
                   ON s.instr_id = i.instr_id
WHERE i.instr_id IS NULL OR s.section_id IS NULL;
-- Why subqueries: a filter like "WHERE i.dept_id = 1" placed after a FULL JOIN
-- removes the rows where i is NULL, i.e. exactly the unmatched sections.

-- I8. Composite join condition
SELECT st.full_name, i.full_name AS advisor, c.code
FROM students st
         JOIN enrollments e ON e.student_id = st.student_id
         JOIN sections s    ON s.section_id = e.section_id
    AND s.instr_id   = st.advisor_id
         JOIN instructors i ON i.instr_id   = st.advisor_id
         JOIN courses c     ON c.course_id  = s.course_id
WHERE s.semester = '2026-FALL';
-- Result: Aruzhan (CSE3101), Dias (CSE2101), Nurlan (CSE2101),
--         Alina (CSE4101) - all taught by their advisor Dana Seitova.


-- =====================================================================
-- Advanced tasks
-- =====================================================================

-- A1. Fan-out (double counting)
-- Wrong: sections x advisees rows per instructor
SELECT i.full_name, COUNT(s.section_id), COUNT(st.student_id)
FROM instructors i
         LEFT JOIN sections s  ON s.instr_id    = i.instr_id
         LEFT JOIN students st ON st.advisor_id = i.instr_id
GROUP BY i.instr_id;
-- Result: Dana Seitova shows 16 and 16 (4 sections x 4 advisees).

-- Correct: pre-aggregate each branch
SELECT i.full_name,
       COALESCE(s.cnt, 0) AS sections,
       COALESCE(a.cnt, 0) AS advisees
FROM instructors i
         LEFT JOIN (SELECT instr_id, COUNT(*) AS cnt
                    FROM sections GROUP BY instr_id) s ON s.instr_id = i.instr_id
         LEFT JOIN (SELECT advisor_id, COUNT(*) AS cnt
                    FROM students GROUP BY advisor_id) a ON a.advisor_id = i.instr_id;
-- Result: Dana Seitova: 4 sections, 4 advisees.
-- COUNT(DISTINCT id) fixes counts because ids are unique. It does not work for
-- SUM(salary) or AVG(score): without DISTINCT every value is multiplied by the
-- fan-out, and with DISTINCT two different rows that happen to have the same
-- value (two scores of 90) are merged into one - the result is wrong either way.

-- A2. Top-N per group with LATERAL
SELECT c.code, t.full_name, t.score
FROM courses c
         LEFT JOIN LATERAL (
    SELECT st.full_name, e.score
    FROM sections s
             JOIN enrollments e ON e.section_id = s.section_id
             JOIN students st   ON st.student_id = e.student_id
    WHERE s.course_id = c.course_id
      AND e.score IS NOT NULL
    ORDER BY e.score DESC
        FETCH FIRST 3 ROWS WITH TIES
        ) t ON true
ORDER BY c.code, t.score DESC;
-- LEFT JOIN LATERAL ... ON true keeps courses with no grades (CSE4101 has one,
-- PHYS1101 has one, MATH2101 none -> shown with NULL).
-- CROSS JOIN LATERAL would drop courses with no graded students.
-- WITH TIES: if the 3rd and 4th scores are equal, both are returned.

-- Same result with a window function
SELECT code, full_name, score
FROM (
         SELECT c.code, st.full_name, e.score,
                RANK() OVER (PARTITION BY c.course_id ORDER BY e.score DESC) AS rnk
         FROM courses c
                  JOIN sections s    ON s.course_id  = c.course_id
                  JOIN enrollments e ON e.section_id = s.section_id
                  JOIN students st   ON st.student_id = e.student_id
         WHERE e.score IS NOT NULL
     ) ranked
WHERE rnk <= 3
ORDER BY code, score DESC;
-- RANK keeps ties like WITH TIES; ROW_NUMBER would cut them at exactly 3.
-- This version uses inner joins, so courses with no grades are not shown.

-- A3. Prerequisite violations
SELECT st.full_name, c.code AS course, pc.code AS missing_prereq
FROM enrollments e
         JOIN sections s      ON s.section_id = e.section_id
         JOIN students st     ON st.student_id = e.student_id
         JOIN courses c       ON c.course_id  = s.course_id
         JOIN prerequisites p ON p.course_id  = s.course_id
         JOIN courses pc      ON pc.course_id = p.prereq_id
WHERE s.semester = '2026-FALL'
  AND NOT EXISTS (
    SELECT 1
    FROM enrollments e2
             JOIN sections s2 ON s2.section_id = e2.section_id
    WHERE e2.student_id = e.student_id
      AND s2.course_id  = p.prereq_id
      AND s2.starts_on  < s.starts_on
      AND e2.score      >= 50
);
-- Result: Dias (CSE2101 <- CSE1101, he got 45), Zhanna (CSE2101 <- CSE1101),
--         Alina (CSE4101 <- CSE2101, CSE3101, MATH2101).
-- Nurlan is not listed: he passed CSE1101 in 2025-FALL.

-- Rewrite with NOT IN
SELECT st.full_name, c.code AS course, pc.code AS missing_prereq
FROM enrollments e
         JOIN sections s      ON s.section_id = e.section_id
         JOIN students st     ON st.student_id = e.student_id
         JOIN courses c       ON c.course_id  = s.course_id
         JOIN prerequisites p ON p.course_id  = s.course_id
         JOIN courses pc      ON pc.course_id = p.prereq_id
WHERE s.semester = '2026-FALL'
  AND p.prereq_id NOT IN (
    SELECT s2.course_id
    FROM enrollments e2
             JOIN sections s2 ON s2.section_id = e2.section_id
    WHERE e2.student_id = e.student_id
      AND s2.starts_on  < s.starts_on
      AND e2.score      >= 50
);
-- Same result here. Danger: if the subquery ever returns a NULL,
-- "x NOT IN (..., NULL)" is NULL (not TRUE) for every x, and the query
-- silently returns no rows. NOT EXISTS has no such problem.

-- A4. Relational division
-- Version 1: counting
SELECT st.student_id, st.full_name
FROM students st
         JOIN enrollments e ON e.student_id = st.student_id AND e.score >= 50
         JOIN sections s    ON s.section_id = e.section_id
         JOIN courses c     ON c.course_id  = s.course_id
         JOIN departments d ON d.dept_id    = c.dept_id
WHERE d.name = 'Computer Science'
GROUP BY st.student_id, st.full_name
HAVING COUNT(DISTINCT c.course_id) = (
    SELECT COUNT(*)
    FROM courses c2
             JOIN departments d2 USING (dept_id)
    WHERE d2.name = 'Computer Science');

-- Version 2: double NOT EXISTS ("no CS course the student hasn't passed")
SELECT st.full_name
FROM students st
WHERE NOT EXISTS (
    SELECT 1
    FROM courses c
             JOIN departments d USING (dept_id)
    WHERE d.name = 'Computer Science'
      AND NOT EXISTS (
        SELECT 1
        FROM enrollments e
                 JOIN sections s USING (section_id)
        WHERE e.student_id = st.student_id
          AND s.course_id  = c.course_id
          AND e.score      >= 50));
-- Result (both): Aruzhan Bekova - passed all 4 CS courses.
-- If CS had zero courses: Version 2 returns every student (there is no course
-- they failed to pass), Version 1 returns none (the joins find no CS rows,
-- so there are no groups at all).

-- A5. Recursive join
WITH RECURSIVE chain AS (
    SELECT p.prereq_id, 1 AS depth, ARRAY[p.course_id, p.prereq_id] AS path
FROM prerequisites p
    JOIN courses c ON c.course_id = p.course_id
WHERE c.code = 'CSE4101'
UNION ALL
SELECT p.prereq_id, ch.depth + 1, ch.path || p.prereq_id
FROM chain ch
         JOIN prerequisites p ON p.course_id = ch.prereq_id
WHERE p.prereq_id <> ALL (ch.path)      -- cycle guard
    )
SELECT c.code, c.title, MIN(ch.depth) AS depth
FROM chain ch
         JOIN courses c ON c.course_id = ch.prereq_id
GROUP BY c.code, c.title
ORDER BY depth, c.code;
-- Result: depth 1: CSE2101, CSE3101, MATH2101; depth 2: CSE1101, MATH1101.
-- CSE2101 is reached at depth 1 and 2 - MIN keeps 1.

-- Alternative with the PostgreSQL 14+ CYCLE clause instead of the manual guard
WITH RECURSIVE chain (course_id, prereq_id, depth) AS (
    SELECT p.course_id, p.prereq_id, 1
    FROM prerequisites p
             JOIN courses c ON c.course_id = p.course_id
    WHERE c.code = 'CSE4101'
    UNION ALL
    SELECT p.course_id, p.prereq_id, ch.depth + 1
    FROM chain ch
             JOIN prerequisites p ON p.course_id = ch.prereq_id
) CYCLE prereq_id SET is_cycle USING path
SELECT c.code, c.title, MIN(ch.depth) AS depth
FROM chain ch
         JOIN courses c ON c.course_id = ch.prereq_id
WHERE NOT ch.is_cycle
GROUP BY c.code, c.title
ORDER BY depth, c.code;

-- A6. Greatest-per-group with ties
-- Join to an aggregate (keeps ties)
SELECT d.name, i.full_name, i.salary
FROM instructors i
         JOIN departments d ON d.dept_id = i.dept_id
         JOIN (SELECT dept_id, MAX(salary) AS max_sal
               FROM instructors GROUP BY dept_id) m
              ON m.dept_id = i.dept_id AND m.max_sal = i.salary;
-- Result: CS - Dana Seitova; Mathematics - Saule Abenova AND Timur Ospanov (tie).

-- DISTINCT ON (PostgreSQL-specific, drops ties)
SELECT DISTINCT ON (i.dept_id) d.name, i.full_name, i.salary
FROM instructors i
    JOIN departments d USING (dept_id)
ORDER BY i.dept_id, i.salary DESC;
-- Result: Mathematics shows only one of the two (whichever comes first).

-- Third version with RANK() (keeps ties)
SELECT name, full_name, salary
FROM (
         SELECT d.name, i.full_name, i.salary,
                RANK() OVER (PARTITION BY i.dept_id ORDER BY i.salary DESC) AS rnk
         FROM instructors i
                  JOIN departments d ON d.dept_id = i.dept_id
     ) r
WHERE rnk = 1;

-- A7. Joins in DML
UPDATE instructors i
SET salary = salary * 1.05
    FROM (
    SELECT s.instr_id
    FROM sections s
    JOIN enrollments e ON e.section_id = s.section_id
    WHERE s.semester = '2026-SPRING' AND e.score IS NOT NULL
    GROUP BY s.instr_id
    HAVING AVG(e.score) >= 85
) top
WHERE top.instr_id = i.instr_id
    RETURNING i.full_name, i.salary;
-- Result: Saule Abenova 800000 -> 840000 (2026-SPRING average 89);
--         Arman Kim 700000 -> 735000 (average 89.5).

DELETE FROM enrollments e
    USING sections s
WHERE s.section_id = e.section_id
  AND s.semester   = '2026-FALL'
  AND s.instr_id IS NULL
  AND e.score IS NULL;
-- Result: DELETE 2 (Zhanna and Kamila in section 9, which has no instructor).
-- The source of the UPDATE is aggregated to one row per instructor: if
-- UPDATE ... FROM matched a target row several times, PostgreSQL would use
-- an arbitrary one of the matches.

-- A8. Join strategies and indexing
-- 1. Plan without an index on enrollments(section_id)
EXPLAIN ANALYZE
SELECT s.section_id, c.code, COUNT(e.student_id) AS enrolled, s.capacity
FROM sections s
         JOIN courses c          ON c.course_id = s.course_id
         LEFT JOIN enrollments e ON e.section_id = s.section_id
WHERE s.semester = '2026-FALL'
GROUP BY s.section_id, c.code;

-- 2. With an index on the FK column
CREATE INDEX ON enrollments (section_id);

EXPLAIN ANALYZE
SELECT s.section_id, c.code, COUNT(e.student_id) AS enrolled, s.capacity
FROM sections s
         JOIN courses c          ON c.course_id = s.course_id
         LEFT JOIN enrollments e ON e.section_id = s.section_id
WHERE s.semester = '2026-FALL'
GROUP BY s.section_id, c.code;

-- 3. Disable hash join and see the fallback strategy
SET enable_hashjoin = off;

EXPLAIN ANALYZE
SELECT s.section_id, c.code, COUNT(e.student_id) AS enrolled, s.capacity
FROM sections s
         JOIN courses c          ON c.course_id = s.course_id
         LEFT JOIN enrollments e ON e.section_id = s.section_id
WHERE s.semester = '2026-FALL'
GROUP BY s.section_id, c.code;

RESET enable_hashjoin;
