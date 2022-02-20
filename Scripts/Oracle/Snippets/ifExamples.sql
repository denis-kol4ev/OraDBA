/*
Три варианта конструкции IF
IF THEN END IF;
IF THEN ELSE END IF;
IF THEN ELSIF ELSE END IF;
*/

-- IF THEN END IF;
declare
  v1 number := 100;
  v2 number := 99;
begin
  if v1 > v2 then
    dbms_output.put_line(v1 || ' is greater than ' || v2);
  end if;
end;
/

-- IF THEN ELSE END IF;
declare
  v1 number := 100;
  v2 number := 99;
begin
  if v1 > v2 then
    dbms_output.put_line(v1 || ' is greater than ' || v2);
  else
    dbms_output.put_line(v1 || ' is not greater than ' || v2);
  end if;
end;
/

-- IF THEN ELSIF ELSE END IF;
declare
  v1 number := 100;
  v2 number := 99;
begin
  if v1 > v2 then
    dbms_output.put_line(v1 || ' is greater than ' || v2);
  elsif v1 < v2 then
    dbms_output.put_line(v1 || ' is lower than ' || v2);
  else
    dbms_output.put_line(v1 || ' and ' || v2 || ' are equal');
  end if;
end;
/

-- Nested if
declare
  v1 number := 100;
  v2 number := 99;
begin
  if v1 > v2 then
    dbms_output.put_line(v1 || ' is greater than ' || v2);
    if (v2 / v1) < 0.5 then
      dbms_output.put_line(v1 || ' is significant greater than ' || v2);     
      end if;
  end if;
end;
/