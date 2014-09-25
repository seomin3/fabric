from fabric.api import put, run
from fabric.contrib.files import exists
execfile('./fabenv.py')

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

def set_yum(arch):
	if arch == 'rhel':
		put('../repo/local-rhel6.repo', '/etc/yum.repos.d/')
	if arch == 'cent':
		put('../repo/local-cent6.repo', '/etc/yum.repos.d/')
	if exists('/etc/yum.repos.d/CentOS-Base.repo'):
		run('mkdir -p /etc/yum.repos.d/old')
		run('mv -f /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/old/')
	run('yum clean all')
	run('yum repolist')
	ins_pkgs = 'system-config-network-tui wget vim git sysstat perl ntp yum-plugin-priorities htop lsof mlocate man openssh-client nc lynx htop bind-utils nfs-utils nfs-utils-lib acpid'
	run('yum -y -q install '+ ins_pkgs)
	#run('yum -y -q update')

def prep_rhel6():
	set_yum('rhel')
	set_ntp()
	start_service = 'acpid'
	stop_service = 'iptables NetworkManager'
	for i in start_service.split():
		set_service(i, 'start')
	for i in stop_service.split():
		set_service(i, 'stop')
	run('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')
	run('perl -pi -e "s/plugins=1/plugins=0/" /etc/yum.conf')

def prep_cent6():
	set_yum('cent')
	set_ntp()
	stop_service = 'iptables'
	for i in stop_service.split():
		set_service(i, 'stop')
	run('perl -pi -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config')

def reboot():
	run('init 6')
