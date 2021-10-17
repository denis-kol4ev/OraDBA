create or replace function sys.remote_sysdate(p_db_link_name in varchar2)
  return date as
  l_remote_sysdate date;
begin
  execute immediate replace('declare ' || 
                            'l_cursor    int; ' ||
                            'l_status    int; ' ||
                            'l_sysdate      date; ' || 
                            'begin ' ||
                            
                            'l_cursor := dbms_sql.open_cursor@<REMOTE_DB>;' ||
                            
                            'dbms_sql.parse@<REMOTE_DB>(l_cursor, ''begin :x := sysdate; end;'', dbms_sql.native);' ||
                            
                            'dbms_sql.bind_variable@<REMOTE_DB>(l_cursor, '':x'', l_sysdate);' ||
                            
                            'l_status := dbms_sql.execute@<REMOTE_DB>(l_cursor);' ||
                            
                            'dbms_sql.variable_value@<REMOTE_DB>(l_cursor, '':x'', l_sysdate);' ||
                            
                            'dbms_sql.close_cursor@<REMOTE_DB>(l_cursor);' ||
                            
                            ':Y := l_sysdate;' || 
                            
                            ' end;',
                            '<REMOTE_DB>',
                            p_db_link_name)
    using out l_remote_sysdate;
  return l_remote_sysdate;
end;
