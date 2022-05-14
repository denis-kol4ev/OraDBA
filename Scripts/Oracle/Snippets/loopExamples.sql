DROP TABLE sales_data;
/

CREATE TABLE sales_data (year INTEGER, sales_amount NUMBER);
/

insert into sales_data values(2000, 1000);
insert into sales_data values(2001, 1500);
insert into sales_data values(2002, 2000);
insert into sales_data values(2003, 2300);
insert into sales_data values(2004, 3100);
commit;

CREATE OR REPLACE PROCEDURE display_total_sales(year_in IN PLS_INTEGER) IS
BEGIN
  DBMS_OUTPUT.put_line('Total for year ' || year_in);
END display_total_sales;
/

/*
Простой цикл начинается с ключевого слова LOOP и завершается командой END LOOP.
Выполнение цикла прерывается при выполнении команды EXIT WHEN или EXIT.
*/
CREATE OR REPLACE PROCEDURE display_multiple_years(start_year_in IN PLS_INTEGER,
                                                   end_year_in   IN PLS_INTEGER) IS
  l_current_year PLS_INTEGER := start_year_in;
BEGIN
  LOOP
    EXIT WHEN l_current_year > end_year_in;
    display_total_sales(l_current_year);
    l_current_year := l_current_year + 1;
  END LOOP;
END display_multiple_years;
/

CREATE OR REPLACE PROCEDURE display_multiple_years(start_year_in IN PLS_INTEGER,
                                                   end_year_in   IN PLS_INTEGER) IS
  l_current_year PLS_INTEGER := start_year_in;
BEGIN
  LOOP
    IF l_current_year > end_year_in 
      THEN
        EXIT;
    ELSE
      display_total_sales(l_current_year);
      l_current_year := l_current_year + 1;
    END IF;
  END LOOP;
END display_multiple_years;
/

/*
Цикл WHILE имеет много общего с простым циклом. Принципиальное отличие заключается в том, 
что условие завершения проверяется перед выполнением очередной итерации.
*/
CREATE OR REPLACE PROCEDURE display_multiple_years(start_year_in IN PLS_INTEGER,
                                                   end_year_in   IN PLS_INTEGER) IS
  l_current_year PLS_INTEGER := start_year_in;
BEGIN
  WHILE (l_current_year <= end_year_in) LOOP
    display_total_sales(l_current_year);
    l_current_year := l_current_year + 1;
  END LOOP;
END display_multiple_years;
/

/*
Цикл FOR существует в двух формах: числовой и курсорной. В числовых циклах FOR задается начальное и конечное целочисленные значения, 
а PL/SQL перебирает все промежуточные значения, после чего завершает цикл.
*/
CREATE OR REPLACE PROCEDURE display_multiple_years(start_year_in IN PLS_INTEGER,
                                                   end_year_in   IN PLS_INTEGER) IS
BEGIN
  FOR l_current_year IN start_year_in .. end_year_in LOOP
    display_total_sales(l_current_year);
  END LOOP;
END display_multiple_years;
/

/*
Курсорная форма цикла FOR имеет аналогичную базовую структуру, но вместо границ
числового диапазона в ней задается курсор или конструкция SELECT:
*/
CREATE OR REPLACE PROCEDURE display_multiple_years(start_year_in IN PLS_INTEGER,
                                                   end_year_in   IN PLS_INTEGER) IS
BEGIN
  FOR sales_rec IN (SELECT *
                      FROM sales_data
                     WHERE year BETWEEN start_year_in AND end_year_in) LOOP
    -- Процедуре передается неявно объявленная запись с типом sales_data%ROWTYPE...
    display_total_sales(sales_rec.year);
  END LOOP;
END display_multiple_years;
/

CREATE OR REPLACE PROCEDURE display_multiple_years(start_year_in IN PLS_INTEGER,
                                                   end_year_in   IN PLS_INTEGER) IS
  cursor c1 is
    SELECT *
      FROM sales_data
     WHERE year BETWEEN start_year_in AND end_year_in;
BEGIN
  FOR sales_rec IN c1 LOOP
    display_total_sales(sales_rec.year);
  END LOOP;
END display_multiple_years;
/

/*
Бесконечный цикл.
Например нам нужно постоянно выполнять сбор данных с паузой между итерациями.  
*/
BEGIN
  LOOP
  dbms_output.put_line(sysdate);
  dbms_lock.sleep(5);
  END LOOP;
END;
/

/*
Команда continue используется для выхода из текущей итерации цикла и перехода к следующей.
Альтернативный вариант использовать if, но при использовании continue можно сократить уровень
вложенности (в сравнении с if) и тем самым упростить читаемость кода.
*/
BEGIN
  FOR l_index IN 1 .. 10 LOOP
    CONTINUE WHEN MOD(l_index, 2) = 0;
    dbms_output.put_line('Counter=' || to_char(l_index));
  END LOOP;
END;
/

BEGIN
  FOR l_index IN 1 .. 10 LOOP
    if mod(l_index, 2) = 0
    then null;
    else
    dbms_output.put_line('Counter=' || to_char(l_index));
    end if;
  END LOOP;
END;
/

/*
Использование continue с несколькими условиям
*/

declare
  v1 number := 0;
begin
  loop
    v1 := v1 + 1;
    exit when v1 = 10;
    continue when v1 = 1;
    continue when v1 = 5;
    dbms_output.put_line('Counter=' || v1);
  end loop;
end;

/*
Команду continue можно использовать для прерывания внутренних циклов и 
передачи управления внешнему циклу, для этого используются метки циклов.
*/
BEGIN
  <<outer>>
  FOR outer_index IN 1 .. 5 LOOP
    dbms_output.put_line('Outer counter = ' || to_char(outer_index));
    <<inner>>
    FOR inner_index IN 1 .. 5 LOOP
      dbms_output.put_line('Inner counter = ' || to_char(inner_index));
      CONTINUE outer;
    END LOOP inner;
  END LOOP outer;
END;
/
