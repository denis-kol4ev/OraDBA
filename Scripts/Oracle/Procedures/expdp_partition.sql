-- -----------------------------------------------------------------------------------
-- Description:
-- The procedure simplifies the process of preparing parameter files for unloading 
-- partitions of table to dumps for long-term storage.
-- When called:
-- 1. creates a file with parameters for the expdp utility in the specified directory
-- 2. print the command to call expdp
-- 3. partition and upload attributes are logged to the expdp_log table.
-- The administrator starts the upload using the formed command,
-- upon successful completion, updates the entry in the expdp_log table,
-- the exported field needs to be updated to Y.
-- -----------------------------------------------------------------------------------

-- Create log table
create table MAINT.EXPDP_LOG
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

-- Grant permissions 
grant select on dba_directories to maint;
grant select on dba_tab_partitions to maint;
grant select on dba_segments to maint;
grant select on dba_lob_partitions to maint;
grant read, write on directory docs to maint;

-- Create procedure
create or replace procedure maint.expdp_partition (l_shema_name in varchar2, 
l_tab_name in varchar2,
l_part_name in varchar2,
l_dir in varchar2
) as
  l_part_row_cnt    number;
  l_part_size_mb    number;
  l_cmd             varchar2(64);
  l_path            varchar2(64);
  l_dump_file       varchar2(64);
  l_log_file        varchar2(64);
  l_par_file        varchar2(64);
  l_expdp_cmd       varchar2(128);
  l_parfile_content clob;
  l_file_handle     utl_file.file_type;
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
  select s.bytes / 1024 / 1024 as size_mb
    from dba_tab_partitions p, dba_segments s
   where p.table_owner = s.owner
     and p.table_name = s.segment_name
     and p.partition_name = s.partition_name
     and p.table_owner = l_shema_name
     and p.table_name = l_tab_name
     and p.partition_name = l_part_name
  union all
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

l_parfile_content := 'directory=' || l_dir || chr(10) || 'tables=' ||
                     l_shema_name || '.' || l_tab_name || ':' ||
                     l_part_name || chr(10) || 'dumpfile=' || l_dump_file ||
                     chr(10) || 'logfile=' || l_log_file || chr(10) ||
                     'flashback_time=systimestamp';

l_file_handle := utl_file.fopen(location  => l_dir,
                                filename  => l_par_file,
                                open_mode => 'w');
utl_file.put_line(file => l_file_handle, buffer => l_parfile_content);
utl_file.fclose(file => l_file_handle);

dbms_output.put_line(rpad('Schema name:', 25, '.') || l_shema_name);
dbms_output.put_line(rpad('Table name:', 25, '.') || l_tab_name);
dbms_output.put_line(rpad('Partition name:', 25, '.') || l_part_name);
dbms_output.put_line(rpad('Partition row count:', 25, '.') ||
                     l_part_row_cnt);
dbms_output.put_line(rpad('Partition size Mb:', 25, '.') || l_part_size_mb);
dbms_output.put_line(rpad('Expdp command:', 25, '.') || l_expdp_cmd);
dbms_output.put_line(rpad('Parfile contents:', 25, '.') || l_par_file);
dbms_output.put_line(l_parfile_content);

insert into MAINT.EXPDP_LOG
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
end expdp_partition;
/

-- Execute example
begin
  maint.expdp_partition(l_shema_name => 'SCOTT',
                        l_tab_name   => 'ARC_DOCS',
                        l_part_name  => 'SYS_P678',
                        l_dir        => 'DOCS');
end;
/
