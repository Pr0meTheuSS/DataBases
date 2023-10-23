-- Выбрать всех студентов с фамилией, начинающейся с буквы, задаваемой в запросе.
SELECT * FROM Students
WHERE lastname LIKE 'A%';

	-- Найти всех студентов-одноименцев.
	SELECT id, s.firstname, lastname, patronymic, groupid
	FROM Students s
	JOIN (
		SELECT firstname, COUNT(firstname) AS count
		FROM Students
		GROUP BY firstname
		HAVING COUNT(*) > 1) same_name
	ON s.firstname = same_name.firstname;

	-- Запрос без джоина
	SELECT t1.* 
	FROM Students t1, 
	(SELECT firstname, count(*) 
	FROM Students
	GROUP BY firstname 
	HAVING count(*)>1) t2 
	WHERE t1.firstname=t2.firstname;

	-- Запрос без join, having, group by  
	SELECT s.firstname, s.lastname, s.patronymic
	FROM (
		SELECT *, 
		COUNT(1) OVER (PARTITION BY firstname) as s_count
		FROM Students
	) s
	WHERE s.s_count > 1;

-- c. Список всех студентов у преподавателя.
SELECT id, s.firstname, lastname, patronymic, s.groupid
FROM Students s
JOIN (
    SELECT groupid FROM Lessons 
    WHERE teacher = (SELECT id FROM Teachers WHERE firstname = 'Aris' AND lastname = '...')
) b ON s.groupid = b.groupid;

-- d. Найти группы, в которых нет старосты.
SELECT * FROM Groups
WHERE elder IS NULL;

-- e. Вывести все группы и среднюю успеваемость в них.
SELECT G.groupname, AVG(GR.grade) AS average_grade
FROM Groups G
LEFT JOIN Students S ON G.id = S.groupid
LEFT JOIN Grades GR ON S.id = GR.student
GROUP BY G.id;

-- f. Вывести N лучших студентов по ср. баллу (N – параметр запроса).
SELECT S.lastname, AVG(GR.grade) AS average_grade
FROM Students S
LEFT JOIN Grades GR ON S.id = GR.student
GROUP BY S.id
ORDER BY average_grade DESC NULLS LAST
LIMIT 3; 

-- g. Выбрать группу с самой высокой успеваемостью.
SELECT G.groupname, AVG(GR.grade) AS average_grade
FROM Groups G
LEFT JOIN Students S ON G.id = S.groupid
LEFT JOIN Grades GR ON S.id = GR.student
GROUP BY G.id
ORDER BY average_grade DESC NULLS LAST
LIMIT 1; 

-- h. Посчитать количество студентов у каждого преподавателя.
SELECT T.firstname, T.lastname, T.patronymic, COUNT(*) AS students_amount
FROM Teachers T
JOIN Lessons Ls ON T.id = Ls.teacher
JOIN Students S ON Ls.groupid = S.groupid
GROUP BY T.id;

-- i. Выбрать преподавателей, у которого студентов-отличников больше 10. 
SELECT  well_grades.teacher_id, COUNT(*) AS well_studends_count 
FROM (
    -- Подзапрос формирует записи с преподавателями и студентами-отличниками
	SELECT T.id as teacher_id, T.lastname as teacher_lastname, S.id
	FROM Teachers T
	JOIN Lessons Ls ON T.id = Ls.teacher
	JOIN Students S ON Ls.groupid = S.groupid
	JOIN Grades GR ON S.id = GR.student
	GROUP BY teacher_id, S.id
	HAVING AVG(GR.grade) > 4.0
) AS well_grades
JOIN Teachers T ON T.id = well_grades.teacher_id
GROUP BY well_grades.teacher_id 
HAVING COUNT(*) > 1;
