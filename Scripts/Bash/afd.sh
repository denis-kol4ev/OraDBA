#!/bin/bash
sleep 1s
AFD_DISK_COUNT=$(ls -1 /dev/oracleafd/disks | wc -l)

if [[ $AFD_DISK_COUNT -eq 0 ]]
  then
    echo "No AFD disks found, try to scan ..."
    export ORACLE_BASE=/tmp
    /opt/oracle/grid/19c/bin/asmcmd afd_scan
    AFD_DISK_COUNT=$(ls -1 /dev/oracleafd/disks | wc -l)
      if [[ $AFD_DISK_COUNT -eq 0 ]]
        then
          echo "scan failed"
        else
          echo "Disk count after scan is $AFD_DISK_COUNT"
      fi
   else
       echo "AFD disk present in system, disk count is $AFD_DISK_COUNT"
       exit 
fi

DBNAME=$(su -c ". oraenv <<<+ASM >> /dev/null && crsctl stat resource -w 'TYPE = ora.database.type' | grep -i name | sed 's/NAME=ora.\(.*\).db/\1/g'" oracle)
echo 'DBNAME=' $DBNAME
DBTARGET=$(su -c ". oraenv <<<+ASM >> /dev/null && crsctl stat resource -w 'TYPE = ora.database.type' | grep -i target | sed 's/TARGET=\(.*\)/\1/g'" oracle)
echo 'DBTARGET=' $DBTARGET
DBSTATE=$(su -c ". oraenv <<<+ASM >> /dev/null && crsctl stat resource -w 'TYPE = ora.database.type' | grep -i state | sed 's/STATE=\([^ ]*\).*/\1/g'" oracle)
echo 'DBSTATE=' $DBSTATE

if [[ $DBTARGET == "ONLINE" && $DBSTATE == "OFFLINE" ]]
  then
    echo "Start database $DBNAME"
    su -m -c ". oraenv <<<+ASM >> /dev/null && srvctl status database -d $DBNAME" oracle

fi