-- Procedure drop_user_prc allow non administrative user to drop database users, 
-- except oracle maintained users.

-- create log table
create table system.drop_user_log (
  date_time date,
  ip          varchar2(30),
  host        varchar2(100),
  os_user     varchar2(100),
  session_user varchar2(100),
  isdba       varchar2(10),
  client_program_name varchar2(100),
  command     varchar2(100),
  
  err_stack     varchar2(4000),
  err_backtrace varchar2(4000)
  ) tablespace users;
  
-- grant privs
grant select on dba_users to system;
grant drop user to system;

-- create proc
create or replace procedure system.drop_user_prc(v_drop_user varchar2) as
  v_command             varchar2(100);
  v_cnt                 number;
  v_ip                  varchar2(30);
  v_host                varchar2(100);
  v_os_user             varchar2(100);
  v_session_user        varchar2(100);
  v_isdba               varchar2(10);
  v_client_program_name varchar2(100);
  err_stack             varchar2(4000);
  err_backtrace         varchar2(4000);
begin
  v_ip                  := sys_context('userenv', 'ip_address');
  v_host                := sys_context('userenv', 'host');
  v_os_user             := sys_context('userenv', 'os_user');
  v_session_user        := sys_context('userenv', 'session_user');
  v_isdba               := sys_context('userenv', 'isdba');
  v_client_program_name := sys_context('userenv', 'client_program_name');

  select count(*)
    into v_cnt
    from dba_users u
   where u.username = upper(v_drop_user)
     and (u.oracle_maintained = 'Y' or username in ('MAINT'));
  if v_cnt != 0 then
    sys.dbms_system.ksdwrt(2,
                           'Attempt to drop Oracle system user ' ||
                           upper(v_drop_user) || ' has been blocked.');
  
    raise_application_error(-20001,
                            'Attempt to drop Oracle system user ' ||
                            upper(v_drop_user) || ' has been blocked.');
  elsif v_cnt = 0 then
    v_command := 'drop user ' || v_drop_user || ' cascade';
    execute immediate v_command;
    sys.dbms_system.ksdwrt(2, v_command);
    insert into system.drop_user_log
    values
      (sysdate,
       v_ip,
       v_host,
       v_os_user,
       v_session_user,
       v_isdba,
       v_client_program_name,
       v_command,
       err_stack,
       err_backtrace);
    commit;
  end if;
exception
  when others then
    err_stack     := DBMS_UTILITY.FORMAT_ERROR_STACK();
    err_backtrace := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE();
  
    insert into system.drop_user_log
    values
      (sysdate,
       v_ip,
       v_host,
       v_os_user,
       v_session_user,
       v_isdba,
       v_client_program_name,
       v_command,
       err_stack,
       err_backtrace);
    commit;
    raise;
end;
/
