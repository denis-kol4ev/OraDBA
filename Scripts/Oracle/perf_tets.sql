set echo on

connect test_usr/Zz123456@&1

declare
  v1    number;
  v2    number;
  v_sql varchar2(500);
begin
  for i in 1 .. 100000 loop
    v1    := round(dbms_random.value(1, 200000));
    v_sql := 'select idc from test_usr.big_table where idc = :v1';
    execute immediate v_sql into v2 using v1;
  end loop;
EXCEPTION
  WHEN no_data_found THEN
    dbms_output.put_line('exc ' || v1);
end;
/

exit;