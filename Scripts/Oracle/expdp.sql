-- Data Pump export table partition via DBMS_DATAPUMP

-- Drop table
drop table system.t1;
-- Create a partitioned table 
create table system.t1
(
  c_id              NUMBER primary key,
  c_date            date,
  c_message        varchar2(100)
)
PARTITION BY RANGE (c_date)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
   PARTITION part_01 values LESS THAN (TO_DATE('01-01-2020','DD-MM-YYYY'))
);
/
-- Populate the table
declare 
 l_date date := TO_DATE('01-01-2020 00:00:00','DD-MM-YYYY hh24:mi:ss');
begin
  for i in 1..10000 loop
    insert into system.t1 values (i, l_date, dbms_random.string(opt => 'L', len => 20));
    l_date := l_date +  numtodsinterval(10,'MINUTE');
  end loop;
  commit;
end;
/
-- Verify the table partitions
select table_owner, table_name, partition_name, tp.high_value
  from dba_tab_partitions tp
 where table_owner = 'SYSTEM'
   and table_name = 'T1'
 order by table_owner, table_name, partition_position;

truncate table system.t1;
select count(*) from system.t1 partition (SYS_P3026);
