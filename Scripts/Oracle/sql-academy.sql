--Найдите максимальный возраст (колич. лет) среди обучающихся 10 классов ?
SELECT TRUNCATE(DATEDIFF(CURDATE(), birthday) / 365, 0) AS max_year
FROM Student s
	JOIN Student_in_class sc ON s.id = sc.student
	AND sc.class IN (
		SELECT id
		FROM Class
		WHERE name LIKE '10%'
	)
ORDER BY 1 DESC
LIMIT 1;

--Какие кабинеты чаще всего использовались для проведения занятий? Выведите те, которые использовались максимальное количество раз.
SELECT classroom
FROM Schedule
GROUP BY classroom
HAVING COUNT(classroom) = (
		SELECT max(used_count)
		FROM (
				SELECT classroom,
					COUNT(classroom) AS used_count
				FROM Schedule
				GROUP BY classroom
				ORDER BY 2 DESC
			) t
	)


-- Выведите идентификаторы преподавателей, которые хотя бы один раз за всё время преподавали в каждом из одиннадцатых классов.
SELECT teacher
FROM (
		SELECT s.teacher,
			s.class
		FROM Teacher t
			JOIN Schedule s ON t.id = s.teacher
		WHERE s.class IN (
				SELECT id
				FROM Class
				WHERE name LIKE '11%'
			)
		ORDER BY 1
	) t
GROUP BY teacher
HAVING COUNT(DISTINCT (class)) = (
		SELECT COUNT(id)
		FROM Class
		WHERE name LIKE '11%'
	);

-- Для каждой комнаты, которую снимали как минимум 1 раз, найдите имя человека, снимавшего ее последний раз, и дату, когда он выехал
SELECT room_id,
	name,
	end_date
FROM Reservations r
	JOIN Users u
WHERE r.user_id = u.id
	AND (room_id, end_date) IN (
		SELECT room_id,
			max(end_date)
		FROM Reservations
		GROUP BY room_id
	);

-- Вывести идентификаторы всех владельцев комнат, что размещены на сервисе бронирования жилья и сумму, которую они заработали
SELECT owner_id,
	sum(total) AS total_earn
FROM (
		SELECT owner_id,
			COALESCE(total, 0) AS total
		FROM Rooms r
			LEFT JOIN Reservations rv ON r.id = rv.room_id
		ORDER BY owner_id
	) t
GROUP BY owner_id;

-- Найдите какой процент пользователей, зарегистрированных на сервисе бронирования, хоть раз арендовали или сдавали в аренду жилье. Результат округлите до сотых.
WITH all_users AS (
	SELECT COUNT(id) AS all_users_cnt
	FROM Users
),
users_res AS (
	SELECT COUNT(DISTINCT id) users_res_cnt
	FROM (
			SELECT id
			FROM users u
			WHERE EXISTS (
					SELECT 1
					FROM Reservations rv
					WHERE rv.user_id = u.id
				)
			UNION ALL
			SELECT DISTINCT(owner_id)
			FROM Rooms r
			WHERE EXISTS (
					SELECT 1
					FROM Reservations rv
					WHERE rv.room_id = r.id
				)
			ORDER BY 1
		) t
)
SELECT ROUND(users_res_cnt / all_users_cnt * 100, 2) AS percent
FROM all_users,
	users_res;

-- вариант 2, без использования CTE
SELECT round(
		COUNT(id) / (
			SELECT COUNT(id)
			FROM Users
		) * 100,
		2
	) AS percent
FROM Users u
WHERE EXISTS (
		SELECT 1
		FROM (
				SELECT user_id,
					owner_id
				FROM Reservations rv,
					Rooms r
				WHERE rv.room_id = r.id
			) t
		WHERE t.user_id = u.id
			OR t.owner_id = u.id
	);