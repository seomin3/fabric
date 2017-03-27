#!/bin/bash

##############################
#
# user settings
#
###############################

# Password
database_user='root'
database_pass='Tmysql12@'
admin_token='admin_token'
admin_pass='admin_pass'
service_pass='service_pass'
metadata_pass='metadata_secret'

# FIXME
controller_hostname='172.16.10.152'
glance_hostname=$controller_hostname
cinder_hostname=$controller_hostname
swift_hostname=$controller_hostname
controller_ip_vnc=$controller_hostname
database_hostname=$controller_hostname

###############################
#
# static variables
#
###############################

conf_mysql='/etc/my.cnf'
conf_keystone='/etc/keystone/keystone.conf'
conf_glance_api='/etc/glance/glance-api.conf'
conf_glance_registry='/etc/glance/glance-registry.conf'
conf_nova='/etc/nova/nova.conf'
conf_nova_api='/etc/nova/api-paste.ini'
conf_neutron='/etc/neutron/neutron.conf'
conf_meta='/etc/neutron/metadata_agent.ini'
conf_ml2='/etc/neutron/plugins/ml2/ml2_conf.ini'
conf_dhcp='/etc/neutron/dhcp_agent.ini'
conf_cinder='/etc/cinder/cinder.conf'
conf_ceilometer='/etc/ceilometer/ceilometer.conf'

###################################
# Installing and setting configurations
#       for Basic Packages
###################################

# install basic packages on Controller Node
install_pkgs 'ntp mysql MySQL-python openstack-utils telnet openstack-selinux'

#ntpd
service_handle ntpd
logg "ntpd service started and registered"

# openrc.sh
openrc='/root/admin-openrc.sh'
if [ ! -f $openrc ]; then
    logg "generating credentails to /root/creds"
    
    echo 'export OS_USERNAME=admin' >> $openrc
    echo "export OS_PASSWORD=$admin_pass" >> $openrc
    echo 'export OS_TENANT_NAME=admin' >> $openrc
    echo "export OS_AUTH_URL=http://$controller_hostname:35357/v2.0" >> $openrc
    cat $openrc >> /root/.bashrc
    for i in cloud sysop; do
    	bashrc="/home/$i/.bashrc"
    	[ -f $bashrc ] && cat $openrc >> $bashrc && cp $openrc /home/$i
    done
fi
source /root/admin-openrc.sh

# openstack client
install_pkgs 'python-ceilometerclient python-cinderclient python-glanceclient python-keystoneclient python-neutronclient python-novaclient'
#install_pkgs 'python-ceilometerclient python-cinderclient python-glanceclient python-heatclient python-keystoneclient python-neutronclient python-novaclient python-swiftclient python-troveclient'
