#!/bin/bash
source ./include/fuction.sh
source ./include/controller.sh

###########################################
#
# neutron (server)
#
##########################################
logg_big "neutron"

logg "install neutron server rpms"
install_pkgs 'openstack-neutron openstack-neutron-ml2 python-neutronclient'

logg "create database and database user for neutron"
create_database "neutron"

keystone user-create --name neutron --pass $service_pass --email neutron@example.com
keystone user-role-add --user neutron --tenant service --role admin

logg "register neutron service and endpoint to keystone"
keystone service-get neutron > /dev/null
if [ "$?" -ne "0" ]
then
	keystone service-create --name neutron --type network --description "OpenStack Networking Service"
	keystone endpoint-create \
	 --service-id $(keystone service-list | awk '/ network / {print $2}')  \
	 --publicurl http://$controller_hostname:9696 \
	 --adminurl http://$controller_hostname:9696 \
	 --internalurl http://$controller_hostname:9696
fi

# set basic configurations for neutron.conf
set_conf "neutron.conf" "database" "connection" "mysql://neutron:$database_pass@$database_hostname/neutron"
set_conf "neutron.conf" "DEFAULT" "auth_strategy" "keystone"
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
set_conf "neutron.conf" "DEFAULT" "max_fixed_ips_per_port" "100"
set_conf "neutron.conf" "DEFAULT" "dhcp_agents_per_network" "10000"
set_conf "neutron.conf" "keystone_authtoken" "auth_host" $controller_hostname
set_conf "neutron.conf" "keystone_authtoken" "auth_protocol" "http"
set_conf "neutron.conf" "keystone_authtoken" "auth_port" "35357"
set_conf "neutron.conf" "keystone_authtoken" "admin_tenant_name" "service"
set_conf "neutron.conf" "keystone_authtoken" "admin_user" "neutron"
set_conf "neutron.conf" "keystone_authtoken" "admin_password" $service_pass

# /etc/neutron/plugins/ml2/ml2_conf.ini
set_conf 'ml2_conf.ini' "ml2" "type_drivers" "local,flat,vlan,vxlan"
set_conf 'ml2_conf.ini' "ml2" "tenant_network_types" "vlan"
set_conf 'ml2_conf.ini' "ml2" "mechanism_drivers" "openvswitch"
set_conf 'ml2_conf.ini' "ml2_type_flat" "flat_networks" "physnet0"
set_conf 'ml2_conf.ini' "ml2_type_vlan" "network_vlan_ranges" "physnet2:1024:2048"
set_conf 'ml2_conf.ini' "securitygroup" "firewall_driver" "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
set_conf 'ml2_conf.ini' "securitygroup" "enable_security_group" "True"
set_conf 'ml2_conf.ini' "ovs" "tenant_network_type" "vlan"
set_conf 'ml2_conf.ini' "ovs" "integration_bridge" "br-int"
#set_conf 'ml2_conf.ini' "ovs" "enable_tunneling" "True"
#set_conf 'ml2_conf.ini' "ovs" "tunnel_type" "vlan"
#set_conf 'ml2_conf.ini' "ovs" "tunnel_id_ranges" "100:199"
#set_conf 'ml2_conf.ini' "ovs" "integration_bridge" "br-int"
#set_conf 'ml2_conf.ini' "ovs" "tunnel_bridge" "br-tun"
#set_conf 'ml2_conf.ini' "ovs" "local_ip" $compute_ip_data
set_conf 'ml2_conf.ini' "ovs" "network_vlan_ranges" "physnet0:2:2,physnet2:1024:2048"
set_conf 'ml2_conf.ini' "ovs" "bridge_mappings" "physnet0:br-flat,physnet2:br-vlan"
#set_conf 'ml2_conf.ini' "agent" "tunnel_types" "vlan"

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
#set_conf "nova.conf" "DEFAULT" "service_neutron_metadata_proxy" "True"
#set_conf "nova.conf" "DEFAULT" "neutron_metadata_proxy_shared_secret" "metadata_secret"
set_conf "nova.conf" "DEFAULT" "allow_resize_to_same_host" "True"
#set_conf "nova.conf" "DEFAULT" "resize_confirm_window" "5"

# add soft link
ln -fs plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
logg "added soft link for neutron plugin"
ls -al /etc/neutron/ | grep "plugin.ini"

logg "restarting nova api, nova scheduler, nova conductor to comply changed configurations on nova.conf"
for i in openstack-nova-{api,scheduler,conductor};do
        service $i restart
done

logg "starting neutron server"
clear_conf $conf_neutron
clear_conf $conf_ml2
service_handle "neutron-server"

# check:: is database created
#       neuron database is created when neutron server is started AT EVERYTIME (dynamically created)
logg "check:: is tables created?"
db_query "neutron" "show tables"
cmd_check $?

logg "check:: show neutron conf"
grep -v '^#\|^\s*$' $conf_neutron
logg "check:: show ml2 conf"
grep -v '^#\|^\s*$' $conf_ml2

logg "check:: show nova conf"
grep -v '^#\|^\s*$' $conf_nova
