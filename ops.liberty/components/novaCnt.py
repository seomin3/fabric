'''
Created on 6 Feb 2015

@author: dh
'''

from utils import deployerSystemCall as dSys
import os
import socket

class DepNova(object):
	databasePass = ''
	mqPass = ''
	cntHostname = ''
	keystoneHostname = ''
	novaHostname = ''
	neutronHostname = ''
	dbHostname = ''
	passwd = {}
	secret = {}
	evr = {}
	
	def __init__(self, env, cntHostname):
		self.databasePass = env['config']['credentials']['database']['after']
		self.mqPass = env['config']['credentials']['mq']['after']
		self.cntHostname = cntHostname
		self.keystoneHostname = env['host_type']['keystone']
		self.novaHostname = env['host_type']['nova']
		self.neutronHostname = env['host_type']['neutron']
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
		print 'starting to install nova'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
	
	def __presets(self):
		dSys.DeployerBash().createOpstDb('nova', self.databasePass, self.dbHostname)
		
		dSys.DeployerBash(self.evr).keystoneUserCR('nova', self.passwd['nova'], 'nova@mail.com')
		dSys.DeployerBash(self.evr).keystoneUserRoleAdd('nova', 'service', 'admin')
		dSys.DeployerBash(self.evr).keystoneServCR('nova', 'compute', 'OpenStack Compute')
		dSys.DeployerBash(self.evr).endpointCreate('nova',self.novaHostname, ['8774','8774','8774'],'v2/%(tenant_id)s')
	
	def __packageInstall(self):
		novaPkgs = ['openstack-nova-api','openstack-nova-cert','openstack-nova-conductor','openstack-nova-console','openstack-nova-novncproxy','openstack-nova-scheduler','python-novaclient']
		dSys.DeployerBash().packageInstall(novaPkgs)
	
	def __config(self):
		hostIp = socket.gethostbyname(socket.getfqdn())
		conf = [
			['DEFAULT','verbose','True'],
			['DEFAULT','rpc_backend','rabbit'],
			['oslo_messaging_rabbit','rabbit_host',self.cntHostname],
			['oslo_messaging_rabbit','rabbit_password',self.mqPass],
			['vnc','vncserver_listen',hostIp],
			['vnc','vncserver_proxyclient_address',hostIp],
			['DEFAULT','my_ip',hostIp],
			['DEFAULT','auth_strategy','keystone'],
			['DEFAULT','network_api_class','nova.network.neutronv2.api.API'],
			['DEFAULT','security_group_api','neutron'],
			['DEFAULT','linuxnet_interface_driver','nova.network.linux_net.LinuxOVSInterfaceDriver'],
			['DEFAULT','firewall_driver','nova.virt.firewall.NoopFirewallDriver'],
			['DEFAULT','enabled_apis','osapi_compute,metadata'],
			['neutron','url','http://'+self.neutronHostname+':9696'],
			['neutron','auth_url','http://'+self.keystoneHostname+':35357'],
			['neutron','auth_plugin','password'],
			['neutron','project_domain_id','default'],
			['neutron','user_domain_id','default'],
			['neutron','project_name','service'],
			['neutron','username','neutron'],
			['neutron','password',self.passwd['neutron']],
			['neutron','service_metadata_proxy','True'],
			['neutron','metadata_proxy_shared_secret',self.secret['metadata']],
			['glance','host',self.cntHostname],
			['database','connection','mysql://nova:'+self.databasePass+'@'+self.dbHostname+'/nova'],
			['keystone_authtoken','auth_uri','http://'+self.keystoneHostname+':5000'],
			['keystone_authtoken','auth_url','http://'+self.keystoneHostname+':35357'],
			['keystone_authtoken','auth_plugin','password'],
			['keystone_authtoken','project_domain_id','default'],
			['keystone_authtoken','user_domain_id','default'],
			['keystone_authtoken','project_name','service'],
			['keystone_authtoken','username','nova'],
			['keystone_authtoken','password',self.passwd['nova']]
		]
		
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/nova/nova.conf')

	def __initialSetup(self):
		svList = ['api','cert','consoleauth','scheduler','conductor','novncproxy']
		
		# must stop all service before dbsync
		for s in svList:
			dSys.DeployerBash().serviceControl('stop', 'openstack-nova-'+s+'.service') 
		
		dSys.DeployerBash().syncOpstDb('nova')
		
		for s in svList:
			dSys.DeployerBash().serviceControl('enable', 'openstack-nova-'+s+'.service')
		for s in svList:
			dSys.DeployerBash().serviceControl('restart', 'openstack-nova-'+s+'.service')
		
		dSys.DeployerBash().firewallSetup(['8773','8774','8775','6080'])
		
		
		
