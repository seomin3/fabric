from fabric.api import task, env, run, put
from fabric.contrib.files import exists

@task
def cent6():
    set_yum(arch = 'cent', reposerver = '203.239.182.189:8888')
    set_ntp()
    start_service = 'acpid'
    stop_service = 'iptables NetworkManager'
    for i in start_service.split(): set_service(i, 'start')
    for i in stop_service.split(): set_service(i, 'stop')
    run('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')

@task
def reboot():
    run('sync && init 6')

def set_service(name, op):
    if exists('/etc/init.d/' + name):
        if op == 'start':
            run('chkconfig ' + name + ' on')
            run('service ' + name + ' start')
        elif op == 'stop':
            run('chkconfig ' + name + ' off')
            run('service ' + name + ' stop')

def set_ntp():
    set_service('ntpd', 'stop')
    run('ntpdate -b kr.pool.ntp.org')
    set_service('ntpd', 'start')

def set_yum(arch = cent, reposerver = '127.0.0.1'):
    if arch == 'rhel': put('./repo/local-rhel6.repo', '/etc/yum.repos.d/')
    if arch == 'cent':
        put('./repo/local-cent6.repo', '/etc/yum.repos.d/')
        run('perl -pi -e "s/IPADDRESS/%s/g" /etc/yum.repos.d/local-cent6.repo' % reposerver)
    exit
    if exists('/etc/yum.repos.d/CentOS-Base.repo'):
        run('mkdir -p /etc/yum.repos.d/old')
        run('find /etc/yum.repos.d/ -maxdepth 1 -type f \( ! -iname "local-cent6.repo" \) -exec mv -f {} /etc/yum.repos.d/old \;')
    run('yum clean all')
    run('yum -d 1 repolist')
    ins_pkgs = 'system-config-network-tui wget vim git sysstat perl ntp yum-plugin-priorities htop lsof mlocate man openssh-client nc lynx htop bind-utils nfs-utils nfs-utils-lib acpid lrzsz parted tcpdump'
    run('yum -y -d 1 install '+ ins_pkgs)
    run("echo 'export HISTTIMEFORMAT=\"[ %d/%m/%y %T ] \"' >> ~/.bash_profile")

def prep_rhel6():
    set_yum('rhel')
    set_ntp()
    start_service = 'acpid'
    stop_service = 'iptables NetworkManager'
    for i in start_service.split(): set_service(i, 'start')
    for i in stop_service.split(): set_service(i, 'stop')
    run('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')
    run('perl -pi -e "s/plugins=1/plugins=0/" /etc/yum.conf')

@task
def testrun():
    run('exit 1')