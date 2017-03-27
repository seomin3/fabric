'''
Created on 19 Nov 2015

@author: kjahyeon
'''
from utils import deployerSystemCall as dSys

class DepNeutronAgtBridge(object):
	myIp = ''
	
	def __init__(self, env, cntHostname = '', cntHostip = '', myMngIp = ''):
		self.myIp = myMngIp
		pass
	
	def reconfig(self):
		self.__config()
		self.__initialSetup()
		
	def start(self):
		print 'starting to install neutron bridge agent'
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
			['linux_bridge','physical_interface_mappings','public:eth0'],
			['vxlan','enable_vxlan','True'],
			['vxlan','local_ip',self.myIp],
			['vxlan','l2_population','True'],
			['agent','prevent_arp_spoofing','True'],
			['securitygroup','enable_security_group','True'],
			['securitygroup','firewall_driver','neutron.agent.linux.iptables_firewall.IptablesFirewallDriver']
		]
		
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/plugins/ml2/linuxbridge_agent.ini')
	
	def __initialSetup(self):
		dSys.DeployerBash().pkill('dnsmasq')
		dSys.DeployerBash().serviceControl('enable', 'neutron-dhcp-agent.service')
		dSys.DeployerBash().serviceControl('restart', 'neutron-dhcp-agent.service')
