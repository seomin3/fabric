#!/bin/bash

source def_controller.sh
source inc_controller.sh

###############################
#
# basic settings
#
###############################
logg_big "basic settings"

logg "install crone only if cronetab command is invalid"
install_pkgs 'cronie'

logg "install mysql"
install_pkgs 'mysql MySQL-python mysql-server expect'

# modify my.cnf
if grep --quiet character-set-server /etc/my.cnf;then
        echo "skipping my.cnf"
else
        mv -f /etc/my.cnf /etc/my.cnf.bak;
        sed "s/mysqld\]/mysqld\]\ndefault-storage-engine=innodb\ncollation-server=utf8_general_ci\ninit-connect=\'SET\ NAMES\ utf8\'\ncharacter-set-server=utf8/g" /etc/my.cnf.bak > /etc/my.cnf
fi
# check my.cnf
grep -v '^#\|^\s*$' /etc/my.cnf

# mysql database install
logg "prepare mysql"
{
        service_handle mysqld
		[ ! -f '/var/lib/mysql/ibdata1' ] && mysql_install_db;
		echo $?
} || {
        echo "failed at launching mysql."
        echo "RERUN script."
        exit 1;
}

mysql -uroot -Dtest -B -e'show databases' > /dev/null 2>&1
RET=$?

if [ "$RET" -eq "0" ]
then
	logg "mysql secure installation"
	# expect selection
/usr/bin/expect <<EOD
spawn mysql_secure_installation
expect {
		timeout { exit 1; }
		"*password for the*" {          send "\r"               }
}
expect {
		timeout { exit 1; }
		"Enter current password for root*" {    send "\r"       }
}
expect {
		timeout { exit 1; }
		"New password*" {       send "$database_pass\r"         }
}
expect {
		timeout { exit 1; }
		"Re-enter new password*" {      send "$database_pass\r"         }
}
expect {
		timeout { exit 1; }
		"Remove anonymous users*" {                send "y\r"        }
}
expect {
		timeout { exit 1; }
		"Disallow root login remotely*" {                send "n\r"        }
expect {
		timeout { exit 1; }
		"Remove test database and access to it*" {                send "y\r"        }
}
expect {
		timeout { exit 1; }
		"Reload privilege tables now*" {                send "y\r"        }
}
EOD
fi

logg "install message queue"
install_pkgs 'rabbitmq-server python-pip python-kombu'
rabbitmqctl change_password guest guest

service_handle rabbitmq-server

logg "set iptable for mq and database"
set_iptables "3306"
set_iptables "5672"
#check:: iptables for mq and db
iptables -L | grep "3306\|5672"

logg "selinux off for httpd"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo 0 > /selinux/enforce
#check:: selinux is changed?
cat /selinux/enforce

###########################################
#
# keystone
#
##########################################
logg_big "keystone"

logg "install keystone"
install_pkgs 'openstack-keystone python-keystoneclient python-glanceclient'

logg "set database connnection info on conf"
set_conf "keystone.conf" "database" "connection" "mysql://keystone:$database_pass@$database_hostname/keystone"

logg "create database for keystone"
create_database "keystone"
su -s /bin/sh -c "keystone-manage db_sync" keystone

logg "check:: is database created?"
db_query "mysql" "show databases"
logg "check:: is tables created?"
db_query "keystone" "show tables"
cmd_check $?

logg "set admin token"
set_conf "keystone.conf" "DEFAULT" "admin_token" $admin_token

logg "set pki info and set file auth for keystone"
keystone-manage pki_setup --keystone-user keystone --keystone-group  keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl
chown keystone:keystone /var/log/keystone/keystone.log
# check:: is the auth of keystone files right?
ls -al /etc/keystone
ls -al /var/log/keystone

logg "service start and enable"
clear_conf $conf_keystone
service_handle openstack-keystone

logg "register 5000, 35357 ports to iptables"
set_iptables 5000
set_iptables 35357
# check:: is keystone port registered to iptable?
iptables -L | grep '5000\|35357'

logg "registering flush expired keys"
(crontab -l 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/root\

logg "set service tokens"
export OS_SERVICE_TOKEN=$admin_token
export OS_SERVICE_ENDPOINT=http://$controller_hostname:35357/v2.0
echo "service token is:    $OS_SERVICE_TOKEN "
echo "service endpoint is: $OS_SERVICE_ENDPOINT "

logg "create admin user, role"
keystone user-create --name=admin --pass=$admin_pass --email=admin@email.com
keystone role-create --name=admin

logg "create admin tenant"
keystone tenant-create --name=admin --description="Admin Tenant"

logg "assign roles of admin and _member_ to admin user "
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin

logg "create service tenant"
keystone tenant-create --name=service --description="Service Tenant"

logg "create keystone service & endpoint"
keystone service-get keystone > /dev/null
if [ "$?" -ne "0" ]
then
	keystone service-create --name=keystone --type=identity --description="OpenStack Identity Service"
	keystone endpoint-create \
	 --service-id=$(keystone service-list | awk '/ identity / {print $2}') \
	 --publicurl=http://$controller_hostname:5000/v2.0 \
	 --internalurl=http://$controller_hostname:5000/v2.0 \
	 --adminurl=http://$controller_hostname:35357/v2.0
fi

logg "test keystone token-get using service token"
keystone --os-username=admin --os-password=$admin_pass --os-auth-url=http://$controller_hostname:35357/v2.0 token-get > /dev/null

logg "test keystone token-get with admin tenant by service token"
keystone --os-username=admin --os-password=$admin_pass --os-tenant-name=admin --os-auth-url=http://$controller_hostname:35357/v2.0  token-get > /dev/null

logg "unsetting service tokens"
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
echo "OS_SERVICE_TOKEN : " $OS_SERVICE_TOKEN
echo "OS_SERVICE_ENDPOINT : " $OS_SERVICE_ENDPOINT

logg "loading credentials"
export OS_USERNAME=admin
export OS_PASSWORD=$admin_pass
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$controller_hostname:35357/v2.0
echo $OS_USERNAME
echo $OS_PASSWORD
echo $OS_TENANT_NAME
echo $OS_AUTH_URL

logg "testing keystone token-get using credential"
keystone token-get

logg "testing keystone user-list using credential"
keystone user-list

logg "testing keystone user-role-list using credential"
keystone user-role-list --user admin --tenant admin

logg "show conf"
grep -v '^#\|^\s*$' $conf_keystone
