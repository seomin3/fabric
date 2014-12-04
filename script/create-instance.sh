#!/bin/bash
IFS='
'
VM_PROJECT=$1
NET_ID=a060bb48-dd8d-4559-b782-73fea03505f4
for i in $(nova image-list | grep $VM_PROJECT); do
    VM_ID=$(echo $i | awk '{ print $2 }')
    VM_NAME=$(echo $i | awk '{ print $4 }')
    
    nova --os-tenant-name $VM_PROJECT boot --flavor m1.medium --image $VM_ID \
    --nic net-id=$NET_ID \
    --availability-zone nova  \
    $VM_NAME
done
