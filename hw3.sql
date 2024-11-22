-- Seminar queries, see homework #3 below
CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    manager_id INT REFERENCES employees(employee_id)
);

-- Пример данных
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Alice Johnson', 'Manager', 'Sales', 85000, NULL),
    ('Bob Smith', 'Sales Associate', 'Sales', 50000, 1),
    ('Carol Lee', 'Sales Associate', 'Sales', 48000, 1),
    ('David Brown', 'Sales Intern', 'Sales', 30000, 2),
    ('Eve Davis', 'Developer', 'IT', 75000, NULL),
    ('Frank Miller', 'Intern', 'IT', 35000, 5);

SELECT * FROM employees LIMIT 5;

CREATE TABLE IF NOT EXISTS sales(
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);

-- Пример данных
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES
    (2, 1, 20, '2024-10-15'),
    (2, 2, 15, '2024-10-16'),
    (3, 1, 10, '2024-10-17'),
    (3, 3, 5, '2024-10-20'),
    (4, 2, 8, '2024-10-21'),
    (2, 1, 12, '2024-11-01'),
    (1, 2, 3, '2024-11-09'),
    (3, 3, 2, '2024-11-11'),
    (4, 2, 8, '2024-11-13'),
    (1, 3, 20, '2024-11-14'),
    (1, 1, 26, '2024-11-16');


CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

-- Пример данных
INSERT INTO products (name, price)
VALUES
    ('Product A', 150.00),
    ('Product B', 200.00),
    ('Product C', 100.00);

-------------------------------------------
--------------- Homework #3 ---------------
-------------------------------------------
-- 1. Создайте временную таблицу high_sales_products, которая будет содержать продукты, 
-- проданные в количестве более 10 единиц за последние 7 дней. 
-- Выведите данные из таблицы high_sales_products 
-- 2. Создайте CTE employee_sales_stats, который посчитает общее количество продаж 
-- и среднее количество продаж для каждого сотрудника за последние 30 дней. 
-- Напишите запрос, который выводит сотрудников с количеством продаж выше среднего по компании 
-- 3. Используя CTE, создайте иерархическую структуру, показывающую всех сотрудников, 
-- которые подчиняются конкретному менеджеру
-- 4. Напишите запрос с CTE, который выведет топ-3 продукта по количеству продаж за текущий месяц 
-- и за прошлый месяц. 
-- В результатах должно быть указано, к какому месяцу относится каждая запись
-- 5. Создайте индекс для таблицы sales по полю employee_id и sale_date. 
-- Проверьте, как наличие индекса влияет на производительность следующего запроса, 
-- используя трассировку (EXPLAIN ANALYZE)
-- 6. Используя трассировку, проанализируйте запрос, 
-- который находит общее количество проданных единиц каждого продукта.


-- 1. create temporary table high_sales_products 
CREATE TEMP TABLE high_sales_products AS
SELECT p.product_id, p.name AS product_name, p.price AS product_price, SUM(s.quantity) AS total_quantity
    FROM sales s
        JOIN products p ON s.product_id = p.product_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY p.product_id, p.name, p.price
    HAVING SUM(s.quantity) > 10;

-- print data from high_sales_products
SELECT * FROM high_sales_products LIMIT 100;


-- 2. Create CTE employee_sales_stats 
-- LEFT JOIN is used to preserve employee ids with no sales 
-- / 30 is used to normilize quantity by days. 
-- For example: 
--    If we have sales for employee A: [100, 2]
--    and sales for employee B: [100], 
--    then the average for them will be 51 and 100, 
--    even the employee A have sold more.
--    Therefore we need normalization constant.
WITH employee_sales_stats AS (
    SELECT
        e.employee_id,
        e.name AS employee_name,
        SUM(s.quantity) AS total_sales,
        AVG(s.quantity) / 30 AS avg_sales_by_day
    FROM employees e
    LEFT JOIN sales s ON e.employee_id = s.employee_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY e.employee_id, e.name
)

SELECT * FROM employee_sales_stats LIMIT 100;

-- Sales more than average
WITH sales_avg AS (
    SELECT AVG(quantity) as avg_quantity FROM sales
), employee_sales_more_avg AS (
    SELECT
        e.employee_id,
        e.name AS employee_name,
        SUM(s.quantity) AS total_sales
    FROM employees e
    LEFT JOIN sales s ON e.employee_id = s.employee_id
    GROUP BY (e.employee_id, e.name)
    HAVING SUM(s.quantity) > (SELECT * FROM sales_avg)
)
SELECT * FROM employee_sales_more_avg LIMIT 100;


-- 3. Show hierarchy of manager with id = 1. Using recursive CTE.
WITH RECURSIVE employee_hierarchy AS (
    SELECT
        e.employee_id,
        e.name AS employee_name,
        e.manager_id,
        e.position,
        e.department,
        0 AS level
    FROM employees e
    WHERE e.employee_id = 1 

    UNION ALL
    SELECT
        e.employee_id,
        e.name AS employee_name,
        e.manager_id,
        e.position,
        e.department,
        eh.level - 1 AS level
    FROM employees e, employee_hierarchy eh
    WHERE e.manager_id = eh.employee_id
)
SELECT *
    FROM employee_hierarchy
    ORDER BY level DESC, employee_name
    LIMIT 100;


CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);
CREATE TABLE IF NOT EXISTS sales(
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);

-- 4. 
WITH current_month_sales AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        SUM(s.quantity) AS total_quantity
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE DATE_TRUNC('month', s.sale_date) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY p.product_id, p.name
    ORDER BY total_quantity DESC
    LIMIT 3
), last_month_sales AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        SUM(s.quantity) AS total_quantity
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE DATE_TRUNC('month', s.sale_date) = DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
    GROUP BY p.product_id, p.name
    ORDER BY total_quantity DESC
    LIMIT 3
)
SELECT
    'current month' AS period,
    product_id,
    product_name,
    total_quantity
FROM current_month_sales
UNION ALL
SELECT
    'last month' AS period,
    product_id,
    product_name,
    total_quantity
FROM last_month_sales
ORDER BY period, total_quantity DESC;

-- 5. Let's create some query, that uses `employee_id` and `sale_date` from `sales` table.
-- Insert additional data:
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
SELECT
    FLOOR(RANDOM() * 5 + 1)::INT AS employee_id,
    FLOOR(RANDOM() * 3 + 1)::INT AS product_id,
    FLOOR(RANDOM() * 50 + 1)::INT AS quantity,
    CURRENT_DATE - (RANDOM() * 365)::INT
FROM
    generate_series(1, 100000);

-- Before index
EXPLAIN ANALYZE
SELECT employee_id, sale_date
FROM sales
WHERE employee_id = 2 AND sale_date >= '2024-09-01';
-- Results:
--      Planning Time: 0.035 ms
--      Execution Time: 5.231 ms


-- After creating index
CREATE INDEX employee_sale_date_idx ON sales (employee_id, sale_date);

EXPLAIN ANALYZE
SELECT employee_id, sale_date
FROM sales
WHERE employee_id = 2 AND sale_date >= '2024-09-01';
-- Results:
--      Planning Time: 0.072 ms
--      Execution Time: 1.442 ms



-- Note: in fact, after creating the index, some queries were slower than without the index, 
-- so, you need to think whether you really need index or not.


-- 6
EXPLAIN ANALYZE
SELECT s.product_id, p.name, SUM(s.quantity)
    FROM sales s
        INNER JOIN products p ON p.product_id=s.product_id 
    GROUP BY product_id
    LIMIT 100;

-- QUERY PLAN: 
-- Limit  (cost=1512.11..3366.51 rows=100 width=130) (actual time=52.502..74.679 rows=3 loops=1)
--   ->  GroupAggregate  (cost=1512.11..743271.51 rows=40000 width=130) (actual time=52.501..74.677 rows=3 loops=1)
--         Group Key: s.product_id, p.name
--         ->  Incremental Sort  (cost=1512.11..742121.43 rows=100011 width=126) (actual time=33.896..66.966 rows=100011 loops=1)
--               Sort Key: s.product_id, p.name
--               Presorted Key: s.product_id
--               Full-sort Groups: 3  Sort Method: quicksort  Average Memory: 27kB  Peak Memory: 27kB
--               Pre-sorted Groups: 3  Sort Method: quicksort  Average Memory: 2838kB  Peak Memory: 2841kB
--               ->  Nested Loop  (cost=0.15..737024.48 rows=100011 width=126) (actual time=0.010..53.512 rows=100011 loops=1)
--                     Join Filter: (p.product_id = s.product_id)
--                     Rows Removed by Join Filter: 200022
--                     ->  Index Scan using products_pkey on products p  (cost=0.15..55.50 rows=490 width=122) (actual time=0.002..0.016 rows=3 loops=1)
--                     ->  Materialize  (cost=0.00..2138.16 rows=100011 width=8) (actual time=0.005..10.964 rows=100011 loops=3)
--                           ->  Seq Scan on sales s  (cost=0.00..1638.11 rows=100011 width=8) (actual time=0.005..6.785 rows=100011 loops=1)
-- Planning Time: 0.150 ms
-- Execution Time: 75.150 ms


DROP TABLE IF EXISTS high_sales_products;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS employees;


