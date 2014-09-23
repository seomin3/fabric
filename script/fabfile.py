from fabric.api import put, run
from fabric.contrib.files import exists
execfile('/opt/sandbox/script/fabfile_host.py')

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
	run("echo 'nameserver 8.8.8.8' > /etc/resolv.conf")
	if arch == 'rhel':
		put('../repo/local-rhel6.repo', '/etc/yum.repos.d/')
	if arch == 'cent':
		put('../repo/local-cent6.repo', '/etc/yum.repos.d/')
		run('mkdir -p /etc/yum.repos.d/old')
		if exists('/etc/yum.repos.d/CentOS-*'):
			run('mv -f /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/old/')
	# rpmforge
	#if not exists('/etc/yum.repos.d/rpmforge.repo'):
	#	ins_repo = 'http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm'
	#	run('[ ! -f /etc/yum.repos.d/mirrors-rpmforge ] && yum -y -q install '+ ins_repo)
	run('yum clean all')
	ins_pkgs = 'system-config-network-tui wget vim git sysstat perl ntp yum-plugin-priorities htop lsof mlocate man openssh-client nc lynx htop bind-utils nfs-utils nfs-utils-lib acpid'
	run('yum -y -q install '+ ins_pkgs)
	run('yum -y -q update')

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

def test():
	put('../repo/local-cent6.repo', '/etc/yum.repos.d/')


def reboot():
	run('init 6')
