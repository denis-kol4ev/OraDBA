whenever sqlerror exit sql.sqlcode
set timing on
set echo on
set serveroutput on


set term off
column c new_value vHostDate
select 'Host: ' || sys_context('userenv', 'server_host') || ' Database: ' || sys_context('userenv', 'db_unique_name') || ' Date: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') as c from dual;
set term on
spool db_run_sql.log append
prompt &vHostDate

alter table SCOTT.DEPARTMENTS move online parallel 8 tablespace SCOTT_TS;

spool off
set term off
column c new_value vHostDate
select 'Host: ' || sys_context('userenv', 'server_host') || ' Database: ' || sys_context('userenv', 'db_unique_name') || ' Date: ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') as c from dual;
set term on
spool db_run_sql.log append
prompt &vHostDate
exit
