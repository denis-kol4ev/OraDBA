-- Case examples
-- 1. Searched CASE statement examples
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

declare
  v1 number := 10;
begin
  case 
    when v1 * 10 = 100 then
      dbms_output.put_line('v1 is 100');
    when v1 * 10 = 1000 then
      dbms_output.put_line('v1 is 1000');
    else
      dbms_output.put_line('v1 is unknown ');
  end case;
end;
/

declare
  grade char(1);
begin
  grade := 'B';
  case
    when grade = 'A' then dbms_output.put_line('Excellent');
    when grade = 'B' then dbms_output.put_line('Very Good');
    when grade = 'C' then dbms_output.put_line('Good');
    when grade = 'D' then dbms_output.put_line('Fair');
    when grade = 'F' then dbms_output.put_line('Poor');
    else dbms_output.put_line('No such grade');
  end case;
end;
/
-- 2. Simple CASE statement examples
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
