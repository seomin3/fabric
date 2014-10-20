#!/bin/bash
basedir=$(dirname $0)

[ -f "$basedir/.serverlist" ] && servers=$(cat $basedir/.serverlist)
[ -z "$1" ] && echo "exit 1"

for server in ${servers[@]}; do
	ssh "root@$server" "$@" 2>&1 | sed "s/^/root@$server: /"
done
