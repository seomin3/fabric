#!/bin/bash

ME=$(basename $0)
RET=$(ps -ef| grep $ME | grep -v grep| wc -l)
[ "$RET" -gt 2 ] && exit 1

LOG_PATH='/var/log/cputime'
mkdir -p $LOG_PATH

while [ 1 ]; do
    LOG_DATE=$(date +%y%m%d)
    LOG_FILE=${LOG_PATH}/$(hostname)-${LOG_DATE}.log

    top -b -d 0 -n 1 | head -n 20  >> $LOG_FILE
    echo >> $LOG_FILE
    echo >> $LOG_FILE
    sleep 2
done
