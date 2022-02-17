--pl/sql boolean example
create or replace function isEven(n number)
return boolean
as
begin
  return mod(n,2) = 0;
end isEven;

begin 
  if isEven(4) then
    dbms_output.put_line('even');
  else 
    dbms_output.put_line('odd');
   end if;
end;

--pl/sql boolean example 2
CREATE OR REPLACE FUNCTION valid_deptid(p_deptid IN departments.department_id%TYPE)
  RETURN BOOLEAN IS
  v_dummy PLS_INTEGER;
BEGIN
  SELECT 1 INTO v_dummy FROM departments WHERE department_id = p_deptid;
  RETURN TRUE;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN FALSE;
END valid_deptid;
/

-- Использование логической переменной в качестве флага
declare
  order_exceeds_balance boolean;
  order_total           number := 120;
  max_allowable_order   number := 100;
begin
  order_exceeds_balance := order_total > max_allowable_order;
  if order_exceeds_balance then
    dbms_output.put_line('Order balance exceeded');
  else
    dbms_output.put_line('Let''s do order!');
  end if;
end;
/
