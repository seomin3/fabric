'''
Created on 8 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
import os
import shutil

class DepNeutronAgtOvs(object):
	
	databasePass = ''
	mqPass = ''
	cntHostname = ''
	cntHostip = ''
	passwd = {}
	secret = {}
	myip = ''
	ovsInfo = {}
	
	def __init__(self, env, cntHostname,cntHostip, myMngIp):
		self.mqPass = env['config']['credentials']['mq']['after']
		self.cntHostname = cntHostname
		self.cntHostip = cntHostip
		self.passwd = env['config']['credentials']['passwd']
		self.secret = env['config']['credentials']['secret']
		self.myip = myMngIp
		self.ovsInfo = env['config']['network']['ovs']
		
	def start(self):
		print 'starting to install neutron ovs agent'
		self.__presets()
		self.__packageInstall()
		self.__config()
		self.__initialSetup()

	def __presets(self):
		sysFile = '/etc/sysctl.conf'
		dSys.DeployerBash().configAddIfNot('net.ipv4.ip_forward', sysFile, 'net.ipv4.ip_forward=1')
		dSys.DeployerBash().configAddIfNot('net.ipv4.conf.all.rp_filter', sysFile, 'net.ipv4.conf.all.rp_filter=0')
		dSys.DeployerBash().configAddIfNot('net.ipv4.conf.default.rp_filter', sysFile, 'net.ipv4.conf.default.rp_filter=0')
		dSys.DeployerBash().sysctlShow()
		
	def __packageInstall(self):
		neutronOvsPkgs = ['openstack-neutron-ml2','openstack-neutron-openvswitch'] 
		dSys .DeployerBash().packageInstall(neutronOvsPkgs)

	def __config(self):
		conf = [
			['DEFAULT','core_plugin','ml2'],
			['DEFAULT','service_plugins','router'],
			['DEFAULT','allow_overlapping_ips','True'],
			['DEFAULT','auth_strategy','keystone'],
			['DEFAULT','rpc_backend','rabbit'],
			['DEFAULT','rabbit_host',self.cntHostname],
			['DEFAULT','rabbit_password',self.mqPass],
			['DEFAULT','notification_driver','neutron.openstack.common.notifier.rpc_notifier'],
			['keystone_authtoken','auth_uri','http://'+self.cntHostname+':5000/v2.0'],
			['keystone_authtoken','identity_uri','http://'+self.cntHostname+':35357'],
			['keystone_authtoken','admin_tenant_name','service'],
			['keystone_authtoken','admin_user','neutron'],
			['keystone_authtoken','admin_password',self.passwd['neutron']]
		]
		
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/neutron.conf')
		
		conf = [
			['ml2','type_drivers','flat,vlan'],
			['ml2','tenant_network_types','vlan'],
			['ml2','mechanism_drivers','openvswitch'],
			['ml2_type_flat','flat_networks','physnet0'],
			['ml2_type_vlan','network_vlan_ranges','physnet2:100:200'],
			['securitygroup','enable_security_group','True'],
			['securitygroup','enable_ipset','True'],
			['securitygroup','firewall_driver','neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'],
			['ovs','tenant_network_type','vlan'],
			['ovs','integration_bridge','br-int'],
			['ovs','network_vlan_ranges','physnet0:1:1,physnet2:100:200'],
			['ovs','bridge_mappings','physnet0:'+self.ovsInfo['flat']['name']+',physnet2:'+self.ovsInfo['vlan']['name']]
		]

		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/plugins/ml2/ml2_conf.ini')

	def __initialSetup(self):
		dSys.DeployerBash().serviceControl('enable', 'openvswitch.service')
		dSys.DeployerBash().serviceControl('restart', 'openvswitch.service')
		
		for nType in self.ovsInfo:
			brName = self.ovsInfo[nType]['name']
			dSys.DeployerBash().ovsCntBr('add-br', brName)
			for nic in self.ovsInfo[nType]['nics']:
				dSys.DeployerBash().ovsCntPort('add-port', brName, nic)
				
		tgLink = '/etc/neutron/plugin.ini'
		if os.path.isfile(tgLink) is False:
			os.symlink('/etc/neutron/plugins/ml2/ml2_conf.ini',tgLink)
		
		ovsSvcFile = '/usr/lib/systemd/system/neutron-openvswitch-agent.service'
		shutil.copyfile(ovsSvcFile, ovsSvcFile+'.orig')
		dSys.DeployerBash().configSed('plugins\/openvswitch\/ovs_neutron_plugin.ini', 'plugin.ini', ovsSvcFile, option='')
		dSys.DeployerBash().runBash(['systemctl','daemon-reload'])
		dSys.DeployerBash().serviceControl('enable', 'neutron-openvswitch-agent.service')
		dSys.DeployerBash().serviceControl('restart', 'neutron-openvswitch-agent.service')
		
		