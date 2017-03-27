'''
Created on 8 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
class DepDashboard(object):

	cntHostname = ''

	def __init__(self, env, cntHostname):
		self.cntHostname = cntHostname
	
	def reconfig(self):
		self.__config()
		self.__initialSetup()
		
	def start(self):
		print 'starting to install dashboard'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
	
	def __presets(self):
		pass
		
	def __packageInstall(self):
		dashboardPkg = ['openstack-dashboard','httpd','mod_wsgi','memcached','python-memcached']
		dSys.DeployerBash().packageInstall(dashboardPkg)
	
	def __config(self):
		dashboardConf = '/etc/openstack-dashboard/local_settings'
		dSys.DeployerBash().configSed('ALLOWED_HOSTS\s*=\s*\[.*\]', 'ALLOWED_HOSTS = \[\'*\'\]', dashboardConf,option='')
		dSys.DeployerBash().configSed('OPENSTACK_HOST\s*=\s*"[0-9\.]*"', 'OPENSTACK_HOST = "'+self.cntHostname+'"', dashboardConf)
		dSys.DeployerBash().configSed('TIME_ZONE\s*=\s*"UTC"', 'TIME_ZONE = "Asia/Seoul"',dashboardConf)
		
	def __initialSetup(self):
		dSys.DeployerBash().runBash(['setsebool','-P','httpd_can_network_connect','on'])
		dSys.DeployerBash().chownSetup('apache', '/usr/share/openstack-dashboard/static')
			
		dSys.DeployerBash().serviceControl('enable', 'httpd.service')
		dSys.DeployerBash().serviceControl('restart', 'httpd.service')
		dSys.DeployerBash().serviceControl('enable', 'memcached.service')
		dSys.DeployerBash().serviceControl('restart', 'memcached.service')
		
		dSys.DeployerBash().firewallSetup('80')
		dSys.DeployerBash().firewallSetup('11211')
