-- Case 1
-- Handling predefined exceptions
DECLARE
  v_ename   employees.last_name%TYPE;
  v_emp_sal employees.salary%TYPE := 2000;
BEGIN
  SELECT last_name INTO v_ename FROM employees WHERE salary = v_emp_sal;
  INSERT INTO messages (results) VALUES (v_ename || ' - ' || v_emp_sal);
EXCEPTION
  WHEN no_data_found THEN
    INSERT INTO messages
      (results)
    VALUES
      ('No employee with a salary of ' || TO_CHAR(v_emp_sal));
  WHEN too_many_rows THEN
    INSERT INTO messages
      (results)
    VALUES
      ('More than one employee with a salary of ' || TO_CHAR(v_emp_sal));
  WHEN others THEN
    INSERT INTO messages (results) VALUES ('Some other error occurred.');
END;

-- Case 2
-- Handling standard oracle exceptions
-- 00001, 00000, "unique constraint (%s.%s) violated"
BEGIN
  INSERT INTO hr.departments (department_id,
                              department_name,
                              manager_id,
                              location_id) VALUES (10, 'Administration', 200, 1700);
EXCEPTION
    WHEN others THEN
      IF SQLCODE = -00001 THEN
    DBMS_OUTPUT.PUT_LINE('Duplicate department_id found');
END IF;
END;

-- Case 3
-- Handling standard oracle exceptions with EXCEPTION_INIT directive
-- 02292 "integrity constraint (%s.%s) violated - child record found"
DECLARE
  e_childrecord_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_childrecord_exists, -02292);
BEGIN
  DBMS_OUTPUT.PUT_LINE(' Deleting department 40........');
  delete from departments where department_id = 40;
EXCEPTION
  WHEN e_childrecord_exists THEN
    DBMS_OUTPUT.PUT_LINE(' Cannot delete this department. There are employees in this department (child records exist.) ');
END;

-- Case 4
-- Raise a user-defined exception via RAISE_APPLICATION_ERROR procedure 
declare
  date_of_manufacture date := to_date('01.10.2019', 'dd.mm.yyyy');
  min_years           number := 3;
  actual_years        number;
begin
  actual_years := months_between(trunc(sysdate, 'mm'),
                                 trunc(date_of_manufacture, 'mm'));
  if min_years > (actual_years / 12) then
    raise_application_error(-20001,
                            'Vehicle must be at least ' || min_years ||
                            ' years old, actual age is ' ||
                            floor(actual_years / 12) || ' years and ' ||
                            mod(actual_years, 12) || ' month');
  end if;
end;

-- Case 5
-- Продолжение работы цикла в случае возникновения ошибки в одной или более итераций
-- How to Handle Exceptions And Still Continue to Process a PL/SQL Procedure (Doc ID 1297175.1)

-- Процедура закончит работу на итерации 5 при возникновении exception. 
-- Код следующий после end loop не выполнится.
CREATE OR REPLACE PROCEDURE main_run IS
  zero_found_exception EXCEPTION;
  v_mod                NUMBER;
  v_counter            NUMBER;
BEGIN
  FOR v_loop IN 1 .. 20 LOOP
    v_counter := v_loop;
    dbms_output.put_line('Loop number ' || v_loop);
    v_mod := MOD(v_loop, 5);
    IF (v_mod = 0) THEN
      RAISE zero_found_exception;
    END IF;
  END LOOP;
  dbms_output.put_line('Back in the outer section after the exception.');
EXCEPTION
  WHEN zero_found_exception THEN
    dbms_output.put_line('Zero Found Exception was raised');
  WHEN OTHERS THEN
    RAISE;
END;
/

begin
  main_run;
end;
/

-- Та же логика, но добавлен внутренний блок begin....end, в который добавлен свой exception.
-- Процедура выполнит все 20 итераций, не смотря на то, что обрабатываемый exception возникает 4 раза в ходе выполнения. 
-- Код следующий после end loop выполнится.
CREATE OR REPLACE PROCEDURE main_run2 IS
  zero_found_exception EXCEPTION;
  v_mod                NUMBER;
  v_counter            NUMBER;
BEGIN
  ---BEGIN outer block
  dbms_output.put_line('In the outer section.');
  FOR v_loop IN 1 .. 20 LOOP
    BEGIN
      ---BEGIN Inner block
      v_counter := v_loop;
      dbms_output.put_line('Loop number ' || v_loop);
      v_mod := MOD(v_loop, 5);
      IF (v_mod = 0) THEN
        RAISE zero_found_exception;
      END IF;
    EXCEPTION
      WHEN zero_found_exception THEN
        dbms_output.put_line('Zero Found Exception was raised');
      WHEN OTHERS THEN
        RAISE;
    END; ---END inner block
  END LOOP;
  dbms_output.put_line('Back in the outer section after the exception.');
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END; ---END outer block
/

begin
  main_run2;
end;
/
