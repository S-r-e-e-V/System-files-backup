#!/bin/bash

INCREMENTAL_VAR=0
BACKLOG_DIR="$HOME/home/backup"
LATEST_BACKUP=""

export TZ=America/New_York

function run_full_backup() {
    # Set the backup directory
    BACKUP_DIR="$HOME/home/backup/cb"

    # Check if the backup directory exists, create it if necessary
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi

    # Create the tar file with a unique name
    TIMESTAMP=$(date "+%Y%m%d%H%M%S")
    TAR_FILENAME="cb$TIMESTAMP.tar"
    find $HOME -type f -name "*.txt" -print0 | tar -cvf $BACKUP_DIR/$TAR_FILENAME --null -T -

    LATEST_BACKUP="$BACKUP_DIR/$TAR_FILENAME"

    # Update the backup log with the timestamp and tar filename
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $TAR_FILENAME was created" >> $BACKLOG_DIR/backup.log
}

function run_incremental_backup() {
    # Set the backup directory
    BACKUP_DIR="$HOME/home/backup/ib"

    # Check if the backup directory exists, create it if necessary
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi

    # if there are no update then return from the function
    if ! [ $(find $HOME -type f -name "*.txt" -newer $LATEST_BACKUP | wc -l) -gt 0 ]; then
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes-Incremental backup was not created" >> $BACKLOG_DIR/backup.log
        return 0
    fi

    # Create the tar file with a unique name
    TIMESTAMP=$(date "+%Y%m%d%H%M%S")
    TAR_FILENAME="ib$TIMESTAMP.tar"
    find $HOME -type f -name "*.txt" -newer $LATEST_BACKUP -print0 | tar -cvf $BACKUP_DIR/$TAR_FILENAME --null -T -

    LATEST_BACKUP="$BACKUP_DIR/$TAR_FILENAME"

    # Update the backup log with the timestamp and tar filename
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $TAR_FILENAME was created" >> $BACKLOG_DIR/backup.log
}


while true; do

    if [ $(expr $INCREMENTAL_VAR % 4) -eq 0 ]; then
        run_full_backup
    else 
        run_incremental_backup
    fi
    ((INCREMENTAL_VAR++))
    
    # Sleep for 2 minutes
    sleep 120

done &
