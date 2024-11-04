-- ДОМАШНЕЕ ЗАДАНИЕ.--
-- 1. Создать таблицу courses, в которой будут храниться курсы студентов. 
--      Поля -- id, name, is_exam, min_grade, max_grade.--
-- 2. Создать таблицу groups, в которой будут храниться данные групп. 
--      Поля -- id, full_name, short_name, students_ids.--
-- 3. Создать таблицу students, в которой будут храниться данные студентов. 
--      Поля -- id, first_name, last_name, group_id, courses_ids.--
-- 4. Создать таблицу любого курса, в котором будут поля 
--      student_id, grade, grade_str с учетом min_grade и max_grade
----    Каждую таблицу нужно заполнить соответствующими данные, показать процедуры фильтрации и агрегации.


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
    -- It is probably better to use an intermediate table 
    -- (something like `student_groups`)
    -- to get rid of arrays and convert db to first normal form,
    -- but I assume arrays here is the task requirement.
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(512) NOT NULL,
    last_name VARCHAR(512),
    group_id INTEGER,
    courses_ids INTEGER[]
    -- Same remarks as in above
);

CREATE TABLE llm_cource (
    student_id INTEGER REFERENCES students(id),
    grade SMALLINT 
        CONSTRAINT normal_grade CHECK (grade > 0 AND grade <= 10),
    grade_str VARCHAR(50),
    -- Again, it's better to get rid of `grade_str`, 
    -- and move it to separate tables `grade` and `cources_grade` 
    -- which will be referenced by `llm_cource`
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
    -- there is no cource with id = 4, but there is no constraints,
    -- so we allowed to do this op.
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
    
    
SELECT first_name, last_name, courses_ids, array_length(courses_ids, 1) AS cources_num
    FROM students
    WHERE array_length(courses_ids, 1) > 1
    ORDER BY cources_num DESC;
    
    
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
    
    

-- delete tables; it is useful when you want to run this script again
DROP TABLE llm_cource;
DROP TABLE groups;
DROP TABLE students;
DROP TABLE courses;
