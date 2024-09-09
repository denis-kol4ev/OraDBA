/*
  NAME
    drop_db_links.sql
  DESCRIPTION
    Удаление всех линков в БД, за исключением линков из списка для сохранения.
    Запускать от пользователя SYS.
    Линк SYS.SYS_HUB создаваемый по умолчанию (12.2 и старше) используется только для RAC.
*/
DECLARE
  TYPE nested_type IS TABLE OF VARCHAR2(256);
  -- Указываем линки которые необходимо сохранить или отставляем значение по умолчанию
  v_links_to_keep nested_type := nested_type('OWNER.LINK', 'SYS.SYS_HUB');
  v_all_links     nested_type := nested_type();
  v_owner         VARCHAR2(128);
  v_db_link       VARCHAR2(128);
  v_user_id       PLS_INTEGER;
  v_deleted_cnt   PLS_INTEGER := 0;
  v_cursor        PLS_INTEGER;
  v_sql           VARCHAR2(512);
BEGIN

  SELECT l.owner || '.' || l.db_link
    BULK COLLECT
    INTO v_all_links
    FROM dba_db_links l;

  FOR rec IN v_all_links.first .. v_all_links.last LOOP
    IF v_all_links(rec) NOT MEMBER OF v_links_to_keep THEN
      SELECT u.user_id, l.owner, l.db_link
        INTO v_user_id, v_owner, v_db_link
        FROM dba_db_links l, dba_users u
       WHERE l.owner = u.username(+)
         AND l.owner || '.' || l.db_link = v_all_links(rec);
      IF v_owner = 'PUBLIC' THEN
        EXECUTE IMMEDIATE 'DROP PUBLIC DATABASE LINK ' || v_db_link;
        v_deleted_cnt := v_deleted_cnt + 1;
      ELSE
        v_sql    := 'DROP DATABASE LINK ' || v_db_link;
        v_cursor := dbms_sys_sql.open_cursor();
        dbms_sys_sql.parse_as_user(c             => v_cursor,
                                   STATEMENT     => v_sql,
                                   language_flag => dbms_sql.native,
                                   userid        => v_user_id);
        v_deleted_cnt := v_deleted_cnt + 1;
      END IF;
    END IF;
  END LOOP;

  dbms_output.put_line('---------------------------');
  dbms_output.put_line('Links left in schemas:');
  FOR rec IN (SELECT owner, COUNT(*) cnt FROM dba_db_links GROUP BY owner) LOOP
  
    dbms_output.put_line(rec.owner || ' - ' || rec.cnt);
  END LOOP;
  dbms_output.put_line('---------------------------');
  dbms_output.put_line('Deleted links: ' || v_deleted_cnt);
  dbms_output.put_line('---------------------------');
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
/
