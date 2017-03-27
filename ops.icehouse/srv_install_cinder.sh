#!/bin/bash

source def_controller.sh
source inc_controller.sh

###########################################
#
# cinder service node
#
##########################################
logg_big "cinder service node"

logg "install cinder"
install_pkgs 'openstack-cinder scsi-target-utils'

# set database info
set_conf "cinder.conf" "database" "connection" "mysql://cinder:$database_pass@$database_hostname/cinder"

# configure auth information on conf
set_conf 'cinder.conf' 'DEFAULT' 'api_paste_confg' '/etc/cinder/api-paste.ini'
set_conf 'cinder.conf' 'DEFAULT' 'auth_strategy' 'keystone'
set_conf 'cinder.conf' 'DEFAULT' 'glance_host' $glance_hostname
set_conf 'cinder.conf' 'DEFAULT' 'iscsi_helper' 'tgtadm'
set_conf 'cinder.conf' 'DEFAULT' 'iscsi_ip_address' $cinder_hostname
set_conf 'cinder.conf' 'DEFAULT' 'lock_path' '/var/lock/cinder'
set_conf 'cinder.conf' 'DEFAULT' 'max_gigabytes' '10000'
set_conf 'cinder.conf' 'DEFAULT' 'notification_driver' 'cinder.openstack.common.notifier.rpc_notifier'
set_conf 'cinder.conf' 'DEFAULT' 'notification_topics' 'notifications'
set_conf 'cinder.conf' 'DEFAULT' 'policy_file' '/etc/cinder/policy.json'
set_conf 'cinder.conf' 'DEFAULT' 'rabbit_host' $controller_hostname
set_conf 'cinder.conf' 'DEFAULT' 'rootwrap_config' '/etc/cinder/rootwrap.conf'
set_conf 'cinder.conf' 'DEFAULT' 'rpc_backend' 'rabbit'
set_conf 'cinder.conf' 'DEFAULT' 'state_path' '/var/lib/cinder'
set_conf 'cinder.conf' 'DEFAULT' 'storage_availability_zone' 'nova'
set_conf 'cinder.conf' 'DEFAULT' 'volume_clear_size' '0'
set_conf 'cinder.conf' 'DEFAULT' 'volume_clear' 'zero'
set_conf 'cinder.conf' 'DEFAULT' 'volume_driver' 'cinder.volume.drivers.lvm.LVMISCSIDriver'
set_conf 'cinder.conf' 'DEFAULT' 'volume_group' 'cinder-volumes'
set_conf 'cinder.conf' 'DEFAULT' 'volume_name_template' 'volume-%s'
set_conf 'cinder.conf' 'DEFAULT' 'volume_pool_size' 'None'
set_conf 'cinder.conf' 'DEFAULT' 'volumes_dir' '/etc/cinder/volumes'
set_conf 'cinder.conf' 'DEFAULT' 'control_exchange' 'cinder'
set_conf 'cinder.conf' 'keystone_authtoken' 'auth_host' $controller_hostname
set_conf 'cinder.conf' 'keystone_authtoken' 'auth_protocol' 'http'
set_conf 'cinder.conf' 'keystone_authtoken' 'auth_port' '35357'
set_conf 'cinder.conf' 'keystone_authtoken' 'admin_user' 'cinder'
set_conf 'cinder.conf' 'keystone_authtoken' 'admin_tenant_name' 'service'
set_conf 'cinder.conf' 'keystone_authtoken' 'admin_password' $service_pass

logg "set iptable for cinder"
#set_iptables "9292"
#iptables -L | grep "9292"

# register cinder services and start
clear_conf $conf_cinder

# lock dir
mkdir -p /var/lock/cinder/volumes
chown -R cinder. /var/lock/cinder
# volume dir
mkdir -p /etc/cinder/volumes
echo 'include /etc/cinder/volumes/*' >> /etc/tgt/targets.conf

# service
for i in openstack-cinder-volume tgtd; do
        service_handle $i
done
