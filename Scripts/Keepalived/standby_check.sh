#!/bin/bash
cd /home/oracle/maint/keepalived
echo 'ORACLE_BASE='$(awk '/^(ORACLE_BASE=.+|export ORACLE_BASE=.+)/ {sub("(ORACLE_BASE=|export ORACLE_BASE=)", "", $0); print $0}' /home/oracle/.bash_profile) > ora_env_stb
echo 'ORACLE_HOME='$(awk '/^(ORACLE_HOME=.+|export ORACLE_HOME=.+)/ {sub("(ORACLE_HOME=|export ORACLE_HOME=)", "", $0); print $0}' /home/oracle/.bash_profile) >> ora_env_stb
echo 'ORACLE_SID='$(awk '/^(ORACLE_SID=.+|export ORACLE_SID=.+)/ {sub("(ORACLE_SID=|export ORACLE_SID=)", "", $0); print $0}' /home/oracle/.bash_profile) >> ora_env_stb
echo 'PATH=$PATH:$ORACLE_HOME/bin' >> ora_env_stb
echo 'export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH' >> ora_env_stb
source ora_env_stb

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