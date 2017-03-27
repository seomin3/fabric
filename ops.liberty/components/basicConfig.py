'''
Created on 9 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
class DepBasicConfig(object):

	def __init__(self):
		pass

	def start(self):
		print 'starting to install basic configuration'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
	
	def __presets(self):
		pass

	def __packageInstall(self):
		#epelrpm = 'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm'
		#rdojunorpm = 'http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm'
		basicPkg = ['openstack-utils','python-openstackclient','ntp','yum-plugin-priorities','openstack-selinux','tcpdump','wget','telnet','crudini','python-devel','pexpect','mysql']
		#dSys.DeployerBash().packageInstall([epelrpm])
		#dSys.DeployerBash().packageInstall([rdojunorpm])
		dSys.DeployerBash().packageInstall(basicPkg)
	
	def __config(self):
		pass
	
	def __initialSetup(self):
		dSys.DeployerBash().serviceControl('enable', 'ntpd.service')
		dSys.DeployerBash().serviceControl('restart', 'ntpd.service')
