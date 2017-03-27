'''
Created on 3 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
import os

class DepKeystone(object):
	databasePass = ''
	cntHostname = ''
	dbHostname = ''
	passwd = {}
	secret = {}
	evr = {}

	def __init__(self, env, hostname):
		self.databasePass = env['config']['credentials']['database']['after']
		self.cntHostname = hostname
		self.dbHostname = env['mysql']['ip']
		self.passwd = env['config']['credentials']['passwd']
		self.secret = env['config']['credentials']['secret']
		
		self.evr = dict(os.environ)
		self.evr['OS_TOKEN'] = 'admin_token'
		self.evr['OS_URL'] = 'http://'+self.cntHostname+':35357/v3'
		self.evr['OS_IDENTITY_API_VERSION'] = '3'
		
	def start(self):
		print "starting to install keystone"
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
	
	def __presets(self):
		dSys.DeployerBash().createOpstDb('keystone', self.databasePass, self.dbHostname)
	
	def __packageInstall(self):
		keystonePkgs = ['openstack-keystone']
		dSys.DeployerBash().packageInstall(keystonePkgs)
	
	def __config(self):
		admin_token = self.secret['admin']
		conf = [
			['DEFAULT','verbose','true'],
			['DEFAULT','admin_token',admin_token],
			['database',"connection",'mysql://keystone:'+self.databasePass+'@'+self.dbHostname+'/keystone'],
			['token','provider','keystone.token.providers.uuid.Provider'],
			['token','driver','keystone.token.persistence.backends.sql.Token']
		]
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/keystone/keystone.conf')

	def __initialSetup(self):
		pkiSetupCmm = ['keystone-manage', 'pki_setup', '--keystone-user', 'keystone', '--keystone-group', 'keystone']
		dSys.DeployerBash().runBash(pkiSetupCmm)
		dSys.DeployerBash().chownSetup('keystone','/var/log/keystone')
		dSys.DeployerBash().chownSetup('keystone','/etc/keystone/ssl')
		chmodCmm = ['chmod','-R','o-rwx','/etc/keystone/ssl']
		dSys.DeployerBash().runBash(chmodCmm)
		dSys.DeployerBash().syncOpstDb('keystone')
		dSys.DeployerBash().serviceControl('enable', 'openstack-keystone.service')
		dSys.DeployerBash().serviceControl('restart', 'openstack-keystone.service')
		
# 		crtStr = "( crontab -l -u keystone 2 > &1 | grep -q token_flush ) || echo '@hourly /usr/bin/keystone-manage token_flush > /var/log/keystone/keystone-tokenflush.log 2 > & 1' >> /var/spool/cron/keystone"
# 		crtCmm = crtStr.split(' ')
# 		dSys.DeployerBash().runBash(crtCmm)
		
		dSys.DeployerBash().firewallSetup(['35357','5000'])
		
		dSys.DeployerBash(self.evr).keystoneServCR('keystone', 'identity', 'OpenStack Identity v2')
		dSys.DeployerBash(self.evr).endpointCreate('keystone',self.cntHostname, ['5000','5000','35357'],'v2.0')
		dSys.DeployerBash(self.evr).keystoneServCR('keystone-v3', 'identity', 'OpenStack Identity v3')
		dSys.DeployerBash(self.evr).endpointCreate('keystone-v3',self.cntHostname, ['5000','5000','35357'],'v3')
		
		dSys.DeployerBash(self.evr).keystoneTenantCR('admin', 'Admin Tenant')
		dSys.DeployerBash(self.evr).keystoneUserCR('admin', self.passwd['admin'], 'admin@mail.com')
		dSys.DeployerBash(self.evr).keystoneRoleCR('admin')
		dSys.DeployerBash(self.evr).keystoneUserRoleAdd('admin', 'admin', 'admin')
		
		dSys.DeployerBash(self.evr).keystoneTenantCR('service', 'Service Tenant')
		
		
		
		
