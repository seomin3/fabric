#!/usr/bin/env python
'''
Created on 31 Jan 2015

@author: dh
'''
from utils import envLoader, deployerException
import socket
from components.neutronCnt import DepNeutron 
from components.basicConfig import DepBasicConfig

def deployController():
	startmsg()
	# check this node is controller
	hostname = socket.gethostbyname(socket.gethostname())
	env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'neutron');
	if env['type'] != 'neutron':
		raise deployerException.DeployerException("This node is not neutron server")
	
	
	# deploy components
	ctrHostname = env['hacontroller']['ip']
	DepBasicConfig().start()
	DepNeutron(env,ctrHostname).start()

def startmsg():
	print '###################################################'
	print '# starting to install openstack controller Node'
	print '###################################################'
	

if __name__ == '__main__':
	deployController()
	
