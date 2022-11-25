grant create procedure to maint;
grant select on dba_tablespaces to maint;
grant select on v_$parameter to maint;
grant select on v_$database to maint;
grant select on dba_data_files to maint;
grant select on dba_free_space to maint;

create or replace procedure maint.add_data_files_prc (v_tbs in varchar2, v_alert_pct number default 85, v_low_pct number default 80) as
/*
  NAME
    add_data_files_prc - добавление файлов в табличное пространство (ТП)
  
  DESCRIPTION
   Процедура оценивает процент использования ТП и выводит рекомендации 
   по количеству файлов которые необходимо добавить.
   Проверки:
            a.Цифры могут быть не только в конце имени файла, например user01_data_137.dbf
            b.Цифры могут быть в пути до имени файла, например /u01/oradata/users01.dbf
            c.Файл может не содержать цифр в имени, тогда последующий файл будет иметь имя <file_name>02.dbf
            d.Файл с префиксом 0 будет увеличен на единицу с сохранением префикса, если файлов в ТП менее 10 
              Пример 
                users01.dbf следующий файл users01.dbf
                users09.dbf следующий файл users10.dbf
            e.Файл с префиксом 00 будет увеличен на единицу с сохранением префикса, если файлов в ТП менее 10.
              Для файлов с номерами от 10 до 99 префикс будет уменьшен до 0
              Пример 
                users001.dbf следующий файл users002.dbf
                users009.dbf следующий файл users010.dbf
                users099.dbf следующий файл users100.dbf
            f.ТП не является bigfile
            g.В БД не используются Oracle Managed Files (OMF)
            h.Подддержка ТП с размером блока 8192 и 16384
            i.БД не является physical standby
            j.Наличие в ТП файлов с отключенным автораширением
            k.При добавлении в ТП файлов их количество не превысит 1023, 
              ORA-01686: max # files (1023) reached for the tablespace
  
  NOTES
   Входные параметры:
    * v_tbs       имя ТП в верхнем регистре
    * v_alert_pct % заполнения ТП, с учетом авто расширения, при котором срабатывает алерт (значение по умолчанию 85)
    * v_low_pct   % до которого необходимо снизить заполнение ТП (значение по умолчанию 80)
  
  MODIFIED   (MM/DD/YY)
  dkolchev    13/11/22 - создание процедуры
*/
  v_file_cnt             number;
  v_block_size           number;
  v_file_add             number;
  v_first_file_name       varchar2(256);
  v_first_file_name_short varchar2(256);
  v_first_file_digit      varchar2(256);
  v_last_file_name       varchar2(256);
  v_last_file_name_short varchar2(256);
  v_last_file_digit      varchar2(256);
  v_next_file_name       varchar2(256);
  v_next_file_cmd        varchar2(512);
  v_big_file             varchar2(4);
  v_omf                  varchar2(64);
  v_db_role              varchar2(64);
  v_ts_used_pct          number;
  v_ts_size_gb           number;
  v_ts_used_gb           number;
  v_ts_free_gb           number;
  v_ts_max_size_gb       number;
  v_ts_max_used_pct      number;
  v_ts_new_max_size_gb   number;
  v_ts_new_max_used_pct  number;
  v_no_autoext           number;
  v_ts_diff_gb           number;
  v_ts_max_files         number;
  v_ts_max_files_limit   number := 1023;
  v_zero_prefix number;

  procedure print_prc(p_label in varchar2, p_msg in varchar2) is
  begin
    dbms_output.put_line(rpad(p_label, 45, '.') || p_msg);
  end;

begin
  select t.block_size
    into v_block_size
    from dba_tablespaces t
   where t.tablespace_name = v_tbs;
  if v_block_size not in (8192, 16384) then
    raise_application_error(-20001,
                            'Tablespace with block size (in bytes) ' ||
                            v_block_size ||
                            ' are not supported for this procedure');
  end if;

  select bigfile
    into v_big_file
    from dba_tablespaces
   where tablespace_name = upper(v_tbs);
  if v_big_file = 'YES' then
    raise_application_error(-20001,
                            'Tablespace ' || v_tbs ||
                            ' is bigfile and this type of tablespace are not supported for this procedure');
  end if;

  select value
    into v_omf
    from v$parameter p
   where p.NAME = 'db_create_file_dest';
  if v_omf is not null then
    raise_application_error(-20001,
                            'Parameter db_create_file_dest=' || v_omf ||
                            ', databases with OMF files are not supported for this procedure');
  end if;

  select database_role into v_db_role from v$database;
  if v_db_role = 'PHYSICAL STANDBY' then
    raise_application_error(-20001,
                            'Database role ' || v_db_role ||
                            ' are not supported for this procedure');
  end if;

  with ts_total_space as
   (select TableSpace_name,
           sum(bytes) as bytes,
           sum(blocks) as blocks,
           sum(decode(autoextensible, 'YES', maxbytes, bytes)) maxbytes
      from dba_data_files
     group by TableSpace_name),
  ts_free_space as
   (select ddf.TableSpace_name,
           nvl(sum(dfs.bytes), 0) as bytes,
           nvl(sum(dfs.blocks), 0) as blocks
      from dba_data_files ddf, dba_free_space dfs
     where ddf.file_id = dfs.file_id(+)
     group by ddf.TableSpace_name)
  select round((ttsp.bytes - tfs.bytes) / ttsp.bytes * 100, 1) as "TSUsedPrct",
         round(ttsp.bytes / 1024 / 1024 / 1024, 1) as "TSSizeGb",
         round((ttsp.bytes - tfs.bytes) / 1024 / 1024 / 1024, 1) as "TSUsedGb",
         round(tfs.bytes / 1024 / 1024 / 1024, 1) as "TSFreeGb",
         round(ttsp.maxbytes / 1024 / 1024 / 1024, 1) as "TSMaxSizeGb",
         round((ttsp.bytes - tfs.bytes) / ttsp.maxbytes * 100, 1) as "TSMaxUsedPrct"
    into v_ts_used_pct,
         v_ts_size_gb,
         v_ts_used_gb,
         v_ts_free_gb,
         v_ts_max_size_gb,
         v_ts_max_used_pct
    from dba_TableSpaces dt, ts_total_space ttsp, ts_free_space tfs
   where dt.TableSpace_name = ttsp.TableSpace_name(+)
     and dt.TableSpace_name = tfs.TableSpace_name(+)
     and dt.TableSpace_name = v_tbs;

  select count(*)
    into v_file_cnt
    from dba_data_files f
   where f.tablespace_name = v_tbs;
  
  select file_name as first_file,
         substr(file_name, instr(file_name, '/', -1) + 1) as name_short,
         nvl(to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')), 0) as name_digit
    into v_first_file_name, v_first_file_name_short, v_first_file_digit
    from dba_data_files
   where tablespace_name = upper(v_tbs)
     and exists (select 1
            from dba_tablespaces
           where bigfile = 'NO'
             and tablespace_name = upper(v_tbs))
     and exists (select 1
            from v$parameter p
           where p.NAME = 'db_create_file_dest'
             and value is null)
   order by to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+'))
   asc nulls last fetch first row only;
   
   v_zero_prefix := regexp_count(regexp_substr(regexp_substr(lower(v_first_file_name), '\d+\.dbf'), '0+'), '0');
   
  select file_name as last_file,
         substr(file_name, instr(file_name, '/', -1) + 1) as name_short,
         nvl(to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')), 0) as name_digit
    into v_last_file_name, v_last_file_name_short, v_last_file_digit
    from dba_data_files
   where tablespace_name = upper(v_tbs)
     and exists (select 1
            from dba_tablespaces
           where bigfile = 'NO'
             and tablespace_name = upper(v_tbs))
     and exists (select 1
            from v$parameter p
           where p.NAME = 'db_create_file_dest'
             and value is null)
   order by to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+'))
   desc nulls last fetch first row only;

  if v_ts_max_used_pct < v_alert_pct then
    print_prc('Tablespace name', v_tbs);
    print_prc('Tablespace size Gb', v_ts_size_gb);
    print_prc('Tablespace used Gb', v_ts_used_gb);
    print_prc('Tablespace free Gb', v_ts_free_gb);
    print_prc('Tablespace used %', v_ts_used_pct);
    print_prc('Tablespace max size Gb', v_ts_max_size_gb);
    print_prc('Tablespace max used %', v_ts_max_used_pct);
    print_prc('Tablespace files count', v_file_cnt);
    print_prc('Tablespace block size (in bytes)', v_block_size);
    print_prc('Tablespace last file by name (full)', v_last_file_name);
    print_prc('Tablespace last file by name (short)',
              v_last_file_name_short);
    print_prc('Tablespace last file digit', v_last_file_digit || chr(10));
    dbms_output.put_line('Tablespace ' || v_tbs || ' max used percent is ' ||
                         v_ts_max_used_pct ||
                         ' and it''s lower than alert percent ' ||
                         v_alert_pct || '.' || chr(10) ||
                         'No data files need to be added.');
  else
    v_ts_new_max_size_gb := case
                              when v_ts_max_used_pct >= v_alert_pct then
                               case
                                 when v_block_size = 8192 then
                                  round(ceil(v_ts_used_gb / v_low_pct * 100 /
                                             (34359721984 / 1024 / 1024 / 1024)) *
                                        (34359721984 / 1024 / 1024 / 1024), 1)
                                 when v_block_size = 16384 then
                                  round(ceil(v_ts_used_gb / v_low_pct * 100 /
                                             (68719443968 / 1024 / 1024 / 1024)) *
                                        (68719443968 / 1024 / 1024 / 1024),1)
                               end
                              else
                               v_ts_max_size_gb
                            end;
  
    v_ts_new_max_used_pct := round(v_ts_used_gb / v_ts_new_max_size_gb * 100, 1);
  
    v_ts_diff_gb := round(v_ts_new_max_size_gb - v_ts_max_size_gb, 1);
  
    v_file_add := case
                    when v_block_size = 8192 then
                     ceil(trunc(v_ts_diff_gb * 1024 * 1024 * 1024 / 34359721984, 1))
                    when v_block_size = 16384 then
                     ceil(trunc(v_ts_diff_gb * 1024 * 1024 * 1024 / 68719443968, 1))
                  end;
  
    print_prc('Tablespace name', v_tbs);
    print_prc('Tablespace size Gb', v_ts_size_gb);
    print_prc('Tablespace used Gb', v_ts_used_gb);
    print_prc('Tablespace free Gb', v_ts_free_gb);
    print_prc('Tablespace used %', v_ts_used_pct);
    print_prc('Tablespace max size Gb', v_ts_max_size_gb);
    print_prc('Tablespace max used %', v_ts_max_used_pct);
    print_prc('Tablespace files count', v_file_cnt);
    print_prc('Tablespace block size (in bytes)', v_block_size);
    print_prc('Tablespace last file by name (full)', v_last_file_name);
    print_prc('Tablespace last file by name (short)', v_last_file_name_short);
    print_prc('Tablespace last file digit', v_last_file_digit || chr(10));
    print_prc('Recommended size to add Gb', v_ts_diff_gb);
    print_prc('Recommended number of files to add', v_file_add);
    print_prc('New tablespace used %', v_ts_new_max_used_pct);
    print_prc('New tablespace max size Gb', v_ts_new_max_size_gb || chr(10));

    select count(*)
      into v_no_autoext
      from dba_data_files f
     where f.tablespace_name = v_tbs
       and f.autoextensible != 'YES';
    if v_no_autoext > 0 then
      dbms_output.put_line('Tablespace ' || v_tbs || ' has files with disabled autoextend,' || chr(10) ||
                           'it''s make sense to check that files and enable autoextend rather than add new datafiles to tablespace.' || chr(10));
    end if;
  
    v_ts_max_files := v_file_cnt + v_file_add;
    if v_ts_max_files > v_ts_max_files_limit then
      dbms_output.put_line('Tablespace ' || v_tbs || ' files limit is reached,' || chr(10) ||
                           'if you try to add more then ' || v_ts_max_files_limit ||
                           ' files to tablespace you get ORA-01686 (Doc ID 2706122.1)' ||
                           chr(10));
    end if;
  
    for i in 1 .. v_file_add loop
      v_ts_max_files := v_file_cnt + i;
      continue when v_ts_max_files > v_ts_max_files_limit;
      
      v_next_file_name := case
                            when regexp_count(regexp_substr(lower(v_last_file_name), '\d+\.dbf'),'\d+') > 0
                             then
                               case
                                 when v_zero_prefix = 1 and v_last_file_digit < 9
                                   then
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            '0' || to_char(regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1),
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i')
                                  when v_zero_prefix = 2 and v_last_file_digit < 9
                                   then
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            '00' || to_char(regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1),
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i')
                                   when v_zero_prefix = 2 and v_last_file_digit < 99
                                    then
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            '0' || to_char(regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1),
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i')
                                   else 
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1,
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i')
                               end
                            else
                             regexp_replace(v_last_file_name, '\.dbf', '02.dbf', 1, 1, 'i')
                      end;

      v_next_file_cmd := case
                            when regexp_count(regexp_substr(lower(v_last_file_name), '\d+\.dbf'),'\d+') > 0
                             then
                               case
                                 when v_zero_prefix = 1 and v_last_file_digit < 9
                                   then
                                        'alter tablespace ' || upper(v_tbs) || ' add datafile ''' ||
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            '0' || to_char(regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1),
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i') ||
                                            ''' size 1024m autoextend on next 256m maxsize unlimited;'
                                  when v_zero_prefix = 2 and v_last_file_digit < 9
                                   then
                                        'alter tablespace ' || upper(v_tbs) || ' add datafile ''' ||
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            '00' || to_char(regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1),
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i')  ||
                                            ''' size 1024m autoextend on next 256m maxsize unlimited;'
                                   when v_zero_prefix = 2 and v_last_file_digit < 99
                                    then
                                        'alter tablespace ' || upper(v_tbs) || ' add datafile ''' ||
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            '0' || to_char(regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1),
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i') ||
                                            ''' size 1024m autoextend on next 256m maxsize unlimited;'
                                   else 
                                        'alter tablespace ' || upper(v_tbs) || ' add datafile ''' ||
                                        regexp_replace(v_last_file_name,
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+'),
                                            regexp_substr(regexp_substr(lower(v_last_file_name),
                                                                                  '\d+\.dbf'), '\d+') + 1,
                                            regexp_instr(lower(v_last_file_name),'\d+\.dbf'), 1, 'i') ||
                                            ''' size 1024m autoextend on next 256m maxsize unlimited;'
                               end
                            else
                             'alter tablespace ' || upper(v_tbs) || ' add datafile ''' ||
                             regexp_replace(v_last_file_name, '\.dbf', '02.dbf', 1, 1, 'i') ||
                             ''' size 1024m autoextend on next 256m maxsize unlimited;'
                      end;
      dbms_output.put_line(v_next_file_cmd);
      v_last_file_name := v_next_file_name;
    end loop;
  end if;
end add_data_files_prc;
/
