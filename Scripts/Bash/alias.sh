#!/bin/bash
IP=10.10.10.222
MASK=/24
DEV=eth1
LISTENER=listener_vip
ORACLE_HOME=/opt/oracle/grid/19.3

case $1 in
'start')
    ping -c 1 ${IP} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
            echo "IP ${IP} already used"
            exit 1
    fi
    sudo ip addr add ${IP}${MASK} dev ${DEV}
    ${ORACLE_HOME}/bin/srvctl start listener -l ${LISTENER}
    ping -c 1 ${IP} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Alias UP"
        exit 0
    fi
   RET=$?
    ;;
'stop')
    ping -c 1 ${IP} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
            echo "IP ${IP} not used"
            exit 1
    fi
    ${ORACLE_HOME}/bin/srvctl stop listener -l ${LISTENER}
    sudo ip addr del ${IP}${MASK} dev ${DEV}
    ping -c 1 ${IP} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Alias OFF"
        exit 0
    fi
   RET=$?
    ;;
'clean')
   ping -c 1 ${IP} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
            echo "IP ${IP} not used"
            exit 1
    fi
    sudo ip addr del ${IP}${MASK} dev ${DEV}
    ping -c 1 ${IP} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Alias OFF"
        exit 0
    fi
   RET=$?
    ;;
'check')
   ip addr | grep $IP > /dev/null 2>&1
   RET=$?
    ;;
*)
   echo "Usage: $0 { start | stop | clean | check }"
   RET=0
    ;;
esac
# 0: success; 1 : error
if [ $RET -eq 0 ]; then
exit 0
else
exit 1
fi
