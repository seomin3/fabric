#!/bin/bash

###############################
#
# common functions
#
###############################

cmd_check(){
    if [ "$1" -ne "0" ]
    then
        echo 'return code 1' && exit 1
    else
        echo 'return OK'
    fi
}

## mysql console command
# $1 database name
# $2 query string
db_query(){
    mysql -h$database_hostname -u$database_user -p$database_pass $1 -e "$2" -B
}

## package install
# $1: pgackage list(pkg1 pkg2 ...)
install_pkgs(){
    RET=0
    CNT=0

    for str in $1
    do
        [ "$(rpm -qa | grep $str)" ] && RET=$(expr $RET + 1)
        CNT=$(expr $CNT + 1)
    done

    if [ "$RET" -ne "$CNT" ]
    then
        yum -y -d 1 install $1
    else
        echo 'Notting to do'
    fi
}

## service start and register to the auto-start list
# $1 : service name
service_handle(){
    chkconfig $1 on
    {
        service $1 restart
    } || {
        echo "fail to service statup - $1"
        exit 1
    }
    echo
    service $1 status
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

    case $1 in
    my.cnf)
        conf=$conf_mysql
        ;;
    # keystone
    keystone.conf)
        conf=$conf_keystone
        ;;
    # glance
    glance-api.conf)
        conf=$conf_glance_api
        ;;
    glance-registry.conf)
        conf=$conf_glance_registry
        ;;
    # nova
    nova.conf)
        conf=$conf_nova
        ;;
    api-paste.ini)
        conf=$conf_nova_api
        ;;
    # neutron
    neutron.conf)
        conf=$conf_neutron
        ;;
    ml2_conf.ini)
        conf=$conf_ml2
        ;;
    dhcp_agent.ini)
        conf=$conf_dhcp
        ;;
    metadata_agent.ini)
        conf=$conf_meta
        ;;
    # cinder
    cinder.conf)
        conf=$conf_cinder
        ;;
    # ceilometer
    ceilo.conf)
        conf=$conf_ceilometer
        ;;
    # swift
    proxy-server.conf)
        conf='/etc/swift/proxy-server.conf'
        ;;
    esac
    echo "openstack-config --set $conf $2 $3 $4"
    openstack-config --set $conf $2 $3 $4
}

# $1 openstack component name
remote_access_database(){
	mysql -hlocalhost -u$database_user -p$database_pass -e "
		GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$database_pass' with grant option;
		FLUSH PRIVILEGES;
		exit"
}
create_database(){
    mysql -h$database_hostname -u$database_user -p$database_pass -e "
        CREATE DATABASE $1;
        GRANT ALL PRIVILEGES ON $1.* TO '$1'@'localhost' IDENTIFIED BY '$database_pass';
        GRANT ALL PRIVILEGES ON $1.* TO '$1'@'%' IDENTIFIED BY '$database_pass';
        grant all on $1.* to '$1'@'%';
        FLUSH PRIVILEGES;
        exit"
}

# $1 port to open
set_iptables(){
    iptables -A INPUT -i eth0 -p tcp -m tcp --dport $1 -j ACCEPT
    service iptables save
}
