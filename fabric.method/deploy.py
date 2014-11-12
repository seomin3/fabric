from fabric.api import task, put, cd, run, sudo
import fuc

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
def api_swift():
    go('./api_swift.sh')
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
    fuc.pushfile('/sandbox/', '/home/sysop/openstack/', '/tmp/')
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
