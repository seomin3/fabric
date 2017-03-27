'''
Created on 8 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
class DepNeutronAgtL3(object):
	
	def __init__(self, env, cntHostname,cntHostip, myMngIp):
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
			['DEBAULT','verbose','True'],
			['DEFAULT','interface_driver','neutron.agent.linux.interface.BridgeInterfaceDriver'],
			['DEFAULT','use_namespaces','True'],
			['DEFAULT','external_network_bridge','br-ex']
		]

		for c in conf:
			dSys.DeployerBash().configSet(c,'/etc/neutron/l3_agent.ini')
			
	def __initialSetup(self):
		dSys.DeployerBash().serviceControl('enable', 'neutron-l3-agent.service')
		dSys.DeployerBash().serviceControl('restart', 'neutron-l3-agent.service')
	