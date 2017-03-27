#!/bin/bash

if [ -f 'def_controller.sh' ] && [ -f 'inc_controller.sh' ]; then
    source def_controller.sh
    source inc_controller.sh
    logg 'include script'
else
    cmd_check '1'
fi


###########################################
#
# ceilometer
#
###########################################


# install telemetry service
logg 'install packages'
install_pkgs 'openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central openstack-ceilometer-alarm python-ceilometerclient'

# install mongodb
install_pkgs 'mongodb-server mongodb'
perl -pi -e 's/bind_ip = 127.0.0.1/bind_ip = 0.0.0.0/' /etc/mongodb.conf
service_handle 'mongod'

# init mongodb
logg 'init mongodb'
sleep 2
mongo "${controller_hostname}:27017/ceilometer" --eval "db.stats()"
mongo "${controller_hostname}:27017/ceilometer" --eval "db.addUser({user: \"ceilometer\", pwd: \"$database_pass\", roles: [ \"readWrite\", \"dbAdmin\" ]})"

# config
logg 'openstack config'
set_conf 'ceilo.conf' 'DEFAULT' 'rabbit_host' $controller_hostname
set_conf 'ceilo.conf' 'DEFAULT' 'rpc_backend' 'ceilometer.openstack.common.rpc.impl_kombu'
set_conf 'ceilo.conf' 'DEFAULT' 'auth_strategy' 'keystone'
#set_conf 'ceilo.conf' 'DEFAULT' 'http_control_exchanges' 'glance'
#set_conf 'ceilo.conf' 'DEFAULT' 'cinder_control_exchange' 'cinder'
set_conf 'ceilo.conf' 'publisher' 'metering_secret' $admin_token
set_conf 'ceilo.conf' 'database' 'connection' "mongodb://ceilometer:$database_pass@$controller_hostname:27017/ceilometer"
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

# keystone user
keystone user-create --name=ceilometer --pass=$service_pass --email=ceilometer@example.com
keystone user-role-add --user=ceilometer --tenant=service --role=admin

# keystone service
keystone service-get ceilometer > /dev/null
if [ "$?" -ne "0" ]; then
    keystone service-create --name=ceilometer --type=metering --description="OpenStack Telemetry Service"
    keystone endpoint-create \
      --service-id=$(keystone service-list | awk '/ metering / {print $2}') \
      --publicurl=http://$controller_hostname:8777 \
      --internalurl=http://$controller_hostname:8777 \
      --adminurl=http://$controller_hostname:8777
fi

# ceilometer service
for i in openstack-ceilometer-{api,notification,central,collector,alarm-evaluator,alarm-notifier}; do
        service_handle $i
done

openstack-service status