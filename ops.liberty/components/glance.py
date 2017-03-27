'''
Created on 4 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
import os

class DepGlance(object):
	databasePass = ''
	cntHostname = ''
	keystoneHostname = ''
	glanceHostname = ''
	dbHostname = ''
	passwd = {}
	secret = {}
	evr = {}
	
	def __init__(self, env, cntHostname):
		self.databasePass = env['config']['credentials']['database']['after']
		self.cntHostname = cntHostname
		self.keystoneHostname = env['host_type']['keystone']
		self.glanceHostname = env['host_type']['glance']
		self.dbHostname = env['mysql']['ip']
		self.passwd = env['config']['credentials']['passwd']
		self.secret = env['config']['credentials']['secret']
		
		self.evr = dict(os.environ)
		self.evr['OS_TOKEN'] = 'admin_token'
		self.evr['OS_URL'] = 'http://'+self.cntHostname+':35357/v3'
		self.evr['OS_IDENTITY_API_VERSION'] = '3'
	
	def reconfig(self):
		self.__config()
		self.__initialSetup()

	def start(self):
		print 'starting to install glance'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
		
	def __presets(self):
		dSys.DeployerBash().createOpstDb('glance', self.databasePass, self.dbHostname)
		
		dSys.DeployerBash(self.evr).keystoneUserCR('glance', self.passwd['glance'], 'glance@mail.com')
		dSys.DeployerBash(self.evr).keystoneUserRoleAdd('glance', 'service', 'admin')
		dSys.DeployerBash(self.evr).keystoneServCR('glance', 'image', 'OpenStack Image Service')
		dSys.DeployerBash(self.evr).endpointCreate('glance',self.glanceHostname, ['9292','9292','9292'],'')
		
	def __packageInstall(self):
		glancePkgs = ['openstack-glance','python-glanceclient']
		dSys.DeployerBash().packageInstall(glancePkgs)
		
	def __config(self):
		conf = [
			['DEFAULT','verbose','True'],
			['database',"connection",'mysql://glance:'+self.databasePass+'@'+self.dbHostname+'/glance'],
			['keystone_authtoken','auth_uri','http://'+self.keystoneHostname+':5000'],
			['keystone_authtoken','auth_url','http://'+self.keystoneHostname+':35357'],
			['keystone_authtoken','auth_plugin','password'],
			['keystone_authtoken','project_domain_id','default'],
			['keystone_authtoken','user_domain_id','default'],
			['keystone_authtoken','project_name','service'],
			['keystone_authtoken','username','glance'],
			['keystone_authtoken','password',self.passwd['glance']],
			['paste_deploy','flavor','keystone'],
			['glance_store','default_store','file'],
			['glance_store','filesystem_store_datadir','/var/lib/glance/images/']
		]
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/glance/glance-api.conf')
		
		conf = [
			['DEFAULT]','verbose','True'],
			['database',"connection",'mysql://glance:'+self.databasePass+'@'+self.dbHostname+'/glance'],
			['keystone_authtoken','auth_uri','http://'+self.keystoneHostname+':5000'],
			['keystone_authtoken','auth_uri','http://'+self.keystoneHostname+':35357'],
			['keystone_authtoken','auth_plugin','password'],
			['keystone_authtoken','project_domain_id','default'],
			['keystone_authtoken','user_domain_id','default'],
			['keystone_authtoken','project_name','service'],
			['keystone_authtoken','username','glance'],
			['keystone_authtoken','password',self.passwd['glance']],
			['paste_deploy','flavor','keystone']
		]
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/glance/glance-registry.conf')
		
		
	def __initialSetup(self):
		dSys.DeployerBash().syncOpstDb('glance')
		dSys.DeployerBash().serviceControl('enable', 'openstack-glance-api.service')
		dSys.DeployerBash().serviceControl('enable', 'openstack-glance-registry.service')
		dSys.DeployerBash().serviceControl('restart', 'openstack-glance-api.service')
		dSys.DeployerBash().serviceControl('restart', 'openstack-glance-registry.service')
		
		dSys.DeployerBash().firewallSetup(['9191','9292'])

		
		
