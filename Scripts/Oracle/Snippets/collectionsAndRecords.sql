-- Collections and Records
-- 1. Collections
-- 2. Records
-- 3. Operations on Collections
-- 4. Collections methods
   
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

-- Associative array example 1
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

  v3('Canada') := 'Ottawa';
  v3('USA') := 'Washington';
  v3('Russia') := 'Moscow';

  v_idx := v3.first;
  while (v_idx is not null) loop
    dbms_output.put_line('The capital of ' || v_idx || ' is ' || v3(v_idx));
    v_idx := v3.next(v_idx);
  end loop;
END;
/

-- Associative array example 2
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
declare
  cursor c_users is
    select u.user_id, u.username, u.last_login from dba_users u;
  r_users c_users%rowtype;
begin
  open c_users;
  loop
    fetch c_users
      into r_users;
    exit when c_users%notfound;
    if r_users.last_login is not null then
      dbms_output.put_line(r_users.username || '   ' || r_users.last_login);
    end if;
  end loop;
end;

-- Programmer-defined record
-- TYPE record_type IS RECORD

-- Record with nested table collection
declare
  type t_rec is record(
    user varchar2(30),
    host varchar2(30),
    port number);
  type t_rec_type is table of t_rec;
  v1 t_rec_type := t_rec_type();
begin
  v1.extend();
  v1(v1.last).user := 'sap_dev';
  v1(v1.last).host := 'server-dev';
  v1(v1.last).port := 1521;

  v1.extend();
  v1(v1.last).user := 'sap_test';
  v1(v1.last).host := 'server-test';
  v1(v1.last).port := 1521;

  v1.extend();
  v1(v1.last).user := 'sap_prod';
  v1(v1.last).host := 'server-prod';
  v1(v1.last).port := 1521;

  for i in 1 .. v1.count loop
    dbms_output.put_line(v1(i).user || ' ' || v1(i).host || ' ' || v1(i).port);
  end loop;

  for i in v1.first .. v1.last loop
    dbms_output.put_line(v1(i).user || ' ' || v1(i).host || ' ' || v1(i).port);
  end loop;
end;
/

-- Record with associative array collection (index by pls_integer)
declare
  type t_rec is record(user varchar2(30), host varchar2(30), port number);
  type t_rec_type is table of t_rec index by pls_integer;
  v1 t_rec_type := t_rec_type();
begin
  v1(1).user := 'sap_dev';
  v1(1).host := 'server-dev';
  v1(1).port := 1521;

  v1(2).user := 'sap_test';
  v1(2).host := 'server-test';
  v1(2).port := 1521;

  v1(3).user := 'sap_prod';
  v1(3).host := 'server-prod';
  v1(3).port := 1521;

  for i in 1 .. v1.count loop
  dbms_output.put_line(v1(i).user || ' ' || v1(i).host || ' ' || v1(i).port);
  end loop;

  for i in v1.first .. v1.last loop
  dbms_output.put_line(v1(i).user || ' ' || v1(i).host || ' ' || v1(i).port);
  end loop;
end;
/

-- Record with associative array collection (index by varchar2)
declare
  type t_rec is record(user varchar2(30), host varchar2(30), port number);
  type t_rec_type is table of t_rec index by varchar2(64);
  v1 t_rec_type := t_rec_type();
  v_idx varchar(20);
begin
  v1('DC1').user := 'sap_dev';
  v1('DC1').host := 'server-dev';
  v1('DC1').port := 1521;

  v1('DC2').user := 'sap_test';
  v1('DC2').host := 'server-test';
  v1('DC2').port := 1521;

  v1('DC3').user := 'sap_prod';
  v1('DC3').host := 'server-prod';
  v1('DC3').port := 1521;

  v_idx := v1.first;
  while (v_idx is not null) loop
    dbms_output.put_line(v_idx || ': ' || v1(v_idx).user || ' ' || v1(v_idx).host || ' ' || v1(v_idx).port);
    v_idx := v1.next(v_idx);
  end loop;
end;
/
   
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

-- Table-based record with associative array
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

-- Table-based record with associative array and bulk collect
declare
  type dba_users_table_type is table of dba_users%rowtype index by pls_integer;
  v_dba_users_table dba_users_table_type;
begin
  select * bulk collect into v_dba_users_table from dba_users;
  for i in v_dba_users_table.first .. v_dba_users_table.last loop
    dbms_output.put_line(v_dba_users_table(i).username || ' ' || v_dba_users_table(i).last_login);
  end loop;
end;
/

-- 3. Operations on Collections
-- 3.1 Determing members of collection: member of  / not member of
declare
  type user_type is table of dba_users.username%type;
  v_system_users user_type := user_type('SYS', 'SYSTEM', 'DBSNMP');
begin
  for i in (select user_id, username from dba_users) loop
    if i.username not member of v_system_users then
      dbms_output.put_line(i.user_id);
    end if;
  end loop;
end;
/

DECLARE
  TYPE user_type IS TABLE OF dba_users.username%type;
  v_system_users user_type := user_type('SYS', 'SYSTEM', 'DBSNMP');
  v_all_users    user_type;
BEGIN
  select username bulk collect into v_all_users from dba_users;
  for i in v_all_users.first .. v_all_users.last loop
    if v_all_users(i) member of v_system_users then
      dbms_output.put_line(v_all_users(i));
    end if;
  end loop;
END;
/

DECLARE
  TYPE user_rec is record(
    user_id  dba_users.user_id%type,
    username dba_users.username%type);
  TYPE user_rec_type IS TABLE OF user_rec;
  v_all_users user_rec_type;

  TYPE sys_user_type IS TABLE OF dba_users.username%type;
  v_sys_users sys_user_type := sys_user_type('SYS', 'SYSTEM', 'DBSNMP');

BEGIN
  select user_id, username bulk collect into v_all_users from dba_users;
  for i in v_all_users.first .. v_all_users.last loop
    if v_all_users(i).username member of v_sys_users then
      dbms_output.put_line(v_all_users(i).user_id);
    end if;
  end loop;
END;
/

-- Check collection is empty / is not empty
declare
  type user_type is table of dba_users.username%type;
  v_system_users user_type;
begin
  v_system_users := user_type();
  if v_system_users is empty then
    dbms_output.put_line('Collection is empty');
  end if;
  v_system_users := user_type('SYS', 'SYSTEM', 'DBSNMP');
  if v_system_users is not empty then
    dbms_output.put_line('Collection is not empty');
  end if;
end;
/

-- Check collection is null / is not null
declare
  type user_type is table of dba_users.username%type;
  v_system_users user_type;
begin
  if v_system_users is null then
    dbms_output.put_line('Collection is null');
  end if;
  v_system_users := user_type();
  if v_system_users is not null then
    dbms_output.put_line('Collection is not null');
  end if;
end;
/

-- Comparing collections
declare
  type user_type is table of varchar2(50); -- element type is not record type
  v_users1 user_type := user_type('SYS', 'SYSTEM', 'DBSNMP');
  v_users2 user_type := user_type('SYSTEM', 'DBSNMP', 'SYS');
  v_users3 user_type := user_type('SCOTT', 'SYSTEM', 'DBSNMP');
begin
  if v_users1 = v_users2 then
    dbms_output.put_line('v_users1 = v_users2');
  end if;
  if v_users1 != v_users3 then
    dbms_output.put_line('v_users1 != v_users3');
  end if;
end;
/

-- Cardinality, Set, Multiset 
/*
CARDINALITY returns the number of elements in a nested table

SET converts a nested table into a set by eliminating duplicates.

MULTISET operators combine the results of two nested tables into a single nested table.

MULTISET EXCEPT [DISTINCT] takes as arguments two nested tables and returns a nested table                             
                           whose elements are in the first nested table but not in the 
                           second nested table. 
MULTISET INTERSECT [DISTINCT] takes as arguments two nested tables and returns a nested table 
                              whose values are common in the two input nested tables.
MULTISET UNION [DISTINCT] takes as arguments two nested tables and returns a nested table 
                          whose values are those of the two input nested tables.
*/
declare
  type user_type is table of varchar2(50);
  v_users1 user_type := user_type('SYS', 'SYSTEM', 'DBSNMP');
  v_users2 user_type := user_type('SCOTT', 'SYSTEM', 'DBSNMP');
  v_users3 user_type := user_type('SYS',
                                  'SYSTEM',
                                  'DBSNMP',
                                  'SYS',
                                  'SYSTEM',
                                  'DBSNMP');

  v_cardinality        number;
  v_set                user_type;
  v_multiset_except    user_type;
  v_multiset_intersect user_type;
  v_multiset_union     user_type;

begin
  dbms_output.put_line('CARDINALITY');
  v_cardinality := cardinality(v_users3);
  dbms_output.put_line(v_cardinality);
  dbms_output.put_line('*****');

  dbms_output.put_line('SET');
  v_set := set(v_users3);
  for i in v_set.first .. v_set.last loop
    dbms_output.put_line(v_set(i));
  end loop;
  dbms_output.put_line('*****');

  dbms_output.put_line('MULTISET EXCEPT');
  v_multiset_except := v_users1 MULTISET EXCEPT v_users2;
  for i in v_multiset_except.first .. v_multiset_except.last loop
    dbms_output.put_line(v_multiset_except(i));
  end loop;
  dbms_output.put_line('*****');

  dbms_output.put_line('MULTISET INTERSECT');
  v_multiset_intersect := v_users1 MULTISET INTERSECT v_users2;
  for i in v_multiset_intersect.first .. v_multiset_intersect.last loop
    dbms_output.put_line(v_multiset_intersect(i));
  end loop;
  dbms_output.put_line('*****');

  dbms_output.put_line('MULTISET UNION');
  v_multiset_union := v_users1 MULTISET UNION v_users2;
  for i in v_multiset_union.first .. v_multiset_union.last loop
    dbms_output.put_line(v_multiset_union(i));
  end loop;
end;
/

-- Comparing Nested Tables with SQL Multiset Conditions
DECLARE 
  TYPE nested_typ IS TABLE OF NUMBER; 
  nt1 nested_typ := nested_typ(1,2,3); 
  nt2 nested_typ := nested_typ(3,2,1); 
  nt3 nested_typ := nested_typ(2,3,1,3); 
  nt4 nested_typ := nested_typ(1,2,4); 
 
  PROCEDURE testify ( 
    truth BOOLEAN := NULL, 
    quantity NUMBER := NULL 
  ) IS 
  BEGIN 
    IF truth IS NOT NULL THEN 
      DBMS_OUTPUT.PUT_LINE ( 
        CASE truth 
           WHEN TRUE THEN 'True' 
           WHEN FALSE THEN 'False' 
        END 
      ); 
    END IF; 
    IF quantity IS NOT NULL THEN 
        DBMS_OUTPUT.PUT_LINE(quantity); 
    END IF; 
  END; 
BEGIN 
  testify(truth => (nt1 IN (nt2,nt3,nt4)));        -- condition 
  testify(truth => (nt1 SUBMULTISET OF nt3));      -- condition 
  testify(truth => (nt1 NOT SUBMULTISET OF nt4));  -- condition 
  testify(truth => (4 MEMBER OF nt1));             -- condition 
  testify(truth => (nt3 IS A SET));                -- condition 
  testify(truth => (nt3 IS NOT A SET));            -- condition 
  testify(truth => (nt1 IS EMPTY));                -- condition 
  testify(quantity => (CARDINALITY(nt3)));         -- function 
  testify(quantity => (CARDINALITY(SET(nt3))));    -- 2 functions 
END; 
/

-- Collections methods
/*
The basic syntax of a collection method invocation is: collection_name.method

DELETE - Deletes elements from collection.

TRIM - Deletes elements from end of varray or nested table.
TRIM operates on the internal size of a collection. That is, if DELETE deletes 
an element but keeps a placeholder for it, then TRIM considers the element to exist. 
Therefore, TRIM can delete a deleted element.

EXTEND - Adds elements to end of varray or nested table.

EXISTS - Returns TRUE if and only if specified element of varray or nested table exists.

FIRST - Returns first index in collection.

LAST - Returns last index in collection.

COUNT - Returns number of elements in collection.

LIMIT - Returns maximum number of elements that collection can have.

PRIOR - Returns index that precedes specified index.

NEXT - Returns index that succeeds specified index.
*/
declare
  type nt_type is table of varchar2(2); -- все примеры будут работать и с is table of number
  v_nt nt_type;
  
  v_idx number;
  
  procedure print_nt(nt_v nt_type) is
  begin
    v_idx := v_nt.first;
    if v_idx is null then
      dbms_output.put_line('v_nt is empty');
      else
    while v_idx is not null loop
      dbms_output.put_line('v_nt index ' || v_idx || ' v_nt value ' || v_nt(v_idx));
      v_idx := v_nt.next(v_idx);
    end loop;
    end if;
    dbms_output.put_line('-----');
  end print_nt;

begin
  dbms_output.put_line('*** DELETE ***');
  
  v_nt := nt_type('A', 'B', 'C', 'D');
  
  dbms_output.put_line('Initial collection');
  print_nt(v_nt);
  
  dbms_output.put_line('Delete second element');
  v_nt.DELETE(2);     
  print_nt(v_nt);
  
  dbms_output.put_line('Restore second element');
  v_nt(2) := 'BB';
  print_nt(v_nt);
  
  dbms_output.put_line('Delete range of elements');
  v_nt.DELETE(2, 4);  
  print_nt(v_nt);
  
  dbms_output.put_line('Restore third element');
  v_nt(3) := 'CC';
  print_nt(v_nt);
  
  dbms_output.put_line('Delete all elements');
  v_nt.DELETE;
  print_nt(v_nt);

  dbms_output.put_line('*** TRIM ***');
  
  v_nt := nt_type('A', 'B', 'C', 'D');
  
  dbms_output.put_line('Initial collection');
  print_nt(v_nt);
    
  dbms_output.put_line('Trim last element');
  v_nt.TRIM;
  print_nt(v_nt);
  
  dbms_output.put_line('Delete third element');
  v_nt.DELETE(3);
  print_nt(v_nt);
  
  dbms_output.put_line('Trim last two elements');
  v_nt.TRIM(2);
  print_nt(v_nt);

  dbms_output.put_line('*** EXTEND ***');
  
  v_nt := nt_type('A', 'B', 'C', 'D');
  
  dbms_output.put_line('Initial collection');
  print_nt(v_nt);
  
  dbms_output.put_line('Append two copies of first element');
  v_nt.EXTEND(2,1); 
  print_nt(v_nt);
  
  dbms_output.put_line('Delete fifth element');
  v_nt.DELETE(5); 
  print_nt(v_nt);
  
  dbms_output.put_line('Append one null element');
  v_nt.EXTEND; 
  print_nt(v_nt);
  
  dbms_output.put_line('*** EXISTS ***');
  
  v_nt := nt_type('A', 'B', 'C', 'D');
  
  dbms_output.put_line('Initial collection');
  print_nt(v_nt);
  
  dbms_output.put_line('Delete second element');
  
  v_nt.DELETE(2);
  for i in 1..4 loop
    if v_nt.EXISTS(i) then
      dbms_output.put_line('v_nt(' || i || ') = ' || v_nt(i));
    else
      dbms_output.put_line('v_nt(' || i || ') does not exist');
    end if;
  end loop;
  
  dbms_output.put_line('*** FIRST and LAST ***');
  
  v_nt := nt_type('A', 'B', 'C', 'D');
  
  dbms_output.put_line('Initial collection');
  print_nt(v_nt);
    
  dbms_output.put_line('FIRST = ' || v_nt.FIRST);
  dbms_output.put_line('LAST = ' || v_nt.LAST);
  
  dbms_output.put_line('Delete 1 and 4 elements');
  v_nt.DELETE(1);
  v_nt.DELETE(4);
  
  dbms_output.put_line('FIRST = ' || v_nt.FIRST);
  dbms_output.put_line('LAST = ' || v_nt.LAST);
 
  dbms_output.put_line('*** COUNT ***');
  
  v_nt := nt_type('A', 'B', 'C', 'D');
  
  dbms_output.put_line('Initial collection');
  print_nt(v_nt);
  dbms_output.put_line('COUNT = ' || v_nt.COUNT);
  dbms_output.put_line('LAST = ' || v_nt.LAST);
  
  dbms_output.put_line('Delete third element');
  v_nt.DELETE(3);
  print_nt(v_nt);
  dbms_output.put_line('COUNT = ' || v_nt.COUNT);
  dbms_output.put_line('LAST = ' || v_nt.LAST);
  
  dbms_output.put_line('Add two null elements to end');
  v_nt.EXTEND(2);
  print_nt(v_nt);
  dbms_output.put_line('COUNT = ' || v_nt.COUNT);
  dbms_output.put_line('LAST = ' || v_nt.LAST);

end;
/
