import os
from fabric.api import task, run, sudo
# import inhouse code
import fuc

@task
def gmond():
    fuc.install_pkgs('ganglia-gmond')
    fuc.set_service('gmond')

@task
def hppmp():
    fuc.pushfile('hp-pmp', '/home/sysop/work/')
    sudo('rpm -Uvh /tmp/fab/hp-pmp/*rpm')

@task
def chrome():
    fuc.pushfile('chrome', '/home/sysop/work/')
    fuc.install_pkgs('policycoreutils-python')
    sudo('rpm -Uvh /tmp/fab/chrome/*', warn_only=True)

@task
def ko_font():
    fuc.install_pkgs('baekmuk-ttf-*')

@task
def zabbix_agent():
    sudo('yum -y -d 1 install zabbix-agent')
    sudo('perl -pi -e "s/Server=127.0.0.1/Server=192.168.1.24/" /etc/zabbix/zabbix_agentd.conf')
    sudo('perl -pi -e "s/ServerActive=127.0.0.1/ServerActive=192.168.1.24/" /etc/zabbix/zabbix_agentd.conf')
    fuc.set_service('zabbix-agent')
    sudo('tail -n 10 /var/log/zabbix/zabbix_agentd.log')

@task
def vertx():
    RET = False
    fuc.pushfile('vert.x-2.1.2.tar.gz', '/home/sysop/work/vertx/', '/tmp/vertx/')
    sudo('mkdir -p /usr/neodc/sw/ && tar xzf /tmp/vertx/vert.x-2.1.2.tar.gz -C /usr/neodc/sw/')
    sudo('ln -sf /usr/neodc/sw/vert.x-2.1.2 /usr/neodc/sw/vertx')
    file = sudo('cat /etc/profile', quiet = True)
    for i in file.split('\n'):
    if 'VERTX_HOME' in i: RET = True
    if RET == False:
    sudo('echo "export VERTX_HOME=/usr/neodc/sw/vertx" >> /etc/profile')
    sudo('echo "export PATH=$PATH:$VERTX_HOME/bin:$ANT_HOME/bin" >> /etc/profile')
    sudo('source /etc/profile')
    run('vertx version')

@task
def java():
    fuc.pushfile('*', '/home/sysop/work/jdk/', '/tmp/jdk/')
    sudo('rpm -ivh /tmp/jdk/jdk-7u71-linux-x64.rpm', warn_only=True)
    sudo("alternatives --install '/usr/bin/java' java '/usr/java/default/bin/java' 10")
    sudo("alternatives --install '/usr/bin/javac' javac '/usr/java/default/bin/javac' 10")
    run('java -version')
    run('javac -version')

@task
def vncserver():
    sudo('init 3')
    fuc.install_pkgs('control-center-extra eog gdm-plugin-fingerprint gnome-applets gnome-media gnome-packagekit gnome-vfs2-smb gok openssh-askpass orca pulseaudio-module-gconf pulseaudio-module-x11 vino alsa-plugins-pulseaudio at-spi control-center dbus gdm gdm-user-switch-applet gnome-panel gnome-power-manager gnome-screensaver gnome-session gnome-terminal gvfs-archive gvfs-fuse gvfs-smb metacity nautilus notification-daemon polkit-gnome xdg-user-dirs-gtk yelp')
    fuc.install_pkgs('xsetroot xterm twm firefox gnome-desktop tigervnc-server')
    fuc.pushfile('./vnc/')
    sudo('cp -f /tmp/fab/vnc/vncservers /etc/sysconfig/vncservers')
    sudo('su - cloud -c "mkdir -p /home/cloud/.vnc/"')
    sudo('su - cloud -c "cp -f /tmp/fab/vnc/passwd /home/cloud/.vnc/"')
    fuc.set_service('vncserver')

@task
def vsftpd():
    fuc.install_pkgs('vsftpd')
    fuc.pushfile('./etc/vsftpd.conf', tempdir='/tmp/vsftpd/')
    sudo('cp -f /tmp/vsftpd/vsftpd.conf /etc/vsftpd/')
    fuc.set_service('vsftpd')

@task
def xfs():
    fuc.install_pkgs('xfsprogs xfsdump')
