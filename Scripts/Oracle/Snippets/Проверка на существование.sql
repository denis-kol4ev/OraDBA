--- При помощи переменной
declare
  v_role_name       varchar2(500) := 'QWERTY_READ_ONLY';
  v_role_name_check varchar2(500);
  v_sqlstr_cr       varchar2(500);
begin
  begin
    select role
      into v_role_name_check
      from dba_roles
     where role = v_role_name;
  exception
    when others then
      v_role_name_check := null;
  end;
  if v_role_name_check is null then
    v_sqlstr_cr := 'create role ' || v_role_name;
    dbms_output.put_line('v_sqlstr_cr = ' || v_sqlstr_cr);
    --  execute immediate v_sqlstr_cr;
  else
    dbms_output.put_line(v_role_name || ' is exist.');
  end if;
end;

--- При помощи boolean функции 
declare
  v_role_name_check varchar2(500);
  v_sqlstr_cr       varchar2(500);
  v_role_name       varchar2(500) := 'QWERTY_READ_ONLY';

  function isRoleExist(v_role_name varchar2) return boolean as
  begin
    begin
      select role
        into v_role_name_check
        from dba_roles
       where role = v_role_name;
    exception
      when others then
        v_role_name_check := null;
    end;
    return v_role_name_check is not null;
  end isRoleExist;
begin
if isRoleExist(v_role_name) then
    dbms_output.put_line(v_role_name || ' is exist.');
  else
 v_sqlstr_cr := 'create role ' || v_role_name;
    dbms_output.put_line('v_sqlstr_cr = ' || v_sqlstr_cr);
    --  execute immediate v_sqlstr_cr;

  end if;
end;
