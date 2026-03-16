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

-- Пример триггера для аудита изменений объектов.
-- Если объект существует, то при его изменении в таблицу maint.ddl_changes_log будут записаны его версия до и после изменения. 
-- Создание или удаление объектов не логируется.

create table maint.ddl_changes_log (
   date_time           date,
   ip_address          varchar2(30),
   host                varchar2(100),
   os_user             varchar2(100),
   session_user        varchar2(100),
   sid                 integer,
   isdba               varchar2(10),
   client_program_name varchar2(100),
   obj_type            varchar2(100),
   obj_status          varchar2(30),
   obj_owner           varchar2(100),
   obj_name            varchar2(100),
   old_version         clob,
   new_version         clob,
   err_stack           varchar2(4000),
   err_backtrace       varchar2(4000)
);

create or replace trigger sys.audit_ddl_trg
  before ddl on database
declare
  v_trigger_owner        varchar2(30) := 'SYS';
  v_trigger_name         varchar2(30) := 'AUDIT_DDL_TRG';
  v_obj_status           varchar2(30);
  v_stmt_old             clob;
  v_stmt_new             clob;
  v_n                    pls_integer;
  v_sql_text             dbms_standard.ora_name_list_t;
  v_ip                   varchar2(30);
  v_host                 varchar2(100);
  v_os_user              varchar2(100);
  v_session_user         varchar2(100);
  v_sid                  pls_integer;
  v_isdba                varchar2(10);
  v_client_program_name  varchar2(100);

 function is_object_exist(p_owner in dba_objects.owner%type, p_name in dba_objects.object_name%type, p_type in dba_objects.object_type%type, p_status out dba_objects.status%type) return boolean as
  begin
    begin
      select status into p_status from dba_objects where owner = p_owner and object_name = p_name and object_type = p_type
        and owner not in ('SYS', 'SYSTEM')
        and object_type in ('TRIGGER', 'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'VIEW');
    exception
      when no_data_found then
        p_status := null;
    end;
    return p_status is not null;
  end is_object_exist;

begin
  v_ip                  := sys_context('userenv', 'ip_address');
  v_host                := sys_context('userenv', 'host');
  v_os_user             := sys_context('userenv', 'os_user');
  v_session_user        := sys_context('userenv', 'session_user');
  v_sid                 := sys_context('userenv', 'sid');
  v_isdba               := sys_context('userenv', 'isdba');
  v_client_program_name := sys_context('userenv', 'client_program_name');

  if is_object_exist(ora_dict_obj_owner, ora_dict_obj_name, ora_dict_obj_type, v_obj_status) and ora_sysevent in ('CREATE', 'ALTER') then
    if ora_dict_obj_type = 'PACKAGE BODY' then
        v_stmt_old := DBMS_METADATA.GET_DDL('PACKAGE_BODY', ora_dict_obj_name, ora_dict_obj_owner);
    else
        v_stmt_old := DBMS_METADATA.GET_DDL(ora_dict_obj_type, ora_dict_obj_name, ora_dict_obj_owner);
    end if;

    -- Сохраняем новую версию объекта
    v_n := ora_sql_txt(v_sql_text);
    for i in 1 .. v_n loop
      v_stmt_new := v_stmt_new || v_sql_text(i);
    end loop;

    insert into maint.ddl_changes_log(date_time, ip_address, host, os_user, session_user, sid, isdba, client_program_name, obj_type, obj_status, obj_owner, obj_name, old_version, new_version, err_stack, err_backtrace)
    values (sysdate, v_ip, v_host, v_os_user, v_session_user, v_sid, v_isdba, v_client_program_name, ora_dict_obj_type, v_obj_status, ora_dict_obj_owner, ora_dict_obj_name, v_stmt_old, v_stmt_new, null, null);
  end if;

  exception
  when others then
    sys.dbms_system.ksdwrt(2, 'Trigger ' || v_trigger_owner || '.' || v_trigger_name || ': ' || sqlerrm);

    insert into maint.ddl_changes_log(date_time, ip_address, host, os_user, session_user, sid, isdba, client_program_name, obj_type, obj_status, obj_owner, obj_name, old_version, new_version, err_stack, err_backtrace)
    values (sysdate, v_ip, v_host, v_os_user, v_session_user, v_sid, v_isdba, v_client_program_name, ora_dict_obj_type, v_obj_status, ora_dict_obj_owner, ora_dict_obj_name, null, null, DBMS_UTILITY.FORMAT_ERROR_STACK(), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
end;

-- Test
create or replace procedure p1 as
begin null; end;
/

create or replace procedure p1 as
begin null; null; end;
/

create or replace function f1 (p1 number) return number as
begin return p1*5; end;
/

create or replace function f1 (p1 number) return number as
begin return p1*10; end;
/

create or replace view hr.v1 as select EMPLOYEE_ID as c1 from hr.employees; 
create or replace view hr.v1 as select EMPLOYEE_ID, FIRST_NAME, LAST_NAME as c1 from hr.employees;

CREATE OR REPLACE PACKAGE hr.employee_management AS
  FUNCTION hire_emp (name VARCHAR2) RETURN NUMBER;
END employee_management;
/

CREATE OR REPLACE PACKAGE BODY hr.employee_management AS
  FUNCTION hire_emp (name VARCHAR2) RETURN NUMBER IS
    new_emp_id NUMBER;
  BEGIN
    RETURN new_emp_id;
  END hire_emp;
END employee_management;
/

CREATE OR REPLACE PACKAGE hr.employee_management AS
  FUNCTION hire_emp (name VARCHAR2) RETURN NUMBER;
  PROCEDURE fire_emp(emp_id IN NUMBER);
END employee_management;
/

CREATE OR REPLACE PACKAGE BODY hr.employee_management AS
  FUNCTION hire_emp (name VARCHAR2) RETURN NUMBER IS
    new_emp_id NUMBER;
  BEGIN
    RETURN new_emp_id;
  END hire_emp;

  PROCEDURE fire_emp(emp_id IN NUMBER) IS
  BEGIN
    null;
  END fire_emp;
END employee_management;
/

alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
select * from maint.ddl_changes_log l order by l.date_time desc;

drop procedure hr.p1;
drop function hr.f1;
drop view hr.v1;
drop package hr.employee_management;
drop trigger sys.audit_ddl_trg;
drop table maint.ddl_changes_log;