#!/bin/bash
# matching disk devices to ASM labels and scsi numbers

printf "%s\t%s\t%s\n" "Disk" "ASM Label" "[H:B:T:L]"
for i in $(lsblk -f | grep oracleasm | awk '{print $1";"$3}' | sort); 
do 
v_dev=$(echo $i | awk -F ";" '{print $1}');
v_asm=$(echo $i | awk -F ";" '{print $2}');
v_scsi=$(lsscsi | grep $v_dev | awk '{print $1}');
printf "%s\t%-10s\t%s\n" $v_dev $v_asm $v_scsi
done
