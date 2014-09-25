BACKUP_DIR='/newdrive/archive/'
for i in puppet foreman rpmforge epel6 centos-extra centos-update centos-base
do
		BACKUP_FILE="$BACKUPDIR/$i.tar.xz"
		[ -f "$BACKUP_FILE" ] && rm -f $BACKUP_FILE
		cd /repo
		tar -cf - $i | xz -9 -c - > $BACKUP_FILE
done
