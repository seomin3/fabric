#!/bin/bash

source def_controller.sh
source inc_compute.sh

###################################
# Firewall
#       for Openstack Operations
###################################

#for compute vnc
set_iptables '5900:6100'
#for vxlan
set_iptables '4789'

##################################
# Installing and setting configurations
#       for Compute On Compute node
###################################

# package install
install_pkgs 'openstack-nova-compute iproute tcpdump libguestfs-tools'

logg 'set nova-compute configureation'
# /etc/nova/nova.conf
set_conf 'nova.conf' 'database' 'connection' "mysql://nova:$database_pass@$controller_hostname/nova"
set_conf 'nova.conf' 'DEFAULT' 'allow_resize_to_same_host' 'true'
set_conf 'nova.conf' 'DEFAULT' 'api_paste_config' 'api-paste.ini'
set_conf 'nova.conf' 'DEFAULT' 'auth_strategy' 'keystone'
set_conf 'nova.conf' 'DEFAULT' 'firewall_driver' 'nova.virt.firewall.NoopFirewallDriver'
set_conf 'nova.conf' 'DEFAULT' 'glance_host' $glance_hostname
set_conf 'nova.conf' 'DEFAULT' 'linuxnet_interface_driver' 'nova.network.linux_net.LinuxOVSInterfaceDriver'
set_conf 'nova.conf' 'DEFAULT' 'my_ip' $compute_ip_mng
set_conf 'nova.conf' 'DEFAULT' 'network_api_class' 'nova.network.neutronv2.api.API'
set_conf 'nova.conf' 'DEFAULT' 'neutron_admin_auth_url' "http://$controller_hostname:35357/v2.0"
set_conf 'nova.conf' 'DEFAULT' 'neutron_admin_password' $service_pass
set_conf 'nova.conf' 'DEFAULT' 'neutron_admin_tenant_name' 'service'
set_conf 'nova.conf' 'DEFAULT' 'neutron_admin_username' 'neutron'
set_conf 'nova.conf' 'DEFAULT' 'neutron_auth_strategy' 'keystone'
set_conf 'nova.conf' 'DEFAULT' 'neutron_url' "http://$controller_hostname:9696"
set_conf 'nova.conf' 'DEFAULT' 'novncproxy_base_url' "http://$controller_ip_external:6080/vnc_auto.html"
set_conf 'nova.conf' 'DEFAULT' 'rabbit_host' $controller_hostname
set_conf 'nova.conf' 'DEFAULT' 'rpc_backend' 'rabbit'
set_conf 'nova.conf' 'DEFAULT' 'security_group_api' 'neutron'
set_conf 'nova.conf' 'DEFAULT' 'vnc_enabled' 'True'
set_conf 'nova.conf' 'DEFAULT' 'vncserver_listen' '0.0.0.0'
set_conf 'nova.conf' 'DEFAULT' 'vncserver_proxyclient_address' $compute_ip_mng
#set_conf 'nova.conf' 'DEFAULT' 'libvirt_inject_key' 'true'
#set_conf 'nova.conf' 'DEFAULT' 'libvirt_inject_partition' '-1'
#set_conf 'nova.conf' 'DEFAULT' 'libvirt_inject_password' 'true'
#set_conf 'nova.conf' 'DEFAULT' 'libvirt_type' 'kvm'
#set_conf 'nova.conf' 'DEFAULT' 'resize_confirm_window' '5'
set_conf 'nova.conf' 'DEFAULT' 'scheduler_default_filters' 'AllHostsFilter'
set_conf 'nova.conf' 'DEFAULT' 'vif_plugging_is_fatal ' 'false'
set_conf 'nova.conf' 'DEFAULT' 'vif_plugging_timeout ' '10'
set_conf 'nova.conf' 'keystone_authtoken' 'admin_password' $service_pass
set_conf 'nova.conf' 'keystone_authtoken' 'admin_tenant_name' 'service'
set_conf 'nova.conf' 'keystone_authtoken' 'admin_user' 'nova'
set_conf 'nova.conf' 'keystone_authtoken' 'auth_host' $controller_hostname
set_conf 'nova.conf' 'keystone_authtoken' 'auth_port' '35357'
set_conf 'nova.conf' 'keystone_authtoken' 'auth_protocol' 'http'
set_conf 'nova.conf' 'zookeeper' 'cinder_catalog_info' 'volume:cinder:adminURL'
set_conf 'nova.conf' 'zookeeper' 'enabled_apis' 'ec2,osapi_compute,metadata'
set_conf 'nova.conf' 'zookeeper' 'iscsi_helper' 'tgtadm'
set_conf 'nova.conf' 'zookeeper' 'volume_api_class' 'nova.volume.cinder.API'
set_conf 'nova.conf' 'zookeeper' 'volume_manager' 'cinder.volume.manager.VolumeManager'

# /etc/nova/api-paste.ini
set_conf 'api-paste.ini' 'filter:authtoken' 'admin_password' $service_pass
set_conf 'api-paste.ini' 'filter:authtoken' 'admin_tenant_name' 'service'
set_conf 'api-paste.ini' 'filter:authtoken' 'admin_user' 'nova'
set_conf 'api-paste.ini' 'filter:authtoken' 'auth_host' $controller_hostname
set_conf 'api-paste.ini' 'filter:authtoken' 'auth_port' '35357'
set_conf 'api-paste.ini' 'filter:authtoken' 'auth_protocol' 'http'

logg 'start nova-compute'
# service
service_handle 'libvirtd'
service_handle 'messagebus'
service_handle 'openstack-nova-compute'

##################################
# Installing and setting configurations
#       for Neutron (Agents) On Compute node
###################################

# kernel parameter
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sed -i 's/net.ipv4.conf.default.rp_filter = 1/net.ipv4.conf.default.rp_filter=0/g' /etc/sysctl.conf
sysctl -p

logg 'install neutron'
# install and set plugin
install_pkgs 'openstack-neutron-ml2 openstack-neutron-openvswitch'
# install iproute from elel repo ( iproute-2.6.32-130.el6ost.netns.2.x86_64 )
install_pkgs 'iproute'
# install openstack neutron
install_pkgs 'openstack-neutron'

logg 'start neutron'
# service
#for i in neutron-{dhcp,metadata}-agent
#do
#    service_handle $i
#done

logg 'set neutron configureation'
# /etc/neutron/neutron.conf'
set_conf 'neutron.conf' 'DEFAULT' 'auth_strategy' 'keystone'
set_conf 'neutron.conf' 'DEFAULT' 'rpc_backend' 'neutron.openstack.common.rpc.impl_kombu'
set_conf 'neutron.conf' 'DEFAULT' 'rabbit_host' $controller_hostname
set_conf 'neutron.conf' 'DEFAULT' 'core_plugin' 'ml2'
set_conf 'neutron.conf' 'DEFAULT' 'service_plugins' 'router'
set_conf 'neutron.conf' 'keystone_authtoken' 'admin_password' $service_pass
set_conf 'neutron.conf' 'keystone_authtoken' 'admin_tenant_name' 'service'
set_conf 'neutron.conf' 'keystone_authtoken' 'admin_user' 'neutron'
set_conf 'neutron.conf' 'keystone_authtoken' 'auth_uri' "http://$controller_hostname:5000"
set_conf 'neutron.conf' 'keystone_authtoken' 'auth_host' $controller_hostname
set_conf 'neutron.conf' 'keystone_authtoken' 'auth_protocol' 'http'
set_conf 'neutron.conf' 'keystone_authtoken' 'auth_port' '35357'
set_conf 'neutron.conf' 'keystone_authtoken' 'identity_uri' "http://$controller_hostname:35357"
set_conf 'neutron.conf' 'service_providers' 'service_provider' 'VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default'

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

# /etc/neutron/dhcp_agent.ini
set_conf 'dhcp_agent.ini' 'DEFAULT' 'interface_driver' 'neutron.agent.linux.interface.OVSInterfaceDriver'
set_conf 'dhcp_agent.ini' 'DEFAULT' 'dhcp_driver' 'neutron.agent.linux.dhcp.Dnsmasq'
set_conf 'dhcp_agent.ini' 'DEFAULT' 'enable_isolated_metadata' 'true'

# /etc/neutron/metadata_agent.ini
set_conf 'metadata_agent.ini' 'DEFAULT' 'auth_url' "http://$controller_hostname:5000/v2.0"
set_conf 'metadata_agent.ini' 'DEFAULT' 'auth_region' 'regionOne'
set_conf 'metadata_agent.ini' 'DEFAULT' 'admin_tenant_name' 'service'
set_conf 'metadata_agent.ini' 'DEFAULT' 'admin_user' 'neutron'
set_conf 'metadata_agent.ini' 'DEFAULT' 'admin_password' $service_pass
set_conf 'metadata_agent.ini' 'DEFAULT' 'nova_metadata_ip' $controller_ip_public
set_conf 'metadata_agent.ini' 'DEFAULT' 'metadata_proxy_shared_secret' $metadata_pass

# /etc/nova/nova.conf

clear_conf $conf_neutron
clear_conf $conf_nova
ln -sf /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

# set ports
logg 'bridge interface'
service_handle 'openvswitch'
# bridge
ovs-vsctl add-br br-int
ovs-vsctl add-br br-flat
ovs-vsctl add-br br-vlan
ovs-vsctl add-port br-vlan eth2
#ovs-vsctl add-port br-eth1.11 eth1.11
#ovs-vsctl add-br br-eth1.12
#ovs-vsctl add-port br-eth1.12 eth1.12

# set service
logg 'start service'
service_handle 'openstack-nova-compute'
service_handle 'neutron-openvswitch-agent'
#for i in neutron-{dhcp,metadata,openvswitch}-agent
#do
#    service_handle $i
#done

logg 'generating credentails to /root/creds'
echo "export OS_USERNAME=admin
export OS_PASSWORD=$admin_pass
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$controller_hostname:35357/v2.0
" > /root/openrc.sh
ls -al /root/ | grep 'openrc.sh'
cp /root/openrc.sh /etc/profile.d/

# openstack status
logg_big 'openstack status'
openstack-status
