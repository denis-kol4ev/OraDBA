#!/bin/bash
display_usage() { 
    echo -e "На сколько нужно расширить ФС чтобы сбросить алерт"
    echo -e "Использование: $0 [Filesystem | MountPoint] ..." 
    echo -e "Пример: $0 /appdata/data /backup"
	} 

if [[ ( $@ == "--help") ||  $@ == "-h" ]] 
then 
	display_usage
	exit 0
fi 

if [[ $# -lt 1 ]] 
then 
	display_usage
	exit 1
fi 

while [[ "$#" -gt 0 ]]
do
	FS=$1
	if df ${FS} > /dev/null 2>&1
	then
		df -Pm ${FS} | \
		awk 'function ceil(v){return(v==int(v)) ? v : int(v)+1}
		BEGIN {v_alert=80; v_alert_close=75; v_disk_multiple=50} 
		{if (NR>1 && $5 >= v_alert) 
			{v_fs_new = $2 * ($5 / 100)  / (v_alert_close / 100); 
			print "Текущий размер файловой системы", $6, ceil($2/1024) " (Гб), утилизация", $5, 
			"\nНеобходимо расширить", $6, "на", ceil((v_fs_new - $2)/1024/v_disk_multiple)*v_disk_multiple, "(Гб) для снижения утилизации до", v_alert_close"%", 
			"\n*кратность расширения", v_disk_multiple" (Гб)"} 
		else if ((NR>1 && $5 < v_alert))
			{print "Утилизация", $6, $5,"порог алерта", v_alert"%"}}'
	else
		echo -e "Файловая система $FS не найдена"
   fi
	shift
done
