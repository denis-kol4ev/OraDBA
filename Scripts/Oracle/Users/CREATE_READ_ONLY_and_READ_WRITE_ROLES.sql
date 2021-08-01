declare
  v_schema          varchar2(30) := '&USERNAME';
  v_role_name_check varchar2(100);
  v_sqlstr          varchar2(200);
  v_ro_role_postfix varchar2(40) := '_READ_ONLY';
  v_rw_role_postfix varchar2(40) := '_READ_WRITE';
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
  -- read only role
  v_role_name := concat(v_schema, v_ro_role_postfix);

  if isRoleExist(v_role_name) then
    dbms_output.put_line('Role ' || v_role_name || ' is already exist');
  else
    v_sqlstr := 'create role ' || v_role_name;
    execute immediate v_sqlstr;
    dbms_output.put_line('Role ' || v_role_name || ' created');
    for i in (select t.owner, t.table_name
                from dba_tables t
               where t.owner = v_schema) loop
      v_sqlstr := 'GRANT SELECT ON ' || i.owner || '.' || i.table_name ||
                  ' to ' || v_role_name;
      begin
        execute immediate v_sqlstr;
      exception
        when others then
          null;
      end;
    end loop;
    for i in (select t.owner, t.view_name
                from dba_views t
               where t.owner = v_schema) loop
      v_sqlstr := 'GRANT SELECT ON ' || i.owner || '.' || i.view_name ||
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
    dbms_output.put_line('Total grants on tables and views of ' ||
                         v_schema || ' schema granted to role ' ||
                         v_role_name || ' is ' || v_grant_cnt);
  
  end if;
  -- read write role
  v_role_name := concat(v_schema, v_rw_role_postfix);

  if isRoleExist(v_role_name) then
    dbms_output.put_line('Role ' || v_role_name || ' is already exist');
  else
    v_sqlstr := 'create role ' || v_role_name;
    execute immediate v_sqlstr;
    dbms_output.put_line('Role ' || v_role_name || ' created');
    for i in (select t.owner, t.table_name
                from dba_tables t
               where t.owner = v_schema) loop
      v_sqlstr := 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || i.owner || '.' ||
                  i.table_name || ' to ' || v_role_name;
      begin
        execute immediate v_sqlstr;
      exception
        when others then
          null;
      end;
    end loop;
    for i in (select t.owner, t.view_name
                from dba_views t
               where t.owner = v_schema) loop
      v_sqlstr := 'GRANT SELECT ON ' || i.owner || '.' || i.view_name ||
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
    dbms_output.put_line('Total grants on tables and views of ' ||
                         v_schema || ' schema granted to role ' ||
                         v_role_name || ' is ' || v_grant_cnt);
  end if;
end;
