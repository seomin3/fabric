from fabric.api import task, cd, run, get, sudo
from fabric.colors import magenta, blue
from fabric.contrib.files import exists
import fuc

@task
def openstack():
    hostname = run('hostname')
    backupdate = run('date +%y%m%d')
    backupdir = '/var/backup/%s-openstack-%s/' % (hostname, backupdate)
    fuc.install_pkgs('python-swiftclient')
    fuc.pushfile('openrc.sh');
    sudo('cp -f /tmp/fab/openrc.sh /etc/profile.d/')
    #if exists(backupdir): sudo('rm -rf %s' % backupdir)
    project = 'keystone glance nova neutron cinder ceilometer swift'
    for i in project.split():
        if exists('/etc/%s' % i):
            sudo('mkdir -p %s' % backupdir)
            sudo('cp -r /etc/%s/ %s' % (i,backupdir))
    sudo('swift upload openstack-config %s' % backupdir, warn_only=True)

#@task
def conf_openstack():
    hostname = run('hostname')
    if exists('/tmp/%s-openstack/' % hostname): run('rm -rf /tmp/%s-openstack/' % hostname)
    project = 'keystone glance nova neutron cinder ceilometer'
    for i in project.split():
        if exists('/etc/%s' % i):
            run('mkdir -p /tmp/%s-openstack/%s' % (hostname, i))
            with cd('/etc/%s' % i):
                find = sudo("find ./ -maxdepth 1 -type f -name '*conf' -o -name '*ini'")
                for j in find.split(): sudo("grep -v '^#\|^\s*$' %s > /tmp/%s-openstack/%s/%s" % (j, hostname, i, j))
    with cd('/tmp/%s-openstack/' % hostname):
        run('tar cf - ./ | xz -9 -c - > /tmp/%s-${date +%y%m%d}-openstack.tar.xz' % hostname)
        #get('/tmp/%s-${date +%y%m%d}-openstack-.tar.xz' % hostname, '/home/sysop/')

@task
def conf_etc():
    with cd('/etc'):
        sudo('tar --exclude=./pki --exclude=./selinux/targeted -cf - ./ | xz -9 -c - > /var/tmp/$(hostname)_etc.tar.xz')
