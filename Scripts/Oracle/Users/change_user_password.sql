-- Cмена пароля пользователя.
-- Если роль БД primary и если пользователь существует - выполнить смену пароля, 
-- в противном случае выход из блока.
declare
  v_user   dba_users.username%type := 'SCOTT';
  v_pass_hash varchar2(300) := 'S:FF2FABAA62D16E16D0AE0388051EB296D1B718A98F16D5FFA71DF86466EF;T:F01E9609026876D2BE20DD1D9C84EF20439A86B2BCC1DBB4C0FC5DBE9E7306C5EC0C6D0DE7185F12844A17F828CFA26857EFF9289B7F85A1731FC9DD35FCEA5252EA8C592A7ECBB30DED38391D95B49B';
  v_sqlstr clob;

  function isPrimary return boolean as
    v_role v$database.database_role%type;
  begin
    select d.database_role into v_role from v$database d;
    return v_role = 'PRIMARY';
  end isPrimary;

  function isUserExist(v_user_name dba_users.username%type) return boolean as
    v_user_check dba_users.username%type;
  begin
    begin
      select username
        into v_user_check
        from dba_users
       where username = v_user_name;
    exception
      when others then
        v_user_check := null;
    end;
    return v_user_check is not null;
  end isUserExist;

begin
  if not isPrimary() then
    return;
  end if;

  if not isUserExist(v_user) then
    return;
  end if;

  v_sqlstr := 'alter user "' || v_user || '" identified by values ' || '''' || v_pass_hash || '''';
  execute immediate v_sqlstr;
  dbms_output.put_line('User password altered');
end;
/
