
-- Task:
    -- Создать триггеры со всеми возможными ключевыми словами,
    --  а также рассмотреть операционные триггеры Попрактиковаться в созданиях транзакций
    --  (привести пример успешной и фейл транзакции, объяснить в комментариях почему она зафейлилась).
    -- Попробовать использовать RAISE внутри триггеров для логирования


-- drop tables to execute this script multiple times
DROP VIEW IF EXISTS common_students_info;
DROP TABLE IF EXISTS students_groups;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS groups;

-- Let's create some tables.
CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    group_num INTEGER,
    group_desc VARCHAR(1000)
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(500),
    second_name VARCHAR(500)
);

CREATE TABLE students_groups(
    group_id INTEGER REFERENCES groups(id) ON DELETE CASCADE,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
        -- A pair (group_id, student_is) must be unique
    PRIMARY KEY (group_id, student_id)
);

-- And then insert some data
INSERT INTO groups (group_num, group_desc) VALUES
    (1011, 'First year students'),
    (1012, 'First year students'),
    (2011, 'Second year students. Ex. 1013 and 1014'),
    (3011, 'Third year students'),
    (4012, 'Fourth year students. Graduate students');

INSERT INTO students (first_name, second_name) VALUES
    ('Aleksandr', 'Ivanov'),
    ('Maria', 'Petrova'),
    ('Dmitriy', 'Sidorov'),
    ('Anna', 'Kuznetsova'),
    ('Sergey', 'Popov'),
    ('Elena', 'Semenova'),
    ('Ivan', 'Lebedev'),
    ('Olga', 'Morozova'),
    ('Nikolay', 'Solovyev'),
    ('Tatyana', 'Stepanova'),
    ('Artem', 'Alexandrov'),
    ('Ksenia', 'Lebedeva'),
    ('Maksim', 'Grigoryev'),
    ('Yuliya', 'Kovalenko'),
    ('Vladimir', 'Egorov');

INSERT INTO students_groups (group_id, student_id) VALUES
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (2, 5),
    (2, 6),
    (2, 7),
    (2, 8),
    (2, 9),
    (3, 10),
    (4, 11),
    (5, 12),
    (5, 13),
    (5, 14),
    (5, 15);

CREATE OR REPLACE VIEW common_students_info AS
    SELECT sg.student_id, first_name, second_name, sg.group_id, group_num
        FROM students_groups sg
            INNER JOIN groups gr ON gr.id = sg.group_id
            INNER JOIN students st ON st.id = sg.student_id
    ORDER BY group_num;

-- check if everything works
SELECT * FROM common_students_info LIMIT 100;

-- --------------------------------- --
-- Finally, it is time for TRIGGERS! --
-- --------------------------------- --

-- Trigger 1: Capitalize first letter of first_name before insert
CREATE OR REPLACE FUNCTION capitalize_first_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.first_name := INITCAP(NEW.first_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER first_name_capital_TG
    BEFORE INSERT ON students
    FOR EACH ROW
    EXECUTE FUNCTION capitalize_first_name();

-- Test the trigger
INSERT INTO students (first_name, second_name) VALUES ('sergey', 'ivanov');
SELECT * FROM students LIMIT 100;

-- Trigger 2: Capitalize first letter of second_name after insert
CREATE OR REPLACE FUNCTION capitalize_second_name()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE students
    SET second_name = INITCAP(NEW.second_name)
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER second_name_capital_TG
    AFTER INSERT ON students
    FOR EACH ROW
    EXECUTE FUNCTION capitalize_second_name();

-- Test the trigger
INSERT INTO students (first_name, second_name) VALUES ('alexey', 'smirnov');
SELECT * FROM students;

-- Trigger 3: Log how many students were deleted before delete
-- [!] NOTE: some SQL clients does not show logs as SQL Electron (which I use), 
--           but I have run the same statements in VS Code (with SQL excetions) and logs appeared.
CREATE OR REPLACE FUNCTION log_delete_students()
RETURNS TRIGGER AS $$
DECLARE
    student_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO student_count FROM students;
    RAISE NOTICE 'Number of students before deletion: %', student_count;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_delete_students_TG
    BEFORE DELETE ON students
    FOR EACH STATEMENT
    EXECUTE FUNCTION log_delete_students();

-- Test the trigger
DELETE FROM students WHERE id = 3 OR id = 4;
SELECT * FROM students;

-- Trigger 4: Raise error if a group has more than 5 students
CREATE OR REPLACE FUNCTION check_group_capacity()
RETURNS TRIGGER AS $$
DECLARE
    student_count INTEGER;
    group_number INTEGER;
BEGIN
    SELECT COUNT(*) INTO student_count
    FROM students_groups
    WHERE group_id = NEW.group_id;

    IF student_count >= 5 THEN
        SELECT group_num INTO group_number FROM groups WHERE id=NEW.group_id;
        RAISE EXCEPTION 'Group with num % (id=%) already has 5 students. No more students can be added.', group_number, NEW.group_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER no_more_five_TG
    BEFORE INSERT ON students_groups
    FOR EACH ROW
    EXECUTE FUNCTION check_group_capacity();

-- -- Test the trigger
-- -- This will work, as group 1 has less than 5 students
INSERT INTO students_groups (group_id, student_id) VALUES (1, 5);

-- -- This will fail, as group 2 already has 5 students
-- -- Note: you should uncomment next line to see that trigger execute RAISE statement
-- INSERT INTO students_groups (group_id, student_id) VALUES (2, 10);

-- -- Trigger 5: Log and prevent TRUNCATE on the students table
CREATE OR REPLACE FUNCTION disable_truncate_students()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'TRUNCATE operation on students table is not allowed.';
    RETURN NULL;  -- Prevent the TRUNCATE from proceeding
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER disable_truncate_students_TG
    BEFORE TRUNCATE ON students
    FOR EACH STATEMENT
    EXECUTE FUNCTION disable_truncate_students();


-- -- This will raise an exception and prevent the truncate
-- -- Note: don't forget to uncomment this line
-- TRUNCATE TABLE students CASCADE; 
-- -- Show that everinthing is okay after not working truncate (actually this wouldn't even execute, since the previos statement will RAISE exception)
-- SELECT * FROM students LIMIT 100;

-- Trigger 6: Insert into students, groups, and students_groups instead of common_students_info view
CREATE OR REPLACE FUNCTION insert_into_common_students()
RETURNS TRIGGER AS $$
DECLARE
    new_group_id INTEGER;
    new_student_id INTEGER;
BEGIN
    -- Insert into the groups table if the group_num doesn't already exist
    SELECT id INTO new_group_id FROM groups WHERE group_num = NEW.group_num;
    IF NOT FOUND THEN
        INSERT INTO groups (group_num, group_desc) VALUES (NEW.group_num, 'Created on the fly') RETURNING id INTO new_group_id;
    END IF;

    INSERT INTO students (first_name, second_name) VALUES (NEW.first_name, NEW.second_name) RETURNING id INTO new_student_id;

    INSERT INTO students_groups (group_id, student_id) VALUES (new_group_id, new_student_id);

    RETURN NULL;    -- Since it's an INSTEAD OF trigger, we return null
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_into_common_students_RG
    INSTEAD OF INSERT ON common_students_info
    FOR EACH ROW
    EXECUTE FUNCTION insert_into_common_students();

-- Test the trigger
-- This will insert a new group, student, and entry in students_groups
INSERT INTO common_students_info (first_name, second_name, group_num)
VALUES ('donald', 'trump', 5013);

-- -- Validate the insertion
SELECT * FROM common_students_info LIMIT 100;
SELECT * FROM students LIMIT 100;
SELECT * FROM groups LIMIT 100;
SELECT * FROM students_groups LIMIT 100;

-- Test inserting into an existing group (should not create a new group)
INSERT INTO common_students_info (first_name, second_name, group_num)
VALUES ('Svetlana', 'Smirnova', 1011);

-- Validate the insertion
SELECT * FROM groups LIMIT 100;



-- ------------- --
-- TRANSACTIONS  --
-- ------------- --


-- Example of succesfull transaction
BEGIN;
    INSERT INTO groups (group_num, group_desc) VALUES (6011, 'Sixth year students');
    INSERT INTO students (first_name, second_name) VALUES ('Svetlana', 'Novikova');
    INSERT INTO students_groups (group_id, student_id)
        VALUES (
            (SELECT id FROM groups WHERE group_num = 6011),
            (SELECT id FROM students WHERE first_name = 'Svetlana' AND second_name = 'Novikova'));
COMMIT;



-- -- The next transaction will fail at the step of adding a record to students_groups
-- --  because it violates the foreign key of students table.
-- --  And group 7011 will NOT be added to the database even it is separate statement.
-- -- Note: don't forget to uncomment this statements
-- BEGIN;
--     INSERT INTO groups (group_num, group_desc) VALUES (7011, 'Seventh year students');
--     INSERT INTO students_groups (group_id, student_id)
--         VALUES (
--             (SELECT id FROM groups WHERE group_num = 6011),
--             -- Note: student with id 999 is not exist
--             999);
-- COMMIT;


-- This should exist:
SELECT id FROM groups WHERE group_num=6011;
-- This shouldn't exists since transaction failed:
SELECT id FROM groups WHERE group_num=7011;
-- 
-- 
-- 
-- 
-- 
--   ___________________________________
-- / Thanks for checking my homework. It \\
-- \\ seems to be the end of the file.    /
--   -----------------------------------
--          \   ^__^ 
--           \  (oo)\_______
--              (__)\       )\/\\
--                  ||----w |
--                  ||     ||
    
