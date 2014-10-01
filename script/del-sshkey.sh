#!/bin/bash

function dep_print_error() {
    echo "Usage: $(basename $0) REMOTE_HOST_NAME REMOTE_HOST_PASSWORD"
    exit 1
}

if [ -n "$1" ]; then
    REMOTE_HOST=$1
else
    dep_print_error
fi

for i in $(cat /etc/hosts | grep $REMOTE_HOST); do
    ssh-keygen -R $i
    su - sysop -c "ssh-keygen -R $i"
done
