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
