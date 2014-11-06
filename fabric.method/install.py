import os
from fabric.api import task, run, sudo
# import inhouse code
import fuc

@task
def vncserver():
    sudo('init 3')
    fuc.install_pkgs('tigervnc-server')
    fuc.pushfile('./vnc/')
    sudo('cp -f /tmp/vnc/vncservers /etc/sysconfig/vncservers')
    sudo('su - cloud -c "mkdir -p /home/cloud/.vnc/"')
    sudo('su - cloud -c "cp -f /tmp/vnc/passwd /home/cloud/.vnc/"')
    fuc.set_service('vncserver')

@task
def vsftpd():
    fuc.install_pkgs('vsftpd')
    fuc.pushfile('vsftpd.conf', tempdir='/tmp/vsftpd/')
    sudo('cp -f /tmp/vsftpd/vsftpd.conf /etc/vsftpd/')
    fuc.set_service('vsftpd')

@task
def xfs():
    sudo('yum -d -y install xfsprogs xfsdump')
