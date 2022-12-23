whenever sqlerror exit failure
set heading off 
set pagesize 0
set feedback off;
set termout off;
spool /home/oracle/hosts_for_puppet/hosts_for_puppet.csv

select lower(t.host_name) host_name
  from sysman.mgmt$target@oem t
 where t.target_type = 'host'
union all
select lower(t.host_name) host_name
  from sysman.mgmt$target@oemtst t
 where t.target_type = 'host'
 order by 1;

spool off
