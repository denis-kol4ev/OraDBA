DROP TABLE sales_data
/

CREATE TABLE sales_data (year INTEGER, sales_amount NUMBER)
/

CREATE OR REPLACE PROCEDURE display_total_sales (year_in IN PLS_INTEGER)
IS
BEGIN
   DBMS_OUTPUT.put_line ('Total for year ' || year_in);
END display_total_sales;
/

/*
Простой цикл начинается с ключевого слова LOOP и завершается командой END LOOP.
Выполнение цикла прерывается при выполнении команды EXIT WHEN.
*/
CREATE OR REPLACE PROCEDURE display_multiple_years (
   start_year_in IN PLS_INTEGER
 , end_year_in   IN PLS_INTEGER
)
IS
   l_current_year   PLS_INTEGER := start_year_in;
BEGIN
   LOOP
      EXIT WHEN l_current_year > end_year_in;
      display_total_sales (l_current_year);
      l_current_year := l_current_year + 1;
   END LOOP;
END display_multiple_years;
/

/*
Цикл FOR существует в двух формах: числовой и курсорной. В числовых циклах FOR про-
граммист задает начальное и конечное целочисленные значения, а PL/SQL перебирает
все промежуточные значения, после чего завершает цикл:
*/
CREATE OR REPLACE PROCEDURE display_multiple_years (
   start_year_in IN PLS_INTEGER
 , end_year_in   IN PLS_INTEGER
)
IS
BEGIN
   FOR l_current_year IN start_year_in .. end_year_in
   LOOP
      display_total_sales (l_current_year);
   END LOOP;
END display_multiple_years;
/

/*
Курсорная форма цикла FOR имеет аналогичную базовую структуру, но вместо границ
числового диапазона в ней задается курсор или конструкция SELECT:
*/
CREATE OR REPLACE PROCEDURE display_multiple_years (
   start_year_in IN PLS_INTEGER
 , end_year_in   IN PLS_INTEGER
)
IS
BEGIN
   FOR sales_rec IN (
      SELECT *
        FROM sales_data
       WHERE year BETWEEN start_year_in AND end_year_in)
   LOOP
   -- Процедуре передается запись, неявно объявленная
   -- с типом sales_data%ROWTYPE...
      display_total_sales (sales_rec.year);
   END LOOP;
END display_multiple_years;
/

/*
Цикл WHILE имеет много общего с простым циклом. Принципиальное отличие за-
ключается в том, что условие завершения проверяется перед выполнением очередной
итерации.
*/
CREATE OR REPLACE PROCEDURE display_multiple_years (
   start_year_in IN PLS_INTEGER
 , end_year_in   IN PLS_INTEGER
)
IS
   l_current_year   PLS_INTEGER := start_year_in;
BEGIN
   WHILE (l_current_year <= end_year_in)
   LOOP
      display_total_sales (l_current_year);
      l_current_year := l_current_year + 1;
   END LOOP;
END display_multiple_years;
/