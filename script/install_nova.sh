#!/bin/bash
###############################
#
# user settings
#
###############################

database_pass='database_pass'
admin_pass='admin_pass'
service_pass='service_pass'
metadata_pass='metadata_secret'

controller_hostname='192.168.122.22'
compute_ip_mng=''
compute_ip_data='192.168.1.'
controller_ip_external='192.168.122.22'
controller_ip_public='192.168.122.22'

###############################
#
# common functions
#
###############################

service_handle(){
    systemctl restart $1
	systemctl enable $1
	systemctl status $1
	[ ! $? ] && exit 1
}

logg_big(){
        echo ""
        echo ""
        echo "###############################################################################"
        echo "#"
        echo "#"
        echo "#" $1
        echo "#"
        echo "#"
        echo "###############################################################################"
        echo ""
        echo ""

}

## logging
logg(){
        echo ""
        echo ""
        echo "##############################"
        echo "#" $1
        echo "##############################"
        echo ""
        echo ""
}

# $1 : conf file name
# $2 : options
# $3 : key
# $4 : value
set_conf(){
        openstack-config --set $1 $2 $3 $4
}
# Remove duplicated [DEFAULT] String on a text file
# $1 : file name
clearconf(){
        sed -i ':a;N;$!ba;s/FAULT\]\n\[DE//g' $1
}

###################################
# Installing and setting configurations 
#       for Basic Packages
###################################

#install EPEL repo and RDO repo
[ ! -f /etc/yum.repos.d/rdo-release.repo ] && yum -y -q install http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-1.noarch.rpm
[ ! -f /etc/yum.repos.d/epel.repo ] && yum -y -q install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-1.noarch.rpm

#install basic packages on Controller Node
yum -y install ntp mysql MySQL-python openstack-utils telnet openstack-selinux wget

#ntpd
service_handle ntpd

###################################
# Firewall
#       for Openstack Operations
###################################

#for compute vnc
iptables -A INPUT -p tcp -m tcp --dport 5900:6100 -j ACCEPT

#for vxlan
iptables -A INPUT -p udp -m udp --dport 4789 -j ACCEPT 

##################################
# Installing and setting configurations
#       for Compute On Compute node
###################################

yum -y install openstack-nova-compute

ocnf=/etc/nova/nova.conf
set_conf $ocnf "database" "connection" "mysql://nova:$database_pass@$controller_hostname/nova"
set_conf $ocnf "DEFAULT" "auth_strategy" "keystone"
set_conf $ocnf "keystone_authtoken" "auth_host" $controller_hostname
set_conf $ocnf "keystone_authtoken" "auth_uri" "http://$controller_hostname:5000"
set_conf $ocnf "keystone_authtoken" "auth_protocol" "http"
set_conf $ocnf "keystone_authtoken" "auth_port" "35357"
set_conf $ocnf "keystone_authtoken" "admin_user" "nova"
set_conf $ocnf "keystone_authtoken" "admin_tenant_name" "service"
set_conf $ocnf "keystone_authtoken" "admin_password" $service_pass
set_conf $ocnf "DEFAULT" "rpc_backend" "rabbit"
set_conf $ocnf "DEFAULT" "rabbit_host" $controller_hostname
set_conf $ocnf "DEFAULT" "my_ip" $compute_ip_mng
set_conf $ocnf "DEFAULT" "vnc_enabled" "True"
set_conf $ocnf "DEFAULT" "vncserver_listen" "0.0.0.0"
set_conf $ocnf "DEFAULT" "vncserver_proxyclient_address" $compute_ip_mng 
set_conf $ocnf "DEFAULT" "novncproxy_base_url" "http://$controller_ip_external:6080/vnc_auto.html"
set_conf $ocnf "DEFAULT" "glance_host" $controller_hostname
set_conf $ocnf "DEFAULT" "allow_resize_to_same_host" "true"
set_conf $ocnf "DEFAULT" "api_paste_config" "api-paste.ini"
clearconf $ocnf
ocnf=/etc/nova/api-paste.ini
set_conf $ocnf "filter:authtoken" "auth_host" $controller_hostname
set_conf $ocnf "filter:authtoken" "auth_port" "35357"
set_conf $ocnf "filter:authtoken" "auth_protocol" "http"
set_conf $ocnf "filter:authtoken" "admin_tenant_name" "service"
set_conf $ocnf "filter:authtoken" "admin_user" "nova"
set_conf $ocnf "filter:authtoken" "admin_password" $service_pass

service_handle libvirtd
service_handle messagebus
service_handle openstack-nova-compute

##################################
# Installing and setting configurations
#       for Neutron (Agents) On Compute node
###################################

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sed -i 's/net.ipv4.conf.default.rp_filter = 1/net.ipv4.conf.default.rp_filter=0/g' /etc/sysctl.conf
sysctl -p

#install and set plugin
yum -y install openstack-neutron-ml2 openstack-neutron-openvswitch

#install iproute from elel repo ( iproute-2.6.32-130.el6ost.netns.2.x86_64 )
yum -y install iproute

#install openstack neutron
yum -y install openstack-neutron
for s in neutron-{dhcp,metadata}-agent; do chkconfig $s on; done

ocnf="/etc/neutron/neutron.conf"
set_conf $ocnf "keystone_authtoken" "auth_host" $controller_hostname
set_conf $ocnf "keystone_authtoken" "auth_uri" "http://$controller_hostname:5000"
set_conf $ocnf "keystone_authtoken" "auth_protocol" "http"
set_conf $ocnf "keystone_authtoken" "auth_port" "35357"
set_conf $ocnf "keystone_authtoken" "admin_tenant_name" "service"
set_conf $ocnf "keystone_authtoken" "admin_user" "neutron"
set_conf $ocnf "keystone_authtoken" "admin_password" $service_pass
set_conf $ocnf "DEFAULT" "auth_strategy" "keystone"

set_conf $ocnf "DEFAULT" "rpc_backend" "neutron.openstack.common.rpc.impl_kombu"
set_conf $ocnf "DEFAULT" "rabbit_host" $controller_hostname

set_conf $ocnf "DEFAULT" "core_plugin" "ml2"
set_conf $ocnf "DEFAULT" "service_plugins" "router"
set_conf $ocnf "service_providers" "service_provider" "VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default"

ocnf="/etc/neutron/plugins/ml2/ml2_conf.ini"
set_conf $ocnf "ml2" "type_drivers" "local,flat,vlan,vxlan"
set_conf $ocnf "ml2" "tenant_network_types" "vlan"
set_conf $ocnf "ml2" "mechanism_drivers" "openvswitch"
set_conf $ocnf "ml2_type_flat" "flat_networks" "physnet0"
set_conf $ocnf "ml2_type_vlan" "network_vlan_ranges" "physnet2:100:199"
set_conf $ocnf "securitygroup" "firewall_driver" "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
set_conf $ocnf "securitygroup" "enable_security_group" "True"

set_conf $ocnf "ovs" "tenant_network_type" "vlan"
set_conf $ocnf "ovs" "integration_bridge" "br-int"
#set_conf $ocnf "ovs" "enable_tunneling" "True"
#set_conf $ocnf "ovs" "tunnel_type" "vlan"
#set_conf $ocnf "ovs" "tunnel_id_ranges" "100:199"
#set_conf $ocnf "ovs" "integration_bridge" "br-int"
#set_conf $ocnf "ovs" "tunnel_bridge" "br-tun"
#set_conf $ocnf "ovs" "local_ip" $compute_ip_data
set_conf $ocnf "ovs" "network_vlan_ranges" "physnet0:2:2,physnet2:100:199"
set_conf $ocnf "ovs" "bridge_mappings" "physnet0:br-flat,physnet2:br-vlan"
#set_conf $ocnf "agent" "tunnel_types" "vlan"

#settings for dhcp 
ocnf="/etc/neutron/dhcp_agent.ini"
set_conf $ocnf "DEFAULT" "interface_driver" "neutron.agent.linux.interface.OVSInterfaceDriver"
set_conf $ocnf "DEFAULT" "dhcp_driver" "neutron.agent.linux.dhcp.Dnsmasq"
set_conf $ocnf "DEFAULT" "enable_isolated_metadata" "true"
clearconf $ocnf

#settings for metadata
ocnf="/etc/neutron/metadata_agent.ini"
set_conf $ocnf "DEFAULT" "auth_url" "http://$controller_hostname:5000/v2.0"
set_conf $ocnf "DEFAULT" "auth_region" "regionOne"
set_conf $ocnf "DEFAULT" "admin_tenant_name" "service"
set_conf $ocnf "DEFAULT" "admin_user" "neutron"
set_conf $ocnf "DEFAULT" "admin_password" $service_pass
set_conf $ocnf "DEFAULT" "nova_metadata_ip" $controller_ip_public
set_conf $ocnf "DEFAULT" "metadata_proxy_shared_secret" $metadata_pass
clearconf $ocnf

ocnf="/etc/nova/nova.conf"
set_conf $ocnf "DEFAULT" "network_api_class" "nova.network.neutronv2.api.API"
set_conf $ocnf "DEFAULT" "neutron_url" "http://$controller_hostname:9696"
set_conf $ocnf "DEFAULT" "neutron_auth_strategy" "keystone"
set_conf $ocnf "DEFAULT" "neutron_admin_tenant_name" "service"
set_conf $ocnf "DEFAULT" "neutron_admin_username" "neutron"
set_conf $ocnf "DEFAULT" "neutron_admin_password" $service_pass
set_conf $ocnf "DEFAULT" "neutron_admin_auth_url" "http://$controller_hostname:35357/v2.0"
set_conf $ocnf "DEFAULT" "linuxnet_interface_driver" "nova.network.linux_net.LinuxOVSInterfaceDriver"
set_conf $ocnf "DEFAULT" "firewall_driver" "nova.virt.firewall.NoopFirewallDriver"
set_conf $ocnf "DEFAULT" "security_group_api" "neutron"

clearconf "/etc/neutron/neutron.conf"
clearconf "/etc/nova/nova.conf"

#vxlan bug patch
if grep -irnq "= get_installed_ovs_klm_version()" /usr/lib/python2.6/site-packages/neutron/agent/linux/ovs_lib.py ;then
  sed -i 's,=\ get_installed_ovs_klm_version(),=\ \"1\.11\",g' /usr/lib/python2.6/site-packages/neutron/agent/linux/ovs_lib.py
fi

ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

#set ports 
service_handle openvswitch
ovs-vsctl add-br br-int

#ovs-vsctl add-br br-eth1.11
#ovs-vsctl add-port br-eth1.11 eth1.11

#ovs-vsctl add-br br-eth1.12
#ovs-vsctl add-port br-eth1.12 eth1.12

#ovs-vsctl add-br br-eth2
#ovs-vsctl add-port br-eth2 eth2

service_handle openstack-nova-compute
service_handle neutron-openvswitch-agent

service_handle neutron-dhcp-agent
#service_handle neutron-l3-agent restart
service_handle neutron-metadata-agent
service_handle neutron-openvswitch-agent