#!/bin/bash

source def_controller.sh
source inc_controller.sh

########################################
# Installing and setting configurations
#       for Swift Controller
########################################

source /etc/profile.d/openrc.sh

# user create and add role
keystone user-create --name=swift --pass=$service_pass --email=swift@example.com
keystone user-role-add --user=swift --tenant=service --role=admin
logg "user create and role add finish!"

# swift service create
keystone service-create --name=swift --type=object-store --description="Object Storage Service"
logg "swift service create finish!"

# swift endpoint create
keystone endpoint_create "object-store" "http://$swift_proxy_ip:8080"  "http://$swift_proxy_ip:8080/v1/AUTH_%(tenant_id)s"  "http://$swift_proxy_ip:8080/v1/AUTH_%(tenant_id)s" 
logg "swift endpoint create finish!"


###################################
# Installing and setting configurations 
#       for Basic Packages
###################################

#package install
install_pkgs 'openstack-swift openstack-swift-proxy memcached python-swiftclient python-keystone-auth-token'

mkdir -p /etc/swift
chown -R swift:swift /etc/swift/

echo [swift-hash] >> /etc/swift/swift.conf
echo # random unique strings that can never change (DO NOT LOSE) >> /etc/swift/swift.conf
echo swift_hash_path_prefix = `od -t x8 -N 8 -A n </dev/random` >> /etc/swift/swift.conf
echo swift_hash_path_suffix = `od -t x8 -N 8 -A n </dev/random` >> /etc/swift/swift.conf


#setting memcache ip and restart 
perl -pi -e "s/-l 0.0.0.0/-l $local_ip/" /etc/sysconfig/memcached
service memcached restart
chkconfig memcached on

set_conf 'proxy-server.conf' "filter:authtoken" "admin_token" $admin_token
set_conf 'proxy-server.conf' "filter:authtoken" "auth_token" $admin_token

# keystone auth info configuration
set_conf 'proxy-server.conf' "filter:authtoken" "auth_host" $controller_hostname
set_conf 'proxy-server.conf' "filter:authtoken" "admin_user" "swift"
set_conf 'proxy-server.conf' "filter:authtoken" "admin_tenant_name" "service"
set_conf 'proxy-server.conf' "filter:authtoken" "admin_password" $service_pass
set_conf 'proxy-server.conf' "filter:authtoken" "auth_protocol" "http"
set_conf 'proxy-server.conf' "filter:authtoken" "auth_port" "35357"
set_conf 'proxy-server.conf' "filter:authtoken" "auth_uri" "http://$controller_hostname:5000/"
logg "keystone auth setting finish!"


# sample 3 node ring builder script
#cd /etc/swift

#rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

#swift-ring-builder object.builder create 18 3 1
#swift-ring-builder object.builder add z1-172.16.76.141:6000/sdb1 100
#swift-ring-builder object.builder add z1-172.16.76.142:6000/sdb1 100
#swift-ring-builder object.builder add z1-172.16.76.143:6000/sdb1 100
#swift-ring-builder object.builder rebalance
#swift-ring-builder container.builder create 18 3 1
#swift-ring-builder container.builder add z1-172.16.76.141:6001/sdb1 100
#swift-ring-builder container.builder add z1-172.16.76.142:6001/sdb1 100
#swift-ring-builder container.builder add z1-172.16.76.143:6001/sdb1 100
#swift-ring-builder container.builder rebalance
#swift-ring-builder account.builder create 18 3 1
#swift-ring-builder account.builder add z1-172.16.76.141:6002/sdb1 100
#swift-ring-builder account.builder add z1-172.16.76.142:6002/sdb1 100
#swift-ring-builder account.builder add z1-172.16.76.143:6002/sdb1 100
#swift-ring-builder account.builder rebalance
#instlog "ring builder setting finish!"

# swift service start
#service openstack-swift-proxy start
#chkconfig openstack-swift-proxy on

