#!/bin/bash

cd /repo
for i in $(ls)
do
        createrepo ./$i
        tar -cf - $i | xz -9 -c - > /tmp/repo-$i.tar.xz
done
