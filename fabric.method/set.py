from fabric.api import task, run, put, sudo, env
# import inhouse code
import fuc

@task
def ulimit():
    fuc.pushfile('neodc.conf', './docs/etc/limits.d/')
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
        fuc.pushfile('ntp.conf')
        sudo('cp -f /tmp/ntp.conf /etc/')
        fuc.set_date()

@task
def hosts():
    hostfile = './docs/hosts'
    put('%s' % hostfile, '/tmp/sysop')
    sudo('mkdir -p /etc/backup; cp /etc/hosts /etc/backup/hosts-$(date +%y%m%d)')
    sudo('cp /tmp/sysop/hosts /etc/hosts')

'''
@task
def bash_history():
    RET = False
    file = run('cat ~/.bash_profile', quiet = True)
    for i in file.split('\n'):
        if 'HISTTIMEFORMAT' in i: RET = True
    if RET == False:
        run("echo 'export HISTTIMEFORMAT=\"[ %d/%m/%y %T ] \"' >> ~/.bash_profile")
        sudo("echo 'export HISTTIMEFORMAT=\"[ %d/%m/%y %T ] \"' >> /root/.bash_profile")
@task
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
