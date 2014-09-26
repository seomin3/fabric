#!/bin/bash

GIT_DIR='/opt/git'
cd $GIT_DIR

for i in $(find  -maxdepth 1 -type d)
do
	[ "$i" == "." ] && continue
	cd $i
	echo "=== $i git repository pulling ==="
	git pull
	cd ..
done
