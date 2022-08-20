-- Convert column value with long type to varchar type
create or replace function maint.long_to_varchar_func (v_table_owner in varchar2, v_table_name in varchar2, v_partition_position in number) return varchar2
IS
  v_high_value  varchar2(4000);
BEGIN
  SELECT high_value
  INTO v_high_value
  FROM DBA_TAB_PARTITIONS where table_owner=v_table_owner and table_name=v_table_name and partition_position=v_partition_position;
  RETURN  v_high_value;
END;
