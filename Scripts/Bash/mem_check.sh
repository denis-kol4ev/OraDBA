#!/bin/bash
cd /home/oracle
. .bash_profile > /dev/null

echo -e "Check that the memory limit (ulimit -l) for the Oracle user in the OS does not exceed 90% of the host memory\n"

awk \
-v v_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}') \
-v v_lim=$(ulimit -l) \
'BEGIN{
    printf "MemTotal = %d\n", v_mem; 
    printf "Oracle user limit must not exceed %d (90 %% of MemTotal)\n", v_mem * 0.9; 
    if (v_lim > v_mem * 0.9) 
    {printf "WARNING: Actual user limit %d (%4.2f %% of MemTotal)\n\n", v_lim, v_lim / v_mem * 100} 
    else 
    {printf "Actual user limit %d (%4.2f %% of MemTotal)\n\n", v_lim, v_lim / v_mem * 100}}'

echo -e "Check that the total memory allocation for the SGA and PGA components does not exceed 95% of the memory limit set for the user\n"

awk \
-v v_lim=$(ulimit -l) \
-v v_sga=$(echo "select p.VALUE/1024 as sga_max_size_kb from v\$parameter p where p.NAME='sga_max_size';" | sqlplus -s / as sysdba | egrep -o "[0-9]+") \
-v v_pga=$(echo "select p.VALUE/1024 as pga_aggregate_limit_kb from v\$parameter p where p.NAME='pga_aggregate_limit';" | sqlplus -s / as sysdba | egrep -o "[0-9]+") \
'BEGIN {
    if (v_sga + v_pga > v_lim * 0.95) 
    {printf "WARNING: sga_max_size + pga_aggregate_limit exceeded 95%% of ulimit, actual value %4.2f %%\n\n", (v_sga + v_pga) / v_lim * 100} 
    else 
    {printf "Actual sga_max_size + pga_aggregate_limit lower than 95%% of ulimit, actual value %4.2f %%\n\n", (v_sga + v_pga) / v_lim * 100}}'

echo -e "Check that the number of HugePages is correctly selected for the size sga_max_size\n"

awk \
-v v_Hugepagesize=$(grep Hugepagesize /proc/meminfo | awk '{print $2}') \
-v v_HugePages_Total=$(grep HugePages_Total /proc/meminfo | awk '{print $2}') \
-v v_sga_max_size=$(echo "select p.VALUE as sga_max_size from v\$parameter p where p.NAME='sga_max_size';" | sqlplus -s / as sysdba | egrep -o "[0-9]+") \
'function ceil(num1){
   if (num1 == int(num1))
      return num1
   return int(num1)+1};
BEGIN{
    printf "HugePages_Total = %d\n", v_HugePages_Total;
    printf "Hugepagesize_kb = %d\n", v_Hugepagesize;
    printf "sga_max_size_kb = %d\n", v_sga_max_size / 1024;
    v_sga_max_size_mb = v_sga_max_size / 1024 / 1024;
    if (v_sga_max_size_mb > 1024 && v_sga_max_size_mb <= 8192)
        {v_granule_size_mb = 16}
    else if (v_sga_max_size_mb > 8192 && v_sga_max_size_mb <= 16384)
        {v_granule_size_mb = 32}
    else if (v_sga_max_size_mb > 16384 && v_sga_max_size_mb <= 32768)
        {v_granule_size_mb = 64}
    else if (v_sga_max_size_mb > 32768 && v_sga_max_size_mb <= 65536)
        {v_granule_size_mb = 128}
    else if (v_sga_max_size_mb > 65536 && v_sga_max_size_mb <= 131072)
        {v_granule_size_mb = 256}
    else if (v_sga_max_size_mb > 131072)
        {v_granule_size_mb = 512}
    v_hugepages_for_sga = int(ceil(v_sga_max_size_mb / v_granule_size_mb) * v_granule_size_mb * 1024 / v_Hugepagesize + 15)
    if (v_HugePages_Total == 0)
        {printf "HugePages is not configured\n"}
    else if (v_hugepages_for_sga < v_HugePages_Total)
        {printf "WARNING: HugePages_Total probably oversized for current sga_max_size, HugePages_Total recommended %d, HugePages_Total actual %d\n", v_hugepages_for_sga, v_HugePages_Total
        printf "Check vm.nr_hugepages settings in /etc/sysctl.conf\n"}
    else if (v_hugepages_for_sga > v_HugePages_Total)
        {printf "WARNING: HugePages_Total probably insufficient for current sga_max_size, HugePages_Total recommended %d, HugePages_Total actual %d\n", v_hugepages_for_sga, v_HugePages_Total
        printf "Check vm.nr_hugepages settings in /etc/sysctl.conf\n"}
    else
        {printf "HugePages_Total recommended %d, HugePages_Total actual %d\n", v_hugepages_for_sga, v_HugePages_Total}
    }'
