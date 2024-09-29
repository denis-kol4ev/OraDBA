#!/bin/bash
. /home/oracle/.bash_profile >> /dev/null 2>&1 
rec=$(sqlplus -S /nolog << EOF
conn sys / as sysdba
set pages 1001
set linesize 500
set feedback off
set heading off
select case when sys_context('USERENV', 'DATABASE_ROLE')='PHYSICAL STANDBY' then to_number(0) else to_number(1) end from dual;
exit
EOF
)
#echo 'exit'$rec
exit $rec
