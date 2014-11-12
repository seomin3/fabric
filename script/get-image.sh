#!/bin/bash

IM_TENANT='admin'
IM_PUBLIC='True'
IM_DATE=$(date +%y%m%d)
IM_NAME=$1

if [ ! -n "$1" ]; then
    echo 'Exit code: 1'
    exit 1
fi

if [ -n "$2" ]; then
    IM_TENANT=$2
    IM_PUBLIC='False'
fi


echo "Project - $IM_TENANT, Instance - $IM_NAME"
glance --os-tenant-name $IM_TENANT image-create --name ${IM_NAME}-${IM_DATE} --disk-format qcow2 \
  --container-format bare --is-public $IM_PUBLIC --progress <  $IM_NAME
