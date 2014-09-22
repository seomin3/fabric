#!/bin/bash

servers=(
	"vlan-key"
	"vlan-nova"
)

for server in ${servers[@]}; do
	ssh "root@$server" "$@" 2>&1 | sed "s/^/$server: /"
done
