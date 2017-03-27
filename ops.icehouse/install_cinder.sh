#!/bin/bash

source def_controller.sh
source inc_controller.sh

###########################################
#
# cinder
#
###########################################
logg_big "cinder"

logg "install cinder"
install_pkgs 'openstack-cinder'

# set database info
set_conf "cinder.conf" "database" "connection" "mysql://cinder:$database_pass@$database_hostname/cinder"

logg "create database and user for cinder"
create_database "cinder"
su -s /bin/sh -c "cinder-manage db sync" cinder

logg "check:: is database created?"
db_query "mysql" "show databases"
logg "check:: is tables created?"
db_query "cinder" "show tables"
cmd_check $?

logg "register cinder user to keystone and set it as a admin account"
keystone user-create --name=cinder --pass=$service_pass --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

# configure auth information on conf
set_conf 'cinder.conf' 'DEFAULT' 'api_paste_conf' '/etc/cinder/api-paste.ini'
set_conf 'cinder.conf' 'DEFAULT' 'auth_strategy' 'keystone'
set_conf 'cinder.conf' 'DEFAULT' 'iscsi_helper' 'tgtadm'
set_conf 'cinder.conf' 'DEFAULT' 'notification_driver' 'cinder.openstack.common.notifier.rpc_notifier'
set_conf 'cinder.conf' 'DEFAULT' 'notification_topics' 'notifications'
set_conf 'cinder.conf' 'DEFAULT' 'osapi_volume_listen' '0.0.0.0'
set_conf 'cinder.conf' 'DEFAULT' 'osapi_volume_listen_port' '8776'
set_conf 'cinder.conf' 'DEFAULT' 'policy_file' '/etc/cinder/policy.json'
set_conf 'cinder.conf' 'DEFAULT' 'rabbit_host' $controller_hostname
set_conf 'cinder.conf' 'DEFAULT' 'rootwrap_config' '/etc/cinder/rootwrap.conf'
set_conf 'cinder.conf' 'DEFAULT' 'scheduler_driver' 'cinder.scheduler.filter_scheduler.FilterScheduler'
set_conf 'cinder.conf' 'DEFAULT' 'volume_clear_size' '0'
set_conf 'cinder.conf' 'DEFAULT' 'volume_clear' 'zero'
set_conf 'cinder.conf' 'DEFAULT' 'volume_driver' 'cinder.volume.drivers.lvm.LVMISCSIDriver'
set_conf 'cinder.conf' 'DEFAULT' 'volume_group' 'cinder-volumes'
set_conf 'cinder.conf' 'DEFAULT' 'volume_pool_size' 'None'
set_conf 'cinder.conf' 'DEFAULT' 'control_exchange' 'cinder'
set_conf 'cinder.conf' 'keystone_authtoken' 'auth_host' "$controller_hostname"
set_conf 'cinder.conf' 'keystone_authtoken' 'auth_protocol' 'http'
set_conf 'cinder.conf' 'keystone_authtoken' 'auth_port' '35357'
set_conf 'cinder.conf' 'keystone_authtoken' 'admin_user' 'cinder'
set_conf 'cinder.conf' 'keystone_authtoken' 'admin_tenant_name' 'service'
set_conf 'cinder.conf' 'keystone_authtoken' 'admin_password' $service_pass

logg "create service and endpoint for cinder"
keystone service-get cinder > /dev/null
if [ "$?" -ne "0" ]; then
    keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage"
    keystone endpoint-create --service-id=$(keystone service-list | awk '/ volume  / {print $2}') \
     --publicurl=http://$cinder_hostname:8776/v1/%\(tenant_id\)s \
     --internalurl=http://$cinder_hostname:8776/v1/%\(tenant_id\)s \
     --adminurl=http://$cinder_hostname:8776/v1/%\(tenant_id\)s
fi

logg "create service and endpoint for cinder v2"
keystone service-get cinderv2 > /dev/null
if [ "$?" -ne "0" ]; then
    keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage v2"
    keystone endpoint-create --service-id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
     --publicurl=http://$cinder_hostname:8776/v2/%\(tenant_id\)s \
     --internalurl=http://$cinder_hostname:8776/v2/%\(tenant_id\)s \
     --adminurl=http://$cinder_hostname:8776/v2/%\(tenant_id\)s
fi

logg "set iptable for cinder"
#set_iptables "9292"
#iptables -L | grep "9292"

# register cinder services and start
clear_conf $conf_cinder

for i in openstack-cinder-{api,scheduler};do
        service_handle $i
done
