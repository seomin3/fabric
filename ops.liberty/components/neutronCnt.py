'''
Created on 6 Feb 2015

@author: dh
'''

from utils import deployerSystemCall as dSys
import os

class DepNeutron(object):
	databasePass = ''
	mqPass = ''
	cntHostname = ''
	keystoneHostname = ''
	novaHostname = ''
	neutronHostname = ''
	dbHostname =''
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
		print 'starting to install neutron controller'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
	
	def __presets(self):
		dSys.DeployerBash().createOpstDb('neutron', self.databasePass, self.dbHostname)
		
		dSys.DeployerBash(self.evr).keystoneUserCR('neutron', self.passwd['neutron'], 'neutron@mail.com')
		dSys.DeployerBash(self.evr).keystoneUserRoleAdd('neutron', 'service', 'admin')
		dSys.DeployerBash(self.evr).keystoneServCR('neutron', 'network', 'OpenStack Networking')
		dSys.DeployerBash(self.evr).endpointCreate('neutron',self.neutronHostname,['9696','9696','9696'],'')
	
	def __packageInstall(self):
		neutronPkgs = ['openstack-neutron','openstack-neutron-ml2','openstack-neutron-linuxbridge','python-neutronclient','ebtables','ipset']
		dSys.DeployerBash().packageInstall(neutronPkgs)
		
	def __config(self):
		conf = [
			['oslo_concurrency','lock_path','/var/lib/neutron/tmp'],
			['DEFAULT','verbose','True'],
			['DEFAULT','allow_overlapping_ips','True'],
			['DEFAULT','core_plugin','ml2'],
			['DEFAULT','service_plugins','router'],
			['DEFAULT','auth_strategy','keystone'],
			['DEFAULT','rpc_backend','rabbit'],
			['oslo_messaging_rabbit','rabbit_host',self.cntHostname],
			['oslo_messaging_rabbit','rabbit_password',self.mqPass],
			['DEFAULT','notification_driver','neutron.openstack.common.notifier.rpc_notifier'],
			['DEFAULT','notify_nova_on_port_status_changes','True'],
			['DEFAULT','notify_nova_on_port_data_changes','True'],
			['DEFAULT','nova_url','http://'+self.novaHostname+':8774/v2'],
			['nova','auth_rul','http://'+self.keystoneHostname+':35357'],
			['nova','auth_plugin','password'],
			['nova','project_domain_id','default'],
			['nova','user_domain_id','default'],
			['nova','project_name','service'],
			['nova','username','nova'],
			['nova','password',self.passwd['nova']],
			['keystone_authtoken','auth_uri','http://'+self.keystoneHostname+':5000'],
			['keystone_authtoken','auth_url','http://'+self.keystoneHostname+':35357'],
			['keystone_authtoken','auth_plugin','password'],
			['keystone_authtoken','project_domain_id','default'],
			['keystone_authtoken','user_domain_id','default'],
			['keystone_authtoken','project_name','service'],
			['keystone_authtoken','username','neutron'],
			['keystone_authtoken','password',self.passwd['neutron']],
			['database','connection','mysql://neutron:'+self.databasePass+'@'+self.dbHostname+'/neutron']
		]
		
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/neutron.conf')

		conf = [
			['ml2','type_drivers','flat,vlan,vxlan'],
			['ml2','tenant_network_types','vxlan'],
			['ml2','mechanism_drivers','linuxbridge,l2population'],
			['ml2','extension_drivers','port_security'],
			['ml2_type_flat','flat_networks','physnet0'],
			['ml2_type_vlan','network_vlan_ranges','physnet2:10:99'],
			['ml2_type_vxlan','vni_ranges','100:1000'],
			['securitygroup','enable_security_group','True'],
			['securitygroup','enable_ipset','True'],
			['securitygroup','firewall_driver','neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver']
		]
		
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/plugins/ml2/ml2_conf.ini')
					
	def __initialSetup(self):
		tgLink = '/etc/neutron/plugin.ini'
		if os.path.isfile(tgLink) is False:
			os.symlink('/etc/neutron/plugins/ml2/ml2_conf.ini',tgLink)
		dSys.DeployerBash().syncOpstDb('neutron')
		
		dSys.DeployerBash().serviceControl('enable', 'neutron-server.service')
		dSys.DeployerBash().serviceControl('restart', 'neutron-server.service')
		
		dSys.DeployerBash().firewallSetup('9696')
		
