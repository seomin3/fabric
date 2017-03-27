'''
Created on 8 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
class DepNeutronAgtMeta(object):

	cntHostname = ''
	cntHostip = ''
	passwd = {}
	secret = {}
	
	def __init__(self, env, cntHostname,cntHostip, myMngIp):
		self.cntHostname = cntHostname
		self.cntHostip = cntHostip
		self.passwd = env['config']['credentials']['passwd']
		self.secret = env['config']['credentials']['secret']
		
	def reconfig(self):
		self.__config()
		self.__initialSetup()
		
	def start(self):
		print 'starting to install neutron metadata agent'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
		
	def __presets(self):
		pass

	def __packageInstall(self):
		pass
	
	def __config(self):
		conf = [
			['DEFAULT','verbose','True'],
			['DEFAULT','auth_uri','http://'+self.cntHostname+':5000'],
			['DEFAULT','auth_url','http://'+self.cntHostname+':35357'],
			['DEFAULT','auth_plugin','password'],
			['DEFAULT','project_domain_id','default'],
			['DEFAULT','user_domain_id','default'],
			['DEFAULT','project_name','service'],
			['DEFAULT','username','neutron'],
			['DEFAULT','password',self.passwd['neutron']],
			['DEFAULT','nova_metadata_ip',self.cntHostname],
			['DEFAULT','metadata_proxy_shared_secret',self.secret['metadata']]
		]

		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/metadata_agent.ini')

	def __initialSetup(self):
		dSys.DeployerBash().serviceControl('enable', 'neutron-metadata-agent.service')
		dSys.DeployerBash().serviceControl('restart', 'neutron-metadata-agent.service')
	
		
		
		