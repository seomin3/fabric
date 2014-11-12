#!/bin/bash
source /etc/profile.d/openrc.sh

filter() {
    [ "$1" == '' ] || [ "$1" == 'ID' ] || [ "$1" == 'Name' ] && continue
}
logg() {
    echo "============== $1 =============="
}

IFS='
'
VM_ID=''
VM_LIST=''
VM_NAME='nova-instance'
for i in $(nova list | grep $VM_NAME); do
    VM_ID=$(echo $i| awk '{ print $2 }')
    filter $VM_ID
    VM_LIST="$VM_LIST $VM_ID"
done
nova delete $VM_LIST
