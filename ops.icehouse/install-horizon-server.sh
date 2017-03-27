#!/bin/bash
source ./include/fuction.sh
source ./include/controller.sh

###########################################
#
# horizon dashboard
#
##########################################
logg_big "horizon dashboard"

logg "install dashboard components"
install_pkgs 'memcached python-memcached mod_wsgi openstack-dashboard'

# set dashboard config file
hconf="/etc/openstack-dashboard/local_settings"
sed -i "s/ALLOWED_HOSTS = \['horizon.example.com', 'localhost'\]/ALLOWED_HOSTS=['*']/g" $hconf
sed -i "s/OPENSTACK_HOST = \"\"/OPENSTACK_HOST = \"$controller_ip_vnc\"/g" $hconf
#sed -i "s/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"_member_\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE= \"_admin_\"/g" $hconf

logg "starting httpd"
service_handle "httpd"
service_handle "memcached"
