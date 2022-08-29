-- Create table
create table ARC_EDI.EXPDP_LOG
(
  schema_name         VARCHAR2(16),
  table_name          VARCHAR2(32),
  partition_name      VARCHAR2(16),
  partition_row_count NUMBER,
  partition_size_mb   NUMBER,
  dir_name            VARCHAR2(16),
  dir_path            VARCHAR2(64),
  expdp_dump_file     VARCHAR2(64),
  expdp_log_file      VARCHAR2(64),
  expdp_par_file      VARCHAR2(64),
  par_file_contents   CLOB,
  exported            VARCHAR2(1) default 'N'
);

declare
  l_shema_name      varchar2(16) := 'ARC_EDI';
  l_tab_name        varchar2(32) := 'DOCS';
  l_part_name       varchar2(16) := 'SYS_P1981';
  l_part_row_cnt    number;
  l_part_size_mb    number;
  l_cmd             varchar2(64);
  l_dir             varchar2(16) := 'DOCS';
  l_path            varchar2(64);
  l_dump_file       varchar2(64);
  l_log_file        varchar2(64);
  l_par_file        varchar2(64);
  l_expdp_cmd       varchar2(128);
  l_parfile_content clob;
begin
  select 'select count(*) FROM ' || table_owner || '.' || table_name ||
         ' partition(' || partition_name || ')'
    into l_cmd
    from dba_tab_partitions p
   WHERE table_owner = l_shema_name
     AND table_name = l_tab_name
     and partition_name = l_part_name;
  execute immediate l_cmd
    into l_part_row_cnt;

  with t as
   (
    -- Partition size Mb
    select s.bytes / 1024 / 1024 as size_mb
      from dba_tab_partitions p, dba_segments s
     where p.table_owner = s.owner
       and p.table_name = s.segment_name
       and p.partition_name = s.partition_name
       and p.table_owner = l_shema_name
       and p.table_name = l_tab_name
       and p.partition_name = l_part_name
    union all
    -- Partition lob's size Mb
    select s.bytes / 1024 / 1024 as size_mb
      from dba_tab_partitions p, dba_lob_partitions l, dba_segments s
     where p.table_owner = l.table_owner
       and p.table_name = l.table_name
       and p.partition_name = l.partition_name
       and l.table_owner = s.owner
       and l.lob_name = s.segment_name
       and l.lob_partition_name = s.partition_name
       and p.table_owner = l_shema_name
       and p.table_name = l_tab_name
       and p.partition_name = l_part_name)
  select sum(size_mb) into l_part_size_mb from t;

  select d.DIRECTORY_PATH || '/'
    into l_path
    from dba_directories d
   where d.DIRECTORY_NAME = l_dir
     and d.OWNER = user;

  select lower(p.table_owner || '-' || p.table_name || '-' ||
               regexp_substr(maint.long_to_varchar_func(p.table_owner,
                                                        p.table_name,
                                                        p.partition_position),
                             '\d{4}-\d{2}-\d{2}') || '.dmp') as dump_file_name,
         lower(p.table_owner || '-' || p.table_name || '-' ||
               regexp_substr(maint.long_to_varchar_func(p.table_owner,
                                                        p.table_name,
                                                        p.partition_position),
                             '\d{4}-\d{2}-\d{2}') || '.log') as log_file_name,
         lower(p.table_owner || '-' || p.table_name || '-' ||
               regexp_substr(maint.long_to_varchar_func(p.table_owner,
                                                        p.table_name,
                                                        p.partition_position),
                             '\d{4}-\d{2}-\d{2}') || '-param.txt') as param_file_name
    into l_dump_file, l_log_file, l_par_file
    from dba_tab_partitions p
   where p.table_owner = l_shema_name
     and p.table_name = l_tab_name
     and p.partition_name = l_part_name;

  l_expdp_cmd := 'expdp system parfile=' || l_path || l_par_file;

  l_parfile_content := 'directory=' || l_dir || chr(13) || 'tables=' ||
                       l_shema_name || '.' || l_tab_name || ':' ||
                       l_part_name || chr(13) || 'dumpfile=' || l_dump_file ||
                       chr(13) || 'logfile=' || l_log_file || chr(13) ||
                       'flashback_time=systimestamp';

  dbms_output.put_line(rpad('Schema name:', 25, '.') || l_shema_name);
  dbms_output.put_line(rpad('Table name:', 25, '.') || l_tab_name);
  dbms_output.put_line(rpad('Partition name:', 25, '.') || l_part_name);
  dbms_output.put_line(rpad('Partition row count:', 25, '.') ||
                       l_part_row_cnt);
  dbms_output.put_line(rpad('Partition size Mb:', 25, '.') ||
                       l_part_size_mb);
  dbms_output.put_line(rpad('Expdp command:', 25, '.') || l_expdp_cmd);
  dbms_output.put_line(rpad('Parfile contents:', 25, '.') || l_par_file);
  dbms_output.put_line(l_parfile_content);

  insert into ARC_EDI.EXPDP_LOG
    (SCHEMA_NAME,
     TABLE_NAME,
     PARTITION_NAME,
     PARTITION_ROW_COUNT,
     PARTITION_SIZE_MB,
     DIR_NAME,
     DIR_PATH,
     EXPDP_DUMP_FILE,
     EXPDP_LOG_FILE,
     EXPDP_PAR_FILE,
     PAR_FILE_CONTENTS)
  values
    (l_shema_name,
     l_tab_name,
     l_part_name,
     l_part_row_cnt,
     l_part_size_mb,
     l_dir,
     l_path,
     l_dump_file,
     l_log_file,
     l_par_file,
     l_parfile_content);
  commit;
end;
/
