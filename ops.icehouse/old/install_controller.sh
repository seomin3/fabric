#!/bin/bash

source def_controller.sh
source inc_controller.sh

###########################################
#
# nova (services for serving computing: api, conductor etc.)
#
##########################################
logg_big "nova"

logg "installing openstack nova"
yum -y install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

logg "config database and messsage queue"
set_conf "nova.conf" "database" "connection" "mysql://nova:$database_pass@$controller_hostname/nova"
set_conf "nova.conf" "DEFAULT" "rabbit_host" $controller_hostname
set_conf "nova.conf" "DEFAULT" "rpc_backend" "rabbit"

logg "config vnc for nova"
set_conf "nova.conf" "DEFAULT" "my_ip" $controller_ip_mng
set_conf "nova.conf" "DEFAULT" "vncserver_listen" $controller_ip_mng
set_conf "nova.conf" "DEFAULT" "vncserver_proxyclient_address" $controller_ip_mng

logg "create database and database user for nova"
create_database "nova"
su -s /bin/sh -c "nova-manage db sync" nova

logg "check:: is database created?"
db_query "mysql" "show databases"
logg "check:: is tables created?"
db_query "nova" "show tables"

logg "create nova user and register it to admin"
keystone user-create --name=nova --pass=$service_pass --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin

set_conf "nova.conf" "DEFAULT" "auth_strategy" "keystone"
set_conf "nova.conf" "keystone_authtoken" "auth_uri" "http://$controller_hostname:5000"
set_conf "nova.conf" "keystone_authtoken" "auth_host" $controller_hostname
set_conf "nova.conf" "keystone_authtoken" "auth_protocol" "http"
set_conf "nova.conf" "keystone_authtoken" "auth_port" "35357"
set_conf "nova.conf" "keystone_authtoken" "admin_user" "nova"
set_conf "nova.conf" "keystone_authtoken" "admin_tenant_name" "service"
set_conf "nova.conf" "keystone_authtoken" "admin_password" "$service_pass"

logg "register nova service and endpoint to keystone"
keystone service-create --name=nova --type=compute \
 --description="OpenStack Compute"
keystone endpoint-create \
 --service-id=$(keystone service-list | awk '/ compute / {print $2}') \
 --publicurl=http://$controller_hostname:8774/v2/%\(tenant_id\)s \
 --internalurl=http://$controller_hostname:8774/v2/%\(tenant_id\)s \
 --adminurl=http://$controller_hostname:8774/v2/%\(tenant_id\)s

logg "register port to iptables for keystone"
set_iptables "8774"
# check:: is nova port registered to iptable?
iptables -L | grep "8774"

logg "starting nova services"
clear_conf $conf_nova
for i in openstack-nova-{api,cert,consoleauth,scheduler,conductor,novncproxy};do
        service_handle $i
done
# check:: is nova process started?
ps -ef | grep nova

logg "test nova api"
nova image-list

logg "check:: show conf"
grep -v '^#\|^\s*$' $conf_nova

###########################################
#
# neutron (server)
#
##########################################
logg_big "neutron"

logg "install neutron server rpms"
yum -y install openstack-neutron openstack-neutron-ml2 python-neutronclient

logg "create database and database user for neutron"
create_database "neutron"

keystone user-create --name neutron --pass $service_pass --email neutron@example.com
keystone user-role-add --user neutron --tenant service --role admin
keystone service-create --name neutron --type network --description "OpenStack Networking"
keystone endpoint-create \
 --service-id $(keystone service-list | awk '/ network / {print $2}')  \
 --publicurl http://$controller_hostname:9696 \
 --adminurl http://$controller_hostname:9696 \
 --internalurl http://$controller_hostname:9696

# set basic configurations for neutron.conf 
set_conf "neutron.conf" "database" "connection" "mysql://neutron:$database_pass@$controller_hostname/neutron"
set_conf "neutron.conf" "DEFAULT" "auth_strategy" "keystone"
set_conf "neutron.conf" "keystone_authtoken" "auth_uri" "http://$controller_hostname:5000"
set_conf "neutron.conf" "keystone_authtoken" "auth_host" $controller_hostname
set_conf "neutron.conf" "keystone_authtoken" "auth_protocol" "http"
set_conf "neutron.conf" "keystone_authtoken" "auth_port" "35357"
set_conf "neutron.conf" "keystone_authtoken" "admin_tenant_name" "service"
set_conf "neutron.conf" "keystone_authtoken" "admin_user" "neutron"
set_conf "neutron.conf" "keystone_authtoken" "admin_password" $service_pass
set_conf "neutron.conf" "DEFAULT" "rpc_backend" "neutron.openstack.common.rpc.impl_kombu"
set_conf "neutron.conf" "DEFAULT" "rabbit_host" $controller_hostname
set_conf "neutron.conf" "DEFAULT" "notify_nova_on_port_status_changes" "True"
set_conf "neutron.conf" "DEFAULT" "notify_nova_on_port_data_changes" "True"
set_conf "neutron.conf" "DEFAULT" "nova_url" "http://$controller_hostname:8774/v2"
set_conf "neutron.conf" "DEFAULT" "nova_admin_username" "nova"
set_conf "neutron.conf" "DEFAULT" "nova_admin_tenant_id" $(keystone tenant-list | awk '/ service / { print $2 }')
set_conf "neutron.conf" "DEFAULT" "nova_admin_password" $service_pass
set_conf "neutron.conf" "DEFAULT" "nova_admin_auth_url" "http://$controller_hostname:35357/v2.0"
set_conf "neutron.conf" "DEFAULT" "core_plugin" "ml2"
set_conf "neutron.conf" "DEFAULT" "service_plugins" "router"

# set ml2 config
set_conf "ml2_conf.ini" "ml2" "type_drivers" "local,flat,vlan,vxlan"
set_conf "ml2_conf.ini" "ml2" "tenant_network_types" "vlan"
set_conf "ml2_conf.ini" "ml2" "mechanism_drivers" "openvswitch"
set_conf "ml2_conf.ini" "ml2_type_flat" "flat_networks" "physnet2,physnet3"
set_conf "ml2_conf.ini" "ml2_type_vlan" "network_vlan_ranges" "physnet1:100:200"
#set_conf "ml2_conf.ini" "ml2_type_vxlan" "vni_ranges" "1001:2000"
#set_conf "ml2_conf.ini" "ml2_type_vxlan" "vxlan_group" "239.1.1.1"
set_conf "ml2_conf.ini" "securitygroup" "firewall_driver" "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
set_conf "ml2_conf.ini" "securitygroup" "enable_security_group" "True"
set_conf "ml2_conf.ini" "ovs" "enable_tunneling" "True"
set_conf "ml2_conf.ini" "agent" "tunnel_types" "vlan"

# set nova.conf to use neutorn networking
set_conf "nova.conf" "DEFAULT" "network_api_class" "nova.network.neutronv2.api.API"
set_conf "nova.conf" "DEFAULT" "neutron_url" "http://$controller_hostname:9696"
set_conf "nova.conf" "DEFAULT" "neutron_auth_strategy" "keystone"
set_conf "nova.conf" "DEFAULT" "neutron_admin_tenant_name" "service"
set_conf "nova.conf" "DEFAULT" "neutron_admin_username" "neutron"
set_conf "nova.conf" "DEFAULT" "neutron_admin_password" $service_pass
set_conf "nova.conf" "DEFAULT" "neutron_admin_auth_url" "http://$controller_hostname:35357/v2.0"
set_conf "nova.conf" "DEFAULT" "linuxnet_interface_driver" "nova.network.linux_net.LinuxOVSInterfaceDriver"
set_conf "nova.conf" "DEFAULT" "firewall_driver" "nova.virt.firewall.NoopFirewallDriver"
set_conf "nova.conf" "DEFAULT" "security_group_api" "neutron"

# add soft link 
ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
logg "added soft link for neutron plugin"
ls -al /etc/neutron/ | grep "plugin.ini"

logg "restarting nova api, nova scheduler, nova conductor to comply changed configurations on nova.conf"
for i in openstack-nova-{api,scheduler,conductor};do
        service $i restart
done
# check:: is nova process restarted
ps -ef | grep nova

logg "starting neutron server"
clear_conf $conf_neutron
clear_conf $conf_ml2
service_handle "neutron-server"
# check:: is neutron server started
ps -ef | grep neutron-server

# check:: is database created 
#       neuron database is created when neutron server is started AT EVERYTIME (dynamically created)
logg "check:: is database created?"
db_query "mysql" "show databases"
sleep 4
logg "check:: is tables created?"
db_query "neutron" "show tables"

logg "check:: show neutron conf"
grep -v '^#\|^\s*$' $conf_neutron
grep -v '^#\|^\s*$' $conf_ml2

logg "check:: show nova conf"
grep -v '^#\|^\s*$' $conf_nova

###########################################
#
# horizon dashboard
#
##########################################
logg_big "horizon dashboard"

logg "install dashboard components"
yum -y install memcached python-memcached mod_wsgi openstack-dashboard

# set dashboard config file
hconf="/etc/openstack-dashboard/local_settings"
sed -i "s/ALLOWED_HOSTS = \['horizon.example.com', 'localhost'\]/ALLOWED_HOSTS=['*']/g" $hconf
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"$controller_ip_mng\"/g" $hconf
sed -i "s/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"Member\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE= \"admin\"/g" $hconf

logg "starting httpd"
service_handle "httpd"
service_handle "memcached"
# check:: process of httpd and memcached
ps -ef | grep httpd
ps -ef | grep memcached
