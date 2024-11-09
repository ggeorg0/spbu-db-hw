-- homework 1, see homework 2 below
CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(1024) NOT NULL,
    is_exam BOOLEAN NOT NULL,
    min_grade SMALLINT,
    max_grade SMALLINT
);

CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(600) NOT NULL,
    short_name VARCHAR(600),
    students_ids INTEGER[]
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(512) NOT NULL,
    last_name VARCHAR(512),
    group_id INTEGER,
    courses_ids INTEGER[]
);

CREATE TABLE llm_cource (
    student_id INTEGER REFERENCES students(id),
    grade SMALLINT 
        CONSTRAINT normal_grade CHECK (grade > 0 AND grade <= 10),
    grade_str VARCHAR(50),
    PRIMARY KEY (student_id, grade)
);

INSERT INTO courses (name, is_exam, min_grade, max_grade) VALUES 
    ('VK LLMs', true, 1, 10), 
    ('English for IT', false, 1, 5),
    ('Computer Science', true, 1, 10);

INSERT INTO students (first_name, last_name, group_id, courses_ids) VALUES
    ('George', 'Ponomarev', 1, '{1, 2, 3}'),
    ('Ivan', 'Alekseev', 1, '{3}'),
    ('Darya', 'Sobakina', 1, '{4}'),
    ('Anastasia', 'Sobakina', 1, '{4, 5}'),
    ('Vitaly', 'Sobakin', 2, '{1, 2, 3}'),
    ('Max', 'Monetov', 2, '{2, 3}') ,
    ('Polina', 'Gagarina', 1, '{1, 2, 3}') ,
    ('Vasiliy', 'Nemtsov', 1, '{2}') ,
    ('Tamara', 'Drozdova', 2, '{2, 3}') ,
    ('Timur', 'Drozdov', 2, '{2, 3}') ,
    ('Diana', 'Kolesova', 2, '{1, 3}');

INSERT INTO groups (full_name, short_name, students_ids) VALUES
    ('1013 Infomatics and Computer Science', '13', '{1, 4, 5}'),
    ('2011 Software Engeenering', '11', '{2, 3}');

INSERT INTO llm_cource (student_id, grade, grade_str) VALUES
    (1, 8, 'eight'),
    (2, 7, 'seven'),
    (1, 4, 'four'),
    (1, 5, 'five'),
    (3, 9, 'nine'),
    (4, 9, 'nine'),
    (2, 3, 'three'),
    (1, 3, 'three');

SELECT student_id, first_name, AVG(grade) AS avg_grade
    FROM llm_cource 
        INNER JOIN students ON llm_cource.student_id = students.id
    GROUP BY (student_id, first_name)
    ORDER BY avg_grade;
    
SELECT first_name, last_name, courses_ids, array_length(courses_ids, 1) AS courses_num
    FROM students
    WHERE array_length(courses_ids, 1) > 1
    ORDER BY courses_num DESC;
    
SELECT COUNT(first_name) st_count 
    FROM students;

SELECT first_name, last_name from students
    WHERE last_name LIKE '%va' OR first_name like '%a' 
    LIMIT 2;

-- top 3 popular surnames
SELECT 
    CASE 
        WHEN last_name LIKE 'Sobakin%' THEN 'Sobakin*'
        WHEN last_name LIKE 'Drozdov%' THEN 'Drozdov*'
        ELSE last_name END 
        AS family, 
    COUNT(first_name) AS counts
    FROM students
    GROUP BY family
    ORDER BY counts DESC
    LIMIT 3;

-------------------------------------------
--------------- Homework #2 ---------------
-------------------------------------------

-- 1. Создать промежуточные таблицы:
--  student_courses — связывает студентов с курсами. 
--   Поля: id, student_id, course_id.
--  group_courses — связывает группы с курсами. 
--   Поля: id, group_id, course_id.
-- 
--  Заполнить эти таблицы данными, чтобы облегчить работу с отношениями «многие ко многим».
--  Должно гарантироваться уникальное отношение соответствующих полей (ключевое слово UNIQUE).
--  Удалить неактуальные, после модификации структуры, поля (пример: courses_ids) SQL запросом, 
--   (важно, запрос ALTER TABLE).
-- 2. Добавить в таблицу courses уникальное ограничение на поле name, 
--   чтобы не допустить дублирующих названий курсов.
--  Создать индекс на поле group_id в таблице students и объяснить, 
--   как индексирование влияет на производительность запросов (Комментариями в коде).
-- 3. Написать запрос, который покажет список всех студентов с их курсами. 
--  Найти студентов, у которых средняя оценка по курсам выше, 
--   чем у любого другого студента в их группе. (Ключевые слова JOIN, GROUP BY, HAVING)
-- 4. Подсчитать количество студентов на каждом курсе. Найти среднюю оценку на каждом курсе.

CREATE TABLE student_courses (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    UNIQUE (student_id, course_id)
);

CREATE TABLE group_courses (
    id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(id),
    course_id INTEGER REFERENCES courses(id),
    UNIQUE (group_id, course_id)
);


-- Drop column courses_ids of students table
ALTER TABLE students DROP COLUMN courses_ids;

-- Drop column students_ids from groups table
ALTER TABLE groups DROP COLUMN students_ids;

-- Add group_id foreign key constraint to student's table 
ALTER TABLE students 
    ADD CONSTRAINT group_id_FK 
    FOREIGN KEY (group_id)
    REFERENCES groups (id);

-- Make course name unique in courses table
ALTER TABLE courses ADD CONSTRAINT unique_name UNIQUE (name);

-- Create index on column group_id
-- As documentation says:
--  "Indexes are primarily used to enhance database performance 
--  (though inappropriate use can result in slower performance)" 
--  source: https://www.postgresql.org/docs/current/sql-createindex.html
-- And: 
-- "B-trees can handle equality and range queries on data that can be sorted into some ordering
-- In particular, the PostgreSQL query planner will consider using a B-tree index 
-- whenever an indexed column is involved in a comparison using one of these operators:
--  <   <=   =   >=   >"
--  source: https://www.postgresql.org/docs/current/indexes-types.html
-- The last statement probably means the PostreSQL would have automatically choosen B-tree,
--  but I explicitly specify index type using 'USING' keyword.
CREATE INDEX group_id_IDX ON students USING BTREE (group_id);

-- Show current data in tables after altering
SELECT * FROM students LIMIT 100;
SELECT * FROM groups LIMIT 100;
SELECT * FROM courses LIMIT 100;

-- Update freshly created tables with new data
INSERT INTO student_courses (student_id, course_id) VALUES 
    (1, 1),
    (1, 2),
    (1, 3),
    (2, 1),
    (4, 3),
    (5, 1),
    (5, 2),
    (6, 3),
    (7, 2),
    (8, 1),
    (8, 2),
    (8, 3),
    (10, 1),
    (11, 3);

INSERT INTO group_courses (group_id, course_id) VALUES 
    (1, 1),
    (1, 2),
    (1, 3),
    (2, 2),
    (2, 3);


-- show all students with their courses
-- Note: I decided to create temporary VIEW to use it twice: here and in the last queries.
CREATE OR REPLACE TEMPORARY VIEW all_student_courses 
    (student_id, first_name, last_name, course_id, course_name)
AS
    SELECT DISTINCT * FROM (
    (SELECT student_id, st.first_name, st.last_name, course_id, c.name
        FROM student_courses 
            INNER JOIN students st ON student_id = st.id
            INNER JOIN courses c ON course_id = c.id)
    UNION
    (SELECT st.id, st.first_name, st.last_name, gc.course_id, c.name
        FROM students st
            INNER JOIN group_courses gc ON st.group_id = gc.group_id
            INNER JOIN courses c ON gc.course_id = c.id)
    );

-- show all students with their courses
SELECT * FROM all_student_courses ORDER BY student_id LIMIT 100;


-- [!] There is no possible way to find students with the average grade more 
-- than average grade of all students, because THERE IS NO TABLE WITH GRADES of different courses!
-- I created a separate table 'student_grades' with the fields (student_id, course_id, grade). 
-- I also noticed that this new table is the same as 'student_courses' except of an additional 'grade' column.
-- As an alternative, it’s possible to avoid duplication by altering 'student_courses' to add a 'grade' column.
CREATE TABLE IF NOT EXISTS student_grades (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    grade INTEGER,
    PRIMARY KEY (student_id, course_id)
);
-- create tirgger function to check if the grade in range of specific course
-- see more about trigger functions: https://www.postgresql.org/docs/current/plpgsql-trigger.html
CREATE FUNCTION check_grade_range()
    RETURNS trigger AS $$
    DECLARE
        min_grade INTEGER;
        max_grade INTEGER;
    BEGIN
    -- The construction 'SELECT INTO' saves selected values into the given variables
        SELECT c.min_grade, c.max_grade INTO min_grade, max_grade FROM courses c WHERE c.id = NEW.course_id;
        IF NEW.grade < min_grade OR NEW.grade > max_grade THEN
            RAISE EXCEPTION 'grade must be in course range, (course.id = %)', NEW.course_id;
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;
-- create tirgger to check if grade in range of specific course
CREATE OR REPLACE TRIGGER TR_grade_in_range BEFORE INSERT OR UPDATE ON student_grades
    FOR EACH ROW
    EXECUTE FUNCTION check_grade_range();

-- -- check if trigger properly raises exception
-- INSERT INTO student_grades VALUES (1, 3, 99);

-- Insert sutents grades for different courses
-- Note: The values are not normalized because 
--  different courses can have a different range of grades
INSERT INTO student_grades VALUES 
    (1, 1, 8),
    (1, 2, 4),
    (1, 3, 9),
    (2, 1, 3),
    (4, 3, 5),
    (5, 1, 10),
    (5, 2, 5),
    (6, 3, 4),
    (7, 2, 5),
    (8, 1, 6),
    (8, 2, 3),
    (8, 3, 9),
    (10, 1, 8),
    (11, 3, 9);

-- find students with the average grade more than average grade of all students
SELECT student_id, first_name, last_name, AVG(grade) AS avg_grade
    FROM student_grades
        INNER JOIN students
        ON student_grades.student_id = students.id
    GROUP BY (student_id, first_name, last_name)
    HAVING AVG(grade) > (SELECT AVG(grade) FROM student_grades)
    ORDER BY avg_grade DESC
    LIMIT 100;


-- Count students at different courses
SELECT course_id, course_name, COUNT(student_id) AS student_counts 
    -- using data from VIEW here 
    FROM all_student_courses
    GROUP BY (course_id, course_name)
    LIMIT 100;

-- Average grade for each course
SELECT course_id, AVG(grade) as avg_course_grade 
    FROM student_grades 
    GROUP BY course_id
    LIMIT 100;

-- delete tables; it is useful when you want to run this script again
DROP TRIGGER IF EXISTS TR_grade_in_range ON student_grades;
DROP FUNCTION IF EXISTS check_grade_range;
DROP VIEW IF EXISTS all_student_courses;
DROP TABLE IF EXISTS student_grades;
DROP TABLE IF EXISTS group_courses;
DROP TABLE IF EXISTS student_courses;
DROP TABLE IF EXISTS llm_cource;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS courses;
