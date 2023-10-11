-- Вопросы для собеседования на https://livesql.oracle.com

==================
    Вопросы
==================
-- Вопрос №1
-- Используя таблицу EMPLOYEES схемы HR найдите топ три зарплаты в комапании
-- с сортрировкой от большего к меньшему. 

-- Вопрос №2
-- Используя таблицы EMP и DEPT схемы SCOTT выведите информацию по всем департаментам и их служащим.

-- Вопрос №3
-- Используя таблицы CUSTOMERS и ORDERS схемы OE выведите всех клиентов которые не имеют заказов.

-- Вопрос №4
-- Используя таблицу EMPLOYEES схемы HR найдите самых высокооплачиваемых сотрудников в каждом департаменте

-- Вопрос №5
-- Используя таблицу EMPLOYEES схемы HR выведете сотрудников с чётным порядковым номером (employee_id)

-- Выпрос №6
-- Выведете топ три заказа (по сумме) для каждого клиента.
-- Используйте таблицы ORDERS, ORDER_ITEM схемы CO
-- Итоговый набор полей: 
-- клиент (customer_id), заказ (order_id), сумма_заказа (order_total)
-- сортрировка по customer_id от меньшего к большему

-- Вопрос №7
-- Выведете все заказы сделанные в Лондоне с суммой заказа больше либо равной 100.
-- Используйте таблицы CUSTOMERS, STORES, ORDERS, ORDER_ITEMS схемы CO
-- Итоговый набор полей: 
-- номер_заказа (order_id), имя_клиента (full_name), имя_магазина (store_name), сумма_заказа (order_total)
-- сортрировка по order_total от большего к меньшему 
    
==================
    Ответы
==================
-- Вопрос №1
-- Используя таблицу EMPLOYEES схемы HR найдите топ три зарплаты в комапании
-- с сортрировкой от большего к меньшему.  
select distinct(salary) from hr.employees e order by salary desc fetch first 3 rows only;

-- Вопрос №2
-- Используя таблицы EMP и DEPT схемы SCOTT выведите информацию по всем департаментам и их служащим.
select * from scott.dept left join scott.emp using(deptno);

-- Вопрос №3
-- Используя таблицы CUSTOMERS и ORDERS схемы OE выведите всех клиентов которые не имеют заказов.
select * from oe.customers c where not exists (select 1 from oe.orders o where o.customer_id = c.customer_id); 

-- Вопрос №4
-- Используя таблицу EMPLOYEES схемы HR найдите самых высокооплачиваемых сотрудников в каждом департаменте
-- с сортрировкой по department_id от меньшего к большему. 
-- вариант 1
select * from hr.employees e where (department_id, salary) in (select department_id, max(salary) as salary from hr.employees group by department_id) order by department_id;
-- вариант 2
select * from hr.employees e where salary=(select max(salary) from hr.employees where department_id = e.department_id) order by department_id;

-- Вопрос №5
-- Используя таблицу EMPLOYEES схемы HR выведете сотрудников с чётным порядковым номером (employee_id)
select * from hr.employees e where mod(employee_id, 2) = 0;

-- Выпрос №6
-- Выведете топ три заказа (по сумме) для каждого клиента.
-- Используйте таблицы ORDERS, ORDER_ITEM схемы CO
-- Итоговый набор полей: 
-- клиент (customer_id), заказ (order_id), сумма_заказа (order_total)
-- сортрировка по customer_id от меньшего к большему
    with t (customer_id, order_id, order_total, rn) as (
select o.customer_id, o.order_id, sum(oi.unit_price * oi.quantity) as order_total, row_number() over (partition by o.customer_id order by sum(oi.unit_price * oi.quantity) desc) as rn
    from co.orders o join co.order_items oi on o.order_id=oi.order_id
    group by o.customer_id, o.order_id)
    select * from t where rn <= 3 order by customer_id;

-- Вопрос №7
-- Выведете все заказы сделанные в Лондоне с суммой заказа больше либо равной 100.
-- Используйте таблицы CUSTOMERS, STORES, ORDERS, ORDER_ITEMS схемы CO
-- Итоговый набор полей: 
-- номер_заказа (order_id), имя_клиента (full_name), имя_магазина (store_name), сумма_заказа (order_total)
-- сортрировка по order_total от большего к меньшему 
select  o.order_id, c.full_name, s.store_name, sum(oi.unit_price * oi.quantity) as order_total
    from co.orders o 
    join co.stores s on o.store_id = s.store_id
    join co.customers c on o.customer_id = c.customer_id
    join co.order_items oi on o.order_id=oi.order_id
    where s.store_name = 'London'
    group by o.order_id, c.full_name, s.store_name
    having sum(oi.unit_price * oi.quantity) >= 100 order by order_total desc;
