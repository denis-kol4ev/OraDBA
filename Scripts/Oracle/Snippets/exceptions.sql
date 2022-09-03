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
