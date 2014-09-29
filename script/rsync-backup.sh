BACKUP_DIR='/srv/archive/'
for i in puppet foreman rpmforge epel6 centos-extra centos-update centos-base
do
	BACKUP_FILE="$BACKUP_DIR/$i.tar.xz"
	[ -f "$BACKUP_FILE" ] && rm -f $BACKUP_FILE
	cd /repo
	tar -cf - $i | xz -9 -c - > $BACKUP_FILE
done
