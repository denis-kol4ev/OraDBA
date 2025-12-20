#!/bin/bash

Help()
{
   echo "Script for step by step tasks execution."
   echo
   echo "Syntax: $0 [-h] [-s TASK_NUMBER]"
   echo "options:"
   echo "-h         Print this Help."
   echo "-s NUMBER  The task number from which to start executing the script."
   echo
   echo "Examples:"
   echo "  $0              # Start from task 1 (default)"
   echo "  $0 -s 2         # Start from task 2"
   echo "  $0 -s 1         # Start from task 1 (explicit)"
}

# START_TASK - шаг с которого запускается скрипт
# CURRENT_TASK - текущий шаг (увеличивается после выполнения)

START_TASK=1

# Обработка аргументов
while getopts ":hs:" option; do
   case $option in
      h)
         Help
         exit 0
         ;;
      s)
         START_TASK="$OPTARG"
         ;;
      :)
         echo "Error: option -$OPTARG requires an argument (integer)" >&2
         exit 1
         ;;
     \?)
         echo "Error: invalid option -$OPTARG, use -h for help" >&2
         exit 1
         ;;
   esac
done

# Проверка, что START_TASK - положительное целое число
if ! [[ "$START_TASK" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: -s argument must be a positive integer (1 or more)" >&2
    exit 1
fi

echo "Start script from task: ${START_TASK}"

CURRENT_TASK="$START_TASK"

TASK_ID=1
TASK_NAME="Drop old test DB."
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    echo "Do work for task" ${TASK_ID}":" ${TASK_NAME}
    ((CURRENT_TASK++))
else
    echo "Task" ${TASK_ID} "skipped"
fi

TASK_ID=2
TASK_NAME="Clone prod DB to test."
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    echo "Do work for task" ${TASK_ID}":" ${TASK_NAME}
    ((CURRENT_TASK++))
else
    echo "Task" ${TASK_ID} "skipped"
fi

TASK_ID=3
TASK_NAME="Post clone task."
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    echo "Do work for task" ${TASK_ID}":" ${TASK_NAME}
    ((CURRENT_TASK++))
else
    echo "Task" ${TASK_ID} "skipped"
fi
