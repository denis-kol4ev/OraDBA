#!/bin/bash
cd /home/oracle
. .bash_profile > /dev/null

LOG_DIR=/home/oracle/maint/logs
LOG_FILE=$LOG_DIR/hosts_for_puppet_$(date +%F-%H-%M.log)
{
echo "==========Beginning of Script=========="
echo "Date        : `date`"
echo "HOST        : `hostname`"
echo "LOG  : $LOG_FILE"
echo
cd /home/oracle/maint
sqlplus /nolog <<EOF
CONNECT <usr>/<pass>@//<host>/<service>
@hosts_for_puppet.sql
exit
EOF
EXPORT_STATUS=$?
} >> $LOG_FILE 2>&1
echo $EXPORT_STATUS

{
cd /home/oracle/hosts_for_puppet
git add hosts_for_puppet.csv
git commit -m "New hosts uploaded"
git push origin main
GIT_STATUS=$?
} >> $LOG_FILE 2>&1
echo $GIT_STATUS
