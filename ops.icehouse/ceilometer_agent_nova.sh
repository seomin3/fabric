#!/bin/bash

if [ -f 'def_controller.sh' ] && [ -f 'inc_compute.sh' ]; then
    source def_controller.sh
    source inc_compute.sh
    logg 'include script'
else
    cmd_check '1'
fi

###########################################
#
# ceilometer agent for nova-compute
#
###########################################


# service check
logg 'checking to compute node'
service openstack-nova-compute status > /dev/null
cmd_check $?

# agent install
logg 'agent install'
install_pkgs 'openstack-ceilometer-compute python-ceilometerclient python-pecan'

# /etc/nova/nova.conf
logg 'agent config'
set_conf nova.conf DEFAULT instance_usage_audit True
set_conf nova.conf DEFAULT instance_usage_audit_period hour
set_conf nova.conf DEFAULT notify_on_state_change vm_and_task_state
set_conf nova.conf DEFAULT notification_driver nova.openstack.common.notifier.rpc_notifier
set_conf nova.conf DEFAULT notification_driver ceilometer.compute.nova_notifier
# /etc/ceilometer/ceilometer.conf
set_conf ceilo.conf publisher metering_secret $admin_token
set_conf ceilo.conf DEFAULT rpc_backend ceilometer.openstack.common.rpc.impl_kombu
set_conf ceilo.conf DEFAULT rabbit_host $controller_hostname
set_conf 'ceilo.conf' 'service_credentials' 'os_username' 'ceilometer'
set_conf 'ceilo.conf' 'service_credentials' 'os_tenant_name' 'service'
set_conf 'ceilo.conf' 'service_credentials' 'os_password' $service_pass
set_conf 'ceilo.conf' 'service_credentials' 'os_auth_url' "http://$controller_hostname:5000/v2.0"
set_conf 'ceilo.conf' 'keystone_authtoken' 'admin_user' 'ceilometer'
set_conf 'ceilo.conf' 'keystone_authtoken' 'admin_tenant_name' 'service'
set_conf 'ceilo.conf' 'keystone_authtoken' 'admin_password' $service_pass
set_conf 'ceilo.conf' 'keystone_authtoken' 'auth_host' "$controller_hostname"
set_conf 'ceilo.conf' 'keystone_authtoken' 'auth_protocol' 'http'
set_conf 'ceilo.conf' 'keystone_authtoken' 'auth_port' '35357'

# nova restart
openstack-service restart nova

# ceilometer start
logg 'agent start'
service_handle 'openstack-ceilometer-compute'
