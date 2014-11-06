from fabric.api import task, cd, run, get
from fabric.colors import magenta, blue
from fabric.contrib.files import exists

@task
def conf_openstack():
    hostname = run('hostname')
    if exists('/tmp/%s-diff/' % hostname): run('rm -rf /tmp/%s-diff/' % hostname)
    project = 'keystone glance nova neutron cinder'
    for i in project.split():
        if exists('/etc/%s' % i):
            run('mkdir -p /tmp/%s-diff/%s' % (hostname, i))
            with cd('/etc/%s' % i):
                find = run("find ./ -maxdepth 1 -type f -name '*conf' -o -name '*ini'")
                for j in find.split(): run("grep -v '^#\|^\s*$' %s > /tmp/%s-diff/%s/%s" % (j, hostname, i, j))
    with cd('/tmp/%s-diff/' % hostname):
        run('tar cf - ./ | xz -9 -c - > /tmp/%s-diff.tar.xz' % hostname)
        get('/tmp/%s-diff.tar.xz' % hostname, '/home/sysop/')

@task
def conf_etc():
    with cd('/etc'):
        run('tar --exclude=./pki --exclude=./selinux/targeted -cf - ./ | xz -9 -c - > /var/tmp/$(hostname)_etc.tar.xz')
