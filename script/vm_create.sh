#!/bin/bash
NAME=vlan-master_rhel7

[ $(virsh domid $NAME) ] && echo 'exit 1' && exit 1
cd /kvmfs

[ ! -f $NAME.qcow2 ] && qemu-img create -f qcow2 $NAME.qcow2 50G

virt-install --name $NAME -r 1024 --vcpu 1 \
--disk path=/kvmfs/$NAME.qcow2,format=qcow2,bus=virtio \
--network network=default,model=virtio \
--network network=virbr1,model=virtio \
--os-type=linux --os-variant=rhel7 \
-c /home/iso/rhel-server-7.0-x86_64-dvd.iso
