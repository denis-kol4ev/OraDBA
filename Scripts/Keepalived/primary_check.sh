#!/bin/bash
cd /home/oracle/maint/keepalived
echo 'ORACLE_BASE='$(awk '/^(ORACLE_BASE=.+|export ORACLE_BASE=.+)/ {sub("(ORACLE_BASE=|export ORACLE_BASE=)", "", $0); print $0}' /home/oracle/.bash_profile) > ora_env_prm
echo 'ORACLE_HOME='$(awk '/^(ORACLE_HOME=.+|export ORACLE_HOME=.+)/ {sub("(ORACLE_HOME=|export ORACLE_HOME=)", "", $0); print $0}' /home/oracle/.bash_profile) >> ora_env_prm
echo 'ORACLE_SID='$(awk '/^(ORACLE_SID=.+|export ORACLE_SID=.+)/ {sub("(ORACLE_SID=|export ORACLE_SID=)", "", $0); print $0}' /home/oracle/.bash_profile) >> ora_env_prm
echo 'PATH=$PATH:$ORACLE_HOME/bin' >> ora_env_prm
echo 'export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH' >> ora_env_prm
source ora_env_prm

rec=$(sqlplus -S /nolog << EOF
conn sys / as sysdba
set pages 1001
set linesize 500
set feedback off
set heading off
select case when sys_context('USERENV', 'DATABASE_ROLE')='PRIMARY' then to_number(0) else to_number(1) end from dual;
exit
EOF
)
exit $rec