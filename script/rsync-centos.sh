#!/bin/bash

BASE_DIR='/repo/centos-base'
UPDATE_DIR='/repo/centos-update'
EXTRA_DIR='/repo/extra'
REPO_URL='ftp.neowiz.com'

[ ! -d $BASE_DIR ] && mkdir -p $BASE_DIR
[ ! -d $UPDATE_DIR ] && mkdir -p $UPDATE_DIR
[ ! -d $EXTRA_DIR ] && mkdir -p $EXTRA_DIR

rsync -azt --delete rsync://$REPO_URL/centos/6.5/os/x86_64/Packages/ $BASE_DIR > $BASE_DIR/rsync.log 2>&1
rsync -azt --delete rsync://$REPO_URL/centos/6.5/updates/x86_64/Packages/ $UPDATE_DIR > $UPDATE_DIR/rsync.log 2>&1
rsync -azt --delete rsync://$REPO_URL/centos/6.5/extras/x86_64/Packages/ $EXTRA_DIR > $EXTRA_DIR/rsync.log 2>&1

createrepo $UPDATE_DIR
createrepo $EXTRA_DIR
