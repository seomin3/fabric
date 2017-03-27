#!/bin/bash
###############################
#
# user settings
#
###############################

# Password
admin_token='admin_token'
admin_pass='admin_pass'
database_user='openstack'
database_pass='database_pass'
service_pass='service_pass'
metadata_pass='metadata_secret'

# FIXME
controller_hostname='192.168.1.42'
glance_hostname='192.168.1.181'
controller_ip_external=$controller_hostname
controller_ip_public=$controller_hostname
compute_ip_mng='192.168.1.190'
compute_ip_data=$compute_ip_mng

# local ip check
if [ "$(basename $0| grep agent_ > /dev/null ; echo $?)" -ne '0' ]; then
    for i in $compute_ip_mng $compute_ip_data; do
        echo "compute ip checking $i"
        ifconfig | grep -v grep | grep $i > /dev/null
        cmd_check $?
    done
fi


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

# local repository file
mkdir -p /etc/yum.repos.d/old
find /etc/yum.repos.d/ -maxdepth 1 -type f \( ! -iname "local-cent6.repo" \) -exec mv -f {} /etc/yum.repos.d/old \;
#cp -f ./local-centos6.repo /etc/yum.repos.d/

# install EPEL repo and RDO repo
#install_pkgs 'http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-3.noarch.rpm http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'

# install basic packages on Controller Node
install_pkgs 'ntp mysql MySQL-python openstack-utils telnet openstack-selinux'

#ntpd
service_handle ntpd
logg "ntpd service started and registered"
