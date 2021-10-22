-- Collections and Records

-- Record usage example
DECLARE
  v_countryid      varchar2(20) := 'CA';
  v_country_record countries%ROWTYPE;
BEGIN
  SELECT *
    INTO v_country_record
    FROM countries
   WHERE country_id = UPPER(v_countryid);

  DBMS_OUTPUT.PUT_LINE('Country Id: ' || v_country_record.country_id || chr(10) ||
                       'Country Name: ' || v_country_record.country_name || chr(10) ||
                       'Region: ' || v_country_record.region_id);

END;
/

-- Associative array usage example 1
DECLARE
  TYPE dept_table_type is table of departments.department_name%TYPE INDEX BY PLS_INTEGER;
  my_dept_table dept_table_type;
  f_loop_count  NUMBER(2) := 10;
  v_deptno      NUMBER(4) := 0;
BEGIN
  FOR i IN 1 .. f_loop_count LOOP
    v_deptno := v_deptno + 10;
    SELECT department_name
      INTO my_dept_table(i)
      FROM departments
     WHERE department_id = v_deptno;
  END LOOP;
  FOR i IN 1 .. f_loop_count LOOP
    DBMS_OUTPUT.PUT_LINE(my_dept_table(i));
  END LOOP;
END;
/

-- Associative array usage example 2
DECLARE
  TYPE dept_table_type is table of departments%ROWTYPE INDEX BY PLS_INTEGER;
  my_dept_table dept_table_type;
  f_loop_count  NUMBER(2) := 10;
  v_deptno      NUMBER(4) := 0;
BEGIN
  FOR i IN 1 .. f_loop_count LOOP
    v_deptno := v_deptno + 10;
    SELECT *
      INTO my_dept_table(i)
      FROM departments
     WHERE department_id = v_deptno;
  END LOOP;
  FOR i IN 1 .. f_loop_count LOOP
    DBMS_OUTPUT.PUT_LINE('Department Number: ' || my_dept_table(i).department_id ||
                         ' Department Name: ' || my_dept_table(i).department_name ||
                         ' Manager Id: ' || my_dept_table(i).manager_id ||
                         ' Location Id: ' || my_dept_table(i).location_id);
  END LOOP;
END;
/
