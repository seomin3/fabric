'''
Created on 8 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
class DepNeutronAgtDhcp(object):
	
	def __init__(self, env, cntHostname, cntHostip, myMngIp):
		pass
	
	def reconfig(self):
		self.__config()
		self.__initialSetup()
		
	def start(self):
		print 'starting to install neutron dhcp agent'
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
			['DEBUALT','verbose','True'],
			['DEFAULT','interface_driver','neutron.agent.linux.interface.BridgeInterfaceDriver'],
			['DEFAULT','dhcp_driver','neutron.agent.linux.dhcp.Dnsmasq'],
			['DEFAULT','use_namespaces','True'],
			['DEFAULT','dnsmasq_config_file','/etc/neutron/dnsmasq-neutron.conf'],
			['DEFAULT','enable_isolated_metadata','true'],
			['DEFAULT','ovs_use_veth','true']
		]
		
		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/dhcp_agent.ini')
		
		dnsmasqFile = '/etc/neutron/dnsmasq-neutron.conf'
		conf = [
			'log-dhcp',
			'log-facility = /var/log/neutron/dnsmasq.log',
			'dhcp-option-force = 26,1450'
		]
		dSys.DeployerBash().runSh('echo ""> '+dnsmasqFile) # create new file on the fly
		for c in conf:
			dSys.DeployerBash().configAddIfNot(c, dnsmasqFile, c)
	
	def __initialSetup(self):
		dSys.DeployerBash().pkill('dnsmasq')
		dSys.DeployerBash().serviceControl('enable', 'neutron-dhcp-agent.service')
		dSys.DeployerBash().serviceControl('restart', 'neutron-dhcp-agent.service')