-- Выведете все заказы сделанные в Лондоне с суммой заказа больше 100.
-- Используйте таблицы customers,stores,orders,order_items схемы CO
-- Итоговый набор полей: 
-- номер_заказа (order_id), имя_клиента (full_name), имя_магазина (store_name), сумма_заказа (order_total)

select  o.order_id, c.full_name, s.store_name, sum(oi.unit_price * oi.quantity) as order_total
    from co.orders o 
    join co.stores s on o.store_id = s.store_id
    join co.customers c on o.customer_id = c.customer_id
    join co.order_items oi on o.order_id=oi.order_id
    where s.store_name = 'London'
    group by o.order_id, c.full_name, s.store_name
    having sum(oi.unit_price * oi.quantity) >= 100 order by order_total desc;
=========
-- Используя таблицу hr.employees найдите всторую самую высокую зарплату сотрудника
-- вариант 1
select max(salary) from hr.employees e where e.salary not in (select max(salary) from hr.employees);
-- вариант 2
with t as (select row_number() over (order by salary desc) as rn, e.salary from hr.employees e order by e.salary desc)
    select * from t where rn=2;

-- Используя таблицу hr.employees найдите самых высокооплачиваемых сотрудников в каждом департаменте
-- вариант 1
select * from hr.employees e where (department_id, salary) in (select department_id, max(salary) as salary from hr.employees group by department_id) order by department_id;
-- вариант 2
select * from hr.employees e where salary=(select max(salary) from hr.employees where department_id = e.department_id) order by department_id;

-- Используя таблицу hr.employees выведете сотрудников с чётным порядковым номером (employee_id)
select * from hr.employees e where mod(employee_id, 2) = 0;

-- Выведете все заказы сделанные в Лондоне с суммой заказа больше 100.
-- Используйте таблицы customers,stores,orders,order_items схемы CO
-- Итоговый набор полей: 
-- номер_заказа (order_id), имя_клиента (full_name), имя_магазина (store_name), сумма_заказа (order_total)

select  o.order_id, c.full_name, s.store_name, sum(oi.unit_price * oi.quantity) as order_total
    from co.orders o 
    join co.stores s on o.store_id = s.store_id
    join co.customers c on o.customer_id = c.customer_id
    join co.order_items oi on o.order_id=oi.order_id
    where s.store_name = 'London'
    group by o.order_id, c.full_name, s.store_name
    having sum(oi.unit_price * oi.quantity) >= 100 order by order_total desc;
