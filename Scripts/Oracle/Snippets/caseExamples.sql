-- CASE examples

/*
Простая команда CASE используется тогда, когда решение принимается на основании результата одного выражения.
Поисковые команды CASE используются в тех случаях, когда выполняемые команды определяются набором логических выражений. 
*/

-- 1. Simple CASE statement examples
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
  v1 number := 100;
begin
  case v1 * 10
    when 100 then
      dbms_output.put_line('v1 is 10');
    when 1000 then
      dbms_output.put_line('v1 is 100');
    else
      dbms_output.put_line('v1 is unknown ');
  end case;
end;
/

-- 2. Searched CASE statement examples
declare
  v1 number := 10;
  v2 char(1) := 'A';
begin
  case 
    when v1 * 10 = 100 and v2 = 'A' then
      dbms_output.put_line('v1 = 10');
    when v1 * 10 = 1000 and v2 = 'A' then
      dbms_output.put_line('v1 = 100');
    else
      dbms_output.put_line('v1 is unknown ');
  end case;
end;
/
