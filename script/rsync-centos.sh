#!/bin/bash

REPO_URL='ftp.jaist.ac.jp'
# CentOS
BASE_DIR='/repo/centos-base'
BASE_URL="$REPO_URL/pub/Linux/CentOS/6.5/os/x86_64/Packages/"
UPDATE_DIR='/repo/centos-update'
UPDATE_URL="$REPO_URL/pub/Linux/CentOS/6.5/updates/x86_64/Packages/"
EXTRA_DIR='/repo/centos-extra'
EXTRA_URL="$REPO_URL/pub/Linux/CentOS/6.5/extras/x86_64/Packages/"
# Fedora EPEL6
EPEL6_DIR='/repo/epel6'
EPEL6_URL="$REPO_URL/pub/Linux/Fedora/epel/6/x86_64/"
# rpmforge
REPO_URL='ftp.riken.jp'
RPMFORGE_DIR='/repo/rpmforge'
RPMFORGE_URL="$REPO_URL/repoforge/redhat/el6/en/x86_64/rpmforge/RPMS/"

for i in $BASE_DIR $UPDATE_DIR $EXTRA_DIR $EPEL6_DIR $RPMFORGE_DIR
do
	[ ! -d $i ] && mkdir -p $i
done

# CentOS
rsync -at --delete rsync://$BASE_URL $BASE_DIR > $BASE_DIR/rsync.log 2>&1
rsync -at --delete rsync://$UPDATE_URL $UPDATE_DIR > $UPDATE_DIR/rsync.log 2>&1
rsync -at --delete rsync://$EXTRA_URL $EXTRA_DIR > $EXTRA_DIR/rsync.log 2>&1

# Fedora EPEL6
rsync -at --delete rsync://$EPEL6_URL $EPEL6_DIR > $EPEL6_DIR/rsync.log 2>&1

# rpmforge
rsync -at --delete rsync://$RPMFORGE_URL $RPMFORGE_DIR > $RPMFORGE_DIR/rsync.log 2>&1

for i in $BASE_DIR $UPDATE_DIR $EXTRA_DIR $EPEL6_DIR
do
	createrepo $i
	#tar -cf - $i | xz -9 -c - > /tmp/repo-$i.tar.xz
done
