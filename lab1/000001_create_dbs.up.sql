--   С помощью утилиты migrate выполнил все миграции с суффиксом up в папке /schema для базы postgres
--   (пользователь пароль  для базы = postgres password, внешний порт определен как 5431)
  
--   migrate -path ./schema -database 'postgres://postgres:password@localhost:5431/postgres?sslmode=disable' up

-- С помощью команды 
-- sudo docker run -d \                                                            
--   --name postgres \
--   -e POSTGRES_PASSWORD=password \
--   -v /home/prometheus/home/prometheus/db-host:/var/lib/postgresql/data \
--   -p 5431:5432 \
--   postgres:latest
-- поднимаю локально базу данных

-- С помощью команды 
-- sudo docker exec -it <container-id> /bin/bash 
-- получаю доступ к откружению, в котором развернута база данных.

BEGIN;
    CREATE TABLE Groups (
        id SERIAL PRIMARY KEY,
        groupname VARCHAR(64) NOT NULL,
        elder INT DEFAULT NULL
    );

    CREATE TABLE Students (
        id SERIAL PRIMARY KEY,
        firstname VARCHAR(128) NOT NULL,
        lastname VARCHAR(128) NOT NULL,
        patronymic VARCHAR(128) NOT NULL,
        groupid INT NOT NULL
    );

    ALTER TABLE Groups
    ADD CONSTRAINT fk_groups_to_students
    FOREIGN KEY (elder)
    REFERENCES Students(id);

    ALTER TABLE Students
    ADD CONSTRAINT fk_students_to_groups
    FOREIGN KEY (groupid)
    REFERENCES Groups(id);

    CREATE TABLE Teachers (
        id SERIAL PRIMARY KEY,
        firstname VARCHAR(128) NOT NULL,
        lastname VARCHAR(128) NOT NULL,
        patronymic VARCHAR(128) NOT NULL
    );

    CREATE TABLE Disciplines (
        id SERIAL PRIMARY KEY,
        disciplinename VARCHAR(64) NOT NULL
    );

    CREATE TABLE Specializations (
        id SERIAL PRIMARY KEY,
        teacher INT NOT NULL,
        discipline INT NOT NULL,

        FOREIGN KEY (teacher) REFERENCES Teachers(id),
        FOREIGN KEY (discipline) REFERENCES Disciplines(id),

        CONSTRAINT unique_teacher_and_discipline UNIQUE(teacher, discipline)
    );

    CREATE TABLE Lessons (
        id SERIAL PRIMARY KEY,
        lessontype VARCHAR(32) NOT NULL,
        lessondate DATE NOT NULL,
        timeframe INT NOT NULL,
        auditorium VARCHAR(16) NOT NULL,
        teacher INT NOT NULL,
        groupid INT NOT NULL,

        FOREIGN KEY (teacher) REFERENCES Teachers(id),
        FOREIGN KEY (groupid) REFERENCES Groups(id),

        CONSTRAINT unique_date_time_auditorium UNIQUE(lessondate, timeframe, auditorium)
    );

    CREATE TABLE Grades (
        id SERIAL PRIMARY KEY,
        student INT NOT NULL,
        discipline INT NOT NULL,
        grade INT NOT NULL,
        lessondate DATE NOT NULL,

        FOREIGN KEY (discipline) REFERENCES Disciplines(id),
        FOREIGN KEY (student) REFERENCES Students(id)
    );

    -- Создаем триггер для проверки, что преподаватель может вести указанную дисциплину
    CREATE OR REPLACE FUNCTION check_teacher_discipline()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Проверяем, существует ли запись в таблице Specializations
        -- для данного преподавателя и дисциплины
        IF NOT EXISTS (
            SELECT 1 FROM Specializations
            WHERE teacher = NEW.teacher AND discipline = NEW.discipline
        ) THEN
            -- Если запись не существует, то генерируем ошибку
            RAISE EXCEPTION 'Преподаватель не имеет права вести данную дисциплину';
        END IF;
        
        -- Если проверка прошла успешно, возвращаем NEW (новую запись)
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    -- Создаем триггер для проверки, что староста учится в той же группе
    CREATE OR REPLACE FUNCTION check_elder_in_group()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Проверяем, если староста равен NULL, то не выполняем проверку и сразу возвращаем NEW (новую запись)
        IF NEW.elder IS NULL THEN
            RETURN NEW;
        END IF;

        -- Проверяем, существует ли запись в таблице Students
        -- для данной группы и указанного старосты
        IF NOT EXISTS (
            SELECT 1 FROM Students
            WHERE id = NEW.elder AND groupid = NEW.id
        ) THEN
            -- Если записи не существует, генерируем ошибку
            RAISE EXCEPTION 'Староста не учится в данной группе';
        END IF;

        -- Если проверка прошла успешно, возвращаем NEW (новую запись)
        RETURN NEW;
    END;

    $$ LANGUAGE plpgsql;

COMMIT;

BEGIN;
    INSERT INTO Groups (groupname, elder)
    VALUES 
        ('21212', NULL),
        ('21211', NULL),
        ('19211', NULL);

    INSERT INTO Disciplines (disciplinename)
    VALUES 
        ('Mathematics'),
        ('Analitic Geometry'),
        ('Physics'),
        ('Programming'),
        ('History');

    INSERT INTO Teachers (firstname, patronymic, lastname)
    VALUES 
        ('Aris', 'Savvich', 'Tersenov'),
        ('Valeriy', 'Avdeevich', 'Churkin'),
        ('Abrick', 'Ibragimovihc', 'Valishev'),
        ('Petrov', 'Evgeniy', 'Sergeevich'),
        ('Renata', 'Valerievna', 'Oplakanskaya');

    INSERT INTO Specializations (teacher, discipline)
    VALUES 
        (1, 1),
        (2, 2),
        (3, 3),
        (4, 4),
        (5, 5);

    INSERT INTO Students (firstname, patronymic, lastname, groupid)
    VALUES 
        ('Alexey', 'Love', 'Ducks', 1),
        ('Tofig', 'Tahirovich', 'Aliev', 1),
        ('Daniil', 'Mihailovich', 'Lanin', 1),
        ('Vladislav', 'Pavlovich', 'Menschickov', 1),
        ('Yuriy', 'Yurievich', 'Olimpiev', 1),
        ('Viktoria', 'Denisovna', 'Stepanova', 1),
        ('Victor', 'Batkovich', 'Sbityakov', 1),
        ('Nikita', 'Igorevich', 'Skopin', 1),
        ('Nikita', 'Otetsevich', 'Yurakov', 1);

    UPDATE Groups
    SET elder = (SELECT id FROM Students WHERE lastname = 'Ducks' AND firstname = 'Alexey');

    INSERT INTO Lessons (lessontype, lessondate, timeframe, auditorium, teacher, groupid)
    VALUES
        ('Lecture', '2023-10-05', 1, 'Room 101', 1, 1),
        ('Lab', '2023-10-06', 2, 'Room 102', 2, 2),
        ('Workshop', '2023-10-07', 3, 'Room 103', 3, 3);

    INSERT INTO Grades (student, discipline, grade, lessondate)
    VALUES
        (1, 1, 5, '2023-10-05'),
        (2, 2, 4, '2023-10-06'),
        (3, 3, 3, '2023-10-07');

COMMIT;
