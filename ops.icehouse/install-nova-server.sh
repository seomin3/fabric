#!/bin/bash
source ./include/fuction.sh
source ./include/controller.sh

###########################################
#
# nova (services for serving computing: api, conductor etc.)
#
##########################################
logg_big "nova"

logg "installing openstack nova"
install_pkgs 'openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient'

logg "config database and messsage queue"
set_conf "nova.conf" "database" "connection" "mysql://nova:$database_pass@$database_hostname/nova"
set_conf "nova.conf" "DEFAULT" "rabbit_host" $controller_hostname
set_conf "nova.conf" "DEFAULT" "rpc_backend" "rabbit"

logg "config vnc for nova"
set_conf "nova.conf" "DEFAULT" "my_ip" $controller_ip_vnc
set_conf "nova.conf" "DEFAULT" "vncserver_listen" $controller_ip_vnc
set_conf "nova.conf" "DEFAULT" "vncserver_proxyclient_address" $controller_ip_vnc

logg "create database and database user for nova"
create_database "nova"
su -s /bin/sh -c "nova-manage db sync" nova

logg "check:: is tables created?"
db_query "nova" "show tables"
cmd_check $?

logg "create nova user and register it to admin"
keystone user-create --name=nova --pass=$service_pass --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin

set_conf "nova.conf" "DEFAULT" "auth_strategy" "keystone"
set_conf 'nova.conf' 'DEFAULT' 'glance_host' $glance_hostname
set_conf "nova.conf" "keystone_authtoken" "auth_host" $controller_hostname
set_conf "nova.conf" "keystone_authtoken" "auth_protocol" "http"
set_conf "nova.conf" "keystone_authtoken" "auth_port" "35357"
set_conf "nova.conf" "keystone_authtoken" "admin_user" "nova"
set_conf "nova.conf" "keystone_authtoken" "admin_tenant_name" "service"
set_conf "nova.conf" "keystone_authtoken" "admin_password" "$service_pass"

logg "register nova service and endpoint to keystone"
keystone service-get nova > /dev/null
if [ "$?" -ne "0" ]
then
	keystone service-create --name=nova --type=compute \
	 --description="OpenStack Compute Service"
	keystone endpoint-create \
	 --service-id=$(keystone service-list | awk '/ compute / {print $2}') \
	 --publicurl=http://$controller_hostname:8774/v2/%\(tenant_id\)s \
	 --internalurl=http://$controller_hostname:8774/v2/%\(tenant_id\)s \
	 --adminurl=http://$controller_hostname:8774/v2/%\(tenant_id\)s
fi

logg "register port to iptables for keystone"
set_iptables "8774"
# check:: is nova port registered to iptable?
iptables -L | grep "8774"

logg "starting nova services"
clear_conf $conf_nova
for i in openstack-nova-{api,cert,consoleauth,scheduler,conductor,novncproxy};do
        service_handle $i
done

logg "test nova api"
nova list
cmd_check $?

logg "check:: show conf"
grep -v '^#\|^\s*$' $conf_nova
