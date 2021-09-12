#!/bin/bash
source ~/.bash_profile  > /dev/null

function check_olap {
    cd $ORACLE_HOME/rdbms/lib
    if [[ $(ar -tv libknlopt.a | egrep -c "xsyeolap.o") -eq 0 ]]; 
    then
        echo 'OLAP disabled'
    else
        echo 'OLAP enabled'
    fi
}

function check_rat {
    cd $ORACLE_HOME/rdbms/lib
    if [[ $(ar -tv libknlopt.a | egrep -c "kecwr.o") -eq 0 ]]; 
    then
        echo 'RAT disabled'
    else
        echo 'RAT enabled'
    fi
}

function disable_rat {
    $ORACLE_HOME/bin/lsnrctl stop
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<< "shutdown immediate"
    $ORACLE_HOME/bin/chopt disable rat 
    $ORACLE_HOME/bin/lsnrctl start
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<< startup
}

function disable_olap {
    $ORACLE_HOME/bin/lsnrctl stop
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<< "shutdown immediate"
    $ORACLE_HOME/bin/chopt disable olap 
    $ORACLE_HOME/bin/lsnrctl start
    $ORACLE_HOME/bin/sqlplus -s "/ as sysdba" <<< startup
}

check_olap
check_rat 

if [[ $(ar -tv libknlopt.a | egrep -c "xsyeolap.o") -eq 1 ]]; 
    then
        disable_olap
        echo -e "\n"
        check_olap
fi

if [[ $(ar -tv libknlopt.a | egrep -c "kecwr.o") -eq 1 ]]; 
    then
        disable_rat
        echo -e "\n"
        check_rat
fi
