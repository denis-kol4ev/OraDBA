declare
  function isPrimary return boolean as
    v_role varchar2(100);
  begin
      select d.DATABASE_ROLE
        into v_role
        from v$database d;
    return v_role = 'PRIMARY';
  end isPrimary;

begin
  if isPrimary() then
    dbms_output.put_line('it''s primary database, let''s do useful work');
  end if;
end;
