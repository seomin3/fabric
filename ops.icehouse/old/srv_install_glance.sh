#!/bin/bash

source def_controller.sh
source inc_controller.sh

###########################################
#
# glance
#
##########################################
logg_big "glance"

logg "install glance"
install_pkgs 'openstack-glance python-keystoneclient python-glanceclient'

#set database info
set_conf "glance-api.conf" "database" "connection" "mysql://glance:$database_pass@$database_hostname/glance"
set_conf "glance-registry.conf" "database" "connection" "mysql://glance:$database_pass@$database_hostname/glance"

#set_conf "glance-api.conf" "rpc_backend" "qpid"
#set_conf "glance-api.conf" "DEFAULT" "qpid_hostname" $controller_hostname

logg "create database and user for glance"
create_database "glance"
su -s /bin/sh -c "glance-manage -v -d db_sync" glance

logg "check:: is database created?"
db_query "mysql" "show databases"
logg "check:: is tables created?"
db_query "glance" "show tables"
cmd_check $?

logg "register glance user to keystone and set it as a admin account"
keystone user-create --name=glance --pass=$service_pass --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin

# configure auth information on conf
for i in glance-{api,registry}.conf;do
    set_conf $i 'DEFAULT' 'rabbit_host' $controller_hostname
    set_conf $i 'DEFAULT' 'rpc_backend' 'rabbit'
    set_conf $i "keystone_authtoken" "auth_host" "$controller_hostname"
    set_conf $i "keystone_authtoken" "auth_port" "35357"
    set_conf $i "keystone_authtoken" "auth_protocol" "http"
    set_conf $i "keystone_authtoken" "admin_tenant_name" "service"
    set_conf $i "keystone_authtoken" "admin_user" "glance"
    set_conf $i "keystone_authtoken" "admin_password" "$service_pass"
    set_conf $i "paste_deploy" "flavor" "keystone"
done
#set_conf 'glance-api' 'DEFAULT' 'filesystem_store_datadir' '/image/'

logg "create service and endpoint for glance"
keystone service-get glance > /dev/null
if [ "$?" -ne "0" ]; then
	keystone service-create --name=glance --type=image --description="OpenStack Image Service"
	keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}') \
	 --publicurl=http://$glance_hostname:9292 \
	 --internalurl=http://$glance_hostname:9292 \
	 --adminurl=http://$glance_hostname:9292
fi

logg "set iptable for glance"
set_iptables "9292"
iptables -L | grep "9292"

# register glance services and start
clear_conf $conf_glance_api
clear_conf $conf_glance_registry
for i in openstack-glance-{api,registry};do
        service_handle $i
done

logg "download and register test image(cirros)"
glance image-create --name "cirros-0.3.2-x86_64" --disk-format qcow2 --container-format bare --is-public True --progress < cirros-0.3.2-x86_64-disk.img

logg "test glance"
glance image-list

logg "check:: show conf"
grep -v '^#\|^\s*$' $conf_glance_registry
grep -v '^#\|^\s*$' $conf_glance_api
