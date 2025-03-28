#!/bin/bash
#Description: This script backup folders defined in config file

CONFIG_FILE=backup_config.json

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed. Please install jq to use this script."
    exit 1
fi

create_backup() {
    echo "Backing up $2 to $3 ..."
    tar -czf $3 $2

    if [[ $? -eq 0 ]]; then
        echo "Backup $1 completed successfully."
    else
        echo "Backup $1 failed."
    fi
}

BACKUP_COUNT=$(jq -r '.backup_list | length' $CONFIG_FILE)

for ((i = 0; i < $BACKUP_COUNT; i++)); do
    BACKUP_NAME=$(jq -r ".backup_list[$i].backup_name" $CONFIG_FILE)
    SOURCE_FOLDER=$(jq -r ".backup_list[$i].source_folder" $CONFIG_FILE)
    TARGET_FOLDER=$(jq -r ".backup_list[$i].target_folder" $CONFIG_FILE)

    echo "Start backup: $BACKUP_NAME"

    if [[ ! -d $SOURCE_FOLDER ]]; then
        echo "Skipping backup $BACKUP_NAME: Source folder $SOURCE_FOLDER does not exist."
        continue
    fi

    if [[ ! -d $TARGET_FOLDER ]]; then
        echo "Target folder $TARGET_FOLDER for backup $BACKUP_NAME does not exist, creating..."
        mkdir -pv $TARGET_FOLDER
    fi

    BACKUP_FILE=$TARGET_FOLDER/$BACKUP_NAME-$(date +%F-%H-%M.tar.gz)

    create_backup $BACKUP_NAME $SOURCE_FOLDER $BACKUP_FILE

    echo -e "Finish backup: $BACKUP_NAME \n"

done
