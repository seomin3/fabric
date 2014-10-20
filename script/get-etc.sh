#!/bin/bash
BK_DIR=/mnt/backup/$hostname

[ ! -d $BK_DIR ] && mkdir -p $BK_DIR
cd /etc
tar --exclude=./pki --exclude=./selinux/targeted -cf - ./ | xz -9 -c - > $BK_DIR/$(hostname)_etc.tar.xz
