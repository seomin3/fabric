from fabric.api import task, env, run, put, sudo
from fabric.contrib.files import exists
import fuc, set

@task
def yum():
    fuc.prep_yum()

@task
def dcos():
    fuc.set_date()
    fuc.prep_yum()
    start_service = 'acpid'
    stop_service = 'iptables NetworkManager sendmail'
    for i in start_service.split(): fuc.set_service(i, 'start')
    for i in stop_service.split(): fuc.set_service(i, 'stop')
    sudo('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')

'''
def reboot():
    sudo('sync && init 6')

def prep_rhel6():
    set_yum('rhel')
    set_ntp()
    start_service = 'acpid'
    stop_service = 'iptables NetworkManager'
    for i in start_service.split(): fuc.set_service(i, 'start')
    for i in stop_service.split(): fuc.set_service(i, 'stop')
    sudo('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')
    sudo('perl -pi -e "s/plugins=1/plugins=0/" /etc/yum.conf')

@task
def cent6():
    fuc.set_date()
    fuc.clean_yum()
    start_service = 'acpid'
    stop_service = 'iptables NetworkManager sendmail'
    for i in start_service.split(): fuc.set_service(i, 'start')
    for i in stop_service.split(): fuc.set_service(i, 'stop')
    sudo('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')
    
'''
