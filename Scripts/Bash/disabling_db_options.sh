#!/bin/bash
source ~/.bash_profile  > /dev/null

# How to Check and Enable/Disable Oracle Binary Options ? (Doc ID 948061.1)	
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

# How to remove the Oracle OLAP Option from a 12c Database (Doc ID 1940098.1)
v_db_role=$((echo "set head off"; echo "select upper(database_role) from v\$database;") | sqlplus -s / as sysdba | sed "/^$/d")

if [[ $v_db_role != "PRIMARY" ]];
    then
        echo -e "For remove of OLAP component connect to PRIMARY database \n"
        exit 
fi

v_cdb=$((echo "set head off"; echo "select upper(cdb) from v\$database;") | sqlplus -s / as sysdba | sed "/^$/d")

if [[ $v_cdb != "NO" ]];
    then
        echo -e "Removal OLAP component from CDB is NOT supported at this time \n"
        exit 
fi

v_olap_db_installed=$((echo "set head off"; echo "select count(*) from dba_registry where comp_name like '%OLAP%';") | sqlplus -s / as sysdba)

v_olap_db_used=$((echo "set head off"; echo "select count(*) from dba_aws where owner !='SYS';") | sqlplus -s / as sysdba)

if [[ $v_olap_db_installed -gt 0 ]]; 
    then
        echo -e "OLAP component installed in DB \n"
            if [[ $v_olap_db_used -eq 0 ]];
                then
                    echo -e "OLAP component not used by users \n"
                    echo -e "Deinstall OLAP component ... \n"
                    cd ~
                    (
                     echo "set term off"; \
                     echo "spool remove_olap.log"; \
                     # Remove OLAP Catalog
                     echo "@?/olap/admin/catnoamd.sql"; \
                     # Remove OLAP API
                     echo "@?/olap/admin/catnoxoq.sql"; \
                     # Deinstall APS - OLAP AW component
                     echo "@?/olap/admin/catnoaps.sql"; \
                     # Recompile invalids
                     echo "@?/rdbms/admin/utlrp.sql"; \
                     echo "spool off"
                     ) | sqlplus -s / as sysdba
                    echo -e "OLAP deinstalled, check remove_olap.log \n"
            else 
                    echo -e "OLAP component used by users \n"
            fi 
else 
        echo -e "OLAP component not found in DB \n"
fi
