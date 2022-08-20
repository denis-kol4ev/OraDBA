 -- Count rows by partition with query
select 'select ''' || p.partition_name ||
       ''', count(*) FROM <SCHEMA>.<TABLE_NAME> partition(' || p.partition_name || ')  union all'
  from dba_tab_partitions p
 WHERE table_owner = '<SCHEMA>'
   AND table_name = '<TABLE_NAME>'
 ORDER BY partition_position ASC;
 
 -- Count rows by partition with pipelined function
create type maint.t_part_row as object (tab_owner varchar2(40), tab_name varchar2(40),part_position number, part_name varchar2(40), high_value varchar2(40), cnt number, pct number);
create type maint.t_part_tab as table of t_part_row;
create or replace function maint.long_to_varchar_func (v_table_owner in varchar2, v_table_name in varchar2, v_partition_position in number) return varchar2
IS
  v_high_value  varchar2(4000);
BEGIN
  SELECT high_value
  INTO v_high_value
  FROM DBA_TAB_PARTITIONS where table_owner=v_table_owner and table_name=v_table_name and partition_position=v_partition_position;
  RETURN  v_high_value;
END;

create or replace function maint.f_check_part_count (v_owner varchar2, v_tab varchar2) return t_part_tab pipelined as
  v_part_cnt   number;
  v_tab_cnt   number;
begin
 execute immediate 'select /*+ parallel*/ count(*) from ' || v_owner || '.' ||v_tab into v_tab_cnt;
 for i in (select p.table_owner,
                   p.table_name,
                   p.partition_position,
                   p.partition_name,
                   regexp_substr(maint.long_to_varchar_func(p.table_owner,
                                  p.table_name,
                                  p.partition_position), '\d{4}-\d{2}-\d{2}') as high_value
              from dba_tab_partitions p
             where p.table_owner = v_owner
               and p.table_name = v_tab
             order by partition_position) loop
    execute immediate 'select count(*) from ' || i.table_owner || '.' ||
                      i.table_name || ' partition(' || i.partition_name || ')'
      into v_part_cnt;
    pipe row( t_part_row(i.table_owner,i.table_name,i.partition_position,i.partition_name,v_part_cnt,round((v_part_cnt/greatest(1,v_tab_cnt))*100)));
  end loop;
  return;
end f_check_part_count;

--Test
select * from TABLE(maint.f_check_part_count('<SCHEMA>','<TABLE_NAME>'));
