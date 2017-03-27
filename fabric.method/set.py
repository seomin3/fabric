from fabric.api import task, run, put, sudo, env
# import inhouse code
import fuc

@task
def gmond():
    fuc.pushfile('gmond.conf', './doc/etc/ganglia/')
    sudo('cp /tmp/fab/gmond.conf /etc/ganglia/')
    sudo('service gmond restart')

@task
def rsyslog_sudo():
    fuc.pushfile('sudo.conf', './doc/etc/')
    fuc.pushfile('sudolog', './doc/etc/')
    fuc.pushfile('syslog', './doc/etc/')
    sudo('cp /tmp/fab/sudo.conf /etc/rsyslog.d/')
    sudo('cp /tmp/fab/syslog /etc/logrotate.d/')
    sudo('cp /tmp/fab/sudolog /etc/logrotate.d')
    sudo('service rsyslog restart')

@task
def ulimit():
    fuc.pushfile('neodc.conf', './doc/etc/limits.d/')
    sudo('cp /tmp/fab/neodc.conf /etc/security/limits.d/')

@task
def disable_rootlogin():
    sudo('perl -pi -e "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config')
    sudo('grep -i PermitRootLogin /etc/ssh/sshd_config')
    sudo('service sshd restart')

@task
def enable_rootlogin():
    sudo('perl -pi -e "s/^PermitRootLogin no/PermitRootLogin yes/" /etc/ssh/sshd_config')
    sudo('grep -i PermitRootLogin /etc/ssh/sshd_config')
    sudo('service sshd restart')

@task
def resetpw():
    USER_NAME = 'user'
    USER_PASS = 'pass!!'
    sudo('echo "%s:%s" | chpasswd' % (USER_NAME,USER_PASS))

@task
def ntp():
    ntpserver = 'dcos-glance-storage'
    if env.host != ntpserver:
        fuc.pushfile('./etc/ntp.conf')
        sudo('cp -f /tmp/fab/ntp.conf /etc/')
        fuc.set_date()

@task
def hosts():
    hostfile = './etc/hosts'
    fuc.pushfile(hostfile)
    sudo('mkdir -p /etc/backup; cp /etc/hosts /etc/backup/hosts-$(date +%y%m%d)')
    sudo('cp /tmp/fab/hosts /etc/hosts')

'''

def bash_history():
    RET = False
    file = run('cat ~/.bash_profile', quiet = True)
    for i in file.split('\n'):
        if 'HISTTIMEFORMAT' in i: RET = True
    if RET == False:
        run("echo 'export HISTTIMEFORMAT=\"[ %d/%m/%y %T ] \"' >> ~/.bash_profile")
        sudo("echo 'export HISTTIMEFORMAT=\"[ %d/%m/%y %T ] \"' >> /root/.bash_profile")

def novavnc():
    sudo('perl -pi -e "s/IPA:6080/IPB:6080/" /etc/nova/nova.conf')
    sudo('openstack-service restart nova')

def lv_compute():
    sudo('lvcreate -L 2048G -n lv_compute vg')
    sudo('mkfs.ext4 /dev/vg/lv_compute')
    sudo('echo "/dev/vg/lv_compute      /var/lib/nova           ext4    defaults        0 0" >> /etc/fstab')
    sudo('mkdir -p /var/lib/nova')
    sudo('mount -a')

def gw():
    sudo('perl -pi -e "s/GATEWAY=150.24.223.1/GATEWAY=150.24.223.2/g" /etc/sysconfig/network-scripts/ifcfg-eth0', warn_only=True)
    sudo('perl -pi -e "s/GATEWAY=150.24.223.1/GATEWAY=150.24.223.2/g" /etc/sysconfig/network', warn_only=True)
    sudo('perl -pi -e "s/GATEWAY=150.24.223.1/GATEWAY=150.24.223.2/g" /etc/sysconfig/network-scripts/ifcfg-em1', warn_only=True)
    sudo('service network restart')
    sudo('route -n')

'''
