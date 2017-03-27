'''
Created on 6 Feb 2015

@author: dh
'''

from utils import deployerSystemCall as dSys
import os

class DepNovaAgt(object):
	databasePass = ''
	mqPass = ''
	cntHostname = ''
	keystoneHostname = ''
	glanceHostname = ''
	novaHostname = ''
	neutronHostname = ''
	dbHostname = ''
	passwd = {}
	secret = {}
	myip = ''
	
	def __init__(self, env, cntHostname,hostname):
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
		
		self.myip = hostname
	
	def start(self):
		print 'starting to install nova compute agent'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()

	def __presets(self):
		pass
	
	def __packageInstall(self):
		novaCmpPkgs = ['openstack-nova-compute','sysfsutils','libvirt-daemon-config-nwfilter','libvirt-daemon-driver-nwfilter']
		dSys .DeployerBash().packageInstall(novaCmpPkgs)
		
	def __config(self):
		conf = [
			['DEFAULT','verbose','True'],
			['DEFAULT','rpc_backend','rabbit'],
			['oslo_messaging_rabbit','rabbit_host',self.cntHostname],
			['oslo_messaging_rabbit','rabbit_password',self.mqPass],
			['DEFAULT','my_ip',self.myip],
			['DEFAULT','auth_strategy','keystone'],
			['vnc','enabled','True'],
			['vnc','novncproxy_base_url','http://'+self.novaHostname+':6080/vnc_auto.html'],
			['vnc','vncserver_listen','0.0.0.0'],
			['vnc','vncserver_proxyclient_address',self.myip],
			['DEFAULT','network_api_class','nova.network.neutronv2.api.API'],
			['DEFAULT','security_group_api','neutron'],
			['DEFAULT','linuxnet_interface_driver','nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver'],
			['DEFAULT','firewall_driver','nova.virt.firewall.NoopFirewallDriver'],
			['glance','host',self.glanceHostname],
			['neutron','url','http://'+self.neutronHostname+':9696'],
			['neutron','auth_strategy','keystone'],
			['neutron','admin_auth_url','http://'+self.keystoneHostname+':35357/v2.0'],
			['neutron','admin_tenant_name','service'],
			['neutron','admin_username','neutron'],
			['neutron','admin_password',self.passwd['neutron']],
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
		
		dSys.DeployerBash().serviceControl('enable', 'libvirtd.service')
		dSys.DeployerBash().serviceControl('enable', 'openstack-nova-compute.service')		
		dSys.DeployerBash().serviceControl('start', 'libvirtd.service')
		dSys.DeployerBash().serviceControl('start', 'openstack-nova-compute.service')
		
		dSys.DeployerBash().firewallSetup(['5672','3260','5900-6100'])
		