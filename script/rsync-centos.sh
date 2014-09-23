#!/bin/bash
COMPRESS=0
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
# foreman
FOREMAN_DIR='/repo/foreman'
FOREMAN_URL="yum.theforeman.org/yum/"
# puppet
PUPPET_DIR='/repo/puppet'
PUPPET_URL="yum.puppetlabs.com/packages/yum/el/6.5/"

# create directory
for i in $BASE_DIR $UPDATE_DIR $EXTRA_DIR $EPEL6_DIR $RPMFORGE_DIR $FOREMAN_DIR $PUPPET_DIR
do
	[ ! -d $i ] && mkdir -p $i
done

# CentOS
rsync -at --delete rsync://$BASE_URL $BASE_DIR --log-file=$BASE_DIR/rsync.log
rsync -at --delete rsync://$UPDATE_URL $UPDATE_DIR --log-file=$UPDATE_DIR/rsync.log
rsync -at --delete rsync://$EXTRA_URL $EXTRA_DIR --log-file=$EXTRA_DIR/rsync.log

# Fedora EPEL6
rsync -at --delete rsync://$EPEL6_URL $EPEL6_DIR --log-file=$EPEL6_DIR/rsync.log

# rpmforge
rsync -at --delete rsync://$RPMFORGE_URL $RPMFORGE_DIR --log-file=$RPMFORGE_DIR/rsync.log

# foreman
rsync -at --delete rsync://$FOREMAN_URL $FOREMAN_DIR --log-file=$FOREMAN_DIR/rsync.log

# puppet
rsync -at --delete rsync://$PUPPET_URL $PUPPET_DIR --log-file=$PUPPET_DIR/rsync.log

# openstack-icehouse

reposync -r openstack-icehouse -p /repo > /repo/openstack-icehouse/reposync.log 2>&1


# create xml
# compress
if [ ! $COMPRESS -eq 0 ]
then
	for i in puppet foreman rpmforge epel6 centos-extra centos-update centos-base
	do
		#createrepo $i
		cd /repo
		tar -cf - $i | xz -9 -c - > /newdrive/archive/$i.tar.xz
	done
fi
