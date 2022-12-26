#!/bin/bash
cd /home/oracle
. .bash_profile > /dev/null

SCRIPT_NAME=$(basename "$0")
ADDRESS=$(hostname -s)
ADMIN_MAIL1=admin1@company.ru
ADMIN_MAIL2=admin2@company.ru
LOG_DIR=/home/oracle/maint/logs
LOG_FILE=$LOG_DIR/hosts_for_puppet_$(date +%F-%H-%M.log)

check_error_f () {
  if [[ $1 -ne 0 ]]
    then RETURN_STATUS='FAILED'
         echo "Step $2 status: "$RETURN_STATUS >> $LOG_FILE
         echo "***** End of script *****" >> $LOG_FILE
         (
         echo "Script: $SCRIPT_NAME" 
         echo "Step: $2" 
         echo "Status: $RETURN_STATUS"
         echo "Check attachment for details"
         ) | mailx -S smtp=relay.company.ru -r $ADDRESS@company.ru -a $LOG_FILE -s "$SCRIPT_NAME status: $RETURN_STATUS" $ADMIN_MAIL1 $ADMIN_MAIL2
         exit
    else RETURN_STATUS='SUCCEED'
         echo "Step $2 status: "$RETURN_STATUS >> $LOG_FILE
  fi
}

{
echo "***** Start of script *****"
echo "Date        : `date`"
echo "HOST        : `hostname`"
echo "LOG  : $LOG_FILE"
} >> $LOG_FILE 2>&1

STEP_NAME="Export form DB"

{
echo
echo "=========================================================="
echo " $(date) Step 1: $STEP_NAME"                   
echo "=========================================================="
echo 
} >> $LOG_FILE 2>&1

{
cd /home/oracle/maint
sqlplus -s /nolog <<EOF
@hosts_for_puppet.sql
exit
EOF
STEP_STATUS=$?
} >> $LOG_FILE 2>&1

echo "STEP_NAME="$STEP_NAME
echo "STEP_STATUS="$STEP_STATUS

check_error_f "$STEP_STATUS" "$STEP_NAME"

STEP_NAME="Push to Git"

{
echo
echo "=========================================================="
echo " $(date) Step 2: $STEP_NAME"                   
echo "=========================================================="
echo 
} >> $LOG_FILE 2>&1

{
cd /home/oracle/hosts_for_puppet
git add hosts_for_puppet.csv
git commit -m "New hosts uploaded" 
git push origin main
STEP_STATUS=$?
} >> $LOG_FILE 2>&1

echo "STEP_NAME="$STEP_NAME
echo "STEP_STATUS="$STEP_STATUS

check_error_f "$STEP_STATUS" "$STEP_NAME"

echo "***** End of script *****" >> $LOG_FILE
