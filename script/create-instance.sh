#!/bin/bash
IFS='
'
VM_PROJECT=$1
NET_ID=09ca9b4c-20c6-4058-9361-fa9c24cca210
for i in $(nova image-list | grep $VM_PROJECT); do
    VM_ID=$(echo $i | awk '{ print $2 }')
    VM_NAME=$(echo $i | awk '{ print $4 }')
    
    nova --os-tenant-name $VM_PROJECT boot --flavor m1.medium --image $VM_ID \
    --nic net-id=$NET_ID \
    --availability-zone nova  \
    $VM_NAME
done