-- Триггеры
-- 1. DML triggers
-- 2. System triggers

-- 1. DML triggers 

-- Пример DML триггера для аудита вставки, обновлении или удалении записей таблицы.
drop table hr.t1 purge;
drop table hr.t1_aud purge;

create table hr.t1 (id number primary key, name varchar2(100) not null);
create table hr.t1_aud (date_time date, session_user varchar2(100), optype varchar2(10), t1_id number, t1_name varchar2(100));

create or replace trigger hr.t1_aud_trg
before insert or update or delete on hr.t1
   for each row
begin
 CASE
    WHEN INSERTING THEN
      insert into hr.t1_aud values(sysdate, sys_context('userenv', 'session_user'), 'I', :new.id, :new.name);
    WHEN UPDATING THEN
      insert into hr.t1_aud values(sysdate, sys_context('userenv', 'session_user'), 'U', :old.id, :old.name);
    WHEN DELETING THEN
      insert into hr.t1_aud values(sysdate, sys_context('userenv', 'session_user'), 'D', :old.id, :old.name);
  END CASE;
end;
/
SHOW ERRORS;
/

insert into hr.t1 (id,name) values (1,'Alice');
insert into hr.t1 (id,name) values (2,'Bob');
insert into hr.t1 (id,name) values (3,'Charlie');
commit;

insert into hr.t1 (id, name) values (4,'Diana');
commit;

update hr.t1 set name = 'Zoe' where id = 1;
commit;

delete from hr.t1 where id = 3;
commit;

select * from hr.t1;
select * from hr.t1_aud;

-- 2. System triggers