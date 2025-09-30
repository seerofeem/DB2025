
CREATE DATABASE advanced_lab WITH ENCODING='UTF8' TEMPLATE=template0;




CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) UNIQUE NOT NULL,
    budget INTEGER NOT NULL CHECK (budget >= 0),
    manager_id INTEGER NULL 
);

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_id INTEGER REFERENCES departments(dept_id),
    salary INTEGER CHECK (salary >= 0),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    start_date DATE,
    end_date DATE,
    budget INTEGER CHECK (budget >= 0)
);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
  ('Unassigned', 0, NULL),
  ('IT', 150000, NULL),
  ('Sales', 120000, NULL),
  ('Management', 300000, NULL),
  ('Senior', 80000, NULL),
  ('Junior', 30000, NULL)
RETURNING *;  

INSERT INTO employees (first_name, last_name, department_id)
VALUES
  ('bob', 'bober', (SELECT dept_id FROM departments WHERE dept_name = 'IT')),
  ('bill', 'biller', (SELECT dept_id FROM departments WHERE dept_name = 'Sales'))
RETURNING emp_id, first_name, last_name, department_id;

INSERT INTO employees (first_name, last_name, department_id)
VALUES ('chubrik', 'chubik', (SELECT dept_id FROM departments WHERE dept_name = 'Unassigned'))
RETURNING emp_id, first_name || ' ' || last_name AS full_name, salary, status;

INSERT INTO departments (dept_name, budget)
VALUES
  ('R&D', 200000),
  ('HR', 60000),
  ('Support', 50000)
RETURNING *;

INSERT INTO employees (first_name, last_name, department_id, salary, hire_date)
VALUES (
  'asd', 'dsa',
  (SELECT dept_id FROM departments WHERE dept_name = 'R&D'),
  CAST(50000 * 1.1 AS INTEGER),
  CURRENT_DATE
)
RETURNING emp_id, first_name, last_name, salary, hire_date;

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department_id = (SELECT dept_id FROM departments WHERE dept_name = 'IT');

SELECT * FROM temp_employees;


INSERT INTO employees (first_name, last_name, department_id, salary, hire_date, status)
VALUES
  ('Erlan', 'Tleubayev', (SELECT dept_id FROM departments WHERE dept_name = 'IT'), 70000, '2018-06-15', 'Active'),
RETURNING emp_id, first_name, last_name, department_id, salary, hire_date, status;


UPDATE employees
SET salary = CAST(salary * 1.10 AS INTEGER)
WHERE salary IS NOT NULL
RETURNING emp_id, first_name, last_name, salary;


UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date IS NOT NULL
  AND hire_date < DATE '2020-01-01'
RETURNING emp_id, first_name, last_name, salary, hire_date, status;

UPDATE employees
SET department_id = CASE
    WHEN salary > 80000 THEN (SELECT dept_id FROM departments WHERE dept_name = 'Management' LIMIT 1)
    WHEN salary BETWEEN 50000 AND 80000 THEN (SELECT dept_id FROM departments WHERE dept_name = 'Senior' LIMIT 1)
    ELSE (SELECT dept_id FROM departments WHERE dept_name = 'Junior' LIMIT 1)
END

WHERE salary IS NOT NULL
RETURNING emp_id, first_name, last_name, salary, department_id;

UPDATE employees
SET department_id = (SELECT dept_id FROM departments WHERE dept_name = 'Unassigned' LIMIT 1)
WHERE status = 'Inactive'
RETURNING emp_id, first_name, last_name, status, department_id;

UPDATE departments d
SET budget = CAST(
    COALESCE((SELECT AVG(salary) FROM employees e WHERE e.department_id = d.dept_id AND salary IS NOT NULL), 0) * 1.20
    AS INTEGER)

UPDATE employees
SET salary = CAST(salary * 1.15 AS INTEGER),
    status = 'Promoted'
WHERE department_id = (SELECT dept_id FROM departments WHERE dept_name = 'Sales')
  AND salary IS NOT NULL
RETURNING emp_id, first_name, last_name, salary, status;

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES
  ('Website Overhaul', (SELECT dept_id FROM departments WHERE dept_name = 'IT'), '2022-01-01', '2022-06-01', 40000),
  ('New Product Launch', (SELECT dept_id FROM departments WHERE dept_name = 'R&D'), '2021-05-01', '2021-12-31', 120000),
  ('Legacy Migration', (SELECT dept_id FROM departments WHERE dept_name = 'Support'), '2019-03-01', '2022-02-01', 30000),
  ('Old Campaign', (SELECT dept_id FROM departments WHERE dept_name = 'Marketing' LIMIT 1), '2018-01-01', '2019-01-01', 25000)
ON CONFLICT DO NOTHING;

INSERT INTO employees (first_name, last_name, department_id, salary, hire_date, status)
VALUES ('Term', 'One', (SELECT dept_id FROM departments WHERE dept_name = 'Support'), 30000, '2019-01-01', 'Terminated');

DELETE FROM employees
WHERE status = 'Terminated'
RETURNING emp_id, first_name, last_name, status;

INSERT INTO employees (first_name, last_name, department_id, salary, hire_date, status)
VALUES ('52', '228', NULL, 35000, '2024-04-01', 'Active');

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department_id IS NULL
RETURNING emp_id, first_name, last_name, salary, hire_date, department_id;


DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT department_id FROM employees WHERE department_id IS NOT NULL
)
RETURNING dept_id, dept_name;
DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;


INSERT INTO employees (first_name, last_name, department_id, salary, hire_date, status)
VALUES ('Null', 'Fields', NULL, NULL, CURRENT_DATE, 'Active')
RETURNING emp_id, first_name, last_name, department_id, salary;

UPDATE employees
SET department_id = (SELECT dept_id FROM departments WHERE dept_name = 'Unassigned' LIMIT 1)
WHERE department_id IS NULL
RETURNING emp_id, first_name, last_name, department_id;

DELETE FROM employees
WHERE salary IS NULL OR department_id IS NULL
RETURNING emp_id, first_name, last_name, salary, department_id;


INSERT INTO employees (first_name, last_name, department_id, salary, hire_date)
VALUES ('Jamal', 'Aman', (SELECT dept_id FROM departments WHERE dept_name = 'IT'), 65000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;


WITH before AS (
    SELECT emp_id, salary AS old_salary
    FROM employees
    WHERE department_id = (SELECT dept_id FROM departments WHERE dept_name = 'IT')
)
UPDATE employees e
SET salary = salary + 5000
FROM before b
WHERE e.emp_id = b.emp_id
RETURNING e.emp_id, b.old_salary, e.salary AS new_salary;


DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department_id, salary, hire_date)
SELECT 'Unique', 'Person', (SELECT dept_id FROM departments WHERE dept_name = 'HR' LIMIT 1), 40000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.first_name = 'Unique' AND e.last_name = 'Person'
)
RETURNING *;

UPDATE employees e
SET salary = CAST(
    CASE
        WHEN d.budget > 100000 THEN e.salary * 1.10
        ELSE e.salary * 1.05
    END
AS INTEGER)
FROM departments d
WHERE e.department_id = d.dept_id
  AND e.salary IS NOT NULL
RETURNING e.emp_id, e.first_name, e.last_name, d.dept_name, e.salary;


INSERT INTO employees (first_name, last_name, department_id, salary, hire_date)
VALUES
  ('Kair', 'One', (SELECT dept_id FROM departments WHERE dept_name = 'Support' LIMIT 1), 30000, CURRENT_DATE),
  ('Lila', 'Two', (SELECT dept_id FROM departments WHERE dept_name = 'Support' LIMIT 1), 32000, CURRENT_DATE),
  ('Musa', 'Three', (SELECT dept_id FROM departments WHERE dept_name = 'Support' LIMIT 1), 31000, CURRENT_DATE),
  ('Nora', 'Four', (SELECT dept_id FROM departments WHERE dept_name = 'Support' LIMIT 1), 33000, CURRENT_DATE),
  ('Omar', 'Five', (SELECT dept_id FROM departments WHERE dept_name = 'Support' LIMIT 1), 34000, CURRENT_DATE)
RETURNING emp_id, first_name, last_name, salary;


UPDATE employees
SET salary = CAST(salary * 1.10 AS INTEGER)
WHERE first_name IN ('Kair','Lila','Musa','Nora','Omar')
RETURNING emp_id, first_name, salary;

DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE FALSE; 

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive'
RETURNING *;

DELETE FROM employees WHERE status = 'Inactive';
WITH dept_counts AS (
    SELECT department_id, COUNT(*) AS emp_count
    FROM employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
)
UPDATE projects p
SET end_date = (p.end_date + INTERVAL '30 days')::date
FROM departments d
JOIN dept_counts dc ON d.dept_id = dc.department_id
WHERE p.dept_id = d.dept_id
  AND p.budget > 50000
  AND dc.emp_count > 3
RETURNING p.project_id, p.project_name, p.dept_id, p.end_date, p.budget;
