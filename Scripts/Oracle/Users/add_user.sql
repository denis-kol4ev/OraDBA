/*
  NAME
    add_user.sql
  
  DESCRIPTION
    Массовое создание пользователей в БД.
    Скрипт предназначен для запуска на группе БД через какое-либо средство автоматизации.
 
    Для запуска задайте переменные 
    v_user - список пользователей
    v_pass - временный пароль
    
    Порядок работы:
    Если БД primary, проверяется наличие в БД роли READ_ONLY_USER,
    при отсутсвии роль будет создана и ей присвоены 
    - CONNECT
    - роли по шаблону _READ_ONLY
    Создание пользователей из списка и присвоение им роли READ_ONLY_USER
  
  NOTES
*/
declare
  type nt is table of varchar2(100);
  v_user   nt := nt('IVAN.IVANOV', 'PETR.PETROV');
  v_pass   varchar2(100) := 'Zz123#';
  v_role   dba_roles.role%type := trim(upper('READ_ONLY_USER'));
  v_sqlstr clob;

  function isPrimary return boolean as
    v_role v$database.database_role%type;
  begin
    select d.database_role into v_role from v$database d;
    return v_role = 'PRIMARY';
  end isPrimary;

  function isRoleExist(v_role dba_users.username%type) return boolean as
    v_role_check dba_roles.role%type;
  begin
    begin
      select role into v_role_check from dba_roles where role = v_role;
    exception
      when others then
        v_role_check := null;
    end;
    return v_role_check is not null;
  end isRoleExist;

  function isUserExist(v_user dba_users.username%type) return boolean as
    v_user_check dba_users.username%type;
  begin
    begin
      select username into v_user_check from dba_users where username = v_user;
    exception
      when others then
        v_user_check := null;
    end;
    return v_user_check is not null;
  end isUserExist;

begin
  if not isPrimary() then
    dbms_output.put_line('Database role is not PRIMARY');
    return;
  end if;

  if not isRoleExist(v_role) then
    dbms_output.put_line('Role ' || v_role || ' not found. Let''s create it.');
    v_sqlstr := 'create role ' || v_role;
    execute immediate v_sqlstr;
    v_sqlstr := 'grant CONNECT to ' || v_role;
    execute immediate v_sqlstr;
    for i in (select r.role
                from dba_roles r
               where regexp_like(r.role,
                                 '_READ_ONLY$',
                                 'i')) loop
      v_sqlstr := 'grant ' || i.role || ' to ' || v_role;
      execute immediate v_sqlstr;
    end loop;
    dbms_output.put_line('Role ' || v_role || ' created');
  end if;

  for i in v_user.first .. v_user.last loop
    v_user(i) := trim(upper(v_user(i)));
    if not isUserExist(v_user(i)) then
      dbms_output.put_line('User ' || v_user(i) ||
                           ' not found. Let''s create it.');
      v_sqlstr := 'CREATE USER "' || v_user(i) || '" IDENTIFIED BY ' || v_pass ||
                  ' PASSWORD EXPIRE';
      execute immediate v_sqlstr;
      v_sqlstr := 'GRANT "' || v_role || '" to "' || v_user(i) || '"';
      execute immediate v_sqlstr;
      dbms_output.put_line('User ' || v_user(i) || ' created');
    else
      dbms_output.put_line('User ' || v_user(i) || ' already exist');
    end if;
  end loop;
end;
/
