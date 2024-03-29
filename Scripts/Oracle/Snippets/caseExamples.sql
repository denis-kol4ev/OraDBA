-- CASE statement and CASE expression examples

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

/*
Main difference is that the CASE expression returns a value whereas the CASE statement performs actions.
CASE expression can be used in both SQL and PL/SQL, whereas CASE statement can only be used in PL/SQL.
CASE statement is finished with an END CASE, statement rather than just END.
*/

-- 3. CASE expression examples
declare
  v_dep_no number := 20;
  v_dep_desc  varchar2(20);
begin
  v_dep_desc := case v_dep_no
                 when 10 then 'Accounting'
                 when 20 then 'Research'
                 when 30 then 'Sales'
                 when 40 then 'Operations'
                 else 'Unknown'
               end;
dbms_output.put_line(v_dep_desc);
end;
/

declare
  v_boolean boolean := null;
  function f_bool_to_varch2(v_flag in boolean) return varchar2 is
  begin
    return 
    case v_flag 
      when true then 'True' 
      when false then 'False' 
      else 'Null'
    end;
  end f_bool_to_varch2;
begin
  dbms_output.put_line(f_bool_to_varch2(v_boolean));
end;
/

begin
  dbms_output.put_line(case when trim(to_char(sysdate, 'DAY')) in
                       ('SATURDAY', 'SUNDAY') then 'Holiday' else
                       'Working day' end);
end;
/
