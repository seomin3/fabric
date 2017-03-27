from fabric.api import task, cd, run, get, sudo
from fabric.colors import magenta, blue
from fabric.contrib.files import exists
import fuc

@task
def perf():
    perf_list = []
    with hide('output'):
        host_name = run('hostname')
        core_num = run("cat /proc/cpuinfo | grep 'processor' | wc -l")
        load5 = run("cat /proc/loadavg| awk '{print $1,$2,$3 }'")
        io5 = run("iostat | grep avg-cpu: -A 1 | grep -v avg-cpu | awk '{print $5}'")
        free5 = run("free -m| grep Mem: | awk '{print $2,$3,$4,$5,$6,$7}'")
    perf_list.append(host_name)
    perf_list.append(core_num)
    for i in load5.split(' '):
        perf_list.append(float(i))
    perf_list.append(io5)
    for i in load5.split(' '):
        perf_list.append(str(round(float(i) / int(core_num) * 100, 1)) + "%")
    for i in free5.split(' '):
        perf_list.append(int(i))
    perf_list.append(str(round(float(perf_list[10]) / float(perf_list[9]) * 100, 1)) + "%")

    f = open('/tmp/result.txt', 'a')
    for line in perf_list:
        f.write(str(line))
        f.write(' ')
    f.write('\n')
    f.close()

@task
def ladvd():
    run('grep -i LADVD_OPTION /etc/sysconfig/ladvd')

#@task
#def openstack():
#    hostname = run('hostname')
#    backupdate = run('date +%y%m%d')
#    backupdir = '/var/backup/%s-openstack-%s/' % (hostname, backupdate)
#    fuc.install_pkgs('python-swiftclient')
#    fuc.pushfile('openrc.sh');
#    sudo('cp -f /tmp/fab/openrc.sh /etc/profile.d/')
#    #if exists(backupdir): sudo('rm -rf %s' % backupdir)
#    project = 'keystone glance nova neutron cinder ceilometer swift'
#    for i in project.split():
#        if exists('/etc/%s' % i):
#            sudo('mkdir -p %s' % backupdir)
#            sudo('cp -r /etc/%s/ %s' % (i,backupdir))
#    sudo('swift upload openstack-config %s' % backupdir, warn_only=True)

@task
def conf_os():
    hostname = run('hostname -s')
    backupdir = '/tmp/%s-os/' % hostname
    backupdate = run('date +%y%m%d')
    backup = '/tmp/%s.%s.os.tar.xz' % (hostname, backupdate)
    if exists(backupdir): run('rm -rf %s' % backupdir)
    project = 'keystone glance nova neutron cinder ceilometer swift'
    for i in project.split():
        if exists('/etc/%s' % i):
            run('mkdir -p %s/%s' % (backupdir, i))
            with cd('/etc/%s' % i):
                find = sudo("find ./ -maxdepth 1 -type f -name '*conf' -o -name '*ini'")
                for j in find.split(): sudo("grep -v '^#\|^\s*$' %s > %s/%s/%s" % (j, backupdir, i, j))
    with cd(backupdir):
        run('tar cf - ./ | xz -9 -c - > %s' % backup)
        get(backup, '/home/sysop/tmp/')

@task
def conf_etc():
    hostname = run('hostname -s')
    backupdate = run('date +%y%m%d')
    backup = '/tmp/%s.%s.etc.tar.xz' % (hostname, backupdate)
    with cd('/etc'):
        sudo('tar --exclude=./pki --exclude=./selinux/targeted -cf - ./ | xz -9 -c - > %s' % backup)
        get(backup, '/home/sysop')
