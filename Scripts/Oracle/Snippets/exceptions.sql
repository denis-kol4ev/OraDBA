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
