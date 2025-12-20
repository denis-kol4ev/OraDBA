#!/bin/bash

Help()
{
   echo "Script for step by step tasks execution."
   echo
   echo "Syntax: $0 [-h|-s|]"
   echo "options:"
   echo "-h   Print this Help."
   echo "-s   The task number from which to start executing the script."
   echo
}

# START_TASK шаг с которого запускается скрипт (на начальные шаги проверок это не рпспространяется, они выполняются всегда)
# CURRENT_TASK  текущеий шаг, увеличивается после выполнения очредного шага
# TASK_ID  номер задания

START_TASK=1

while getopts ":hs:" option; do
   case $option in
      h)
         Help
         exit;;
      s)
         START_TASK=$OPTARG;;
      :)
        echo "Error: option -$OPTARG requires an argument (integer)"
        exit;;
     \?)
         echo "Error: invalid option, use -h for help"
         exit;;
   esac
done

if ! [[ ${START_TASK} =~ ^[0-9]+$ ]]; then
    echo "Error: -s argument must be an integer"
    exit 1
fi

echo "Start script from task: ${START_TASK}"

CURRENT_TASK=${START_TASK}

TASK_ID=1
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    echo "Do work for task " ${TASK_ID}
    ((CURRENT_TASK+=1))
else
    echo "Task" ${TASK_ID} "skipped"
fi

TASK_ID=2
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    echo "Do work for task " ${TASK_ID}
    ((CURRENT_TASK+=1))
else
    echo "Task" ${TASK_ID} "skipped"
fi

TASK_ID=3
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    echo "Do work for task " ${TASK_ID}
    ((CURRENT_TASK+=1))
else
    echo "Task" ${TASK_ID} "skipped"
fi
