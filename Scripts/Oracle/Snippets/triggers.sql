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
show errors;

-- Test
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

-- 2.1 Триггеры уровня схемы. 

-- Триггеры уровня схемы. 
-- Срабатывают при выполнении операций под пользователем заданным в условии триггера <имя>.schema
-- Триггер ниже сработает на drop table hr.t1; если команду выполнить под пользователем hr, 
-- но не сработает если выполнить ту же команду под другим пользователем.

-- Пример DDL триггера для аудита изменений объектов под пользователем hr.

create table hr.log_ddl (
   date_time date,
   db_user   varchar2(100),
   os_user   varchar2(100),
   host      varchar2(100),
   ip_addr   varchar2(100),
   obj_owner varchar2(100),
   obj_name  varchar2(100),
   obj_type  varchar2(100),
   sysevent  varchar2(100),
   sql_text  clob
);

create or replace trigger hr.ddl_trg
   before ddl on hr.schema 
   declare
      sql_text dbms_standard.ora_name_list_t;
      n        pls_integer;
      v_stmt   clob;
   begin
      n := ora_sql_txt(sql_text);
      for i in 1..n loop
         v_stmt := v_stmt || sql_text(i);
      end loop;

      insert into hr.log_ddl values ( sysdate,
                                      ora_login_user,
                                      sys_context('USERENV','OS_USER'),
                                      sys_context('USERENV','HOST'),
                                      sys_context('USERENV','IP_ADDRESS'),
                                      ora_dict_obj_owner,
                                      ora_dict_obj_name,
                                      ora_dict_obj_type,
                                      ora_sysevent,
                                      v_stmt );
   end;
/
show errors

-- Test 
create table hr.t1 (id number primary key, first_name varchar2(100) not null);
alter table hr.t1 add second_name varchar2(100);
drop table hr.t1 purge;

create or replace procedure hr.p1 as
begin
   null;
end;
/

select * from hr.log_ddl l order by l.DATE_TIME desc;

-- 2.2 Триггеры уровня базы. 

-- Пример триггера для аудита выдачи и отзыва привилегий.

create table maint.log_grant (
   date_time date,
   db_user   varchar2(100),
   os_user   varchar2(100),
   host      varchar2(100),
   ip_addr   varchar2(100),
   obj_owner varchar2(100),
   obj_name  varchar2(100),
   priv_type  varchar2(100),
   sysevent  varchar2(100),
   grantee  varchar2(4000),
   privileges varchar2(4000),
   with_grant_option varchar2(10)
);

create or replace trigger sys.grant_trg
   after grant or revoke on database declare
      v_user_list             dbms_standard.ora_name_list_t;
      v_number_of_grantees    pls_integer;
      v_number_of_revokees    pls_integer;
      v_privelege_list        dbms_standard.ora_name_list_t;
      v_number_of_privileges  pls_integer;
      v_ora_with_grant_option varchar2(10) := 'NO';
   begin
      if ora_sysevent = 'GRANT' then
         v_number_of_grantees := ora_grantee(v_user_list);
         v_number_of_privileges := ora_privilege_list(v_privelege_list);
         for i in 1..v_number_of_grantees loop
            for k in 1..v_number_of_privileges loop
               if ora_with_grant_option then
                  v_ora_with_grant_option := 'YES';
               end if;
               insert into maint.log_grant values ( sysdate,
                                                    ora_login_user,
                                                    sys_context('USERENV','OS_USER'),
                                                    sys_context('USERENV','HOST'),
                                                    sys_context('USERENV','IP_ADDRESS'),
                                                    ora_dict_obj_owner,
                                                    ora_dict_obj_name,
                                                    ora_dict_obj_type,
                                                    ora_sysevent,
                                                    v_user_list(i),
                                                    v_privelege_list(k),
                                                    v_ora_with_grant_option );
            end loop;
         end loop;
      end if;

      if ora_sysevent = 'REVOKE' then
         v_number_of_revokees := ora_revokee(v_user_list);
         v_number_of_privileges := ora_privilege_list(v_privelege_list);
         for i in 1..v_number_of_revokees loop
            for k in 1..v_number_of_privileges loop
               if ora_with_grant_option then
                  v_ora_with_grant_option := 'YES';
               end if;
               insert into maint.log_grant values ( sysdate,
                                                    ora_login_user,
                                                    sys_context('USERENV','OS_USER'),
                                                    sys_context('USERENV','HOST'),
                                                    sys_context('USERENV','IP_ADDRESS'),
                                                    ora_dict_obj_owner,
                                                    ora_dict_obj_name,
                                                    ora_dict_obj_type,
                                                    ora_sysevent,
                                                    v_user_list(i),
                                                    v_privelege_list(k),
                                                    null );
            end loop;
         end loop;
      end if;
   end;
/
show errors

-- Test
grant select, update, delete on hr.log_ddl to maint with grant option;
revoke delete on hr.log_ddl from maint;
grant delete on hr.log_ddl to maint;
revoke select, update, delete on hr.log_ddl from maint;

select * from maint.log_grant order by 1 desc;	
truncate table maint.log_grant;
