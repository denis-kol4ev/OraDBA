declare
  v_schema          varchar2(30) := '&USERNAME';
  v_role_name_check varchar2(100);
  v_sqlstr          varchar2(100);
  v_role_postfix    varchar2(30) := '_EXECUTE';
  v_role_name       varchar2(100);
  v_grant_cnt       number;

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
  -- execute role
  v_role_name := concat(v_schema, v_role_postfix);

  if isRoleExist(v_role_name) then
    dbms_output.put_line('Role ' || v_role_name || ' is already exist');
  else
    v_sqlstr := 'create role ' || v_role_name;
    execute immediate v_sqlstr;
    dbms_output.put_line('Role ' || v_role_name || ' created');
    for i in (select o.owner, o.object_name
                from dba_objects o
               where o.object_type in ('FUNCTION', 'PROCEDURE', 'PACKAGE')
                 and o.owner = v_schema) loop
      v_sqlstr := 'GRANT EXECUTE ON ' || i.owner || '.' || i.object_name ||
                  ' to ' || v_role_name;
      begin
        execute immediate v_sqlstr;
      exception
        when others then
          null;
      end;
    end loop;
    select count(*)
      into v_grant_cnt
      from dba_tab_privs p
     where p.grantee = v_role_name;
    dbms_output.put_line('Total grants on functions, procedures, packages of ' ||
                         v_schema || ' schema granted to role ' ||
                         v_role_name || ' is ' || v_grant_cnt);
  
  end if;
end;
