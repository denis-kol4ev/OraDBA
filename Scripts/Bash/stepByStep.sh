#!/bin/bash

# Функция справки
help()
{
   echo "Script for step by step tasks execution."
   echo
   echo "Syntax: $0 [-h] [-s TASK_NUMBER]"
   echo "options:"
   echo "-h         Print this help."
   echo "-s NUMBER  The task number from which to start executing the script."
   echo
   echo "Examples:"
   echo "  $0              # Start from task 1 (default)"
   echo "  $0 -s 2         # Start from task 2"
   echo "  $0 -s 1         # Start from task 1 (explicit)"
}

# Функция инициализации логирования
init_log() {
    # Убираем расширение .sh из имени скрипта
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_NAME_NOEXT="${SCRIPT_NAME%.sh}"
    LOG_FILE="${SCRIPT_NAME_NOEXT}_$(date +%Y%m%d_%H%M%S).log"
    
    {
        echo "=== Task Execution Log ==="
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Parameters: $*"
        echo "Start script from task: ${START_TASK}"
        echo ""
    } > "$LOG_FILE"
}

# Функция логирования запуска задания
log_task_start() {
    local id="$1"
    local name="$2"
    local message="Start task ${id}: ${name}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] $message"
    local show_on_screen="${3:-true}" # По умолчанию выводим на экран
    
    # Пишем в лог-файл
    echo "$log_entry" >> "$LOG_FILE"
    
    # Выводим на экран если нужно
    if [[ "$show_on_screen" == "true" ]]; then
        echo "$log_entry"
    fi
}

# Функция логирования завершения задания 
log_task_finish() {
    local id="$1"
    local status="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local show_on_screen="${3:-true}" # По умолчанию выводим на экран
    
    # Пишем в лог-файл
    if [[ $status -eq 0 ]]; then
        echo "[$timestamp] Finish task ${id}: Successfully" >> "$LOG_FILE"
    else
        echo "[$timestamp] Finish task ${id}: Failed" >> "$LOG_FILE"
    fi
    
    # Выводим на экран если нужно
    if [[ "$show_on_screen" == "true" ]]; then
        if [[ $status -eq 0 ]]; then
            echo "[$timestamp] Finish task ${id}: Successfully"
        else
            echo "[$timestamp] Finish task ${id}: Failed"
            exit 1;
        fi
    fi

}

# Задаём шаг с которого по умолчанию запускается скрипт
START_TASK=1 

# Обработка аргументов
while getopts ":hs:" option; do
   case $option in
      h)
         help
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

# Инициализация логирования
init_log "$@"

# Текущий шаг, увеличивается после выполнения
CURRENT_TASK="$START_TASK"

TASK_ID=1
TASK_NAME="Drop old test DB."
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    log_task_start "${TASK_ID}" "${TASK_NAME}"
    echo "Do some useful work for task ${TASK_ID}..."
    sleep 1
    TASK_STATUS=$?
    log_task_finish "${TASK_ID}" "${TASK_STATUS}"
    ((CURRENT_TASK++))
else
    echo "Task" ${TASK_ID} "skipped"
fi

TASK_ID=2
TASK_NAME="Clone prod DB to test."
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    log_task_start "${TASK_ID}" "${TASK_NAME}"
    echo "Do some useful work for task ${TASK_ID}..."
    sleep 1
    TASK_STATUS=$?
    log_task_finish "${TASK_ID}" "${TASK_STATUS}"
    ((CURRENT_TASK++))
else
    echo "Task" ${TASK_ID} "skipped"
fi

TASK_ID=3
TASK_NAME="Post clone task."
if [[ ${TASK_ID} -ge ${CURRENT_TASK} ]]; then
    log_task_start "${TASK_ID}" "${TASK_NAME}"
    echo "Do some useful work for task ${TASK_ID}..."
    sleep 1
    TASK_STATUS=$?
    log_task_finish "${TASK_ID}" "${TASK_STATUS}"
    ((CURRENT_TASK++))
else
    echo "Task" ${TASK_ID} "skipped"
fi
