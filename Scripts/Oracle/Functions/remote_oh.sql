-- Get oracle home from remote database
create or replace function sys.remote_oh(p_db_link_name in varchar2)
  return varchar2 as
  l_remote_oh varchar2(100);
begin
  execute immediate replace('declare ' || '   l_cursor    int; ' ||
                            '   l_status    int; ' ||
                            '   l_oh      varchar2(100); ' || 'begin ' ||
                            
                            '    l_cursor := dbms_sql.open_cursor@<REMOTE_DB>; ' ||
                            
                            '    dbms_sql.parse@<REMOTE_DB>  ' ||
                            '        ( l_cursor, ' ||
                            '          ''begin :x := SYS_CONTEXT (''''USERENV'''',''''ORACLE_HOME''''); end;'', ' ||
                            '          dbms_sql.native ' || '        ); ' ||
                            
                            '    dbms_sql.bind_variable@<REMOTE_DB> ' ||
                            '       ( l_cursor, '':x'', l_oh, 100); ' ||
                            
                            '    l_status := dbms_sql.execute@<REMOTE_DB> ' ||
                            '       ( l_cursor ); ' ||
                            
                            '    dbms_sql.variable_value@<REMOTE_DB> ' ||
                            '       (l_cursor, '':x'', l_oh ); ' ||
                            
                            '    dbms_sql.close_cursor@<REMOTE_DB> ' ||
                            '       (l_cursor); ' ||
                            
                            '    :Y := l_oh; ' || 'end; ',
                            '<REMOTE_DB>',
                            p_db_link_name)
    using out l_remote_oh;
  return l_remote_oh;
end;
