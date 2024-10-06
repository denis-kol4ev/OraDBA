#!/bin/bash

MAINT_DIR=/home/oracle/maint/keepalived
LOGFILE=$MAINT_DIR/restart_lsnr.log

{
echo
echo "=========================================================="
echo " $(date) Step 1: Stop Listener "              
echo "=========================================================="
srvctl stop listener
#lsnrctl stop
echo
echo "=========================================================="
echo " $(date) Step 2: Start Listener "              
echo "=========================================================="
srvctl start listener
#lsnrctl start
echo
echo "=========================================================="
echo " $(date) Step 3: Register Database "              
echo "=========================================================="
sqlplus "/as sysdba" <<EOF
alter system register;
exit
EOF
} >> $LOGFILE 2>&1