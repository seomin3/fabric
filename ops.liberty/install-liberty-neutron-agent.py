#!/usr/bin/env python
'''
Created on 8 Feb 2015

@author: dh
'''

from utils import envLoader, deployerException
import socket
#from components.neutronAgtOvs import DepNeutronAgtOvs
from components.neutronAgtBridge import DepNeutronAgtBridge
from components.neutronAgtDhcp import DepNeutronAgtDhcp
from components.neutronAgtMeta import DepNeutronAgtMeta
from components.neutronAgtL3 import DepNeutronAgtL3
from components.basicConfig import DepBasicConfig

def deployNetwork():
	startmsg()
	hostname = socket.gethostbyname(socket.gethostname())
	env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'neutron-agent');
	if env['type'] != 'neutron-agent':
		raise deployerException.DeployerException("This node is not neutron agent server")
	
	ctrHostname = env['hacontroller']['ip']
	ctrHostip = env['hacontroller']['ip']
	myhostname = socket.gethostname()
	myMngIp = socket.gethostbyname(myhostname)

	#deploy compoments
	DepBasicConfig().start()
	#DepNeutronAgtOvs(env,ctrHostname,ctrHostip,myMngIp).start()
	DepNeutronAgtBridge(env,ctrHostname,ctrHostip,myMngIp).start()
	DepNeutronAgtDhcp(env,ctrHostname,ctrHostip,myMngIp).start()
	DepNeutronAgtMeta(env,ctrHostname,ctrHostip,myMngIp).start()
	DepNeutronAgtL3(env,ctrHostname,ctrHostip,myMngIp).start()

def startmsg():
	print '###################################################'
	print '# starting to install openstack network Node'
	print '###################################################'

if __name__ == '__main__':
	deployNetwork()
