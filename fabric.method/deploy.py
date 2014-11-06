from fabric.api import task, put, cd, run, sudo
import fuc

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
    sudo('mkdir -p /usr/dcos/sw/ && tar xzf /tmp/vertx/vert.x-2.1.2.tar.gz -C /usr/dcos/sw/')
    sudo('ln -sf /usr/dcos/sw/vert.x-2.1.2 /usr/dcos/sw/vertx')
    file = sudo('cat /etc/profile', quiet = True)
    for i in file.split('\n'):
        if 'VERTX_HOME' in i: RET = True
    if RET == False:
        sudo('echo "export VERTX_HOME=/usr/dcos/sw/vertx" >> /etc/profile')
        sudo('echo "export PATH=$PATH:$VERTX_HOME/bin:$ANT_HOME/bin" >> /etc/profile')
    sudo('source /etc/profile')
    run('vertx version')

@task
def java():
    fuc.pushfile('*', '/home/sysop/work/jdk/', '/tmp/jdk/')
    sudo('rpm -ivh /tmp/jdk/jdk-7u71-linux-x64.rpm', warn_only=True)
    run('java -version')
    run('javac -version')

@task
def api_keystone():
    go('./install_keystone.sh')
@task
def api_glance():
    go('./srv_install_glance.sh')
@task
def api_horizon():
    go('./install_horizon.sh')
@task
def api_cinder():
    go('./install_cinder.sh')
@task
def api_ceilo():
    go('./install_ceilometer.sh')
@task
def srv_neutron():
    go('./srv_install_neutron.sh')
@task
def srv_nova():
    go('./srv_install_nova.sh')
@task
def srv_cinder():
    go('./srv_install_cinder.sh')
@task
def ceilo_nova():
    go('./ceilometer_agent_nova.sh')

def go(basename):
    fuc.pushfile('/sandbox/', '/home/sysop/openstack/', '/tmp/sandbox/')
    with cd('/tmp/sandbox/'):
        sudo('chmod 744 *sh')
        sudo(basename)

'''

@task
def ladvd():
    fuc.pushfile('*', '/home/sysop/work/ladvd/', '/tmp/ladvd/')
    sudo('rpm -ivh /tmp/ladvd/ladvd-1.0.4-1.el6.x86_64.rpm', warn_only=True)
    sudo('cp -f /tmp/ladvd/ladvd /etc/sysconfig/')
    sudo('chkconfig ladvd on && service ladvd restart')

'''