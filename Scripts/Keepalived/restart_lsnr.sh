#!/bin/bash
source /home/oracle/.bash_profile >> /dev/null 2>&1

MAINT_DIR=/home/oracle/maint
LOGFILE=$MAINT_DIR/restart_lsnr.log

{
echo
echo "=========================================================="
echo " $(date) Step 1: Stop Listener "              
echo "=========================================================="
lsnrctl stop
echo
echo "=========================================================="
echo " $(date) Step 2: Start Listener "              
echo "=========================================================="
lsnrctl start
echo
echo "=========================================================="
echo " $(date) Step 3: Register Database "              
echo "=========================================================="
sqlplus "/as sysdba" <<EOF
alter system register;
exit
EOF
} >> $LOGFILE 2>&1