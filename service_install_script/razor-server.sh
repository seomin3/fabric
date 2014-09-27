#!/bin/bash

#
# Variables section
#
YUM_CMD='yum -y -d install'
IPADDR='192.168.122.2'


#
# Functions section
#
logp {
    echo '###########################'
    echo '#'
    echo "# $1"
    echo '#'
    echo '###########################'

}

#
# jruby
#
logp "jruby install"
curl -L https://get.rvm.io | bash
source /etc/profile.d/rvm.sh
rvm install jruby-1.7.13
rvm jruby use 1.7.13 --default

:<<END
#
# postgresql
#
logp 'postgresql install'
$YUM_CMD http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
$YUM_CMD postgresql93-server
chkconfig postgresql-9.3 on
service postgresql-9.3 initdb 
service postgresql-9.3 start

# grant
su - postgres -c 'createuser -P -SDR razor'
su - postgres -c 'createdb -O razor razor_prd'
su - postgres -c 'createdb -O razor razor_dev'
su - postgres -c 'createdb -O razor razor_test'
# 
cat >> /var/lib/pgsql/9.3/data/pg_hba.conf << __CONF__
local all postgres peer
host all all 127.0.0.1/32 md5
local all all peer
__CONF__

service postgresql-9.3 restart
#
# razor-server
#
logp 'razor-server install'
$YUM_CMD git libarchive-devel
cd /opt
git clone https://github.com/puppetlabs/razor-server.git
cd razor-server
rvm use jruby-1.7.13 --default
bundle install
cp config.yaml.sample config.yaml
mkdir -p /var/lib/razor/repo-store

#
# dnsmasq
#
logp 'dnsmasq install'
$YUM_CMD dnsmasq tftp
cat >> /etc/dnsmasq.conf << __CONF__

user=root
interface=eth0
except-interface=lo
# IPXE
dhcp-match=IPXEBOOT,175
dhcp-boot=net:IPXEBOOT,bootstrap.ipxe
dhcp-boot=undionly.kpxe
# TFTP setup
enable-tftp
tftp-root=/var/lib/tftpboot
dhcp-range=eth1,192.168.122.100,192.168.122.199,1h
log-queries
log-dhcp
log-facility = /var/log/dnsmasq.log

__CONF__

mkdir -p /var/lib/tftpboot
service dnsmasq restart
cd /var/lib/tftpboot
curl -L -O http://boot.ipxe.org/undionly.kpxe
curl -L http://$IPADDR:8080/api/microkernel/bootstrap?nic_max=3 -o bootstrap.ipxe
curl -L -O http://links.puppetlabs.com/razor-microkernel-003.tar
tar xf razor-microkernel-003.tar -C /var/lib/razor/repo-store/

END