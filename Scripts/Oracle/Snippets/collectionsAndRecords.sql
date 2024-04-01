-- Collections and Records

-- 1. Collections 
-- Three types of collections
-- Nested Tables
-- Associative array
-- Varray    

-- Nested Tables
DECLARE
   TYPE nested_type IS TABLE OF VARCHAR2(20);
   v1 nested_type;
BEGIN
   v1 := nested_type('A','B','C','D');
   for i in v1.first .. v1.last loop
   dbms_output.put_line(v1(i));
   end loop;
END;
/

DECLARE
   TYPE nested_type IS TABLE OF VARCHAR2(20);
   v1 nested_type := nested_type('A','B','C','D');
BEGIN
   for i in v1.first .. v1.last loop
   dbms_output.put_line(v1(i));
   end loop;
END;
/

DECLARE
  TYPE nested_type IS TABLE OF VARCHAR2(20);
  v1 nested_type := nested_type();
BEGIN
  v1.extend(3);
  v1(1) := 'A';
  v1(2) := 'B';
  v1(3) := 'C';

  for i in v1.first .. v1.last loop
    dbms_output.put_line(v1(i));
  end loop;

  for i in 1 .. v1.count loop
    dbms_output.put_line(v1(i));
  end loop;
END;
/

DECLARE
  TYPE nested_type IS TABLE OF VARCHAR2(20);
  v1 nested_type := nested_type();
BEGIN
  v1.extend();
  v1(v1.last) := 'A';

  v1.extend();
  v1(v1.last) := 'B';

  v1.extend();
  v1(v1.last) := 'C';

  for i in v1.first .. v1.last loop
    dbms_output.put_line(v1(i));
  end loop;

  for i in 1 .. v1.count loop
    dbms_output.put_line(v1(i));
  end loop;
END;
/

-- Associative array
DECLARE
  TYPE assoc_array_num_type IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE assoc_array_str_type IS TABLE OF VARCHAR2(32) INDEX BY PLS_INTEGER;
  TYPE assoc_array_str_type2 IS TABLE OF VARCHAR2(32) INDEX BY VARCHAR2(64);
  v1    assoc_array_num_type;
  v2    assoc_array_str_type;
  v3    assoc_array_str_type2;
  v_idx varchar(20);
BEGIN
  v1(1) := 10;
  v1(2) := 20;
  v1(3) := 30;

  for i in v1.first .. v1.last loop
    dbms_output.put_line(v1(i));
  end loop;

  v2(1) := 'A';
  v2(2) := 'B';
  v2(3) := 'C';

  for i in v2.first .. v2.last loop
    dbms_output.put_line(v2(i));
  end loop;

  v3('Ottawa') := 'Canada';
  v3('Washington') := 'USA';
  v3('Moscow') := 'Russia';

  v_idx := v3.first;
  while (v_idx is not null) loop
    dbms_output.put_line(v3(v_idx));
    v_idx := v3.next(v_idx);
  end loop;
END;
/

-- Varray 
DECLARE
   TYPE varray_type IS VARRAY(5) OF INTEGER;
   v1 varray_type;
BEGIN
   v1 := varray_type(10, 20, 40, 80, 160);
   for i in v1.first .. v1.last loop
   dbms_output.put_line(v1(i));
   end loop;
END;
/

DECLARE
   TYPE varray_type IS VARRAY(5) OF INTEGER;
   v1 varray_type := varray_type(10, 20, 40, 80, 160);
BEGIN
   for i in v1.first .. v1.last loop
   dbms_output.put_line(v1(i));
   end loop;
END;
/

-- 2. Records 
-- Cursor-based record
-- record_name cursor_name%ROWTYPE;
DECLARE
    CURSOR c_contacts IS
        SELECT first_name, last_name, phone
        FROM contacts;
    r_contact c_contacts%ROWTYPE;

-- Programmer-defined record
-- TYPE record_type IS RECORD

-- Table-based record
-- record_name table_name%ROWTYPE;

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
