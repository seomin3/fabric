#!/bin/bash
###############################
#
# user settings
#
###############################

admin_token="admin_token"
admin_pass="admin_pass"
database_pass="database_pass"
service_pass="service_pass"

controller_hostname="192.168.122.22"
controller_ip_mng="192.168.122.22"

###############################
#
# static variables 
#
###############################

conf_mysql="/etc/my.cnf"
conf_keystone="/etc/keystone/keystone.conf"
conf_glance_api="/etc/glance/glance-api.conf"
conf_glance_registry="/etc/glance/glance-registry.conf"
conf_nova="/etc/nova/nova.conf"
conf_neutron="/etc/neutron/neutron.conf"
conf_ml2="/etc/neutron/plugins/ml2/ml2_conf.ini"

###################################
# Installing and setting configurations 
#       for Basic Packages
###################################

#install EPEL repo and RDO repo
[ ! -f /etc/yum.repos.d/rdo-release.repo ] && yum -y -q install http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/rdo-release-icehouse-1.noarch.rpm
[ ! -f /etc/yum.repos.d/epel.repo ] && yum -y -q install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-1.noarch.rpm

[ -f /etc/yum.repos.d/foreman.repo ] && mv /etc/yum.repos.d/foreman.repo /tmp/

#install basic packages on Controller Node
yum -y install ntp mysql MySQL-python openstack-utils telnet openstack-selinux

#ntpd
systemctl restart ntpd
systemctl enable ntpd
instlog "ntpd service started and registered"

###############################
#
# common functions 
#
###############################

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

## remove [DEFAULT]\n[DEFAULT]
clear_conf(){
        sed -i ':a;N;$!ba;s/FAULT\]\n\[DE//g' "$1"
}

## set config 
# $1 : conf file name
# $2 : type
# $3 : key
# $4 : value
set_conf(){
        conf=''
        if [ "$1" == "my.cnf" ];then
                conf=$conf_mysql
        elif [ $1 == "keystone.conf" ];then
                conf=$conf_keystone
        elif [ $1 == "glance-api.conf" ];then
                conf=$conf_glance_api
        elif [ $1 == "glance-registry.conf" ];then
                conf=$conf_glance_registry
        elif [ $1 == "nova.conf" ];then
                conf=$conf_nova
        elif [ $1 == "neutron.conf" ];then
                conf=$conf_neutron
        elif [ $1 == "ml2_conf.ini" ];then
                conf=$conf_ml2
        fi
        echo "openstack-config --set $conf $2 $3 $4"
        openstack-config --set $conf $2 $3 $4
}

## service start and register to the auto-start list
# $1 : service name
service_handle(){
        systemctl restart $1
	systemctl enable $1
	systemctl status $1
	[ ! $? ] && exit 1
}

# $1 openstack component name
create_database(){
        mysql -u root -p$database_pass -e "
                CREATE DATABASE $1;
                GRANT ALL PRIVILEGES ON $1.* TO '$1'@'localhost' IDENTIFIED BY '$database_pass';
                GRANT ALL PRIVILEGES ON $1.* TO '$1'@'%' IDENTIFIED BY '$database_pass';
                grant all on $1.* to '$1'@'localhost';
                grant all on $1.* to '$1'@'%';
                FLUSH PRIVILEGES;
                exit"
}

# $1 database name
# $2 query string 
db_query(){
        mysql -uroot -p$database_pass $1 -e "$2"
}
# $1 port to open
set_iptables(){
	firewall-cmd --zone=public --add-port=$i/tcp --permanent
	#iptables -A INPUT -i eth0 -p tcp -m tcp --dport $1 -j ACCEPT
}

###############################
#
# basic settings
#
###############################
logg_big "basic settings"

logg "install crone only if cronetab command is invalid"
crontab -l || yum install -y cronie 

logg "install mysql"
yum -y install mysql mysql-server MySQL-python expect

if grep --quiet character-set-server /etc/my.cnf;then
        echo "skipping my.cnf"
else 
        mv -f /etc/my.cnf /etc/my.cnf.bak; 
        sed "s/mysqld\]/mysqld\]\ndefault-storage-engine=innodb\ncollation-server=utf8_general_ci\ninit-connect=\'SET\ NAMES\ utf8\'\ncharacter-set-server=utf8/g" /etc/my.cnf.bak > /etc/my.cnf
fi
# check my.cnf
cat /etc/my.cnf

logg "prepare mysql"
{
        systemctl restart mariadb;
        systemctl enable mariadb;
        #mysql_install_db;
} || {
        echo "failed at launching mysql."
        echo "RERUN script."
        exit 1;
}

logg "mysql secure installation"
/usr/bin/expect <<EOD
spawn mysql_secure_installation
expect {        
        timeout { exit 1; }
        "*password for the*" {          send "\r"               }       
}
expect {
        timeout { exit 1; }
        "Enter current password for root*" {    send "\r"       }
}
expect {       
        timeout { exit 1; } 
        "New password*" {       send "$database_pass\r"         }
}
expect {        
        timeout { exit 1; }
        "Re-enter new password*" {      send "$database_pass\r"         }
}
expect {
        timeout { exit 1; }
        "Remove anonymous users*" {                send "y\r"        }
}
expect {
        timeout { exit 1; }
        "Disallow root login remotely*" {                send "n\r"        }
expect {
        timeout { exit 1; }
        "Remove test database and access to it*" {                send "y\r"        }
}
expect {
        timeout { exit 1; }
        "Reload privilege tables now*" {                send "y\r"        }
}
EOD

logg "install message queue"
yum -y install rabbitmq-server python-pip python-kombu
rabbitmqctl change_password guest guest

service_handle rabbitmq-server 
logg "check if rabbitmq is started"
[ ! $(pidof epmd) ] && exit 1

logg "set iptable for mq and database"
set_iptables "3306"
set_iptables "5672"
#check:: iptables for mq and db
iptables -L | grep "3306\|5672"

logg "selinux off for httpd"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo 0 > /selinux/enforce
#check:: selinux is changed?
cat /selinux/enforce

###########################################
#
# keystone  
#
##########################################
logg_big "keystone"

logg "install keystone"
yum -y install openstack-keystone python-keystoneclient

logg "set database connnection info on conf"
set_conf "keystone.conf" "database" "connection" "mysql://keystone:$database_pass@$controller_hostname/keystone"

logg "create database for keystone"
create_database "keystone"
su -s /bin/sh -c "keystone-manage db_sync" keystone

logg "check:: is database created?"
db_query "mysql" "show databases"
logg "check:: is tables created?"
db_query "keystone" "show tables"

logg "set admin token"
set_conf "keystone.conf" "DEFAULT" "admin_token" $admin_token

logg "set pki info and set file auth for keystone"
keystone-manage pki_setup --keystone-user keystone --keystone-group  keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl
chown keystone:keystone /var/log/keystone/keystone.log
# check:: is the auth of keystone files right? 
ls -al /etc/keystone
ls -al /var/log/keystone

logg "service start and enable"
clear_conf $conf_keystone
service_handle openstack-keystone

logg "register 5000, 35357 ports to iptables"
set_iptables 5000
set_iptables 35357
# check:: is keystone port registered to iptable?
iptables -L | grep '5000\|35357'

logg "registering flush expired keys"
(crontab -l 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/root\

logg "set service tokens"
export OS_SERVICE_TOKEN=$admin_token
export OS_SERVICE_ENDPOINT=http://$controller_hostname:35357/v2.0
echo "service token is:    $OS_SERVICE_TOKEN "
echo "service endpoint is: $OS_SERVICE_ENDPOINT "

logg "create admin user, role"
keystone user-create --name=admin --pass=$admin_pass --email=admin@email.com
keystone role-create --name=admin

logg "create admin tenant"
keystone tenant-create --name=admin --description="Admin Tenant"

logg "assign roles of admin and _member_ to admin user "
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin

logg "create service tenant"
keystone tenant-create --name=service --description="Service Tenant"

logg "create keystone service"
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"

logg "create keystone enpoint"
keystone endpoint-create \
 --service-id=$(keystone service-list | awk '/ identity / {print $2}') \
 --publicurl=http://$controller_hostname:5000/v2.0 \
 --internalurl=http://$controller_hostname:5000/v2.0 \
 --adminurl=http://$controller_hostname:35357/v2.0

logg "test keystone token-get using service token"
keystone --os-username=admin --os-password=$admin_pass --os-auth-url=http://$controller_hostname:35357/v2.0 token-get

logg "test keystone token-get with admin tenant by service token"
keystone --os-username=admin --os-password=$admin_pass --os-tenant-name=admin --os-auth-url=http://$controller_hostname:35357/v2.0  token-get

logg "unsetting service tokens"
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
echo "OS_SERVICE_TOKEN : " $OS_SERVICE_TOKEN 
echo "OS_SERVICE_ENDPOINT : " $OS_SERVICE_ENDPOINT

logg "loading credentials"
export OS_USERNAME=admin
export OS_PASSWORD=$admin_pass
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$controller_hostname:35357/v2.0
echo $OS_USERNAME
echo $OS_PASSWORD
echo $OS_TENANT_NAME
echo $OS_AUTH_URL

logg "generating credentails to /root/creds"
echo "export OS_USERNAME=admin
export OS_PASSWORD=$admin_pass
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$controller_hostname:35357/v2.0
" > /root/openrc.sh
ls -al /root/ | grep "openrc.sh"

logg "testing keystone token-get using credential"
keystone token-get

logg "testing keystone user-list using credential"
keystone user-list

logg "testing keystone user-role-list using credential"
keystone user-role-list --user admin --tenant admin

logg "show conf"
grep -v '^#\|^\s*$' $conf_keystone

###########################################
#
# glance 
#
##########################################
logg_big "glance"

logg "install glance"
yum -y install openstack-glance python-glanceclient

#set database info
set_conf "glance-api.conf" "database" "connection" "mysql://glance:database_pass@$controller_hostname/glance"
set_conf "glance-registry.conf" "database" "connection" "mysql://glance:database_pass@$controller_hostname/glance"

#set_conf "glance-api.conf" "rpc_backend" "qpid"
#set_conf "glance-api.conf" "DEFAULT" "qpid_hostname" $controller_hostname

logg "create database and user for glance"
create_database "glance"
su -s /bin/sh -c "glance-manage db_sync" glance

logg "check:: is database created?"
db_query "mysql" "show databases"
logg "check:: is tables created?"
db_query "glance" "show tables"

logg "register glance user to keystone and set it as a admin account"
keystone user-create --name=glance --pass=$service_pass --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin

# configure auth information on conf
for i in glance-{api,registry}.conf;do
        set_conf "$i" "keystone_authtoken" "auth_uri" "http://$controller_hostname:5000"
        set_conf "$i" "keystone_authtoken" "auth_host" "$controller_hostname"
        set_conf "$i" "keystone_authtoken" "auth_port" "35357"
        set_conf "$i" "keystone_authtoken" "auth_protocol" "http"
        set_conf "$i" "keystone_authtoken" "admin_tenant_name" "service"
        set_conf "$i" "keystone_authtoken" "admin_user" "glance"
        set_conf "$i" "keystone_authtoken" "admin_password" "$service_pass"
        set_conf "$i" "paste_deploy" "flavor" "keystone"
done

logg "create service and endpoint for glance"
keystone service-create --name=glance --type=image --description="OpenStack Image Service"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}') \
 --publicurl=http://$controller_hostname:9292 \
 --internalurl=http://$controller_hostname:9292 \
 --adminurl=http://$controller_hostname:9292

logg "set iptable for glance"
set_iptables "9292"
iptables -L | grep "9292"

# register glance services and start
clear_conf $conf_glance_api
clear_conf $conf_glance_registry
for i in openstack-glance-{api,registry};do
        service_handle $i
done

logg "download and register test image(cirros)"
wget -q http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img
ls- al | grep cirros
glance image-create --name "cirros-0.3.2-x86_64" --disk-format qcow2 --container-format bare --is-public True --progress < cirros-0.3.2-x86_64-disk.img

logg "test glance"
glance image-list

logg "check:: show conf"
grep -v '^#\|^\s*$' $conf_glance_registry
grep -v '^#\|^\s*$' $conf_glance_api

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
set_conf "ml2_conf.ini" "ml2_type_flat" "flat_networks" "physnet0"
set_conf "ml2_conf.ini" "ml2_type_vlan" "network_vlan_ranges" "physnet2:100:199"
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
set_iptables "80"
# check:: process of httpd and memcached
ps -ef | grep httpd
ps -ef | grep memcached