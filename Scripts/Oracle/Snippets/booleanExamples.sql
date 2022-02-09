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
