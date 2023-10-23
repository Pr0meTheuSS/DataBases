BEGIN;
    ALTER TABLE IF EXISTS Groups
    DROP CONSTRAINT fk_groups_to_students;
 
    ALTER TABLE IF EXISTS Students
    DROP CONSTRAINT fk_students_to_groups;
    -- Удаление таблицы Grades
    DROP TABLE IF EXISTS Grades;

    -- Удаление таблицы Lessons
    DROP TABLE IF EXISTS Lessons;

    -- Удаление таблицы Specializations
    DROP TABLE IF EXISTS Specializations;

    -- Удаление таблицы Students
    DROP TABLE IF EXISTS Students;

    -- Удаление таблицы Teachers
    DROP TABLE IF EXISTS Teachers;

    -- Удаление таблицы Disciplines
    DROP TABLE IF EXISTS Disciplines;

    -- Удаление таблицы Groups
    DROP TABLE IF EXISTS Groups;
COMMIT;
