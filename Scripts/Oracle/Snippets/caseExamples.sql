-- Case
declare
  v1 char(1) := 'C';
begin
  case v1
    when 'A' then
      dbms_output.put_line('v1 is ' || v1);
    when 'B' then
      dbms_output.put_line('v1 is ' || v1);
    else
      dbms_output.put_line('v1 is unknown ');
  end case;
end;
/

declare
  v1 number := 10;
begin
  case v1 * 10
    when 100 then
      dbms_output.put_line('v1 is 100');
    when 1000 then
      dbms_output.put_line('v1 is 1000');
    else
      dbms_output.put_line('v1 is unknown ');
  end case;
end;
/

declare
  v1 number := 10;
begin
  case 
    when v1 = 10 then
      dbms_output.put_line('v1 = 10');
    when v1 = 20 then
      dbms_output.put_line('v1 = 20');
    else
      dbms_output.put_line('v1 is unknown ');
  end case;
end;
/
